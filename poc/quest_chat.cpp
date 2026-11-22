// Diagnostic experiment. Read ../NATIVE_TRACE.txt and ../ACTIVITY_TRACE.txt.
// Completion observation is logging only until local causation is proven.
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <Xinput.h>
#include <bcrypt.h>
#include <intrin.h>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <cstdarg>
#include <cstring>
#include <cwchar>

template<class C> struct TtlString { C* data; uint32_t length, capacity; };
static_assert(sizeof(TtlString<wchar_t>) == 16, "Observed x64 string ABI");
static_assert(offsetof(TtlString<wchar_t>, length) == 8, "Observed length offset");
using ButtonHandler = void(__fastcall*)(void*, void*);
using QuestCallback = void(__fastcall*)(void*, void*);
using GetExplicitText = const TtlString<wchar_t>*(__fastcall*)(void*);
using SendChat = void(__fastcall*)(void*, const TtlString<wchar_t>*, int);
using MsgSend = void(__fastcall*)(void*, unsigned, const unsigned char*, unsigned);
using FindSelection = uintptr_t(__fastcall*)(void*, const void*);
using TalkCheck = bool(__fastcall*)(void*);

static uintptr_t gameBase;
static ButtonHandler originalButton;
static QuestCallback originalQuest;
static QuestCallback originalFinished;
static MsgSend originalMsgSend;
static TalkCheck originalTalkCheck;
static volatile LONG talkSamples;
static GetExplicitText getExplicitText;
static HANDLE logFile = INVALID_HANDLE_VALUE;
static SRWLOCK logLock = SRWLOCK_INIT;
struct Acceptance { bool committed; char expected[256], quest[256]; uint32_t uid; wchar_t title[256]; };
static thread_local Acceptance* currentAcceptance;
static thread_local unsigned* currentChatHandoffs;

static void Log(const char* format, ...) {
    char body[1600], line[1800];
    va_list args; va_start(args, format);
    _vsnprintf_s(body, sizeof(body), _TRUNCATE, format, args); va_end(args);
    _snprintf_s(line, sizeof(line), _TRUNCATE, "%llu thread=%lu %s\r\n",
        GetTickCount64(), GetCurrentThreadId(), body);
    OutputDebugStringA(line);
    AcquireSRWLockExclusive(&logLock);
    if(logFile != INVALID_HANDLE_VALUE) { DWORD written; WriteFile(logFile, line, static_cast<DWORD>(strlen(line)), &written, nullptr); }
    ReleaseSRWLockExclusive(&logLock);
}
template<class T> static T Read(uintptr_t address) {
    T value{}; SIZE_T done=0;
    if(!address || !ReadProcessMemory(GetCurrentProcess(), reinterpret_cast<void*>(address), &value, sizeof(value), &done) || done!=sizeof(value)) return T{};
    return value;
}
template<class C> static bool CopyString(const TtlString<C>& value, C (&target)[256]) {
    if(!value.data || !value.length || value.length>=256) return false;
    SIZE_T size=value.length*sizeof(C), done=0;
    if(!ReadProcessMemory(GetCurrentProcess(), value.data, target, size, &done) || done!=size) return false;
    target[value.length]=0; return true;
}
static void Utf8(const wchar_t* text, char (&output)[1024]) {
    if(!WideCharToMultiByte(CP_UTF8, 0, text, -1, output, sizeof(output), nullptr, nullptr)) output[0]=0;
}

