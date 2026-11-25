import AVFoundation
import XCTest
@testable import Ace

/// The voice call: the timer, talking over Ace, "call Ace", quiet calls, captions and the orb.
@MainActor
final class CallTests: XCTestCase {

    // MARK: Timer

    func testClockLooksLikeAPhone() {
        XCTAssertEqual(CallLogic.clock(0), "0:00")
        XCTAssertEqual(CallLogic.clock(7.9), "0:07")
        XCTAssertEqual(CallLogic.clock(65), "1:05")
        XCTAssertEqual(CallLogic.clock(12 * 60 + 30), "12:30")
        XCTAssertEqual(CallLogic.clock(3600 + 2 * 60 + 3), "1:02:03")
        XCTAssertEqual(CallLogic.clock(-5), "0:00")
    }

    func testLengthInWords() {
        XCTAssertEqual(CallLogic.lengthInWords(0), "0 seconds")
        XCTAssertEqual(CallLogic.lengthInWords(1), "1 second")
        XCTAssertEqual(CallLogic.lengthInWords(125), "2 minutes 5 seconds")
        XCTAssertEqual(CallLogic.lengthInWords(60), "1 minute")
        XCTAssertEqual(CallLogic.lengthInWords(3600 + 60), "1 hour 1 minute")
    }

    // MARK: Talking over Ace

    func testWords() {
        XCTAssertEqual(CallLogic.words("Wait, what?!"), ["wait", "what"])
        XCTAssertEqual(CallLogic.words("It's 72°F today."), ["it's", "72", "f", "today"])
        XCTAssertEqual(CallLogic.words("  "), [])
    }

    func testAceHearingItselfDoesNotInterrupt() {
        let ace = "The capital of France is Paris. It's famous for the Eiffel Tower."
        // The microphone picks up Ace's own voice: same words, so Ace keeps talking.
        XCTAssertFalse(CallLogic.shouldInterrupt(heard: "the capital of france is paris", aceSaying: ace))
        XCTAssertFalse(CallLogic.shouldInterrupt(heard: "Eiffel Tower", aceSaying: ace))
        XCTAssertFalse(CallLogic.shouldInterrupt(heard: "", aceSaying: ace))
        // One new word that isn't a stop word could be a mishearing.
        XCTAssertFalse(CallLogic.shouldInterrupt(heard: "the capital of france is paris um", aceSaying: ace))
    }

    func testTalkingOverAceInterrupts() {
        let ace = "The capital of France is Paris. It's famous for the Eiffel Tower."
        XCTAssertTrue(CallLogic.shouldInterrupt(heard: "what about Spain", aceSaying: ace))
        XCTAssertTrue(CallLogic.shouldInterrupt(heard: "the capital of france is paris what about spain", aceSaying: ace))
        XCTAssertTrue(CallLogic.shouldInterrupt(heard: "wait", aceSaying: ace))
        XCTAssertTrue(CallLogic.shouldInterrupt(heard: "Stop", aceSaying: ace))
        XCTAssertTrue(CallLogic.shouldInterrupt(heard: "hold on", aceSaying: ace))
        // A stop word Ace is saying itself doesn't count.
        XCTAssertFalse(CallLogic.shouldInterrupt(heard: "wait", aceSaying: "Wait for the oven to heat up."))
    }

    func testEchoIsTakenOutOfYourWords() {
        let ace = "The capital of France is Paris."
        XCTAssertEqual(CallLogic.userPart(heard: "the capital of France is Paris wait what about Spain", aceSaying: ace),
                       "wait what about Spain")
        XCTAssertEqual(CallLogic.userPart(heard: "What about Spain?", aceSaying: ace), "What about Spain")
        XCTAssertEqual(CallLogic.userPart(heard: "the capital is", aceSaying: ace), "")
        XCTAssertEqual(CallLogic.userPart(heard: "hello there", aceSaying: ""), "hello there")
        // Words after yours that happen to match Ace's stay in (only the echo at the start goes).
        XCTAssertEqual(CallLogic.userPart(heard: "Paris no what is the capital of Spain", aceSaying: ace),
                       "no what is the capital of Spain")
    }

