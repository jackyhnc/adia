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
}