static void TraceQuest(const char* event, void* quest, uintptr_t caller) {
    const auto address=reinterpret_cast<uintptr_t>(quest);
    char name[256]{};
    CopyString(Read<TtlString<char>>(address+0x10), name);
    void* frames[24]{};
    const auto count=CaptureStackBackTrace(1,24,frames,nullptr);
    const auto peOffset=Read<uint32_t>(gameBase+0x3C);
    const auto imageSize=Read<uint32_t>(gameBase+peOffset+0x50);
    char stack[700]{}; size_t used=0;
    for(USHORT i=0;i<count;i++) {
        const auto frame=reinterpret_cast<uintptr_t>(frames[i]);
        if(frame<gameBase || frame-gameBase>=imageSize) continue;
        const auto written=_snprintf_s(stack+used,sizeof(stack)-used,_TRUNCATE," g+%llX",frame-gameBase);
        if(written<0) break;
        used+=static_cast<size_t>(written);
    }
    const auto root=Read<uintptr_t>(address+0x40);
    Log("TRACE %s quest=%s uid=%u state=%u flags70=%02X flags7c=%02X parent=%p rootVtable=%p managerMode=%u caller=g+%llX localAcceptScope=%u stack:%s",
        event,name[0]?name:"UNAVAILABLE",Read<uint32_t>(address+8),Read<uint32_t>(address+0x3C),
        Read<unsigned char>(address+0x70),Read<unsigned char>(address+0x7C),
        reinterpret_cast<void*>(Read<uintptr_t>(address+0xB8)),reinterpret_cast<void*>(Read<uintptr_t>(root)),
        Read<uint32_t>(gameBase+0x1326E98),caller-gameBase,currentAcceptance?1u:0u,stack);
}

// Same read-only selection lookup and row layout used inside sub_00137A60.
static bool CopySelectedQuest(void* screen, char (&name)[256]) {
    const auto record=reinterpret_cast<FindSelection>(gameBase+0x139BF0)(
        reinterpret_cast<void*>(gameBase+0x1244BD8),reinterpret_cast<void*>(reinterpret_cast<uintptr_t>(screen)+0x498));
    if(!record) return false;
    const auto selectedOffset=Read<unsigned char>(record-0x54)?0xBEu:0xC0u;
    const auto index=Read<int16_t>(record-selectedOffset);
    const auto count=Read<uint32_t>(record-0x68);
    const auto rows=Read<uintptr_t>(record-0x70);
    if(index<0 || static_cast<uint32_t>(index)>=count || !rows) return false;
    return CopyString(Read<TtlString<char>>(rows+static_cast<uintptr_t>(index)*0x38),name);
}

// GameDI callback invoked by sub_007BA680 after its active-state write.
__declspec(noinline) static void __fastcall OnQuestStarted(void* game, void* quest) {
    const auto returnAddress=reinterpret_cast<uintptr_t>(_ReturnAddress());
    TraceQuest("started",quest,returnAddress);
    auto scope=currentAcceptance;
    if(scope && !scope->committed && returnAddress==gameBase+0x7BA78A &&
       Read<uint32_t>(reinterpret_cast<uintptr_t>(quest)+0x3C)==1) {
        const auto name=Read<TtlString<char>>(reinterpret_cast<uintptr_t>(quest)+0x10);
        char candidate[256]{};
        if(!CopyString(name,candidate)) {
            Log("acceptance detection: native active-state callback; quest identification: FAILED");
        } else if(strcmp(candidate,scope->expected)==0) {
            strcpy_s(scope->quest,candidate);
            scope->uid=Read<uint32_t>(reinterpret_cast<uintptr_t>(quest)+8);
            scope->committed=true;
            Log("acceptance detection: matching native active-state commit; quest identification: %s uid=%u",
                scope->quest,scope->uid);
        } else {
            Log("acceptance detection: ignoring nested/nonmatching start %s; selected target=%s",candidate,scope->expected);
        }
    }
    originalQuest(game, quest);
}

__declspec(noinline) static void __fastcall OnQuestFinished(void* game, void* quest) {
    TraceQuest("finished (LOCAL CAUSE UNPROVEN; NO CHAT)",quest,reinterpret_cast<uintptr_t>(_ReturnAddress()));
    originalFinished(game,quest);
}

