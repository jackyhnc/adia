import Testing
import Foundation
@testable import AdiCore

@Suite("SuggestedSessionTemplates")
struct SuggestedSessionTemplatesTests {

    @Test func catalogIsNonEmpty() {
        #expect(!SuggestedSessionTemplates.all.isEmpty)
    }

    @Test func allTemplatesHaveNonEmptyTask() {
        for t in SuggestedSessionTemplates.all {
            #expect(!t.task.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                    "template '\(t.task)' has empty task text")
        }
    }

    @Test func allTemplatesHaveNonEmptySuccessCriteria() {
        for t in SuggestedSessionTemplates.all {
            #expect(!t.successCriteria.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                    "template '\(t.task)' has empty successCriteria")
        }
    }

    @Test func allTemplatesHaveNonEmptyIcon() {
        for t in SuggestedSessionTemplates.all {
            #expect(!t.icon.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                    "template '\(t.task)' has empty icon name")
        }
    }

    @Test func allPositivePreferredDurationsWhenSet() {
        for t in SuggestedSessionTemplates.all {
            if let dur = t.preferredDuration {
                #expect(dur > 0,
                        "template '\(t.task)' has non-positive preferredDuration \(dur)")
            }
        }
    }

    @Test func displayCountDoesNotExceedCatalogSize() {
        #expect(SuggestedSessionTemplates.displayCount <= SuggestedSessionTemplates.all.count)
    }

    @Test func displayCountIsAtLeastOne() {
        #expect(SuggestedSessionTemplates.displayCount >= 1)
    }

    @Test func catalogContainsEssayTemplate() {
        let hasEssay = SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("essay") }
        #expect(hasEssay, "catalog should contain an essay-writing template")
    }

    @Test func catalogContainsCodingTemplate() {
        let hasCoding = SuggestedSessionTemplates.all.contains {
            let t = $0.task.lowercased()
            return t.contains("cod") || t.contains("project")
        }
        #expect(hasCoding, "catalog should contain a coding-project template")
    }

    @Test func taskTextsAreUnique() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let uniqueTasks = Set(tasks)
        #expect(tasks.count == uniqueTasks.count, "catalog has duplicate task texts")
    }
}
