import Testing
import Foundation
@testable import AdiCore

@Suite("SessionTemplateStore")
struct SessionTemplateTests {

    // MARK: - Helpers

    private func makeStore() -> SessionTemplateStore {
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent("adia_template_test_\(UUID()).json")
        return SessionTemplateStore(fileURL: tmp)
    }

    // MARK: - Basic CRUD

    @Test func emptyStoreLoadsEmpty() async {
        let store = makeStore()
        let templates = await store.load()
        #expect(templates.isEmpty)
    }

    @Test func addedTemplateIsLoaded() async {
        let store = makeStore()
        await store.add(task: "Finish essay", successCriteria: "Submitted on Canvas")
        let templates = await store.load()
        #expect(templates.count == 1)
        #expect(templates[0].task == "Finish essay")
        #expect(templates[0].successCriteria == "Submitted on Canvas")
        #expect(templates[0].useCount == 0)
        #expect(templates[0].lastUsedAt == nil)
    }

    @Test func addMultipleTemplates() async {
        let store = makeStore()
        await store.add(task: "Task A", successCriteria: "Done A")
        await store.add(task: "Task B", successCriteria: "Done B")
        let templates = await store.load()
        #expect(templates.count == 2)
    }

    @Test func deleteRemovesTemplate() async {
        let store = makeStore()
        await store.add(task: "Task to delete", successCriteria: "")
        let before = await store.load()
        #expect(before.count == 1)
        let id = before[0].id
        await store.delete(id: id)
        let after = await store.load()
        #expect(after.isEmpty)
    }

    @Test func deleteUnknownIdIsNoOp() async {
        let store = makeStore()
        await store.add(task: "Keep me", successCriteria: "")
        await store.delete(id: UUID())
        let templates = await store.load()
        #expect(templates.count == 1)
    }

    // MARK: - Deduplication

    @Test func addingDuplicateTaskUpdatesCriteria() async {
        let store = makeStore()
        await store.add(task: "Write essay", successCriteria: "Old criteria")
        await store.add(task: "Write essay", successCriteria: "New criteria")
        let templates = await store.load()
        #expect(templates.count == 1)
        #expect(templates[0].successCriteria == "New criteria")
    }

    @Test func deduplicationIsCaseAndWhitespaceInsensitive() async {
        let store = makeStore()
        await store.add(task: "  Write Essay  ", successCriteria: "First")
        await store.add(task: "write essay",    successCriteria: "Second")
        let templates = await store.load()
        #expect(templates.count == 1)
        #expect(templates[0].successCriteria == "Second")
    }

    // MARK: - recordUse

    @Test func recordUseIncrementsCountAndSetsDate() async {
        let store = makeStore()
        await store.add(task: "Daily exercise", successCriteria: "30 min logged")
        let id = await store.load()[0].id
        await store.recordUse(id: id)
        let templates = await store.load()
        #expect(templates[0].useCount == 1)
        #expect(templates[0].lastUsedAt != nil)
    }

    @Test func recordUseMultipleTimes() async {
        let store = makeStore()
        await store.add(task: "Leetcode", successCriteria: "2 problems solved")
        let id = await store.load()[0].id
        await store.recordUse(id: id)
        await store.recordUse(id: id)
        await store.recordUse(id: id)
        let templates = await store.load()
        #expect(templates[0].useCount == 3)
    }

    @Test func recordUseOnUnknownIdIsNoOp() async {
        let store = makeStore()
        await store.add(task: "Task", successCriteria: "")
        await store.recordUse(id: UUID())
        let templates = await store.load()
        #expect(templates[0].useCount == 0)
    }

    // MARK: - Sorted order

    @Test func sortedReturnsNewestUsedFirst() async {
        let store = makeStore()
        await store.add(task: "Task A", successCriteria: "")
        await store.add(task: "Task B", successCriteria: "")
        let ids = await store.load().map { $0.id }
        // Record use on Task A — it should sort first now.
        await store.recordUse(id: ids.first(where: { _ in true })!)
        let sorted = await store.sorted()
        // The one with lastUsedAt set should be first.
        #expect(sorted[0].lastUsedAt != nil)
    }

    @Test func sortedPutsNeverUsedAfterUsed() async {
        let store = makeStore()
        await store.add(task: "Used",   successCriteria: "")
        await store.add(task: "Unused", successCriteria: "")
        let usedID = await store.load().first(where: { $0.task == "Used" })!.id
        await store.recordUse(id: usedID)
        let sorted = await store.sorted()
        #expect(sorted[0].task == "Used")
        #expect(sorted[1].task == "Unused")
    }

    // MARK: - update