static bool __fastcall OnTalkCheck(void* phase) {
    const auto ready=originalTalkCheck(phase);
    const auto address=reinterpret_cast<uintptr_t>(phase);
    const auto quest=Read<uintptr_t>(address+0x70);
    if(ready && Read<uint32_t>(quest+0x3C)==1 && InterlockedIncrement(&talkSamples)<=128) {
        const auto game=Read<uintptr_t>(gameBase+0x12822A8);
        const auto session=Read<uintptr_t>(game+0x4A0);
        const auto table=Read<uintptr_t>(session);
        const auto getter=Read<uintptr_t>(table+0x7B8);
        const auto local=(session && getter)?reinterpret_cast<uintptr_t(__fastcall*)(void*)>(getter)(reinterpret_cast<void*>(session)):0;
        const auto speaker=Read<uintptr_t>(address+0x140)?Read<uintptr_t>(address+0x148):0;
        const auto player=Read<uintptr_t>(local+0xA90);
        const auto dialog=player && Read<uintptr_t>(player+0xEC8)?Read<uintptr_t>(player+0xED0):0;
        const auto participant=dialog && Read<uintptr_t>(dialog+0x78)?Read<uintptr_t>(dialog+0x80):0;
        Log("TRACE talk ready (NOT ACTOR PROOF) questUid=%u phase=%p flags131=%02X speaker=%p speakerRaw2a0=%p speakerRaw2a8=%u localDialog=%p participantCandidate=%p localPlayerCandidate=%p",
            Read<uint32_t>(quest+8),phase,Read<unsigned char>(address+0x131),reinterpret_cast<void*>(speaker),
            reinterpret_cast<void*>(Read<uintptr_t>(speaker+0x2A0)),Read<uint32_t>(speaker+0x2A8),
            reinterpret_cast<void*>(dialog),reinterpret_cast<void*>(participant),reinterpret_cast<void*>(player));
    }
    return ready;
}

__declspec(noinline) static void __fastcall OnMsgSend(void* game, unsigned recipient, const unsigned char* data, unsigned size) {
    if(reinterpret_cast<uintptr_t>(_ReturnAddress())==gameBase+0x1054C6 && size>=4 &&
       Read<unsigned char>(reinterpret_cast<uintptr_t>(data))==1) {
        Log("chat transport: stock chat -> IGame::MsgSend recipient=%u bytes=%u mode=%u automaticScope=%u",
            recipient,size,Read<unsigned char>(reinterpret_cast<uintptr_t>(data)+1),currentChatHandoffs?1u:0u);
        if(currentChatHandoffs) ++*currentChatHandoffs;
    }
    originalMsgSend(game,recipient,data,size);
}

static void SendAccepted(const Acceptance& accepted) {
    if(!accepted.title[0]) { Log("FAIL title resolution: displayed title was unavailable"); return; }
    auto game=Read<uintptr_t>(gameBase+0x12822A8);
    auto session=Read<uintptr_t>(game+0x4A0);
    auto vtable=Read<uintptr_t>(session);
    auto getLocal=Read<uintptr_t>(vtable+0x7B8);
    if(!game || !session || !vtable || !getLocal) { Log("FAIL chat send: no normal local-player context"); return; }
    auto context=reinterpret_cast<void*(__fastcall*)(void*)>(getLocal)(reinterpret_cast<void*>(session));
    if(!context) { Log("FAIL chat send: session returned no local-player context"); return; }
    wchar_t message[300];
    _snwprintf_s(message, sizeof(message)/sizeof(message[0]), _TRUNCATE, L"accepted \"%s\"", accepted.title);
    TtlString<wchar_t> text{message, static_cast<uint32_t>(wcslen(message)), static_cast<uint32_t>(wcslen(message))};
    char utf8[1024]; Utf8(message, utf8);
    Log("chat send: calling stock sub_0011E940, SayAll mode 0, message=%s", utf8);
    unsigned handoffs=0;
    auto previousHandoffs=currentChatHandoffs;
    currentChatHandoffs=&handoffs;
    reinterpret_cast<SendChat>(gameBase+0x11E940)(context, &text, 0);
    currentChatHandoffs=previousHandoffs;
    Log("chat send: stock sender returned; stock remote handoffs=%u; remote delivery: UNVERIFIED (observer must confirm)",handoffs);
}

