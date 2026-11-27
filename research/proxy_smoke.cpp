// Isolated process test: exercise forwarding, then refuse deliberately wrong modules.
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <Xinput.h>
#include <shlobj.h>
#include <cstdio>
#include <cstring>
#include <cwchar>
#include <string>
#include "../poc/display_toggle.h"

class TestProfile {
    HKEY key_{};
    wchar_t branch_[96]{};
    bool overridden_{};
    bool Set(const wchar_t* branch,const wchar_t* name,const wchar_t* value,DWORD type) {
        HKEY entry=nullptr;
        if(RegCreateKeyExW(key_,branch,0,nullptr,REG_OPTION_VOLATILE,KEY_WRITE,nullptr,&entry,nullptr)!=ERROR_SUCCESS) return false;
        const auto length=static_cast<DWORD>((wcslen(value)+1)*sizeof(wchar_t));
        const auto result=RegSetValueExW(entry,name,0,type,reinterpret_cast<const BYTE*>(value),length);
        RegCloseKey(entry);
        return result==ERROR_SUCCESS;
    }
public:
    bool Init() {
        swprintf_s(branch_,L"Software\\BanoiSmoke-%lu-%llu",GetCurrentProcessId(),GetTickCount64());
        DWORD disposition=0;
        if(RegCreateKeyExW(HKEY_CURRENT_USER,branch_,0,nullptr,REG_OPTION_VOLATILE,KEY_ALL_ACCESS,nullptr,&key_,&disposition)!=ERROR_SUCCESS ||
           disposition!=REG_CREATED_NEW_KEY) { branch_[0]=0; return false; }
        if(!Set(L"Software\\BanoiTogether",L"TesterRole",L"H",REG_SZ)) return false;
        overridden_=RegOverridePredefKey(HKEY_CURRENT_USER,key_)==ERROR_SUCCESS;
        return overridden_;
    }
    ~TestProfile() {
        if(overridden_) RegOverridePredefKey(HKEY_CURRENT_USER,nullptr);
        if(key_) RegCloseKey(key_);
        if(branch_[0]) RegDeleteTreeW(HKEY_CURRENT_USER,branch_);
    }
};

static bool WindowToggleFixture() {
    const auto window=CreateWindowExW(0,L"STATIC",L"Banoi display fixture",WS_OVERLAPPEDWINDOW,80,80,640,480,nullptr,nullptr,nullptr,nullptr);
    if(!window) return false;
    RECT original{},fullscreen{},restored{};
    MONITORINFO monitor{sizeof(monitor)};
    const auto style=GetWindowLongPtrW(window,GWL_STYLE);
    BanoiDisplay::Toggle toggle;
    const auto passed=GetWindowRect(window,&original) &&
        GetMonitorInfoW(MonitorFromWindow(window,MONITOR_DEFAULTTONEAREST),&monitor) &&
        toggle.Enter(window) && GetWindowRect(window,&fullscreen) && EqualRect(&fullscreen,&monitor.rcMonitor) &&
        toggle.Restore(window) && GetWindowRect(window,&restored) && EqualRect(&original,&restored) &&
        GetWindowLongPtrW(window,GWL_STYLE)==style;
    if(!passed) printf("fixture geometry: before=%ld,%ld,%ld,%ld fullscreen=%ld,%ld,%ld,%ld monitor=%ld,%ld,%ld,%ld restored=%ld,%ld,%ld,%ld style=%llx->%llx error=%lu\n",
        original.left,original.top,original.right,original.bottom,fullscreen.left,fullscreen.top,fullscreen.right,fullscreen.bottom,
        monitor.rcMonitor.left,monitor.rcMonitor.top,monitor.rcMonitor.right,monitor.rcMonitor.bottom,
        restored.left,restored.top,restored.right,restored.bottom,style,GetWindowLongPtrW(window,GWL_STYLE),GetLastError());
    DestroyWindow(window);
    return passed;
}

int wmain(int argc,wchar_t** argv) {
    if(argc!=3) return 2;
    if(!WindowToggleFixture()) { puts("FAIL borderless window could not be restored"); return 9; }
    puts("PASS borderless window fills monitor and restores prior window bounds and style");
    PWSTR actualDesktop=nullptr;
    if(FAILED(SHGetKnownFolderPath(FOLDERID_Desktop,0,nullptr,&actualDesktop)) || !actualDesktop) {
        puts("FAIL no Windows Desktop"); return 8;
    }
    const std::wstring desktop(actualDesktop);
    CoTaskMemFree(actualDesktop);
    TestProfile profile;
    if(!profile.Init()) { puts("FAIL could not isolate the tester role"); return 8; }
    const auto glob=desktop+L"\\DIDEQuestChatPoC-H-Hannah-*.log";
    char marker[40]; sprintf_s(marker,"pid=%lu;",GetCurrentProcessId());
    FILETIME started{}; GetSystemTimeAsFileTime(&started);
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
        WIN32_FIND_DATAW entry{};
        const auto search=FindFirstFileW(glob.c_str(),&entry);
        if(search==INVALID_HANDLE_VALUE) { Sleep(100); continue; }
        do {
            if(CompareFileTime(&entry.ftCreationTime,&started)<0) continue;
            const auto logPath=desktop+L"\\"+entry.cFileName;
            const auto file=CreateFileW(logPath.c_str(),GENERIC_READ,FILE_SHARE_READ|FILE_SHARE_WRITE|FILE_SHARE_DELETE,nullptr,OPEN_EXISTING,0,nullptr);
            if(file==INVALID_HANDLE_VALUE) continue;
            char log[8192]{}; DWORD count=0; ReadFile(file,log,sizeof(log)-1,&count,nullptr); CloseHandle(file);
            if(strstr(log,marker) && strstr(log,"FAIL initialization: unsupported binary; no hook installed")) {
                FindClose(search);
                if(!DeleteFileW(logPath.c_str())) { puts("FAIL could not clean up the fixture log"); return 11; }
                const auto firstLine=strstr(log,"Z | Player H (Hannah)\r\n");
                if(!firstLine || firstLine-log!=23 || !strstr(log,"tester=H; log=Desktop")) {
                    puts("FAIL timestamp or player label missing from Desktop log"); return 10;
                }
                puts("PASS timestamped Desktop log and wrong-build fingerprint refusal"); return 0;
            }
        } while(FindNextFileW(search,&entry));
        FindClose(search);
        Sleep(100);
    }
    puts("FAIL wrong-build refusal was not observed"); return 6;
}
