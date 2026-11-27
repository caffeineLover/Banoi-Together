#include "../poc/acceptance.h"
#include "../poc/completion.h"
#include <cstdio>
#include <cstring>
#include <cwchar>
#include <thread>

using namespace QuestActivity;
static unsigned failures;
#define CHECK(condition) do { if(!(condition)) { std::printf("FAIL line %u: %s\n", __LINE__, #condition); ++failures; } } while(0)

static Intent Offer(const wchar_t* title=L"Passport to Life") { return {0xA,0xB,0xC,title}; }
static TalkObservation Talk(const char* key="&ACT1A_WalkieTalkies_Name&") {
    return {0xA,0xB,0xC,0xD,0xE,"ACT1A_TalkToSinamoi01",32,key,1,true,true,true};
}
static StartObservation Start(const char* name="ACT1A_WalkieTalkies",unsigned uid=34) {
    return {0xF,0xE,name,uid,1,2,true};
}
static void PassportOrdering() {
    Tracker observer;
    CHECK(observer.Arm(Offer()));
    Accepted result{};
    CHECK(!observer.Take(result)); // Accept is input, not commit.
    CHECK(observer.Check(Talk()));
    CHECK(!observer.Take(result)); // Even Yes/ready is not commit.
    CHECK(observer.Commit(0xD,1,2,0xA,true));
    CHECK(!observer.Take(result)); // Correct child has not started.
    observer.Started(Start("__ACT1A_Bloody_man_Pool",33));
    CHECK(!observer.Take(result));
    observer.Started(Start());
    CHECK(observer.Take(result));
    CHECK(result.uid==34);
    CHECK(std::strcmp(result.name,"ACT1A_WalkieTalkies")==0);
    CHECK(std::wcscmp(result.title,L"Passport to Life")==0);
    observer.Started(Start("Steffen_Q1",372));
    observer.Started(Start());
    CHECK(!observer.Take(result)); // Repeated callbacks cannot repeat output.
}
static void ActiveOwner() {
    Tracker observer;
    observer.Arm(Offer(L"Where is Maggie?"));
    auto talk=Talk("&Steffen_Q1_Name&"); talk.ownerName="Steffen_Q1"; talk.ownerUid=372;
    CHECK(observer.Check(talk));
    Accepted result{};
    CHECK(!observer.Take(result));
    CHECK(observer.Commit(0xD,1,2,0xA,true));
    CHECK(observer.Take(result));
    CHECK(result.uid==372);
    CHECK(std::wcscmp(result.title,L"Where is Maggie?")==0);
}
static void RejectUnrelatedTalk() {
    for(unsigned variant=0;variant<9;++variant) {
        Tracker observer; observer.Arm(Offer()); auto talk=Talk();
        switch(variant) {
            case 0: talk.actor=0x99; break;
            case 1: talk.speaker=0x99; break;
            case 2: talk.resource=0x99; break;
            case 3: talk.ready=false; break;
            case 4: talk.positive=false; break;
            case 5: talk.normal=false; break;
            case 6: talk.phaseState=2; break;
            case 7: talk.titleKey="&ACT1A_WalkieTalkies_PaperLine_A&"; break;
            case 8: talk.titleKey="&ACT1A_WalkieTalkies_Name"; break;
        }
        CHECK(!observer.Check(talk));
        observer.Commit(0xD,1,2,0xA,true); observer.Started(Start());
        Accepted result{}; CHECK(!observer.Take(result));
    }
    Tracker unarmed; CHECK(!unarmed.Check(Talk()));
}
static void RejectUncommittedOrReplicated() {
    for(unsigned variant=0;variant<5;++variant) {
        Tracker observer; observer.Arm(Offer()); observer.Check(Talk());
        const auto phase=variant==0?0x99u:0xDu;
        const auto before=variant==1?2u:1u;
        const auto after=variant==2?1u:2u;
        const auto actor=variant==3?0x99u:0xAu;
        CHECK(!observer.Commit(phase,before,after,actor,variant!=4));
        observer.Started(Start()); Accepted result{}; CHECK(!observer.Take(result));
    }
}
static void RejectWrongChild() {
    for(unsigned variant=0;variant<5;++variant) {
        Tracker observer; observer.Arm(Offer()); observer.Check(Talk()); observer.Commit(0xD,1,2,0xA,true);
        auto start=Start();
        switch(variant) {
            case 0: start.parent=0x99; break;
            case 1: start.name="Steffen_Q1"; break;
            case 2: start.state=2; break;
            case 3: start.parentState=1; break;
            case 4: start.normal=false; break;
        }
        observer.Started(start); Accepted result{}; CHECK(!observer.Take(result));
    }
}
static void CancelAndLocalize() {
    Tracker observer; observer.Arm(Offer()); observer.Check(Talk()); observer.Cancel();
    observer.Commit(0xD,1,2,0xA,true); observer.Started(Start());
    Accepted result{}; CHECK(!observer.Take(result));
    CHECK(observer.Arm(Offer(L"Passeport pour la vie")));
    CHECK(observer.Check(Talk())); CHECK(observer.Commit(0xD,1,2,0xA,true));
    observer.Started(Start()); CHECK(observer.Take(result));
    CHECK(std::wcscmp(result.title,L"Passeport pour la vie")==0);
    CHECK(!observer.Arm(Offer(L"")));
}
static void AcrossThreads() {
    // Native UI input and later quest update occurred on different threads.
    Tracker observer;
    std::thread ui([&] { CHECK(observer.Arm(Offer())); }); ui.join();
    std::thread tick([&] {
        CHECK(observer.Check(Talk())); CHECK(observer.Commit(0xD,1,2,0xA,true)); observer.Started(Start());
    }); tick.join();
    Accepted result{}; CHECK(observer.Take(result)); CHECK(result.uid==34);
}
static void CompletionProof() {
    using namespace QuestActivity;
    const CompletionContext context{0x10,0x20};
    const CompletionTalk talk{context,0x30,0x40,0x50,352,1000};
    Accepted accepted{352,"ACT1A_BobbyAmbulatory",L"Bloody Health Service!"};
    CompletionTracker tracker;
    tracker.Remember(context,accepted);
    CHECK(tracker.Observe(talk));
    auto ticket=tracker.Commit(talk,1100,0x60);
    CHECK(ticket.frame==0x60);
    Accepted completed{};
    CHECK(!tracker.Finish(ticket,context,0x31,352,0x60,completed));
    CHECK(!tracker.Finish(ticket,context,0x30,352,0x61,completed));
    CHECK(!tracker.Finish(ticket,{0x10,0x21},0x30,352,0x60,completed));
    CHECK(tracker.Finish(ticket,context,0x30,352,0x60,completed));
    CHECK(std::wcscmp(completed.title,L"Bloody Health Service!")==0);
    CHECK(!tracker.Finish(ticket,context,0x30,352,0x60,completed));
}
static void CompletionRejectsStaleOrForeignTalk() {
    using namespace QuestActivity;
    const CompletionContext context{0x10,0x20};
    CompletionTalk talk{context,0x30,0x40,0x50,352,1000};
    Accepted accepted{352,"ACT1A_BobbyAmbulatory",L"Quest"};
    CompletionTracker tracker;
    CHECK(!tracker.Observe(talk));
    tracker.Remember(context,accepted);
    CHECK(tracker.Observe(talk));
    auto other=talk; other.context.actor=0x21;
    CHECK(!tracker.Commit(other,1100,0x60).frame);
    CHECK(tracker.Observe(talk));
    CHECK(!tracker.Commit(talk,62000,0x60).frame);
    CHECK(tracker.Observe(talk));
    other=talk; other.resource=0x51;
    CHECK(!tracker.Commit(other,1100,0x60).frame);
    CHECK(tracker.Observe(talk));
    tracker.Reset();
    CHECK(!tracker.Commit(talk,1100,0x60).frame);
}
int main() {
    PassportOrdering(); ActiveOwner(); RejectUnrelatedTalk(); RejectUncommittedOrReplicated();
    RejectWrongChild(); CancelAndLocalize(); AcrossThreads();
    CompletionProof(); CompletionRejectsStaleOrForeignTalk();
    if(failures) { std::printf("FAIL: %u acceptance assertions\n",failures); return 1; }
    std::puts("PASS: acceptance and completion correlation, ownership, native update identity, localized titles and single consumption");
    return 0;
}
