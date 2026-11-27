#pragma once
#include "acceptance.h"

namespace QuestActivity {
struct CompletionContext {
    uintptr_t session{},actor{};
    bool operator==(const CompletionContext& other) const { return session==other.session && actor==other.actor; }
    bool Valid() const { return session && actor; }
};
struct CompletionTalk {
    CompletionContext context{};
    uintptr_t quest{},phase{},resource{};
    uint32_t uid{};
    uint64_t tick{};
};
struct CompletionTicket {
    CompletionTalk talk{};
    uintptr_t frame{};
};
class CompletionTracker {
    static constexpr unsigned capacity=32;
    static constexpr uint64_t maxTalkAge=1500;
    Accepted titles_[capacity]{};
    unsigned next_{};
    CompletionContext context_{};
    CompletionTalk observed_{};
    Accepted* Title(uint32_t uid) {
        if(uid) for(auto& title : titles_) if(title.uid==uid) return &title;
        return nullptr;
    }
public:
    void Reset() {
        for(auto& title : titles_) title.uid=0;
        observed_={}; context_={}; next_=0;
    }
    void Remember(CompletionContext context,const Accepted& entry) {
        if(!context.Valid() || !entry.uid || !entry.title[0]) return;
        if(!(context==context_)) { Reset(); context_=context; }
        auto title=Title(entry.uid);
        if(!title) { title=&titles_[next_]; next_=(next_+1)%capacity; }
        *title=entry;
    }
    bool Observe(const CompletionTalk& talk) {
        if(!(talk.context==context_) || !talk.quest || !talk.phase || !talk.resource || !Title(talk.uid)) return false;
        const auto changed=observed_.phase!=talk.phase || observed_.resource!=talk.resource || observed_.quest!=talk.quest;
        observed_=talk;
        return changed;
    }
    CompletionTalk Candidate() const { return observed_; }
    CompletionTicket Commit(const CompletionTalk& talk,uint64_t now,uintptr_t frame) {
        if(!talk.quest || !talk.phase || talk.quest!=observed_.quest || talk.phase!=observed_.phase) return {};
        const auto prior=observed_;
        observed_={};
        if(!frame || !(talk.context==context_) || !(talk.context==prior.context) ||
           !talk.resource || talk.resource!=prior.resource || talk.uid!=prior.uid || !Title(talk.uid) ||
           now<prior.tick || now-prior.tick>maxTalkAge) return {};
        return {prior,frame};
    }
    bool Finish(const CompletionTicket& ticket,CompletionContext context,uintptr_t quest,uint32_t uid,uintptr_t frame,Accepted& result) {
        if(!frame || ticket.frame!=frame || ticket.talk.quest!=quest || ticket.talk.uid!=uid ||
           !(context==context_) || !(context==ticket.talk.context)) return false;
        auto title=Title(uid);
        if(!title) return false;
        result=*title;
        title->uid=0;
        return true;
    }
};
}