    @Test func updateChangesBothFields() async {
        let store = makeStore()
        await store.add(task: "Original task", successCriteria: "Original criteria")
        let id = await store.load()[0].id
        await store.update(id: id, task: "Updated task", successCriteria: "Updated criteria")
        let templates = await store.load()
        #expect(templates.count == 1)
        #expect(templates[0].task == "Updated task")
        #expect(templates[0].successCriteria == "Updated criteria")
    }

    @Test func updatePreservesOtherFields() async {
        let store = makeStore()
        await store.add(task: "Task", successCriteria: "Criteria")
        let id = await store.load()[0].id
        await store.recordUse(id: id)
        await store.update(id: id, task: "New task", successCriteria: "New criteria")
        let templates = await store.load()
        #expect(templates[0].id == id)
        #expect(templates[0].useCount == 1)
        #expect(templates[0].lastUsedAt != nil)
    }

    @Test func updateUnknownIdIsNoOp() async {
        let store = makeStore()
        await store.add(task: "Keep me", successCriteria: "Original")
        await store.update(id: UUID(), task: "Changed", successCriteria: "Changed criteria")
        let templates = await store.load()
        #expect(templates.count == 1)
        #expect(templates[0].task == "Keep me")
        #expect(templates[0].successCriteria == "Original")
    }

    @Test func updateDoesNotAffectOtherTemplates() async {
        let store = makeStore()
        await store.add(task: "Task A", successCriteria: "Criteria A")
        await store.add(task: "Task B", successCriteria: "Criteria B")
        let templates = await store.load()
        let idA = templates.first(where: { $0.task == "Task A" })!.id
        await store.update(id: idA, task: "Task A updated", successCriteria: "Criteria A updated")
        let after = await store.load()
        let b = after.first(where: { $0.task == "Task B" })
        #expect(b != nil)
        #expect(b?.successCriteria == "Criteria B")
    }

    // MARK: - Max templates limit

    @Test func exceedingMaxTemplatesTrimsToLimit() async {
        let store = makeStore()
        for i in 1...12 {
            await store.add(task: "Task \(i)", successCriteria: "Criteria \(i)")
        }
        let templates = await store.load()
        #expect(templates.count == SessionTemplateStore.maxTemplates)
    }

    // MARK: - Codable round-trip

    @Test func templateSurvivesRoundTrip() async {
        let store = makeStore()
        await store.add(task: "Read chapter 5", successCriteria: "Can summarize main ideas")
        let loaded = await store.load()
        #expect(loaded[0].task == "Read chapter 5")
        #expect(loaded[0].successCriteria == "Can summarize main ideas")
        #expect(loaded[0].useCount == 0)
    }

    // MARK: - Prepend on add

    @Test func addPrependsNewTemplateAtFront() async {
        let store = makeStore()
        await store.add(task: "Task A", successCriteria: "")
        await store.add(task: "Task B", successCriteria: "")
        let loaded = await store.load()
        // B was added last so it should be at index 0 (front of display order).
        #expect(loaded[0].task == "Task B")
        #expect(loaded[1].task == "Task A")
    }

    // MARK: - Reorder

    @Test func reorderMovesItemToFront() async {
        let store = makeStore()
        await store.add(task: "Task A", successCriteria: "")
        await store.add(task: "Task B", successCriteria: "")
        await store.add(task: "Task C", successCriteria: "")
        // After prepend-adds, load order is [C, B, A].
        // Move item at index 2 (A) to front (offset 0).
        await store.reorder(fromOffsets: IndexSet(integer: 2), toOffset: 0)
        let loaded = await store.load()
        #expect(loaded[0].task == "Task A")
        #expect(loaded[1].task == "Task C")
        #expect(loaded[2].task == "Task B")
    }

    @Test func reorderIsPersisted() async {
        let store = makeStore()
        await store.add(task: "First", successCriteria: "")
        await store.add(task: "Second", successCriteria: "")
        // After prepend-adds, load order is [Second, First].
        // Move First (index 1) to front (offset 0).
        await store.reorder(fromOffsets: IndexSet(integer: 1), toOffset: 0)
        // Load again — a fresh read should reflect the persisted order.
        let loaded = await store.load()
        #expect(loaded[0].task == "First")
        #expect(loaded[1].task == "Second")
    }

    @Test func reorderOnSingleItemIsNoOp() async {
        let store = makeStore()
        await store.add(task: "Only one", successCriteria: "")
        await store.reorder(fromOffsets: IndexSet(integer: 0), toOffset: 0)
        let loaded = await store.load()
        #expect(loaded.count == 1)
        #expect(loaded[0].task == "Only one")
    }

    @Test func reorderPreservesTemplateFields() async {
        let store = makeStore()
        await store.add(task: "Task A", successCriteria: "Criteria A")
        await store.add(task: "Task B", successCriteria: "Criteria B")
        let idA = await store.load().first(where: { $0.task == "Task A" })!.id
        // Load order is [B, A]. Move A to front.
        await store.reorder(fromOffsets: IndexSet(integer: 1), toOffset: 0)
        let loaded = await store.load()
        #expect(loaded[0].task == "Task A")
        #expect(loaded[0].id == idA)
        #expect(loaded[0].successCriteria == "Criteria A")
    }

