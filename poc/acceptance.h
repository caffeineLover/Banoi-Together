#pragma once
#include <cstdint>
#include <cstring>

namespace QuestActivity {
struct Accepted { uint32_t uid{}; char name[256]{}; wchar_t title[256]{}; };
struct Intent { uintptr_t actor, speaker, resource; const wchar_t* title; };
struct TalkObservation {
    uintptr_t actor, speaker, resource, phase, owner;
    const char* ownerName; uint32_t ownerUid; const char* titleKey;
    uint32_t phaseState; bool ready, positive, normal;
};
struct StartObservation { uintptr_t quest, parent; const char* name; uint32_t uid, state, parentState; bool normal; };
class Tracker {
    uintptr_t actor_{}, speaker_{}, resource_{}, phase_{}, owner_{};
    bool active_{}, committed_{}, targetReady_{};
    char expected_[256]{};
    Accepted result_{};
    template<class C> static bool Copy(const C* source,C (&target)[256]) {
        if(!source) return false;
        for(unsigned i=0;i<256;++i) {
            target[i]=source[i];
            if(!source[i]) return i!=0;
        }
        target[0]=0; return false;
    }
    static bool BriefName(const char* key,char (&name)[256]) {
        if(!key) return false;
        size_t length=0; while(length<256 && key[length]) ++length;
        if(length==256) return false;
        if(length && key[0]=='&') {
            if(length<2 || key[length-1]!='&') return false;
            ++key; length-=2;
        }
        constexpr char suffix[]="_Name";
        if(length<=5 || std::memcmp(key+length-5,suffix,5)!=0) return false;
        length-=5;
        for(size_t i=0;i<length;++i) {
            const auto c=key[i];
            if(!((c>='A' && c<='Z') || (c>='a' && c<='z') || (c>='0' && c<='9') || c=='_')) return false;
        }
        std::memcpy(name,key,length); name[length]=0; return true;
    }
public:
    // Synchronization belongs to the native hook adapter; no engine pointers
    // are dereferenced here and no engine memory is owned by this tracker.
    bool Active() const { return active_; }
    uintptr_t Actor() const { return actor_; }
    uintptr_t Resource() const { return resource_; }
    bool Arm(const Intent& input) {
        Cancel();
        if(!input.actor || !input.speaker || !input.resource || !Copy(input.title,result_.title)) return false;
        actor_=input.actor; speaker_=input.speaker; resource_=input.resource; active_=true; return true;
    }
    bool Check(const TalkObservation& event) {
        if(!active_ || event.actor!=actor_ || event.speaker!=speaker_ || event.resource!=resource_ ||
           !event.ready || !event.positive || !event.normal || event.phaseState!=1 ||
           !event.phase || !event.owner || !event.ownerName || !event.ownerUid) return false;
        char name[256]{};
        if(!BriefName(event.titleKey,name)) return false;
        if(phase_) return phase_==event.phase && owner_==event.owner && std::strcmp(expected_,name)==0;
        Copy(name,expected_); phase_=event.phase; owner_=event.owner;
        if(std::strcmp(expected_,event.ownerName)==0) {
            Copy(expected_,result_.name); result_.uid=event.ownerUid; targetReady_=true;
        }
        return true;
    }
    bool Commit(uintptr_t phase,uint32_t before,uint32_t after,uintptr_t actor,bool normal) {
        if(!active_ || !normal || actor!=actor_ || !phase_ || phase!=phase_ || before!=1 || after!=2) return false;
        committed_=true; return true;
    }
    void Started(const StartObservation& event) {
        if(!active_ || !phase_ || targetReady_ || !event.normal || !event.quest || event.parent!=owner_ ||
           event.state!=1 || event.parentState!=2 || !event.uid || !event.name || std::strcmp(event.name,expected_)!=0) return;
        Copy(expected_,result_.name); result_.uid=event.uid; targetReady_=true;
    }
    bool Take(Accepted& output) {
        if(!active_ || !committed_ || !targetReady_) return false;
        output=result_; Cancel(); return true;
    }
    void Cancel() { *this=Tracker{}; }
};
}
