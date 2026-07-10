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

    @Test func catalogHasAtLeastTwentyTemplates() {
        #expect(SuggestedSessionTemplates.all.count >= 20,
                "catalog should contain at least 20 templates for broad coverage")
    }

    @Test func catalogContainsPresentationTemplate() {
        let hasPresentation = SuggestedSessionTemplates.all.contains {
            $0.task.lowercased().contains("presentation") || $0.task.lowercased().contains("slides")
        }
        #expect(hasPresentation, "catalog should contain a presentation/slides template")
    }

    @Test func catalogContainsPodcastTemplate() {
        let hasPodcast = SuggestedSessionTemplates.all.contains {
            $0.task.lowercased().contains("podcast")
        }
        #expect(hasPodcast, "catalog should contain a podcast recording template")
    }

    @Test func catalogContainsDesignTemplate() {
        let hasDesign = SuggestedSessionTemplates.all.contains {
            let t = $0.task.lowercased()
            return t.contains("design") || t.contains("mockup") || t.contains("figma")
        }
        #expect(hasDesign, "catalog should contain a design/mockup template")
    }

    @Test func catalogContainsInterviewTemplate() {
        let hasInterview = SuggestedSessionTemplates.all.contains {
            $0.task.lowercased().contains("interview")
        }
        #expect(hasInterview, "catalog should contain an interview-prep template")
    }

    @Test func catalogContainsBlogOrWritingTemplate() {
        let hasBlog = SuggestedSessionTemplates.all.contains {
            let t = $0.task.lowercased()
            return t.contains("blog") || t.contains("post") || t.contains("newsletter")
        }
        #expect(hasBlog, "catalog should contain a blog-post or writing template")
    }

    @Test func catalogContainsThesisOrResearchTemplate() {
        let hasThesis = SuggestedSessionTemplates.all.contains {
            let t = $0.task.lowercased()
            return t.contains("thesis") || t.contains("research") || t.contains("paper")
        }
        #expect(hasThesis, "catalog should contain a thesis or research paper template")
    }

    @Test func catalogContainsFitnessOrWorkoutTemplate() {
        let hasFitness = SuggestedSessionTemplates.all.contains {
            let t = $0.task.lowercased()
            return t.contains("workout") || t.contains("exercise") || t.contains("gym") || t.contains("run")
        }
        #expect(hasFitness, "catalog should contain a fitness or workout template")
    }

    @Test func catalogContainsLanguageLearningTemplate() {
        let hasLanguage = SuggestedSessionTemplates.all.contains {
            let t = $0.task.lowercased()
            return t.contains("language") || t.contains("vocabulary") || t.contains("spanish")
                || t.contains("french") || t.contains("japanese") || t.contains("duolingo")
        }
        #expect(hasLanguage, "catalog should contain a language-learning template")
    }

    @Test func catalogContainsMusicPracticeTemplate() {
        let hasMusic = SuggestedSessionTemplates.all.contains {
            let t = $0.task.lowercased()
            return t.contains("music") || t.contains("instrument") || t.contains("piano")
                || t.contains("guitar") || t.contains("practice")
        }
        #expect(hasMusic, "catalog should contain a music or instrument practice template")
    }

    @Test func catalogContainsVideoEditingTemplate() {
        let hasVideo = SuggestedSessionTemplates.all.contains {
            let t = $0.task.lowercased()
            return t.contains("video") || t.contains("edit") || t.contains("footage")
        }
        #expect(hasVideo, "catalog should contain a video editing template")
    }

    @Test func catalogContainsBudgetTemplate() {
        let hasBudget = SuggestedSessionTemplates.all.contains {
            let t = $0.task.lowercased()
            return t.contains("budget") || t.contains("finance") || t.contains("spreadsheet")
        }
        #expect(hasBudget, "catalog should contain a budget or finance template")
    }

    @Test func catalogContainsCreativeWritingTemplate() {
        let hasCreative = SuggestedSessionTemplates.all.contains {
            let t = $0.task.lowercased()
            return t.contains("novel") || t.contains("chapter") || t.contains("fiction")
        }
        #expect(hasCreative, "catalog should contain a creative writing / novel template")
    }

    @Test func allTemplatesHaveValidSuccessCriteriaLength() {
        for t in SuggestedSessionTemplates.all {
            #expect(t.successCriteria.count >= 20,
                    "template '\(t.task)' has suspiciously short successCriteria: '\(t.successCriteria)'")
        }
    }

    // MARK: randomSuggestions

    @Test func randomSuggestionsRespectsCount() {
        let results = SuggestedSessionTemplates.randomSuggestions(count: 3)
        #expect(results.count == 3)
    }

    @Test func randomSuggestionsExcludesSpecifiedTasks() {
        let excluded = Set(SuggestedSessionTemplates.all.prefix(5).map(\.task))
        let results = SuggestedSessionTemplates.randomSuggestions(
            count: SuggestedSessionTemplates.all.count,
            excluding: excluded
        )
        for task in excluded {
            #expect(!results.map(\.task).contains(task),
                    "randomSuggestions should not return excluded task '\(task)'")
        }
    }

    @Test func randomSuggestionsCountCappedByCatalogSize() {
        let results = SuggestedSessionTemplates.randomSuggestions(count: 999)
        #expect(results.count == SuggestedSessionTemplates.all.count,
                "count > catalog should return all available templates")
    }

    @Test func randomSuggestionsReturnsEmptyWhenAllExcluded() {
        let allTasks = Set(SuggestedSessionTemplates.all.map(\.task))
        let results = SuggestedSessionTemplates.randomSuggestions(count: 3, excluding: allTasks)
        #expect(results.isEmpty, "all tasks excluded → result should be empty")
    }

    @Test func randomSuggestionsResultsAreUnique() {
        let results = SuggestedSessionTemplates.randomSuggestions(count: SuggestedSessionTemplates.all.count)
        let tasks = results.map(\.task)
        #expect(tasks.count == Set(tasks).count, "randomSuggestions should not return duplicate templates")
    }
}