static void __fastcall OnButton(void* screen, void* control) {
    const auto address=reinterpret_cast<uintptr_t>(screen);
    const auto accept=Read<void*>(address+0x3B0);
    if(control!=accept || !accept) { originalButton(screen, control); return; }
    const auto mode=Read<uint32_t>(address+0x490);
    Log("acceptance detection: B_Accept pressed, mode=%u (press alone is not commit)", mode);
    if(mode!=1) {
        const auto player=Read<uintptr_t>(address+0x488);
        const auto dialog=Read<uintptr_t>(player+0xEC8)?Read<uintptr_t>(player+0xED0):0;
        Log("TRACE unsupported Accept player=%p dialog=%p choiceBefore=%u",reinterpret_cast<void*>(player),
            reinterpret_cast<void*>(dialog),Read<uint32_t>(dialog+0xC0));
        Log("FAIL acceptance detection: mode %u uses the unproven asynchronous dialogue-choice path; no alert sent", mode);
        originalButton(screen, control);
        Log("TRACE unsupported Accept returned dialog=%p choiceAfter=%u (choice alone is not commit)",
            reinterpret_cast<void*>(dialog),Read<uint32_t>(dialog+0xC0));
        return;
    }
    Acceptance scope{};
    if(!CopySelectedQuest(screen,scope.expected)) {
        Log("FAIL quest identification: selected target lookup unavailable; no alert sent");
        originalButton(screen,control); return;
    }
    Log("quest identification: selected target=%s (will require exact committed-name match)",scope.expected);
    auto titleControl=Read<void*>(address+0x3D0);
    if(titleControl) {
        const auto title=getExplicitText(titleControl);
        if(title) CopyString(Read<TtlString<wchar_t>>(reinterpret_cast<uintptr_t>(title)), scope.title);
    }
    char titleUtf8[1024]; Utf8(scope.title, titleUtf8);
    Log("title resolution: displayed UTF-16 title=%s", titleUtf8[0]?titleUtf8:"UNAVAILABLE");
    auto previous=currentAcceptance;
    currentAcceptance=&scope;
    originalButton(screen, control);
    currentAcceptance=previous;
    if(scope.committed) SendAccepted(scope);
    else Log("FAIL acceptance detection: supported Accept handler returned without a scoped native commit");
}

