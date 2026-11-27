#pragma once
#include <windows.h>

namespace BanoiDisplay {
class Toggle {
    HWND window_{};
    LONG_PTR style_{};
    WINDOWPLACEMENT placement_{};

    static bool SetStyle(HWND window,LONG_PTR style) {
        SetLastError(ERROR_SUCCESS);
        return SetWindowLongPtrW(window,GWL_STYLE,style)!=0 || GetLastError()==ERROR_SUCCESS;
    }
    static bool RefreshFrame(HWND window) {
        return SetWindowPos(window,nullptr,0,0,0,0,
            SWP_FRAMECHANGED|SWP_NOMOVE|SWP_NOSIZE|SWP_NOZORDER|SWP_NOACTIVATE)!=FALSE;
    }
public:
    bool IsFullscreen(HWND window) const { return window_==window; }
    bool Enter(HWND window) {
        MONITORINFO monitor{sizeof(monitor)};
        WINDOWPLACEMENT placement{sizeof(placement)};
        if(!GetMonitorInfoW(MonitorFromWindow(window,MONITOR_DEFAULTTONEAREST),&monitor) ||
           !GetWindowPlacement(window,&placement)) return false;
        if(!IsWindowVisible(window)) placement.showCmd=SW_HIDE;
        const auto style=GetWindowLongPtrW(window,GWL_STYLE);
        const auto borderless=(style & ~static_cast<LONG_PTR>(WS_OVERLAPPEDWINDOW)) | static_cast<LONG_PTR>(WS_POPUP);
        if(IsZoomed(window)) ShowWindow(window,SW_RESTORE);
        const auto& rect=monitor.rcMonitor;
        if(!SetStyle(window,borderless) || !SetWindowPos(window,nullptr,rect.left,rect.top,
           rect.right-rect.left,rect.bottom-rect.top,SWP_FRAMECHANGED|SWP_NOZORDER|SWP_NOACTIVATE)) {
            SetStyle(window,style); SetWindowPlacement(window,&placement); RefreshFrame(window);
            return false;
        }
        window_=window; style_=style; placement_=placement;
        return true;
    }
    bool Restore(HWND window) {
        if(!IsFullscreen(window) || !SetStyle(window,style_) ||
           !SetWindowPlacement(window,&placement_) || !RefreshFrame(window)) return false;
        window_=nullptr;
        return true;
    }
};
}