    // MARK: - Preferred duration

    @Test func addWithPreferredDurationStoresIt() async {
        let store = makeStore()
        await store.add(task: "Write essay", successCriteria: "Submitted", preferredDuration: 2700)
        let templates = await store.load()
        #expect(templates[0].preferredDuration == 2700)
    }

    @Test func addWithoutPreferredDurationDefaultsToNil() async {
        let store = makeStore()
        await store.add(task: "Quick task", successCriteria: "Done")
        let templates = await store.load()
        #expect(templates[0].preferredDuration == nil)
    }

    @Test func addDuplicateTaskUpdatesPreferredDuration() async {
        let store = makeStore()
        await store.add(task: "Essay", successCriteria: "Submitted", preferredDuration: 2700)
        await store.add(task: "Essay", successCriteria: "Submitted", preferredDuration: 5400)
        let templates = await store.load()
        #expect(templates.count == 1)
        #expect(templates[0].preferredDuration == 5400)
    }

    @Test func addDuplicateTaskClearsPreferredDurationWhenNil() async {
        let store = makeStore()
        await store.add(task: "Essay", successCriteria: "Submitted", preferredDuration: 2700)
        await store.add(task: "Essay", successCriteria: "Submitted", preferredDuration: nil)
        let templates = await store.load()
        #expect(templates.count == 1)
        #expect(templates[0].preferredDuration == nil)
    }

    @Test func updateWithPreferredDurationStoresIt() async {
        let store = makeStore()
        await store.add(task: "Task", successCriteria: "Criteria")
        let id = await store.load()[0].id
        await store.update(id: id, task: "Task", successCriteria: "Criteria", preferredDuration: 3600)
        let templates = await store.load()
        #expect(templates[0].preferredDuration == 3600)
    }

    @Test func preferredDurationSurvivesCodecRoundTrip() async {
        let store = makeStore()
        await store.add(task: "Study session", successCriteria: "Notes done", preferredDuration: 4500)
        let loaded = await store.load()
        #expect(loaded[0].preferredDuration == 4500)
    }

    @Test func legacyJSONWithoutPreferredDurationDecodesAsNil() throws {
        // JSON that a previous agent wrote — no preferredDuration key.
        let json = """
        [{"id":"00000000-0000-0000-0000-000000000001","task":"Write paper","successCriteria":"Submitted","useCount":2,"lastUsedAt":null,"createdAt":700000000.0}]
        """
        let data = try #require(json.data(using: .utf8))
        let templates = try JSONDecoder().decode([SessionTemplate].self, from: data)
        #expect(templates.count == 1)
        #expect(templates[0].preferredDuration == nil)
    }

    @Test func updateWithNilPreferredDurationClearsStoredValue() async {
        // Regression: EditTemplateSheet previously called update without preferredDuration,
        // which silently reset the stored duration to nil on every edit save.
        // This test verifies the store correctly accepts nil and overwrites an existing value.
        let store = makeStore()
        await store.add(task: "Study", successCriteria: "Notes done", preferredDuration: 3600)
        let id = await store.load()[0].id
        await store.update(id: id, task: "Study", successCriteria: "Notes done", preferredDuration: nil)
        let templates = await store.load()
        #expect(templates[0].preferredDuration == nil)
    }

    @Test func updatePersistsAllThreeFieldsTogether() async {
        // Full round-trip through the edit sheet code path: task + criteria + duration.
        let store = makeStore()
        await store.add(task: "Original", successCriteria: "Old", preferredDuration: nil)
        let id = await store.load()[0].id
        await store.update(id: id, task: "Revised task", successCriteria: "Revised criteria", preferredDuration: 2700)
        let templates = await store.load()
        #expect(templates[0].task == "Revised task")
        #expect(templates[0].successCriteria == "Revised criteria")
        #expect(templates[0].preferredDuration == 2700)
    }

    @Test func updatePreservesDurationWhenPassedThrough() async {
        // Simulates the fixed EditTemplateSheet behavior: reading stored duration,
        // keeping it as-is, and passing it back through update.
        let store = makeStore()
        await store.add(task: "Task", successCriteria: "Criteria", preferredDuration: 5400)
        let template = await store.load()[0]
        // EditTemplateSheet reads template.preferredDuration and passes it back unchanged.
        await store.update(id: template.id, task: "Task (edited)", successCriteria: "Criteria",
                           preferredDuration: template.preferredDuration)
        let reloaded = await store.load()
        #expect(reloaded[0].preferredDuration == 5400)
    }
}
