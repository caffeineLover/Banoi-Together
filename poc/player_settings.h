#pragma once
#include <cstdio>
#include <cwchar>
#include <string>
#include <string_view>

namespace BanoiSettings {
struct Player { char role; const wchar_t* name; const char* label; };
inline Player Identity(wchar_t role) {
    switch(role) {
        case L'A': case L'P': return {'P',L"Peter","Peter"};
        case L'B': case L'H': return {'H',L"Hannah","Hannah"};
        case L'C': case L'M': return {'M',L"Morty","Morty"};
        default: return {'?',L"Unassigned","Unassigned"};
    }
}
struct Stamp { unsigned year,month,day,hour,minute,second,millisecond; };
inline std::wstring LogName(Player player,Stamp t,unsigned sequence=0) {
    wchar_t filename[160];
    const auto suffix=sequence? L"-"+std::to_wstring(sequence):std::wstring{};
    const auto tag=player.role=='?'?std::wstring(player.name):std::wstring(1,player.role)+L"-"+player.name;
    swprintf_s(filename,L"DIDEQuestChatPoC-%ls-%04u-%02u-%02u_%02u-%02u-%02u-%03uZ%ls.log",
        tag.c_str(),t.year,t.month,t.day,t.hour,t.minute,t.second,t.millisecond,suffix.c_str());
    return filename;
}
inline std::string LogHeader(Player player,Stamp t) {
    char header[160];
    sprintf_s(header,"%04u-%02u-%02uT%02u:%02u:%02u.%03uZ | Player %c (%s)\r\n",
        t.year,t.month,t.day,t.hour,t.minute,t.second,t.millisecond,player.role,player.label);
    return header;
}
inline std::string_view Trim(std::string_view text) {
    const auto first=text.find_first_not_of(" \t\r");
    if(first==std::string_view::npos) return {};
    return text.substr(first,text.find_last_not_of(" \t\r")-first+1);
}
inline unsigned FullscreenKey(std::string_view yaml) {
    constexpr unsigned fallback=0x7A; // F11
    if(yaml.substr(0,3)=="\xEF\xBB\xBF") yaml.remove_prefix(3);
    while(!yaml.empty()) {
        const auto newline=yaml.find('\n');
        auto line=yaml.substr(0,newline);
        yaml=newline==std::string_view::npos?std::string_view{}:yaml.substr(newline+1);
        line=Trim(line.substr(0,line.find('#')));
        const auto colon=line.find(':');
        if(colon==std::string_view::npos || Trim(line.substr(0,colon))!="fullscreen_key") continue;
        auto key=Trim(line.substr(colon+1));
        if(key.size()>=2 && (key[0]=='\'' || key[0]=='"') && key.back()==key.front()) key=key.substr(1,key.size()-2);
        if(key.size()==1) {
            const auto c=key.front();
            if((c>='A' && c<='Z') || (c>='0' && c<='9')) return static_cast<unsigned>(c);
            if(c>='a' && c<='z') return static_cast<unsigned>(c-'a'+'A');
        } else if(key.size()>=2 && key.size()<=3 && (key[0]=='F' || key[0]=='f')) {
            unsigned number=0;
            for(const auto digit : key.substr(1)) {
                if(digit<'0' || digit>'9') return fallback;
                number=number*10+static_cast<unsigned>(digit-'0');
            }
            if(number>=1 && number<=24) return 0x6F+number;
        }
        return fallback;
    }
    return fallback;
}
class KeyEdge {
    bool down_{};
public:
    bool Update(bool down,bool foreground) {
        const auto pressed=down && !down_ && foreground;
        down_=down;
        return pressed;
    }
};
}
