// Isolated process test: exercise forwarding, then refuse deliberately wrong modules.
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <Xinput.h>
#include <cstdio>
#include <cstring>

int wmain(int argc,wchar_t** argv) {
    if(argc!=3) return 2;
    SetEnvironmentVariableW(L"TMP",argv[2]); SetEnvironmentVariableW(L"TEMP",argv[2]);
    wchar_t logPath[MAX_PATH]; swprintf_s(logPath,L"%s\\DIDEQuestChatPoC.log",argv[2]);
    HANDLE freshLog=CreateFileW(logPath,GENERIC_WRITE,FILE_SHARE_READ|FILE_SHARE_WRITE,nullptr,CREATE_ALWAYS,0,nullptr);
    if(freshLog==INVALID_HANDLE_VALUE) { puts("FAIL could not clear isolated test log"); return 7; }
    CloseHandle(freshLog);
    auto fakeGame=LoadLibraryW(L"research\\smoke-build\\gamedll_x64_rwdi.dll");
    auto fakeEngine=LoadLibraryW(L"research\\smoke-build\\engine_x64_rwdi.dll");
    auto proxy=LoadLibraryW(argv[1]);
    wchar_t systemPath[MAX_PATH]; GetSystemDirectoryW(systemPath,MAX_PATH); wcscat_s(systemPath,L"\\xinput1_3.dll");
    auto system=LoadLibraryW(systemPath);
    if(!fakeGame || !fakeEngine || !proxy || !system) {printf("FAIL module load %lu\n",GetLastError());return 3;}
    const char* names[]={"XInputGetState","XInputSetState","XInputGetCapabilities"};
    for(int i=0;i<3;i++) {
        if(GetProcAddress(proxy,names[i])!=GetProcAddress(proxy,MAKEINTRESOURCEA(i+2))) {printf("FAIL export ordinal %d\n",i+2);return 4;}
    }
    XINPUT_STATE state{}; XINPUT_VIBRATION vibration{}; XINPUT_CAPABILITIES caps{};
    auto pGet=reinterpret_cast<decltype(&XInputGetState)>(GetProcAddress(proxy,names[0]));
    auto sGet=reinterpret_cast<decltype(&XInputGetState)>(GetProcAddress(system,names[0]));
    auto pSet=reinterpret_cast<decltype(&XInputSetState)>(GetProcAddress(proxy,names[1]));
    auto sSet=reinterpret_cast<decltype(&XInputSetState)>(GetProcAddress(system,names[1]));
    auto pCaps=reinterpret_cast<decltype(&XInputGetCapabilities)>(GetProcAddress(proxy,names[2]));
    auto sCaps=reinterpret_cast<decltype(&XInputGetCapabilities)>(GetProcAddress(system,names[2]));
    const DWORD invalidIndex=0xFFFFFFFFu;
    if(pGet(invalidIndex,&state)!=sGet(invalidIndex,&state) || pSet(invalidIndex,&vibration)!=sSet(invalidIndex,&vibration) ||
       pCaps(invalidIndex,0,&caps)!=sCaps(invalidIndex,0,&caps)) {puts("FAIL forwarding mismatch");return 5;}
    puts("PASS named exports and ordinals 2/3/4; all three calls match the system DLL");
    for(int i=0;i<50;i++) {
        HANDLE file=CreateFileW(logPath,GENERIC_READ,FILE_SHARE_READ|FILE_SHARE_WRITE,nullptr,OPEN_EXISTING,0,nullptr);
        if(file!=INVALID_HANDLE_VALUE) {
            char log[8192]{}; DWORD count; ReadFile(file,log,sizeof(log)-1,&count,nullptr); CloseHandle(file);
            if(strstr(log,"FAIL initialization: unsupported binary; no hook installed")) {
                puts("PASS wrong-build fingerprint refused; no hooks installed"); return 0;
            }
        }
        Sleep(100);
    }
    puts("FAIL wrong-build refusal was not observed"); return 6;
}
