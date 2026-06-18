import Testing
import Foundation
@testable import AdiCore

@Suite("SessionRecord computed properties")
struct SessionRecordComputedTests {

    private func makeRecord(
        startTime: Date = Date(timeIntervalSince1970: 1000),
        endTime: Date = Date(timeIntervalSince1970: 2000),
        onTaskChecks: Int = 0,
        totalChecks: Int = 0,
        completedSuccessfully: Bool = true
    ) -> SessionRecord {
        SessionRecord(
            task: "Write essay",
            successCriteria: "Submit to Canvas",
            startTime: startTime,
            endTime: endTime,
            completedSuccessfully: completedSuccessfully,
            calloutCount: 0,
            onTaskChecks: onTaskChecks,
            totalChecks: totalChecks
        )
    }

    @Test func durationComputed() {
        let r = makeRecord(
            startTime: Date(timeIntervalSince1970: 1000),
            endTime: Date(timeIntervalSince1970: 4600)
        )
        #expect(r.duration == 3600)
    }

    @Test func durationZeroWhenSameTime() {
        let t = Date(timeIntervalSince1970: 5000)
        let r = makeRecord(startTime: t, endTime: t)
        #expect(r.duration == 0)
    }

    @Test func focusScoreNilWhenNoChecks() {
        let r = makeRecord(onTaskChecks: 0, totalChecks: 0)
        #expect(r.focusScore == nil)
    }

    @Test func focusScorePerfect() {
        let r = makeRecord(onTaskChecks: 10, totalChecks: 10)
        #expect(r.focusScore == 1.0)
    }

    @Test func focusScoreZero() {
        let r = makeRecord(onTaskChecks: 0, totalChecks: 10)
        #expect(r.focusScore == 0.0)
    }

    @Test func focusScorePartial() {
        let r = makeRecord(onTaskChecks: 3, totalChecks: 4)
        #expect(r.focusScore == 0.75)
    }

    @Test func focusScoreSingleCheck() {
        let r = makeRecord(onTaskChecks: 1, totalChecks: 1)
        #expect(r.focusScore == 1.0)
    }
}

@Suite("SessionRecord Codable")
struct SessionRecordCodableTests {

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .secondsSince1970
        return e
    }()

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .secondsSince1970
        return d
    }()

    @Test func roundTripPreservesAllFields() throws {
        let original = SessionRecord(
            task: "Study",
            successCriteria: "Pass quiz",
            startTime: Date(timeIntervalSince1970: 1000),
            endTime: Date(timeIntervalSince1970: 2000),
            completedSuccessfully: true,
            calloutCount: 3,
            note: "Good session",
            onTaskChecks: 8,
            totalChecks: 10,
            reasoningAttempts: 2,
            reasoningGranted: 1,
            blockedDomains: ["reddit.com", "twitter.com"],
            blockedApps: ["com.apple.TV"]
        )
        let data = try encoder.encode(original)
        let decoded = try decoder.decode(SessionRecord.self, from: data)

        #expect(decoded.id == original.id)
        #expect(decoded.task == original.task)
        #expect(decoded.successCriteria == original.successCriteria)
        #expect(decoded.startTime == original.startTime)
        #expect(decoded.endTime == original.endTime)
        #expect(decoded.completedSuccessfully == original.completedSuccessfully)
        #expect(decoded.calloutCount == original.calloutCount)
        #expect(decoded.note == original.note)
        #expect(decoded.onTaskChecks == original.onTaskChecks)
        #expect(decoded.totalChecks == original.totalChecks)
        #expect(decoded.reasoningAttempts == original.reasoningAttempts)
        #expect(decoded.reasoningGranted == original.reasoningGranted)
        #expect(decoded.blockedDomains == original.blockedDomains)
        #expect(decoded.blockedApps == original.blockedApps)
    }

    @Test func encodedJSONContainsFocusScoreAndDuration() throws {
        let r = SessionRecord(
            task: "t",
            successCriteria: "c",
            startTime: Date(timeIntervalSince1970: 0),
            endTime: Date(timeIntervalSince1970: 120),
            completedSuccessfully: true,
            calloutCount: 0,
            onTaskChecks: 7,
            totalChecks: 10
        )
        let data = try encoder.encode(r)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        #expect(json["durationSeconds"] as? Int == 120)
        #expect(json["focusScore"] as? Double == 0.7)
    }

    @Test func encodedJSONOmitsFocusScoreWhenNil() throws {
        let r = SessionRecord(
            task: "t",
            successCriteria: "c",
            startTime: Date(timeIntervalSince1970: 0),
            endTime: Date(timeIntervalSince1970: 60),
            completedSuccessfully: false,
            calloutCount: 0,
            onTaskChecks: 0,
            totalChecks: 0
        )
        let data = try encoder.encode(r)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        #expect(json["focusScore"] == nil)
        #expect(json["durationSeconds"] as? Int == 60)
    }

    @Test func backwardCompatMissingOptionalFields() throws {
        let json: [String: Any] = [
            "id": UUID().uuidString,
            "task": "Old task",
            "successCriteria": "Old criteria",
            "startTime": 1000.0,
            "endTime": 2000.0,
            "completedSuccessfully": true,
            "calloutCount": 5
        ]
        let data = try JSONSerialization.data(withJSONObject: json)
        let record = try decoder.decode(SessionRecord.self, from: data)
        #expect(record.note == nil)
        #expect(record.onTaskChecks == 0)
        #expect(record.totalChecks == 0)
        #expect(record.reasoningAttempts == 0)
        #expect(record.reasoningGranted == 0)
        #expect(record.blockedDomains.isEmpty)
        #expect(record.blockedApps.isEmpty)
        #expect(record.focusScore == nil)
    }

    @Test func noteNilWhenNotPresent() throws {
        let r = SessionRecord(
            task: "t",
            successCriteria: "c",
            startTime: Date(timeIntervalSince1970: 0),
            endTime: Date(timeIntervalSince1970: 1),
            completedSuccessfully: false,
            calloutCount: 0
        )
        let data = try encoder.encode(r)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        #expect(json["note"] == nil)
    }

    @Test func notePreservedWhenSet() throws {
        var r = SessionRecord(
            task: "t",
            successCriteria: "c",
            startTime: Date(timeIntervalSince1970: 0),
            endTime: Date(timeIntervalSince1970: 1),
            completedSuccessfully: false,
            calloutCount: 0,
            note: "My note"
        )
        r.note = "Updated note"
        let data = try encoder.encode(r)
        let decoded = try decoder.decode(SessionRecord.self, from: data)
        #expect(decoded.note == "Updated note")
    }
}

@Suite("SessionRecord identity")
struct SessionRecordIdentityTests {

    @Test func defaultIdIsUnique() {
        let a = SessionRecord(
            task: "t", successCriteria: "c",
            startTime: .now, endTime: .now,
            completedSuccessfully: true, calloutCount: 0
        )
        let b = SessionRecord(
            task: "t", successCriteria: "c",
            startTime: .now, endTime: .now,
            completedSuccessfully: true, calloutCount: 0
        )
        #expect(a.id != b.id)
    }

    @Test func explicitIdPreserved() {
        let fixed = UUID()
        let r = SessionRecord(
            id: fixed, task: "t", successCriteria: "c",
            startTime: .now, endTime: .now,
            completedSuccessfully: true, calloutCount: 0
        )
        #expect(r.id == fixed)
    }
}