    // MARK: Starting a call by voice

    func testCallAceWords() {
        XCTAssertTrue(CallLogic.saysCallAce("call Ace"))
        XCTAssertTrue(CallLogic.saysCallAce("Call ace please"))
        XCTAssertTrue(CallLogic.saysCallAce("um call a's"))
        XCTAssertFalse(CallLogic.saysCallAce("call mom"))
        XCTAssertFalse(CallLogic.saysCallAce("ace"))
        XCTAssertFalse(CallLogic.saysCallAce("I'm calling Ace later"))
        XCTAssertFalse(CallLogic.saysCallAce("hey ace"))
    }

    func testCallIntents() {
        let start = ["call Ace", "Call Ace please", "hey Ace, call Ace", "start a call", "start a voice call with me",
                     "let's have a call", "can we talk on the phone", "voice call", "phone call mode", "call",
                     "facetime ace", "Ace, start a call", "open the call screen", "call mode"]
        for text in start {
            if case .call(let on) = IntentRouter.parse(text) {
                XCTAssertTrue(on, text)
            } else {
                XCTFail("\"\(text)\" should start a call, got \(String(describing: IntentRouter.parse(text)))")
            }
        }
        let end = ["hang up", "end the call", "End call", "stop the call", "bye and hang up", "hang up now",
                   "okay hang up", "leave the call", "end this call ace"]
        for text in end {
            if case .call(let on) = IntentRouter.parse(text) {
                XCTAssertFalse(on, text)
            } else {
                XCTFail("\"\(text)\" should end a call, got \(String(describing: IntentRouter.parse(text)))")
            }
        }
        // These aren't calls to Ace.
        for text in ["call mom", "call me Sam", "what is a phone call", "call of duty", "I will call you later",
                     "stop calling me", "make a call to grandma", "the call of the wild", "end the game"] {
            if case .call = IntentRouter.parse(text) { XCTFail("\"\(text)\" isn't a call") }
        }
        if case .setName(let name) = IntentRouter.parse("call me Sam") {
            XCTAssertEqual(name, "sam")
        } else {
            XCTFail("\"call me Sam\" should still set your name")
        }
        if case .goodbye = IntentRouter.parse("bye") {} else { XCTFail("\"bye\" is still a goodbye") }
    }

    func testCallIsAnActionNotAQuestion() {
        XCTAssertEqual(Intent.call(true).kind, "call")
        XCTAssertTrue(Intent.call(true).isAction)
        XCTAssertTrue(Brain.notQuestions.contains("call"))
    }

    func testCallRepliesSayTheRightThing() {
        for line in Say.wordings(.callNotOn) {
            XCTAssertTrue(line.lowercased().contains("\"call ace\""), line)
        }
        let hello = Say.line(.callHello, ["who": ", Storm"])
        XCTAssertTrue(hello.contains(", Storm"), hello)
        let plain = Say.line(.callHello, ["who": ""])
        XCTAssertFalse(plain.contains("{"), plain)
        XCTAssertFalse(plain.contains(" !"), plain)
        for key in [ReplyKey.callStarting, .callAlready, .callBye, .callStillThere, .callQuietBye] {
            XCTAssertEqual(Say.wordings(key).count, 20, key.rawValue)
        }
    }

    // MARK: Quiet calls

    func testQuietCallsAskThenHangUp() {
        XCTAssertEqual(CallLogic.idleStep(silentFor: 10, nudged: false), .wait)
        XCTAssertEqual(CallLogic.idleStep(silentFor: CallLogic.nudgeAfter, nudged: false), .nudge)
        XCTAssertEqual(CallLogic.idleStep(silentFor: 5, nudged: true), .wait)
        XCTAssertEqual(CallLogic.idleStep(silentFor: CallLogic.hangUpAfter, nudged: true), .hangUp)
    }

    // MARK: Captions