static bool Fingerprint(HMODULE module, const char* expected) {
    wchar_t path[MAX_PATH]; if(!GetModuleFileNameW(module,path,MAX_PATH)) return false;
    HANDLE file=CreateFileW(path,GENERIC_READ,FILE_SHARE_READ|FILE_SHARE_WRITE|FILE_SHARE_DELETE,nullptr,OPEN_EXISTING,0,nullptr);
    if(file==INVALID_HANDLE_VALUE) return false;
    BCRYPT_ALG_HANDLE algorithm=nullptr; BCRYPT_HASH_HANDLE hash=nullptr;
    bool ok=BCryptOpenAlgorithmProvider(&algorithm,BCRYPT_SHA256_ALGORITHM,nullptr,0)>=0;
    if(ok) ok=BCryptCreateHash(algorithm,&hash,nullptr,0,nullptr,0,0)>=0;
    BYTE buffer[65536],digest[32]; DWORD count=0;
    while(ok) {
        if(!ReadFile(file,buffer,sizeof(buffer),&count,nullptr)) {ok=false;break;}
        if(!count) break;
        ok=BCryptHashData(hash,buffer,count,0)>=0;
    }
    if(ok) ok=BCryptFinishHash(hash,digest,sizeof(digest),0)>=0;
    if(hash) BCryptDestroyHash(hash); if(algorithm) BCryptCloseAlgorithmProvider(algorithm,0); CloseHandle(file);
    char hex[65]{}; if(ok) for(unsigned i=0;i<32;i++) sprintf_s(hex+2*i,3,"%02X",digest[i]);
    Log("binary fingerprint: %s", ok?hex:"FAILED");
    return ok && strcmp(hex,expected)==0;
}
static bool PatchSlot(uintptr_t slot, void* expected, void* replacement) {
    if(Read<void*>(slot)!=expected) return false;
    DWORD oldProtection;
    if(!VirtualProtect(reinterpret_cast<void*>(slot),sizeof(void*),PAGE_READWRITE,&oldProtection)) return false;
    InterlockedExchangePointer(reinterpret_cast<void* volatile*>(slot),replacement);
    DWORD ignored; VirtualProtect(reinterpret_cast<void*>(slot),sizeof(void*),oldProtection,&ignored);
    return true;
}
static DWORD WINAPI Initialize(void*) {
    wchar_t temp[MAX_PATH],path[MAX_PATH];
    if(GetTempPathW(MAX_PATH,temp)) {
        _snwprintf_s(path,sizeof(path)/sizeof(path[0]),_TRUNCATE,L"%sDIDEQuestChatPoC.log",temp);
        logFile=CreateFileW(path,FILE_APPEND_DATA,FILE_SHARE_READ|FILE_SHARE_WRITE,nullptr,OPEN_ALWAYS,FILE_ATTRIBUTE_NORMAL,nullptr);
    }
    Log("Quest Chat diagnostic 2 startup: target-matched acceptance; completion LOG ONLY; no archive edits; waiting for native modules");
    HMODULE game=nullptr,engine=nullptr;
    for(unsigned i=0;i<600 && (!game || !engine);i++) {
        game=GetModuleHandleW(L"gamedll_x64_rwdi.dll"); engine=GetModuleHandleW(L"engine_x64_rwdi.dll");
        if(!game || !engine) Sleep(100);
    }
    if(!game || !engine) { Log("FAIL initialization: native modules unavailable"); return 0; }
    if(!Fingerprint(game,"D10C7F59AD3BF62E7F2DD69CD7E49EB634D4E8D046E4F4C07463B5D589833545") ||
       !Fingerprint(engine,"7CF1F0153A2748DA55A36D89FCF2E451BA444468260355836722D3EF76B27C79")) {
        Log("FAIL initialization: unsupported binary; no hook installed"); return 0;
    }
    gameBase=reinterpret_cast<uintptr_t>(game);
    Log("native module base: game=%p engine=%p",reinterpret_cast<void*>(gameBase),reinterpret_cast<void*>(engine));
    originalButton=reinterpret_cast<ButtonHandler>(gameBase+0x3FB7A0);
    originalQuest=reinterpret_cast<QuestCallback>(gameBase+0x1018C0);
    originalFinished=reinterpret_cast<QuestCallback>(gameBase+0x101A20);
    originalTalkCheck=reinterpret_cast<TalkCheck>(gameBase+0x806620);
    originalMsgSend=reinterpret_cast<MsgSend>(GetProcAddress(engine,"?MsgSend@IGame@@QEAAXIPEBEI@Z"));
    getExplicitText=reinterpret_cast<GetExplicitText>(GetProcAddress(engine,"?GetTextExplicit@IUIText@@UEAAAEBV?$string_base@_W@ttl@@XZ"));
    if(!getExplicitText || !originalMsgSend || Read<void*>(gameBase+0xDCE248)!=reinterpret_cast<void*>(originalButton) ||
       Read<void*>(gameBase+0xD028A0)!=reinterpret_cast<void*>(originalQuest) ||
       Read<void*>(gameBase+0xD028B0)!=reinterpret_cast<void*>(originalFinished) ||
       Read<void*>(gameBase+0xF01B38)!=reinterpret_cast<void*>(originalTalkCheck) ||
       Read<void*>(gameBase+0xC7E8B0)!=reinterpret_cast<void*>(originalMsgSend)) {
        Log("FAIL initialization: expected export/vtable slots not present; no hook installed"); return 0;
    }
    if(!PatchSlot(gameBase+0xC7E8B0,reinterpret_cast<void*>(originalMsgSend),reinterpret_cast<void*>(&OnMsgSend))) {
        Log("FAIL initialization: chat transport observer unavailable"); return 0;
    }
    if(!PatchSlot(gameBase+0xD028B0,reinterpret_cast<void*>(originalFinished),reinterpret_cast<void*>(&OnQuestFinished))) {
        PatchSlot(gameBase+0xC7E8B0,reinterpret_cast<void*>(&OnMsgSend),reinterpret_cast<void*>(originalMsgSend));
        Log("FAIL initialization: finish observer unavailable; transport hook restored"); return 0;
    }
    if(!PatchSlot(gameBase+0xD028A0,reinterpret_cast<void*>(originalQuest),reinterpret_cast<void*>(&OnQuestStarted))) {
        PatchSlot(gameBase+0xD028B0,reinterpret_cast<void*>(&OnQuestFinished),reinterpret_cast<void*>(originalFinished));
        PatchSlot(gameBase+0xC7E8B0,reinterpret_cast<void*>(&OnMsgSend),reinterpret_cast<void*>(originalMsgSend));
        Log("FAIL initialization: quest callback hook unavailable; other hooks restored"); return 0;
    }
    if(!PatchSlot(gameBase+0xDCE248,reinterpret_cast<void*>(originalButton),reinterpret_cast<void*>(&OnButton))) {
        PatchSlot(gameBase+0xD028A0,reinterpret_cast<void*>(&OnQuestStarted),reinterpret_cast<void*>(originalQuest));
        PatchSlot(gameBase+0xD028B0,reinterpret_cast<void*>(&OnQuestFinished),reinterpret_cast<void*>(originalFinished));
        PatchSlot(gameBase+0xC7E8B0,reinterpret_cast<void*>(&OnMsgSend),reinterpret_cast<void*>(originalMsgSend));
        Log("FAIL initialization: button hook unavailable; other hooks restored"); return 0;
    }
    if(!PatchSlot(gameBase+0xF01B38,reinterpret_cast<void*>(originalTalkCheck),reinterpret_cast<void*>(&OnTalkCheck))) {
        PatchSlot(gameBase+0xDCE248,reinterpret_cast<void*>(&OnButton),reinterpret_cast<void*>(originalButton));
        PatchSlot(gameBase+0xD028A0,reinterpret_cast<void*>(&OnQuestStarted),reinterpret_cast<void*>(originalQuest));
        PatchSlot(gameBase+0xD028B0,reinterpret_cast<void*>(&OnQuestFinished),reinterpret_cast<void*>(originalFinished));
        PatchSlot(gameBase+0xC7E8B0,reinterpret_cast<void*>(&OnMsgSend),reinterpret_cast<void*>(originalMsgSend));
        Log("FAIL initialization: talk observer unavailable; other hooks restored"); return 0;
    }
    Log("READY diagnostic 2: target-matched acceptance, start/finish/talk observers and stock chat handoff observer installed; completion sends DISABLED");
    return 0;
}

