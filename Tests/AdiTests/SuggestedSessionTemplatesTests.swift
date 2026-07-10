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

    @Test func catalogHasAtLeastTwentyTwoTemplates() {
        #expect(SuggestedSessionTemplates.all.count >= 22,
                "catalog should contain at least 22 templates for broad coverage")
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

    @Test func catalogContainsEmailTemplate() {
        let hasEmail = SuggestedSessionTemplates.all.contains {
            let t = $0.task.lowercased()
            return t.contains("email") || t.contains("inbox")
        }
        #expect(hasEmail, "catalog should contain an email / inbox-zero template")
    }

    @Test func catalogContainsJobApplicationTemplate() {
        let hasJobApp = SuggestedSessionTemplates.all.contains {
            let t = $0.task.lowercased()
            return t.contains("job application") || t.contains("job apps") || t.contains("application")
        }
        #expect(hasJobApp, "catalog should contain a job-application template")
    }

    @Test func catalogContainsJournalingTemplate() {
        let hasJournaling = SuggestedSessionTemplates.all.contains {
            let t = $0.task.lowercased()
            return t.contains("journal")
        }
        #expect(hasJournaling, "catalog should contain a journaling template")
    }

    @Test func catalogContainsAudiobookTemplate() {
        let hasAudiobook = SuggestedSessionTemplates.all.contains {
            let t = $0.task.lowercased()
            return t.contains("audiobook") || t.contains("listen") || t.contains("annotate")
        }
        #expect(hasAudiobook, "catalog should contain an audiobook or listening template")
    }

    @Test func journalingTemplateHasReasonableDuration() {
        let journaling = SuggestedSessionTemplates.all.first {
            $0.task.lowercased().contains("journal")
        }
        if let t = journaling, let dur = t.preferredDuration {
            // Journal sessions should be under an hour — people don't journal for 2 hours
            #expect(dur <= 3600, "journaling template preferredDuration should be <= 60 minutes")
            #expect(dur >= 300, "journaling template preferredDuration should be >= 5 minutes")
        }
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

    @Test func catalogContainsCaseBriefTemplate() {
        let tasks = SuggestedSessionTemplates.all.map(\.task).map { $0.lowercased() }
        #expect(tasks.contains { $0.contains("brief") || $0.contains("case") },
                "catalog must include a legal/case-brief template")
    }

    @Test func catalogContainsBarExamTemplate() {
        let tasks = SuggestedSessionTemplates.all.map(\.task).map { $0.lowercased() }
        #expect(tasks.contains { $0.contains("bar") || $0.contains("bar exam") },
                "catalog must include a bar-exam prep template")
    }

    @Test func legalTemplatesHaveReasonableDuration() {
        let legalTemplates = SuggestedSessionTemplates.all.filter { t in
            let lower = t.task.lowercased()
            return lower.contains("brief") || lower.contains("bar")
        }
        #expect(!legalTemplates.isEmpty, "at least one legal template must exist")
        for template in legalTemplates {
            if let duration = template.preferredDuration {
                #expect(duration >= 5 * 60 && duration <= 3 * 60 * 60,
                        "legal template duration must be between 5 minutes and 3 hours")
            }
        }
    }

    @Test func catalogHasAtLeastTwentyFourTemplates() {
        #expect(SuggestedSessionTemplates.all.count >= 24,
                "catalog should have at least 24 templates after legal additions")
    }

    // MARK: - Pre-med templates

    @Test func catalogContainsMcatTemplate() {
        let tasks = SuggestedSessionTemplates.all.map(\.task).map { $0.lowercased() }
        #expect(tasks.contains { $0.contains("mcat") },
                "catalog must include an MCAT study template")
    }

    @Test func catalogContainsAnatomyTemplate() {
        let tasks = SuggestedSessionTemplates.all.map(\.task).map { $0.lowercased() }
        #expect(tasks.contains { $0.contains("anatomy") },
                "catalog must include an anatomy review template")
    }

    @Test func premedTemplatesHaveReasonableDuration() {
        let premedTemplates = SuggestedSessionTemplates.all.filter { t in
            let lower = t.task.lowercased()
            return lower.contains("mcat") || lower.contains("anatomy") || lower.contains("med school")
        }
        #expect(!premedTemplates.isEmpty, "at least one premed template must exist")
        for template in premedTemplates {
            if let duration = template.preferredDuration {
                #expect(duration >= 5 * 60 && duration <= 3 * 60 * 60,
                        "premed template duration must be between 5 minutes and 3 hours")
            }
        }
    }

    @Test func catalogHasAtLeastTwentySixTemplates() {
        #expect(SuggestedSessionTemplates.all.count >= 26,
                "catalog should have at least 26 templates after premed additions")
    }
}
