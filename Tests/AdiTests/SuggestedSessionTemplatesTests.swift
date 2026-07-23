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

    // MARK: - Architecture templates

    @Test func catalogContainsArchitectureStudioTemplate() {
        let tasks = SuggestedSessionTemplates.all.map(\.task).map { $0.lowercased() }
        #expect(tasks.contains { $0.contains("architecture") || $0.contains("studio") },
                "catalog must include an architecture studio template")
    }

    @Test func catalogContainsArchitectureLicensingTemplate() {
        let tasks = SuggestedSessionTemplates.all.map(\.task).map { $0.lowercased() }
        #expect(tasks.contains { $0.contains("licensing") || $0.contains("are") || $0.contains("architecture exam") },
                "catalog must include an architecture licensing exam template")
    }

    @Test func architectureTemplatesHaveReasonableDuration() {
        let archTemplates = SuggestedSessionTemplates.all.filter { t in
            let lower = t.task.lowercased()
            return lower.contains("architecture") || lower.contains("studio")
        }
        #expect(!archTemplates.isEmpty, "at least one architecture template must exist")
        for template in archTemplates {
            if let duration = template.preferredDuration {
                #expect(duration >= 5 * 60 && duration <= 3 * 60 * 60,
                        "architecture template duration must be between 5 minutes and 3 hours")
            }
        }
    }

    @Test func catalogHasAtLeastTwentyEightTemplates() {
        #expect(SuggestedSessionTemplates.all.count >= 28,
                "catalog should have at least 28 templates after architecture additions")
    }

    // MARK: - Startup templates

    @Test func catalogContainsPitchDeckTemplate() {
        let tasks = SuggestedSessionTemplates.all.map(\.task).map { $0.lowercased() }
        #expect(tasks.contains { $0.contains("pitch") || $0.contains("pitch deck") },
                "catalog must include a pitch deck template")
    }

    @Test func catalogContainsBusinessPlanTemplate() {
        let tasks = SuggestedSessionTemplates.all.map(\.task).map { $0.lowercased() }
        #expect(tasks.contains { $0.contains("business plan") || $0.contains("business") },
                "catalog must include a business plan template")
    }

    @Test func startupTemplatesHaveReasonableDuration() {
        let startupTemplates = SuggestedSessionTemplates.all.filter { t in
            let lower = t.task.lowercased()
            return lower.contains("pitch") || lower.contains("business plan") || lower.contains("startup")
        }
        #expect(!startupTemplates.isEmpty, "at least one startup template must exist")
        for template in startupTemplates {
            if let duration = template.preferredDuration {
                #expect(duration >= 5 * 60 && duration <= 3 * 60 * 60,
                        "startup template duration must be between 5 minutes and 3 hours")
            }
        }
    }

    @Test func catalogHasAtLeastThirtyTemplates() {
        #expect(SuggestedSessionTemplates.all.count >= 30,
                "catalog should have at least 30 templates after startup additions")
    }

    @Test func catalogContainsNursingCarePlanTemplate() {
        let hasCarePlan = SuggestedSessionTemplates.all.contains { t in
            t.task.lowercased().contains("care plan") || t.task.lowercased().contains("nursing")
        }
        #expect(hasCarePlan, "catalog must include a nursing care plan template")
    }

    @Test func catalogContainsDosageCalcTemplate() {
        let hasDosage = SuggestedSessionTemplates.all.contains { t in
            t.task.lowercased().contains("dosage") || t.task.lowercased().contains("medication")
                || t.task.lowercased().contains("med calc")
        }
        #expect(hasDosage, "catalog must include a dosage calculation template")
    }

    @Test func nursingTemplatesHaveReasonableDuration() {
        let nursingTemplates = SuggestedSessionTemplates.all.filter { t in
            let lower = t.task.lowercased()
            return lower.contains("care plan") || lower.contains("dosage") || lower.contains("nursing")
        }
        #expect(!nursingTemplates.isEmpty, "at least one nursing template must exist")
        for template in nursingTemplates {
            if let duration = template.preferredDuration {
                #expect(duration >= 5 * 60 && duration <= 3 * 60 * 60,
                        "nursing template duration must be between 5 minutes and 3 hours")
            }
        }
    }

    @Test func catalogHasAtLeastThirtyTwoTemplates() {
        #expect(SuggestedSessionTemplates.all.count >= 32,
                "catalog should have at least 32 templates after nursing additions")
    }

    // MARK: - Photography templates

    @Test func catalogContainsPhotoEditingTemplate() {
        let hasPhotoEdit = SuggestedSessionTemplates.all.contains { t in
            let lower = t.task.lowercased()
            return lower.contains("photo") && (lower.contains("edit") || lower.contains("export"))
        }
        #expect(hasPhotoEdit, "catalog must include a photo editing template")
    }

    @Test func catalogContainsPhotographyPracticeTemplate() {
        let hasPractice = SuggestedSessionTemplates.all.contains { t in
            let lower = t.task.lowercased()
            return lower.contains("photo") || lower.contains("photograph")
        }
        #expect(hasPractice, "catalog must include a photography practice template")
    }

    @Test func photographyTemplatesHaveReasonableDuration() {
        let photoTemplates = SuggestedSessionTemplates.all.filter { t in
            let lower = t.task.lowercased()
            return lower.contains("photo") || lower.contains("photograph") || lower.contains("lightroom")
        }
        #expect(!photoTemplates.isEmpty, "at least one photography template must exist")
        for template in photoTemplates {
            if let dur = template.preferredDuration {
                #expect(dur >= 5 * 60 && dur <= 3 * 60 * 60,
                            "photography template duration must be between 5 minutes and 3 hours")
            }
        }
    }

    @Test func catalogHasAtLeastThirtyFourTemplates() {
        #expect(SuggestedSessionTemplates.all.count >= 34,
                "catalog should have at least 34 templates after photography additions")
    }

    // MARK: - Data science / ML templates

    @Test func catalogContainsMLModelTemplate() {
        let hasML = SuggestedSessionTemplates.all.contains { t in
            let lower = t.task.lowercased()
            return lower.contains("machine learning") || lower.contains("model")
        }
        #expect(hasML, "catalog must include a machine learning / model template")
    }

    @Test func catalogContainsKaggleTemplate() {
        let hasKaggle = SuggestedSessionTemplates.all.contains { t in
            let lower = t.task.lowercased()
            return lower.contains("kaggle") || lower.contains("data science") || lower.contains("notebook")
        }
        #expect(hasKaggle, "catalog must include a Kaggle / data science notebook template")
    }

    @Test func datascienceTemplatesHaveReasonableDuration() {
        let dsTemplates = SuggestedSessionTemplates.all.filter { t in
            let lower = t.task.lowercased()
            return lower.contains("machine learning") || lower.contains("kaggle")
                || lower.contains("model") || lower.contains("notebook")
        }
        #expect(!dsTemplates.isEmpty, "at least one data science template must exist")
        for template in dsTemplates {
            if let dur = template.preferredDuration {
                #expect(dur >= 5 * 60 && dur <= 3 * 60 * 60,
                            "data science template duration must be between 5 minutes and 3 hours")
            }
        }
    }

    @Test func catalogHasAtLeastThirtySixTemplates() {
        #expect(SuggestedSessionTemplates.all.count >= 36,
                "catalog should have at least 36 templates after data science additions")
    }

    // MARK: - Game dev templates

    @Test func catalogContainsGameDevBuildTemplate() {
        let has = SuggestedSessionTemplates.all.contains { t in
            let lower = t.task.lowercased()
            return lower.contains("game") && (lower.contains("unity") || lower.contains("godot")
                || lower.contains("build") || lower.contains("engine"))
        }
        #expect(has, "catalog must include a game-engine build template")
    }

    @Test func catalogContainsGameDesignDocTemplate() {
        let has = SuggestedSessionTemplates.all.contains { t in
            let lower = t.task.lowercased()
            return lower.contains("game design") || lower.contains("game design document")
        }
        #expect(has, "catalog must include a game design document template")
    }

    @Test func gamedevTemplatesHaveReasonableDuration() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            let lower = t.task.lowercased()
            return lower.contains("game") && (lower.contains("unity") || lower.contains("godot")
                || lower.contains("design document") || lower.contains("build"))
        }
        #expect(!templates.isEmpty, "at least one game dev template must exist")
        for t in templates {
            if let dur = t.preferredDuration {
                #expect(dur >= 5 * 60 && dur <= 3 * 60 * 60,
                        "game dev template duration must be between 5 min and 3 hours")
            }
        }
    }

    @Test func catalogHasAtLeastFortyTwoTemplates() {
        #expect(SuggestedSessionTemplates.all.count >= 42,
                "catalog should have at least 42 templates after gamedev/engineering/therapy additions")
    }

    // MARK: - Engineering templates

    @Test func catalogContainsEngineeringProblemSetTemplate() {
        let has = SuggestedSessionTemplates.all.contains { t in
            let lower = t.task.lowercased()
            return lower.contains("engineering") && lower.contains("problem set")
        }
        #expect(has, "catalog must include an engineering problem set template")
    }

    @Test func catalogContainsCADTemplate() {
        let has = SuggestedSessionTemplates.all.contains { t in
            let lower = t.task.lowercased()
            return lower.contains("cad") || lower.contains("technical drawing")
        }
        #expect(has, "catalog must include a CAD/technical drawing template")
    }

    @Test func engineeringTemplatesHaveReasonableDuration() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            let lower = t.task.lowercased()
            return lower.contains("engineering") || lower.contains("cad") || lower.contains("technical drawing")
        }
        #expect(!templates.isEmpty, "at least one engineering template must exist")
        for t in templates {
            if let dur = t.preferredDuration {
                #expect(dur >= 5 * 60 && dur <= 3 * 60 * 60,
                        "engineering template duration must be between 5 min and 3 hours")
            }
        }
    }

    // MARK: - Therapy templates

    @Test func catalogContainsTherapyNotesTemplate() {
        let has = SuggestedSessionTemplates.all.contains { t in
            let lower = t.task.lowercased()
            return lower.contains("therapy") || lower.contains("session notes") || lower.contains("case notes")
        }
        #expect(has, "catalog must include a therapy notes template")
    }

    @Test func catalogContainsCBTTemplate() {
        let has = SuggestedSessionTemplates.all.contains { t in
            let lower = t.task.lowercased()
            return lower.contains("cbt") || lower.contains("treatment plan")
        }
        #expect(has, "catalog must include a CBT/treatment planning template")
    }

    @Test func therapyTemplatesHaveReasonableDuration() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            let lower = t.task.lowercased()
            return lower.contains("therapy") || lower.contains("cbt") || lower.contains("treatment")
        }
        #expect(!templates.isEmpty, "at least one therapy template must exist")
        for t in templates {
            if let dur = t.preferredDuration {
                #expect(dur >= 5 * 60 && dur <= 3 * 60 * 60,
                        "therapy template duration must be between 5 min and 3 hours")
            }
        }
    }

    // MARK: - Social science templates

    @Test func catalogContainsPoliticalScienceTemplate() {
        let has = SuggestedSessionTemplates.all.contains { t in
            let lower = t.task.lowercased()
            return lower.contains("political science") || lower.contains("sociology")
        }
        #expect(has, "catalog must include a political science/sociology template")
    }

    @Test func catalogContainsLSATTemplate() {
        let has = SuggestedSessionTemplates.all.contains { t in
            t.task.lowercased().contains("lsat")
        }
        #expect(has, "catalog must include an LSAT template")
    }

    @Test func socialScienceTemplatesHaveReasonableDuration() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            let lower = t.task.lowercased()
            return lower.contains("political science") || lower.contains("lsat")
        }
        #expect(!templates.isEmpty, "at least one social science template must exist")
        for t in templates {
            if let dur = t.preferredDuration {
                #expect(dur >= 5 * 60 && dur <= 3 * 60 * 60,
                        "social science template duration must be between 5 min and 3 hours")
            }
        }
    }

    // MARK: - Nutrition templates

    @Test func catalogContainsDieteticsTemplate() {
        let has = SuggestedSessionTemplates.all.contains { t in
            let lower = t.task.lowercased()
            return lower.contains("dietetics") || lower.contains("food science")
        }
        #expect(has, "catalog must include a dietetics/food science template")
    }

    @Test func catalogContainsNutritionTrackingTemplate() {
        let has = SuggestedSessionTemplates.all.contains { t in
            let lower = t.task.lowercased()
            return lower.contains("nutrition") && lower.contains("track")
        }
        #expect(has, "catalog must include a nutrition tracking template")
    }

    @Test func nutritionTemplatesHaveReasonableDuration() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            let lower = t.task.lowercased()
            return lower.contains("dietetics") || lower.contains("nutrition")
        }
        #expect(!templates.isEmpty, "at least one nutrition template must exist")
        for t in templates {
            if let dur = t.preferredDuration {
                #expect(dur >= 5 * 60 && dur <= 3 * 60 * 60,
                        "nutrition template duration must be between 5 min and 3 hours")
            }
        }
    }

    @Test func catalogHasAtLeastFortyFiveTemplates() {
        #expect(SuggestedSessionTemplates.all.count >= 45,
                "catalog should have ≥45 templates after social science + nutrition additions")
    }

    // MARK: - Culinary templates

    @Test func catalogContainsRecipeDevelopmentTemplate() {
        let has = SuggestedSessionTemplates.all.contains { t in
            let lower = t.task.lowercased()
            return lower.contains("recipe") || lower.contains("culinary")
        }
        #expect(has, "catalog must include a recipe development or culinary template")
    }

    @Test func catalogContainsCulinaryStudyTemplate() {
        let has = SuggestedSessionTemplates.all.contains { t in
            let lower = t.task.lowercased()
            return (lower.contains("culinary") && lower.contains("exam"))
                || (lower.contains("culinary") && lower.contains("study"))
        }
        #expect(has, "catalog must include a culinary exam/study template")
    }

    @Test func culinaryTemplatesHaveReasonableDuration() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            let lower = t.task.lowercased()
            return lower.contains("recipe") || lower.contains("culinary")
        }
        #expect(!templates.isEmpty, "at least one culinary template must exist")
        for t in templates {
            if let dur = t.preferredDuration {
                #expect(dur >= 5 * 60 && dur <= 3 * 60 * 60,
                        "culinary template duration must be between 5 min and 3 hours")
            }
        }
    }

    // MARK: - Philosophy templates

    @Test func catalogContainsPhilosophyArgumentTemplate() {
        let has = SuggestedSessionTemplates.all.contains { t in
            let lower = t.task.lowercased()
            return lower.contains("philosoph") && (lower.contains("argument") || lower.contains("response"))
        }
        #expect(has, "catalog must include a philosophical argument/response template")
    }

    @Test func catalogContainsPhilosophyReadingTemplate() {
        let has = SuggestedSessionTemplates.all.contains { t in
            let lower = t.task.lowercased()
            return lower.contains("philosoph") && lower.contains("read")
        }
        #expect(has, "catalog must include a philosophy reading template")
    }

    @Test func philosophyTemplatesHaveReasonableDuration() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("philosoph")
        }
        #expect(!templates.isEmpty, "at least one philosophy template must exist")
        for t in templates {
            if let dur = t.preferredDuration {
                #expect(dur >= 5 * 60 && dur <= 3 * 60 * 60,
                        "philosophy template duration must be between 5 min and 3 hours")
            }
        }
    }

    @Test func catalogHasAtLeastFiftyTemplates() {
        #expect(SuggestedSessionTemplates.all.count >= 50,
                "catalog should have ≥50 templates after culinary + philosophy additions")
    }

    // MARK: - Music production / theory + environmental science templates

    @Test func catalogContainsMusicProductionTemplate() {
        let has = SuggestedSessionTemplates.all.contains { t in
            let lower = t.task.lowercased()
            return lower.contains("daw") || lower.contains("produce") || lower.contains("mix")
        }
        #expect(has, "catalog must include a music production template")
    }

    @Test func catalogContainsMusicTheoryTemplate() {
        let has = SuggestedSessionTemplates.all.contains { t in
            let lower = t.task.lowercased()
            return lower.contains("ear training") || lower.contains("music theory")
        }
        #expect(has, "catalog must include a music theory / ear training template")
    }

    @Test func musicTemplatesHaveReasonableDuration() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            let lower = t.task.lowercased()
            return lower.contains("daw") || lower.contains("ear training") || lower.contains("music theory")
        }
        #expect(!templates.isEmpty, "at least one music production/theory template must exist")
        for t in templates {
            if let dur = t.preferredDuration {
                #expect(dur >= 5 * 60 && dur <= 3 * 60 * 60,
                        "music template duration must be between 5 min and 3 hours")
            }
        }
    }

    @Test func catalogContainsEnviroFieldReportTemplate() {
        let has = SuggestedSessionTemplates.all.contains { t in
            let lower = t.task.lowercased()
            return (lower.contains("ecology") || lower.contains("environmental")) && lower.contains("report")
        }
        #expect(has, "catalog must include an environmental science field report template")
    }

    @Test func catalogContainsEnviroExamTemplate() {
        let has = SuggestedSessionTemplates.all.contains { t in
            let lower = t.task.lowercased()
            return lower.contains("environmental science") && lower.contains("exam")
        }
        #expect(has, "catalog must include an environmental science exam study template")
    }

    @Test func enviroTemplatesHaveReasonableDuration() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            let lower = t.task.lowercased()
            return lower.contains("ecology") || lower.contains("environmental science")
        }
        #expect(!templates.isEmpty, "at least one enviro template must exist")
        for t in templates {
            if let dur = t.preferredDuration {
                #expect(dur >= 5 * 60 && dur <= 3 * 60 * 60,
                        "enviro template duration must be between 5 min and 3 hours")
            }
        }
    }

    @Test func catalogHasAtLeastFiftyFourTemplates() {
        #expect(SuggestedSessionTemplates.all.count >= 54,
                "catalog should have ≥54 templates after music split + enviro additions")
    }

    // MARK: - Finance templates

    @Test func catalogContainsFinanceModelingTemplate() {
        let has = SuggestedSessionTemplates.all.contains { t in
            let lower = t.task.lowercased()
            return lower.contains("financial") && (lower.contains("model") || lower.contains("analysis"))
        }
        #expect(has, "catalog must include a financial modeling/analysis template")
    }

    @Test func catalogContainsCPACFATemplate() {
        let has = SuggestedSessionTemplates.all.contains { t in
            let lower = t.task.lowercased()
            return (lower.contains("cpa") || lower.contains("cfa")) && lower.contains("exam")
        }
        #expect(has, "catalog must include a CPA or CFA exam study template")
    }

    @Test func financeTemplatesHaveReasonableDuration() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            let lower = t.task.lowercased()
            return lower.contains("financial") || lower.contains("cpa") || lower.contains("cfa")
        }
        #expect(!templates.isEmpty, "at least one finance template must exist")
        for t in templates {
            if let dur = t.preferredDuration {
                #expect(dur >= 5 * 60 && dur <= 3 * 60 * 60,
                        "finance template duration must be between 5 min and 3 hours")
            }
        }
    }

    // MARK: - Policy templates

    @Test func catalogContainsPolicyMemoTemplate() {
        let has = SuggestedSessionTemplates.all.contains { t in
            let lower = t.task.lowercased()
            return lower.contains("policy") && (lower.contains("memo") || lower.contains("brief"))
        }
        #expect(has, "catalog must include a policy memo or brief template")
    }

    @Test func catalogContainsRegulatoryAnalysisTemplate() {
        let has = SuggestedSessionTemplates.all.contains { t in
            let lower = t.task.lowercased()
            return lower.contains("regulatory") || (lower.contains("policy") && lower.contains("document"))
        }
        #expect(has, "catalog must include a regulatory analysis template")
    }

    @Test func policyTemplatesHaveReasonableDuration() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            let lower = t.task.lowercased()
            return lower.contains("policy memo") || lower.contains("policy brief")
                || lower.contains("regulatory")
        }
        #expect(!templates.isEmpty, "at least one policy template must exist")
        for t in templates {
            if let dur = t.preferredDuration {
                #expect(dur >= 5 * 60 && dur <= 3 * 60 * 60,
                        "policy template duration must be between 5 min and 3 hours")
            }
        }
    }

    @Test func catalogHasAtLeastFiftyEightTemplates() {
        #expect(SuggestedSessionTemplates.all.count >= 58,
                "catalog should have ≥58 templates after finance and policy additions")
    }

    // MARK: - UX design templates

    @Test func catalogContainsUserResearchTemplate() {
        let has = SuggestedSessionTemplates.all.contains { t in
            let lower = t.task.lowercased()
            return lower.contains("user research")
        }
        #expect(has, "catalog must include a user research template")
    }

    @Test func catalogContainsUXWireframeTemplate() {
        let has = SuggestedSessionTemplates.all.contains { t in
            let lower = t.task.lowercased()
            return (lower.contains("user flow") || lower.contains("wireframe"))
                && (lower.contains("figma") || lower.contains("feature") || lower.contains("map"))
        }
        #expect(has, "catalog must include a user flow or wireframe template")
    }

    @Test func uxTemplatesHaveReasonableDuration() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            let lower = t.task.lowercased()
            return lower.contains("user research") || lower.contains("user flow")
                || lower.contains("wireframe")
        }
        #expect(!templates.isEmpty, "at least one UX template must exist")
        for t in templates {
            if let dur = t.preferredDuration {
                #expect(dur >= 5 * 60 && dur <= 3 * 60 * 60,
                        "UX template duration must be between 5 min and 3 hours")
            }
        }
    }

    @Test func catalogHasAtLeastSixtyTemplates() {
        #expect(SuggestedSessionTemplates.all.count >= 60,
                "catalog should have ≥60 templates after UX additions")
    }

    // MARK: - Statistics templates

    @Test func catalogContainsStatisticsAnalysisTemplate() {
        let has = SuggestedSessionTemplates.all.contains { t in
            let lower = t.task.lowercased()
            return (lower.contains("statistical analysis") || lower.contains("r") || lower.contains("spss"))
                && (lower.contains("analysis") || lower.contains("run"))
        }
        #expect(has, "catalog must include a statistics/R/SPSS analysis template")
    }

    @Test func catalogContainsStatisticsProblemSetTemplate() {
        let has = SuggestedSessionTemplates.all.contains { t in
            let lower = t.task.lowercased()
            return lower.contains("statistics") && (lower.contains("problem set") || lower.contains("lab report"))
        }
        #expect(has, "catalog must include a statistics problem set or lab report template")
    }

    @Test func statisticsTemplatesHaveReasonableDuration() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            let lower = t.task.lowercased()
            return lower.contains("statistic") || lower.contains("r or spss")
        }
        #expect(!templates.isEmpty, "at least one statistics template must exist")
        for t in templates {
            if let dur = t.preferredDuration {
                #expect(dur >= 5 * 60 && dur <= 3 * 60 * 60,
                        "statistics template duration must be between 5 min and 3 hours")
            }
        }
    }

    // MARK: - Kinesiology templates

    @Test func catalogContainsKinesiologyAssignmentTemplate() {
        let has = SuggestedSessionTemplates.all.contains { t in
            let lower = t.task.lowercased()
            return (lower.contains("kinesiology") || lower.contains("exercise physiology"))
                && (lower.contains("assignment") || lower.contains("lab report") || lower.contains("complete"))
        }
        #expect(has, "catalog must include a kinesiology assignment template")
    }

    @Test func catalogContainsKinesiologyExamTemplate() {
        let has = SuggestedSessionTemplates.all.contains { t in
            let lower = t.task.lowercased()
            return (lower.contains("cscs") || lower.contains("kinesiology"))
                && (lower.contains("exam") || lower.contains("test") || lower.contains("study"))
        }
        #expect(has, "catalog must include a kinesiology exam/CSCS template")
    }

    @Test func kinesiologyTemplatesHaveReasonableDuration() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            let lower = t.task.lowercased()
            return lower.contains("kinesiology") || lower.contains("cscs")
        }
        #expect(!templates.isEmpty, "at least one kinesiology template must exist")
        for t in templates {
            if let dur = t.preferredDuration {
                #expect(dur >= 5 * 60 && dur <= 3 * 60 * 60,
                        "kinesiology template duration must be between 5 min and 3 hours")
            }
        }
    }

    // MARK: - Veterinary templates

    @Test func catalogContainsVeterinaryCaseNotesTemplate() {
        let has = SuggestedSessionTemplates.all.contains { t in
            let lower = t.task.lowercased()
            return lower.contains("veterinary") && (lower.contains("case notes") || lower.contains("assignment"))
        }
        #expect(has, "catalog must include a veterinary case notes or assignment template")
    }

    @Test func catalogContainsVeterinaryExamTemplate() {
        let has = SuggestedSessionTemplates.all.contains { t in
            let lower = t.task.lowercased()
            return lower.contains("navle") || (lower.contains("veterinary") && lower.contains("exam"))
        }
        #expect(has, "catalog must include a NAVLE or vet school exam template")
    }

    @Test func veterinaryTemplatesHaveReasonableDuration() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            let lower = t.task.lowercased()
            return lower.contains("veterinary") || lower.contains("navle")
        }
        #expect(!templates.isEmpty, "at least one veterinary template must exist")
        for t in templates {
            if let dur = t.preferredDuration {
                #expect(dur >= 5 * 60 && dur <= 3 * 60 * 60,
                        "veterinary template duration must be between 5 min and 3 hours")
            }
        }
    }

    @Test func catalogHasAtLeastSixtySixTemplates() {
        #expect(SuggestedSessionTemplates.all.count >= 66,
                "catalog should have ≥66 templates after statistics/kinesiology/veterinary additions")
    }

    // MARK: - Business/management templates

    @Test func catalogContainsMBACaseAnalysisTemplate() {
        let has = SuggestedSessionTemplates.all.contains { t in
            let lower = t.task.lowercased()
            return lower.contains("mba") || (lower.contains("case analysis") && lower.contains("strategic"))
        }
        #expect(has, "catalog must include an MBA case analysis or strategic management template")
    }

    @Test func catalogContainsGMATTemplate() {
        let has = SuggestedSessionTemplates.all.contains { t in
            t.task.lowercased().contains("gmat")
        }
        #expect(has, "catalog must include a GMAT prep template")
    }

    @Test func businessTemplatesHaveReasonableDuration() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            let lower = t.task.lowercased()
            return lower.contains("mba") || lower.contains("gmat")
        }
        #expect(!templates.isEmpty, "at least one business template must exist")
        for t in templates {
            if let dur = t.preferredDuration {
                #expect(dur >= 5 * 60 && dur <= 3 * 60 * 60,
                        "business template duration must be between 5 min and 3 hours")
            }
        }
    }

    @Test func catalogHasAtLeastSixtyEightTemplates() {
        #expect(SuggestedSessionTemplates.all.count >= 68,
                "catalog should have ≥68 templates after business additions")
    }

    @Test func catalogContainsDCFModelTemplate() {
        let has = SuggestedSessionTemplates.all.contains { t in
            let lower = t.task.lowercased()
            return lower.contains("dcf") || lower.contains("investment banking")
        }
        #expect(has, "catalog must include a DCF / investment banking analysis template")
    }

    @Test func dcfTemplateHasReasonableDuration() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("dcf") || t.task.lowercased().contains("investment banking")
        }
        #expect(!templates.isEmpty, "at least one DCF/IB template must exist")
        for t in templates {
            if let dur = t.preferredDuration {
                #expect(dur >= 5 * 60 && dur <= 3 * 60 * 60,
                        "DCF template duration must be between 5 min and 3 hours")
            }
        }
    }

    @Test func catalogHasAtLeastSixtyNineTemplates() {
        #expect(SuggestedSessionTemplates.all.count >= 69,
                "catalog should have ≥69 templates after DCF/IB finance template addition")
    }

    // MARK: - Public health templates

    @Test func catalogContainsPublicHealthExamTemplate() {
        let found = SuggestedSessionTemplates.all.contains { t in
            t.task.lowercased().contains("public health") && t.task.lowercased().contains("exam")
        }
        #expect(found, "catalog must contain a public health exam study template")
    }

    @Test func catalogContainsEpidemiologyAssignmentTemplate() {
        let found = SuggestedSessionTemplates.all.contains { t in
            t.task.lowercased().contains("epidemiology") || t.task.lowercased().contains("community health")
        }
        #expect(found, "catalog must contain an epidemiology or community health project template")
    }

    @Test func publichealthTemplatesHaveReasonableDuration() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("public health") || t.task.lowercased().contains("epidemiology")
        }
        #expect(!templates.isEmpty, "at least one public health template must exist")
        for t in templates {
            if let dur = t.preferredDuration {
                #expect(dur >= 5 * 60 && dur <= 3 * 60 * 60,
                        "public health template duration must be between 5 min and 3 hours")
            }
        }
    }

    @Test func catalogHasAtLeastSeventyOneTemplates() {
        #expect(SuggestedSessionTemplates.all.count >= 71,
                "catalog should have ≥71 templates after public health template additions")
    }

    // MARK: - paramedicine templates

    @Test func catalogContainsNREMTStudyTemplate() {
        let found = SuggestedSessionTemplates.all.contains { t in
            t.task.lowercased().contains("nremt") || t.task.lowercased().contains("emt")
        }
        #expect(found, "catalog must contain an NREMT or EMT certification study template")
    }

    @Test func catalogContainsEMSTrainingTemplate() {
        let found = SuggestedSessionTemplates.all.contains { t in
            t.task.lowercased().contains("paramedic") || t.task.lowercased().contains("ems")
        }
        #expect(found, "catalog must contain a paramedic or EMS training template")
    }

    @Test func paramedicineTemplatesHaveReasonableDuration() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("nremt") || t.task.lowercased().contains("emt")
                || t.task.lowercased().contains("paramedic") || t.task.lowercased().contains("ems")
        }
        #expect(!templates.isEmpty, "at least one paramedicine template must exist")
        for t in templates {
            if let dur = t.preferredDuration {
                #expect(dur >= 5 * 60 && dur <= 3 * 60 * 60,
                        "paramedicine template duration must be between 5 min and 3 hours")
            }
        }
    }

    // MARK: - social work templates

    @Test func catalogContainsSocialWorkCaseNotesTemplate() {
        let found = SuggestedSessionTemplates.all.contains { t in
            t.task.lowercased().contains("case notes") || t.task.lowercased().contains("intake assessment")
        }
        #expect(found, "catalog must contain a social work case notes or intake assessment template")
    }

    @Test func catalogContainsMSWCourseworkTemplate() {
        let found = SuggestedSessionTemplates.all.contains { t in
            t.task.lowercased().contains("msw") || t.task.lowercased().contains("social work licensing")
        }
        #expect(found, "catalog must contain a social work licensing or MSW coursework template")
    }

    @Test func socialworkTemplatesHaveReasonableDuration() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("social work") || t.task.lowercased().contains("msw")
        }
        #expect(!templates.isEmpty, "at least one social work template must exist")
        for t in templates {
            if let dur = t.preferredDuration {
                #expect(dur >= 5 * 60 && dur <= 3 * 60 * 60,
                        "social work template duration must be between 5 min and 3 hours")
            }
        }
    }

    // MARK: - occupational therapy templates

    @Test func catalogContainsOTSessionNotesTemplate() {
        let found = SuggestedSessionTemplates.all.contains { t in
            t.task.lowercased().contains("ot session") || t.task.lowercased().contains("occupational therapy")
        }
        #expect(found, "catalog must contain an OT session notes or treatment plan template")
    }

    @Test func catalogContainsNBCOTStudyTemplate() {
        let found = SuggestedSessionTemplates.all.contains { t in
            t.task.lowercased().contains("nbcot") || t.task.lowercased().contains("occupational therapy school")
        }
        #expect(found, "catalog must contain an NBCOT or OT school exam study template")
    }

    @Test func occupationaltherapyTemplatesHaveReasonableDuration() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("nbcot") || t.task.lowercased().contains("occupational therapy")
                || t.task.lowercased().contains("ot session")
        }
        #expect(!templates.isEmpty, "at least one occupational therapy template must exist")
        for t in templates {
            if let dur = t.preferredDuration {
                #expect(dur >= 5 * 60 && dur <= 3 * 60 * 60,
                        "occupational therapy template duration must be between 5 min and 3 hours")
            }
        }
    }

    @Test func catalogHasAtLeastSeventySevenTemplates() {
        #expect(SuggestedSessionTemplates.all.count >= 77,
                "catalog should have ≥77 templates after paramedicine/socialwork/OT additions")
    }

    // MARK: - Dental templates

    @Test func dentalTemplatesExist() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("nbde") || t.task.lowercased().contains("dental")
        }
        #expect(!templates.isEmpty, "at least one dental template must exist")
    }

    @Test func dentalTemplatesHaveVariety() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("nbde") || t.task.lowercased().contains("dental")
        }
        #expect(templates.count >= 2, "should have ≥2 dental templates (boards study + clinical notes)")
    }

    @Test func dentalTemplatesHaveReasonableDuration() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("nbde") || t.task.lowercased().contains("dental")
        }
        #expect(!templates.isEmpty)
        for t in templates {
            if let dur = t.preferredDuration {
                #expect(dur >= 5 * 60 && dur <= 3 * 60 * 60,
                        "dental template duration must be between 5 min and 3 hours")
            }
        }
    }

    // MARK: - Pharmacy templates

    @Test func pharmacyTemplatesExist() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("naplex") || t.task.lowercased().contains("pharmacy")
        }
        #expect(!templates.isEmpty, "at least one pharmacy template must exist")
    }

    @Test func pharmacyTemplatesHaveVariety() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("naplex") || t.task.lowercased().contains("pharmacy")
        }
        #expect(templates.count >= 2, "should have ≥2 pharmacy templates (boards study + drug review)")
    }

    @Test func pharmacyTemplatesHaveReasonableDuration() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("naplex") || t.task.lowercased().contains("pharmacy")
        }
        #expect(!templates.isEmpty)
        for t in templates {
            if let dur = t.preferredDuration {
                #expect(dur >= 5 * 60 && dur <= 3 * 60 * 60,
                        "pharmacy template duration must be between 5 min and 3 hours")
            }
        }
    }

    // MARK: - Optometry templates

    @Test func optometryTemplatesExist() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("nbeo") || t.task.lowercased().contains("optometry")
        }
        #expect(!templates.isEmpty, "at least one optometry template must exist")
    }

    @Test func optometryTemplatesHaveVariety() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("nbeo") || t.task.lowercased().contains("optometry")
        }
        #expect(templates.count >= 2, "should have ≥2 optometry templates (boards study + clinical notes)")
    }

    @Test func optometryTemplatesHaveReasonableDuration() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("nbeo") || t.task.lowercased().contains("optometry")
        }
        #expect(!templates.isEmpty)
        for t in templates {
            if let dur = t.preferredDuration {
                #expect(dur >= 5 * 60 && dur <= 3 * 60 * 60,
                        "optometry template duration must be between 5 min and 3 hours")
            }
        }
    }

    @Test func catalogHasAtLeastEightyThreeTemplates() {
        #expect(SuggestedSessionTemplates.all.count >= 83,
                "catalog should have ≥83 templates after dental/pharmacy/optometry additions")
    }

    // MARK: - Cybersecurity templates

    @Test func cybersecurityTemplatesExist() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("ctf") || t.task.lowercased().contains("security")
        }
        #expect(!templates.isEmpty, "at least one cybersecurity template must exist")
    }

    @Test func cybersecurityTemplatesHaveVariety() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("ctf") || t.task.lowercased().contains("security")
                || t.task.lowercased().contains("penetration")
        }
        #expect(templates.count >= 2, "should have ≥2 cybersecurity templates (CTF + cert prep)")
    }

    @Test func cybersecurityTemplatesHaveReasonableDuration() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("ctf") || t.task.lowercased().contains("security+")
        }
        #expect(!templates.isEmpty)
        for t in templates {
            if let dur = t.preferredDuration {
                #expect(dur >= 5 * 60 && dur <= 3 * 60 * 60,
                        "cybersecurity template duration must be between 5 min and 3 hours")
            }
        }
    }

    // MARK: - Screenwriting / Creative Writing templates

    @Test func screenwritingTemplatesExist() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("screenplay") || t.task.lowercased().contains("novel")
                || t.task.lowercased().contains("story structure")
        }
        #expect(!templates.isEmpty, "at least one screenwriting template must exist")
    }

    @Test func screenwritingTemplatesHaveVariety() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("screenplay") || t.task.lowercased().contains("scene")
                || t.task.lowercased().contains("story") || t.task.lowercased().contains("chapter")
        }
        #expect(templates.count >= 2, "should have ≥2 screenwriting templates (scene writing + outline)")
    }

    @Test func screenwritingTemplatesHaveReasonableDuration() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("screenplay") || t.task.lowercased().contains("story structure")
        }
        #expect(!templates.isEmpty)
        for t in templates {
            if let dur = t.preferredDuration {
                #expect(dur >= 5 * 60 && dur <= 3 * 60 * 60,
                        "screenwriting template duration must be between 5 min and 3 hours")
            }
        }
    }

    @Test func catalogHasAtLeastEightySevenTemplates() {
        #expect(SuggestedSessionTemplates.all.count >= 87,
                "catalog should have ≥87 templates after cybersecurity/screenwriting additions")
    }

    // MARK: - Graphic Design / Branding

    @Test func graphicdesignTemplatesExist() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("logo") || t.task.lowercased().contains("infographic")
                || t.task.lowercased().contains("brand")
        }
        #expect(!templates.isEmpty, "at least one graphic design template must exist")
    }
    @Test func graphicdesignTemplatesHaveVariety() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("logo") || t.task.lowercased().contains("infographic")
                || t.task.lowercased().contains("brand")
        }
        #expect(templates.count >= 2, "should have ≥2 graphic design templates (logo + infographic)")
    }
    @Test func graphicdesignTemplatesHaveReasonableDuration() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("logo") || t.task.lowercased().contains("infographic")
        }
        #expect(!templates.isEmpty)
        for t in templates {
            if let dur = t.preferredDuration {
                #expect(dur >= 5 * 60 && dur <= 3 * 60 * 60,
                        "graphic design template duration must be between 5 min and 3 hours")
            }
        }
    }

    // MARK: - Interior Design

    @Test func interiordesignTemplatesExist() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("interior design") || t.task.lowercased().contains("ncidq")
                || t.task.lowercased().contains("space plan") || t.task.lowercased().contains("floor layout")
        }
        #expect(!templates.isEmpty, "at least one interior design template must exist")
    }
    @Test func interiordesignTemplatesHaveVariety() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("interior design") || t.task.lowercased().contains("ncidq")
                || t.task.lowercased().contains("space plan") || t.task.lowercased().contains("floor layout")
        }
        #expect(templates.count >= 2, "should have ≥2 interior design templates (floor layout + exam)")
    }
    @Test func interiordesignTemplatesHaveReasonableDuration() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("interior design") || t.task.lowercased().contains("ncidq")
        }
        #expect(!templates.isEmpty)
        for t in templates {
            if let dur = t.preferredDuration {
                #expect(dur >= 5 * 60 && dur <= 3 * 60 * 60,
                        "interior design template duration must be between 5 min and 3 hours")
            }
        }
    }

    // MARK: - Speech-Language Pathology

    @Test func speechpathologyTemplatesExist() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("speech therapy") || t.task.lowercased().contains("praxis slp")
                || t.task.lowercased().contains("speech-language")
        }
        #expect(!templates.isEmpty, "at least one speech-language pathology template must exist")
    }
    @Test func speechpathologyTemplatesHaveVariety() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("speech therapy") || t.task.lowercased().contains("praxis slp")
                || t.task.lowercased().contains("speech-language")
        }
        #expect(templates.count >= 2, "should have ≥2 SLP templates (session notes + exam prep)")
    }
    @Test func speechpathologyTemplatesHaveReasonableDuration() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("speech therapy") || t.task.lowercased().contains("praxis slp")
        }
        #expect(!templates.isEmpty)
        for t in templates {
            if let dur = t.preferredDuration {
                #expect(dur >= 5 * 60 && dur <= 3 * 60 * 60,
                        "SLP template duration must be between 5 min and 3 hours")
            }
        }
    }

    @Test func catalogHasAtLeastNinetyThreeTemplates() {
        #expect(SuggestedSessionTemplates.all.count >= 93,
                "catalog should have ≥93 templates after graphic design/interior design/SLP additions")
    }

    // MARK: - Physician Assistant

    @Test func physicianassistantTemplatesExist() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("pance") || t.task.lowercased().contains("pa school")
                || t.task.lowercased().contains("pa clinical") || t.task.lowercased().contains("soap notes")
                    && t.task.lowercased().contains("pa")
        }
        #expect(!templates.isEmpty, "at least one physician assistant template must exist")
    }
    @Test func physicianassistantTemplatesHaveVariety() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("pance") || t.task.lowercased().contains("pa clinical")
                || t.task.lowercased().contains("pa school")
        }
        #expect(templates.count >= 2, "should have ≥2 PA templates (exam prep + clinical notes)")
    }
    @Test func physicianassistantTemplatesHaveReasonableDuration() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("pance") || t.task.lowercased().contains("pa clinical")
        }
        #expect(!templates.isEmpty)
        for t in templates {
            if let dur = t.preferredDuration {
                #expect(dur >= 5 * 60 && dur <= 3 * 60 * 60,
                        "PA template duration must be between 5 min and 3 hours")
            }
        }
    }

    @Test func catalogHasAtLeastNinetyFiveTemplates() {
        #expect(SuggestedSessionTemplates.all.count >= 95,
                "catalog should have ≥95 templates after physician assistant additions")
    }

    // MARK: - Real Estate

    @Test func realestateTemplatesExist() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("real estate") || t.task.lowercased().contains("comparative market")
        }
        #expect(!templates.isEmpty, "at least one real estate template must exist")
    }
    @Test func realestateTemplatesHaveVariety() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("real estate") || t.task.lowercased().contains("comparative market")
        }
        #expect(templates.count >= 2, "should have ≥2 real estate templates (licensing exam + CMA)")
    }
    @Test func realestateTemplatesHaveReasonableDuration() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("real estate") || t.task.lowercased().contains("comparative market")
        }
        #expect(!templates.isEmpty)
        for t in templates {
            if let dur = t.preferredDuration {
                #expect(dur >= 5 * 60 && dur <= 3 * 60 * 60,
                        "real estate template duration must be between 5 min and 3 hours")
            }
        }
    }

    // MARK: - Education / Teaching

    @Test func educationTemplatesExist() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("lesson plan") || t.task.lowercased().contains("praxis")
                || t.task.lowercased().contains("teaching certification")
        }
        #expect(!templates.isEmpty, "at least one education template must exist")
    }
    @Test func educationTemplatesHaveVariety() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("lesson plan") || t.task.lowercased().contains("praxis")
        }
        #expect(templates.count >= 2, "should have ≥2 education templates (lesson plans + Praxis)")
    }
    @Test func educationTemplatesHaveReasonableDuration() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("lesson plan") || t.task.lowercased().contains("praxis")
        }
        #expect(!templates.isEmpty)
        for t in templates {
            if let dur = t.preferredDuration {
                #expect(dur >= 5 * 60 && dur <= 3 * 60 * 60,
                        "education template duration must be between 5 min and 3 hours")
            }
        }
    }

    // MARK: - Actuarial Science

    @Test func actuarialTemplatesExist() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("actuarial") || t.task.lowercased().contains("exam p")
                || t.task.lowercased().contains("loss model")
        }
        #expect(!templates.isEmpty, "at least one actuarial template must exist")
    }
    @Test func actuarialTemplatesHaveVariety() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("actuarial")
        }
        #expect(templates.count >= 2, "should have ≥2 actuarial templates (exam prep + practice problems)")
    }
    @Test func actuarialTemplatesHaveReasonableDuration() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("actuarial")
        }
        #expect(!templates.isEmpty)
        for t in templates {
            if let dur = t.preferredDuration {
                #expect(dur >= 5 * 60 && dur <= 3 * 60 * 60,
                        "actuarial template duration must be between 5 min and 3 hours")
            }
        }
    }

    @Test func catalogHasAtLeastOneHundredOneTemplates() {
        #expect(SuggestedSessionTemplates.all.count >= 101,
                "catalog should have ≥101 templates after real estate/education/actuarial additions")
    }

    // MARK: - Journalism / Media Studies

    @Test func journalismTemplatesExist() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("journalism") || t.task.lowercased().contains("news article")
                || t.task.lowercased().contains("media") || t.task.lowercased().contains("investigative")
        }
        #expect(!templates.isEmpty, "at least one journalism template must exist")
    }
    @Test func journalismTemplatesHaveVariety() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("journalism") || t.task.lowercased().contains("news article")
                || t.task.lowercased().contains("investigative") || t.task.lowercased().contains("media")
        }
        #expect(templates.count >= 2, "should have ≥2 journalism templates")
    }
    @Test func journalismTemplatesHaveReasonableDuration() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("journalism") || t.task.lowercased().contains("news article")
        }
        #expect(!templates.isEmpty)
        for t in templates {
            if let dur = t.preferredDuration {
                #expect(dur >= 5 * 60 && dur <= 3 * 60 * 60,
                        "journalism template duration must be between 5 min and 3 hours")
            }
        }
    }

    // MARK: - Theology / Religious Studies

    @Test func theologyTemplatesExist() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("theolog") || t.task.lowercased().contains("seminary")
                || t.task.lowercased().contains("scripture") || t.task.lowercased().contains("divinity")
        }
        #expect(!templates.isEmpty, "at least one theology template must exist")
    }
    @Test func theologyTemplatesHaveVariety() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("theolog") || t.task.lowercased().contains("seminary")
                || t.task.lowercased().contains("scripture")
        }
        #expect(templates.count >= 2, "should have ≥2 theology templates")
    }
    @Test func theologyTemplatesHaveReasonableDuration() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("theolog") || t.task.lowercased().contains("seminary")
        }
        #expect(!templates.isEmpty)
        for t in templates {
            if let dur = t.preferredDuration {
                #expect(dur >= 5 * 60 && dur <= 3 * 60 * 60,
                        "theology template duration must be between 5 min and 3 hours")
            }
        }
    }

    // MARK: - Criminal Justice / Criminology

    @Test func criminalJusticeTemplatesExist() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("criminolog") || t.task.lowercased().contains("criminal justice")
        }
        #expect(!templates.isEmpty, "at least one criminal justice template must exist")
    }
    @Test func criminalJusticeTemplatesHaveVariety() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("criminolog") || t.task.lowercased().contains("criminal justice")
        }
        #expect(templates.count >= 2, "should have ≥2 criminal justice templates")
    }
    @Test func criminalJusticeTemplatesHaveReasonableDuration() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("criminolog") || t.task.lowercased().contains("criminal justice")
        }
        #expect(!templates.isEmpty)
        for t in templates {
            if let dur = t.preferredDuration {
                #expect(dur >= 5 * 60 && dur <= 3 * 60 * 60,
                        "criminal justice template duration must be between 5 min and 3 hours")
            }
        }
    }

    @Test func catalogHasAtLeastOneHundredSevenTemplates() {
        #expect(SuggestedSessionTemplates.all.count >= 107,
                "catalog should have ≥107 templates after journalism/theology/criminal justice additions")
    }

    // MARK: - Chiropractic

    @Test func chiropracticTemplatesExist() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("chiropractic") || t.task.lowercased().contains("nbce")
        }
        #expect(!templates.isEmpty, "at least one chiropractic template must exist")
    }
    @Test func chiropracticTemplatesHaveVariety() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("chiropractic") || t.task.lowercased().contains("nbce")
        }
        #expect(templates.count >= 2, "should have ≥2 chiropractic templates")
    }
    @Test func chiropracticTemplatesHaveReasonableDuration() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("chiropractic") || t.task.lowercased().contains("nbce")
        }
        #expect(!templates.isEmpty)
        for t in templates {
            if let dur = t.preferredDuration {
                #expect(dur >= 5 * 60 && dur <= 3 * 60 * 60)
            }
        }
    }

    // MARK: - Respiratory Therapy

    @Test func respiratorytherapyTemplatesExist() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("respiratory") || t.task.lowercased().contains("nbrc")
        }
        #expect(!templates.isEmpty, "at least one respiratory therapy template must exist")
    }
    @Test func respiratorytherapyTemplatesHaveVariety() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("respiratory") || t.task.lowercased().contains("nbrc")
        }
        #expect(templates.count >= 2, "should have ≥2 respiratory therapy templates")
    }
    @Test func respiratorytherapyTemplatesHaveReasonableDuration() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("respiratory") || t.task.lowercased().contains("nbrc")
        }
        #expect(!templates.isEmpty)
        for t in templates {
            if let dur = t.preferredDuration {
                #expect(dur >= 5 * 60 && dur <= 3 * 60 * 60)
            }
        }
    }

    // MARK: - Psychology

    @Test func psychologyTemplatesExist() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("psychology") || t.task.lowercased().contains("psych")
        }
        #expect(!templates.isEmpty, "at least one psychology template must exist")
    }
    @Test func psychologyTemplatesHaveVariety() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("psychology") || t.task.lowercased().contains("psych")
        }
        #expect(templates.count >= 2, "should have ≥2 psychology templates")
    }
    @Test func psychologyTemplatesHaveReasonableDuration() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("psychology") || t.task.lowercased().contains("psych")
        }
        #expect(!templates.isEmpty)
        for t in templates {
            if let dur = t.preferredDuration {
                #expect(dur >= 5 * 60 && dur <= 3 * 60 * 60)
            }
        }
    }

    // MARK: - Geology

    @Test func geologyTemplatesExist() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("geology") || t.task.lowercased().contains("earth science")
        }
        #expect(!templates.isEmpty, "at least one geology template must exist")
    }
    @Test func geologyTemplatesHaveVariety() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("geology") || t.task.lowercased().contains("earth science")
        }
        #expect(templates.count >= 2, "should have ≥2 geology templates")
    }
    @Test func geologyTemplatesHaveReasonableDuration() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("geology") || t.task.lowercased().contains("earth science")
        }
        #expect(!templates.isEmpty)
        for t in templates {
            if let dur = t.preferredDuration {
                #expect(dur >= 5 * 60 && dur <= 3 * 60 * 60)
            }
        }
    }

    // MARK: - Bioinformatics

    @Test func bioinformaticsTemplatesExist() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("bioinformatics") || t.task.lowercased().contains("genomics")
        }
        #expect(!templates.isEmpty, "at least one bioinformatics template must exist")
    }
    @Test func bioinformaticsTemplatesHaveVariety() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("bioinformatics") || t.task.lowercased().contains("genomics")
        }
        #expect(templates.count >= 2, "should have ≥2 bioinformatics templates")
    }
    @Test func bioinformaticsTemplatesHaveReasonableDuration() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("bioinformatics") || t.task.lowercased().contains("genomics")
        }
        #expect(!templates.isEmpty)
        for t in templates {
            if let dur = t.preferredDuration {
                #expect(dur >= 5 * 60 && dur <= 3 * 60 * 60)
            }
        }
    }

    // MARK: - Urban Planning

    @Test func urbanplanningTemplatesExist() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("urban planning") || t.task.lowercased().contains("aicp")
        }
        #expect(!templates.isEmpty, "at least one urban planning template must exist")
    }
    @Test func urbanplanningTemplatesHaveVariety() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("urban planning") || t.task.lowercased().contains("aicp")
                || t.task.lowercased().contains("comprehensive plan")
        }
        #expect(templates.count >= 2, "should have ≥2 urban planning templates")
    }
    @Test func urbanplanningTemplatesHaveReasonableDuration() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("urban planning") || t.task.lowercased().contains("aicp")
        }
        #expect(!templates.isEmpty)
        for t in templates {
            if let dur = t.preferredDuration {
                #expect(dur >= 5 * 60 && dur <= 3 * 60 * 60)
            }
        }
    }

    // MARK: - Dental Hygiene

    @Test func dentalhygieneTemplatesExist() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("dental hygiene") || t.task.lowercased().contains("nbdhe")
        }
        #expect(!templates.isEmpty, "at least one dental hygiene template must exist")
    }
    @Test func dentalhygieneTemplatesHaveVariety() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("dental hygiene") || t.task.lowercased().contains("nbdhe")
                || t.task.lowercased().contains("periodontal charting")
        }
        #expect(templates.count >= 2, "should have ≥2 dental hygiene templates")
    }
    @Test func dentalhygieneTemplatesHaveReasonableDuration() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("dental hygiene") || t.task.lowercased().contains("nbdhe")
        }
        #expect(!templates.isEmpty)
        for t in templates {
            if let dur = t.preferredDuration {
                #expect(dur >= 5 * 60 && dur <= 3 * 60 * 60)
            }
        }
    }

    // MARK: - Molecular Biology

    @Test func molecularbiologyTemplatesExist() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("molecular biology") || t.task.lowercased().contains("pcr")
        }
        #expect(!templates.isEmpty, "at least one molecular biology template must exist")
    }
    @Test func molecularbiologyTemplatesHaveVariety() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("molecular biology") || t.task.lowercased().contains("pcr")
                || t.task.lowercased().contains("cell biology")
        }
        #expect(templates.count >= 2, "should have ≥2 molecular biology templates")
    }
    @Test func molecularbiologyTemplatesHaveReasonableDuration() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("molecular biology") || t.task.lowercased().contains("pcr")
        }
        #expect(!templates.isEmpty)
        for t in templates {
            if let dur = t.preferredDuration {
                #expect(dur >= 5 * 60 && dur <= 3 * 60 * 60)
            }
        }
    }

    @Test func catalogHasAtLeastOneHundredTwentyThreeTemplates() {
        #expect(SuggestedSessionTemplates.all.count >= 123,
                "catalog should have ≥123 templates after geology/bioinformatics/urbanplanning/dentalhygiene/molecularbiology additions")
    }

    // MARK: - Forensic Accounting
    @Test func forensicaccountingTemplatesExist() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("forensic accounting") || t.task.lowercased().contains("cfe")
                || t.task.lowercased().contains("fraud")
        }
        #expect(!templates.isEmpty, "at least one forensic accounting template must exist")
    }
    @Test func forensicaccountingTemplatesHaveVariety() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("forensic accounting") || t.task.lowercased().contains("cfe")
                || t.task.lowercased().contains("fraud")
        }
        #expect(templates.count >= 2, "should have ≥2 forensic accounting templates")
    }
    @Test func forensicaccountingTemplatesHaveReasonableDuration() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("forensic accounting") || t.task.lowercased().contains("cfe")
        }
        #expect(!templates.isEmpty)
        for t in templates {
            if let dur = t.preferredDuration {
                #expect(dur >= 5 * 60 && dur <= 3 * 60 * 60)
            }
        }
    }

    // MARK: - Public Relations / Communications
    @Test func publicrelationsTemplatesExist() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("pr") || t.task.lowercased().contains("public relations")
                || t.task.lowercased().contains("communications")
        }
        #expect(!templates.isEmpty, "at least one public relations template must exist")
    }
    @Test func publicrelationsTemplatesHaveVariety() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("pr") || t.task.lowercased().contains("communications")
        }
        #expect(templates.count >= 2, "should have ≥2 public relations templates")
    }
    @Test func publicrelationsTemplatesHaveReasonableDuration() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("pr strategy") || t.task.lowercased().contains("communications exam")
        }
        #expect(!templates.isEmpty)
        for t in templates {
            if let dur = t.preferredDuration {
                #expect(dur >= 5 * 60 && dur <= 3 * 60 * 60)
            }
        }
    }

    // MARK: - Physical Education / Sport Coaching
    @Test func physedTemplatesExist() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("coaching") || t.task.lowercased().contains("physical education")
                || t.task.lowercased().contains("pe teacher")
        }
        #expect(!templates.isEmpty, "at least one physical education template must exist")
    }
    @Test func physedTemplatesHaveVariety() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("coaching") && (
                t.task.lowercased().contains("lesson") || t.task.lowercased().contains("certification")
            )
        }
        #expect(templates.count >= 2, "should have ≥2 physical education/coaching templates")
    }
    @Test func physedTemplatesHaveReasonableDuration() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("coaching plans") || t.task.lowercased().contains("coaching certification")
        }
        #expect(!templates.isEmpty)
        for t in templates {
            if let dur = t.preferredDuration {
                #expect(dur >= 5 * 60 && dur <= 3 * 60 * 60)
            }
        }
    }

    // MARK: - Library Science
    @Test func libraryscienceTemplatesExist() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("library science") || t.task.lowercased().contains("mlis")
                || t.task.lowercased().contains("archival")
        }
        #expect(!templates.isEmpty, "at least one library science template must exist")
    }
    @Test func libraryscienceTemplatesHaveVariety() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("library") || t.task.lowercased().contains("archival")
        }
        #expect(templates.count >= 2, "should have ≥2 library science templates")
    }
    @Test func libraryscienceTemplatesHaveReasonableDuration() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("library science") || t.task.lowercased().contains("archival")
        }
        #expect(!templates.isEmpty)
        for t in templates {
            if let dur = t.preferredDuration {
                #expect(dur >= 5 * 60 && dur <= 3 * 60 * 60)
            }
        }
    }

    // MARK: - Dental Assisting
    @Test func dentalassistingTemplatesExist() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("danb") || t.task.lowercased().contains("dental assisting")
                || t.task.lowercased().contains("chairside")
        }
        #expect(!templates.isEmpty, "at least one dental assisting template must exist")
    }
    @Test func dentalassistingTemplatesHaveVariety() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("dental assisting")
        }
        #expect(templates.count >= 2, "should have ≥2 dental assisting templates")
    }
    @Test func dentalassistingTemplatesHaveReasonableDuration() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("danb") || t.task.lowercased().contains("dental assisting")
        }
        #expect(!templates.isEmpty)
        for t in templates {
            if let dur = t.preferredDuration {
                #expect(dur >= 5 * 60 && dur <= 3 * 60 * 60)
            }
        }
    }

    // MARK: - Film Studies
    @Test func filmstudiesTemplatesExist() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("film analysis") || t.task.lowercased().contains("film studies")
                || t.task.lowercased().contains("film criticism")
        }
        #expect(!templates.isEmpty, "at least one film studies template must exist")
    }
    @Test func filmstudiesTemplatesHaveVariety() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("film") && (t.task.lowercased().contains("analysis")
                || t.task.lowercased().contains("studies") || t.task.lowercased().contains("exam"))
        }
        #expect(templates.count >= 2, "should have ≥2 film studies templates")
    }
    @Test func filmstudiesTemplatesHaveReasonableDuration() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("film analysis") || t.task.lowercased().contains("film studies")
        }
        #expect(!templates.isEmpty)
        for t in templates {
            if let dur = t.preferredDuration {
                #expect(dur >= 5 * 60 && dur <= 3 * 60 * 60)
            }
        }
    }

    // MARK: - Performing Arts
    @Test func performingArtsTemplatesExist() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("rehearse") || t.task.lowercased().contains("monologue")
                || t.task.lowercased().contains("dramaturgy") || t.task.lowercased().contains("theater")
        }
        #expect(!templates.isEmpty, "at least one performing arts template must exist")
    }
    @Test func performingArtsTemplatesHaveVariety() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("rehearse") || t.task.lowercased().contains("dramaturgy")
        }
        #expect(templates.count >= 2, "should have ≥2 performing arts templates")
    }
    @Test func performingArtsTemplatesHaveReasonableDuration() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("rehearse") || t.task.lowercased().contains("monologue")
        }
        #expect(!templates.isEmpty)
        for t in templates {
            if let dur = t.preferredDuration {
                #expect(dur >= 5 * 60 && dur <= 3 * 60 * 60)
            }
        }
    }

    // MARK: - Astronomy
    @Test func astronomyTemplatesExist() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("astrophysics") || t.task.lowercased().contains("astronomy")
        }
        #expect(!templates.isEmpty, "at least one astronomy template must exist")
    }
    @Test func astronomyTemplatesHaveVariety() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("astronomy") || t.task.lowercased().contains("astrophysics")
        }
        #expect(templates.count >= 2, "should have ≥2 astronomy templates")
    }
    @Test func astronomyTemplatesHaveReasonableDuration() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("astrophysics") || t.task.lowercased().contains("astronomy")
        }
        #expect(!templates.isEmpty)
        for t in templates {
            if let dur = t.preferredDuration {
                #expect(dur >= 5 * 60 && dur <= 3 * 60 * 60)
            }
        }
    }

    // MARK: - Mathematics
    @Test func mathematicsTemplatesExist() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("proof") || t.task.lowercased().contains("number theory")
                || t.task.lowercased().contains("mathematics problem")
        }
        #expect(!templates.isEmpty, "at least one mathematics template must exist")
    }
    @Test func mathematicsTemplatesHaveVariety() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("proof") || t.task.lowercased().contains("mathematics")
        }
        #expect(templates.count >= 2, "should have ≥2 mathematics templates")
    }
    @Test func mathematicsTemplatesHaveReasonableDuration() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("mathematical proof") || t.task.lowercased().contains("mathematics problem")
        }
        #expect(!templates.isEmpty)
        for t in templates {
            if let dur = t.preferredDuration {
                #expect(dur >= 5 * 60 && dur <= 3 * 60 * 60)
            }
        }
    }

    // MARK: - Linguistics
    @Test func linguisticsTemplatesExist() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("linguistics") || t.task.lowercased().contains("phonetics")
        }
        #expect(!templates.isEmpty, "at least one linguistics template must exist")
    }
    @Test func linguisticsTemplatesHaveVariety() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("linguistics")
        }
        #expect(templates.count >= 2, "should have ≥2 linguistics templates")
    }
    @Test func linguisticsTemplatesHaveReasonableDuration() {
        let templates = SuggestedSessionTemplates.all.filter { t in
            t.task.lowercased().contains("linguistics")
        }
        #expect(!templates.isEmpty)
        for t in templates {
            if let dur = t.preferredDuration {
                #expect(dur >= 5 * 60 && dur <= 3 * 60 * 60)
            }
        }
    }

    @Test func catalogHasAtLeastOneHundredThirtyThreeTemplates() {
        #expect(SuggestedSessionTemplates.all.count >= 133,
                "catalog should have ≥133 templates after forensicaccounting/publicrelations/physed/libraryscience/dentalassisting additions")
    }
    @Test func catalogHasAtLeastOneHundredFortyThreeTemplates() {
        #expect(SuggestedSessionTemplates.all.count >= 143,
                "catalog should have ≥143 templates after filmstudies/performingarts/astronomy/mathematics/linguistics additions")
    }

    // MARK: - Art History templates
    @Test func arthistoryTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasEssay = tasks.contains { $0.localizedCaseInsensitiveContains("art history essay") }
        let hasExam  = tasks.contains { $0.localizedCaseInsensitiveContains("art history exam") }
        #expect(hasEssay, "catalog must include an art history essay template")
        #expect(hasExam,  "catalog must include an art history exam template")
    }

    // MARK: - Marine Biology templates
    @Test func marinebiologyTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasLab  = tasks.contains { $0.localizedCaseInsensitiveContains("marine biology") }
        let hasExam = tasks.contains { $0.localizedCaseInsensitiveContains("oceanography") || $0.localizedCaseInsensitiveContains("marine biology") }
        #expect(hasLab,  "catalog must include a marine biology lab template")
        #expect(hasExam, "catalog must include a marine biology/oceanography exam template")
    }

    // MARK: - Speech Arts templates
    @Test func speechartsTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasDebate  = tasks.contains { $0.localizedCaseInsensitiveContains("debate") }
        let hasModelUN = tasks.contains { $0.localizedCaseInsensitiveContains("Model UN") || $0.localizedCaseInsensitiveContains("public speaking") }
        #expect(hasDebate,  "catalog must include a debate prep template")
        #expect(hasModelUN, "catalog must include a Model UN or public speaking template")
    }

    // MARK: - Forensic Science templates
    @Test func forensicscienceTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasLab  = tasks.contains { $0.localizedCaseInsensitiveContains("forensic science") }
        let hasExam = tasks.contains { $0.localizedCaseInsensitiveContains("FEPAC") || $0.localizedCaseInsensitiveContains("forensic science exam") }
        #expect(hasLab,  "catalog must include a forensic science lab template")
        #expect(hasExam, "catalog must include a forensic science exam template")
    }

    // MARK: - Accounting templates
    @Test func accountingTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasHomework = tasks.contains { $0.localizedCaseInsensitiveContains("accounting homework") || $0.localizedCaseInsensitiveContains("accounting") }
        let hasCMA = tasks.contains { $0.localizedCaseInsensitiveContains("CMA") || $0.localizedCaseInsensitiveContains("accounting course") }
        #expect(hasHomework, "catalog must include an accounting homework template")
        #expect(hasCMA,      "catalog must include a CMA exam or accounting exam template")
    }

    // MARK: - Sports Management templates
    @Test func sportsmanagementTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasCaseStudy = tasks.contains { $0.localizedCaseInsensitiveContains("sports management") }
        let hasExam      = tasks.contains { $0.localizedCaseInsensitiveContains("sports marketing") || $0.localizedCaseInsensitiveContains("sports management") }
        #expect(hasCaseStudy, "catalog must include a sports management case study template")
        #expect(hasExam,      "catalog must include a sports management exam template")
    }

    // MARK: - Art Restoration templates
    @Test func artrestorationTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasReport = tasks.contains { $0.localizedCaseInsensitiveContains("conservation") }
        let hasExam   = tasks.contains { $0.localizedCaseInsensitiveContains("conservation science") || $0.localizedCaseInsensitiveContains("conservation exam") }
        #expect(hasReport, "catalog must include a conservation treatment report template")
        #expect(hasExam,   "catalog must include a conservation science exam template")
    }

    // MARK: - Computational Science templates
    @Test func computationalscienceTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasSimulation = tasks.contains { $0.localizedCaseInsensitiveContains("simulation") || $0.localizedCaseInsensitiveContains("HPC") }
        let hasProblemSet = tasks.contains { $0.localizedCaseInsensitiveContains("computational science") || $0.localizedCaseInsensitiveContains("numerical methods") }
        #expect(hasSimulation, "catalog must include a simulation or HPC template")
        #expect(hasProblemSet, "catalog must include a computational science problem set template")
    }

    // MARK: - Forensic Psychology templates
    @Test func forensicpsychologyTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasAssessment = tasks.contains { $0.localizedCaseInsensitiveContains("forensic psychological") || $0.localizedCaseInsensitiveContains("forensic psychology") }
        let hasEPPP       = tasks.contains { $0.localizedCaseInsensitiveContains("EPPP") || $0.localizedCaseInsensitiveContains("forensic psychology") }
        #expect(hasAssessment, "catalog must include a forensic psychology assessment template")
        #expect(hasEPPP,       "catalog must include an EPPP exam or forensic psychology template")
    }

    // MARK: - Geospatial Science templates
    @Test func geospatialTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasGIS  = tasks.contains { $0.localizedCaseInsensitiveContains("GIS") || $0.localizedCaseInsensitiveContains("spatial") }
        let hasGISP = tasks.contains { $0.localizedCaseInsensitiveContains("GISP") || $0.localizedCaseInsensitiveContains("geospatial") }
        #expect(hasGIS,  "catalog must include a GIS analysis template")
        #expect(hasGISP, "catalog must include a GISP exam or geospatial science template")
    }

    // MARK: - Fashion Design templates
    @Test func fashiondesignTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasSketch = tasks.contains { $0.localizedCaseInsensitiveContains("fashion collection") || $0.localizedCaseInsensitiveContains("garment") }
        let hasExam   = tasks.contains { $0.localizedCaseInsensitiveContains("fashion design exam") || $0.localizedCaseInsensitiveContains("fashion merchandising") }
        #expect(hasSketch, "catalog must include a fashion sketching or garment template")
        #expect(hasExam,   "catalog must include a fashion design exam or merchandising template")
    }

    // MARK: - Hospitality templates
    @Test func hospitalityTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasCaseStudy = tasks.contains { $0.localizedCaseInsensitiveContains("hospitality") }
        let hasExam      = tasks.contains { $0.localizedCaseInsensitiveContains("tourism") || $0.localizedCaseInsensitiveContains("hospitality") }
        #expect(hasCaseStudy, "catalog must include a hospitality management case study template")
        #expect(hasExam,      "catalog must include a hospitality or tourism exam template")
    }

    // MARK: - Sports Analytics templates
    @Test func sportsanalyticsTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasModel    = tasks.contains { $0.localizedCaseInsensitiveContains("sports analytics") || $0.localizedCaseInsensitiveContains("player performance") }
        let hasProbSet  = tasks.contains { $0.localizedCaseInsensitiveContains("sports analytics assignment") || $0.localizedCaseInsensitiveContains("sabermetrics") }
        #expect(hasModel,   "catalog must include a sports analytics model template")
        #expect(hasProbSet, "catalog must include a sports analytics assignment or sabermetrics template")
    }

    // MARK: - Emergency Management templates
    @Test func emergencymanagementTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasPlan = tasks.contains { $0.localizedCaseInsensitiveContains("emergency management plan") || $0.localizedCaseInsensitiveContains("disaster response") }
        let hasFEMA = tasks.contains { $0.localizedCaseInsensitiveContains("FEMA") || $0.localizedCaseInsensitiveContains("emergency management") }
        #expect(hasPlan, "catalog must include an emergency management plan template")
        #expect(hasFEMA, "catalog must include a FEMA certification or emergency management template")
    }

    // MARK: - Aviation templates
    @Test func aviationTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasFAA   = tasks.contains { $0.localizedCaseInsensitiveContains("FAA") || $0.localizedCaseInsensitiveContains("private pilot") }
        let hasGround = tasks.contains { $0.localizedCaseInsensitiveContains("ground school") || $0.localizedCaseInsensitiveContains("aviation training") }
        #expect(hasFAA,    "catalog must include an FAA/private pilot written exam template")
        #expect(hasGround, "catalog must include a ground school or aviation training template")
    }

    // MARK: - Product Design templates
    @Test func productdesignTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasSketch  = tasks.contains { $0.localizedCaseInsensitiveContains("product design") && ($0.localizedCaseInsensitiveContains("sketch") || $0.localizedCaseInsensitiveContains("concept")) }
        let hasProto   = tasks.contains { $0.localizedCaseInsensitiveContains("prototype") || $0.localizedCaseInsensitiveContains("industrial") }
        #expect(hasSketch, "catalog must include a product design sketching or concept template")
        #expect(hasProto,  "catalog must include a product design prototype or industrial design template")
    }

    // MARK: - Tax Preparation templates
    @Test func taxprepTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasTaxReturn = tasks.contains { $0.localizedCaseInsensitiveContains("tax return") || $0.localizedCaseInsensitiveContains("file my tax") }
        let hasEA        = tasks.contains { $0.localizedCaseInsensitiveContains("EA") || $0.localizedCaseInsensitiveContains("Enrolled Agent") || $0.localizedCaseInsensitiveContains("tax preparation assignment") }
        #expect(hasTaxReturn, "catalog must include a tax return filing template")
        #expect(hasEA,        "catalog must include an EA exam or tax preparation assignment template")
    }

    // MARK: - Medical Billing and Coding templates
    @Test func medicalbillingTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasCoding = tasks.contains { $0.localizedCaseInsensitiveContains("CPT") || $0.localizedCaseInsensitiveContains("ICD-10") || $0.localizedCaseInsensitiveContains("medical coding") }
        let hasCPC    = tasks.contains { $0.localizedCaseInsensitiveContains("CPC") || $0.localizedCaseInsensitiveContains("medical billing") }
        #expect(hasCoding, "catalog must include a CPT/ICD-10 medical coding template")
        #expect(hasCPC,    "catalog must include a CPC exam or medical billing template")
    }

    // MARK: - Military Studies templates
    @Test func militarystudiesTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasPaper  = tasks.contains { $0.localizedCaseInsensitiveContains("military history") || $0.localizedCaseInsensitiveContains("defense studies") }
        let hasASVAB  = tasks.contains { $0.localizedCaseInsensitiveContains("ASVAB") || $0.localizedCaseInsensitiveContains("military science") || $0.localizedCaseInsensitiveContains("ROTC") }
        #expect(hasPaper, "catalog must include a military history paper or defense studies template")
        #expect(hasASVAB, "catalog must include an ASVAB or military science/ROTC template")
    }

    // MARK: - Supply Chain templates
    @Test func supplychainTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasCase   = tasks.contains { $0.localizedCaseInsensitiveContains("supply chain management") || $0.localizedCaseInsensitiveContains("logistics case") }
        let hasCPIM   = tasks.contains { $0.localizedCaseInsensitiveContains("CPIM") || $0.localizedCaseInsensitiveContains("CSCP") }
        #expect(hasCase,  "catalog must include a supply chain management assignment template")
        #expect(hasCPIM,  "catalog must include a CPIM or CSCP exam prep template")
    }

    // MARK: - Communication Studies templates
    @Test func communicationstudiesTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasPaper = tasks.contains { $0.localizedCaseInsensitiveContains("communication theory") }
        let hasExam  = tasks.contains { $0.localizedCaseInsensitiveContains("communication studies exam") || $0.localizedCaseInsensitiveContains("comm assignment") }
        #expect(hasPaper, "catalog must include a communication theory paper template")
        #expect(hasExam,  "catalog must include a communication studies exam template")
    }

    // MARK: - Healthcare Administration templates
    @Test func healthcareadminTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasCase = tasks.contains { $0.localizedCaseInsensitiveContains("healthcare administration") || $0.localizedCaseInsensitiveContains("health informatics") }
        let hasRHIA = tasks.contains { $0.localizedCaseInsensitiveContains("RHIA") || $0.localizedCaseInsensitiveContains("health information management") }
        #expect(hasCase, "catalog must include a healthcare administration case study template")
        #expect(hasRHIA, "catalog must include a RHIA or health information management exam template")
    }

    // MARK: - Neuroscience templates
    @Test func neuroscienceTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasPaper = tasks.contains { $0.localizedCaseInsensitiveContains("neuroscience paper") || $0.localizedCaseInsensitiveContains("neuro assignment") }
        let hasExam  = tasks.contains { $0.localizedCaseInsensitiveContains("neuroscience") && $0.localizedCaseInsensitiveContains("exam") }
        #expect(hasPaper, "catalog must include a neuroscience paper template")
        #expect(hasExam,  "catalog must include a neuroscience exam template")
    }

    // MARK: - Ethnic Studies templates
    @Test func ethnicstudiesTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasPaper = tasks.contains { $0.localizedCaseInsensitiveContains("ethnic studies") || $0.localizedCaseInsensitiveContains("gender studies") }
        let hasExam  = tasks.contains { $0.localizedCaseInsensitiveContains("cultural studies") || $0.localizedCaseInsensitiveContains("women's studies") }
        #expect(hasPaper, "catalog must include an ethnic or gender studies paper template")
        #expect(hasExam,  "catalog must include a cultural studies or women's studies exam template")
    }

    // MARK: - Human Factors / Ergonomics templates
    @Test func humanfactorsTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasAssignment = tasks.contains { $0.localizedCaseInsensitiveContains("human factors") || $0.localizedCaseInsensitiveContains("ergonomics assessment") }
        let hasExam       = tasks.contains { $0.localizedCaseInsensitiveContains("BCPE") || $0.localizedCaseInsensitiveContains("human factors course") }
        #expect(hasAssignment, "catalog must include a human factors assignment template")
        #expect(hasExam,       "catalog must include a BCPE or human factors course template")
    }

    // MARK: - Behavioral Economics templates
    @Test func behavioraleconomicsTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasPaper = tasks.contains { $0.localizedCaseInsensitiveContains("behavioral economics") }
        let hasExam  = tasks.contains { $0.localizedCaseInsensitiveContains("behavioral economics exam") || $0.localizedCaseInsensitiveContains("behavioral science") }
        #expect(hasPaper, "catalog must include a behavioral economics paper template")
        #expect(hasExam,  "catalog must include a behavioral economics exam template")
    }

    // MARK: - Translational Research templates
    @Test func translationalresearchTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasProposal = tasks.contains { $0.localizedCaseInsensitiveContains("translational research") }
        let hasAnalysis = tasks.contains { $0.localizedCaseInsensitiveContains("clinical translation") }
        #expect(hasProposal, "catalog must include a translational research proposal template")
        #expect(hasAnalysis, "catalog must include a clinical translation analysis template")
    }

    // MARK: - Healthcare Law templates
    @Test func healthcarelawTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasMemo = tasks.contains { $0.localizedCaseInsensitiveContains("healthcare law") || $0.localizedCaseInsensitiveContains("bioethics") }
        let hasExam = tasks.contains { $0.localizedCaseInsensitiveContains("health law exam") || $0.localizedCaseInsensitiveContains("healthcare regulation") }
        #expect(hasMemo, "catalog must include a healthcare law memo or bioethics template")
        #expect(hasExam, "catalog must include a health law exam or regulation template")
    }

    // MARK: - International Trade Law templates
    @Test func tradelawTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasBrief = tasks.contains { $0.localizedCaseInsensitiveContains("trade law") || $0.localizedCaseInsensitiveContains("comparative law") }
        let hasExam  = tasks.contains { $0.localizedCaseInsensitiveContains("international law exam") || $0.localizedCaseInsensitiveContains("trade compliance") }
        #expect(hasBrief, "catalog must include an international trade law brief template")
        #expect(hasExam,  "catalog must include an international law exam or trade compliance template")
    }

    // MARK: - Cosmetology templates
    @Test func cosmetologyTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasBoard = tasks.contains { $0.localizedCaseInsensitiveContains("cosmetology") || $0.localizedCaseInsensitiveContains("state board") }
        let hasEsthetics = tasks.contains { $0.localizedCaseInsensitiveContains("esthetics") || $0.localizedCaseInsensitiveContains("nail tech") }
        #expect(hasBoard,    "catalog must include a cosmetology state board template")
        #expect(hasEsthetics, "catalog must include an esthetics or nail tech template")
    }

    // MARK: - Personal Training templates
    @Test func personaltrainingTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasCert = tasks.contains { $0.localizedCaseInsensitiveContains("NASM") || $0.localizedCaseInsensitiveContains("ACE") && $0.localizedCaseInsensitiveContains("personal training") }
        let hasProgram = tasks.contains { $0.localizedCaseInsensitiveContains("client training program") || $0.localizedCaseInsensitiveContains("training program") && $0.localizedCaseInsensitiveContains("personal training") }
        #expect(hasCert,    "catalog must include a NASM/ACE certification template")
        #expect(hasProgram, "catalog must include a client training program template")
    }

    // MARK: - Dental Lab templates
    @Test func dentallabTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasNBDALE = tasks.contains { $0.localizedCaseInsensitiveContains("NBDALE") || $0.localizedCaseInsensitiveContains("dental laboratory") }
        let hasCeramics = tasks.contains { $0.localizedCaseInsensitiveContains("dental ceramics") || $0.localizedCaseInsensitiveContains("crown-and-bridge") }
        #expect(hasNBDALE,   "catalog must include a dental lab / NBDALE template")
        #expect(hasCeramics, "catalog must include a dental ceramics template")
    }

    // MARK: - Landscape Architecture templates
    @Test func landscapearchitectureTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasPlanting = tasks.contains { $0.localizedCaseInsensitiveContains("planting plan") || $0.localizedCaseInsensitiveContains("landscape architecture") }
        let hasCLARB = tasks.contains { $0.localizedCaseInsensitiveContains("CLARB") || $0.localizedCaseInsensitiveContains("landscape architecture assignment") }
        #expect(hasPlanting, "catalog must include a landscape architecture planting plan template")
        #expect(hasCLARB,    "catalog must include a CLARB exam or landscape architecture assignment template")
    }

    // MARK: - Immigration Law templates
    @Test func immigrationlawTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasPetition = tasks.contains { $0.localizedCaseInsensitiveContains("visa petition") || $0.localizedCaseInsensitiveContains("immigration case") }
        let hasExam = tasks.contains { $0.localizedCaseInsensitiveContains("immigration law exam") || $0.localizedCaseInsensitiveContains("immigration law assignment") }
        #expect(hasPetition, "catalog must include a visa petition / immigration case template")
        #expect(hasExam,     "catalog must include an immigration law exam template")
    }

    // MARK: - Music Education templates
    @Test func musiceducationTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasLesson = tasks.contains { $0.localizedCaseInsensitiveContains("lesson plan") && $0.localizedCaseInsensitiveContains("music") }
        let hasPraxis = tasks.contains { $0.localizedCaseInsensitiveContains("Praxis music") || $0.localizedCaseInsensitiveContains("music methods") }
        #expect(hasLesson, "catalog must include a music lesson plan template")
        #expect(hasPraxis, "catalog must include a Praxis music or music methods template")
    }

    // MARK: - Massage Therapy templates
    @Test func massagetherapyTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasMBLEx = tasks.contains { $0.localizedCaseInsensitiveContains("MBLEx") || $0.localizedCaseInsensitiveContains("massage therapy state board") }
        let hasCourse = tasks.contains { $0.localizedCaseInsensitiveContains("massage therapy coursework") || $0.localizedCaseInsensitiveContains("massage therapy") && $0.localizedCaseInsensitiveContains("notes") }
        #expect(hasMBLEx, "catalog must include a MBLEx or massage board exam template")
        #expect(hasCourse, "catalog must include a massage therapy coursework template")
    }

    // MARK: - Medical Laboratory Science templates
    @Test func medicallabscienceTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasASCP = tasks.contains { $0.localizedCaseInsensitiveContains("ASCP") || $0.localizedCaseInsensitiveContains("medical laboratory science board") }
        let hasLab = tasks.contains { $0.localizedCaseInsensitiveContains("clinical laboratory science lab report") || $0.localizedCaseInsensitiveContains("clinical laboratory science") && $0.localizedCaseInsensitiveContains("coursework") }
        #expect(hasASCP, "catalog must include an ASCP or medical laboratory science exam template")
        #expect(hasLab,  "catalog must include a clinical laboratory science lab report template")
    }

    // MARK: - Radiologic Technology templates
    @Test func radiologictechnologyTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasARRT = tasks.contains { $0.localizedCaseInsensitiveContains("ARRT") || $0.localizedCaseInsensitiveContains("radiologic technology certification") }
        let hasPositioning = tasks.contains { $0.localizedCaseInsensitiveContains("radiographic positioning") || $0.localizedCaseInsensitiveContains("diagnostic imaging") }
        #expect(hasARRT,       "catalog must include an ARRT or radiologic technology exam template")
        #expect(hasPositioning, "catalog must include a radiographic positioning or diagnostic imaging template")
    }

    // MARK: - Intellectual Property Law templates
    @Test func intellectualpropertyTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasPatent = tasks.contains { $0.localizedCaseInsensitiveContains("patent application") || $0.localizedCaseInsensitiveContains("IP litigation") }
        let hasBar = tasks.contains { $0.localizedCaseInsensitiveContains("patent bar exam") || $0.localizedCaseInsensitiveContains("intellectual property law assignment") }
        #expect(hasPatent, "catalog must include a patent application or IP litigation template")
        #expect(hasBar,    "catalog must include a patent bar exam or IP law assignment template")
    }

    // MARK: - Count guard
    @Test func catalogHasAtLeastOneHundredSixtyOneTemplates() {
        #expect(SuggestedSessionTemplates.all.count >= 161,
                "catalog should have ≥161 templates after accounting/sportsmanagement/artrestoration/computationalscience/forensicpsychology additions")
    }
    @Test func catalogHasAtLeastOneHundredSeventyOneTemplates() {
        #expect(SuggestedSessionTemplates.all.count >= 171,
                "catalog should have ≥171 templates after geospatial/fashiondesign/hospitality/sportsanalytics/emergencymanagement additions")
    }
    @Test func catalogHasAtLeastOneHundredEightyOneTemplates() {
        #expect(SuggestedSessionTemplates.all.count >= 181,
                "catalog should have ≥181 templates after aviation/productdesign/taxprep/medicalbilling/militarystudies additions")
    }
    @Test func catalogHasAtLeastOneHundredNinetyOneTemplates() {
        #expect(SuggestedSessionTemplates.all.count >= 191,
                "catalog should have ≥191 templates after supplychain/communicationstudies/healthcareadmin/neuroscience/ethnicstudies additions")
    }
    @Test func catalogHasAtLeastTwoHundredOneTemplates() {
        #expect(SuggestedSessionTemplates.all.count >= 201,
                "catalog should have ≥201 templates after humanfactors/behavioraleconomics/translationalresearch/healthcarelaw/tradelaw additions")
    }
    @Test func catalogHasAtLeastTwoHundredElevenTemplates() {
        #expect(SuggestedSessionTemplates.all.count >= 211,
                "catalog should have ≥211 templates after cosmetology/personaltraining/dentallab/landscapearchitecture/immigrationlaw additions")
    }
    @Test func catalogHasAtLeastTwoHundredTwentyThreeTemplates() {
        #expect(SuggestedSessionTemplates.all.count >= 223,
                "catalog should have ≥223 templates after musiceducation/massagetherapy/medicallabscience/radiologictechnology/intellectualproperty additions")
    }

    // MARK: - Sign Language / ASL templates
    @Test func signlanguageTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasASL = tasks.contains { $0.localizedCaseInsensitiveContains("ASL") || $0.localizedCaseInsensitiveContains("sign language") }
        let hasExam = tasks.contains { $0.localizedCaseInsensitiveContains("ASL") && ($0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("assignment")) }
        #expect(hasASL,  "catalog must include an ASL or sign language practice template")
        #expect(hasExam, "catalog must include an ASL exam or assignment template")
    }

    // MARK: - Acupuncture / TCM templates
    @Test func acupunctureTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasBoard = tasks.contains { $0.localizedCaseInsensitiveContains("acupuncture") && $0.localizedCaseInsensitiveContains("board") || $0.localizedCaseInsensitiveContains("TCM") }
        let hasAssignment = tasks.contains { $0.localizedCaseInsensitiveContains("acupuncture") && $0.localizedCaseInsensitiveContains("assignment") || $0.localizedCaseInsensitiveContains("traditional chinese medicine") }
        #expect(hasBoard,      "catalog must include an acupuncture board or TCM template")
        #expect(hasAssignment, "catalog must include an acupuncture assignment or TCM school template")
    }

    // MARK: - Art Education templates
    @Test func arteducationTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasLesson = tasks.contains { $0.localizedCaseInsensitiveContains("art lesson plan") || $0.localizedCaseInsensitiveContains("visual arts class") }
        let hasExam = tasks.contains { $0.localizedCaseInsensitiveContains("Praxis art") || $0.localizedCaseInsensitiveContains("art methods") }
        #expect(hasLesson, "catalog must include an art lesson plan template")
        #expect(hasExam,   "catalog must include a Praxis art or art methods template")
    }

    // MARK: - Environmental Law templates
    @Test func environmentallawTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasBrief = tasks.contains { $0.localizedCaseInsensitiveContains("environmental law brief") || $0.localizedCaseInsensitiveContains("environmental law") && $0.localizedCaseInsensitiveContains("policy") }
        let hasExam = tasks.contains { $0.localizedCaseInsensitiveContains("environmental law exam") || $0.localizedCaseInsensitiveContains("environmental regulation") }
        #expect(hasBrief, "catalog must include an environmental law brief or policy template")
        #expect(hasExam,  "catalog must include an environmental law exam or regulation template")
    }

    // MARK: - Family Law templates
    @Test func familylawTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasBrief = tasks.contains { $0.localizedCaseInsensitiveContains("family law brief") || $0.localizedCaseInsensitiveContains("domestic relations") }
        let hasExam = tasks.contains { $0.localizedCaseInsensitiveContains("family law exam") || $0.localizedCaseInsensitiveContains("domestic relations assignment") }
        #expect(hasBrief, "catalog must include a family law brief or domestic relations template")
        #expect(hasExam,  "catalog must include a family law exam or domestic relations assignment template")
    }

    // MARK: - Nuclear Medicine Technology templates
    @Test func nuclearmedtechTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasCNMT = tasks.contains { $0.localizedCaseInsensitiveContains("nuclear medicine") && ($0.localizedCaseInsensitiveContains("CNMT") || $0.localizedCaseInsensitiveContains("board")) }
        let hasAssignment = tasks.contains { $0.localizedCaseInsensitiveContains("nuclear medicine") && $0.localizedCaseInsensitiveContains("assignment") }
        #expect(hasCNMT,       "catalog must include a nuclear medicine board or CNMT prep template")
        #expect(hasAssignment, "catalog must include a nuclear medicine assignment template")
    }

    // MARK: - Diagnostic Medical Sonography templates
    @Test func sonographyTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasARDMS = tasks.contains { $0.localizedCaseInsensitiveContains("ARDMS") || $0.localizedCaseInsensitiveContains("sonography") && $0.localizedCaseInsensitiveContains("exam") }
        let hasAssignment = tasks.contains { $0.localizedCaseInsensitiveContains("sonography") && $0.localizedCaseInsensitiveContains("assignment") }
        #expect(hasARDMS,      "catalog must include an ARDMS registry or sonography exam template")
        #expect(hasAssignment, "catalog must include a sonography assignment template")
    }

    // MARK: - Cardiovascular Technology templates
    @Test func cardiovasculartechTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasCCI = tasks.contains { $0.localizedCaseInsensitiveContains("CCI") || $0.localizedCaseInsensitiveContains("cardiovascular technology") && $0.localizedCaseInsensitiveContains("board") }
        let hasAssignment = tasks.contains { $0.localizedCaseInsensitiveContains("cardiovascular technology") && $0.localizedCaseInsensitiveContains("assignment") }
        #expect(hasCCI,        "catalog must include a CCI board or cardiovascular technology template")
        #expect(hasAssignment, "catalog must include a cardiovascular technology assignment template")
    }

    // MARK: - Surgical Technology templates
    @Test func surgicaltechTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasCST = tasks.contains { $0.localizedCaseInsensitiveContains("CST") || $0.localizedCaseInsensitiveContains("surgical instrumentation") }
        let hasAssignment = tasks.contains { $0.localizedCaseInsensitiveContains("surgical technology") && $0.localizedCaseInsensitiveContains("assignment") }
        #expect(hasCST,        "catalog must include a CST exam or surgical instrumentation template")
        #expect(hasAssignment, "catalog must include a surgical technology assignment template")
    }

    // MARK: - Art Therapy templates
    @Test func arttherapyTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasNotes = tasks.contains { $0.localizedCaseInsensitiveContains("art therapy") && $0.localizedCaseInsensitiveContains("session notes") || $0.localizedCaseInsensitiveContains("art therapy") && $0.localizedCaseInsensitiveContains("treatment plan") }
        let hasATR = tasks.contains { $0.localizedCaseInsensitiveContains("ATR") || $0.localizedCaseInsensitiveContains("art therapy") && $0.localizedCaseInsensitiveContains("board") }
        #expect(hasNotes, "catalog must include an art therapy session notes or treatment plan template")
        #expect(hasATR,   "catalog must include an ATR board or art therapy board template")
    }

    // MARK: - Polysomnography templates
    @Test func polysomnographyTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasRPSGT = tasks.contains { $0.localizedCaseInsensitiveContains("RPSGT") || $0.localizedCaseInsensitiveContains("polysomnography") && $0.localizedCaseInsensitiveContains("sleep scoring") }
        let hasAssignment = tasks.contains { $0.localizedCaseInsensitiveContains("polysomnography") && $0.localizedCaseInsensitiveContains("assignment") }
        #expect(hasRPSGT,      "catalog must include an RPSGT or sleep scoring template")
        #expect(hasAssignment, "catalog must include a polysomnography assignment template")
    }

    // MARK: - Nursing Informatics templates
    @Test func nursinginformaticsTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasInformatics = tasks.contains { $0.localizedCaseInsensitiveContains("nursing informatics") }
        let hasExam = tasks.contains { $0.localizedCaseInsensitiveContains("nursing informatics") && ($0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("certification")) }
        #expect(hasInformatics, "catalog must include a nursing informatics template")
        #expect(hasExam,        "catalog must include a nursing informatics exam or certification template")
    }

    // MARK: - Music Therapy templates
    @Test func musictherapyTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasNotes = tasks.contains { $0.localizedCaseInsensitiveContains("music therapy") && ($0.localizedCaseInsensitiveContains("session notes") || $0.localizedCaseInsensitiveContains("treatment plan")) }
        let hasMTBC = tasks.contains { $0.localizedCaseInsensitiveContains("MT-BC") || $0.localizedCaseInsensitiveContains("music therapy") && $0.localizedCaseInsensitiveContains("board") }
        #expect(hasNotes, "catalog must include a music therapy session notes or treatment plan template")
        #expect(hasMTBC,  "catalog must include an MT-BC board or music therapy board template")
    }

    // MARK: - Drama/Theatre Education templates
    @Test func dramaeducationTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasLesson = tasks.contains { $0.localizedCaseInsensitiveContains("drama lesson plan") || $0.localizedCaseInsensitiveContains("theatre education curriculum") }
        let hasExam = tasks.contains { $0.localizedCaseInsensitiveContains("Praxis drama") || $0.localizedCaseInsensitiveContains("playwriting") && $0.localizedCaseInsensitiveContains("assignment") }
        #expect(hasLesson, "catalog must include a drama lesson plan or theatre education curriculum template")
        #expect(hasExam,   "catalog must include a Praxis drama or playwriting assignment template")
    }

    // MARK: - Wine Studies / Sommelier templates
    @Test func winesommelierTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasWSET = tasks.contains { $0.localizedCaseInsensitiveContains("WSET") || $0.localizedCaseInsensitiveContains("sommelier") && $0.localizedCaseInsensitiveContains("exam") }
        let hasTasting = tasks.contains { $0.localizedCaseInsensitiveContains("blind tasting") || $0.localizedCaseInsensitiveContains("viticulture") && $0.localizedCaseInsensitiveContains("assignment") }
        #expect(hasWSET,    "catalog must include a WSET or sommelier exam template")
        #expect(hasTasting, "catalog must include a blind tasting or viticulture assignment template")
    }

    // MARK: - Gerontology / Aging Studies templates
    @Test func gerontologyTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasAssignment = tasks.contains { $0.localizedCaseInsensitiveContains("gerontology") && ($0.localizedCaseInsensitiveContains("assignment") || $0.localizedCaseInsensitiveContains("aging")) }
        let hasExam = tasks.contains { $0.localizedCaseInsensitiveContains("geriatrics") || ($0.localizedCaseInsensitiveContains("gerontology") && $0.localizedCaseInsensitiveContains("exam")) }
        #expect(hasAssignment, "catalog must include a gerontology assignment or aging studies template")
        #expect(hasExam,       "catalog must include a geriatrics exam or gerontology course template")
    }

    // MARK: - Addiction Counseling templates
    @Test func addictioncounselingTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasNotes = tasks.contains { $0.localizedCaseInsensitiveContains("addiction counseling") && ($0.localizedCaseInsensitiveContains("session notes") || $0.localizedCaseInsensitiveContains("treatment plan")) }
        let hasExam = tasks.contains { ($0.localizedCaseInsensitiveContains("CADC") || $0.localizedCaseInsensitiveContains("NAADAC")) && $0.localizedCaseInsensitiveContains("exam") }
        #expect(hasNotes, "catalog must include an addiction counseling session notes or treatment plan template")
        #expect(hasExam,  "catalog must include a CADC or NAADAC exam template")
    }

    // MARK: - Oral Surgery templates
    @Test func oralsurgeryTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasExam = tasks.contains { $0.localizedCaseInsensitiveContains("oral surgery") && ($0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("OMFS")) }
        let hasAssignment = tasks.contains { $0.localizedCaseInsensitiveContains("oral surgery") && ($0.localizedCaseInsensitiveContains("assignment") || $0.localizedCaseInsensitiveContains("case write")) }
        #expect(hasExam,       "catalog must include an oral surgery exam or OMFS template")
        #expect(hasAssignment, "catalog must include an oral surgery assignment or case write-up template")
    }

    // MARK: - Public Health Law templates
    @Test func publichealthlawTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasMemo = tasks.contains { $0.localizedCaseInsensitiveContains("public health law") && ($0.localizedCaseInsensitiveContains("memo") || $0.localizedCaseInsensitiveContains("regulation")) }
        let hasExam = tasks.contains { $0.localizedCaseInsensitiveContains("public health law") && ($0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("assignment")) }
        #expect(hasMemo, "catalog must include a public health law memo or regulation analysis template")
        #expect(hasExam, "catalog must include a public health law exam or assignment template")
    }

    // MARK: - Count guard
    @Test func catalogHasAtLeastTwoHundredThirtyThreeTemplates() {
        #expect(SuggestedSessionTemplates.all.count >= 233,
                "catalog should have ≥233 templates after signlanguage/acupuncture/arteducation/environmentallaw/familylaw additions")
    }
    @Test func catalogHasAtLeastTwoHundredFortyThreeTemplates() {
        #expect(SuggestedSessionTemplates.all.count >= 243,
                "catalog should have ≥243 templates after nuclearmedtech/sonography/cardiovasculartech/surgicaltech/arttherapy additions")
    }
    @Test func catalogHasAtLeastTwoHundredFiftyThreeTemplates() {
        #expect(SuggestedSessionTemplates.all.count >= 253,
                "catalog should have ≥253 templates after polysomnography/nursinginformatics/musictherapy/dramaeducation/winesommelier additions")
    }
    @Test func catalogHasAtLeastTwoHundredFiftyNineTemplates() {
        #expect(SuggestedSessionTemplates.all.count >= 259,
                "catalog should have ≥259 templates after gerontology/addictioncounseling/oralsurgery/publichealthlaw additions")
    }

    // MARK: - Diagnostic Medical Physics templates
    @Test func diagnosticphysicsTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasExam = tasks.contains { $0.localizedCaseInsensitiveContains("medical physics") && ($0.localizedCaseInsensitiveContains("ABR") || $0.localizedCaseInsensitiveContains("dosimetry")) }
        let hasAssignment = tasks.contains { $0.localizedCaseInsensitiveContains("medical physics") && $0.localizedCaseInsensitiveContains("assignment") }
        #expect(hasExam,       "catalog must include a medical physics board exam or dosimetry template")
        #expect(hasAssignment, "catalog must include a diagnostic medical physics assignment template")
    }

    // MARK: - Perfusion Technology templates
    @Test func perfusiontechnologyTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasExam = tasks.contains { $0.localizedCaseInsensitiveContains("perfusion") && ($0.localizedCaseInsensitiveContains("PBSE") || $0.localizedCaseInsensitiveContains("certification")) }
        let hasAssignment = tasks.contains { $0.localizedCaseInsensitiveContains("perfusion") && $0.localizedCaseInsensitiveContains("assignment") }
        #expect(hasExam,       "catalog must include a perfusion technology certification exam template")
        #expect(hasAssignment, "catalog must include a perfusion technology assignment template")
    }

    // MARK: - Ophthalmic Medical Technology templates
    @Test func ophthalmicTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasExam = tasks.contains { $0.localizedCaseInsensitiveContains("ophthalmic") && ($0.localizedCaseInsensitiveContains("JCAHPO") || $0.localizedCaseInsensitiveContains("certification")) }
        let hasAssignment = tasks.contains { $0.localizedCaseInsensitiveContains("ophthalmic") && ($0.localizedCaseInsensitiveContains("assignment") || $0.localizedCaseInsensitiveContains("documentation")) }
        #expect(hasExam,       "catalog must include a JCAHPO or ophthalmic certification exam template")
        #expect(hasAssignment, "catalog must include an ophthalmic assignment or documentation template")
    }

    // MARK: - Central Sterile Processing templates
    @Test func centralsterileTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasExam = tasks.contains { $0.localizedCaseInsensitiveContains("sterile processing") && ($0.localizedCaseInsensitiveContains("CBSPD") || $0.localizedCaseInsensitiveContains("CRCST")) }
        let hasAssignment = tasks.contains { $0.localizedCaseInsensitiveContains("sterile processing") && ($0.localizedCaseInsensitiveContains("assignment") || $0.localizedCaseInsensitiveContains("case study")) }
        #expect(hasExam,       "catalog must include a CBSPD or CRCST certification exam template")
        #expect(hasAssignment, "catalog must include a central sterile processing assignment template")
    }

    // MARK: - Count guard
    @Test func catalogHasAtLeastTwoHundredSixtyNineTemplates() {
        #expect(SuggestedSessionTemplates.all.count >= 269,
                "catalog should have ≥269 templates after diagnosticphysics/perfusiontechnology/ophthalmic/centralsterile additions")
    }

    // MARK: - Opticianry templates
    @Test func opticianryTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasExam = tasks.contains { $0.localizedCaseInsensitiveContains("opticianry") && ($0.localizedCaseInsensitiveContains("ABO") || $0.localizedCaseInsensitiveContains("certification")) }
        let hasAssignment = tasks.contains { $0.localizedCaseInsensitiveContains("opticianry") && ($0.localizedCaseInsensitiveContains("assignment") || $0.localizedCaseInsensitiveContains("dispensing")) }
        #expect(hasExam,       "catalog must include an opticianry ABO certification exam template")
        #expect(hasAssignment, "catalog must include an opticianry dispensing assignment template")
    }

    // MARK: - Dance/Movement Therapy templates
    @Test func dancetherapyTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasNotes = tasks.contains { $0.localizedCaseInsensitiveContains("dance therapy") && ($0.localizedCaseInsensitiveContains("session notes") || $0.localizedCaseInsensitiveContains("treatment plan")) }
        let hasExam = tasks.contains { $0.localizedCaseInsensitiveContains("dance therapy") && ($0.localizedCaseInsensitiveContains("ADTA") || $0.localizedCaseInsensitiveContains("board exam") || $0.localizedCaseInsensitiveContains("assignment")) }
        #expect(hasNotes, "catalog must include a dance therapy session notes or treatment plan template")
        #expect(hasExam,  "catalog must include an ADTA board exam or dance therapy assignment template")
    }

    // MARK: - Recreational Therapy templates
    @Test func recreationtherapyTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasNotes = tasks.contains { ($0.localizedCaseInsensitiveContains("therapeutic recreation") || $0.localizedCaseInsensitiveContains("recreation therapy")) && ($0.localizedCaseInsensitiveContains("treatment plan") || $0.localizedCaseInsensitiveContains("session notes")) }
        let hasExam = tasks.contains { $0.localizedCaseInsensitiveContains("CTRS") && ($0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("school")) }
        #expect(hasNotes, "catalog must include a therapeutic recreation treatment plan or session notes template")
        #expect(hasExam,  "catalog must include a CTRS exam template")
    }

    // MARK: - Horticultural Therapy templates
    @Test func horticulturetherapyTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasNotes = tasks.contains { $0.localizedCaseInsensitiveContains("horticultural therapy") && ($0.localizedCaseInsensitiveContains("session notes") || $0.localizedCaseInsensitiveContains("program plan")) }
        let hasExam = tasks.contains { $0.localizedCaseInsensitiveContains("HTR") && ($0.localizedCaseInsensitiveContains("credential") || $0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("school")) }
        #expect(hasNotes, "catalog must include a horticultural therapy session notes or program plan template")
        #expect(hasExam,  "catalog must include an HTR credential or exam template")
    }

    // MARK: - Dietetic Technology templates
    @Test func dietetictechnologyTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasExam = tasks.contains { $0.localizedCaseInsensitiveContains("DTR") && ($0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("dietetic technician")) }
        let hasAssignment = tasks.contains { $0.localizedCaseInsensitiveContains("dietetic technician") && ($0.localizedCaseInsensitiveContains("assignment") || $0.localizedCaseInsensitiveContains("dietary analysis")) }
        #expect(hasExam,       "catalog must include a DTR exam or dietetic technician template")
        #expect(hasAssignment, "catalog must include a dietetic technician assignment or dietary analysis template")
    }

    // MARK: - Occupational Medicine templates
    @Test func occupationalmedicineTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasCaseReport = tasks.contains { $0.localizedCaseInsensitiveContains("occupational medicine") && ($0.localizedCaseInsensitiveContains("case report") || $0.localizedCaseInsensitiveContains("industrial hygiene")) }
        let hasExam = tasks.contains { $0.localizedCaseInsensitiveContains("ACOEM") && ($0.localizedCaseInsensitiveContains("boards") || $0.localizedCaseInsensitiveContains("exam")) }
        #expect(hasCaseReport, "catalog must include an occupational medicine case report or industrial hygiene template")
        #expect(hasExam,       "catalog must include an ACOEM boards or exam template")
    }

    // MARK: - Integrative Medicine templates
    @Test func integrativemedicineTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasCaseStudy = tasks.contains { $0.localizedCaseInsensitiveContains("integrative") && ($0.localizedCaseInsensitiveContains("case study") || $0.localizedCaseInsensitiveContains("case report")) }
        let hasExam = tasks.contains { ($0.localizedCaseInsensitiveContains("integrative medicine") || $0.localizedCaseInsensitiveContains("holistic health")) && ($0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("assignment")) }
        #expect(hasCaseStudy, "catalog must include an integrative or functional medicine case study template")
        #expect(hasExam,      "catalog must include an integrative medicine board exam or holistic health assignment template")
    }

    // MARK: - Genetic Counseling templates
    @Test func geneticcounselingTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasCaseReport = tasks.contains { $0.localizedCaseInsensitiveContains("genetic counseling") && ($0.localizedCaseInsensitiveContains("case report") || $0.localizedCaseInsensitiveContains("variant")) }
        let hasExam = tasks.contains { ($0.localizedCaseInsensitiveContains("ABGC") || $0.localizedCaseInsensitiveContains("CGC")) && ($0.localizedCaseInsensitiveContains("board") || $0.localizedCaseInsensitiveContains("exam")) }
        #expect(hasCaseReport, "catalog must include a genetic counseling case report or variant interpretation template")
        #expect(hasExam,       "catalog must include an ABGC board or CGC exam template")
    }

    // MARK: - Behavioral Health Promotion templates
    @Test func behavioralhealthpromotionTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasProgram = tasks.contains { $0.localizedCaseInsensitiveContains("health promotion") && ($0.localizedCaseInsensitiveContains("program") || $0.localizedCaseInsensitiveContains("community health")) }
        let hasExam = tasks.contains { $0.localizedCaseInsensitiveContains("CHES") && ($0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("health education")) }
        #expect(hasProgram, "catalog must include a health promotion program or community health education template")
        #expect(hasExam,    "catalog must include a CHES exam or health education specialist template")
    }

    // MARK: - Dental Public Health templates
    @Test func dentalpublichealthTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasAnalysis = tasks.contains { $0.localizedCaseInsensitiveContains("dental public health") && ($0.localizedCaseInsensitiveContains("analysis") || $0.localizedCaseInsensitiveContains("oral health policy")) }
        let hasExam = tasks.contains { $0.localizedCaseInsensitiveContains("dental public health") && ($0.localizedCaseInsensitiveContains("board exam") || $0.localizedCaseInsensitiveContains("community dentistry")) }
        #expect(hasAnalysis, "catalog must include a dental public health analysis or oral health policy template")
        #expect(hasExam,     "catalog must include a dental public health board exam or community dentistry template")
    }

    // MARK: - Playwriting templates
    @Test func playwrightingTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasScene = tasks.contains { $0.localizedCaseInsensitiveContains("stage play") && ($0.localizedCaseInsensitiveContains("scene") || $0.localizedCaseInsensitiveContains("act")) }
        let hasOutline = tasks.contains { ($0.localizedCaseInsensitiveContains("one-act") || $0.localizedCaseInsensitiveContains("full-length play")) && ($0.localizedCaseInsensitiveContains("outline") || $0.localizedCaseInsensitiveContains("structure")) }
        #expect(hasScene,   "catalog must include a stage play scene/act writing template")
        #expect(hasOutline, "catalog must include a one-act or full-length play outline template")
    }

    // MARK: - Sports Medicine templates
    @Test func sportsmedicineTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasCaseReport = tasks.contains { $0.localizedCaseInsensitiveContains("sports medicine") && ($0.localizedCaseInsensitiveContains("case report") || $0.localizedCaseInsensitiveContains("clinical")) }
        let hasExam = tasks.contains { $0.localizedCaseInsensitiveContains("BOC") && ($0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("sports medicine")) }
        #expect(hasCaseReport, "catalog must include a sports medicine case report or clinical template")
        #expect(hasExam,       "catalog must include a BOC exam or sports medicine assignment template")
    }

    // MARK: - Naturopathic Medicine templates
    @Test func naturopathicmedicineTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasAssignment = tasks.contains { $0.localizedCaseInsensitiveContains("naturopathic medicine") && ($0.localizedCaseInsensitiveContains("assignment") || $0.localizedCaseInsensitiveContains("case study")) }
        let hasExam = tasks.contains { $0.localizedCaseInsensitiveContains("NPLEX") && ($0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("board")) }
        #expect(hasAssignment, "catalog must include a naturopathic medicine assignment or case study template")
        #expect(hasExam,       "catalog must include an NPLEX exam or naturopathic board prep template")
    }

    // MARK: - Midwifery templates
    @Test func midwiferyTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasBirthPlan = tasks.contains { ($0.localizedCaseInsensitiveContains("birth plan") || $0.localizedCaseInsensitiveContains("prenatal notes")) && $0.localizedCaseInsensitiveContains("midwifery") }
        let hasExam = tasks.contains { $0.localizedCaseInsensitiveContains("AMCB") && ($0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("midwifery")) }
        #expect(hasBirthPlan, "catalog must include a midwifery birth plan or prenatal notes template")
        #expect(hasExam,      "catalog must include an AMCB exam or midwifery assignment template")
    }

    // MARK: - Clinical Psychology templates
    @Test func clinicalpsychologyTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasReport = tasks.contains { ($0.localizedCaseInsensitiveContains("neuropsychological") || $0.localizedCaseInsensitiveContains("psychological assessment")) && $0.localizedCaseInsensitiveContains("report") }
        let hasAPPIC = tasks.contains { $0.localizedCaseInsensitiveContains("APPIC") && ($0.localizedCaseInsensitiveContains("internship") || $0.localizedCaseInsensitiveContains("application")) }
        #expect(hasReport, "catalog must include a neuropsychological or psychological assessment report template")
        #expect(hasAPPIC,  "catalog must include an APPIC internship or clinical psychology application template")
    }

    // MARK: - Count guard
    @Test func catalogHasAtLeastTwoHundredSeventyNineTemplates() {
        #expect(SuggestedSessionTemplates.all.count >= 279,
                "catalog should have ≥279 templates after opticianry/dancetherapy/recreationtherapy/horticulturetherapy/dietetictechnology additions")
    }

    @Test func catalogHasAtLeastTwoHundredEightyNineTemplates() {
        #expect(SuggestedSessionTemplates.all.count >= 289,
                "catalog should have ≥289 templates after occupationalmedicine/integrativemedicine/geneticcounseling/behavioralhealthpromotion/dentalpublichealth additions")
    }

    @Test func catalogHasAtLeastTwoHundredNinetySevenTemplates() {
        #expect(SuggestedSessionTemplates.all.count >= 297,
                "catalog should have ≥297 templates after playwriting/sportsmedicine/naturopathicmedicine/midwifery/clinicalpsychology additions")
    }

    // MARK: - Theatre Sound templates
    @Test func theatresoundTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasStudy = tasks.contains { $0.localizedCaseInsensitiveContains("live sound") || ($0.localizedCaseInsensitiveContains("audio tech") && $0.localizedCaseInsensitiveContains("program")) }
        let hasAssignment = tasks.contains { $0.localizedCaseInsensitiveContains("sound design") && $0.localizedCaseInsensitiveContains("theatre") }
        #expect(hasStudy,      "catalog must include a live sound or audio tech program study template")
        #expect(hasAssignment, "catalog must include a sound design/theatre audio assignment template")
    }

    // MARK: - Dance Science templates
    @Test func dancescienceTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasLMA = tasks.contains { $0.localizedCaseInsensitiveContains("Laban") || $0.localizedCaseInsensitiveContains("dance kinesiology") || $0.localizedCaseInsensitiveContains("dance anatomy") }
        let hasStudy = tasks.contains { $0.localizedCaseInsensitiveContains("dance science") || $0.localizedCaseInsensitiveContains("somatic movement") }
        #expect(hasLMA,   "catalog must include a dance anatomy or LMA assignment template")
        #expect(hasStudy, "catalog must include a dance science or somatic movement study template")
    }

    // MARK: - Forensic Nursing templates
    @Test func forensicnursingTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasSANE = tasks.contains { $0.localizedCaseInsensitiveContains("SANE") && ($0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("forensic nursing")) }
        let hasNotes = tasks.contains { $0.localizedCaseInsensitiveContains("forensic nursing") && ($0.localizedCaseInsensitiveContains("notes") || $0.localizedCaseInsensitiveContains("documentation")) }
        #expect(hasSANE,  "catalog must include a SANE exam or forensic nursing study template")
        #expect(hasNotes, "catalog must include a forensic nursing documentation template")
    }

    // MARK: - Midwifery Assisting / Doula templates
    @Test func midwiferyassistingTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasDONA = tasks.contains { $0.localizedCaseInsensitiveContains("DONA") && ($0.localizedCaseInsensitiveContains("certification") || $0.localizedCaseInsensitiveContains("doula")) }
        let hasDoula = tasks.contains { $0.localizedCaseInsensitiveContains("birth doula") || $0.localizedCaseInsensitiveContains("postpartum doula") }
        #expect(hasDONA,  "catalog must include a DONA doula certification template")
        #expect(hasDoula, "catalog must include a birth or postpartum doula template")
    }

    // MARK: - Interpreting templates
    @Test func interpretingTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasRID = tasks.contains { $0.localizedCaseInsensitiveContains("RID") && ($0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("interpreter")) }
        let hasPractice = tasks.contains { $0.localizedCaseInsensitiveContains("interpreting") && ($0.localizedCaseInsensitiveContains("consecutive") || $0.localizedCaseInsensitiveContains("simultaneous")) }
        #expect(hasRID,      "catalog must include an RID interpreter certification template")
        #expect(hasPractice, "catalog must include a consecutive or simultaneous interpreting practice template")
    }

    // MARK: - Count guard
    @Test func catalogHasAtLeastThreeHundredSevenTemplates() {
        #expect(SuggestedSessionTemplates.all.count >= 307,
                "catalog should have ≥307 templates after theatresound/dancescience/forensicnursing/midwiferyassisting/interpreting additions")
    }
    @Test func catalogHasAtLeastThreeHundredFifteenTemplates() {
        #expect(SuggestedSessionTemplates.all.count >= 315,
                "catalog should have ≥315 templates after dramatherapy/horsemanship/glassblowing/landsurveyingtech additions")
    }

    // MARK: - Drama Therapy templates
    @Test func dramatherapyTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasNADT = tasks.contains { $0.localizedCaseInsensitiveContains("NADT") || ($0.localizedCaseInsensitiveContains("drama therapy") && $0.localizedCaseInsensitiveContains("exam")) }
        let hasNotes = tasks.contains { $0.localizedCaseInsensitiveContains("drama therapy") && ($0.localizedCaseInsensitiveContains("notes") || $0.localizedCaseInsensitiveContains("treatment plan")) }
        #expect(hasNADT,  "catalog must include a NADT drama therapy exam template")
        #expect(hasNotes, "catalog must include a drama therapy session notes template")
    }

    // MARK: - Horsemanship / Equestrian templates
    @Test func horsemanshipTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasAssignment = tasks.contains { $0.localizedCaseInsensitiveContains("horsemanship") || $0.localizedCaseInsensitiveContains("equestrian") }
        let hasStudy = tasks.contains { $0.localizedCaseInsensitiveContains("horse training") || $0.localizedCaseInsensitiveContains("equine") }
        #expect(hasAssignment, "catalog must include a horsemanship assignment template")
        #expect(hasStudy,      "catalog must include an equine science study template")
    }

    // MARK: - Glassblowing / Glass Arts templates
    @Test func glassblowingTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasStudio = tasks.contains { $0.localizedCaseInsensitiveContains("glassblowing") || $0.localizedCaseInsensitiveContains("flameworking") }
        let hasStudy = tasks.contains { $0.localizedCaseInsensitiveContains("glass arts") || $0.localizedCaseInsensitiveContains("kiln-formed") }
        #expect(hasStudio, "catalog must include a glassblowing or flameworking studio template")
        #expect(hasStudy,  "catalog must include a glass arts study template")
    }

    // MARK: - Land Surveying Technology templates
    @Test func landsurveyingtechTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasAssignment = tasks.contains { $0.localizedCaseInsensitiveContains("land surveying") && $0.localizedCaseInsensitiveContains("assignment") }
        let hasFSExam = tasks.contains { $0.localizedCaseInsensitiveContains("Fundamentals of Surveying") || $0.localizedCaseInsensitiveContains("FS") && $0.localizedCaseInsensitiveContains("surveying") }
        #expect(hasAssignment, "catalog must include a land surveying assignment template")
        #expect(hasFSExam,     "catalog must include a Fundamentals of Surveying exam template")
    }

    // MARK: - Environmental Engineering templates
    @Test func environmentalengineeringTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasAssignment = tasks.contains { $0.localizedCaseInsensitiveContains("environmental engineering") && ($0.localizedCaseInsensitiveContains("wastewater") || $0.localizedCaseInsensitiveContains("water quality") || $0.localizedCaseInsensitiveContains("air quality")) }
        let hasStudy = tasks.contains { $0.localizedCaseInsensitiveContains("environmental engineering") && ($0.localizedCaseInsensitiveContains("remediation") || $0.localizedCaseInsensitiveContains("stormwater")) }
        #expect(hasAssignment, "catalog must include an environmental engineering assignment template")
        #expect(hasStudy,      "catalog must include an environmental engineering study template")
    }

    // MARK: - Technical Writing templates
    @Test func techwritingTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasDoc = tasks.contains { $0.localizedCaseInsensitiveContains("user manual") || $0.localizedCaseInsensitiveContains("API documentation") || $0.localizedCaseInsensitiveContains("technical guide") }
        let hasCPTC = tasks.contains { $0.localizedCaseInsensitiveContains("CPTC") || $0.localizedCaseInsensitiveContains("technical communication") }
        #expect(hasDoc,   "catalog must include a user manual or API docs template")
        #expect(hasCPTC,  "catalog must include a CPTC or technical communication template")
    }

    // MARK: - Health Coaching templates
    @Test func healthcoachingTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasNBHWC = tasks.contains { $0.localizedCaseInsensitiveContains("NBHWC") || ($0.localizedCaseInsensitiveContains("health") && $0.localizedCaseInsensitiveContains("wellness coaching") && $0.localizedCaseInsensitiveContains("certification")) }
        let hasAssignment = tasks.contains { $0.localizedCaseInsensitiveContains("health coaching") && ($0.localizedCaseInsensitiveContains("assignment") || $0.localizedCaseInsensitiveContains("documentation")) }
        #expect(hasNBHWC,      "catalog must include an NBHWC health coaching certification template")
        #expect(hasAssignment, "catalog must include a health coaching assignment template")
    }

    // MARK: - Podiatry templates
    @Test func podiatryTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasAPMLE = tasks.contains { $0.localizedCaseInsensitiveContains("APMLE") || ($0.localizedCaseInsensitiveContains("podiatry") && $0.localizedCaseInsensitiveContains("board")) }
        let hasNotes = tasks.contains { $0.localizedCaseInsensitiveContains("podiatric medicine") || ($0.localizedCaseInsensitiveContains("podiatry") && ($0.localizedCaseInsensitiveContains("notes") || $0.localizedCaseInsensitiveContains("case"))) }
        #expect(hasAPMLE, "catalog must include an APMLE podiatry board exam template")
        #expect(hasNotes, "catalog must include a podiatric medicine case notes template")
    }

    // MARK: - Classical Studies templates
    @Test func classicalstudiesTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasTranslation = tasks.contains { ($0.localizedCaseInsensitiveContains("Latin") || $0.localizedCaseInsensitiveContains("Greek")) && $0.localizedCaseInsensitiveContains("translate") }
        let hasStudy = tasks.contains { $0.localizedCaseInsensitiveContains("classical studies") && ($0.localizedCaseInsensitiveContains("ancient history") || $0.localizedCaseInsensitiveContains("classical literature")) }
        #expect(hasTranslation, "catalog must include a Latin or Greek translation template")
        #expect(hasStudy,       "catalog must include a classical studies study template")
    }

    // MARK: - Count guard (new batch)
    @Test func catalogHasAtLeastThreeHundredTwentyFiveTemplates() {
        #expect(SuggestedSessionTemplates.all.count >= 325,
                "catalog should have ≥325 templates after environmentalengineering/techwriting/healthcoaching/podiatry/classicalstudies additions")
    }

    // MARK: - PM&R / Physiatry templates
    @Test func pmrehabilitationTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasBoard = tasks.contains { $0.localizedCaseInsensitiveContains("ABPMR") || ($0.localizedCaseInsensitiveContains("physiatry") && $0.localizedCaseInsensitiveContains("board")) }
        let hasNotes = tasks.contains { $0.localizedCaseInsensitiveContains("PM&R") && ($0.localizedCaseInsensitiveContains("case notes") || $0.localizedCaseInsensitiveContains("SOAP note") || $0.localizedCaseInsensitiveContains("evaluation")) }
        #expect(hasBoard, "catalog must include an ABPMR physiatry board exam study template")
        #expect(hasNotes, "catalog must include a PM&R case notes or SOAP note template")
    }

    // MARK: - Performance Nutrition / Sports Dietetics templates
    @Test func performancenutritionTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasCSSD = tasks.contains { $0.localizedCaseInsensitiveContains("CSSD") || ($0.localizedCaseInsensitiveContains("sports dietetics") && $0.localizedCaseInsensitiveContains("exam")) }
        let hasFueling = tasks.contains { $0.localizedCaseInsensitiveContains("athlete fueling") || $0.localizedCaseInsensitiveContains("sports nutrition intervention") }
        #expect(hasCSSD,    "catalog must include a CSSD board exam or sports dietetics exam template")
        #expect(hasFueling, "catalog must include an athlete fueling plan or sports nutrition intervention template")
    }

    // MARK: - Horticulture Science templates
    @Test func horticulturescienceTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasAssignment = tasks.contains { $0.localizedCaseInsensitiveContains("horticulture science") && ($0.localizedCaseInsensitiveContains("assignment") || $0.localizedCaseInsensitiveContains("plant physiology")) }
        let hasExam = tasks.contains { ($0.localizedCaseInsensitiveContains("ISA arborist") || $0.localizedCaseInsensitiveContains("PCA exam")) && $0.localizedCaseInsensitiveContains("certification") || ($0.localizedCaseInsensitiveContains("horticulture science") && $0.localizedCaseInsensitiveContains("licensing")) }
        #expect(hasAssignment, "catalog must include a horticulture science assignment or plant physiology template")
        #expect(hasExam,       "catalog must include an ISA arborist, PCA exam, or horticulture licensing template")
    }

    // MARK: - Global Health / International Development templates
    @Test func globalhealthdevTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasMemo = tasks.contains { $0.localizedCaseInsensitiveContains("international development") && ($0.localizedCaseInsensitiveContains("policy memo") || $0.localizedCaseInsensitiveContains("NGO") || $0.localizedCaseInsensitiveContains("proposal")) }
        let hasStudy = tasks.contains { ($0.localizedCaseInsensitiveContains("global health governance") || $0.localizedCaseInsensitiveContains("international development")) && $0.localizedCaseInsensitiveContains("exam") }
        #expect(hasMemo,  "catalog must include an international development policy memo or NGO proposal template")
        #expect(hasStudy, "catalog must include a global health governance or international development exam study template")
    }

    // MARK: - Count guard
    @Test func catalogHasAtLeastThreeHundredThirtyThreeTemplates() {
        #expect(SuggestedSessionTemplates.all.count >= 333,
                "catalog should have ≥333 templates after pmrehabilitation/performancenutrition/horticulturescience/globalhealthdev additions")
    }

    // MARK: - Maritime Studies templates
    @Test func maritimestudiesTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasUSCG = tasks.contains { $0.localizedCaseInsensitiveContains("USCG") && $0.localizedCaseInsensitiveContains("maritime") }
        let hasProject = tasks.contains { $0.localizedCaseInsensitiveContains("maritime") && ($0.localizedCaseInsensitiveContains("law") || $0.localizedCaseInsensitiveContains("port management") || $0.localizedCaseInsensitiveContains("transportation")) }
        #expect(hasUSCG,    "catalog must include a USCG maritime licensing exam template")
        #expect(hasProject, "catalog must include a maritime law or port management project template")
    }

    // MARK: - HVAC Technology templates
    @Test func hvactechnologyTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasEPA608 = tasks.contains { $0.localizedCaseInsensitiveContains("EPA 608") || ($0.localizedCaseInsensitiveContains("HVAC") && $0.localizedCaseInsensitiveContains("certification")) }
        let hasCourse = tasks.contains { $0.localizedCaseInsensitiveContains("HVAC") && ($0.localizedCaseInsensitiveContains("refrigeration") || $0.localizedCaseInsensitiveContains("air conditioning") || $0.localizedCaseInsensitiveContains("trade program")) }
        #expect(hasEPA608, "catalog must include an EPA 608 HVAC certification exam template")
        #expect(hasCourse, "catalog must include an HVAC systems or refrigeration coursework template")
    }

    // MARK: - Construction Management templates
    @Test func constructionmanagementTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasAssignment = tasks.contains { $0.localizedCaseInsensitiveContains("construction management") && ($0.localizedCaseInsensitiveContains("scheduling") || $0.localizedCaseInsensitiveContains("estimating") || $0.localizedCaseInsensitiveContains("project planning")) }
        let hasCCM = tasks.contains { $0.localizedCaseInsensitiveContains("CCM") || ($0.localizedCaseInsensitiveContains("construction") && $0.localizedCaseInsensitiveContains("project management") && $0.localizedCaseInsensitiveContains("class")) }
        #expect(hasAssignment, "catalog must include a construction management scheduling/estimating assignment template")
        #expect(hasCCM,        "catalog must include a CCM exam or construction project management class template")
    }

    // MARK: - Floristry / Wedding Planning templates
    @Test func floristryweddingplanningTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasFloral = tasks.contains { $0.localizedCaseInsensitiveContains("floral design") && ($0.localizedCaseInsensitiveContains("project") || $0.localizedCaseInsensitiveContains("floristry")) }
        let hasWedding = tasks.contains { $0.localizedCaseInsensitiveContains("wedding planning") && ($0.localizedCaseInsensitiveContains("proposal") || $0.localizedCaseInsensitiveContains("venue") || $0.localizedCaseInsensitiveContains("event floral")) }
        #expect(hasFloral,  "catalog must include a floral design project or floristry exam template")
        #expect(hasWedding, "catalog must include a wedding planning or event floral design template")
    }

    // MARK: - Cosmetic Chemistry templates
    @Test func cosmeticchemistryTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasFormulation = tasks.contains { $0.localizedCaseInsensitiveContains("cosmetic chemistry") || ($0.localizedCaseInsensitiveContains("cosmetic") && $0.localizedCaseInsensitiveContains("formulation")) }
        let hasStudy = tasks.contains { $0.localizedCaseInsensitiveContains("cosmetic science") && ($0.localizedCaseInsensitiveContains("emulsification") || $0.localizedCaseInsensitiveContains("preservation") || $0.localizedCaseInsensitiveContains("ingredient")) }
        #expect(hasFormulation, "catalog must include a cosmetic chemistry formulation assignment template")
        #expect(hasStudy,       "catalog must include a cosmetic science study template covering emulsification or preservation")
    }

    // MARK: - Count guard (maritimestudies/hvac/construction/floristry/cosmeticchemistry batch)
    @Test func catalogHasAtLeastThreeHundredFortyFiveTemplates() {
        #expect(SuggestedSessionTemplates.all.count >= 345,
                "catalog should have ≥345 templates after maritimestudies/hvactechnology/constructionmanagement/floristryweddingplanning/cosmeticchemistry additions")
    }

    // MARK: - Automotive Technology templates
    @Test func automotivetechTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasASE     = tasks.contains { $0.localizedCaseInsensitiveContains("ASE") && $0.localizedCaseInsensitiveContains("automotive technology") }
        let hasService = tasks.contains { $0.localizedCaseInsensitiveContains("automotive service") && ($0.localizedCaseInsensitiveContains("engine diagnostics") || $0.localizedCaseInsensitiveContains("brake") || $0.localizedCaseInsensitiveContains("electrical")) }
        #expect(hasASE,     "catalog must include an ASE certification automotive technology template")
        #expect(hasService, "catalog must include an automotive service lab exercises template")
    }

    // MARK: - Welding Technology templates
    @Test func weldingtechnologyTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasCert   = tasks.contains { $0.localizedCaseInsensitiveContains("AWS") || $0.localizedCaseInsensitiveContains("CWI") }
        let hasAssign = tasks.contains { $0.localizedCaseInsensitiveContains("welding technology") && ($0.localizedCaseInsensitiveContains("procedures") || $0.localizedCaseInsensitiveContains("weld testing") || $0.localizedCaseInsensitiveContains("safety")) }
        #expect(hasCert,   "catalog must include an AWS or CWI welding certification template")
        #expect(hasAssign, "catalog must include a welding technology assignment template")
    }

    // MARK: - Grant Writing templates
    @Test func grantwritingTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasAims  = tasks.contains { $0.localizedCaseInsensitiveContains("specific aims") || ($0.localizedCaseInsensitiveContains("NIH") && $0.localizedCaseInsensitiveContains("grant")) }
        let hasDraft = tasks.contains { $0.localizedCaseInsensitiveContains("grant proposal") && $0.localizedCaseInsensitiveContains("funding application") }
        #expect(hasAims,  "catalog must include an NIH specific aims or grant narrative template")
        #expect(hasDraft, "catalog must include a grant proposal drafting template")
    }

    // MARK: - Animal Husbandry templates
    @Test func animalhusbandryTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasHusbandry = tasks.contains { $0.localizedCaseInsensitiveContains("animal husbandry") || $0.localizedCaseInsensitiveContains("livestock management") }
        let hasProduction = tasks.contains { ($0.localizedCaseInsensitiveContains("swine") || $0.localizedCaseInsensitiveContains("poultry") || $0.localizedCaseInsensitiveContains("beef") || $0.localizedCaseInsensitiveContains("dairy")) && $0.localizedCaseInsensitiveContains("animal science") }
        #expect(hasHusbandry,  "catalog must include an animal husbandry or livestock management template")
        #expect(hasProduction, "catalog must include a livestock production exam study template")
    }

    // MARK: - Paralegal templates
    @Test func paralegalTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasCert   = tasks.contains { $0.localizedCaseInsensitiveContains("CLA") || $0.localizedCaseInsensitiveContains("CP") && $0.localizedCaseInsensitiveContains("paralegal") }
        let hasAssign = tasks.contains { $0.localizedCaseInsensitiveContains("paralegal studies") && ($0.localizedCaseInsensitiveContains("legal research") || $0.localizedCaseInsensitiveContains("document drafting") || $0.localizedCaseInsensitiveContains("case analysis")) }
        #expect(hasCert,   "catalog must include a CLA or CP paralegal certification template")
        #expect(hasAssign, "catalog must include a paralegal studies assignment template")
    }

    // MARK: - Count guard (new 5-domain batch: automotivetech/weldingtechnology/grantwriting/animalhusbandry/paralegal)
    @Test func catalogHasAtLeastThreeHundredFiftyFiveTemplates() {
        #expect(SuggestedSessionTemplates.all.count >= 355,
                "catalog should have ≥355 templates after automotivetech/weldingtechnology/grantwriting/animalhusbandry/paralegal additions")
    }

    // MARK: - Certified Financial Planner templates
    @Test func certifiedfinancialplannerTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasCFPExam = tasks.contains { $0.localizedCaseInsensitiveContains("CFP") && ($0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("coursework")) }
        let hasPlan = tasks.contains { $0.localizedCaseInsensitiveContains("financial plan") && ($0.localizedCaseInsensitiveContains("case study") || $0.localizedCaseInsensitiveContains("client")) }
        #expect(hasCFPExam, "catalog must include a CFP exam study template")
        #expect(hasPlan, "catalog must include a client financial plan template")
    }

    // MARK: - Soil Science templates
    @Test func soilscienceTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasLab = tasks.contains { $0.localizedCaseInsensitiveContains("soil science") && ($0.localizedCaseInsensitiveContains("lab report") || $0.localizedCaseInsensitiveContains("field description") || $0.localizedCaseInsensitiveContains("pedology")) }
        let hasExam = tasks.contains { $0.localizedCaseInsensitiveContains("soil science") && ($0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("taxonomy") || $0.localizedCaseInsensitiveContains("classification")) }
        #expect(hasLab, "catalog must include a soil science lab or field description template")
        #expect(hasExam, "catalog must include a soil science exam study template")
    }

    // MARK: - Industrial Safety templates
    @Test func industrialsafetyTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasAssignment = tasks.contains { ($0.localizedCaseInsensitiveContains("industrial hygiene") || $0.localizedCaseInsensitiveContains("occupational safety")) && $0.localizedCaseInsensitiveContains("assignment") }
        let hasCIH = tasks.contains { $0.localizedCaseInsensitiveContains("CIH") || $0.localizedCaseInsensitiveContains("OSHA") && $0.localizedCaseInsensitiveContains("industrial") }
        #expect(hasAssignment, "catalog must include an industrial safety coursework assignment template")
        #expect(hasCIH, "catalog must include a CIH exam or OSHA industrial safety study template")
    }

    // MARK: - Food Safety templates
    @Test func foodsafetyTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasServSafe = tasks.contains { $0.localizedCaseInsensitiveContains("ServSafe") || $0.localizedCaseInsensitiveContains("food safety") && $0.localizedCaseInsensitiveContains("exam") }
        let hasHACCP = tasks.contains { $0.localizedCaseInsensitiveContains("HACCP") || $0.localizedCaseInsensitiveContains("food safety audit") }
        #expect(hasServSafe, "catalog must include a ServSafe or food safety certification exam template")
        #expect(hasHACCP, "catalog must include a HACCP plan or food safety audit template")
    }

    // MARK: - Applied Music templates
    @Test func appliedmusicTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasJury = tasks.contains { $0.localizedCaseInsensitiveContains("jury") || $0.localizedCaseInsensitiveContains("audition") && $0.localizedCaseInsensitiveContains("repertoire") }
        let hasLesson = tasks.contains { $0.localizedCaseInsensitiveContains("applied music") || $0.localizedCaseInsensitiveContains("music lesson") && $0.localizedCaseInsensitiveContains("technique") }
        #expect(hasJury, "catalog must include a music jury or audition repertoire template")
        #expect(hasLesson, "catalog must include an applied music lesson and technique template")
    }

    // MARK: - Count guard (new 5-domain batch: certifiedfinancialplanner/soilscience/industrialsafety/foodsafety/appliedmusic)
    @Test func catalogHasAtLeastThreeHundredSixtyFiveTemplates() {
        #expect(SuggestedSessionTemplates.all.count >= 365,
                "catalog should have ≥365 templates after certifiedfinancialplanner/soilscience/industrialsafety/foodsafety/appliedmusic additions")
    }

    // MARK: - Plumbing Technology templates
    @Test func plumbingtechTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasExam = tasks.contains { $0.localizedCaseInsensitiveContains("plumber exam") || $0.localizedCaseInsensitiveContains("journeyman") && $0.localizedCaseInsensitiveContains("plumb") }
        let hasAssignment = tasks.contains { $0.localizedCaseInsensitiveContains("plumbing technology") || $0.localizedCaseInsensitiveContains("plumbing code") && $0.localizedCaseInsensitiveContains("assignment") }
        #expect(hasExam, "catalog must include a journeyman/master plumber exam study template")
        #expect(hasAssignment, "catalog must include a plumbing technology class assignment template")
    }

    // MARK: - Electrical Technology templates
    @Test func electricaltechnologyTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasExam = tasks.contains { $0.localizedCaseInsensitiveContains("electrician exam") || $0.localizedCaseInsensitiveContains("journeyman") && $0.localizedCaseInsensitiveContains("electric") }
        let hasAssignment = tasks.contains { $0.localizedCaseInsensitiveContains("IBEW") || $0.localizedCaseInsensitiveContains("electrical theory") || $0.localizedCaseInsensitiveContains("electrician program") }
        #expect(hasExam, "catalog must include a journeyman/master electrician exam study template")
        #expect(hasAssignment, "catalog must include an electrical theory or IBEW apprenticeship assignment template")
    }

    // MARK: - Materials Science templates
    @Test func materialscienceTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasLab = tasks.contains { $0.localizedCaseInsensitiveContains("materials science") && ($0.localizedCaseInsensitiveContains("lab report") || $0.localizedCaseInsensitiveContains("phase diagram") || $0.localizedCaseInsensitiveContains("crystallography")) }
        let hasExam = tasks.contains { ($0.localizedCaseInsensitiveContains("materials science") || $0.localizedCaseInsensitiveContains("materials engineering")) && ($0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("metallurgy") || $0.localizedCaseInsensitiveContains("polymer")) }
        #expect(hasLab, "catalog must include a materials science lab report or problem set template")
        #expect(hasExam, "catalog must include a materials science or materials engineering exam study template")
    }

    // MARK: - Network Engineering templates
    @Test func networkengineeringTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasCCNA = tasks.contains { $0.localizedCaseInsensitiveContains("CCNA") || $0.localizedCaseInsensitiveContains("Network+") || $0.localizedCaseInsensitiveContains("CCNP") }
        let hasAssignment = tasks.contains { $0.localizedCaseInsensitiveContains("network engineering") && ($0.localizedCaseInsensitiveContains("assignment") || $0.localizedCaseInsensitiveContains("IP addressing") || $0.localizedCaseInsensitiveContains("routing")) }
        #expect(hasCCNA, "catalog must include a CCNA/CCNP/Network+ exam study template")
        #expect(hasAssignment, "catalog must include a network engineering assignment template")
    }

    // MARK: - Environmental Health templates
    @Test func environmentalhealthTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasREHS = tasks.contains { $0.localizedCaseInsensitiveContains("REHS") || $0.localizedCaseInsensitiveContains("environmental health science") && $0.localizedCaseInsensitiveContains("food safety") }
        let hasReport = tasks.contains { $0.localizedCaseInsensitiveContains("environmental health report") || $0.localizedCaseInsensitiveContains("community environmental health") }
        #expect(hasREHS, "catalog must include a REHS exam or environmental health science assignment template")
        #expect(hasReport, "catalog must include an environmental health report or case study template")
    }

    // MARK: - Construction Technology templates
    @Test func constructiontechTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasExam = tasks.contains { $0.localizedCaseInsensitiveContains("contractor license exam") || $0.localizedCaseInsensitiveContains("construction technology program") && $0.localizedCaseInsensitiveContains("carpentry") }
        let hasAssignment = tasks.contains { $0.localizedCaseInsensitiveContains("building trades") && ($0.localizedCaseInsensitiveContains("assignment") || $0.localizedCaseInsensitiveContains("wood framing")) }
        #expect(hasExam, "catalog must include a contractor license exam or construction tech assignment template")
        #expect(hasAssignment, "catalog must include a building trades class assignment template")
    }

    // MARK: - Urban Design templates
    @Test func urbandesignTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasStudio = tasks.contains { $0.localizedCaseInsensitiveContains("urban design studio") || $0.localizedCaseInsensitiveContains("streetscape") }
        let hasAssignment = tasks.contains { $0.localizedCaseInsensitiveContains("urban design class") && ($0.localizedCaseInsensitiveContains("placemaking") || $0.localizedCaseInsensitiveContains("pedestrian")) }
        #expect(hasStudio, "catalog must include an urban design studio or streetscape design template")
        #expect(hasAssignment, "catalog must include an urban design class placemaking or pedestrian design template")
    }

    // MARK: - Ceramics and Sculpture templates
    @Test func ceramicsandsculptureTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasStudio = tasks.contains { $0.localizedCaseInsensitiveContains("ceramics project") || $0.localizedCaseInsensitiveContains("wheel throwing") }
        let hasExam = tasks.contains { $0.localizedCaseInsensitiveContains("ceramics") && ($0.localizedCaseInsensitiveContains("class exam") || $0.localizedCaseInsensitiveContains("sculpture class exam")) }
        #expect(hasStudio, "catalog must include a ceramics project or wheel throwing template")
        #expect(hasExam, "catalog must include a ceramics class exam template")
    }

    // MARK: - Exercise Science templates
    @Test func exercisescienceTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasACSM = tasks.contains { $0.localizedCaseInsensitiveContains("ACSM exam") || $0.localizedCaseInsensitiveContains("exercise science class") && $0.localizedCaseInsensitiveContains("exercise testing") }
        let hasLab = tasks.contains { $0.localizedCaseInsensitiveContains("exercise science lab report") || $0.localizedCaseInsensitiveContains("VO2 max") }
        #expect(hasACSM, "catalog must include an ACSM exam or exercise science class assignment template")
        #expect(hasLab, "catalog must include an exercise science lab report or VO2 max template")
    }

    // MARK: - Biochemistry templates
    @Test func biochemistryTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasLab = tasks.contains { $0.localizedCaseInsensitiveContains("biochemistry lab report") && ($0.localizedCaseInsensitiveContains("enzyme kinetics") || $0.localizedCaseInsensitiveContains("protein assay")) }
        let hasExam = tasks.contains { $0.localizedCaseInsensitiveContains("biochemistry exam") && ($0.localizedCaseInsensitiveContains("enzyme kinetics") || $0.localizedCaseInsensitiveContains("metabolic pathways")) }
        #expect(hasLab, "catalog must include a biochemistry lab report template")
        #expect(hasExam, "catalog must include a biochemistry exam study template")
    }

    // MARK: - Count guard (5-domain batch: constructiontech/urbandesign/ceramicsandsculpture/exercisescience/biochemistry)
    @Test func catalogHasAtLeastThreeHundredNinetyThreeTemplates() {
        #expect(SuggestedSessionTemplates.all.count >= 393,
                "catalog should have ≥393 templates after constructiontech/urbandesign/ceramicsandsculpture/exercisescience/biochemistry additions")
    }

    // MARK: - Agricultural Science templates
    @Test func agriculturalscienceTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasAssignment = tasks.contains { $0.localizedCaseInsensitiveContains("agricultural science assignment") && ($0.localizedCaseInsensitiveContains("agronomy") || $0.localizedCaseInsensitiveContains("crop production")) }
        let hasExam = tasks.contains { $0.localizedCaseInsensitiveContains("agronomy exam") && ($0.localizedCaseInsensitiveContains("crop science") || $0.localizedCaseInsensitiveContains("soil fertility")) }
        #expect(hasAssignment, "catalog must include an agricultural science assignment template")
        #expect(hasExam, "catalog must include an agronomy exam study template")
    }

    // MARK: - Textiles Fashion templates
    @Test func textilesfashionTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasStudio = tasks.contains { ($0.localizedCaseInsensitiveContains("fiber arts") || $0.localizedCaseInsensitiveContains("weaving project")) && ($0.localizedCaseInsensitiveContains("natural dyeing") || $0.localizedCaseInsensitiveContains("spinning")) }
        let hasAssignment = tasks.contains { $0.localizedCaseInsensitiveContains("textile") && ($0.localizedCaseInsensitiveContains("class assignment") || $0.localizedCaseInsensitiveContains("engineering assignment")) }
        #expect(hasStudio, "catalog must include a fiber arts weaving or natural dyeing studio template")
        #expect(hasAssignment, "catalog must include a textile science or textile engineering assignment template")
    }

    // MARK: - Geography Earth Ed templates
    @Test func geographyearthedTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasExam = tasks.contains { ($0.localizedCaseInsensitiveContains("AP Human Geography") || $0.localizedCaseInsensitiveContains("geography exam")) && ($0.localizedCaseInsensitiveContains("physical geography") || $0.localizedCaseInsensitiveContains("world geography")) }
        let hasAssignment = tasks.contains { $0.localizedCaseInsensitiveContains("geography class assignment") && ($0.localizedCaseInsensitiveContains("human geography") || $0.localizedCaseInsensitiveContains("cultural geography")) }
        #expect(hasExam, "catalog must include an AP Human Geography or geography exam template")
        #expect(hasAssignment, "catalog must include a geography class assignment template")
    }

    // MARK: - Child Life templates
    @Test func childlifeTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasExam = tasks.contains { $0.localizedCaseInsensitiveContains("CCLS") && ($0.localizedCaseInsensitiveContains("board exam") || $0.localizedCaseInsensitiveContains("certification assignment")) }
        let hasNotes = tasks.contains { ($0.localizedCaseInsensitiveContains("child life session notes") || $0.localizedCaseInsensitiveContains("therapeutic play treatment plan")) && $0.localizedCaseInsensitiveContains("pediatric") }
        #expect(hasExam, "catalog must include a CCLS board exam or child life certification template")
        #expect(hasNotes, "catalog must include a child life session notes or therapeutic play treatment plan template")
    }

    // MARK: - Quality Management templates
    @Test func qualitymanagementTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasExam = tasks.contains { $0.localizedCaseInsensitiveContains("CQE exam") && ($0.localizedCaseInsensitiveContains("statistical process control") || $0.localizedCaseInsensitiveContains("ISO auditing")) }
        let hasAssignment = tasks.contains { $0.localizedCaseInsensitiveContains("quality management") && ($0.localizedCaseInsensitiveContains("ISO 9001") || $0.localizedCaseInsensitiveContains("quality assurance")) }
        #expect(hasExam, "catalog must include an ASQ CQE exam or quality engineering template")
        #expect(hasAssignment, "catalog must include a quality management ISO 9001 assignment template")
    }

    // MARK: - Count guard (5-domain batch: agriculturalscience/textilesfashion/geographyearthed/childlife/qualitymanagement)
    @Test func catalogHasAtLeastFourHundredThreeTemplates() {
        #expect(SuggestedSessionTemplates.all.count >= 403,
                "catalog should have ≥403 templates after agriculturalscience/textilesfashion/geographyearthed/childlife/qualitymanagement additions")
    }

    // MARK: - Quantum Computing templates
    @Test func quantumcomputingTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasCircuit = tasks.contains { $0.localizedCaseInsensitiveContains("quantum circuit") && ($0.localizedCaseInsensitiveContains("Qiskit") || $0.localizedCaseInsensitiveContains("IBM Quantum")) }
        let hasStudy = tasks.contains { $0.localizedCaseInsensitiveContains("quantum computing") && ($0.localizedCaseInsensitiveContains("quantum gates") || $0.localizedCaseInsensitiveContains("quantum algorithms")) }
        #expect(hasCircuit, "catalog must include a Qiskit quantum circuit template")
        #expect(hasStudy, "catalog must include a quantum computing study/exam template")
    }

    // MARK: - Cloud Computing templates
    @Test func cloudcomputingTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasCert = tasks.contains { ($0.localizedCaseInsensitiveContains("AWS") || $0.localizedCaseInsensitiveContains("Azure") || $0.localizedCaseInsensitiveContains("GCP")) && $0.localizedCaseInsensitiveContains("cloud certification") }
        let hasDevOps = tasks.contains { ($0.localizedCaseInsensitiveContains("DevOps") || $0.localizedCaseInsensitiveContains("Terraform") || $0.localizedCaseInsensitiveContains("Kubernetes")) && $0.localizedCaseInsensitiveContains("cloud computing") }
        #expect(hasCert, "catalog must include an AWS/Azure/GCP cloud certification template")
        #expect(hasDevOps, "catalog must include a DevOps/Terraform/Kubernetes cloud computing template")
    }

    // MARK: - Software Testing templates
    @Test func softwaretestingTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasISTQB = tasks.contains { $0.localizedCaseInsensitiveContains("ISTQB") && ($0.localizedCaseInsensitiveContains("software testing") || $0.localizedCaseInsensitiveContains("QA engineering")) }
        let hasAutomation = tasks.contains { ($0.localizedCaseInsensitiveContains("Selenium") || $0.localizedCaseInsensitiveContains("pytest") || $0.localizedCaseInsensitiveContains("JUnit")) && $0.localizedCaseInsensitiveContains("automated tests") }
        #expect(hasISTQB, "catalog must include an ISTQB or software testing exam template")
        #expect(hasAutomation, "catalog must include a Selenium/pytest/JUnit test automation template")
    }

    // MARK: - Mechanical Drafting templates
    @Test func mechanicaldraftingTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasAssignment = tasks.contains { ($0.localizedCaseInsensitiveContains("mechanical drafting") || $0.localizedCaseInsensitiveContains("AutoCAD")) && ($0.localizedCaseInsensitiveContains("technical drawing") || $0.localizedCaseInsensitiveContains("blueprint reading")) }
        let hasStudy = tasks.contains { $0.localizedCaseInsensitiveContains("engineering drawing") && ($0.localizedCaseInsensitiveContains("blueprint reading") || $0.localizedCaseInsensitiveContains("orthographic")) }
        #expect(hasAssignment, "catalog must include a mechanical drafting / AutoCAD assignment template")
        #expect(hasStudy, "catalog must include an engineering drawing / blueprint reading study template")
    }

    // MARK: - Data Engineering templates
    @Test func dataengineeringTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasPipeline = tasks.contains { ($0.localizedCaseInsensitiveContains("ETL pipeline") || $0.localizedCaseInsensitiveContains("Apache Spark") || $0.localizedCaseInsensitiveContains("Kafka")) && $0.localizedCaseInsensitiveContains("data engineering") }
        let hasWarehouse = tasks.contains { ($0.localizedCaseInsensitiveContains("data warehouse") || $0.localizedCaseInsensitiveContains("dbt") || $0.localizedCaseInsensitiveContains("Snowflake")) && $0.localizedCaseInsensitiveContains("data engineering") }
        #expect(hasPipeline, "catalog must include an ETL/Spark/Kafka data engineering pipeline template")
        #expect(hasWarehouse, "catalog must include a data warehouse/dbt/Snowflake data engineering template")
    }

    // MARK: - Count guard (batch: quantumcomputing/cloudcomputing/softwaretesting/mechanicaldrafting/dataengineering)
    @Test func catalogHasAtLeastFourHundredThirteenTemplates() {
        #expect(SuggestedSessionTemplates.all.count >= 413,
                "catalog should have ≥413 templates after quantumcomputing/cloudcomputing/softwaretesting/mechanicaldrafting/dataengineering additions")
    }

    // MARK: - Robotics templates
    @Test func roboticsTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasProject = tasks.contains { $0.localizedCaseInsensitiveContains("robotics") && ($0.localizedCaseInsensitiveContains("ROS") || $0.localizedCaseInsensitiveContains("lab")) }
        let hasStudy = tasks.contains { $0.localizedCaseInsensitiveContains("robotics exam") && ($0.localizedCaseInsensitiveContains("autonomous") || $0.localizedCaseInsensitiveContains("kinematics")) }
        #expect(hasProject, "catalog must include a robotics project / ROS lab template")
        #expect(hasStudy,   "catalog must include a robotics exam / autonomous systems study template")
    }

    // MARK: - Artificial Intelligence templates
    @Test func artificialintelligenceTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasAssignment = tasks.contains { $0.localizedCaseInsensitiveContains("artificial intelligence") && ($0.localizedCaseInsensitiveContains("assignment") || $0.localizedCaseInsensitiveContains("search algorithm")) }
        let hasEthics = tasks.contains { ($0.localizedCaseInsensitiveContains("AI ethics") || $0.localizedCaseInsensitiveContains("responsible AI")) && ($0.localizedCaseInsensitiveContains("paper") || $0.localizedCaseInsensitiveContains("reflection")) }
        #expect(hasAssignment, "catalog must include an AI class assignment template")
        #expect(hasEthics,     "catalog must include an AI ethics / responsible AI paper template")
    }

    // MARK: - Osteopathic Medicine templates
    @Test func osteopathicmedicineTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasCOMLEX = tasks.contains { $0.localizedCaseInsensitiveContains("COMLEX") && ($0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("osteopathic medicine")) }
        let hasOMM = tasks.contains { $0.localizedCaseInsensitiveContains("OMM") && ($0.localizedCaseInsensitiveContains("session notes") || $0.localizedCaseInsensitiveContains("manipulative medicine")) }
        #expect(hasCOMLEX, "catalog must include a COMLEX exam / osteopathic medicine study template")
        #expect(hasOMM,    "catalog must include an OMM session notes / DO clinical template")
    }

    // MARK: - Epidemiology templates
    @Test func epidemiologyTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasAssignment = tasks.contains { $0.localizedCaseInsensitiveContains("epidemiology") && ($0.localizedCaseInsensitiveContains("study") || $0.localizedCaseInsensitiveContains("outbreak")) }
        let hasStudy = tasks.contains { ($0.localizedCaseInsensitiveContains("epidemiology") || $0.localizedCaseInsensitiveContains("biostatistics")) && ($0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("epi concepts")) }
        #expect(hasAssignment, "catalog must include an epidemiology study design / outbreak template")
        #expect(hasStudy,      "catalog must include an epidemiology or biostatistics exam study template")
    }

    // MARK: - Bioethics templates
    @Test func bioethicsTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasIRB = tasks.contains { $0.localizedCaseInsensitiveContains("IRB") && ($0.localizedCaseInsensitiveContains("protocol") || $0.localizedCaseInsensitiveContains("human subjects")) }
        let hasPaper = tasks.contains { $0.localizedCaseInsensitiveContains("bioethics") && ($0.localizedCaseInsensitiveContains("case") || $0.localizedCaseInsensitiveContains("paper")) }
        #expect(hasIRB,   "catalog must include an IRB protocol / human subjects research template")
        #expect(hasPaper, "catalog must include a bioethics case analysis / medical ethics paper template")
    }

    // MARK: - Count guard (batch: robotics/artificialintelligence/osteopathicmedicine/epidemiology/bioethics)
    @Test func catalogHasAtLeastFourHundredTwentyThreeTemplates() {
        #expect(SuggestedSessionTemplates.all.count >= 423,
                "catalog should have ≥423 templates after robotics/artificialintelligence/osteopathicmedicine/epidemiology/bioethics additions")
    }

    // MARK: - Blockchain templates
    @Test func blockchainTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasSmartContract = tasks.contains { $0.localizedCaseInsensitiveContains("smart contract") && ($0.localizedCaseInsensitiveContains("Solidity") || $0.localizedCaseInsensitiveContains("blockchain")) }
        let hasExam = tasks.contains { $0.localizedCaseInsensitiveContains("blockchain") && ($0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("consensus")) }
        #expect(hasSmartContract, "catalog must include a smart contract / Solidity blockchain template")
        #expect(hasExam, "catalog must include a blockchain exam / distributed ledger study template")
    }

    // MARK: - Digital marketing templates
    @Test func digitalmarketingTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasCert = tasks.contains { $0.localizedCaseInsensitiveContains("Google Analytics") || ($0.localizedCaseInsensitiveContains("digital marketing") && $0.localizedCaseInsensitiveContains("certification")) }
        let hasAssignment = tasks.contains { $0.localizedCaseInsensitiveContains("digital marketing") && ($0.localizedCaseInsensitiveContains("assignment") || $0.localizedCaseInsensitiveContains("SEO") || $0.localizedCaseInsensitiveContains("content marketing")) }
        #expect(hasCert, "catalog must include a digital marketing certification / Google Analytics template")
        #expect(hasAssignment, "catalog must include a digital marketing assignment / SEO template")
    }

    // MARK: - Project management templates
    @Test func projectmanagementTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasPMP = tasks.contains { $0.localizedCaseInsensitiveContains("PMP") || ($0.localizedCaseInsensitiveContains("agile") && $0.localizedCaseInsensitiveContains("certification")) }
        let hasAssignment = tasks.contains { $0.localizedCaseInsensitiveContains("project management") && ($0.localizedCaseInsensitiveContains("assignment") || $0.localizedCaseInsensitiveContains("WBS") || $0.localizedCaseInsensitiveContains("sprint")) }
        #expect(hasPMP, "catalog must include a PMP / agile certification exam study template")
        #expect(hasAssignment, "catalog must include a project management assignment / WBS template")
    }

    // MARK: - Risk management templates
    @Test func riskmanagementTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasCert = tasks.contains { $0.localizedCaseInsensitiveContains("RIMS") || ($0.localizedCaseInsensitiveContains("risk management") && $0.localizedCaseInsensitiveContains("certification")) }
        let hasAssignment = tasks.contains { $0.localizedCaseInsensitiveContains("risk management") && ($0.localizedCaseInsensitiveContains("assignment") || $0.localizedCaseInsensitiveContains("GRC") || $0.localizedCaseInsensitiveContains("risk assessment")) }
        #expect(hasCert, "catalog must include a RIMS / ERM certification exam study template")
        #expect(hasAssignment, "catalog must include a risk management assignment / GRC template")
    }

    // MARK: - Speech communication templates
    @Test func speechcommunicationTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasSpeech = tasks.contains { $0.localizedCaseInsensitiveContains("speech") && ($0.localizedCaseInsensitiveContains("public speaking") || $0.localizedCaseInsensitiveContains("rehearse")) }
        let hasDebate = tasks.contains { $0.localizedCaseInsensitiveContains("debate") && ($0.localizedCaseInsensitiveContains("arguments") || $0.localizedCaseInsensitiveContains("rebuttal")) }
        #expect(hasSpeech, "catalog must include a public speaking / speech rehearsal template")
        #expect(hasDebate, "catalog must include a debate arguments / rebuttal preparation template")
    }

    // MARK: - Count guard (batch: blockchain/digitalmarketing/projectmanagement/riskmanagement/speechcommunication)
    @Test func catalogHasAtLeastFourHundredThirtyThreeTemplates() {
        #expect(SuggestedSessionTemplates.all.count >= 433,
                "catalog should have ≥433 templates after blockchain/digitalmarketing/projectmanagement/riskmanagement/speechcommunication additions")
    }

    // MARK: - Audiology templates
    @Test func audiologyTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasPRAXIS = tasks.contains { $0.localizedCaseInsensitiveContains("PRAXIS audiology") || ($0.localizedCaseInsensitiveContains("audiology") && $0.localizedCaseInsensitiveContains("exam")) }
        let hasClinical = tasks.contains { $0.localizedCaseInsensitiveContains("audiology") && ($0.localizedCaseInsensitiveContains("clinical notes") || $0.localizedCaseInsensitiveContains("externship")) }
        #expect(hasPRAXIS, "catalog must include a PRAXIS audiology exam study template")
        #expect(hasClinical, "catalog must include an audiology clinical notes / externship template")
    }

    // MARK: - Behavior analysis templates
    @Test func behavioranalysisTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasBIP = tasks.contains { $0.localizedCaseInsensitiveContains("behavior intervention plan") || ($0.localizedCaseInsensitiveContains("applied behavior analysis") && $0.localizedCaseInsensitiveContains("assignment")) }
        let hasBCBA = tasks.contains { $0.localizedCaseInsensitiveContains("BCBA") || ($0.localizedCaseInsensitiveContains("behavior analysis") && $0.localizedCaseInsensitiveContains("certification")) }
        #expect(hasBIP, "catalog must include an ABA assignment / behavior intervention plan template")
        #expect(hasBCBA, "catalog must include a BCBA / RBT certification exam study template")
    }

    // MARK: - Radiation therapy templates
    @Test func radiationtherapyTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasARRT = tasks.contains { $0.localizedCaseInsensitiveContains("ARRT radiation therapy") || ($0.localizedCaseInsensitiveContains("radiation therapy") && $0.localizedCaseInsensitiveContains("dosimetry")) }
        let hasAssignment = tasks.contains { $0.localizedCaseInsensitiveContains("radiation therapy") && ($0.localizedCaseInsensitiveContains("assignment") || $0.localizedCaseInsensitiveContains("linear accelerator") || $0.localizedCaseInsensitiveContains("treatment planning")) }
        #expect(hasARRT, "catalog must include an ARRT radiation therapy exam study template")
        #expect(hasAssignment, "catalog must include a radiation therapy class assignment / treatment planning template")
    }

    // MARK: - Orthotics templates
    @Test func orthoticsTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasOandP = tasks.contains { ($0.localizedCaseInsensitiveContains("orthotics and prosthetics") || $0.localizedCaseInsensitiveContains("O&P")) && ($0.localizedCaseInsensitiveContains("assignment") || $0.localizedCaseInsensitiveContains("design")) }
        let hasCPO = tasks.contains { $0.localizedCaseInsensitiveContains("CPO") || ($0.localizedCaseInsensitiveContains("orthotics") && $0.localizedCaseInsensitiveContains("board exam")) }
        #expect(hasOandP, "catalog must include an O&P class assignment / device design template")
        #expect(hasCPO, "catalog must include a CPO / CPT board exam study template")
    }

    // MARK: - Health physics templates
    @Test func healthphysicsTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasCHP = tasks.contains { $0.localizedCaseInsensitiveContains("CHP board exam") || ($0.localizedCaseInsensitiveContains("health physics") && $0.localizedCaseInsensitiveContains("certification")) }
        let hasAssignment = tasks.contains { ($0.localizedCaseInsensitiveContains("health physics") || $0.localizedCaseInsensitiveContains("radiation safety")) && ($0.localizedCaseInsensitiveContains("assignment") || $0.localizedCaseInsensitiveContains("shielding")) }
        #expect(hasCHP, "catalog must include a CHP board exam / health physics certification study template")
        #expect(hasAssignment, "catalog must include a health physics / radiation safety assignment template")
    }

    // MARK: - Count guard (batch: audiology/behavioranalysis/radiationtherapy/orthotics/healthphysics)
    @Test func catalogHasAtLeastFourHundredFortyThreeTemplates() {
        #expect(SuggestedSessionTemplates.all.count >= 443,
                "catalog should have ≥443 templates after audiology/behavioranalysis/radiationtherapy/orthotics/healthphysics additions")
    }

    // MARK: - Information systems templates
    @Test func informationsystemsTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasMIS = tasks.contains { $0.localizedCaseInsensitiveContains("MIS") || ($0.localizedCaseInsensitiveContains("information systems") && ($0.localizedCaseInsensitiveContains("assignment") || $0.localizedCaseInsensitiveContains("exam"))) }
        let hasSAP = tasks.contains { $0.localizedCaseInsensitiveContains("systems analysis") || $0.localizedCaseInsensitiveContains("enterprise systems") || $0.localizedCaseInsensitiveContains("SAP") }
        #expect(hasMIS, "catalog must include an MIS / information systems assignment or exam template")
        #expect(hasSAP, "catalog must include a systems analysis / enterprise systems / SAP template")
    }

    // MARK: - Business intelligence templates
    @Test func businessintelligenceTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasTableau = tasks.contains { $0.localizedCaseInsensitiveContains("Tableau") || $0.localizedCaseInsensitiveContains("Power BI") }
        let hasBICert = tasks.contains { $0.localizedCaseInsensitiveContains("business intelligence") && ($0.localizedCaseInsensitiveContains("certification") || $0.localizedCaseInsensitiveContains("dashboard")) }
        #expect(hasTableau, "catalog must include a Tableau or Power BI template")
        #expect(hasBICert, "catalog must include a business intelligence certification or dashboard template")
    }

    // MARK: - International relations templates
    @Test func internationalrelationsTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasIRPaper = tasks.contains { $0.localizedCaseInsensitiveContains("international relations") && ($0.localizedCaseInsensitiveContains("paper") || $0.localizedCaseInsensitiveContains("analysis")) }
        let hasIRExam = tasks.contains { $0.localizedCaseInsensitiveContains("international relations") && $0.localizedCaseInsensitiveContains("exam") }
        #expect(hasIRPaper, "catalog must include an international relations paper or analysis template")
        #expect(hasIRExam, "catalog must include an international relations exam study template")
    }

    // MARK: - Public administration templates
    @Test func publicadministrationTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasMPA = tasks.contains { $0.localizedCaseInsensitiveContains("MPA") || ($0.localizedCaseInsensitiveContains("public administration") && $0.localizedCaseInsensitiveContains("class")) }
        let hasCivilService = tasks.contains { $0.localizedCaseInsensitiveContains("civil service") || ($0.localizedCaseInsensitiveContains("public administration") && $0.localizedCaseInsensitiveContains("exam")) }
        #expect(hasMPA, "catalog must include an MPA class / public administration assignment template")
        #expect(hasCivilService, "catalog must include a civil service exam / public administration exam study template")
    }

    // MARK: - Labor law templates
    @Test func laborlawTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasEmploymentLawPaper = tasks.contains { $0.localizedCaseInsensitiveContains("employment law") && ($0.localizedCaseInsensitiveContains("paper") || $0.localizedCaseInsensitiveContains("labor law")) }
        let hasLaborExam = tasks.contains { ($0.localizedCaseInsensitiveContains("labor law") || $0.localizedCaseInsensitiveContains("employment law")) && ($0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("class")) }
        #expect(hasEmploymentLawPaper, "catalog must include an employment law / labor law paper template")
        #expect(hasLaborExam, "catalog must include a labor law / employment law exam study template")
    }

    // MARK: - Count guard (batch: informationsystems/businessintelligence/internationalrelations/publicadministration/laborlaw)
    @Test func catalogHasAtLeastFourHundredFiftyThreeTemplates() {
        #expect(SuggestedSessionTemplates.all.count >= 453,
                "catalog should have ≥453 templates after informationsystems/businessintelligence/internationalrelations/publicadministration/laborlaw additions")
    }

    // MARK: - Veterinary technology templates
    @Test func veterinarytechnologyTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasVTNE = tasks.contains { $0.localizedCaseInsensitiveContains("VTNE") || ($0.localizedCaseInsensitiveContains("vet tech") && $0.localizedCaseInsensitiveContains("exam")) }
        let hasVetTechAssignment = tasks.contains { $0.localizedCaseInsensitiveContains("veterinary technology") || ($0.localizedCaseInsensitiveContains("vet tech") && $0.localizedCaseInsensitiveContains("assignment")) }
        #expect(hasVTNE, "catalog must include a VTNE or vet tech exam study template")
        #expect(hasVetTechAssignment, "catalog must include a veterinary technology class assignment template")
    }

    // MARK: - Dental radiology templates
    @Test func dentalradiologyTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasDANBRHS = tasks.contains { $0.localizedCaseInsensitiveContains("DANB RHS") || ($0.localizedCaseInsensitiveContains("dental radiography") && $0.localizedCaseInsensitiveContains("exam")) }
        let hasDentalRadClass = tasks.contains { $0.localizedCaseInsensitiveContains("dental radiography") && ($0.localizedCaseInsensitiveContains("assignment") || $0.localizedCaseInsensitiveContains("class")) }
        #expect(hasDANBRHS, "catalog must include a DANB RHS dental radiography exam template")
        #expect(hasDentalRadClass, "catalog must include a dental radiography class assignment template")
    }

    // MARK: - Medical scribing templates
    @Test func medicalscribingTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasScribePractice = tasks.contains { $0.localizedCaseInsensitiveContains("medical scribing") || ($0.localizedCaseInsensitiveContains("patient encounter") && $0.localizedCaseInsensitiveContains("note")) }
        let hasScribeCert = tasks.contains { $0.localizedCaseInsensitiveContains("scribe certification") || ($0.localizedCaseInsensitiveContains("medical scribe") && $0.localizedCaseInsensitiveContains("certification")) }
        #expect(hasScribePractice, "catalog must include a medical scribing practice template")
        #expect(hasScribeCert, "catalog must include a medical scribe certification study template")
    }

    // MARK: - Community health templates
    @Test func communityhealthTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasCHES = tasks.contains { $0.localizedCaseInsensitiveContains("CHES") || ($0.localizedCaseInsensitiveContains("CHW") && $0.localizedCaseInsensitiveContains("certification")) }
        let hasCHWAssignment = tasks.contains { ($0.localizedCaseInsensitiveContains("community health") || $0.localizedCaseInsensitiveContains("CHW")) && ($0.localizedCaseInsensitiveContains("assignment") || $0.localizedCaseInsensitiveContains("outreach")) }
        #expect(hasCHES, "catalog must include a CHES or CHW certification study template")
        #expect(hasCHWAssignment, "catalog must include a community health / CHW class assignment template")
    }

    // MARK: - Toxicology templates
    @Test func toxicologyTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasToxExam = tasks.contains { $0.localizedCaseInsensitiveContains("toxicology") && $0.localizedCaseInsensitiveContains("exam") }
        let hasToxAssignment = tasks.contains { $0.localizedCaseInsensitiveContains("toxicology") && ($0.localizedCaseInsensitiveContains("assignment") || $0.localizedCaseInsensitiveContains("lab report") || $0.localizedCaseInsensitiveContains("forensic")) }
        #expect(hasToxExam, "catalog must include a toxicology exam study template")
        #expect(hasToxAssignment, "catalog must include a toxicology assignment or lab report template")
    }

    // MARK: - Count guard (veterinarytechnology/dentalradiology/medicalscribing/communityhealth/toxicology)
    @Test func catalogHasAtLeastFourHundredSixtyThreeTemplates() {
        #expect(SuggestedSessionTemplates.all.count >= 463,
                "catalog should have ≥463 templates after veterinarytechnology/dentalradiology/medicalscribing/communityhealth/toxicology additions")
    }

    // MARK: - performanceanalysis templates
    @Test func performanceanalysisTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasFilmAnalysis = tasks.contains { $0.localizedCaseInsensitiveContains("performance analysis") && ($0.localizedCaseInsensitiveContains("Dartfish") || $0.localizedCaseInsensitiveContains("Hudl") || $0.localizedCaseInsensitiveContains("game film") || $0.localizedCaseInsensitiveContains("match")) }
        let hasAssignment = tasks.contains { $0.localizedCaseInsensitiveContains("performance analysis") && ($0.localizedCaseInsensitiveContains("assignment") || $0.localizedCaseInsensitiveContains("notational") || $0.localizedCaseInsensitiveContains("coaching analytics")) }
        #expect(hasFilmAnalysis, "catalog must include a performance analysis / game film template")
        #expect(hasAssignment, "catalog must include a performance analysis class assignment template")
    }

    // MARK: - musicbusiness templates
    @Test func musicbusinessTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasExam = tasks.contains { $0.localizedCaseInsensitiveContains("music business") && ($0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("royalt") || $0.localizedCaseInsensitiveContains("publishing")) }
        let hasPaper = tasks.contains { $0.localizedCaseInsensitiveContains("music business") && ($0.localizedCaseInsensitiveContains("paper") || $0.localizedCaseInsensitiveContains("assignment") || $0.localizedCaseInsensitiveContains("entertainment law")) }
        #expect(hasExam, "catalog must include a music business exam study template")
        #expect(hasPaper, "catalog must include a music business paper or assignment template")
    }

    // MARK: - dentalanesthesia templates
    @Test func dentalanesthesiaTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasCOMSExam = tasks.contains { ($0.localizedCaseInsensitiveContains("COMS") || $0.localizedCaseInsensitiveContains("DOCS") || $0.localizedCaseInsensitiveContains("dental anesthesia")) && $0.localizedCaseInsensitiveContains("exam") }
        let hasAssignment = tasks.contains { $0.localizedCaseInsensitiveContains("dental anesthesia") && ($0.localizedCaseInsensitiveContains("assignment") || $0.localizedCaseInsensitiveContains("sedation")) }
        #expect(hasCOMSExam, "catalog must include a dental anesthesia board exam study template")
        #expect(hasAssignment, "catalog must include a dental anesthesia class assignment template")
    }

    // MARK: - palliativecare templates
    @Test func palliativecareTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasCHPNExam = tasks.contains { ($0.localizedCaseInsensitiveContains("CHPN") || $0.localizedCaseInsensitiveContains("palliative care")) && $0.localizedCaseInsensitiveContains("exam") }
        let hasNotes = tasks.contains { ($0.localizedCaseInsensitiveContains("palliative care") || $0.localizedCaseInsensitiveContains("hospice")) && ($0.localizedCaseInsensitiveContains("notes") || $0.localizedCaseInsensitiveContains("care plan") || $0.localizedCaseInsensitiveContains("assignment")) }
        #expect(hasCHPNExam, "catalog must include a CHPN or palliative care exam study template")
        #expect(hasNotes, "catalog must include a palliative care or hospice notes template")
    }

    // MARK: - cognitivescience templates
    @Test func cognitivescienceTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasExam = tasks.contains { $0.localizedCaseInsensitiveContains("cognitive science") && $0.localizedCaseInsensitiveContains("exam") }
        let hasPaper = tasks.contains { ($0.localizedCaseInsensitiveContains("cogsci") || $0.localizedCaseInsensitiveContains("cognitive science")) && ($0.localizedCaseInsensitiveContains("paper") || $0.localizedCaseInsensitiveContains("assignment")) }
        #expect(hasExam, "catalog must include a cognitive science exam study template")
        #expect(hasPaper, "catalog must include a cogsci paper or assignment template")
    }

    // MARK: - Count guard (performanceanalysis/musicbusiness/dentalanesthesia/palliativecare/cognitivescience)
    @Test func catalogHasAtLeastFourHundredSeventyThreeTemplates() {
        #expect(SuggestedSessionTemplates.all.count >= 473,
                "catalog should have ≥473 templates after performanceanalysis/musicbusiness/dentalanesthesia/palliativecare/cognitivescience additions")
    }

    // MARK: - informationassurance
    @Test func informationassuranceTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasExam = tasks.contains {
            ($0.localizedCaseInsensitiveContains("CISM") || $0.localizedCaseInsensitiveContains("CRISC") || $0.localizedCaseInsensitiveContains("information assurance")) &&
            ($0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("certification"))
        }
        let hasAssignment = tasks.contains {
            $0.localizedCaseInsensitiveContains("information assurance") &&
            ($0.localizedCaseInsensitiveContains("assignment") || $0.localizedCaseInsensitiveContains("governance") || $0.localizedCaseInsensitiveContains("RMF"))
        }
        #expect(hasExam, "catalog must include an information assurance exam/cert study template")
        #expect(hasAssignment, "catalog must include an information assurance assignment or governance template")
    }

    // MARK: - hrmanagement
    @Test func hrmanagementTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasExam = tasks.contains {
            ($0.localizedCaseInsensitiveContains("SHRM") || $0.localizedCaseInsensitiveContains("PHR") || $0.localizedCaseInsensitiveContains("SPHR")) &&
            ($0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("certification"))
        }
        let hasAssignment = tasks.contains {
            $0.localizedCaseInsensitiveContains("human resource management") &&
            ($0.localizedCaseInsensitiveContains("assignment") || $0.localizedCaseInsensitiveContains("talent") || $0.localizedCaseInsensitiveContains("compensation"))
        }
        #expect(hasExam, "catalog must include a SHRM/PHR exam study template")
        #expect(hasAssignment, "catalog must include a human resource management assignment template")
    }

    // MARK: - changemanagement
    @Test func changemanagementTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasExam = tasks.contains {
            ($0.localizedCaseInsensitiveContains("Prosci") || $0.localizedCaseInsensitiveContains("ADKAR") || $0.localizedCaseInsensitiveContains("CCMP")) &&
            ($0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("cert"))
        }
        let hasAssignment = tasks.contains {
            ($0.localizedCaseInsensitiveContains("change management") || $0.localizedCaseInsensitiveContains("organizational change")) &&
            ($0.localizedCaseInsensitiveContains("assignment") || $0.localizedCaseInsensitiveContains("stakeholder") || $0.localizedCaseInsensitiveContains("class"))
        }
        #expect(hasExam, "catalog must include a Prosci/ADKAR/CCMP exam or cert template")
        #expect(hasAssignment, "catalog must include a change management assignment template")
    }

    // MARK: - economics
    @Test func economicsTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasExam = tasks.contains {
            ($0.localizedCaseInsensitiveContains("microeconomics") || $0.localizedCaseInsensitiveContains("macroeconomics") || $0.localizedCaseInsensitiveContains("economics")) &&
            $0.localizedCaseInsensitiveContains("exam")
        }
        let hasAssignment = tasks.contains {
            ($0.localizedCaseInsensitiveContains("economics") || $0.localizedCaseInsensitiveContains("econometrics")) &&
            ($0.localizedCaseInsensitiveContains("problem set") || $0.localizedCaseInsensitiveContains("assignment") || $0.localizedCaseInsensitiveContains("regression"))
        }
        #expect(hasExam, "catalog must include an economics exam study template")
        #expect(hasAssignment, "catalog must include an economics problem set or assignment template")
    }

    // MARK: - iopsychology
    @Test func iopsychologyTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasExam = tasks.contains {
            ($0.localizedCaseInsensitiveContains("industrial-organizational") || $0.localizedCaseInsensitiveContains("I/O psychology")) &&
            $0.localizedCaseInsensitiveContains("exam")
        }
        let hasPaper = tasks.contains {
            ($0.localizedCaseInsensitiveContains("I/O psychology") || $0.localizedCaseInsensitiveContains("organizational psychology")) &&
            ($0.localizedCaseInsensitiveContains("paper") || $0.localizedCaseInsensitiveContains("assignment") || $0.localizedCaseInsensitiveContains("personnel selection"))
        }
        #expect(hasExam, "catalog must include an industrial-organizational psychology exam template")
        #expect(hasPaper, "catalog must include an I/O or organizational psychology paper/assignment template")
    }

    // MARK: - Count guard (informationassurance/hrmanagement/changemanagement/economics/iopsychology)
    @Test func catalogHasAtLeastFourHundredEightyThreeTemplates() {
        #expect(SuggestedSessionTemplates.all.count >= 483,
                "catalog should have ≥483 templates after informationassurance/hrmanagement/changemanagement/economics/iopsychology additions")
    }

    // MARK: - criminallaw
    @Test func criminallawTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasExam = tasks.contains {
            ($0.localizedCaseInsensitiveContains("criminal law") || $0.localizedCaseInsensitiveContains("mens rea") || $0.localizedCaseInsensitiveContains("Model Penal Code")) &&
            $0.localizedCaseInsensitiveContains("exam")
        }
        let hasHypo = tasks.contains {
            $0.localizedCaseInsensitiveContains("criminal law") &&
            ($0.localizedCaseInsensitiveContains("hypothetical") || $0.localizedCaseInsensitiveContains("case") || $0.localizedCaseInsensitiveContains("brief"))
        }
        #expect(hasExam, "catalog must include a criminal law exam study template")
        #expect(hasHypo, "catalog must include a criminal law hypothetical or case brief template")
    }

    // MARK: - civilprocedure
    @Test func civilprocedureTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasExam = tasks.contains {
            ($0.localizedCaseInsensitiveContains("civil procedure") || $0.localizedCaseInsensitiveContains("FRCP") || $0.localizedCaseInsensitiveContains("Erie doctrine")) &&
            $0.localizedCaseInsensitiveContains("exam")
        }
        let hasHypo = tasks.contains {
            $0.localizedCaseInsensitiveContains("civil procedure") &&
            ($0.localizedCaseInsensitiveContains("hypothetical") || $0.localizedCaseInsensitiveContains("jurisdiction") || $0.localizedCaseInsensitiveContains("discovery"))
        }
        #expect(hasExam, "catalog must include a civil procedure exam study template")
        #expect(hasHypo, "catalog must include a civil procedure hypothetical or analysis template")
    }

    // MARK: - constitutionallaw
    @Test func constitutionallawTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasExam = tasks.contains {
            ($0.localizedCaseInsensitiveContains("constitutional law") || $0.localizedCaseInsensitiveContains("con law")) &&
            $0.localizedCaseInsensitiveContains("exam")
        }
        let hasAnalysis = tasks.contains {
            $0.localizedCaseInsensitiveContains("constitutional law") &&
            ($0.localizedCaseInsensitiveContains("judicial review") || $0.localizedCaseInsensitiveContains("due process") || $0.localizedCaseInsensitiveContains("Amendment"))
        }
        #expect(hasExam, "catalog must include a constitutional law exam study template")
        #expect(hasAnalysis, "catalog must include a constitutional law analysis template")
    }

    // MARK: - evidencelaw
    @Test func evidencelawTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasExam = tasks.contains {
            ($0.localizedCaseInsensitiveContains("evidence law") || $0.localizedCaseInsensitiveContains("Federal Rules of Evidence") || $0.localizedCaseInsensitiveContains("hearsay")) &&
            $0.localizedCaseInsensitiveContains("exam")
        }
        let hasHypo = tasks.contains {
            $0.localizedCaseInsensitiveContains("evidence") &&
            ($0.localizedCaseInsensitiveContains("hypothetical") || $0.localizedCaseInsensitiveContains("hearsay") || $0.localizedCaseInsensitiveContains("authentication"))
        }
        #expect(hasExam, "catalog must include an evidence law exam study template")
        #expect(hasHypo, "catalog must include an evidence law hypothetical or analysis template")
    }

    // MARK: - tortlaw
    @Test func tortlawTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasExam = tasks.contains {
            ($0.localizedCaseInsensitiveContains("torts") || $0.localizedCaseInsensitiveContains("tort law")) &&
            $0.localizedCaseInsensitiveContains("exam")
        }
        let hasHypo = tasks.contains {
            $0.localizedCaseInsensitiveContains("torts") &&
            ($0.localizedCaseInsensitiveContains("hypothetical") || $0.localizedCaseInsensitiveContains("negligence") || $0.localizedCaseInsensitiveContains("intentional"))
        }
        #expect(hasExam, "catalog must include a torts exam study template")
        #expect(hasHypo, "catalog must include a torts hypothetical or analysis template")
    }

    // MARK: - Count guard (criminallaw/civilprocedure/constitutionallaw/evidencelaw/tortlaw)
    @Test func catalogHasAtLeastFourHundredNinetyFiveTemplates() {
        #expect(SuggestedSessionTemplates.all.count >= 495,
                "catalog should have ≥495 templates after criminallaw/civilprocedure/constitutionallaw/evidencelaw/tortlaw additions")
    }

    // MARK: - architecturaldesign
    @Test func architecturaldesignTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasPortfolio = tasks.contains {
            $0.localizedCaseInsensitiveContains("architecture portfolio") || $0.localizedCaseInsensitiveContains("architectural portfolio")
        }
        let hasDesign = tasks.contains {
            ($0.localizedCaseInsensitiveContains("architectural design") || $0.localizedCaseInsensitiveContains("design concept")) &&
            ($0.localizedCaseInsensitiveContains("studio") || $0.localizedCaseInsensitiveContains("drawing") || $0.localizedCaseInsensitiveContains("concept"))
        }
        #expect(hasPortfolio, "catalog must include an architecture portfolio template")
        #expect(hasDesign, "catalog must include an architectural design concept or studio template")
    }

    // MARK: - historicpreservation
    @Test func historicpreservationTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasSurvey = tasks.contains {
            ($0.localizedCaseInsensitiveContains("historic preservation") || $0.localizedCaseInsensitiveContains("HABS")) &&
            ($0.localizedCaseInsensitiveContains("survey") || $0.localizedCaseInsensitiveContains("documentation") || $0.localizedCaseInsensitiveContains("report"))
        }
        let hasStudy = tasks.contains {
            $0.localizedCaseInsensitiveContains("historic preservation") && $0.localizedCaseInsensitiveContains("exam")
        }
        #expect(hasSurvey, "catalog must include a historic preservation survey or documentation template")
        #expect(hasStudy, "catalog must include a historic preservation exam study template")
    }

    // MARK: - sustainabledesign
    @Test func sustainabledesignTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasLEED = tasks.contains {
            $0.localizedCaseInsensitiveContains("LEED") &&
            ($0.localizedCaseInsensitiveContains("project") || $0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("class"))
        }
        #expect(hasLEED, "catalog must include a LEED project or exam template")
    }

    // MARK: - exhibitdesign
    @Test func exhibitdesignTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasExhibit = tasks.contains {
            $0.localizedCaseInsensitiveContains("exhibit") &&
            ($0.localizedCaseInsensitiveContains("design") || $0.localizedCaseInsensitiveContains("museum") || $0.localizedCaseInsensitiveContains("installation"))
        }
        let hasLabel = tasks.contains {
            $0.localizedCaseInsensitiveContains("exhibit") &&
            ($0.localizedCaseInsensitiveContains("label") || $0.localizedCaseInsensitiveContains("interpretive") || $0.localizedCaseInsensitiveContains("wayfinding"))
        }
        #expect(hasExhibit, "catalog must include an exhibit design or museum installation template")
        #expect(hasLabel, "catalog must include an exhibit label or interpretive text template")
    }

    // MARK: - lightingdesign
    @Test func lightingdesignTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasLightingPlan = tasks.contains {
            $0.localizedCaseInsensitiveContains("lighting") &&
            ($0.localizedCaseInsensitiveContains("design") || $0.localizedCaseInsensitiveContains("photometric") || $0.localizedCaseInsensitiveContains("plan"))
        }
        let hasNCQLPExam = tasks.contains {
            $0.localizedCaseInsensitiveContains("NCQLP") || ($0.localizedCaseInsensitiveContains("lighting") && $0.localizedCaseInsensitiveContains("exam"))
        }
        #expect(hasLightingPlan, "catalog must include a lighting design plan or photometric template")
        #expect(hasNCQLPExam, "catalog must include a lighting exam or NCQLP template")
    }

    // MARK: - Count guard (architecturaldesign/historicpreservation/sustainabledesign/exhibitdesign/lightingdesign)
    @Test func catalogHasAtLeastFiveHundredFiveTemplates() {
        #expect(SuggestedSessionTemplates.all.count >= 505,
                "catalog should have ≥505 templates after architecturaldesign/historicpreservation/sustainabledesign/exhibitdesign/lightingdesign additions")
    }

    // MARK: - socialentrepreneurship
    @Test func socialentrepreneurshipTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasModel = tasks.contains {
            ($0.localizedCaseInsensitiveContains("social enterprise") || $0.localizedCaseInsensitiveContains("B-corp")) &&
            ($0.localizedCaseInsensitiveContains("business model") || $0.localizedCaseInsensitiveContains("certification") || $0.localizedCaseInsensitiveContains("theory of change"))
        }
        let hasStudy = tasks.contains {
            $0.localizedCaseInsensitiveContains("social entrepreneurship") || $0.localizedCaseInsensitiveContains("impact investing")
        }
        #expect(hasModel, "catalog must include a social enterprise business model or B-corp template")
        #expect(hasStudy, "catalog must include a social entrepreneurship or impact investing study template")
    }

    // MARK: - yogapilates
    @Test func yogapilatesTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasYogaTeacher = tasks.contains {
            $0.localizedCaseInsensitiveContains("yoga teacher") || $0.localizedCaseInsensitiveContains("RYT")
        }
        let hasPilates = tasks.contains {
            $0.localizedCaseInsensitiveContains("Pilates") && ($0.localizedCaseInsensitiveContains("certification") || $0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("instructor"))
        }
        #expect(hasYogaTeacher, "catalog must include a yoga teacher training or RYT template")
        #expect(hasPilates, "catalog must include a Pilates certification or instructor template")
    }

    // MARK: - ayurvedic
    @Test func ayurvedicTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasAyurveda = tasks.contains {
            $0.localizedCaseInsensitiveContains("Ayurved") &&
            ($0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("program") || $0.localizedCaseInsensitiveContains("assignment") || $0.localizedCaseInsensitiveContains("doshas"))
        }
        #expect(hasAyurveda, "catalog must include an Ayurvedic exam or practitioner program template")
    }

    // MARK: - positivepsychology
    @Test func positivepsychologyTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasStudy = tasks.contains {
            $0.localizedCaseInsensitiveContains("positive psychology") &&
            ($0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("PERMA") || $0.localizedCaseInsensitiveContains("class"))
        }
        let hasPaper = tasks.contains {
            $0.localizedCaseInsensitiveContains("positive psychology") &&
            ($0.localizedCaseInsensitiveContains("paper") || $0.localizedCaseInsensitiveContains("research") || $0.localizedCaseInsensitiveContains("assignment"))
        }
        #expect(hasStudy, "catalog must include a positive psychology study/exam template")
        #expect(hasPaper, "catalog must include a positive psychology paper or research template")
    }

    // MARK: - policeacademy
    @Test func policeacademyTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasExam = tasks.contains {
            ($0.localizedCaseInsensitiveContains("police officer") || $0.localizedCaseInsensitiveContains("POST")) &&
            ($0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("certification"))
        }
        let hasAcademy = tasks.contains {
            $0.localizedCaseInsensitiveContains("police academy") || $0.localizedCaseInsensitiveContains("law enforcement training")
        }
        #expect(hasExam, "catalog must include a police officer exam or POST certification template")
        #expect(hasAcademy, "catalog must include a police academy or law enforcement training template")
    }

    // MARK: - Count guard (socialentrepreneurship/yogapilates/ayurvedic/positivepsychology/policeacademy)
    @Test func catalogHasAtLeastFiveHundredThirteenTemplates() {
        #expect(SuggestedSessionTemplates.all.count >= 513,
                "catalog should have ≥513 templates after socialentrepreneurship/yogapilates/ayurvedic/positivepsychology/policeacademy additions (10 templates)")
    }

    // MARK: - nursepractitioner
    @Test func nursepractitionerTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasExam = tasks.contains {
            ($0.localizedCaseInsensitiveContains("AANP") || $0.localizedCaseInsensitiveContains("FNP") || $0.localizedCaseInsensitiveContains("nurse practitioner")) &&
            ($0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("certification"))
        }
        let hasNotes = tasks.contains {
            $0.localizedCaseInsensitiveContains("NP clinical") || $0.localizedCaseInsensitiveContains("SOAP notes") &&
            $0.localizedCaseInsensitiveContains("NP")
        }
        #expect(hasExam, "catalog must include an NP board exam or certification template")
        #expect(hasNotes, "catalog must include an NP clinical notes or SOAP notes template")
    }

    // MARK: - mortuaryscience
    @Test func mortuaryscienceTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasExam = tasks.contains {
            ($0.localizedCaseInsensitiveContains("NBE") || $0.localizedCaseInsensitiveContains("mortuary")) &&
            ($0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("board"))
        }
        let hasAssignment = tasks.contains {
            $0.localizedCaseInsensitiveContains("mortuary science") &&
            ($0.localizedCaseInsensitiveContains("assignment") || $0.localizedCaseInsensitiveContains("class") || $0.localizedCaseInsensitiveContains("embalming"))
        }
        #expect(hasExam, "catalog must include an NBE or mortuary science board exam template")
        #expect(hasAssignment, "catalog must include a mortuary science class or embalming template")
    }

    // MARK: - polyvagaltheory
    @Test func polyvagaltheoryTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasStudy = tasks.contains {
            ($0.localizedCaseInsensitiveContains("polyvagal") || $0.localizedCaseInsensitiveContains("somatic experiencing") || $0.localizedCaseInsensitiveContains("IFS")) &&
            ($0.localizedCaseInsensitiveContains("training") || $0.localizedCaseInsensitiveContains("study") || $0.localizedCaseInsensitiveContains("module"))
        }
        let hasNotes = tasks.contains {
            ($0.localizedCaseInsensitiveContains("somatic therapy") || $0.localizedCaseInsensitiveContains("IFS") || $0.localizedCaseInsensitiveContains("polyvagal")) &&
            ($0.localizedCaseInsensitiveContains("notes") || $0.localizedCaseInsensitiveContains("assignment") || $0.localizedCaseInsensitiveContains("reflection"))
        }
        #expect(hasStudy, "catalog must include a polyvagal theory or somatic experiencing training template")
        #expect(hasNotes, "catalog must include a somatic therapy notes or polyvagal assignment template")
    }

    // MARK: - Count guard (nursepractitioner/mortuaryscience/polyvagaltheory)
    @Test func catalogHasAtLeastFiveHundredNineteenTemplates() {
        #expect(SuggestedSessionTemplates.all.count >= 519,
                "catalog should have ≥519 templates after nursepractitioner/mortuaryscience/polyvagaltheory additions (6 templates)")
    }

    // MARK: - virtualreality
    @Test func virtualrealityTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasBuild = tasks.contains {
            ($0.localizedCaseInsensitiveContains("VR") || $0.localizedCaseInsensitiveContains("AR") || $0.localizedCaseInsensitiveContains("XR") || $0.localizedCaseInsensitiveContains("virtual reality")) &&
            ($0.localizedCaseInsensitiveContains("build") || $0.localizedCaseInsensitiveContains("scene") || $0.localizedCaseInsensitiveContains("project"))
        }
        let hasStudy = tasks.contains {
            ($0.localizedCaseInsensitiveContains("virtual reality") || $0.localizedCaseInsensitiveContains("augmented reality") || $0.localizedCaseInsensitiveContains("XR")) &&
            ($0.localizedCaseInsensitiveContains("class") || $0.localizedCaseInsensitiveContains("course") || $0.localizedCaseInsensitiveContains("assignment"))
        }
        #expect(hasBuild, "catalog must include a VR/AR/XR scene build template")
        #expect(hasStudy, "catalog must include a virtual/augmented reality class or course template")
    }

    // MARK: - clinicalresearch
    @Test func clinicalresearchTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasExam = tasks.contains {
            ($0.localizedCaseInsensitiveContains("ACRP") || $0.localizedCaseInsensitiveContains("SOCRA") || $0.localizedCaseInsensitiveContains("clinical research")) &&
            ($0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("certification"))
        }
        let hasWork = tasks.contains {
            ($0.localizedCaseInsensitiveContains("clinical trial") || $0.localizedCaseInsensitiveContains("clinical research") || $0.localizedCaseInsensitiveContains("CRF") || $0.localizedCaseInsensitiveContains("protocol")) &&
            ($0.localizedCaseInsensitiveContains("review") || $0.localizedCaseInsensitiveContains("assignment") || $0.localizedCaseInsensitiveContains("draft"))
        }
        #expect(hasExam, "catalog must include an ACRP/SOCRA exam or clinical research certification template")
        #expect(hasWork, "catalog must include a clinical trial protocol or CRF assignment template")
    }

    // MARK: - homeopathy
    @Test func homeopathyTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasStudy = tasks.contains {
            ($0.localizedCaseInsensitiveContains("homeopathic") || $0.localizedCaseInsensitiveContains("materia medica") || $0.localizedCaseInsensitiveContains("CCH")) &&
            ($0.localizedCaseInsensitiveContains("study") || $0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("remedy"))
        }
        let hasCase = tasks.contains {
            $0.localizedCaseInsensitiveContains("homeopathic") &&
            ($0.localizedCaseInsensitiveContains("case") || $0.localizedCaseInsensitiveContains("analysis") || $0.localizedCaseInsensitiveContains("prescribing"))
        }
        #expect(hasStudy, "catalog must include a homeopathic materia medica or CCH exam template")
        #expect(hasCase, "catalog must include a homeopathic case analysis or prescribing template")
    }

    // MARK: - recreationaltherapy
    @Test func recreationaltherapyTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasExam = tasks.contains {
            ($0.localizedCaseInsensitiveContains("NCTRC") || $0.localizedCaseInsensitiveContains("CTRS") || $0.localizedCaseInsensitiveContains("therapeutic recreation")) &&
            ($0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("certification"))
        }
        let hasNotes = tasks.contains {
            ($0.localizedCaseInsensitiveContains("recreational therapy") || $0.localizedCaseInsensitiveContains("TR")) &&
            ($0.localizedCaseInsensitiveContains("notes") || $0.localizedCaseInsensitiveContains("treatment plan") || $0.localizedCaseInsensitiveContains("assignment"))
        }
        #expect(hasExam, "catalog must include a NCTRC/CTRS exam or therapeutic recreation certification template")
        #expect(hasNotes, "catalog must include a recreational therapy session notes or TR assignment template")
    }

    // MARK: - tibetanmedicine
    @Test func tibetanmedicineTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasStudy = tasks.contains {
            ($0.localizedCaseInsensitiveContains("Tibetan medicine") || $0.localizedCaseInsensitiveContains("Sowa Rigpa") || $0.localizedCaseInsensitiveContains("Gyushi")) &&
            ($0.localizedCaseInsensitiveContains("study") || $0.localizedCaseInsensitiveContains("review") || $0.localizedCaseInsensitiveContains("principles"))
        }
        let hasCase = tasks.contains {
            $0.localizedCaseInsensitiveContains("Tibetan medicine") &&
            ($0.localizedCaseInsensitiveContains("assignment") || $0.localizedCaseInsensitiveContains("case") || $0.localizedCaseInsensitiveContains("class"))
        }
        #expect(hasStudy, "catalog must include a Tibetan medicine theory study template")
        #expect(hasCase, "catalog must include a Tibetan medicine class or case analysis template")
    }

    // MARK: - Count guard (batch: virtualreality/clinicalresearch/homeopathy/recreationaltherapy/tibetanmedicine)
    @Test func catalogHasAtLeastFiveHundredTwentyNineTemplates() {
        #expect(SuggestedSessionTemplates.all.count >= 529,
                "catalog should have ≥529 templates after virtualreality/clinicalresearch/homeopathy/recreationaltherapy/tibetanmedicine additions (10 templates)")
    }

    // MARK: - waterresources
    @Test func waterresourcesTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasEngineering = tasks.contains {
            ($0.localizedCaseInsensitiveContains("hydraulics") || $0.localizedCaseInsensitiveContains("stormwater") || $0.localizedCaseInsensitiveContains("hydrology")) &&
            ($0.localizedCaseInsensitiveContains("problem") || $0.localizedCaseInsensitiveContains("engineering") || $0.localizedCaseInsensitiveContains("water resources"))
        }
        let hasAssignment = tasks.contains {
            ($0.localizedCaseInsensitiveContains("water treatment") || $0.localizedCaseInsensitiveContains("water distribution") || $0.localizedCaseInsensitiveContains("hydraulic design") || $0.localizedCaseInsensitiveContains("wastewater")) &&
            ($0.localizedCaseInsensitiveContains("assignment") || $0.localizedCaseInsensitiveContains("class") || $0.localizedCaseInsensitiveContains("design"))
        }
        #expect(hasEngineering, "catalog must include a water resources engineering problem set template")
        #expect(hasAssignment, "catalog must include a water treatment or hydraulic design assignment template")
    }

    // MARK: - biophysics
    @Test func biophysicsTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasProblemSet = tasks.contains {
            $0.localizedCaseInsensitiveContains("biophysics") &&
            ($0.localizedCaseInsensitiveContains("problem") || $0.localizedCaseInsensitiveContains("thermodynamics") || $0.localizedCaseInsensitiveContains("membrane"))
        }
        let hasLabReport = tasks.contains {
            $0.localizedCaseInsensitiveContains("biophysics") &&
            ($0.localizedCaseInsensitiveContains("lab") || $0.localizedCaseInsensitiveContains("report") || $0.localizedCaseInsensitiveContains("assignment"))
        }
        #expect(hasProblemSet, "catalog must include a biophysics problem set template")
        #expect(hasLabReport, "catalog must include a biophysics lab or assignment template")
    }

    // MARK: - psychopharmacology
    @Test func psychopharmacologyTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasStudy = tasks.contains {
            ($0.localizedCaseInsensitiveContains("psychopharmacology") || $0.localizedCaseInsensitiveContains("neuropsychopharmacology")) &&
            ($0.localizedCaseInsensitiveContains("study") || $0.localizedCaseInsensitiveContains("drug") || $0.localizedCaseInsensitiveContains("receptor"))
        }
        let hasPaper = tasks.contains {
            ($0.localizedCaseInsensitiveContains("psychopharmacology") || $0.localizedCaseInsensitiveContains("psychiatric drug")) &&
            ($0.localizedCaseInsensitiveContains("paper") || $0.localizedCaseInsensitiveContains("assignment") || $0.localizedCaseInsensitiveContains("mechanism"))
        }
        #expect(hasStudy, "catalog must include a psychopharmacology study template")
        #expect(hasPaper, "catalog must include a psychopharmacology paper or assignment template")
    }

    // MARK: - mediationarbitration
    @Test func mediationarbitrationTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasStudy = tasks.contains {
            ($0.localizedCaseInsensitiveContains("mediation") || $0.localizedCaseInsensitiveContains("arbitration") || $0.localizedCaseInsensitiveContains("ADR") || $0.localizedCaseInsensitiveContains("dispute resolution")) &&
            ($0.localizedCaseInsensitiveContains("study") || $0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("certification") || $0.localizedCaseInsensitiveContains("principles"))
        }
        let hasAssignment = tasks.contains {
            ($0.localizedCaseInsensitiveContains("mediation") || $0.localizedCaseInsensitiveContains("arbitration") || $0.localizedCaseInsensitiveContains("dispute resolution")) &&
            ($0.localizedCaseInsensitiveContains("assignment") || $0.localizedCaseInsensitiveContains("brief") || $0.localizedCaseInsensitiveContains("case"))
        }
        #expect(hasStudy, "catalog must include an ADR/mediation exam prep template")
        #expect(hasAssignment, "catalog must include a mediation or arbitration assignment template")
    }

    // MARK: - sportslaw
    @Test func sportslawTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasStudy = tasks.contains {
            $0.localizedCaseInsensitiveContains("sports law") &&
            ($0.localizedCaseInsensitiveContains("study") || $0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("NCAA") || $0.localizedCaseInsensitiveContains("contract"))
        }
        let hasAssignment = tasks.contains {
            ($0.localizedCaseInsensitiveContains("sports law") || $0.localizedCaseInsensitiveContains("sports governance") || $0.localizedCaseInsensitiveContains("athlete contract")) &&
            ($0.localizedCaseInsensitiveContains("assignment") || $0.localizedCaseInsensitiveContains("analyze") || $0.localizedCaseInsensitiveContains("case") || $0.localizedCaseInsensitiveContains("memo"))
        }
        #expect(hasStudy, "catalog must include a sports law study/exam template")
        #expect(hasAssignment, "catalog must include a sports law assignment or analysis template")
    }

    // MARK: - Count guard (batch: waterresources/biophysics/psychopharmacology/mediationarbitration/sportslaw)
    @Test func catalogHasAtLeastFiveHundredThirtyNineTemplates() {
        #expect(SuggestedSessionTemplates.all.count >= 539,
                "catalog should have ≥539 templates after waterresources/biophysics/psychopharmacology/mediationarbitration/sportslaw additions (10 templates)")
    }

    // MARK: - animalassistedtherapy
    @Test func animalassistedtherapyTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasCert = tasks.contains {
            ($0.localizedCaseInsensitiveContains("animal-assisted") || $0.localizedCaseInsensitiveContains("AAT") || $0.localizedCaseInsensitiveContains("therapy dog") || $0.localizedCaseInsensitiveContains("AAI")) &&
            ($0.localizedCaseInsensitiveContains("study") || $0.localizedCaseInsensitiveContains("certification") || $0.localizedCaseInsensitiveContains("protocol"))
        }
        let hasAssignment = tasks.contains {
            ($0.localizedCaseInsensitiveContains("therapy animal") || $0.localizedCaseInsensitiveContains("AAT") || $0.localizedCaseInsensitiveContains("animal-assisted") || $0.localizedCaseInsensitiveContains("therapy dog")) &&
            ($0.localizedCaseInsensitiveContains("assignment") || $0.localizedCaseInsensitiveContains("report") || $0.localizedCaseInsensitiveContains("class"))
        }
        #expect(hasCert, "catalog must include an AAT/AAI certification study template")
        #expect(hasAssignment, "catalog must include an animal-assisted therapy assignment or class template")
    }

    // MARK: - constructionlaw
    @Test func constructionlawTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasStudy = tasks.contains {
            $0.localizedCaseInsensitiveContains("construction law") &&
            ($0.localizedCaseInsensitiveContains("study") || $0.localizedCaseInsensitiveContains("AIA") || $0.localizedCaseInsensitiveContains("lien") || $0.localizedCaseInsensitiveContains("bond"))
        }
        let hasAssignment = tasks.contains {
            ($0.localizedCaseInsensitiveContains("construction law") || $0.localizedCaseInsensitiveContains("mechanics lien") || $0.localizedCaseInsensitiveContains("construction defect")) &&
            ($0.localizedCaseInsensitiveContains("assignment") || $0.localizedCaseInsensitiveContains("analyze") || $0.localizedCaseInsensitiveContains("draft") || $0.localizedCaseInsensitiveContains("memo"))
        }
        #expect(hasStudy, "catalog must include a construction law study template")
        #expect(hasAssignment, "catalog must include a construction law assignment or analysis template")
    }

    // MARK: - healtheconomics
    @Test func healtheconomicsTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasStudy = tasks.contains {
            ($0.localizedCaseInsensitiveContains("health economics") || $0.localizedCaseInsensitiveContains("QALY") || $0.localizedCaseInsensitiveContains("ICER") || $0.localizedCaseInsensitiveContains("cost-effectiveness")) &&
            ($0.localizedCaseInsensitiveContains("study") || $0.localizedCaseInsensitiveContains("concepts") || $0.localizedCaseInsensitiveContains("framework"))
        }
        let hasAssignment = tasks.contains {
            ($0.localizedCaseInsensitiveContains("pharmacoeconomics") || $0.localizedCaseInsensitiveContains("health technology assessment") || $0.localizedCaseInsensitiveContains("health economics")) &&
            ($0.localizedCaseInsensitiveContains("assignment") || $0.localizedCaseInsensitiveContains("class") || $0.localizedCaseInsensitiveContains("model"))
        }
        #expect(hasStudy, "catalog must include a health economics study template")
        #expect(hasAssignment, "catalog must include a pharmacoeconomics or HTA assignment template")
    }

    // MARK: - insurancefinance
    @Test func insurancefinanceTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasStudy = tasks.contains {
            ($0.localizedCaseInsensitiveContains("insurance") && ($0.localizedCaseInsensitiveContains("licensing") || $0.localizedCaseInsensitiveContains("CPCU") || $0.localizedCaseInsensitiveContains("LOMA") || $0.localizedCaseInsensitiveContains("underwriting"))) &&
            ($0.localizedCaseInsensitiveContains("study") || $0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("designation"))
        }
        let hasAssignment = tasks.contains {
            ($0.localizedCaseInsensitiveContains("insurance") && ($0.localizedCaseInsensitiveContains("underwriting") || $0.localizedCaseInsensitiveContains("policy") || $0.localizedCaseInsensitiveContains("risk"))) &&
            ($0.localizedCaseInsensitiveContains("assignment") || $0.localizedCaseInsensitiveContains("class") || $0.localizedCaseInsensitiveContains("analyze") || $0.localizedCaseInsensitiveContains("case"))
        }
        #expect(hasStudy, "catalog must include an insurance licensing/CPCU exam study template")
        #expect(hasAssignment, "catalog must include an insurance class assignment template")
    }

    // MARK: - environmentalplanning
    @Test func environmentalplanningTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasStudy = tasks.contains {
            ($0.localizedCaseInsensitiveContains("NEPA") || $0.localizedCaseInsensitiveContains("CEQA") || $0.localizedCaseInsensitiveContains("environmental review") || $0.localizedCaseInsensitiveContains("EIS")) &&
            ($0.localizedCaseInsensitiveContains("study") || $0.localizedCaseInsensitiveContains("review") || $0.localizedCaseInsensitiveContains("process") || $0.localizedCaseInsensitiveContains("requirements"))
        }
        let hasAssignment = tasks.contains {
            ($0.localizedCaseInsensitiveContains("environmental impact statement") || $0.localizedCaseInsensitiveContains("EIS") || $0.localizedCaseInsensitiveContains("environmental permitting")) &&
            ($0.localizedCaseInsensitiveContains("draft") || $0.localizedCaseInsensitiveContains("complete") || $0.localizedCaseInsensitiveContains("assignment") || $0.localizedCaseInsensitiveContains("planning class"))
        }
        #expect(hasStudy, "catalog must include a NEPA/CEQA environmental review study template")
        #expect(hasAssignment, "catalog must include an EIS/environmental permitting assignment template")
    }

    // MARK: - Count guard (batch: animalassistedtherapy/constructionlaw/healtheconomics/insurancefinance/environmentalplanning)
    @Test func catalogHasAtLeastFiveHundredFortyNineTemplates() {
        #expect(SuggestedSessionTemplates.all.count >= 549,
                "catalog should have ≥549 templates after animalassistedtherapy/constructionlaw/healtheconomics/insurancefinance/environmentalplanning additions (10 templates)")
    }

    // MARK: - tesol
    @Test func tesolTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasStudy = tasks.contains {
            ($0.localizedCaseInsensitiveContains("TESOL") || $0.localizedCaseInsensitiveContains("TEFL") || $0.localizedCaseInsensitiveContains("second language acquisition")) &&
            ($0.localizedCaseInsensitiveContains("study") || $0.localizedCaseInsensitiveContains("certification") || $0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("review"))
        }
        let hasLesson = tasks.contains {
            ($0.localizedCaseInsensitiveContains("ESL") || $0.localizedCaseInsensitiveContains("TESOL") || $0.localizedCaseInsensitiveContains("lesson")) &&
            ($0.localizedCaseInsensitiveContains("lesson plan") || $0.localizedCaseInsensitiveContains("practicum") || $0.localizedCaseInsensitiveContains("material") || $0.localizedCaseInsensitiveContains("activities"))
        }
        #expect(hasStudy, "catalog must include a TESOL/TEFL certification study template")
        #expect(hasLesson, "catalog must include an ESL lesson planning or practicum template")
    }

    // MARK: - specialeducation
    @Test func specialeducationTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasStudy = tasks.contains {
            ($0.localizedCaseInsensitiveContains("special education") || $0.localizedCaseInsensitiveContains("SPED") || $0.localizedCaseInsensitiveContains("PRAXIS special")) &&
            ($0.localizedCaseInsensitiveContains("study") || $0.localizedCaseInsensitiveContains("credential") || $0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("review"))
        }
        let hasIEP = tasks.contains {
            ($0.localizedCaseInsensitiveContains("IEP") || $0.localizedCaseInsensitiveContains("special ed") || $0.localizedCaseInsensitiveContains("SPED")) &&
            ($0.localizedCaseInsensitiveContains("IEP") || $0.localizedCaseInsensitiveContains("goals") || $0.localizedCaseInsensitiveContains("assignment") || $0.localizedCaseInsensitiveContains("case study"))
        }
        #expect(hasStudy, "catalog must include a special education credential study template")
        #expect(hasIEP, "catalog must include an IEP writing or SPED assignment template")
    }

    // MARK: - foodscience
    @Test func foodscienceTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasStudy = tasks.contains {
            ($0.localizedCaseInsensitiveContains("food science") || $0.localizedCaseInsensitiveContains("food chemistry") || $0.localizedCaseInsensitiveContains("food microbiology")) &&
            ($0.localizedCaseInsensitiveContains("study") || $0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("review"))
        }
        let hasLab = tasks.contains {
            ($0.localizedCaseInsensitiveContains("food science") || $0.localizedCaseInsensitiveContains("sensory evaluation") || $0.localizedCaseInsensitiveContains("food chemistry")) &&
            ($0.localizedCaseInsensitiveContains("lab report") || $0.localizedCaseInsensitiveContains("assignment") || $0.localizedCaseInsensitiveContains("product development"))
        }
        #expect(hasStudy, "catalog must include a food science exam study template")
        #expect(hasLab, "catalog must include a food science lab report or assignment template")
    }

    // MARK: - animalwelfare
    @Test func animalwelfareTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasStudy = tasks.contains {
            ($0.localizedCaseInsensitiveContains("animal welfare") || $0.localizedCaseInsensitiveContains("IACUC") || $0.localizedCaseInsensitiveContains("zoo management")) &&
            ($0.localizedCaseInsensitiveContains("study") || $0.localizedCaseInsensitiveContains("review") || $0.localizedCaseInsensitiveContains("concepts") || $0.localizedCaseInsensitiveContains("class"))
        }
        let hasAssignment = tasks.contains {
            ($0.localizedCaseInsensitiveContains("animal welfare") || $0.localizedCaseInsensitiveContains("IACUC") || $0.localizedCaseInsensitiveContains("zoo") || $0.localizedCaseInsensitiveContains("wildlife")) &&
            ($0.localizedCaseInsensitiveContains("assignment") || $0.localizedCaseInsensitiveContains("protocol") || $0.localizedCaseInsensitiveContains("plan") || $0.localizedCaseInsensitiveContains("report"))
        }
        #expect(hasStudy, "catalog must include an animal welfare science study template")
        #expect(hasAssignment, "catalog must include an IACUC/zoo/wildlife assignment template")
    }

    // MARK: - epidemiologicalmodeling
    @Test func epidemiologicalmodelingTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasModel = tasks.contains {
            ($0.localizedCaseInsensitiveContains("SIR") || $0.localizedCaseInsensitiveContains("SEIR") || $0.localizedCaseInsensitiveContains("epidemiological model") || $0.localizedCaseInsensitiveContains("compartmental model")) &&
            ($0.localizedCaseInsensitiveContains("build") || $0.localizedCaseInsensitiveContains("implement") || $0.localizedCaseInsensitiveContains("analyze") || $0.localizedCaseInsensitiveContains("estimate"))
        }
        let hasStudy = tasks.contains {
            ($0.localizedCaseInsensitiveContains("mathematical epidemiology") || $0.localizedCaseInsensitiveContains("compartmental model") || $0.localizedCaseInsensitiveContains("disease dynamics")) &&
            ($0.localizedCaseInsensitiveContains("study") || $0.localizedCaseInsensitiveContains("review") || $0.localizedCaseInsensitiveContains("class"))
        }
        #expect(hasModel, "catalog must include an epidemic model implementation template")
        #expect(hasStudy, "catalog must include a mathematical epidemiology study template")
    }

    // MARK: - Count guard (batch: tesol/specialeducation/foodscience/animalwelfare/epidemiologicalmodeling)
    @Test func catalogHasAtLeastFiveHundredFiftyNineTemplates() {
        #expect(SuggestedSessionTemplates.all.count >= 559,
                "catalog should have ≥559 templates after tesol/specialeducation/foodscience/animalwelfare/epidemiologicalmodeling additions (10 templates)")
    }

    // MARK: - educationalleadership
    @Test func educationalleadershipTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasStudy = tasks.contains {
            ($0.localizedCaseInsensitiveContains("educational leadership") || $0.localizedCaseInsensitiveContains("ISLLC") || $0.localizedCaseInsensitiveContains("PSEL") || $0.localizedCaseInsensitiveContains("principal")) &&
            ($0.localizedCaseInsensitiveContains("study") || $0.localizedCaseInsensitiveContains("review") || $0.localizedCaseInsensitiveContains("complete") || $0.localizedCaseInsensitiveContains("coursework"))
        }
        let hasAssignment = tasks.contains {
            ($0.localizedCaseInsensitiveContains("educational leadership") || $0.localizedCaseInsensitiveContains("school improvement") || $0.localizedCaseInsensitiveContains("principal") || $0.localizedCaseInsensitiveContains("leadership")) &&
            ($0.localizedCaseInsensitiveContains("assignment") || $0.localizedCaseInsensitiveContains("paper") || $0.localizedCaseInsensitiveContains("plan") || $0.localizedCaseInsensitiveContains("write"))
        }
        #expect(hasStudy, "catalog must include an educational leadership study or coursework template")
        #expect(hasAssignment, "catalog must include an educational leadership assignment or paper template")
    }

    // MARK: - medicalhumanities
    @Test func medicalhumanitiesTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasReading = tasks.contains {
            ($0.localizedCaseInsensitiveContains("medical humanities") || $0.localizedCaseInsensitiveContains("narrative medicine") || $0.localizedCaseInsensitiveContains("history of medicine") || $0.localizedCaseInsensitiveContains("illness narrative")) &&
            ($0.localizedCaseInsensitiveContains("read") || $0.localizedCaseInsensitiveContains("analyze") || $0.localizedCaseInsensitiveContains("explore") || $0.localizedCaseInsensitiveContains("class"))
        }
        let hasWriting = tasks.contains {
            ($0.localizedCaseInsensitiveContains("medical humanities") || $0.localizedCaseInsensitiveContains("narrative medicine") || $0.localizedCaseInsensitiveContains("patient narrative") || $0.localizedCaseInsensitiveContains("health humanities")) &&
            ($0.localizedCaseInsensitiveContains("write") || $0.localizedCaseInsensitiveContains("paper") || $0.localizedCaseInsensitiveContains("response") || $0.localizedCaseInsensitiveContains("analyze"))
        }
        #expect(hasReading, "catalog must include a medical humanities reading or analysis template")
        #expect(hasWriting, "catalog must include a medical humanities writing or paper template")
    }

    // MARK: - healthequity
    @Test func healthequityTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasStudy = tasks.contains {
            ($0.localizedCaseInsensitiveContains("health equity") || $0.localizedCaseInsensitiveContains("health disparities") || $0.localizedCaseInsensitiveContains("social determinants")) &&
            ($0.localizedCaseInsensitiveContains("study") || $0.localizedCaseInsensitiveContains("review") || $0.localizedCaseInsensitiveContains("concepts") || $0.localizedCaseInsensitiveContains("class"))
        }
        let hasAssignment = tasks.contains {
            ($0.localizedCaseInsensitiveContains("health equity") || $0.localizedCaseInsensitiveContains("health disparities") || $0.localizedCaseInsensitiveContains("SDOH")) &&
            ($0.localizedCaseInsensitiveContains("write") || $0.localizedCaseInsensitiveContains("paper") || $0.localizedCaseInsensitiveContains("assignment") || $0.localizedCaseInsensitiveContains("analyze"))
        }
        #expect(hasStudy, "catalog must include a health equity study template")
        #expect(hasAssignment, "catalog must include a health equity paper or assignment template")
    }

    // MARK: - neurolaw
    @Test func neurolawTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasStudy = tasks.contains {
            ($0.localizedCaseInsensitiveContains("neurolaw") || $0.localizedCaseInsensitiveContains("law and neuroscience") || $0.localizedCaseInsensitiveContains("brain imaging") || $0.localizedCaseInsensitiveContains("criminal culpability")) &&
            ($0.localizedCaseInsensitiveContains("study") || $0.localizedCaseInsensitiveContains("review") || $0.localizedCaseInsensitiveContains("concepts") || $0.localizedCaseInsensitiveContains("class"))
        }
        let hasWriting = tasks.contains {
            ($0.localizedCaseInsensitiveContains("neurolaw") || $0.localizedCaseInsensitiveContains("neuroscience") || $0.localizedCaseInsensitiveContains("fMRI") || $0.localizedCaseInsensitiveContains("adolescent brain")) &&
            ($0.localizedCaseInsensitiveContains("write") || $0.localizedCaseInsensitiveContains("paper") || $0.localizedCaseInsensitiveContains("assignment") || $0.localizedCaseInsensitiveContains("analyze"))
        }
        #expect(hasStudy, "catalog must include a neurolaw study template")
        #expect(hasWriting, "catalog must include a neurolaw paper or assignment template")
    }

    // MARK: - climatelaw
    @Test func climatelawTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasStudy = tasks.contains {
            ($0.localizedCaseInsensitiveContains("climate law") || $0.localizedCaseInsensitiveContains("Paris Agreement") || $0.localizedCaseInsensitiveContains("carbon market") || $0.localizedCaseInsensitiveContains("emissions trading")) &&
            ($0.localizedCaseInsensitiveContains("study") || $0.localizedCaseInsensitiveContains("review") || $0.localizedCaseInsensitiveContains("class") || $0.localizedCaseInsensitiveContains("exam"))
        }
        let hasAssignment = tasks.contains {
            ($0.localizedCaseInsensitiveContains("climate law") || $0.localizedCaseInsensitiveContains("carbon market") || $0.localizedCaseInsensitiveContains("climate finance") || $0.localizedCaseInsensitiveContains("climate agreement")) &&
            ($0.localizedCaseInsensitiveContains("write") || $0.localizedCaseInsensitiveContains("analyze") || $0.localizedCaseInsensitiveContains("assignment") || $0.localizedCaseInsensitiveContains("research"))
        }
        #expect(hasStudy, "catalog must include a climate law study template")
        #expect(hasAssignment, "catalog must include a climate law assignment or research template")
    }

    // MARK: - Count guard (batch: educationalleadership/medicalhumanities/healthequity/neurolaw/climatelaw)
    @Test func catalogHasAtLeastFiveHundredSixtyNineTemplates() {
        #expect(SuggestedSessionTemplates.all.count >= 569,
                "catalog should have ≥569 templates after educationalleadership/medicalhumanities/healthequity/neurolaw/climatelaw additions (10 templates)")
    }

    // MARK: - athletictraining
    @Test func athletictrainingTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasStudy = tasks.contains {
            ($0.localizedCaseInsensitiveContains("athletic training") || $0.localizedCaseInsensitiveContains("ATC") || $0.localizedCaseInsensitiveContains("therapeutic modalities")) &&
            ($0.localizedCaseInsensitiveContains("study") || $0.localizedCaseInsensitiveContains("review") || $0.localizedCaseInsensitiveContains("concepts") || $0.localizedCaseInsensitiveContains("coursework"))
        }
        let hasAssignment = tasks.contains {
            ($0.localizedCaseInsensitiveContains("athletic training") || $0.localizedCaseInsensitiveContains("taping") || $0.localizedCaseInsensitiveContains("injury evaluation")) &&
            ($0.localizedCaseInsensitiveContains("complete") || $0.localizedCaseInsensitiveContains("assignment") || $0.localizedCaseInsensitiveContains("lab report") || $0.localizedCaseInsensitiveContains("write"))
        }
        #expect(hasStudy, "catalog must include an athletic training study template")
        #expect(hasAssignment, "catalog must include an athletic training assignment or lab template")
    }

    // MARK: - biomechanics
    @Test func biomechanicsTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasAnalysis = tasks.contains {
            ($0.localizedCaseInsensitiveContains("biomechanics") || $0.localizedCaseInsensitiveContains("force plate") || $0.localizedCaseInsensitiveContains("motion capture") || $0.localizedCaseInsensitiveContains("kinematic")) &&
            ($0.localizedCaseInsensitiveContains("analyze") || $0.localizedCaseInsensitiveContains("data") || $0.localizedCaseInsensitiveContains("lab") || $0.localizedCaseInsensitiveContains("report"))
        }
        let hasStudy = tasks.contains {
            ($0.localizedCaseInsensitiveContains("biomechanics") || $0.localizedCaseInsensitiveContains("joint kinetics") || $0.localizedCaseInsensitiveContains("kinematics")) &&
            ($0.localizedCaseInsensitiveContains("study") || $0.localizedCaseInsensitiveContains("review") || $0.localizedCaseInsensitiveContains("concepts") || $0.localizedCaseInsensitiveContains("class"))
        }
        #expect(hasAnalysis, "catalog must include a biomechanics data analysis template")
        #expect(hasStudy, "catalog must include a biomechanics study template")
    }

    // MARK: - zoology
    @Test func zoologyTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasStudy = tasks.contains {
            ($0.localizedCaseInsensitiveContains("zoology") || $0.localizedCaseInsensitiveContains("taxonomy") || $0.localizedCaseInsensitiveContains("invertebrate") || $0.localizedCaseInsensitiveContains("vertebrate")) &&
            ($0.localizedCaseInsensitiveContains("study") || $0.localizedCaseInsensitiveContains("review") || $0.localizedCaseInsensitiveContains("concepts") || $0.localizedCaseInsensitiveContains("class"))
        }
        let hasAssignment = tasks.contains {
            ($0.localizedCaseInsensitiveContains("zoology") || $0.localizedCaseInsensitiveContains("taxonomic") || $0.localizedCaseInsensitiveContains("morphology")) &&
            ($0.localizedCaseInsensitiveContains("lab report") || $0.localizedCaseInsensitiveContains("assignment") || $0.localizedCaseInsensitiveContains("write") || $0.localizedCaseInsensitiveContains("complete"))
        }
        #expect(hasStudy, "catalog must include a zoology study template")
        #expect(hasAssignment, "catalog must include a zoology lab or assignment template")
    }

    // MARK: - militaryscience
    @Test func militaryscienceTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasStudy = tasks.contains {
            ($0.localizedCaseInsensitiveContains("military science") || $0.localizedCaseInsensitiveContains("ROTC") || $0.localizedCaseInsensitiveContains("leadership doctrine") || $0.localizedCaseInsensitiveContains("cadet")) &&
            ($0.localizedCaseInsensitiveContains("study") || $0.localizedCaseInsensitiveContains("review") || $0.localizedCaseInsensitiveContains("coursework") || $0.localizedCaseInsensitiveContains("prepare"))
        }
        let hasAssignment = tasks.contains {
            ($0.localizedCaseInsensitiveContains("military science") || $0.localizedCaseInsensitiveContains("ROTC") || $0.localizedCaseInsensitiveContains("military tactics") || $0.localizedCaseInsensitiveContains("cadet")) &&
            ($0.localizedCaseInsensitiveContains("write") || $0.localizedCaseInsensitiveContains("paper") || $0.localizedCaseInsensitiveContains("assignment") || $0.localizedCaseInsensitiveContains("analyze"))
        }
        #expect(hasStudy, "catalog must include a military science study or coursework template")
        #expect(hasAssignment, "catalog must include a military science paper or assignment template")
    }

    // MARK: - healthinformatics
    @Test func healthinformaticsTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasStudy = tasks.contains {
            ($0.localizedCaseInsensitiveContains("health informatics") || $0.localizedCaseInsensitiveContains("FHIR") || $0.localizedCaseInsensitiveContains("HL7") || $0.localizedCaseInsensitiveContains("interoperability")) &&
            ($0.localizedCaseInsensitiveContains("study") || $0.localizedCaseInsensitiveContains("review") || $0.localizedCaseInsensitiveContains("concepts") || $0.localizedCaseInsensitiveContains("program"))
        }
        let hasAssignment = tasks.contains {
            ($0.localizedCaseInsensitiveContains("health informatics") || $0.localizedCaseInsensitiveContains("FHIR") || $0.localizedCaseInsensitiveContains("interoperability") || $0.localizedCaseInsensitiveContains("clinical decision support")) &&
            ($0.localizedCaseInsensitiveContains("complete") || $0.localizedCaseInsensitiveContains("assignment") || $0.localizedCaseInsensitiveContains("analyze") || $0.localizedCaseInsensitiveContains("design"))
        }
        #expect(hasStudy, "catalog must include a health informatics study template")
        #expect(hasAssignment, "catalog must include a health informatics assignment or analysis template")
    }

    // MARK: - Count guard (batch: athletictraining/biomechanics/zoology/militaryscience/healthinformatics)
    @Test func catalogHasAtLeastFiveHundredSeventyNineTemplates() {
        #expect(SuggestedSessionTemplates.all.count >= 579,
                "catalog should have ≥579 templates after athletictraining/biomechanics/zoology/militaryscience/healthinformatics additions (10 templates)")
    }

    // MARK: - cryptography
    @Test func cryptographyTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasStudy = tasks.contains {
            ($0.localizedCaseInsensitiveContains("cryptography") || $0.localizedCaseInsensitiveContains("AES") || $0.localizedCaseInsensitiveContains("RSA") || $0.localizedCaseInsensitiveContains("cipher")) &&
            ($0.localizedCaseInsensitiveContains("study") || $0.localizedCaseInsensitiveContains("review") || $0.localizedCaseInsensitiveContains("class") || $0.localizedCaseInsensitiveContains("exam"))
        }
        let hasAssignment = tasks.contains {
            ($0.localizedCaseInsensitiveContains("cryptography") || $0.localizedCaseInsensitiveContains("cipher") || $0.localizedCaseInsensitiveContains("encryption")) &&
            ($0.localizedCaseInsensitiveContains("assignment") || $0.localizedCaseInsensitiveContains("implement") || $0.localizedCaseInsensitiveContains("analyze") || $0.localizedCaseInsensitiveContains("complete"))
        }
        #expect(hasStudy, "catalog must include a cryptography study template")
        #expect(hasAssignment, "catalog must include a cryptography assignment template")
    }

    // MARK: - appliedmathematics
    @Test func appliedmathematicsTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasAssignment = tasks.contains {
            ($0.localizedCaseInsensitiveContains("applied mathematics") || $0.localizedCaseInsensitiveContains("applied math") || $0.localizedCaseInsensitiveContains("differential equations") || $0.localizedCaseInsensitiveContains("numerical methods")) &&
            ($0.localizedCaseInsensitiveContains("assignment") || $0.localizedCaseInsensitiveContains("problem set") || $0.localizedCaseInsensitiveContains("work through") || $0.localizedCaseInsensitiveContains("solve"))
        }
        let hasStudy = tasks.contains {
            ($0.localizedCaseInsensitiveContains("applied mathematics") || $0.localizedCaseInsensitiveContains("applied math") || $0.localizedCaseInsensitiveContains("differential equations") || $0.localizedCaseInsensitiveContains("scientific computing")) &&
            ($0.localizedCaseInsensitiveContains("study") || $0.localizedCaseInsensitiveContains("review") || $0.localizedCaseInsensitiveContains("class") || $0.localizedCaseInsensitiveContains("exam"))
        }
        #expect(hasAssignment, "catalog must include an applied math problem set template")
        #expect(hasStudy, "catalog must include an applied math study template")
    }

    // MARK: - historicallinguistics
    @Test func historicallinguisticsTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasStudy = tasks.contains {
            ($0.localizedCaseInsensitiveContains("historical linguistics") || $0.localizedCaseInsensitiveContains("sound change") || $0.localizedCaseInsensitiveContains("Grimm") || $0.localizedCaseInsensitiveContains("diachronic") || $0.localizedCaseInsensitiveContains("proto-language")) &&
            ($0.localizedCaseInsensitiveContains("study") || $0.localizedCaseInsensitiveContains("review") || $0.localizedCaseInsensitiveContains("class") || $0.localizedCaseInsensitiveContains("exam"))
        }
        let hasAssignment = tasks.contains {
            ($0.localizedCaseInsensitiveContains("historical linguistics") || $0.localizedCaseInsensitiveContains("sound change") || $0.localizedCaseInsensitiveContains("proto-language") || $0.localizedCaseInsensitiveContains("diachronic")) &&
            ($0.localizedCaseInsensitiveContains("assignment") || $0.localizedCaseInsensitiveContains("paper") || $0.localizedCaseInsensitiveContains("complete") || $0.localizedCaseInsensitiveContains("trace") || $0.localizedCaseInsensitiveContains("write"))
        }
        #expect(hasStudy, "catalog must include a historical linguistics study template")
        #expect(hasAssignment, "catalog must include a historical linguistics assignment template")
    }

    // MARK: - computationalfinance
    @Test func computationalfinanceTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasAssignment = tasks.contains {
            ($0.localizedCaseInsensitiveContains("Black-Scholes") || $0.localizedCaseInsensitiveContains("Monte Carlo") || $0.localizedCaseInsensitiveContains("quantitative finance") || $0.localizedCaseInsensitiveContains("algorithmic trading") || $0.localizedCaseInsensitiveContains("computational finance")) &&
            ($0.localizedCaseInsensitiveContains("assignment") || $0.localizedCaseInsensitiveContains("implement") || $0.localizedCaseInsensitiveContains("build") || $0.localizedCaseInsensitiveContains("work on"))
        }
        let hasStudy = tasks.contains {
            ($0.localizedCaseInsensitiveContains("quantitative finance") || $0.localizedCaseInsensitiveContains("financial engineering") || $0.localizedCaseInsensitiveContains("stochastic calculus") || $0.localizedCaseInsensitiveContains("computational finance")) &&
            ($0.localizedCaseInsensitiveContains("study") || $0.localizedCaseInsensitiveContains("review") || $0.localizedCaseInsensitiveContains("class") || $0.localizedCaseInsensitiveContains("program"))
        }
        #expect(hasAssignment, "catalog must include a computational finance assignment template")
        #expect(hasStudy, "catalog must include a computational finance study template")
    }

    // MARK: - globalpoliticaleconomy
    @Test func globalpoliticaleconomyTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasStudy = tasks.contains {
            ($0.localizedCaseInsensitiveContains("international political economy") || $0.localizedCaseInsensitiveContains("IPE") || $0.localizedCaseInsensitiveContains("global political economy") || $0.localizedCaseInsensitiveContains("world systems")) &&
            ($0.localizedCaseInsensitiveContains("study") || $0.localizedCaseInsensitiveContains("review") || $0.localizedCaseInsensitiveContains("class") || $0.localizedCaseInsensitiveContains("exam"))
        }
        let hasAssignment = tasks.contains {
            ($0.localizedCaseInsensitiveContains("political economy") || $0.localizedCaseInsensitiveContains("IPE")) &&
            ($0.localizedCaseInsensitiveContains("paper") || $0.localizedCaseInsensitiveContains("assignment") || $0.localizedCaseInsensitiveContains("write") || $0.localizedCaseInsensitiveContains("analyze"))
        }
        #expect(hasStudy, "catalog must include a global political economy study template")
        #expect(hasAssignment, "catalog must include a global political economy assignment template")
    }

    // MARK: - Count guard (batch: cryptography/appliedmathematics/historicallinguistics/computationalfinance/globalpoliticaleconomy)
    @Test func catalogHasAtLeastFiveHundredEightyNineTemplates() {
        #expect(SuggestedSessionTemplates.all.count >= 589,
                "catalog should have ≥589 templates after cryptography/appliedmathematics/historicallinguistics/computationalfinance/globalpoliticaleconomy additions (10 templates)")
    }

    // MARK: - geopolitics
    @Test func geopoliticsTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasAnalysis = tasks.contains {
            ($0.localizedCaseInsensitiveContains("geopolitical analysis") || $0.localizedCaseInsensitiveContains("geopolitical risk") || $0.localizedCaseInsensitiveContains("great power competition") || $0.localizedCaseInsensitiveContains("geopolitical strategy")) &&
            ($0.localizedCaseInsensitiveContains("write") || $0.localizedCaseInsensitiveContains("assess") || $0.localizedCaseInsensitiveContains("analyze") || $0.localizedCaseInsensitiveContains("analysis"))
        }
        let hasAssignment = tasks.contains {
            ($0.localizedCaseInsensitiveContains("geopolitic") || $0.localizedCaseInsensitiveContains("geopolitical")) &&
            ($0.localizedCaseInsensitiveContains("assignment") || $0.localizedCaseInsensitiveContains("paper") || $0.localizedCaseInsensitiveContains("research") || $0.localizedCaseInsensitiveContains("complete"))
        }
        #expect(hasAnalysis, "catalog must include a geopolitical analysis template")
        #expect(hasAssignment, "catalog must include a geopolitics assignment template")
    }

    // MARK: - computationalbiology
    @Test func computationalbiologyTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasProject = tasks.contains {
            ($0.localizedCaseInsensitiveContains("computational biology") || $0.localizedCaseInsensitiveContains("systems biology") || $0.localizedCaseInsensitiveContains("population dynamics") || $0.localizedCaseInsensitiveContains("biological network")) &&
            ($0.localizedCaseInsensitiveContains("project") || $0.localizedCaseInsensitiveContains("build") || $0.localizedCaseInsensitiveContains("simulate") || $0.localizedCaseInsensitiveContains("work on") || $0.localizedCaseInsensitiveContains("model"))
        }
        let hasStudy = tasks.contains {
            ($0.localizedCaseInsensitiveContains("computational biology") || $0.localizedCaseInsensitiveContains("systems biology") || $0.localizedCaseInsensitiveContains("mathematical biology")) &&
            ($0.localizedCaseInsensitiveContains("study") || $0.localizedCaseInsensitiveContains("review") || $0.localizedCaseInsensitiveContains("class") || $0.localizedCaseInsensitiveContains("exam"))
        }
        #expect(hasProject, "catalog must include a computational biology project template")
        #expect(hasStudy, "catalog must include a computational biology study template")
    }

    // MARK: - philosophyofmind
    @Test func philosophyofmindTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasPaper = tasks.contains {
            ($0.localizedCaseInsensitiveContains("philosophy of mind") || $0.localizedCaseInsensitiveContains("qualia") || $0.localizedCaseInsensitiveContains("consciousness") || $0.localizedCaseInsensitiveContains("mind-body")) &&
            ($0.localizedCaseInsensitiveContains("write") || $0.localizedCaseInsensitiveContains("paper") || $0.localizedCaseInsensitiveContains("argue"))
        }
        let hasStudy = tasks.contains {
            ($0.localizedCaseInsensitiveContains("philosophy of mind") || $0.localizedCaseInsensitiveContains("consciousness") || $0.localizedCaseInsensitiveContains("functionalism") || $0.localizedCaseInsensitiveContains("qualia")) &&
            ($0.localizedCaseInsensitiveContains("study") || $0.localizedCaseInsensitiveContains("review") || $0.localizedCaseInsensitiveContains("class") || $0.localizedCaseInsensitiveContains("exam"))
        }
        #expect(hasPaper, "catalog must include a philosophy of mind paper template")
        #expect(hasStudy, "catalog must include a philosophy of mind study template")
    }

    // MARK: - digitalhumanities
    @Test func digitalhumanitiesTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasProject = tasks.contains {
            ($0.localizedCaseInsensitiveContains("digital humanities") || $0.localizedCaseInsensitiveContains("text mining") || $0.localizedCaseInsensitiveContains("topic modeling") || $0.localizedCaseInsensitiveContains("cultural analytics") || $0.localizedCaseInsensitiveContains("distant reading")) &&
            ($0.localizedCaseInsensitiveContains("project") || $0.localizedCaseInsensitiveContains("work on") || $0.localizedCaseInsensitiveContains("run") || $0.localizedCaseInsensitiveContains("build"))
        }
        let hasStudy = tasks.contains {
            ($0.localizedCaseInsensitiveContains("digital humanities") || $0.localizedCaseInsensitiveContains("distant reading") || $0.localizedCaseInsensitiveContains("humanities computing") || $0.localizedCaseInsensitiveContains("corpus analysis")) &&
            ($0.localizedCaseInsensitiveContains("study") || $0.localizedCaseInsensitiveContains("review") || $0.localizedCaseInsensitiveContains("class") || $0.localizedCaseInsensitiveContains("methods"))
        }
        #expect(hasProject, "catalog must include a digital humanities project template")
        #expect(hasStudy, "catalog must include a digital humanities study template")
    }

    // MARK: - environmentalpolicy
    @Test func environmentalpolicyTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasPaper = tasks.contains {
            ($0.localizedCaseInsensitiveContains("environmental policy") || $0.localizedCaseInsensitiveContains("climate policy") || $0.localizedCaseInsensitiveContains("carbon tax") || $0.localizedCaseInsensitiveContains("climate legislation") || $0.localizedCaseInsensitiveContains("cap-and-trade")) &&
            ($0.localizedCaseInsensitiveContains("write") || $0.localizedCaseInsensitiveContains("paper") || $0.localizedCaseInsensitiveContains("analyze") || $0.localizedCaseInsensitiveContains("evaluate"))
        }
        let hasStudy = tasks.contains {
            ($0.localizedCaseInsensitiveContains("environmental policy") || $0.localizedCaseInsensitiveContains("climate policy") || $0.localizedCaseInsensitiveContains("carbon market") || $0.localizedCaseInsensitiveContains("environmental regulation")) &&
            ($0.localizedCaseInsensitiveContains("study") || $0.localizedCaseInsensitiveContains("review") || $0.localizedCaseInsensitiveContains("class") || $0.localizedCaseInsensitiveContains("exam"))
        }
        #expect(hasPaper, "catalog must include an environmental policy paper template")
        #expect(hasStudy, "catalog must include an environmental policy study template")
    }

    // MARK: - Count guard (batch: geopolitics/computationalbiology/philosophyofmind/digitalhumanities/environmentalpolicy)
    @Test func catalogHasAtLeastFiveHundredNinetyNineTemplates() {
        #expect(SuggestedSessionTemplates.all.count >= 599,
                "catalog should have ≥599 templates after geopolitics/computationalbiology/philosophyofmind/digitalhumanities/environmentalpolicy additions (10 templates)")
    }

    // MARK: - paleontology
    @Test func paleontologyTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasLab = tasks.contains {
            ($0.localizedCaseInsensitiveContains("paleontology") || $0.localizedCaseInsensitiveContains("fossil") || $0.localizedCaseInsensitiveContains("taphonomy") || $0.localizedCaseInsensitiveContains("biostratigraphy")) &&
            ($0.localizedCaseInsensitiveContains("lab") || $0.localizedCaseInsensitiveContains("analyze") || $0.localizedCaseInsensitiveContains("report") || $0.localizedCaseInsensitiveContains("field notes"))
        }
        let hasStudy = tasks.contains {
            ($0.localizedCaseInsensitiveContains("paleontology") || $0.localizedCaseInsensitiveContains("fossil record") || $0.localizedCaseInsensitiveContains("invertebrate paleontology") || $0.localizedCaseInsensitiveContains("trace fossil")) &&
            ($0.localizedCaseInsensitiveContains("study") || $0.localizedCaseInsensitiveContains("review") || $0.localizedCaseInsensitiveContains("exam"))
        }
        #expect(hasLab, "catalog must include a paleontology lab/analysis template")
        #expect(hasStudy, "catalog must include a paleontology study template")
    }

    // MARK: - experimentalphysics
    @Test func experimentalphysicsTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasLab = tasks.contains {
            ($0.localizedCaseInsensitiveContains("physics lab") || $0.localizedCaseInsensitiveContains("optics") || $0.localizedCaseInsensitiveContains("electromagnetism") || $0.localizedCaseInsensitiveContains("mechanics") || $0.localizedCaseInsensitiveContains("thermodynamics lab")) &&
            ($0.localizedCaseInsensitiveContains("lab report") || $0.localizedCaseInsensitiveContains("write") || $0.localizedCaseInsensitiveContains("analyze"))
        }
        let hasProblemSet = tasks.contains {
            ($0.localizedCaseInsensitiveContains("quantum mechanics") || $0.localizedCaseInsensitiveContains("classical mechanics") || $0.localizedCaseInsensitiveContains("physics")) &&
            ($0.localizedCaseInsensitiveContains("problem set") || $0.localizedCaseInsensitiveContains("coursework") || $0.localizedCaseInsensitiveContains("class"))
        }
        #expect(hasLab, "catalog must include an experimental physics lab report template")
        #expect(hasProblemSet, "catalog must include a physics problem set template")
    }

    // MARK: - informationscience
    @Test func informationscienceTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasAssignment = tasks.contains {
            ($0.localizedCaseInsensitiveContains("information science") || $0.localizedCaseInsensitiveContains("information retrieval") || $0.localizedCaseInsensitiveContains("digital curation") || $0.localizedCaseInsensitiveContains("knowledge management")) &&
            ($0.localizedCaseInsensitiveContains("assignment") || $0.localizedCaseInsensitiveContains("complete") || $0.localizedCaseInsensitiveContains("coursework"))
        }
        let hasStudy = tasks.contains {
            ($0.localizedCaseInsensitiveContains("information science") || $0.localizedCaseInsensitiveContains("information retrieval") || $0.localizedCaseInsensitiveContains("metadata")) &&
            ($0.localizedCaseInsensitiveContains("study") || $0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("course"))
        }
        #expect(hasAssignment, "catalog must include an information science assignment template")
        #expect(hasStudy, "catalog must include an information science study template")
    }

    // MARK: - socialepidemiology
    @Test func socialepidemiologyTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasPaper = tasks.contains {
            ($0.localizedCaseInsensitiveContains("social epidemiology") || $0.localizedCaseInsensitiveContains("social determinants") || $0.localizedCaseInsensitiveContains("health disparities") || $0.localizedCaseInsensitiveContains("health inequities")) &&
            ($0.localizedCaseInsensitiveContains("write") || $0.localizedCaseInsensitiveContains("paper") || $0.localizedCaseInsensitiveContains("analyze"))
        }
        let hasStudy = tasks.contains {
            ($0.localizedCaseInsensitiveContains("social epidemiology") || $0.localizedCaseInsensitiveContains("social determinants") || $0.localizedCaseInsensitiveContains("health disparities") || $0.localizedCaseInsensitiveContains("SDoH")) &&
            ($0.localizedCaseInsensitiveContains("study") || $0.localizedCaseInsensitiveContains("review") || $0.localizedCaseInsensitiveContains("concepts"))
        }
        #expect(hasPaper, "catalog must include a social epidemiology paper template")
        #expect(hasStudy, "catalog must include a social epidemiology study template")
    }

    // MARK: - cognitiveneuroscience
    @Test func cognitiveneuroscienceTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasData = tasks.contains {
            ($0.localizedCaseInsensitiveContains("fmri") || $0.localizedCaseInsensitiveContains("eeg") || $0.localizedCaseInsensitiveContains("bold signal") || $0.localizedCaseInsensitiveContains("neuroimaging") || $0.localizedCaseInsensitiveContains("cognitive neuroscience")) &&
            ($0.localizedCaseInsensitiveContains("analyze") || $0.localizedCaseInsensitiveContains("data") || $0.localizedCaseInsensitiveContains("research"))
        }
        let hasStudy = tasks.contains {
            ($0.localizedCaseInsensitiveContains("cognitive neuroscience") || $0.localizedCaseInsensitiveContains("fmri") || $0.localizedCaseInsensitiveContains("eeg") || $0.localizedCaseInsensitiveContains("neuroimaging")) &&
            ($0.localizedCaseInsensitiveContains("study") || $0.localizedCaseInsensitiveContains("review") || $0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("class"))
        }
        #expect(hasData, "catalog must include a cognitive neuroscience data analysis template")
        #expect(hasStudy, "catalog must include a cognitive neuroscience study template")
    }

    // MARK: - Count guard (batch: paleontology/experimentalphysics/informationscience/socialepidemiology/cognitiveneuroscience)
    @Test func catalogHasAtLeastSixHundredNineteenTemplates() {
        #expect(SuggestedSessionTemplates.all.count >= 619,
                "catalog should have ≥619 templates after paleontology/experimentalphysics/informationscience/socialepidemiology/cognitiveneuroscience additions (10 templates)")
    }

    // MARK: - organicchemistry
    @Test func organicchemistryTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasProblemSet = tasks.contains {
            ($0.localizedCaseInsensitiveContains("organic chemistry") || $0.localizedCaseInsensitiveContains("orgo") || $0.localizedCaseInsensitiveContains("SN1") || $0.localizedCaseInsensitiveContains("reaction mechanism")) &&
            ($0.localizedCaseInsensitiveContains("problem set") || $0.localizedCaseInsensitiveContains("lab") || $0.localizedCaseInsensitiveContains("complete"))
        }
        let hasStudy = tasks.contains {
            ($0.localizedCaseInsensitiveContains("organic chemistry") || $0.localizedCaseInsensitiveContains("orgo") || $0.localizedCaseInsensitiveContains("NMR") || $0.localizedCaseInsensitiveContains("stereochemistry")) &&
            ($0.localizedCaseInsensitiveContains("study") || $0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("review"))
        }
        #expect(hasProblemSet, "catalog must include an organic chemistry problem set template")
        #expect(hasStudy, "catalog must include an organic chemistry study template")
    }

    // MARK: - botany
    @Test func botanyTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasLab = tasks.contains {
            ($0.localizedCaseInsensitiveContains("botany") || $0.localizedCaseInsensitiveContains("plant taxonomy") || $0.localizedCaseInsensitiveContains("plant biology") || $0.localizedCaseInsensitiveContains("herbarium")) &&
            ($0.localizedCaseInsensitiveContains("lab") || $0.localizedCaseInsensitiveContains("complete") || $0.localizedCaseInsensitiveContains("assignment"))
        }
        let hasStudy = tasks.contains {
            ($0.localizedCaseInsensitiveContains("botany") || $0.localizedCaseInsensitiveContains("plant biology") || $0.localizedCaseInsensitiveContains("plant anatomy")) &&
            ($0.localizedCaseInsensitiveContains("study") || $0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("review"))
        }
        #expect(hasLab, "catalog must include a botany lab/assignment template")
        #expect(hasStudy, "catalog must include a botany study template")
    }

    // MARK: - operationsresearch
    @Test func operationsresearchTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasProblemSet = tasks.contains {
            ($0.localizedCaseInsensitiveContains("operations research") || $0.localizedCaseInsensitiveContains("linear programming") || $0.localizedCaseInsensitiveContains("queueing")) &&
            ($0.localizedCaseInsensitiveContains("problem set") || $0.localizedCaseInsensitiveContains("work on") || $0.localizedCaseInsensitiveContains("network flow"))
        }
        let hasStudy = tasks.contains {
            ($0.localizedCaseInsensitiveContains("operations research") || $0.localizedCaseInsensitiveContains("simplex") || $0.localizedCaseInsensitiveContains("linear programming")) &&
            ($0.localizedCaseInsensitiveContains("study") || $0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("review"))
        }
        #expect(hasProblemSet, "catalog must include an operations research problem set template")
        #expect(hasStudy, "catalog must include an operations research study template")
    }

    // MARK: - internalaudit
    @Test func internalauditTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasExam = tasks.contains {
            ($0.localizedCaseInsensitiveContains("CIA") || $0.localizedCaseInsensitiveContains("IIA") || $0.localizedCaseInsensitiveContains("internal audit")) &&
            ($0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("study") || $0.localizedCaseInsensitiveContains("certification"))
        }
        let hasAssignment = tasks.contains {
            ($0.localizedCaseInsensitiveContains("internal audit") || $0.localizedCaseInsensitiveContains("SOX") || $0.localizedCaseInsensitiveContains("audit report")) &&
            ($0.localizedCaseInsensitiveContains("complete") || $0.localizedCaseInsensitiveContains("write") || $0.localizedCaseInsensitiveContains("assignment"))
        }
        #expect(hasExam, "catalog must include an internal audit exam study template")
        #expect(hasAssignment, "catalog must include an internal audit assignment template")
    }

    // MARK: - healthcarequality
    @Test func healthcarequalityTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasExam = tasks.contains {
            ($0.localizedCaseInsensitiveContains("CPHQ") || $0.localizedCaseInsensitiveContains("patient safety") || $0.localizedCaseInsensitiveContains("Joint Commission")) &&
            ($0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("study") || $0.localizedCaseInsensitiveContains("certification"))
        }
        let hasProject = tasks.contains {
            ($0.localizedCaseInsensitiveContains("healthcare quality") || $0.localizedCaseInsensitiveContains("quality improvement") || $0.localizedCaseInsensitiveContains("PDSA")) &&
            ($0.localizedCaseInsensitiveContains("complete") || $0.localizedCaseInsensitiveContains("project") || $0.localizedCaseInsensitiveContains("write"))
        }
        #expect(hasExam, "catalog must include a healthcare quality exam study template")
        #expect(hasProject, "catalog must include a healthcare quality project template")
    }

    // MARK: - Count guard (batch: organicchemistry/botany/operationsresearch/internalaudit/healthcarequality)
    @Test func catalogHasAtLeastSixHundredFiftyTwoTemplates() {
        #expect(SuggestedSessionTemplates.all.count >= 652,
                "catalog should have ≥652 templates after organicchemistry/botany/operationsresearch/internalaudit/healthcarequality additions (10 templates)")
    }

    // MARK: - nursinganesthesia
    @Test func nursinganesthesiaTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasExam = tasks.contains {
            ($0.localizedCaseInsensitiveContains("NBCRNA") || $0.localizedCaseInsensitiveContains("CRNA") || $0.localizedCaseInsensitiveContains("nurse anesthesia")) &&
            ($0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("study") || $0.localizedCaseInsensitiveContains("review"))
        }
        let hasAssignment = tasks.contains {
            ($0.localizedCaseInsensitiveContains("nurse anesthesia") || $0.localizedCaseInsensitiveContains("CRNA")) &&
            ($0.localizedCaseInsensitiveContains("complete") || $0.localizedCaseInsensitiveContains("notes") || $0.localizedCaseInsensitiveContains("assignment"))
        }
        #expect(hasExam, "catalog must include a nurse anesthesia exam/study template")
        #expect(hasAssignment, "catalog must include a nurse anesthesia assignment/notes template")
    }

    // MARK: - physicalchemistry
    @Test func physicalchemistryTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasProblemSet = tasks.contains {
            ($0.localizedCaseInsensitiveContains("physical chemistry") || $0.localizedCaseInsensitiveContains("pchem") || $0.localizedCaseInsensitiveContains("Gibbs")) &&
            ($0.localizedCaseInsensitiveContains("problem set") || $0.localizedCaseInsensitiveContains("work through"))
        }
        let hasStudy = tasks.contains {
            ($0.localizedCaseInsensitiveContains("physical chemistry") || $0.localizedCaseInsensitiveContains("pchem")) &&
            ($0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("study"))
        }
        #expect(hasProblemSet, "catalog must include a physical chemistry problem set template")
        #expect(hasStudy, "catalog must include a physical chemistry study template")
    }

    // MARK: - inorganicchemistry
    @Test func inorganicchemistryTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasProblemSet = tasks.contains {
            ($0.localizedCaseInsensitiveContains("inorganic chemistry") || $0.localizedCaseInsensitiveContains("coordination") || $0.localizedCaseInsensitiveContains("crystal field")) &&
            ($0.localizedCaseInsensitiveContains("problem set") || $0.localizedCaseInsensitiveContains("complete"))
        }
        let hasStudy = tasks.contains {
            ($0.localizedCaseInsensitiveContains("inorganic chemistry") || $0.localizedCaseInsensitiveContains("crystal field")) &&
            ($0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("study"))
        }
        #expect(hasProblemSet, "catalog must include an inorganic chemistry problem set template")
        #expect(hasStudy, "catalog must include an inorganic chemistry study template")
    }

    // MARK: - analyticalchemistry
    @Test func analyticalchemistryTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasLab = tasks.contains {
            ($0.localizedCaseInsensitiveContains("analytical chemistry") || $0.localizedCaseInsensitiveContains("HPLC") || $0.localizedCaseInsensitiveContains("titration")) &&
            ($0.localizedCaseInsensitiveContains("lab") || $0.localizedCaseInsensitiveContains("complete") || $0.localizedCaseInsensitiveContains("report"))
        }
        let hasStudy = tasks.contains {
            ($0.localizedCaseInsensitiveContains("analytical chemistry") || $0.localizedCaseInsensitiveContains("chromatography")) &&
            ($0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("study"))
        }
        #expect(hasLab, "catalog must include an analytical chemistry lab/report template")
        #expect(hasStudy, "catalog must include an analytical chemistry study template")
    }

    // MARK: - nuclearchemistry
    @Test func nuclearchemistryTemplatesExist() {
        let tasks = SuggestedSessionTemplates.all.map { $0.task }
        let hasProblemSet = tasks.contains {
            ($0.localizedCaseInsensitiveContains("nuclear chemistry") || $0.localizedCaseInsensitiveContains("radioactive decay") || $0.localizedCaseInsensitiveContains("half-life")) &&
            ($0.localizedCaseInsensitiveContains("problem set") || $0.localizedCaseInsensitiveContains("work through"))
        }
        let hasStudy = tasks.contains {
            ($0.localizedCaseInsensitiveContains("nuclear chemistry") || $0.localizedCaseInsensitiveContains("radioactive")) &&
            ($0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("study"))
        }
        #expect(hasProblemSet, "catalog must include a nuclear chemistry problem set template")
        #expect(hasStudy, "catalog must include a nuclear chemistry study template")
    }

    // MARK: - Count guard (batch: nursinganesthesia/physicalchemistry/inorganicchemistry/analyticalchemistry/nuclearchemistry)
    @Test func catalogHasAtLeastSixHundredSixtyOneTemplates() {
        #expect(SuggestedSessionTemplates.all.count >= 661,
                "catalog should have ≥661 templates after nursinganesthesia/physicalchemistry/inorganicchemistry/analyticalchemistry/nuclearchemistry additions (10 templates)")
    }

    // MARK: - electrochemistry templates
    @Test func catalogHasElectrochemistryTemplates() {
        let tasks = SuggestedSessionTemplates.all.map(\.task)
        let hasProblemSet = tasks.contains {
            ($0.localizedCaseInsensitiveContains("electrochemistry") || $0.localizedCaseInsensitiveContains("galvanic cell") || $0.localizedCaseInsensitiveContains("nernst equation")) &&
            ($0.localizedCaseInsensitiveContains("problem set") || $0.localizedCaseInsensitiveContains("work through"))
        }
        let hasStudy = tasks.contains {
            ($0.localizedCaseInsensitiveContains("electrochemistry") || $0.localizedCaseInsensitiveContains("electrochemical")) &&
            ($0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("study"))
        }
        #expect(hasProblemSet, "catalog must include an electrochemistry problem set template")
        #expect(hasStudy, "catalog must include an electrochemistry study template")
    }

    // MARK: - polymerchemistry templates
    @Test func catalogHasPolymerchemistryTemplates() {
        let tasks = SuggestedSessionTemplates.all.map(\.task)
        let hasProblemSet = tasks.contains {
            ($0.localizedCaseInsensitiveContains("polymer chemistry") || $0.localizedCaseInsensitiveContains("polymerization") || $0.localizedCaseInsensitiveContains("polydispersity")) &&
            ($0.localizedCaseInsensitiveContains("problem set") || $0.localizedCaseInsensitiveContains("work through"))
        }
        let hasStudy = tasks.contains {
            ($0.localizedCaseInsensitiveContains("polymer chemistry") || $0.localizedCaseInsensitiveContains("polymer science")) &&
            ($0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("study"))
        }
        #expect(hasProblemSet, "catalog must include a polymer chemistry problem set template")
        #expect(hasStudy, "catalog must include a polymer chemistry study template")
    }

    // MARK: - maternalhealth templates
    @Test func catalogHasMaternalhealthTemplates() {
        let tasks = SuggestedSessionTemplates.all.map(\.task)
        let hasAssignment = tasks.contains {
            ($0.localizedCaseInsensitiveContains("maternal health") || $0.localizedCaseInsensitiveContains("OB nursing") || $0.localizedCaseInsensitiveContains("obstetric nursing")) &&
            ($0.localizedCaseInsensitiveContains("assignment") || $0.localizedCaseInsensitiveContains("complete"))
        }
        let hasStudy = tasks.contains {
            ($0.localizedCaseInsensitiveContains("maternal health") || $0.localizedCaseInsensitiveContains("OB nursing") || $0.localizedCaseInsensitiveContains("prenatal")) &&
            ($0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("study"))
        }
        #expect(hasAssignment, "catalog must include a maternal health assignment template")
        #expect(hasStudy, "catalog must include a maternal health study template")
    }

    // MARK: - globalhealthpolicy templates
    @Test func catalogHasGlobalhealthpolicyTemplates() {
        let tasks = SuggestedSessionTemplates.all.map(\.task)
        let hasPaper = tasks.contains {
            ($0.localizedCaseInsensitiveContains("global health policy") || $0.localizedCaseInsensitiveContains("health systems strengthening") || $0.localizedCaseInsensitiveContains("universal health coverage")) &&
            ($0.localizedCaseInsensitiveContains("paper") || $0.localizedCaseInsensitiveContains("work on") || $0.localizedCaseInsensitiveContains("assignment"))
        }
        let hasStudy = tasks.contains {
            ($0.localizedCaseInsensitiveContains("global health policy") || $0.localizedCaseInsensitiveContains("global health")) &&
            ($0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("study"))
        }
        #expect(hasPaper, "catalog must include a global health policy paper/assignment template")
        #expect(hasStudy, "catalog must include a global health policy study template")
    }

    // MARK: - processengineering templates
    @Test func catalogHasProcessengineeringTemplates() {
        let tasks = SuggestedSessionTemplates.all.map(\.task)
        let hasProblemSet = tasks.contains {
            ($0.localizedCaseInsensitiveContains("unit operations") || $0.localizedCaseInsensitiveContains("process engineering") || $0.localizedCaseInsensitiveContains("reactor design")) &&
            ($0.localizedCaseInsensitiveContains("problem set") || $0.localizedCaseInsensitiveContains("work through"))
        }
        let hasStudy = tasks.contains {
            ($0.localizedCaseInsensitiveContains("unit operations") || $0.localizedCaseInsensitiveContains("process engineering") || $0.localizedCaseInsensitiveContains("transport phenomena")) &&
            ($0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("study"))
        }
        #expect(hasProblemSet, "catalog must include a process engineering problem set template")
        #expect(hasStudy, "catalog must include a process engineering study template")
    }

    // MARK: - Count guard (batch: electrochemistry/polymerchemistry/maternalhealth/globalhealthpolicy/processengineering)
    @Test func catalogHasAtLeastSixHundredSeventyOneTemplates() {
        #expect(SuggestedSessionTemplates.all.count >= 671,
                "catalog should have ≥671 templates after electrochemistry/polymerchemistry/maternalhealth/globalhealthpolicy/processengineering additions (10 templates)")
    }

    // MARK: - civilengineering templates
    @Test func catalogHasCivilengineeringTemplates() {
        let tasks = SuggestedSessionTemplates.all.map(\.task)
        let hasProblemSet = tasks.contains {
            ($0.localizedCaseInsensitiveContains("civil engineering") || $0.localizedCaseInsensitiveContains("structural analysis") || $0.localizedCaseInsensitiveContains("reinforced concrete") || $0.localizedCaseInsensitiveContains("geotechnical")) &&
            ($0.localizedCaseInsensitiveContains("problem set") || $0.localizedCaseInsensitiveContains("work through"))
        }
        let hasStudy = tasks.contains {
            ($0.localizedCaseInsensitiveContains("civil engineering") || $0.localizedCaseInsensitiveContains("structural") || $0.localizedCaseInsensitiveContains("geotechnical")) &&
            ($0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("study"))
        }
        #expect(hasProblemSet, "catalog must include a civil engineering problem set template")
        #expect(hasStudy, "catalog must include a civil engineering study template")
    }

    // MARK: - syntheticbiology templates
    @Test func catalogHasSyntheticbiologyTemplates() {
        let tasks = SuggestedSessionTemplates.all.map(\.task)
        let hasProject = tasks.contains {
            ($0.localizedCaseInsensitiveContains("synthetic biology") || $0.localizedCaseInsensitiveContains("genetic circuit") || $0.localizedCaseInsensitiveContains("iGEM") || $0.localizedCaseInsensitiveContains("BioBrick")) &&
            ($0.localizedCaseInsensitiveContains("project") || $0.localizedCaseInsensitiveContains("work on") || $0.localizedCaseInsensitiveContains("design"))
        }
        let hasStudy = tasks.contains {
            ($0.localizedCaseInsensitiveContains("synthetic biology") || $0.localizedCaseInsensitiveContains("genetic circuit") || $0.localizedCaseInsensitiveContains("metabolic engineering")) &&
            ($0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("study"))
        }
        #expect(hasProject, "catalog must include a synthetic biology project template")
        #expect(hasStudy, "catalog must include a synthetic biology study template")
    }

    // MARK: - proteomics templates
    @Test func catalogHasProteomicsTemplates() {
        let tasks = SuggestedSessionTemplates.all.map(\.task)
        let hasAnalysis = tasks.contains {
            ($0.localizedCaseInsensitiveContains("proteomics") || $0.localizedCaseInsensitiveContains("LC-MS/MS") || $0.localizedCaseInsensitiveContains("mass spectrometry")) &&
            ($0.localizedCaseInsensitiveContains("analyze") || $0.localizedCaseInsensitiveContains("interpret") || $0.localizedCaseInsensitiveContains("write up"))
        }
        let hasStudy = tasks.contains {
            ($0.localizedCaseInsensitiveContains("proteomics") || $0.localizedCaseInsensitiveContains("shotgun proteomics") || $0.localizedCaseInsensitiveContains("2D-PAGE")) &&
            ($0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("study"))
        }
        #expect(hasAnalysis, "catalog must include a proteomics data analysis template")
        #expect(hasStudy, "catalog must include a proteomics study template")
    }

    // MARK: - metabolomics templates
    @Test func catalogHasMetabolomicsTemplates() {
        let tasks = SuggestedSessionTemplates.all.map(\.task)
        let hasAnalysis = tasks.contains {
            ($0.localizedCaseInsensitiveContains("metabolomics") || $0.localizedCaseInsensitiveContains("metabolite") || $0.localizedCaseInsensitiveContains("NMR")) &&
            ($0.localizedCaseInsensitiveContains("analyze") || $0.localizedCaseInsensitiveContains("interpret") || $0.localizedCaseInsensitiveContains("write up"))
        }
        let hasStudy = tasks.contains {
            ($0.localizedCaseInsensitiveContains("metabolomics") || $0.localizedCaseInsensitiveContains("metabolite") || $0.localizedCaseInsensitiveContains("metabolic flux")) &&
            ($0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("study"))
        }
        #expect(hasAnalysis, "catalog must include a metabolomics data analysis template")
        #expect(hasStudy, "catalog must include a metabolomics study template")
    }

    // MARK: - electrophysiology templates
    @Test func catalogHasElectrophysiologyTemplates() {
        let tasks = SuggestedSessionTemplates.all.map(\.task)
        let hasAnalysis = tasks.contains {
            ($0.localizedCaseInsensitiveContains("electrophysiology") || $0.localizedCaseInsensitiveContains("patch clamp") || $0.localizedCaseInsensitiveContains("MEA") || $0.localizedCaseInsensitiveContains("recording")) &&
            ($0.localizedCaseInsensitiveContains("analyze") || $0.localizedCaseInsensitiveContains("sort") || $0.localizedCaseInsensitiveContains("interpret"))
        }
        let hasStudy = tasks.contains {
            ($0.localizedCaseInsensitiveContains("electrophysiology") || $0.localizedCaseInsensitiveContains("patch clamp") || $0.localizedCaseInsensitiveContains("voltage clamp")) &&
            ($0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("study"))
        }
        #expect(hasAnalysis, "catalog must include an electrophysiology data analysis template")
        #expect(hasStudy, "catalog must include an electrophysiology study template")
    }

    // MARK: - Count guard (batch: civilengineering/syntheticbiology/proteomics/metabolomics/electrophysiology)
    @Test func catalogHasAtLeastSixHundredEightyOneTemplates() {
        #expect(SuggestedSessionTemplates.all.count >= 681,
                "catalog should have ≥681 templates after civilengineering/syntheticbiology/proteomics/metabolomics/electrophysiology additions (10 templates)")
    }

    // MARK: - aerospacengineering templates
    @Test func catalogHasAerospacengineeringTemplates() {
        let tasks = SuggestedSessionTemplates.all.map(\.task)
        let hasWork = tasks.contains {
            ($0.localizedCaseInsensitiveContains("aerospace") || $0.localizedCaseInsensitiveContains("aerodynamics") || $0.localizedCaseInsensitiveContains("orbital") || $0.localizedCaseInsensitiveContains("propulsion")) &&
            ($0.localizedCaseInsensitiveContains("assignment") || $0.localizedCaseInsensitiveContains("problem") || $0.localizedCaseInsensitiveContains("design"))
        }
        let hasStudy = tasks.contains {
            ($0.localizedCaseInsensitiveContains("aerospace") || $0.localizedCaseInsensitiveContains("aerodynamics") || $0.localizedCaseInsensitiveContains("orbital") || $0.localizedCaseInsensitiveContains("propulsion")) &&
            ($0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("study"))
        }
        #expect(hasWork, "catalog must include an aerospace engineering work template")
        #expect(hasStudy, "catalog must include an aerospace engineering study template")
    }

    // MARK: - electricalengineering templates
    @Test func catalogHasElectricalengineeringTemplates() {
        let tasks = SuggestedSessionTemplates.all.map(\.task)
        let hasWork = tasks.contains {
            ($0.localizedCaseInsensitiveContains("electrical engineering") || $0.localizedCaseInsensitiveContains("circuit") || $0.localizedCaseInsensitiveContains("Kirchhoff") || $0.localizedCaseInsensitiveContains("op-amp")) &&
            ($0.localizedCaseInsensitiveContains("problem") || $0.localizedCaseInsensitiveContains("set") || $0.localizedCaseInsensitiveContains("analysis") || $0.localizedCaseInsensitiveContains("lab"))
        }
        let hasStudy = tasks.contains {
            ($0.localizedCaseInsensitiveContains("electrical engineering") || $0.localizedCaseInsensitiveContains("circuit") || $0.localizedCaseInsensitiveContains("signal processing") || $0.localizedCaseInsensitiveContains("Thevenin")) &&
            ($0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("study"))
        }
        #expect(hasWork, "catalog must include an electrical engineering work template")
        #expect(hasStudy, "catalog must include an electrical engineering study template")
    }

    // MARK: - genetics templates
    @Test func catalogHasGeneticsTemplates() {
        let tasks = SuggestedSessionTemplates.all.map(\.task)
        let hasWork = tasks.contains {
            ($0.localizedCaseInsensitiveContains("genetics") || $0.localizedCaseInsensitiveContains("Punnett") || $0.localizedCaseInsensitiveContains("Hardy-Weinberg") || $0.localizedCaseInsensitiveContains("pedigree")) &&
            ($0.localizedCaseInsensitiveContains("problem") || $0.localizedCaseInsensitiveContains("set") || $0.localizedCaseInsensitiveContains("work"))
        }
        let hasStudy = tasks.contains {
            ($0.localizedCaseInsensitiveContains("genetics") || $0.localizedCaseInsensitiveContains("Mendelian") || $0.localizedCaseInsensitiveContains("Hardy-Weinberg") || $0.localizedCaseInsensitiveContains("population genetics")) &&
            ($0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("study"))
        }
        #expect(hasWork, "catalog must include a genetics work template")
        #expect(hasStudy, "catalog must include a genetics study template")
    }

    // MARK: - microbiology templates
    @Test func catalogHasMicrobiologyTemplates() {
        let tasks = SuggestedSessionTemplates.all.map(\.task)
        let hasLab = tasks.contains {
            ($0.localizedCaseInsensitiveContains("microbiology") || $0.localizedCaseInsensitiveContains("gram stain") || $0.localizedCaseInsensitiveContains("bacterial") || $0.localizedCaseInsensitiveContains("bacteriology")) &&
            ($0.localizedCaseInsensitiveContains("lab") || $0.localizedCaseInsensitiveContains("report") || $0.localizedCaseInsensitiveContains("assignment"))
        }
        let hasStudy = tasks.contains {
            ($0.localizedCaseInsensitiveContains("microbiology") || $0.localizedCaseInsensitiveContains("bacteriology") || $0.localizedCaseInsensitiveContains("virology")) &&
            ($0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("study"))
        }
        #expect(hasLab, "catalog must include a microbiology lab/assignment template")
        #expect(hasStudy, "catalog must include a microbiology study template")
    }

    // MARK: - immunology templates
    @Test func catalogHasImmunologyTemplates() {
        let tasks = SuggestedSessionTemplates.all.map(\.task)
        let hasStudy = tasks.contains {
            ($0.localizedCaseInsensitiveContains("immunology") || $0.localizedCaseInsensitiveContains("immunity") || $0.localizedCaseInsensitiveContains("T cell") || $0.localizedCaseInsensitiveContains("antibody")) &&
            ($0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("study"))
        }
        let hasWork = tasks.contains {
            ($0.localizedCaseInsensitiveContains("immunology") || $0.localizedCaseInsensitiveContains("immune") || $0.localizedCaseInsensitiveContains("cytokine") || $0.localizedCaseInsensitiveContains("MHC")) &&
            ($0.localizedCaseInsensitiveContains("assignment") || $0.localizedCaseInsensitiveContains("problem") || $0.localizedCaseInsensitiveContains("work"))
        }
        #expect(hasStudy, "catalog must include an immunology study template")
        #expect(hasWork, "catalog must include an immunology work template")
    }

    // MARK: - parasitology templates
    @Test func catalogHasParasitologyTemplates() {
        let tasks = SuggestedSessionTemplates.all.map(\.task)
        let hasLab = tasks.contains {
            ($0.localizedCaseInsensitiveContains("parasitology") || $0.localizedCaseInsensitiveContains("helminth") || $0.localizedCaseInsensitiveContains("protozoa") || $0.localizedCaseInsensitiveContains("parasite")) &&
            ($0.localizedCaseInsensitiveContains("lab") || $0.localizedCaseInsensitiveContains("report") || $0.localizedCaseInsensitiveContains("assignment"))
        }
        let hasStudy = tasks.contains {
            ($0.localizedCaseInsensitiveContains("parasitology") || $0.localizedCaseInsensitiveContains("helminth") || $0.localizedCaseInsensitiveContains("parasite")) &&
            ($0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("study"))
        }
        #expect(hasLab, "catalog must include a parasitology lab/assignment template")
        #expect(hasStudy, "catalog must include a parasitology study template")
    }

    // MARK: - embryology templates
    @Test func catalogHasEmbryologyTemplates() {
        let tasks = SuggestedSessionTemplates.all.map(\.task)
        let hasStudy = tasks.contains {
            ($0.localizedCaseInsensitiveContains("embryology") || $0.localizedCaseInsensitiveContains("organogenesis") || $0.localizedCaseInsensitiveContains("germ layer")) &&
            ($0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("study"))
        }
        let hasWork = tasks.contains {
            ($0.localizedCaseInsensitiveContains("embryology") || $0.localizedCaseInsensitiveContains("developmental")) &&
            ($0.localizedCaseInsensitiveContains("assignment") || $0.localizedCaseInsensitiveContains("work"))
        }
        #expect(hasStudy, "catalog must include an embryology study template")
        #expect(hasWork, "catalog must include an embryology work template")
    }

    // MARK: - histology templates
    @Test func catalogHasHistologyTemplates() {
        let tasks = SuggestedSessionTemplates.all.map(\.task)
        let hasPractice = tasks.contains {
            ($0.localizedCaseInsensitiveContains("histology") || $0.localizedCaseInsensitiveContains("tissue") || $0.localizedCaseInsensitiveContains("H&E")) &&
            ($0.localizedCaseInsensitiveContains("slide") || $0.localizedCaseInsensitiveContains("identification") || $0.localizedCaseInsensitiveContains("practice"))
        }
        let hasStudy = tasks.contains {
            ($0.localizedCaseInsensitiveContains("histology") || $0.localizedCaseInsensitiveContains("epithelial") || $0.localizedCaseInsensitiveContains("tissue")) &&
            ($0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("study") || $0.localizedCaseInsensitiveContains("practical"))
        }
        #expect(hasPractice, "catalog must include a histology practice/slide template")
        #expect(hasStudy, "catalog must include a histology study template")
    }

    // MARK: - pathology templates
    @Test func catalogHasPathologyTemplates() {
        let tasks = SuggestedSessionTemplates.all.map(\.task)
        let hasStudy = tasks.contains {
            ($0.localizedCaseInsensitiveContains("pathology") || $0.localizedCaseInsensitiveContains("histopathology") || $0.localizedCaseInsensitiveContains("disease mechanisms")) &&
            ($0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("study"))
        }
        let hasWork = tasks.contains {
            ($0.localizedCaseInsensitiveContains("pathology") || $0.localizedCaseInsensitiveContains("gross") || $0.localizedCaseInsensitiveContains("histopathology")) &&
            ($0.localizedCaseInsensitiveContains("lab") || $0.localizedCaseInsensitiveContains("assignment") || $0.localizedCaseInsensitiveContains("work"))
        }
        #expect(hasStudy, "catalog must include a pathology study template")
        #expect(hasWork, "catalog must include a pathology lab/work template")
    }

    // MARK: - neuroanatomy templates
    @Test func catalogHasNeuroanatomyTemplates() {
        let tasks = SuggestedSessionTemplates.all.map(\.task)
        let hasStudy = tasks.contains {
            ($0.localizedCaseInsensitiveContains("neuroanatomy") || $0.localizedCaseInsensitiveContains("cranial nerve") || $0.localizedCaseInsensitiveContains("brain region")) &&
            ($0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("study"))
        }
        let hasPractice = tasks.contains {
            ($0.localizedCaseInsensitiveContains("neuroanatomy") || $0.localizedCaseInsensitiveContains("cranial nerve") || $0.localizedCaseInsensitiveContains("neural pathway")) &&
            ($0.localizedCaseInsensitiveContains("identification") || $0.localizedCaseInsensitiveContains("practice") || $0.localizedCaseInsensitiveContains("label") || $0.localizedCaseInsensitiveContains("map"))
        }
        #expect(hasStudy, "catalog must include a neuroanatomy study template")
        #expect(hasPractice, "catalog must include a neuroanatomy practice/identification template")
    }

    // MARK: - Count guard (batch: parasitology/embryology/histology/pathology/neuroanatomy)
    @Test func catalogHasAtLeastSevenHundredOneTemplates() {
        #expect(SuggestedSessionTemplates.all.count >= 701,
                "catalog should have ≥701 templates after parasitology/embryology/histology/pathology/neuroanatomy additions (10 templates)")
    }

    // MARK: - chemicalkinetics templates
    @Test func catalogHasChemicalKineticsTemplates() {
        let tasks = SuggestedSessionTemplates.all.map(\.task)
        let hasProblemSet = tasks.contains {
            ($0.localizedCaseInsensitiveContains("kinetics") || $0.localizedCaseInsensitiveContains("rate law")) &&
            ($0.localizedCaseInsensitiveContains("problem") || $0.localizedCaseInsensitiveContains("derive") || $0.localizedCaseInsensitiveContains("solve") || $0.localizedCaseInsensitiveContains("work"))
        }
        let hasStudy = tasks.contains {
            $0.localizedCaseInsensitiveContains("kinetics") &&
            ($0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("study"))
        }
        #expect(hasProblemSet, "catalog must include a chemical kinetics problem set template")
        #expect(hasStudy, "catalog must include a chemical kinetics study template")
    }

    // MARK: - computationalchemistry templates
    @Test func catalogHasComputationalChemistryTemplates() {
        let tasks = SuggestedSessionTemplates.all.map(\.task)
        let hasCalc = tasks.contains {
            ($0.localizedCaseInsensitiveContains("computational chemistry") || $0.localizedCaseInsensitiveContains("DFT") || $0.localizedCaseInsensitiveContains("ab initio")) &&
            ($0.localizedCaseInsensitiveContains("calculation") || $0.localizedCaseInsensitiveContains("run") || $0.localizedCaseInsensitiveContains("analyze"))
        }
        let hasStudy = tasks.contains {
            $0.localizedCaseInsensitiveContains("computational chemistry") &&
            ($0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("study") || $0.localizedCaseInsensitiveContains("method"))
        }
        #expect(hasCalc, "catalog must include a computational chemistry calculation template")
        #expect(hasStudy, "catalog must include a computational chemistry study template")
    }

    // MARK: - ecology templates
    @Test func catalogHasEcologyTemplates() {
        let tasks = SuggestedSessionTemplates.all.map(\.task)
        let hasStudy = tasks.contains {
            $0.localizedCaseInsensitiveContains("ecology") &&
            ($0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("study"))
        }
        let hasLab = tasks.contains {
            $0.localizedCaseInsensitiveContains("ecology") &&
            ($0.localizedCaseInsensitiveContains("lab") || $0.localizedCaseInsensitiveContains("assignment") || $0.localizedCaseInsensitiveContains("food web"))
        }
        #expect(hasStudy, "catalog must include an ecology study template")
        #expect(hasLab, "catalog must include an ecology lab/assignment template")
    }

    // MARK: - pharmacology templates
    @Test func catalogHasPharmacologyTemplates() {
        let tasks = SuggestedSessionTemplates.all.map(\.task)
        let hasStudy = tasks.contains {
            $0.localizedCaseInsensitiveContains("pharmacology") &&
            ($0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("study"))
        }
        let hasAssignment = tasks.contains {
            $0.localizedCaseInsensitiveContains("pharmacology") &&
            ($0.localizedCaseInsensitiveContains("assignment") || $0.localizedCaseInsensitiveContains("dose-response") || $0.localizedCaseInsensitiveContains("work through"))
        }
        #expect(hasStudy, "catalog must include a pharmacology study template")
        #expect(hasAssignment, "catalog must include a pharmacology assignment template")
    }

    // MARK: - physiology templates
    @Test func catalogHasPhysiologyTemplates() {
        let tasks = SuggestedSessionTemplates.all.map(\.task)
        let hasStudy = tasks.contains {
            $0.localizedCaseInsensitiveContains("physiology") &&
            ($0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("study"))
        }
        let hasLab = tasks.contains {
            $0.localizedCaseInsensitiveContains("physiology") &&
            ($0.localizedCaseInsensitiveContains("lab") || $0.localizedCaseInsensitiveContains("assignment") || $0.localizedCaseInsensitiveContains("complete"))
        }
        #expect(hasStudy, "catalog must include a physiology study template")
        #expect(hasLab, "catalog must include a physiology lab/assignment template")
    }

    // MARK: - Count guard (batch: chemicalkinetics/computationalchemistry/ecology/pharmacology/physiology)
    @Test func catalogHasAtLeastSevenHundredNineTemplates() {
        #expect(SuggestedSessionTemplates.all.count >= 709,
                "catalog should have ≥709 templates after chemicalkinetics/computationalchemistry/ecology/pharmacology/physiology additions (10 templates)")
    }

    // MARK: - mechanicalengineering templates
    @Test func catalogHasMechanicalEngineeringTemplates() {
        let tasks = SuggestedSessionTemplates.all.map(\.task)
        let hasProblemSet = tasks.contains {
            $0.localizedCaseInsensitiveContains("mechanical engineering") &&
            ($0.localizedCaseInsensitiveContains("problem set") || $0.localizedCaseInsensitiveContains("dynamics") || $0.localizedCaseInsensitiveContains("machine design"))
        }
        let hasStudy = tasks.contains {
            $0.localizedCaseInsensitiveContains("mechanical engineering") &&
            ($0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("study"))
        }
        #expect(hasProblemSet, "catalog must include a mechanical engineering problem set template")
        #expect(hasStudy, "catalog must include a mechanical engineering study template")
    }

    // MARK: - nuclearengineering templates
    @Test func catalogHasNuclearEngineeringTemplates() {
        let tasks = SuggestedSessionTemplates.all.map(\.task)
        let hasProblemSet = tasks.contains {
            $0.localizedCaseInsensitiveContains("nuclear engineering") &&
            ($0.localizedCaseInsensitiveContains("problem set") || $0.localizedCaseInsensitiveContains("neutron") || $0.localizedCaseInsensitiveContains("reactor"))
        }
        let hasStudy = tasks.contains {
            $0.localizedCaseInsensitiveContains("nuclear engineering") &&
            ($0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("study"))
        }
        #expect(hasProblemSet, "catalog must include a nuclear engineering problem set template")
        #expect(hasStudy, "catalog must include a nuclear engineering study template")
    }

    // MARK: - materialstesting templates
    @Test func catalogHasMaterialsTestingTemplates() {
        let tasks = SuggestedSessionTemplates.all.map(\.task)
        let hasLab = tasks.contains {
            $0.localizedCaseInsensitiveContains("materials testing") &&
            ($0.localizedCaseInsensitiveContains("lab") || $0.localizedCaseInsensitiveContains("tensile") || $0.localizedCaseInsensitiveContains("stress-strain"))
        }
        let hasStudy = tasks.contains {
            $0.localizedCaseInsensitiveContains("materials testing") &&
            ($0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("study"))
        }
        #expect(hasLab, "catalog must include a materials testing lab template")
        #expect(hasStudy, "catalog must include a materials testing study template")
    }

    // MARK: - biomedicalengineering templates
    @Test func catalogHasBiomedicalEngineeringTemplates() {
        let tasks = SuggestedSessionTemplates.all.map(\.task)
        let hasAssignment = tasks.contains {
            $0.localizedCaseInsensitiveContains("biomedical engineering") &&
            ($0.localizedCaseInsensitiveContains("assignment") || $0.localizedCaseInsensitiveContains("biomechanics") || $0.localizedCaseInsensitiveContains("biomaterials"))
        }
        let hasStudy = tasks.contains {
            $0.localizedCaseInsensitiveContains("biomedical engineering") &&
            ($0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("study"))
        }
        #expect(hasAssignment, "catalog must include a biomedical engineering assignment template")
        #expect(hasStudy, "catalog must include a biomedical engineering study template")
    }

    // MARK: - chemicalengineering templates
    @Test func catalogHasChemicalEngineeringTemplates() {
        let tasks = SuggestedSessionTemplates.all.map(\.task)
        let hasProblemSet = tasks.contains {
            $0.localizedCaseInsensitiveContains("chemical engineering") &&
            ($0.localizedCaseInsensitiveContains("problem set") || $0.localizedCaseInsensitiveContains("transport phenomena") || $0.localizedCaseInsensitiveContains("unit operations"))
        }
        let hasStudy = tasks.contains {
            $0.localizedCaseInsensitiveContains("chemical engineering") &&
            ($0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("study"))
        }
        #expect(hasProblemSet, "catalog must include a chemical engineering problem set template")
        #expect(hasStudy, "catalog must include a chemical engineering study template")
    }

    // MARK: - Count guard (batch: mechanicalengineering/nuclearengineering/materialstesting/biomedicalengineering/chemicalengineering)
    @Test func catalogHasAtLeastSevenHundredTwentyOneTemplates() {
        #expect(SuggestedSessionTemplates.all.count >= 721,
                "catalog should have ≥721 templates after mechanicalengineering/nuclearengineering/materialstesting/biomedicalengineering/chemicalengineering additions (10 templates)")
    }

    // MARK: - oceanography templates
    @Test func catalogHasOceanographyTemplates() {
        let tasks = SuggestedSessionTemplates.all.map(\.task)
        let hasStudy = tasks.contains {
            $0.localizedCaseInsensitiveContains("oceanography") &&
            ($0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("study") || $0.localizedCaseInsensitiveContains("circulation"))
        }
        let hasLab = tasks.contains {
            $0.localizedCaseInsensitiveContains("oceanography") &&
            ($0.localizedCaseInsensitiveContains("lab") || $0.localizedCaseInsensitiveContains("assignment") || $0.localizedCaseInsensitiveContains("data"))
        }
        #expect(hasStudy, "catalog must include an oceanography study template")
        #expect(hasLab, "catalog must include an oceanography lab/assignment template")
    }

    // MARK: - geochemistry templates
    @Test func catalogHasGeochemistryTemplates() {
        let tasks = SuggestedSessionTemplates.all.map(\.task)
        let hasStudy = tasks.contains {
            $0.localizedCaseInsensitiveContains("geochemistry") &&
            ($0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("study") || $0.localizedCaseInsensitiveContains("isotope"))
        }
        let hasLab = tasks.contains {
            $0.localizedCaseInsensitiveContains("geochemistry") &&
            ($0.localizedCaseInsensitiveContains("lab") || $0.localizedCaseInsensitiveContains("assignment") || $0.localizedCaseInsensitiveContains("data"))
        }
        #expect(hasStudy, "catalog must include a geochemistry study template")
        #expect(hasLab, "catalog must include a geochemistry lab/assignment template")
    }

    // MARK: - thermodynamics templates
    @Test func catalogHasThermodynamicsTemplates() {
        let tasks = SuggestedSessionTemplates.all.map(\.task)
        let hasProblemSet = tasks.contains {
            $0.localizedCaseInsensitiveContains("thermodynamics") &&
            ($0.localizedCaseInsensitiveContains("problem set") || $0.localizedCaseInsensitiveContains("Rankine") || $0.localizedCaseInsensitiveContains("steam tables"))
        }
        let hasStudy = tasks.contains {
            $0.localizedCaseInsensitiveContains("thermodynamics") &&
            ($0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("study"))
        }
        #expect(hasProblemSet, "catalog must include a thermodynamics problem set template")
        #expect(hasStudy, "catalog must include a thermodynamics study template")
    }

    // MARK: - radiologyrotation templates
    @Test func catalogHasRadiologyRotationTemplates() {
        let tasks = SuggestedSessionTemplates.all.map(\.task)
        let hasReading = tasks.contains {
            $0.localizedCaseInsensitiveContains("radiology") &&
            ($0.localizedCaseInsensitiveContains("reading") || $0.localizedCaseInsensitiveContains("interpret") || $0.localizedCaseInsensitiveContains("PACS"))
        }
        let hasStudy = tasks.contains {
            $0.localizedCaseInsensitiveContains("radiology") &&
            ($0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("study") || $0.localizedCaseInsensitiveContains("rotation"))
        }
        #expect(hasReading, "catalog must include a radiology reading/interpretation template")
        #expect(hasStudy, "catalog must include a radiology study/rotation template")
    }

    // MARK: - anesthesiology templates
    @Test func catalogHasAnesthesiologyTemplates() {
        let tasks = SuggestedSessionTemplates.all.map(\.task)
        let hasStudy = tasks.contains {
            $0.localizedCaseInsensitiveContains("anesthesiology") &&
            ($0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("study") || $0.localizedCaseInsensitiveContains("CRNA"))
        }
        let hasAssignment = tasks.contains {
            $0.localizedCaseInsensitiveContains("anesthesiology") &&
            ($0.localizedCaseInsensitiveContains("assignment") || $0.localizedCaseInsensitiveContains("case") || $0.localizedCaseInsensitiveContains("rotation"))
        }
        #expect(hasStudy, "catalog must include an anesthesiology study template")
        #expect(hasAssignment, "catalog must include an anesthesiology assignment/case template")
    }

    // MARK: - Count guard (batch: oceanography/geochemistry/thermodynamics/radiologyrotation/anesthesiology)
    @Test func catalogHasAtLeastSevenHundredThirtyOneTemplates() {
        #expect(SuggestedSessionTemplates.all.count >= 731,
                "catalog should have ≥731 templates after oceanography/geochemistry/thermodynamics/radiologyrotation/anesthesiology additions (10 templates)")
    }

    // MARK: - structuralbiology templates
    @Test func catalogHasStructuralbiologyTemplates() {
        let tasks = SuggestedSessionTemplates.all.map(\.task)
        let hasResearch = tasks.contains {
            $0.localizedCaseInsensitiveContains("structural biology") &&
            ($0.localizedCaseInsensitiveContains("cryo") || $0.localizedCaseInsensitiveContains("protein") || $0.localizedCaseInsensitiveContains("PDB"))
        }
        let hasStudy = tasks.contains {
            $0.localizedCaseInsensitiveContains("structural biology") &&
            ($0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("class") || $0.localizedCaseInsensitiveContains("study"))
        }
        #expect(hasResearch, "catalog must include a structural biology research template")
        #expect(hasStudy, "catalog must include a structural biology study template")
    }

    // MARK: - biochemistrylab templates
    @Test func catalogHasBiochemistrylabTemplates() {
        let tasks = SuggestedSessionTemplates.all.map(\.task)
        let hasLabReport = tasks.contains {
            $0.localizedCaseInsensitiveContains("biochemistry lab") &&
            ($0.localizedCaseInsensitiveContains("report") || $0.localizedCaseInsensitiveContains("SDS") || $0.localizedCaseInsensitiveContains("enzyme") || $0.localizedCaseInsensitiveContains("notebook"))
        }
        let hasStudy = tasks.contains {
            $0.localizedCaseInsensitiveContains("biochemistry lab") &&
            ($0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("technique") || $0.localizedCaseInsensitiveContains("practical"))
        }
        #expect(hasLabReport, "catalog must include a biochemistry lab report template")
        #expect(hasStudy, "catalog must include a biochemistry lab techniques study template")
    }

    // MARK: - clinicalneurology templates
    @Test func catalogHasClinicalNeurologyTemplates() {
        let tasks = SuggestedSessionTemplates.all.map(\.task)
        let hasRotation = tasks.contains {
            $0.localizedCaseInsensitiveContains("neurology") &&
            ($0.localizedCaseInsensitiveContains("rotation") || $0.localizedCaseInsensitiveContains("rounds") || $0.localizedCaseInsensitiveContains("case notes"))
        }
        let hasStudy = tasks.contains {
            $0.localizedCaseInsensitiveContains("neurology") &&
            ($0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("study") || $0.localizedCaseInsensitiveContains("neurological"))
        }
        #expect(hasRotation, "catalog must include a clinical neurology rotation template")
        #expect(hasStudy, "catalog must include a clinical neurology study template")
    }

    // MARK: - dermatologyrotation templates
    @Test func catalogHasDermatologyRotationTemplates() {
        let tasks = SuggestedSessionTemplates.all.map(\.task)
        let hasRotation = tasks.contains {
            $0.localizedCaseInsensitiveContains("dermatology") &&
            ($0.localizedCaseInsensitiveContains("rotation") || $0.localizedCaseInsensitiveContains("derm") || $0.localizedCaseInsensitiveContains("lesion"))
        }
        let hasStudy = tasks.contains {
            $0.localizedCaseInsensitiveContains("dermatology") &&
            ($0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("study") || $0.localizedCaseInsensitiveContains("dermoscopy"))
        }
        #expect(hasRotation, "catalog must include a dermatology rotation template")
        #expect(hasStudy, "catalog must include a dermatology study template")
    }

    // MARK: - psychiatryrotation templates
    @Test func catalogHasPsychiatryRotationTemplates() {
        let tasks = SuggestedSessionTemplates.all.map(\.task)
        let hasRotation = tasks.contains {
            $0.localizedCaseInsensitiveContains("psychiatry") &&
            ($0.localizedCaseInsensitiveContains("rotation") || $0.localizedCaseInsensitiveContains("formulation") || $0.localizedCaseInsensitiveContains("DSM"))
        }
        let hasStudy = tasks.contains {
            $0.localizedCaseInsensitiveContains("psychiatry") &&
            ($0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("study") || $0.localizedCaseInsensitiveContains("diagnostic"))
        }
        #expect(hasRotation, "catalog must include a psychiatry rotation template")
        #expect(hasStudy, "catalog must include a psychiatry study template")
    }

    // MARK: - Count guard (batch: structuralbiology/biochemistrylab/clinicalneurology/dermatologyrotation/psychiatryrotation)
    @Test func catalogHasAtLeastSevenHundredFortyOneTemplates() {
        #expect(SuggestedSessionTemplates.all.count >= 741,
                "catalog should have ≥741 templates after structuralbiology/biochemistrylab/clinicalneurology/dermatologyrotation/psychiatryrotation additions (10 templates)")
    }

    // MARK: - surgeryrotation templates
    @Test func catalogHasSurgeryRotationTemplates() {
        let tasks = SuggestedSessionTemplates.all.map(\.task)
        let hasRotation = tasks.contains {
            $0.localizedCaseInsensitiveContains("surgery") &&
            ($0.localizedCaseInsensitiveContains("rotation") || $0.localizedCaseInsensitiveContains("operative") || $0.localizedCaseInsensitiveContains("clerkship"))
        }
        let hasStudy = tasks.contains {
            $0.localizedCaseInsensitiveContains("surgery") &&
            ($0.localizedCaseInsensitiveContains("shelf") || $0.localizedCaseInsensitiveContains("study") || $0.localizedCaseInsensitiveContains("exam"))
        }
        #expect(hasRotation, "catalog must include a surgery rotation template")
        #expect(hasStudy, "catalog must include a surgery study template")
    }

    // MARK: - pediatricsrotation templates
    @Test func catalogHasPediatricsRotationTemplates() {
        let tasks = SuggestedSessionTemplates.all.map(\.task)
        let hasRotation = tasks.contains {
            $0.localizedCaseInsensitiveContains("pediatric") &&
            ($0.localizedCaseInsensitiveContains("rotation") || $0.localizedCaseInsensitiveContains("peds") || $0.localizedCaseInsensitiveContains("milestone"))
        }
        let hasStudy = tasks.contains {
            $0.localizedCaseInsensitiveContains("pediatric") &&
            ($0.localizedCaseInsensitiveContains("shelf") || $0.localizedCaseInsensitiveContains("study") || $0.localizedCaseInsensitiveContains("exam"))
        }
        #expect(hasRotation, "catalog must include a pediatrics rotation template")
        #expect(hasStudy, "catalog must include a pediatrics study template")
    }

    // MARK: - internalmedicine templates
    @Test func catalogHasInternalMedicineTemplates() {
        let tasks = SuggestedSessionTemplates.all.map(\.task)
        let hasRotation = tasks.contains {
            $0.localizedCaseInsensitiveContains("internal medicine") &&
            ($0.localizedCaseInsensitiveContains("rotation") || $0.localizedCaseInsensitiveContains("H&P") || $0.localizedCaseInsensitiveContains("SOAP"))
        }
        let hasStudy = tasks.contains {
            $0.localizedCaseInsensitiveContains("internal medicine") &&
            ($0.localizedCaseInsensitiveContains("shelf") || $0.localizedCaseInsensitiveContains("study") || $0.localizedCaseInsensitiveContains("exam"))
        }
        #expect(hasRotation, "catalog must include an internal medicine rotation template")
        #expect(hasStudy, "catalog must include an internal medicine study template")
    }

    // MARK: - obgynrotation templates
    @Test func catalogHasObGynRotationTemplates() {
        let tasks = SuggestedSessionTemplates.all.map(\.task)
        let hasRotation = tasks.contains {
            ($0.localizedCaseInsensitiveContains("OB/GYN") || $0.localizedCaseInsensitiveContains("obstetric") || $0.localizedCaseInsensitiveContains("gynecol")) &&
            ($0.localizedCaseInsensitiveContains("rotation") || $0.localizedCaseInsensitiveContains("labor") || $0.localizedCaseInsensitiveContains("delivery"))
        }
        let hasStudy = tasks.contains {
            ($0.localizedCaseInsensitiveContains("OB/GYN") || $0.localizedCaseInsensitiveContains("obstetric") || $0.localizedCaseInsensitiveContains("gynecol")) &&
            ($0.localizedCaseInsensitiveContains("shelf") || $0.localizedCaseInsensitiveContains("study") || $0.localizedCaseInsensitiveContains("exam"))
        }
        #expect(hasRotation, "catalog must include an OB/GYN rotation template")
        #expect(hasStudy, "catalog must include an OB/GYN study template")
    }

    // MARK: - familymedicine templates
    @Test func catalogHasFamilyMedicineTemplates() {
        let tasks = SuggestedSessionTemplates.all.map(\.task)
        let hasRotation = tasks.contains {
            $0.localizedCaseInsensitiveContains("family medicine") &&
            ($0.localizedCaseInsensitiveContains("rotation") || $0.localizedCaseInsensitiveContains("clinic") || $0.localizedCaseInsensitiveContains("continuity"))
        }
        let hasStudy = tasks.contains {
            $0.localizedCaseInsensitiveContains("family medicine") &&
            ($0.localizedCaseInsensitiveContains("shelf") || $0.localizedCaseInsensitiveContains("study") || $0.localizedCaseInsensitiveContains("exam"))
        }
        #expect(hasRotation, "catalog must include a family medicine rotation template")
        #expect(hasStudy, "catalog must include a family medicine study template")
    }

    // MARK: - Count guard (batch: surgeryrotation/pediatricsrotation/internalmedicine/obgynrotation/familymedicine)
    @Test func catalogHasAtLeastSevenHundredFiftyOneTemplates() {
        #expect(SuggestedSessionTemplates.all.count >= 751,
                "catalog should have ≥751 templates after surgeryrotation/pediatricsrotation/internalmedicine/obgynrotation/familymedicine additions (10 templates)")
    }

    // MARK: - emergencymedicinerotation templates
    @Test func catalogHasEmergencyMedicineRotationTemplates() {
        let tasks = SuggestedSessionTemplates.all.map(\.task)
        let hasRotation = tasks.contains {
            $0.localizedCaseInsensitiveContains("emergency medicine") &&
            ($0.localizedCaseInsensitiveContains("rotation") || $0.localizedCaseInsensitiveContains("shift") || $0.localizedCaseInsensitiveContains("EM"))
        }
        let hasStudy = tasks.contains {
            $0.localizedCaseInsensitiveContains("emergency medicine") &&
            ($0.localizedCaseInsensitiveContains("shelf") || $0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("study"))
        }
        #expect(hasRotation, "catalog must include an emergency medicine rotation template")
        #expect(hasStudy, "catalog must include an emergency medicine study template")
    }

    // MARK: - virology templates
    @Test func catalogHasVirologyTemplates() {
        let tasks = SuggestedSessionTemplates.all.map(\.task)
        let hasLab = tasks.contains {
            $0.localizedCaseInsensitiveContains("virology") &&
            ($0.localizedCaseInsensitiveContains("lab") || $0.localizedCaseInsensitiveContains("assignment") || $0.localizedCaseInsensitiveContains("replication"))
        }
        let hasStudy = tasks.contains {
            $0.localizedCaseInsensitiveContains("virology") &&
            ($0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("study") || $0.localizedCaseInsensitiveContains("review"))
        }
        #expect(hasLab, "catalog must include a virology lab/assignment template")
        #expect(hasStudy, "catalog must include a virology study template")
    }

    // MARK: - clinicalmicrobiology templates
    @Test func catalogHasClinicalMicrobiologyTemplates() {
        let tasks = SuggestedSessionTemplates.all.map(\.task)
        let hasLab = tasks.contains {
            $0.localizedCaseInsensitiveContains("clinical microbiology") &&
            ($0.localizedCaseInsensitiveContains("lab") || $0.localizedCaseInsensitiveContains("culture") || $0.localizedCaseInsensitiveContains("antibiogram"))
        }
        let hasStudy = tasks.contains {
            $0.localizedCaseInsensitiveContains("clinical microbiology") &&
            ($0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("study") || $0.localizedCaseInsensitiveContains("review"))
        }
        #expect(hasLab, "catalog must include a clinical microbiology lab template")
        #expect(hasStudy, "catalog must include a clinical microbiology study template")
    }

    // MARK: - medicinalchemistry templates
    @Test func catalogHasMedicinalChemistryTemplates() {
        let tasks = SuggestedSessionTemplates.all.map(\.task)
        let hasAssignment = tasks.contains {
            $0.localizedCaseInsensitiveContains("medicinal chemistry") &&
            ($0.localizedCaseInsensitiveContains("assignment") || $0.localizedCaseInsensitiveContains("SAR") || $0.localizedCaseInsensitiveContains("drug design"))
        }
        let hasStudy = tasks.contains {
            $0.localizedCaseInsensitiveContains("medicinal chemistry") &&
            ($0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("study") || $0.localizedCaseInsensitiveContains("review"))
        }
        #expect(hasAssignment, "catalog must include a medicinal chemistry assignment template")
        #expect(hasStudy, "catalog must include a medicinal chemistry study template")
    }

    // MARK: - cellandmolecularbiology templates
    @Test func catalogHasCellBiologyTemplates() {
        let tasks = SuggestedSessionTemplates.all.map(\.task)
        let hasLab = tasks.contains {
            $0.localizedCaseInsensitiveContains("cell biology") &&
            ($0.localizedCaseInsensitiveContains("lab") || $0.localizedCaseInsensitiveContains("assignment") || $0.localizedCaseInsensitiveContains("division"))
        }
        let hasStudy = tasks.contains {
            $0.localizedCaseInsensitiveContains("cell biology") &&
            ($0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("study") || $0.localizedCaseInsensitiveContains("review"))
        }
        #expect(hasLab, "catalog must include a cell biology lab/assignment template")
        #expect(hasStudy, "catalog must include a cell biology study template")
    }

    // MARK: - Count guard (batch: emergencymedicinerotation/virology/clinicalmicrobiology/medicinalchemistry/cellandmolecularbiology)
    @Test func catalogHasAtLeastSevenHundredSixtyOneTemplates() {
        #expect(SuggestedSessionTemplates.all.count >= 761,
                "catalog should have ≥761 templates after emergencymedicinerotation/virology/clinicalmicrobiology/medicinalchemistry/cellandmolecularbiology additions (10 templates)")
    }

    // MARK: - biochemistry2 templates
    @Test func catalogHasBiochemistry2Templates() {
        let tasks = SuggestedSessionTemplates.all.map(\.task)
        let hasProblemSet = tasks.contains {
            $0.localizedCaseInsensitiveContains("advanced biochemistry") &&
            ($0.localizedCaseInsensitiveContains("signal transduction") || $0.localizedCaseInsensitiveContains("lipid metabolism") || $0.localizedCaseInsensitiveContains("nucleotide"))
        }
        let hasStudy = tasks.contains {
            $0.localizedCaseInsensitiveContains("advanced biochemistry") &&
            ($0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("study") || $0.localizedCaseInsensitiveContains("review"))
        }
        #expect(hasProblemSet, "catalog must include an advanced biochemistry problem-set template")
        #expect(hasStudy, "catalog must include an advanced biochemistry study template")
    }

    // MARK: - physicalchemistrylab templates
    @Test func catalogHasPhysicalchemistryLabTemplates() {
        let tasks = SuggestedSessionTemplates.all.map(\.task)
        let hasLab = tasks.contains {
            $0.localizedCaseInsensitiveContains("physical chemistry lab") &&
            ($0.localizedCaseInsensitiveContains("report") || $0.localizedCaseInsensitiveContains("calorimetry") || $0.localizedCaseInsensitiveContains("spectroscopy"))
        }
        let hasPrep = tasks.contains {
            $0.localizedCaseInsensitiveContains("physical chemistry lab") &&
            ($0.localizedCaseInsensitiveContains("prepare") || $0.localizedCaseInsensitiveContains("pre-lab") || $0.localizedCaseInsensitiveContains("review"))
        }
        #expect(hasLab, "catalog must include a physical chemistry lab report template")
        #expect(hasPrep, "catalog must include a physical chemistry lab prep template")
    }

    // MARK: - organicchemistrylab templates
    @Test func catalogHasOrganicchemistryLabTemplates() {
        let tasks = SuggestedSessionTemplates.all.map(\.task)
        let hasReport = tasks.contains {
            $0.localizedCaseInsensitiveContains("organic chemistry lab") &&
            ($0.localizedCaseInsensitiveContains("report") || $0.localizedCaseInsensitiveContains("distillation") || $0.localizedCaseInsensitiveContains("recrystallization"))
        }
        let hasPrep = tasks.contains {
            $0.localizedCaseInsensitiveContains("organic chemistry lab") &&
            ($0.localizedCaseInsensitiveContains("prepare") || $0.localizedCaseInsensitiveContains("pre-lab") || $0.localizedCaseInsensitiveContains("review"))
        }
        #expect(hasReport, "catalog must include an organic chemistry lab report template")
        #expect(hasPrep, "catalog must include an organic chemistry lab prep template")
    }

    // MARK: - immunologycourse templates
    @Test func catalogHasImmunologycourseTemplates() {
        let tasks = SuggestedSessionTemplates.all.map(\.task)
        let hasStudy = tasks.contains {
            $0.localizedCaseInsensitiveContains("advanced immunology") &&
            ($0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("study") || $0.localizedCaseInsensitiveContains("review"))
        }
        let hasAssignment = tasks.contains {
            $0.localizedCaseInsensitiveContains("immunology") &&
            ($0.localizedCaseInsensitiveContains("T-reg") || $0.localizedCaseInsensitiveContains("complement") || $0.localizedCaseInsensitiveContains("checkpoint"))
        }
        #expect(hasStudy, "catalog must include an advanced immunology study template")
        #expect(hasAssignment, "catalog must include an advanced immunology assignment template")
    }

    // MARK: - neurobiologylab templates
    @Test func catalogHasNeurobiologylabTemplates() {
        let tasks = SuggestedSessionTemplates.all.map(\.task)
        let hasReport = tasks.contains {
            $0.localizedCaseInsensitiveContains("neurobiology lab") &&
            ($0.localizedCaseInsensitiveContains("report") || $0.localizedCaseInsensitiveContains("patch clamp") || $0.localizedCaseInsensitiveContains("neural tracing"))
        }
        let hasPrep = tasks.contains {
            $0.localizedCaseInsensitiveContains("neurobiology lab") &&
            ($0.localizedCaseInsensitiveContains("prepare") || $0.localizedCaseInsensitiveContains("pre-lab") || $0.localizedCaseInsensitiveContains("review"))
        }
        #expect(hasReport, "catalog must include a neurobiology lab report template")
        #expect(hasPrep, "catalog must include a neurobiology lab prep template")
    }

    // MARK: - Count guard (batch: biochemistry2/physicalchemistrylab/organicchemistrylab/immunologycourse/neurobiologylab)
    @Test func catalogHasAtLeastSevenHundredSeventyOneTemplates() {
        #expect(SuggestedSessionTemplates.all.count >= 771,
                "catalog should have ≥771 templates after biochemistry2/physicalchemistrylab/organicchemistrylab/immunologycourse/neurobiologylab additions (10 templates)")
    }

    // MARK: - astronomylab templates
    @Test func catalogHasAstronomylabTemplates() {
        let tasks = SuggestedSessionTemplates.all.map(\.task)
        let hasLab = tasks.contains {
            $0.localizedCaseInsensitiveContains("astronomy") &&
            ($0.localizedCaseInsensitiveContains("star chart") || $0.localizedCaseInsensitiveContains("telescope") || $0.localizedCaseInsensitiveContains("light curve") || $0.localizedCaseInsensitiveContains("observational"))
        }
        let hasPrep = tasks.contains {
            $0.localizedCaseInsensitiveContains("astronomy") &&
            ($0.localizedCaseInsensitiveContains("prepare") || $0.localizedCaseInsensitiveContains("observing session") || $0.localizedCaseInsensitiveContains("pre-lab"))
        }
        #expect(hasLab, "catalog must include an astronomy observational lab template")
        #expect(hasPrep, "catalog must include an astronomy lab prep template")
    }

    // MARK: - geologylab templates
    @Test func catalogHasGeologylabTemplates() {
        let tasks = SuggestedSessionTemplates.all.map(\.task)
        let hasLab = tasks.contains {
            $0.localizedCaseInsensitiveContains("geology lab") &&
            ($0.localizedCaseInsensitiveContains("rock") || $0.localizedCaseInsensitiveContains("mineral") || $0.localizedCaseInsensitiveContains("thin section"))
        }
        let hasPrep = tasks.contains {
            $0.localizedCaseInsensitiveContains("geology lab") &&
            ($0.localizedCaseInsensitiveContains("prepare") || $0.localizedCaseInsensitiveContains("pre-lab") || $0.localizedCaseInsensitiveContains("review"))
        }
        #expect(hasLab, "catalog must include a geology lab report template")
        #expect(hasPrep, "catalog must include a geology lab prep template")
    }

    // MARK: - environmentalscience templates
    @Test func catalogHasEnvironmentalscienceTemplates() {
        let tasks = SuggestedSessionTemplates.all.map(\.task)
        let hasAssignment = tasks.contains {
            $0.localizedCaseInsensitiveContains("environmental science") &&
            ($0.localizedCaseInsensitiveContains("assignment") || $0.localizedCaseInsensitiveContains("biogeochemical") || $0.localizedCaseInsensitiveContains("lab"))
        }
        let hasStudy = tasks.contains {
            $0.localizedCaseInsensitiveContains("environmental science") &&
            ($0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("study") || $0.localizedCaseInsensitiveContains("review"))
        }
        #expect(hasAssignment, "catalog must include an environmental science assignment template")
        #expect(hasStudy, "catalog must include an environmental science study template")
    }

    // MARK: - anthropology templates
    @Test func catalogHasAnthropologyTemplates() {
        let tasks = SuggestedSessionTemplates.all.map(\.task)
        let hasPaper = tasks.contains {
            $0.localizedCaseInsensitiveContains("anthropology") &&
            ($0.localizedCaseInsensitiveContains("paper") || $0.localizedCaseInsensitiveContains("ethnography") || $0.localizedCaseInsensitiveContains("write"))
        }
        let hasStudy = tasks.contains {
            $0.localizedCaseInsensitiveContains("anthropology") &&
            ($0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("study") || $0.localizedCaseInsensitiveContains("review"))
        }
        #expect(hasPaper, "catalog must include an anthropology paper/ethnography template")
        #expect(hasStudy, "catalog must include an anthropology study template")
    }

    // MARK: - sociology templates
    @Test func catalogHasSociologyTemplates() {
        let tasks = SuggestedSessionTemplates.all.map(\.task)
        let hasPaper = tasks.contains {
            $0.localizedCaseInsensitiveContains("sociology") &&
            ($0.localizedCaseInsensitiveContains("paper") || $0.localizedCaseInsensitiveContains("theory") || $0.localizedCaseInsensitiveContains("write"))
        }
        let hasStudy = tasks.contains {
            $0.localizedCaseInsensitiveContains("sociology") &&
            ($0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("study") || $0.localizedCaseInsensitiveContains("review"))
        }
        #expect(hasPaper, "catalog must include a sociology paper/analysis template")
        #expect(hasStudy, "catalog must include a sociology study template")
    }

    // MARK: - Count guard (batch: astronomylab/geologylab/environmentalscience/anthropology/sociology)
    @Test func catalogHasAtLeastSevenHundredEightyOneTemplates() {
        #expect(SuggestedSessionTemplates.all.count >= 781,
                "catalog should have ≥781 templates after astronomylab/geologylab/environmentalscience/anthropology/sociology additions (10 templates)")
    }

    // MARK: - biostatistics templates
    @Test func catalogHasBiostatisticsTemplates() {
        let tasks = SuggestedSessionTemplates.all.map(\.task)
        let hasProblemSet = tasks.contains {
            $0.localizedCaseInsensitiveContains("biostatistics") &&
            ($0.localizedCaseInsensitiveContains("problem set") || $0.localizedCaseInsensitiveContains("survival") || $0.localizedCaseInsensitiveContains("Kaplan"))
        }
        let hasStudy = tasks.contains {
            $0.localizedCaseInsensitiveContains("biostatistics") &&
            ($0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("study") || $0.localizedCaseInsensitiveContains("review"))
        }
        #expect(hasProblemSet, "catalog must include a biostatistics problem set template")
        #expect(hasStudy, "catalog must include a biostatistics study template")
    }

    // MARK: - marinebiology2 templates
    @Test func catalogHasMarinebiology2Templates() {
        let tasks = SuggestedSessionTemplates.all.map(\.task)
        let hasLab = tasks.contains {
            $0.localizedCaseInsensitiveContains("marine biology") &&
            ($0.localizedCaseInsensitiveContains("lab") || $0.localizedCaseInsensitiveContains("plankton") || $0.localizedCaseInsensitiveContains("tidepool"))
        }
        let hasPrep = tasks.contains {
            $0.localizedCaseInsensitiveContains("marine biology") &&
            ($0.localizedCaseInsensitiveContains("prepare") || $0.localizedCaseInsensitiveContains("pre-lab") || $0.localizedCaseInsensitiveContains("review"))
        }
        #expect(hasLab, "catalog must include a marine biology lab work template")
        #expect(hasPrep, "catalog must include a marine biology lab prep template")
    }

    // MARK: - moleculargeneticslab templates
    @Test func catalogHasMoleculargeneticslabTemplates() {
        let tasks = SuggestedSessionTemplates.all.map(\.task)
        let hasLab = tasks.contains {
            $0.localizedCaseInsensitiveContains("molecular genetics") &&
            ($0.localizedCaseInsensitiveContains("lab") || $0.localizedCaseInsensitiveContains("restriction") || $0.localizedCaseInsensitiveContains("karyotype"))
        }
        let hasPrep = tasks.contains {
            $0.localizedCaseInsensitiveContains("molecular genetics") &&
            ($0.localizedCaseInsensitiveContains("prepare") || $0.localizedCaseInsensitiveContains("pre-lab") || $0.localizedCaseInsensitiveContains("review"))
        }
        #expect(hasLab, "catalog must include a molecular genetics lab work template")
        #expect(hasPrep, "catalog must include a molecular genetics lab prep template")
    }

    // MARK: - evolutionarybiology templates
    @Test func catalogHasEvolutionarybiologyTemplates() {
        let tasks = SuggestedSessionTemplates.all.map(\.task)
        let hasStudy = tasks.contains {
            $0.localizedCaseInsensitiveContains("evolutionary biology") &&
            ($0.localizedCaseInsensitiveContains("exam") || $0.localizedCaseInsensitiveContains("study") || $0.localizedCaseInsensitiveContains("review"))
        }
        let hasAssignment = tasks.contains {
            $0.localizedCaseInsensitiveContains("evolutionary biology") &&
            ($0.localizedCaseInsensitiveContains("assignment") || $0.localizedCaseInsensitiveContains("phylogenetic") || $0.localizedCaseInsensitiveContains("problem set"))
        }
        #expect(hasStudy, "catalog must include an evolutionary biology study template")
        #expect(hasAssignment, "catalog must include an evolutionary biology assignment template")
    }

    // MARK: - biochemistry3 templates
    @Test func catalogHasBiochemistry3Templates() {
        let tasks = SuggestedSessionTemplates.all.map(\.task)
        let hasStudy = tasks.contains {
            $0.localizedCaseInsensitiveContains("biochemistry") &&
            ($0.localizedCaseInsensitiveContains("cofactor") || $0.localizedCaseInsensitiveContains("coenzyme") || $0.localizedCaseInsensitiveContains("heme"))
        }
        let hasProblemSet = tasks.contains {
            $0.localizedCaseInsensitiveContains("biochemistry") &&
            ($0.localizedCaseInsensitiveContains("cofactor") || $0.localizedCaseInsensitiveContains("porphyrin") || $0.localizedCaseInsensitiveContains("bile acid"))
        }
        #expect(hasStudy, "catalog must include a biochemistry cofactor/coenzyme study template")
        #expect(hasProblemSet, "catalog must include a biochemistry3 problem set template")
    }

    // MARK: - Count guard (batch: biostatistics/marinebiology2/moleculargeneticslab/evolutionarybiology/biochemistry3)
    @Test func catalogHasAtLeastSevenHundredNinetyOneTemplates() {
        #expect(SuggestedSessionTemplates.all.count >= 791,
                "catalog should have ≥791 templates after biostatistics/marinebiology2/moleculargeneticslab/evolutionarybiology/biochemistry3 additions (10 templates)")
    }

    // MARK: - atmosphericscience templates
    @Test func atmosphericscienceStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("atmospheric science") && $0.task.lowercased().contains("exam") })
    }
    @Test func atmosphericscienceAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("meteorology") && $0.task.lowercased().contains("assignment") || $0.task.lowercased().contains("atmospheric science") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - ecologicalfieldwork templates
    @Test func ecologicalfieldworkAnalysisTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("transect") && $0.task.lowercased().contains("ecology") })
    }
    @Test func ecologicalfieldworkPrepTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("quadrat") && $0.task.lowercased().contains("ecology") })
    }
    // MARK: - quantummechanics templates
    @Test func quantummechanicsProblemSetTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("quantum mechanics") && $0.task.lowercased().contains("problem set") })
    }
    @Test func quantummechanicsStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("quantum mechanics") && $0.task.lowercased().contains("exam") })
    }
    // MARK: - solidstatephysics templates
    @Test func solidstatephysicsStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("solid state physics") && $0.task.lowercased().contains("exam") })
    }
    @Test func solidstatephysicsProblemSetTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("condensed matter") || $0.task.lowercased().contains("solid state physics") && $0.task.lowercased().contains("problem set") })
    }
    // MARK: - classicalmechanics templates
    @Test func classicalmechanicsProblemSetTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("classical mechanics") && $0.task.lowercased().contains("problem set") })
    }
    @Test func classicalmechanicsStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("classical mechanics") && $0.task.lowercased().contains("exam") })
    }
    // MARK: - astrophysics templates
    @Test func astrophysicsProblemSetTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("astrophysics") && $0.task.lowercased().contains("problem set") })
    }
    @Test func astrophysicsStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("astrophysics") && $0.task.lowercased().contains("exam") })
    }
    // MARK: - atmosphericchemistry templates
    @Test func atmosphericChemistryAnalysisTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("atmospheric chemistry") && $0.task.lowercased().contains("ozone") })
    }
    @Test func atmosphericChemistryProblemSetTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("atmospheric chemistry") && $0.task.lowercased().contains("problem set") })
    }
    // MARK: - optics templates
    @Test func opticsProblemSetTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("optics") && $0.task.lowercased().contains("problem set") })
    }
    @Test func opticsStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("optics") && $0.task.lowercased().contains("exam") })
    }
    // MARK: - electromagnetism templates
    @Test func electromagnetismProblemSetTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("electromagnetism") && $0.task.lowercased().contains("problem set") })
    }
    @Test func electromagnetismStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("electromagnetism") && $0.task.lowercased().contains("exam") })
    }
    // MARK: - neuroimaging templates
    @Test func neuroimagingPipelineTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("neuroimaging") && $0.task.lowercased().contains("fsl") })
    }
    @Test func neuroimagingAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("neuroimaging") && $0.task.lowercased().contains("bold") })
    }
    // MARK: - geophysics templates
    @Test func geophysicsProblemSetTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("geophysics") && $0.task.lowercased().contains("problem set") })
    }
    @Test func geophysicsStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("geophysics") && $0.task.lowercased().contains("exam") })
    }
    // MARK: - mineralogy templates
    @Test func mineralogyStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("mineralogy") && $0.task.lowercased().contains("exam") })
    }
    @Test func mineralogyLabTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("mineralogy") && $0.task.lowercased().contains("lab") })
    }
    // MARK: - petrology templates
    @Test func petrologyStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("petrology") && $0.task.lowercased().contains("exam") })
    }
    @Test func petrologyAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("petrology") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - hydrogeology templates
    @Test func hydrogeologyProblemSetTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("hydrogeology") && $0.task.lowercased().contains("problem set") })
    }
    @Test func hydrogeologyStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("hydrogeology") && $0.task.lowercased().contains("exam") })
    }
    // MARK: - stratigraphy templates
    @Test func stratigraphyStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("stratigraphy") && $0.task.lowercased().contains("exam") })
    }
    @Test func stratigraphyAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("stratigraphy") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - systemsbiology templates
    @Test func systemsbiologyModelingTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("systems biology") && $0.task.lowercased().contains("flux balance") })
    }
    @Test func systemsbiologyStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("systems biology") && $0.task.lowercased().contains("exam") })
    }
    // MARK: - microbiologylab templates
    @Test func microbiologylabPracticalTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("microbiology") && $0.task.lowercased().contains("disk diffusion") })
    }
    @Test func microbiologylabStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("microbiology") && $0.task.lowercased().contains("lab practical") })
    }
    // MARK: - ecophysiology templates
    @Test func ecophysiologyStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("ecophysiology") && $0.task.lowercased().contains("exam") })
    }
    @Test func ecophysiologyAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("ecophysiology") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - plantphysiology templates
    @Test func plantphysiologyStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("plant physiology") && $0.task.lowercased().contains("exam") })
    }
    @Test func plantphysiologyAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("plant physiology") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - animalphysiology templates
    @Test func animalphysiologyStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("animal physiology") && $0.task.lowercased().contains("exam") })
    }
    @Test func animalphysiologyAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("animal physiology") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - Count guard (≥831)
    @Test func templateCountAtLeast831() {
        #expect(SuggestedSessionTemplates.all.count >= 831, "template catalog must have ≥831 entries after systemsbiology/microbiologylab/ecophysiology/plantphysiology/animalphysiology additions")
    }
    // MARK: - cellsignaling templates
    @Test func cellsignalingStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("cell signaling") && $0.task.lowercased().contains("exam") })
    }
    @Test func cellsignalingAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("cell signaling") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - humangeneticsclass templates
    @Test func humangeneticsclassStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("human genetics") && $0.task.lowercased().contains("exam") })
    }
    @Test func humangeneticsclassAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("human genetics") && $0.task.lowercased().contains("problem set") })
    }
    // MARK: - immunogenetics templates
    @Test func immunogeneticsStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("immunogenetics") && $0.task.lowercased().contains("exam") })
    }
    @Test func immunogeneticsAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("immunogenetics") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - neurologylab templates
    @Test func neurologylabPracticalTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("neurology lab") && $0.task.lowercased().contains("eeg") })
    }
    @Test func neurologylabStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("neurology lab") && $0.task.lowercased().contains("practical") })
    }
    // MARK: - socialpsychology templates
    @Test func socialpsychologyStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("social psychology") && $0.task.lowercased().contains("exam") })
    }
    @Test func socialpsychologyAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("social psychology") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - Count guard (≥841)
    @Test func templateCountAtLeast841() {
        #expect(SuggestedSessionTemplates.all.count >= 841, "template catalog must have ≥841 entries after cellsignaling/humangeneticsclass/immunogenetics/neurologylab/socialpsychology additions")
    }
    // MARK: - geriatricrotation templates
    @Test func geriatricrotationClinicalTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("geriatric rotation") && $0.task.lowercased().contains("cga") })
    }
    @Test func geriatricrotationStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("geriatric rotation") && $0.task.lowercased().contains("frailty") })
    }
    // MARK: - neurochemistry templates
    @Test func neurochemistryStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("neurochemistry") && $0.task.lowercased().contains("exam") })
    }
    @Test func neurochemistryAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("neurochemistry") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - psychobiologyclass templates
    @Test func psychobiologyclassStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("biopsychology") && $0.task.lowercased().contains("exam") })
    }
    @Test func psychobiologyclassAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("biological psychology") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - abnormalpsychology templates
    @Test func abnormalpsychologyStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("abnormal psychology") && $0.task.lowercased().contains("exam") })
    }
    @Test func abnormalpsychologyAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("abnormal psychology") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - healthpsychology templates
    @Test func healthpsychologyStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("health psychology") && $0.task.lowercased().contains("exam") })
    }
    @Test func healthpsychologyAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("health psychology") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - Count guard (≥851)
    @Test func templateCountAtLeast851() {
        #expect(SuggestedSessionTemplates.all.count >= 851, "template catalog must have ≥851 entries after geriatricrotation/neurochemistry/psychobiologyclass/abnormalpsychology/healthpsychology additions")
    }
    // MARK: - linearalgebra templates
    @Test func linearalgebraStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("linear algebra") && $0.task.lowercased().contains("exam") })
    }
    @Test func linearalgebraAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("linear algebra") && $0.task.lowercased().contains("problem set") })
    }
    // MARK: - differentialequations templates
    @Test func differentialequationsStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("differential equations") && $0.task.lowercased().contains("exam") })
    }
    @Test func differentialequationsAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("differential equations") && $0.task.lowercased().contains("problem set") })
    }
    // MARK: - neuropsychology templates
    @Test func neuropsychologyStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("neuropsychology") && $0.task.lowercased().contains("exam") })
    }
    @Test func neuropsychologyAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("neuropsychology") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - developmentalpsych templates
    @Test func developmentalpsychStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("developmental psychology") && $0.task.lowercased().contains("exam") })
    }
    @Test func developmentalpsychAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("developmental psychology") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - militarymedicine templates
    @Test func militarymedicineStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("tccc") && $0.task.lowercased().contains("march") })
    }
    @Test func militarymedicineAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("combat medicine") && $0.task.lowercased().contains("tccc") })
    }
    // MARK: - Count guard (≥861)
    @Test func templateCountAtLeast861() {
        #expect(SuggestedSessionTemplates.all.count >= 861, "template catalog must have ≥861 entries after linearalgebra/differentialequations/neuropsychology/developmentalpsych/militarymedicine additions")
    }
    // MARK: - complexanalysis templates
    @Test func complexanalysisStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("complex analysis") && $0.task.lowercased().contains("exam") })
    }
    @Test func complexanalysisAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("complex analysis") && $0.task.lowercased().contains("problem set") })
    }
    // MARK: - realanalysis templates
    @Test func realanalysisStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("real analysis") && $0.task.lowercased().contains("exam") })
    }
    @Test func realanalysisAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("real analysis") && $0.task.lowercased().contains("problem set") })
    }
    // MARK: - discretemath templates
    @Test func discretemathStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("discrete math") && $0.task.lowercased().contains("exam") })
    }
    @Test func discretemathAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("discrete math") && $0.task.lowercased().contains("problem set") })
    }
    // MARK: - probabilitytheory templates
    @Test func probabilitytheoryStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("probability theory") && $0.task.lowercased().contains("exam") })
    }
    @Test func probabilitytheoryAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("probability theory") && $0.task.lowercased().contains("problem set") })
    }
    // MARK: - numericalanalysis templates
    @Test func numericalanalysisStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("numerical analysis") && $0.task.lowercased().contains("exam") })
    }
    @Test func numericalanalysisAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("numerical analysis") && $0.task.lowercased().contains("problem set") })
    }
    // MARK: - Count guard (≥871)
    @Test func templateCountAtLeast871() {
        #expect(SuggestedSessionTemplates.all.count >= 871, "template catalog must have ≥871 entries after complexanalysis/realanalysis/discretemath/probabilitytheory/numericalanalysis additions")
    }
    // MARK: - statisticalmethods templates
    @Test func statisticalmethodsStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("applied statistics") && $0.task.lowercased().contains("exam") })
    }
    @Test func statisticalmethodsAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("statistical methods") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - topology templates
    @Test func topologyStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("topology") && $0.task.lowercased().contains("exam") })
    }
    @Test func topologyAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("topology") && $0.task.lowercased().contains("problem set") })
    }
    // MARK: - abstractalgebra templates
    @Test func abstractalgebraStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("abstract algebra") && $0.task.lowercased().contains("exam") })
    }
    @Test func abstractalgebraAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("abstract algebra") && $0.task.lowercased().contains("problem set") })
    }
    // MARK: - seismology templates
    @Test func seismologyStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("seismology") && $0.task.lowercased().contains("exam") })
    }
    @Test func seismologyAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("seismology") && $0.task.lowercased().contains("problem set") })
    }
    // MARK: - volcanology templates
    @Test func volcanologyStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("volcanology") && $0.task.lowercased().contains("exam") })
    }
    @Test func volcanologyAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("volcanology") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - Count guard (≥881)
    @Test func templateCountAtLeast881() {
        #expect(SuggestedSessionTemplates.all.count >= 881, "template catalog must have ≥881 entries after statisticalmethods/topology/abstractalgebra/seismology/volcanology additions")
    }
    // MARK: - geomorphology templates
    @Test func geomorphologyStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("geomorphology") && $0.task.lowercased().contains("exam") })
    }
    @Test func geomorphologyAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("geomorphology") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - sedimentology templates
    @Test func sedimentologyStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("sedimentology") && $0.task.lowercased().contains("exam") })
    }
    @Test func sedimentologyAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("sedimentology") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - structuralgeology templates
    @Test func structuralGeologyStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("structural geology") && $0.task.lowercased().contains("exam") })
    }
    @Test func structuralGeologyProblemSetTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("structural geology") && $0.task.lowercased().contains("problem set") })
    }
    // MARK: - functionalanalysis templates
    @Test func functionalAnalysisStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("functional analysis") && $0.task.lowercased().contains("exam") })
    }
    @Test func functionalAnalysisProblemSetTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("functional analysis") && $0.task.lowercased().contains("problem set") })
    }
    // MARK: - differentialgeometry templates
    @Test func differentialGeometryStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("differential geometry") && $0.task.lowercased().contains("exam") })
    }
    @Test func differentialGeometryProblemSetTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("differential geometry") && $0.task.lowercased().contains("problem set") })
    }
    // MARK: - Count guard (≥891)
    @Test func templateCountAtLeast891() {
        #expect(SuggestedSessionTemplates.all.count >= 891, "template catalog must have ≥891 entries after geomorphology/sedimentology/structuralgeology/functionalanalysis/differentialgeometry additions")
    }
    // MARK: - cosmology templates
    @Test func cosmologyStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("cosmology") && $0.task.lowercased().contains("exam") })
    }
    @Test func cosmologyProblemSetTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("cosmology") && $0.task.lowercased().contains("problem set") })
    }
    // MARK: - planetaryscience templates
    @Test func planetaryScienceStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("planetary science") && $0.task.lowercased().contains("exam") })
    }
    @Test func planetaryScienceAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("planetary science") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - particlephysics templates
    @Test func particlePhysicsStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("particle physics") && $0.task.lowercased().contains("exam") })
    }
    @Test func particlePhysicsProblemSetTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("particle physics") && $0.task.lowercased().contains("problem set") })
    }
    // MARK: - statisticalmechanics templates
    @Test func statisticalMechanicsStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("statistical mechanics") && $0.task.lowercased().contains("exam") })
    }
    @Test func statisticalMechanicsProblemSetTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("statistical mechanics") && $0.task.lowercased().contains("problem set") })
    }
    // MARK: - environmentalchemistry templates
    @Test func environmentalChemistryStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("environmental chemistry") && $0.task.lowercased().contains("exam") })
    }
    @Test func environmentalChemistryAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("environmental chemistry") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - radioastronomy templates
    @Test func radioAstronomyStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("radio astronomy") && $0.task.lowercased().contains("exam") })
    }
    @Test func radioAstronomyAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("radio astronomy") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - astrochemistry templates
    @Test func astrochemistryStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("astrochemistry") && $0.task.lowercased().contains("exam") })
    }
    @Test func astrochemistryAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("astrochemistry") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - nuclearphysics templates
    @Test func nuclearPhysicsStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("nuclear physics") && $0.task.lowercased().contains("exam") })
    }
    @Test func nuclearPhysicsProblemSetTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("nuclear physics") && $0.task.lowercased().contains("problem set") })
    }
    // MARK: - plasmaphysics templates
    @Test func plasmaPhysicsStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("plasma physics") && $0.task.lowercased().contains("exam") })
    }
    @Test func plasmaPhysicsProblemSetTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("plasma physics") && $0.task.lowercased().contains("problem set") })
    }
    // MARK: - computationalfluidynamics templates
    @Test func cfdStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("computational fluid dynamics") && $0.task.lowercased().contains("exam") })
    }
    @Test func cfdAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("cfd") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - Count guard (≥911)
    @Test func templateCountAtLeast911() {
        #expect(SuggestedSessionTemplates.all.count >= 911, "template catalog must have ≥911 entries after radioastronomy/astrochemistry/nuclearphysics/plasmaphysics/computationalfluidynamics additions")
    }
    // MARK: - glaciology templates
    @Test func glaciologyStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("glaciology") && $0.task.lowercased().contains("exam") })
    }
    @Test func glaciologyAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("glaciology") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - hydrology templates
    @Test func hydrologyStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("hydrology") && $0.task.lowercased().contains("exam") })
    }
    @Test func hydrologyAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("hydrology") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - climatology templates
    @Test func climatologyStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("climatology") && $0.task.lowercased().contains("exam") })
    }
    @Test func climatologyAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("climatology") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - photochemistry templates
    @Test func photochemistryStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("photochemistry") && $0.task.lowercased().contains("exam") })
    }
    @Test func photochemistryAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("photochemistry") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - electromagnetictheory templates
    @Test func electromagneticTheoryStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("electromagnetic theory") && $0.task.lowercased().contains("exam") })
    }
    @Test func electromagneticTheoryProblemSetTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("electromagnetic theory") && $0.task.lowercased().contains("problem set") })
    }
    // MARK: - Count guard (≥921)
    @Test func templateCountAtLeast921() {
        #expect(SuggestedSessionTemplates.all.count >= 921, "template catalog must have ≥921 entries after hydrology/oceanography/climatology/photochemistry/electromagnetictheory additions")
    }
    // MARK: - operatingsystems templates
    @Test func operatingSystemsStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("operating systems") && $0.task.lowercased().contains("exam") })
    }
    @Test func operatingSystemsAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("operating systems") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - algorithms templates
    @Test func algorithmsStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("algorithms") && $0.task.lowercased().contains("exam") })
    }
    @Test func algorithmsProblemSetTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("algorithms") && $0.task.lowercased().contains("problem set") })
    }
    // MARK: - databasesystems templates
    @Test func databaseSystemsStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("database systems") && $0.task.lowercased().contains("exam") })
    }
    @Test func databaseSystemsAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("database systems") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - computernetworks templates
    @Test func computerNetworksStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("computer networks") && $0.task.lowercased().contains("exam") })
    }
    @Test func computerNetworksAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("computer networks") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - computervision templates
    @Test func computerVisionStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("computer vision") && $0.task.lowercased().contains("exam") })
    }
    @Test func computerVisionProjectTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("computer vision") && $0.task.lowercased().contains("project") })
    }
    // MARK: - Count guard (≥931)
    @Test func templateCountAtLeast931() {
        #expect(SuggestedSessionTemplates.all.count >= 931, "template catalog must have ≥931 entries after operatingsystems/algorithms/databasesystems/computernetworks/computervision additions")
    }
    // MARK: - softwareengineering templates
    @Test func softwareEngineeringStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("software engineering") && $0.task.lowercased().contains("exam") })
    }
    @Test func softwareEngineeringAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("software engineering") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - humancomputerinteraction templates
    @Test func hciStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("human-computer interaction") && $0.task.lowercased().contains("exam") })
    }
    @Test func hciAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("hci") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - machinelearning templates
    @Test func machineLearningStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("machine learning") && $0.task.lowercased().contains("exam") })
    }
    @Test func machineLearningAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("machine learning") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - distributedsystems templates
    @Test func distributedSystemsStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("distributed systems") && $0.task.lowercased().contains("exam") })
    }
    @Test func distributedSystemsAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("distributed systems") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - computersecurity templates
    @Test func computerSecurityStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("computer security") && $0.task.lowercased().contains("exam") })
    }
    @Test func computerSecurityAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("computer security") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - Count guard (≥941)
    @Test func templateCountAtLeast941() {
        #expect(SuggestedSessionTemplates.all.count >= 941, "template catalog must have ≥941 entries after softwareengineering/humancomputerinteraction/machinelearning/distributedsystems/computersecurity additions")
    }
    // MARK: - programminglanguages templates
    @Test func programmingLanguagesStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("programming languages") && $0.task.lowercased().contains("exam") })
    }
    @Test func programmingLanguagesAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("programming languages") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - compilerdesign templates
    @Test func compilerDesignStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("compiler design") && $0.task.lowercased().contains("exam") })
    }
    @Test func compilerDesignAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("compiler design") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - computergraphics templates
    @Test func computerGraphicsStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("computer graphics") && $0.task.lowercased().contains("exam") })
    }
    @Test func computerGraphicsAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("computer graphics") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - embeddedsystems templates
    @Test func embeddedSystemsStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("embedded systems") && $0.task.lowercased().contains("exam") })
    }
    @Test func embeddedSystemsAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("embedded systems") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - formalverification templates
    @Test func formalVerificationStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("formal verification") && $0.task.lowercased().contains("exam") })
    }
    @Test func formalVerificationAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("formal verification") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - Count guard (≥951)
    @Test func templateCountAtLeast951() {
        #expect(SuggestedSessionTemplates.all.count >= 951, "template catalog must have ≥951 entries after programminglanguages/compilerdesign/computergraphics/embeddedsystems/formalverification additions")
    }
    // MARK: - computationtheory templates
    @Test func computationTheoryStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("theory of computation") && $0.task.lowercased().contains("exam") })
    }
    @Test func computationTheoryAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("theory of computation") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - softwarearchitecture templates
    @Test func softwareArchitectureStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("software architecture") && $0.task.lowercased().contains("exam") })
    }
    @Test func softwareArchitectureAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("software architecture") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - informationretrieval templates
    @Test func informationRetrievalStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("information retrieval") && $0.task.lowercased().contains("exam") })
    }
    @Test func informationRetrievalAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("information retrieval") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - naturallanguageprocessing templates
    @Test func naturalLanguageProcessingStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("natural language processing") && $0.task.lowercased().contains("exam") })
    }
    @Test func naturalLanguageProcessingAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("nlp") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - computerarchitecture templates
    @Test func computerArchitectureStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("computer architecture") && $0.task.lowercased().contains("exam") })
    }
    @Test func computerArchitectureAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("computer architecture") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - Count guard (≥961)
    @Test func templateCountAtLeast961() {
        #expect(SuggestedSessionTemplates.all.count >= 961, "template catalog must have ≥961 entries after computationtheory/softwarearchitecture/informationretrieval/naturallanguageprocessing/computerarchitecture additions")
    }
    // MARK: - photonics templates
    @Test func photonicsStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("photonics") && $0.task.lowercased().contains("exam") })
    }
    @Test func photonicsAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("photonics") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - acousticsengineering templates
    @Test func acousticsStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("acoustics") && $0.task.lowercased().contains("exam") })
    }
    @Test func acousticsAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("acoustics") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - petroleumengineering templates
    @Test func petroleumEngineeringStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("petroleum engineering") && $0.task.lowercased().contains("exam") })
    }
    @Test func petroleumEngineeringAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("petroleum engineering") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - sportspsychology templates
    @Test func sportsPsychologyStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("sports psychology") && $0.task.lowercased().contains("exam") })
    }
    @Test func sportsPsychologyAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("sports psychology") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - limnology templates
    @Test func limnologyStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("limnology") && $0.task.lowercased().contains("exam") })
    }
    @Test func limnologyAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("limnology") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - Count guard (≥971)
    @Test func templateCountAtLeast971() {
        #expect(SuggestedSessionTemplates.all.count >= 971, "template catalog must have ≥971 entries after photonics/acousticsengineering/petroleumengineering/sportspsychology/limnology additions")
    }
    // MARK: - astrodynamics templates
    @Test func astrodynamicsStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("astrodynamics") && $0.task.lowercased().contains("exam") })
    }
    @Test func astrodynamicsAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("astrodynamics") && $0.task.lowercased().contains("problem set") })
    }
    // MARK: - biomaterials templates
    @Test func biomaterialsStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("biomaterials") && $0.task.lowercased().contains("exam") })
    }
    @Test func biomaterialsAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("biomaterials") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - crystallography templates
    @Test func crystallographyStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("crystallography") && $0.task.lowercased().contains("exam") })
    }
    @Test func crystallographyAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("crystallography") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - spectroscopy templates
    @Test func spectroscopyStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("spectroscopy") && $0.task.lowercased().contains("exam") })
    }
    @Test func spectroscopyAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("spectroscopy") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - industrialengineering templates
    @Test func industrialEngineeringStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("industrial engineering") && $0.task.lowercased().contains("exam") })
    }
    @Test func industrialEngineeringAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("industrial engineering") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - Count guard (≥981)
    @Test func templateCountAtLeast981() {
        #expect(SuggestedSessionTemplates.all.count >= 981, "template catalog must have ≥981 entries after astrodynamics/biomaterials/crystallography/spectroscopy/industrialengineering additions")
    }
    // MARK: - psycholinguistics templates
    @Test func psycholinguisticsStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("psycholinguistics") && $0.task.lowercased().contains("exam") })
    }
    @Test func psycholinguisticsAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("psycholinguistics") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - photogrammetry templates
    @Test func photogrammetryStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("photogrammetry") && $0.task.lowercased().contains("exam") })
    }
    @Test func photogrammetryAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("photogrammetry") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - tectonics templates
    @Test func tectonicsStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("tectonics") && $0.task.lowercased().contains("exam") })
    }
    @Test func tectonicsAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("tectonics") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - tribology templates
    @Test func tribologyStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("tribology") && $0.task.lowercased().contains("exam") })
    }
    @Test func tribologyAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("tribology") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - radiochemistry templates
    @Test func radiochemistryStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("radiochemistry") && $0.task.lowercased().contains("exam") })
    }
    @Test func radiochemistryAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("radiochemistry") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - Count guard (≥991)
    @Test func templateCountAtLeast991() {
        #expect(SuggestedSessionTemplates.all.count >= 991, "template catalog must have ≥991 entries after psycholinguistics/photogrammetry/tectonics/tribology/radiochemistry additions")
    }
    // MARK: - signalprocessing templates
    @Test func signalProcessingStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("signal processing") && $0.task.lowercased().contains("exam") })
    }
    @Test func signalProcessingAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("dsp") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - controlengineering templates
    @Test func controlEngineeringStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("control engineering") && $0.task.lowercased().contains("exam") })
    }
    @Test func controlEngineeringAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("control systems") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - aerostructures templates
    @Test func aerostructuresStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("aerostructures") && $0.task.lowercased().contains("exam") })
    }
    @Test func aerostructuresAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("aircraft structures") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - optogenetics templates
    @Test func optogeneticsStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("optogenetics") && $0.task.lowercased().contains("exam") })
    }
    @Test func optogeneticsLabReportTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("optogenetics") && $0.task.lowercased().contains("lab report") })
    }
    // MARK: - demography templates
    @Test func demographyStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("demography") && $0.task.lowercased().contains("exam") })
    }
    @Test func demographyAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("demography") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - compositematerials templates
    @Test func compositematerialsStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("composite materials") && $0.task.lowercased().contains("exam") })
    }
    @Test func compositematerialsAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("composite materials") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - powerelectronics templates
    @Test func powerelectronicsStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("power electronics") && $0.task.lowercased().contains("exam") })
    }
    @Test func powerelectronicsAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("power electronics") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - geotechnicalengineering templates
    @Test func geotechnicalengineeringStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("geotechnical engineering") && $0.task.lowercased().contains("exam") })
    }
    @Test func geotechnicalengineeringAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("geotechnical engineering") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - structuralanalysis templates
    @Test func structuralanalysisStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("structural analysis") && $0.task.lowercased().contains("exam") })
    }
    @Test func structuralanalysisAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("structural analysis") && $0.task.lowercased().contains("problem set") })
    }
    // MARK: - miningengineering templates
    @Test func miningengineeringStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("mining engineering") && $0.task.lowercased().contains("exam") })
    }
    @Test func miningengineeringAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("mining engineering") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - wastewatertreatment templates
    @Test func wastewatertreatmentStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("wastewater treatment") && $0.task.lowercased().contains("exam") })
    }
    @Test func wastewatertreatmentAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("wastewater treatment") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - airpollutioncontrol templates
    @Test func airpollutioncontrolStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("air pollution control") && $0.task.lowercased().contains("exam") })
    }
    @Test func airpollutioncontrolAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("air pollution control") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - renewableenergy templates
    @Test func renewableenergyStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("renewable energy") && $0.task.lowercased().contains("exam") })
    }
    @Test func renewableenergyAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("renewable energy") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - navalarchitecture templates
    @Test func navalarchitectureStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("naval architecture") && $0.task.lowercased().contains("exam") })
    }
    @Test func navalarchitectureAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("naval architecture") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - mechatronics templates
    @Test func mechatronicsStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("mechatronics") && $0.task.lowercased().contains("exam") })
    }
    @Test func mechatronicsAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("mechatronics") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - structuraldynamics templates
    @Test func structuraldynamicsStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("structural dynamics") && $0.task.lowercased().contains("exam") })
    }
    @Test func structuraldynamicsAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("structural dynamics") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - bioprocessengineering templates
    @Test func bioprocessengineeringStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("bioprocess engineering") && $0.task.lowercased().contains("exam") })
    }
    @Test func bioprocessengineeringAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("bioprocess engineering") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - systemsengineering templates
    @Test func systemsengineeringStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("systems engineering") && $0.task.lowercased().contains("exam") })
    }
    @Test func systemsengineeringAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("systems engineering") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - transportationplanning templates
    @Test func transportationplanningStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("transportation planning") && $0.task.lowercased().contains("exam") })
    }
    @Test func transportationplanningAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("transportation planning") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - architecturalengineering templates
    @Test func architecturalengineeringStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("architectural engineering") && $0.task.lowercased().contains("exam") })
    }
    @Test func architecturalengineeringAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("architectural engineering") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - environmentalhydrology templates
    @Test func environmentalhydrologyStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("environmental hydrology") && $0.task.lowercased().contains("exam") })
    }
    @Test func environmentalhydrologyAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("environmental hydrology") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - geoenvironmentalengineering templates
    @Test func geoenvironmentalengineeringStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("geoenvironmental engineering") && $0.task.lowercased().contains("exam") })
    }
    @Test func geoenvironmentalengineeringAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("geoenvironmental engineering") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - earthquakeengineering templates
    @Test func earthquakeengineeringStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("earthquake engineering") && $0.task.lowercased().contains("exam") })
    }
    @Test func earthquakeengineeringAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("earthquake engineering") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - computationalstructuralmechanics templates
    @Test func computationalstructuralmechanicsStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("computational structural mechanics") && $0.task.lowercased().contains("exam") })
    }
    @Test func computationalstructuralmechanicsAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("finite element analysis") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - coastalengineeringocean templates
    @Test func coastalengineeringoceanStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("coastal engineering") && $0.task.lowercased().contains("exam") })
    }
    @Test func coastalengineeringoceanAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("coastal engineering") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - Count guard (≥1041)
    @Test func templateCountAtLeast1041() {
        #expect(SuggestedSessionTemplates.all.count >= 1041, "template catalog must have ≥1041 entries after environmentalhydrology/geoenvironmentalengineering/earthquakeengineering/computationalstructuralmechanics/coastalengineeringocean additions")
    }
    // MARK: - corrosionengineering templates
    @Test func corrosionengineeringStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("corrosion engineering") && $0.task.lowercased().contains("exam") })
    }
    @Test func corrosionengineeringAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("corrosion engineering") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - acousticalengineering templates
    @Test func acousticalengineeringStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("acoustical engineering") && $0.task.lowercased().contains("exam") })
    }
    @Test func acousticalengineeringAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("acoustical engineering") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - microfluidics templates
    @Test func microfluidicsStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("microfluidics") && $0.task.lowercased().contains("exam") })
    }
    @Test func microfluidicsAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("microfluidics") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - marinehydrodynamics templates
    @Test func marinehydrodynamicsStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("marine hydrodynamics") && $0.task.lowercased().contains("exam") })
    }
    @Test func marinehydrodynamicsAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("marine hydrodynamics") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - thermofluidscombustion templates
    @Test func thermofluidscombustionStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("combustion engineering") && $0.task.lowercased().contains("exam") })
    }
    @Test func thermofluidscombustionAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("combustion engineering") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - quantumfieldtheory templates
    @Test func quantumfieldtheoryStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("quantum field theory") && $0.task.lowercased().contains("exam") })
    }
    @Test func quantumfieldtheoryAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("quantum field theory") && $0.task.lowercased().contains("problem set") })
    }
    // MARK: - rfengineering templates
    @Test func rfengineeringStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("rf engineering") && $0.task.lowercased().contains("exam") })
    }
    @Test func rfengineeringAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("rf engineering") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - fluidmechanics templates
    @Test func fluidmechanicsStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("fluid mechanics") && $0.task.lowercased().contains("exam") })
    }
    @Test func fluidmechanicsAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("fluid mechanics") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - heattransfer templates
    @Test func heattransferStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("heat transfer") && $0.task.lowercased().contains("exam") })
    }
    @Test func heattransferAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("heat transfer") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - powersystems templates
    @Test func powersystemsStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("power systems") && $0.task.lowercased().contains("exam") })
    }
    @Test func powersystemsAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("power systems") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - nuclearreactorphysics templates
    @Test func nuclearreactorphysicsStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("reactor physics") && $0.task.lowercased().contains("exam") })
    }
    @Test func nuclearreactorphysicsAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("reactor physics") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - optoelectronics templates
    @Test func optoelectronicsStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("optoelectronics") && $0.task.lowercased().contains("exam") })
    }
    @Test func optoelectronicsAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("optoelectronics") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - magneticresonance templates
    @Test func magneticresonanceStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("mri") && $0.task.lowercased().contains("exam") })
    }
    @Test func magneticresonanceAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("mri") && ($0.task.lowercased().contains("assignment") || $0.task.lowercased().contains("nmr")) })
    }
    // MARK: - computationalelectromagnetics templates
    @Test func computationalelectromagneticsStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("computational electromagnetics") && $0.task.lowercased().contains("exam") })
    }
    @Test func computationalelectromagneticsAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("computational electromagnetics") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - thermoelectrics templates
    @Test func thermoelectricsStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("thermoelectrics") && $0.task.lowercased().contains("exam") })
    }
    @Test func thermoelectricsAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("thermoelectrics") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - nucleardynamics templates
    @Test func nucleardynamicsStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("reactor dynamics") && $0.task.lowercased().contains("exam") })
    }
    @Test func nucleardynamicsAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("reactor dynamics") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - additivemfg templates
    @Test func additivemfgStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("additive manufacturing") && $0.task.lowercased().contains("exam") })
    }
    @Test func additivemfgAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("additive manufacturing") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - batterytechnology templates
    @Test func batterytechnologyStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("battery technology") && $0.task.lowercased().contains("exam") })
    }
    @Test func batterytechnologyAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("battery technology") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - semiconductordevices templates
    @Test func semiconductordevicesStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("semiconductor devices") && $0.task.lowercased().contains("exam") })
    }
    @Test func semiconductordevicesAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("semiconductor devices") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - vlsidesign templates
    @Test func vlsidesignStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("vlsi design") && $0.task.lowercased().contains("exam") })
    }
    @Test func vlsidesignAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("vlsi design") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - spaceweather templates
    @Test func spaceweatherStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("space weather") && $0.task.lowercased().contains("exam") })
    }
    @Test func spaceweatherAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("space weather") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - nanophotonics templates
    @Test func nanophotonicsStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("nanophotonics") && $0.task.lowercased().contains("exam") })
    }
    @Test func nanophotonicsAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("nanophotonics") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - microelectromechanicalsystems templates
    @Test func memsStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("mems") && $0.task.lowercased().contains("exam") })
    }
    @Test func memsAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("mems") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - photovoltaicsenergy templates
    @Test func pvStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("photovoltaic") && $0.task.lowercased().contains("exam") })
    }
    @Test func pvAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("photovoltaic") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - biomechatronics templates
    @Test func biomechatronicsStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("biomechatronics") && $0.task.lowercased().contains("exam") })
    }
    @Test func biomechatronicsAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("biomechatronics") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - condensedmatterphysics templates
    @Test func condensedmatterphysicsStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("condensed matter") && $0.task.lowercased().contains("exam") })
    }
    @Test func condensedmatterphysicsAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("condensed matter") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - energymaterials templates
    @Test func energymaterialsStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("energy materials") && $0.task.lowercased().contains("exam") })
    }
    @Test func energymaterialsAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("energy materials") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - computationalneuroscience templates
    @Test func computationalneuroscienceStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("computational neuroscience") && $0.task.lowercased().contains("exam") })
    }
    @Test func computationalneuroscienceAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("computational neuroscience") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - biophysicslab templates
    @Test func biophysicslabStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("biophysics lab") && $0.task.lowercased().contains("study") })
    }
    @Test func biophysicslabAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("biophysics lab report") && $0.task.lowercased().contains("assignment") || $0.task.lowercased().contains("biophysics lab report") })
    }
    // MARK: - solidmechanics templates
    @Test func solidmechanicsStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("solid mechanics") && $0.task.lowercased().contains("exam") })
    }
    @Test func solidmechanicsAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("solid mechanics") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - stochasticprocesses templates
    @Test func stochasticprocessesStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("stochastic processes") && $0.task.lowercased().contains("exam") })
    }
    @Test func stochasticprocessesAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("stochastic processes") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - quantumchemistry templates
    @Test func quantumchemistryStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("quantum chemistry") && $0.task.lowercased().contains("exam") })
    }
    @Test func quantumchemistryAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("quantum chemistry") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - opticalengineering templates
    @Test func opticalengineeringStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("optical engineering") && $0.task.lowercased().contains("exam") })
    }
    @Test func opticalengineeringAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("optical engineering") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - surfacechemistry templates
    @Test func surfacechemistryStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("surface chemistry") && $0.task.lowercased().contains("exam") })
    }
    @Test func surfacechemistryAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("surface chemistry") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - quantumoptics templates
    @Test func quantumopticsStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("quantum optics") && $0.task.lowercased().contains("exam") })
    }
    @Test func quantumopticsAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("quantum optics") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - marinechemistry templates
    @Test func marinechemistryStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("marine chemistry") && $0.task.lowercased().contains("exam") })
    }
    @Test func marinechemistryAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("marine chemistry") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - bioinorganicchemistry templates
    @Test func bioinorganicchemistryStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("bioinorganic chemistry") && $0.task.lowercased().contains("exam") })
    }
    @Test func bioinorganicchemistryAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("bioinorganic chemistry") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - informationtheory templates
    @Test func informationtheoryStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("information theory") && $0.task.lowercased().contains("exam") })
    }
    @Test func informationtheoryAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("information theory") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - mathematicalstatistics templates
    @Test func mathematicalstatisticsStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("mathematical statistics") && $0.task.lowercased().contains("exam") })
    }
    @Test func mathematicalstatisticsAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("mathematical statistics") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - historicalgeology templates
    @Test func historicalgeologyStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("historical geology") && $0.task.lowercased().contains("exam") })
    }
    @Test func historicalgeologyAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("historical geology") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - agriculturalchemistry templates
    @Test func agriculturalchemistryStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("agricultural chemistry") && $0.task.lowercased().contains("exam") })
    }
    @Test func agriculturalchemistryAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("agricultural chemistry") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - digitalcommunications templates
    @Test func digitalcommunicationsStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("digital communications") && $0.task.lowercased().contains("exam") })
    }
    @Test func digitalcommunicationsAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("digital communications") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - contractlaw templates
    @Test func contractlawStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("contract law") && $0.task.lowercased().contains("exam") })
    }
    @Test func contractlawAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("contracts") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - propertylaw templates
    @Test func propertylawStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("property law") && $0.task.lowercased().contains("exam") })
    }
    @Test func propertylawAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("property law") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - metamaterials templates
    @Test func metamaterialsStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("metamaterials") && $0.task.lowercased().contains("exam") })
    }
    @Test func metamaterialsAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("metamaterials") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - nondestructivetesting templates
    @Test func nondestructivetestingStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("nondestructive testing") && $0.task.lowercased().contains("exam") })
    }
    @Test func nondestructivetestingAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("nondestructive testing") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - optimalcontrol templates
    @Test func optimalcontrolStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("optimal control") && $0.task.lowercased().contains("exam") })
    }
    @Test func optimalcontrolAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("optimal control") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - rocketpropulsion templates
    @Test func rocketpropulsionStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("rocket propulsion") && $0.task.lowercased().contains("exam") })
    }
    @Test func rocketpropulsionAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("rocket propulsion") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - reliabilityengineering templates
    @Test func reliabilityengineeringStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("reliability engineering") && $0.task.lowercased().contains("exam") })
    }
    @Test func reliabilityengineeringAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("reliability engineering") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - measuretheory templates
    @Test func measuretheoryStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("measure theory") && $0.task.lowercased().contains("exam") })
    }
    @Test func measuretheoryProblemSetTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("measure theory") && $0.task.lowercased().contains("problem set") })
    }
    // MARK: - algebraictopology templates
    @Test func algebraictopologyStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("algebraic topology") && $0.task.lowercased().contains("exam") })
    }
    @Test func algebraictopologyAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("algebraic topology") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - numbertheory templates
    @Test func numbertheoryStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("number theory") && $0.task.lowercased().contains("exam") })
    }
    @Test func numbertheoryProblemSetTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("number theory") && $0.task.lowercased().contains("problem set") })
    }
    // MARK: - orthopedicsrotation templates
    @Test func orthopedicsrotationNotesTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("orthopedics rotation") && $0.task.lowercased().contains("notes") })
    }
    @Test func orthopedicsrotationShelfTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("orthopedics") && $0.task.lowercased().contains("shelf exam") })
    }
    // MARK: - cardiologyrotation templates
    @Test func cardiologyrotationNotesTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("cardiology rotation") && $0.task.lowercased().contains("notes") })
    }
    @Test func cardiologyrotationShelfTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("cardiology") && $0.task.lowercased().contains("shelf exam") })
    }
    // MARK: - nephrologyrotation templates
    @Test func nephrologyrotationNotesTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("nephrology rotation") && $0.task.lowercased().contains("notes") })
    }
    @Test func nephrologyrotationShelfTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("nephrology") && $0.task.lowercased().contains("shelf exam") })
    }
    // MARK: - endocrinologyrotation templates
    @Test func endocrinologyrotationNotesTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("endocrinology rotation") && $0.task.lowercased().contains("notes") })
    }
    @Test func endocrinologyrotationShelfTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("endocrinology") && $0.task.lowercased().contains("shelf exam") })
    }
    // MARK: - hematologyoncology templates
    @Test func hematologyoncologyNotesTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("hematology oncology rotation") && $0.task.lowercased().contains("notes") })
    }
    @Test func hematologyoncologyShelfTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("hematology oncology") && $0.task.lowercased().contains("shelf exam") })
    }
    // MARK: - advancedlinearalgebra templates
    @Test func advancedlinearalgebraStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("advanced linear algebra") && $0.task.lowercased().contains("exam") })
    }
    @Test func advancedlinearalgebraProblemSetTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("advanced linear algebra") && $0.task.lowercased().contains("problem set") })
    }
    // MARK: - riemanniangeometry templates
    @Test func riemanniangeometryStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("riemannian geometry") && $0.task.lowercased().contains("exam") })
    }
    @Test func riemanniangeometryProblemSetTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("riemannian geometry") && $0.task.lowercased().contains("problem set") })
    }
    // MARK: - neurologyrotation templates
    @Test func neurologyrotationNotesTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("neurology rotation") && $0.task.lowercased().contains("notes") })
    }
    @Test func neurologyrotationShelfTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("neurology shelf") && $0.task.lowercased().contains("study") })
    }
    // MARK: - surgicalpathology templates
    @Test func surgicalpathologyRotationTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("surgical pathology rotation") && $0.task.lowercased().contains("gross") })
    }
    @Test func surgicalpathologyStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("surgical pathology") && $0.task.lowercased().contains("exam") })
    }
    // MARK: - gametheory templates
    @Test func gametheoryStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("game theory") && $0.task.lowercased().contains("exam") })
    }
    @Test func gametheoryProblemSetTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("game theory") && $0.task.lowercased().contains("problem set") })
    }
    // MARK: - forensicchemistry templates
    @Test func forensicchemistryStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("forensic chemistry") && $0.task.lowercased().contains("exam") })
    }
    @Test func forensicchemistryLabTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("forensic chemistry") && $0.task.lowercased().contains("lab report") })
    }
    // MARK: - neuropharmacology templates
    @Test func neuropharmacologyStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("neuropharmacology") && $0.task.lowercased().contains("exam") })
    }
    @Test func neuropharmacologyProblemSetTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("neuropharmacology") && $0.task.lowercased().contains("problem set") })
    }
    // MARK: - clinicaltoxicology templates
    @Test func clinicaltoxicologyNotesTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("clinical toxicology rotation") && $0.task.lowercased().contains("notes") })
    }
    @Test func clinicaltoxicologyStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("clinical toxicology") && $0.task.lowercased().contains("shelf") })
    }
    // MARK: - globalenvironmentalgovernance templates
    @Test func globalenvironmentalgovernanceStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("global environmental governance") && $0.task.lowercased().contains("exam") })
    }
    @Test func globalenvironmentalgovernancePaperTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("global environmental governance") && $0.task.lowercased().contains("paper") })
    }
    // MARK: - corporatelaw templates
    @Test func corporatelawStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("corporate law") && $0.task.lowercased().contains("exam") })
    }
    @Test func corporatelawProblemSetTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("corporate law") && $0.task.lowercased().contains("problem set") })
    }
    // MARK: - taxlaw templates
    @Test func taxlawStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("federal income tax") && $0.task.lowercased().contains("exam") })
    }
    @Test func taxlawProblemSetTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("tax law") && $0.task.lowercased().contains("problem set") })
    }
    // MARK: - administrativelaw templates
    @Test func administrativelawStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("administrative law") && $0.task.lowercased().contains("exam") })
    }
    @Test func administrativelawPaperTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("administrative law") && $0.task.lowercased().contains("paper") })
    }
    // MARK: - physicaltherapy templates
    @Test func physicaltherapyNotesTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("pt clinical notes") || ($0.task.lowercased().contains("physical therapy") && $0.task.lowercased().contains("clinical notes")) })
    }
    @Test func physicaltherapyNPTETemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("npte") || ($0.task.lowercased().contains("physical therapy") && $0.task.lowercased().contains("exam")) })
    }
    // MARK: - medicalspanish templates
    @Test func medicalspanishVocabularyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("medical spanish") && $0.task.lowercased().contains("vocabulary") })
    }
    @Test func medicalspanishPracticeTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("medical spanish") && $0.task.lowercased().contains("practice") })
    }
    // MARK: - musicology templates
    @Test func musicologyPaperTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("musicology") && $0.task.lowercased().contains("paper") })
    }
    @Test func musicologyStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("musicology") && $0.task.lowercased().contains("exam") })
    }
    // MARK: - patientadvocacy templates
    @Test func patientadvocacyCourseworkTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("patient advocacy") && $0.task.lowercased().contains("bcpa") })
    }
    @Test func patientadvocacyCaseStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("patient advocacy") && $0.task.lowercased().contains("case study") })
    }
    // MARK: - animallaw templates
    @Test func animallawStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("animal law") && $0.task.lowercased().contains("exam") })
    }
    @Test func animallawWritingTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("animal law") && $0.task.lowercased().contains("memo") })
    }
    // MARK: - computationallinguistics templates
    @Test func computationallinguisticsStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("computational linguistics") && $0.task.lowercased().contains("exam") })
    }
    @Test func computationallinguisticsProblemSetTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("computational linguistics") && $0.task.lowercased().contains("problem set") })
    }
    // MARK: - sociolinguistics templates
    @Test func sociolinguisticsStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("sociolinguistics") && $0.task.lowercased().contains("exam") })
    }
    @Test func sociolinguisticsPaperTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("sociolinguistics") && $0.task.lowercased().contains("paper") })
    }
    // MARK: - agroecology templates
    @Test func agroecologyStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("agroecology") && $0.task.lowercased().contains("exam") })
    }
    @Test func agroecologyDesignTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("agroecology") && $0.task.lowercased().contains("design") })
    }
    // MARK: - forensicengineering templates
    @Test func forensicengineeringStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("forensic engineering") && $0.task.lowercased().contains("exam") })
    }
    @Test func forensicengineeringReportTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("forensic engineering") && $0.task.lowercased().contains("report") })
    }
    // MARK: - healthlaw templates
    @Test func healthlawStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("health law") && $0.task.lowercased().contains("exam") })
    }
    @Test func healthlawWritingTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("health law") && $0.task.lowercased().contains("paper") })
    }
    // MARK: - Count guard (≥1199)
    @Test func templateCountAtLeast1199() {
        #expect(SuggestedSessionTemplates.all.count >= 1199, "template catalog must have ≥1199 entries after computationallinguistics/sociolinguistics/agroecology/forensicengineering/healthlaw additions")
    }
    // MARK: - deepseabiology templates
    @Test func deepseabiologyStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("deep-sea biology") && $0.task.lowercased().contains("exam") })
    }
    @Test func deepseabiologyLabTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("deep-sea biology") && $0.task.lowercased().contains("lab report") })
    }
    // MARK: - constructionestimating templates
    @Test func constructionestimatingStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("construction estimating") && $0.task.lowercased().contains("exam") })
    }
    @Test func constructionestimatingAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("construction estimating") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - internationallaw templates
    @Test func internationallawStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("public international law") && $0.task.lowercased().contains("exam") })
    }
    @Test func internationallawWritingTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("international law") && $0.task.lowercased().contains("case brief") })
    }
    // MARK: - urbansociology templates
    @Test func urbansociologyStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("urban sociology") && $0.task.lowercased().contains("exam") })
    }
    @Test func urbansociologyPaperTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("urban sociology") && $0.task.lowercased().contains("paper") })
    }
    // MARK: - politicalsociology templates
    @Test func politicalsociologyStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("political sociology") && $0.task.lowercased().contains("exam") })
    }
    @Test func politicalsociologyPaperTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("political sociology") && $0.task.lowercased().contains("paper") })
    }
    // MARK: - Count guard (≥1209)
    @Test func templateCountAtLeast1209() {
        #expect(SuggestedSessionTemplates.all.count >= 1209, "template catalog must have ≥1209 entries after deepseabiology/constructionestimating/internationallaw/urbansociology/politicalsociology additions")
    }
    // MARK: - environmentaleconomics templates
    @Test func environmentaleconomicsStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("environmental economics") && $0.task.lowercased().contains("exam") })
    }
    @Test func environmentaleconomicsProblemSetTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("environmental economics") && $0.task.lowercased().contains("problem set") })
    }
    // MARK: - socialepigenetics templates
    @Test func socialepigeneticsStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("epigenetics") && $0.task.lowercased().contains("exam") })
    }
    @Test func socialepigeneticsLabTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("epigenetics") && $0.task.lowercased().contains("lab report") })
    }
    // MARK: - behavioralneuroscience templates
    @Test func behavioralneuroscienceStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("behavioral neuroscience") && $0.task.lowercased().contains("exam") })
    }
    @Test func behavioralneuroscienceLabTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("behavioral neuroscience") && $0.task.lowercased().contains("lab report") })
    }
    // MARK: - medicalethics templates
    @Test func medicalethicsStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("medical ethics") && $0.task.lowercased().contains("exam") })
    }
    @Test func medicalethicsCaseTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("medical ethics") && $0.task.lowercased().contains("case") })
    }
    // MARK: - lawandeconomics templates
    @Test func lawandeconomicsStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("law and economics") && $0.task.lowercased().contains("exam") })
    }
    @Test func lawandeconomicsPaperTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("law and economics") && $0.task.lowercased().contains("paper") })
    }
    // MARK: - Count guard (≥1219)
    @Test func templateCountAtLeast1219() {
        #expect(SuggestedSessionTemplates.all.count >= 1219, "template catalog must have ≥1219 entries after environmentaleconomics/socialepigenetics/behavioralneuroscience/medicalethics/lawandeconomics additions")
    }
    // MARK: - scientificwriting templates
    @Test func scientificwritingStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("scientific writing") && $0.task.lowercased().contains("exam") })
    }
    @Test func scientificwritingDraftTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("scientific paper") && $0.task.lowercased().contains("methods section") })
    }
    // MARK: - behavioralbiology templates
    @Test func behavioralbiolgyStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("behavioral biology") && $0.task.lowercased().contains("exam") })
    }
    @Test func behavioralbiolgyPaperTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("behavioral biology") && $0.task.lowercased().contains("paper") })
    }
    // MARK: - agingneuroscience templates
    @Test func agingneuroscienceStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("neuroscience of aging") && $0.task.lowercased().contains("exam") })
    }
    @Test func agingneurosciencePaperTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("neuroscience of aging") && $0.task.lowercased().contains("paper") })
    }
    // MARK: - computationalsocialscience templates
    @Test func computationalsocialscienceStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("computational social science") && $0.task.lowercased().contains("exam") })
    }
    @Test func computationalsocialsciencePaperTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("computational social science") && $0.task.lowercased().contains("paper") })
    }
    // MARK: - publicpolicy templates
    @Test func publicpolicyStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("public policy") && $0.task.lowercased().contains("exam") })
    }
    @Test func publicpolicyPaperTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("public policy") && $0.task.lowercased().contains("paper") })
    }
    // MARK: - quantumtransport templates
    @Test func quantumtransportStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("quantum transport") && $0.task.lowercased().contains("exam") })
    }
    @Test func quantumtransportAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("quantum transport") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - geophysicsinversion templates
    @Test func geophysicsinversionStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("seismic inversion") && $0.task.lowercased().contains("exam") })
    }
    @Test func geophysicsinversionAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("seismic inversion") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - constitutivemodeling templates
    @Test func constitutiivemodelingStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("constitutive modeling") && $0.task.lowercased().contains("exam") })
    }
    @Test func constitutivemodelingAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("constitutive modeling") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - infraredspectroscopy templates
    @Test func infraredspectroscopyStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("infrared spectroscopy") && $0.task.lowercased().contains("exam") })
    }
    @Test func infraredspectroscopyAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("infrared spectroscopy") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - biogeochemistry templates
    @Test func biogeochemistryStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("biogeochemistry") && $0.task.lowercased().contains("exam") })
    }
    @Test func biogeochemistryAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("biogeochemistry") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - tectonophysics templates
    @Test func tectonophysicsStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("tectonophysics") && $0.task.lowercased().contains("exam") })
    }
    @Test func tectonophysicsAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("tectonophysics") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - catalysis templates
    @Test func catalysisStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("catalysis") && $0.task.lowercased().contains("exam") })
    }
    @Test func catalysisAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("catalysis") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - rheology templates
    @Test func rheologyStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("rheology") && $0.task.lowercased().contains("exam") })
    }
    @Test func rheologyAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("rheology") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - molecularsimulation templates
    @Test func molecularsimulationStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("molecular simulation") && $0.task.lowercased().contains("exam") })
    }
    @Test func molecularsimulationAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("molecular simulation") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - sciencecommunication templates
    @Test func sciencecommunicationStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("science communication") && $0.task.lowercased().contains("exam") })
    }
    @Test func sciencecommunicationAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("science communication") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - healthbehavior templates
    @Test func healthbehaviorStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("health behavior theory") && $0.task.lowercased().contains("exam") })
    }
    @Test func healthbehaviorAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("health behavior") && $0.task.lowercased().contains("intervention design") })
    }
    // MARK: - physicalanthropology templates
    @Test func physicalanthropologyStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("physical anthropology") && $0.task.lowercased().contains("exam") })
    }
    @Test func physicalanthropologyAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("physical anthropology") && $0.task.lowercased().contains("skeletal analysis") })
    }
    // MARK: - culturalanthropology templates
    @Test func culturalanthropologyStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("cultural anthropology") && $0.task.lowercased().contains("exam") })
    }
    @Test func culturalanthropologyAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("cultural anthropology") && $0.task.lowercased().contains("fieldwork design") })
    }
    // MARK: - translationalscience templates
    @Test func translationalscienceStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("translational science") && $0.task.lowercased().contains("exam") })
    }
    @Test func translationalscienceAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("translational science") && $0.task.lowercased().contains("paper") })
    }
    // MARK: - globalhealth templates
    @Test func globalhealthStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("global health") && $0.task.lowercased().contains("exam") })
    }
    @Test func globalhealthAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("global health") && $0.task.lowercased().contains("paper") })
    }
    // MARK: - disasterrisk templates
    @Test func disasterriskStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("disaster risk") && $0.task.lowercased().contains("exam") })
    }
    @Test func disasterriskAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("disaster risk") && $0.task.lowercased().contains("paper") })
    }
    // MARK: - neonatologyrotation templates
    @Test func neonatologyrotationStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("neonatology") && $0.task.lowercased().contains("rotation") })
    }
    @Test func neonatologyrotationShelfTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("neonatology") && $0.task.lowercased().contains("shelf") })
    }
    // MARK: - developmentalpsychopath templates
    @Test func developmentalpsychopathStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("developmental psychopathology") && $0.task.lowercased().contains("exam") })
    }
    @Test func developmentalpsychopathAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("developmental psychopathology") && $0.task.lowercased().contains("paper") })
    }
    // MARK: - humanrights templates
    @Test func humanrightsStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("human rights") && $0.task.lowercased().contains("exam") })
    }
    @Test func humanrightsAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("human rights") && $0.task.lowercased().contains("paper") })
    }
    // MARK: - exercisephysiology templates
    @Test func exercisephysiologyStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("exercise physiology") && $0.task.lowercased().contains("exam") })
    }
    @Test func exercisephysiologyLabTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("exercise physiology") && $0.task.lowercased().contains("lab report") })
    }
    // MARK: - nutritionscience templates
    @Test func nutritionscienceStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("nutrition science") && $0.task.lowercased().contains("exam") })
    }
    @Test func nutritionscienceAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("nutrition science") && $0.task.lowercased().contains("assignment") })
    }
    // MARK: - reproductivehealth templates
    @Test func reproductivehealthStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("reproductive health") && $0.task.lowercased().contains("exam") })
    }
    @Test func reproductivehealthAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("reproductive health") && $0.task.lowercased().contains("paper") })
    }
    // MARK: - medicalanthropology templates
    @Test func medicalanthropologyStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("medical anthropology") && $0.task.lowercased().contains("exam") })
    }
    @Test func medicalanthropologyAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("medical anthropology") && $0.task.lowercased().contains("paper") })
    }
    // MARK: - comparativepolitics templates
    @Test func comparativepoliticsStudyTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("comparative politics") && $0.task.lowercased().contains("exam") })
    }
    @Test func comparativepoliticsAssignmentTemplateExists() {
        #expect(SuggestedSessionTemplates.all.contains { $0.task.lowercased().contains("comparative politics") && $0.task.lowercased().contains("paper") })
    }
    // MARK: - Count guard (≥1277)
    @Test func templateCountAtLeast1277() {
        #expect(SuggestedSessionTemplates.all.count >= 1277, "template catalog must have ≥1277 entries after exercisephysiology/nutritionscience/reproductivehealth/medicalanthropology/comparativepolitics additions")
    }
}