    func testCaptionsShowTheLatestLinesAndWhatYouSayNow() {
        let lines = (0..<10).map { CallLogic.Caption(who: $0.isMultiple(of: 2) ? .you : .ace, text: "line \($0)") }
        let shown = CallLogic.captions(lines, live: "  what about ", keep: 4)
        XCTAssertEqual(shown.count, 5)
        XCTAssertEqual(shown.first?.text, "line 6")
        XCTAssertEqual(shown.last?.text, "what about")
        XCTAssertEqual(shown.last?.who, .you)
        XCTAssertEqual(shown.last?.live, true)
        XCTAssertEqual(shown.last?.id, CallLogic.liveID)
        XCTAssertEqual(CallLogic.captions(lines, live: "", keep: 4).count, 4)
    }

    func testCaptionTextIsTidy() {
        XCTAssertEqual(CallLogic.captionText("Here you go:\n• Eggs\n• Milk\n\n"), "Here you go: Eggs Milk")
        let long = String(repeating: "word ", count: 200)
        let cut = CallLogic.captionText(long, limit: 50)
        XCTAssertLessThanOrEqual(cut.count, 51)
        XCTAssertTrue(cut.hasSuffix("…"), cut)
    }

    // MARK: Screen

    func testPhases() {
        XCTAssertFalse(CallLogic.Phase.off.isLive)
        XCTAssertFalse(CallLogic.Phase.ended.isLive)
        for p in [CallLogic.Phase.connecting, .listening, .hearing, .thinking, .speaking] {
            XCTAssertTrue(p.isLive, p.rawValue)
            XCTAssertFalse(p.label.isEmpty, p.rawValue)
        }
        XCTAssertEqual(CallLogic.Phase.ended.label, "Call ended")
    }

    func testOrbFollowsTheCall() {
        XCTAssertEqual(CallLogic.orbMood(.hearing, ace: .idle), .listening)
        XCTAssertEqual(CallLogic.orbMood(.thinking, ace: .thinking), .thinking)
        XCTAssertEqual(CallLogic.orbMood(.speaking, ace: .idle), .talking)
        XCTAssertEqual(CallLogic.orbMood(.listening, ace: .idle), .idle)
        XCTAssertEqual(CallLogic.orbMood(.ended, ace: .happy), .sleeping)
        // A sassy eye-roll still shows on the call.
        XCTAssertEqual(CallLogic.orbMood(.speaking, ace: .checking), .checking)
    }

    func testANewCallStartsOff() {
        let call = CallController()
        XCTAssertEqual(call.phase, .off)
        XCTAssertFalse(call.isLive)
        XCTAssertTrue(call.captions.isEmpty)
        // The buttons do nothing without a call.
        call.toggleMute()
        call.hangUp()
        call.interrupt()
        XCTAssertFalse(call.muted)
        XCTAssertEqual(call.phase, .off)
    }

    // MARK: Ace's voice on a call

    func testCallUsesTheSameVoiceLines() {
        let parts = [SpokenPart(text: "Ugh, fine.", language: nil, sassy: true, drama: 3),
                     SpokenPart(text: "  ", language: nil),
                     SpokenPart(text: "It's 4.", language: nil)]
        let lines = VoiceOut.utterances(parts, voiceID: "")
        XCTAssertEqual(lines.count, 2)
        XCTAssertEqual(lines[0].speechString, "Ugh, fine.")
        XCTAssertEqual(lines[0].pitchMultiplier, VoiceOut.sassyStyle(drama: 3).pitch, accuracy: 0.001)
        XCTAssertEqual(lines[1].pitchMultiplier, 1.08, accuracy: 0.001)
    }

    func testWhatsNewShowsVoiceCalls() throws {
        let releases = WhatsNew.load()
        XCTAssertEqual(releases.first?.build, 58, "Newest first")
        let release = try XCTUnwrap(releases.first { $0.build == 58 })
        XCTAssertTrue(release.items.contains { $0.contains("call Ace") })
        XCTAssertEqual(WhatsNew.due(currentBuild: 58, lastShown: 57, releases: releases)?.build, 58)
    }

    func testAudioRouterHasACallMode() {
        // Outside a call, the speaker button does nothing and nothing crashes.
        AudioRouter.shared.callSpeaker(true)
        XCTAssertNotEqual(AudioRouter.shared.mode, .call)
    }
}