static INIT_ONCE xinputOnce=INIT_ONCE_STATIC_INIT;
static HMODULE systemXinput;
static BOOL CALLBACK LoadSystemXinput(PINIT_ONCE, PVOID, PVOID*) {
    wchar_t path[MAX_PATH]; if(!GetSystemDirectoryW(path,MAX_PATH)) return FALSE;
    wcscat_s(path,L"\\xinput1_3.dll"); systemXinput=LoadLibraryW(path); return systemXinput!=nullptr;
}
static FARPROC XinputFunction(const char* name) {
    InitOnceExecuteOnce(&xinputOnce,LoadSystemXinput,nullptr,nullptr);
    return systemXinput?GetProcAddress(systemXinput,name):nullptr;
}
extern "C" DWORD WINAPI ProxyGetState(DWORD index,XINPUT_STATE* state) {
    auto fn=reinterpret_cast<decltype(&XInputGetState)>(XinputFunction("XInputGetState"));
    return fn?fn(index,state):ERROR_DEVICE_NOT_CONNECTED;
}
extern "C" DWORD WINAPI ProxySetState(DWORD index,XINPUT_VIBRATION* vibration) {
    auto fn=reinterpret_cast<decltype(&XInputSetState)>(XinputFunction("XInputSetState"));
    return fn?fn(index,vibration):ERROR_DEVICE_NOT_CONNECTED;
}
extern "C" DWORD WINAPI ProxyGetCapabilities(DWORD index,DWORD flags,XINPUT_CAPABILITIES* capabilities) {
    auto fn=reinterpret_cast<decltype(&XInputGetCapabilities)>(XinputFunction("XInputGetCapabilities"));
    return fn?fn(index,flags,capabilities):ERROR_DEVICE_NOT_CONNECTED;
}
BOOL WINAPI DllMain(HINSTANCE module,DWORD reason,LPVOID) {
    if(reason==DLL_PROCESS_ATTACH) {
        DisableThreadLibraryCalls(module);
        HANDLE worker=CreateThread(nullptr,0,Initialize,nullptr,0,nullptr); if(worker) CloseHandle(worker);
    }
    return TRUE;
}
