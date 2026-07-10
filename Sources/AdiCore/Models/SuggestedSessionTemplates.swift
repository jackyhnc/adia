import Foundation

// MARK: - SuggestedTemplate

/// A read-only, pre-built session template shown in the idle notch when the
/// user has no pinned templates. Clicking one prefills the session creation
/// form so the user can personalise it (e.g. add a course name) before starting.
public struct SuggestedTemplate: Sendable {
    public let icon: String          // SF Symbol name
    public let task: String
    public let successCriteria: String
    public let preferredDuration: TimeInterval?  // nil = no suggestion

    public init(icon: String, task: String, successCriteria: String, preferredDuration: TimeInterval? = nil) {
        self.icon = icon
        self.task = task
        self.successCriteria = successCriteria
        self.preferredDuration = preferredDuration
    }
}

// MARK: - SuggestedSessionTemplates

/// Static catalog of curated session starters. Displayed under "SUGGESTIONS"
/// in the idle notch whenever the user has no pinned templates yet.
/// Limited to the first `displayCount` entries so the notch doesn't overflow.
public enum SuggestedSessionTemplates {
    public static let displayCount: Int = 3

    /// Returns a randomly ordered selection of templates, filtered by excluded task names.
    /// When `count` exceeds the available (non-excluded) catalog size, all available items are returned.
    public static func randomSuggestions(count: Int, excluding excludedTasks: Set<String> = []) -> [SuggestedTemplate] {
        Array(all.filter { !excludedTasks.contains($0.task) }.shuffled().prefix(count))
    }

    public static let all: [SuggestedTemplate] = [
        SuggestedTemplate(
            icon: "doc.text",
            task: "Write my essay and submit it",
            successCriteria: "Essay submitted — confirmation page or upload receipt visible on screen",
            preferredDuration: 90 * 60
        ),
        SuggestedTemplate(
            icon: "function",
            task: "Complete my problem set",
            successCriteria: "All problems answered and assignment submitted to the course portal",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "brain",
            task: "Study for my exam",
            successCriteria: "Finished reviewing all assigned material and completed at least one practice test",
            preferredDuration: 45 * 60
        ),
        SuggestedTemplate(
            icon: "book",
            task: "Read the assigned chapter and take notes",
            successCriteria: "Chapter fully read and handwritten or typed summary notes visible on screen",
            preferredDuration: 45 * 60
        ),
        SuggestedTemplate(
            icon: "flask",
            task: "Write my lab report",
            successCriteria: "Lab report complete with all sections filled in and uploaded to the course portal",
            preferredDuration: 90 * 60
        ),
        SuggestedTemplate(
            icon: "chevron.left.forwardslash.chevron.right",
            task: "Work on my coding project",
            successCriteria: "Target feature implemented, tests passing, changes committed to repo",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "paperplane",
            task: "Write and send job applications",
            successCriteria: "Applications submitted — confirmation emails or portal receipts visible",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "tray.and.arrow.down",
            task: "Clear my email inbox",
            successCriteria: "Inbox at zero — all urgent emails replied to or archived",
            preferredDuration: 25 * 60
        ),
        SuggestedTemplate(
            icon: "person.wave.2",
            task: "Prepare my presentation slides",
            successCriteria: "Slide deck complete with all sections filled in and a full run-through done",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "mic",
            task: "Record a podcast episode",
            successCriteria: "Episode fully recorded, rough edit done, and exported audio file visible in Finder or editor",
            preferredDuration: 45 * 60
        ),
        SuggestedTemplate(
            icon: "paintbrush",
            task: "Design a mockup in Figma",
            successCriteria: "Mockup covers all key screens or states for the target flow and is ready for review",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "briefcase",
            task: "Prep for my upcoming interview",
            successCriteria: "Practiced answers to the top 10 questions and reviewed the company and role out loud",
            preferredDuration: 45 * 60
        ),
        SuggestedTemplate(
            icon: "pencil.and.outline",
            task: "Write a blog post",
            successCriteria: "Post drafted, revised for clarity, and either published or saved as a final draft ready to publish",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "doc.richtext",
            task: "Work on my thesis or research paper",
            successCriteria: "At least one full section drafted or revised with citations in place",
            preferredDuration: 90 * 60
        ),
        SuggestedTemplate(
            icon: "figure.run",
            task: "Complete my workout",
            successCriteria: "All planned exercises finished and logged in workout app or journal",
            preferredDuration: 45 * 60
        ),
        SuggestedTemplate(
            icon: "character.book.closed",
            task: "Study vocabulary for my language class",
            successCriteria: "At least 30 new words reviewed with definitions and used in written sentences",
            preferredDuration: 30 * 60
        ),
        SuggestedTemplate(
            icon: "music.note",
            task: "Practice an instrument for 30 minutes",
            successCriteria: "Practice session complete — pieces or scales logged in practice journal or app",
            preferredDuration: 30 * 60
        ),
        SuggestedTemplate(
            icon: "video",
            task: "Edit and export today's video",
            successCriteria: "Exported video file visible in Finder with correct filename and playback confirmed",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "dollarsign.circle",
            task: "Update my monthly budget",
            successCriteria: "All income and expenses for the month entered, categories balanced, and spreadsheet saved",
            preferredDuration: 30 * 60
        ),
        SuggestedTemplate(
            icon: "text.cursor",
            task: "Write the next chapter of my novel",
            successCriteria: "At least 500 words written and saved (word count visible in writing app)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "book.pages",
            task: "Write today's journal entry",
            successCriteria: "At least 200 words written and saved in journal app or document",
            preferredDuration: 20 * 60
        ),
        SuggestedTemplate(
            icon: "headphones",
            task: "Listen to and annotate an audiobook chapter",
            successCriteria: "Chapter finished and key points noted in reading app or document",
            preferredDuration: 45 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text",
            task: "Write a case brief for class",
            successCriteria: "Case brief complete: facts, issue, rule, analysis, and conclusion all filled in",
            preferredDuration: 45 * 60
        ),
        SuggestedTemplate(
            icon: "text.badge.checkmark",
            task: "Prep for the bar exam — one subject block",
            successCriteria: "Finished one full subject block (essays + MBE practice) and reviewed wrong answers",
            preferredDuration: 2 * 60 * 60
        ),
        SuggestedTemplate(
            icon: "graduationcap",
            task: "Study for the MCAT",
            successCriteria: "Finished one full content section (bio/chem/physics/CARS) with practice questions reviewed and wrong answers noted",
            preferredDuration: 2 * 60 * 60
        ),
        SuggestedTemplate(
            icon: "cross.case",
            task: "Review anatomy for lab practical",
            successCriteria: "All required structures located, labeled in a diagram, and definitions recalled from memory without looking",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "building.2",
            task: "Work on my architecture studio project",
            successCriteria: "Design iteration complete with updated floor plans, elevations, and a rendered view ready for critique",
            preferredDuration: 90 * 60
        ),
        SuggestedTemplate(
            icon: "pencil.and.ruler",
            task: "Study for my architecture licensing exam",
            successCriteria: "Finished one full practice section (ARE) with wrong answers reviewed and key concepts noted",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "chart.line.uptrend.xyaxis",
            task: "Write my startup's pitch deck",
            successCriteria: "All slides complete: problem, solution, market size, business model, traction, team, and ask — narrative flows end to end",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.magnifyingglass",
            task: "Draft a section of my business plan",
            successCriteria: "Section drafted with relevant data, projections, or analysis filled in and conclusion clearly stated",
            preferredDuration: 45 * 60
        ),
        SuggestedTemplate(
            icon: "heart.text.square",
            task: "Write a nursing care plan for class",
            successCriteria: "Care plan complete with nursing diagnosis, patient goals, interventions, and rationale for each problem identified",
            preferredDuration: 45 * 60
        ),
        SuggestedTemplate(
            icon: "pills.circle",
            task: "Practice dosage calculations and medication math",
            successCriteria: "Finished a full set of dosage calc problems with all errors reviewed and correct formulas restated from memory",
            preferredDuration: 30 * 60
        ),
        SuggestedTemplate(
            icon: "camera",
            task: "Edit and export photos from my shoot",
            successCriteria: "All selected photos are edited, color-graded, and exported from Lightroom or Capture One",
            preferredDuration: 45 * 60
        ),
        SuggestedTemplate(
            icon: "camera.aperture",
            task: "Practice and study photography composition techniques",
            successCriteria: "Practiced at least 3 composition techniques with sample shots reviewed and annotated",
            preferredDuration: 30 * 60
        ),
        SuggestedTemplate(
            icon: "brain.head.profile",
            task: "Train and evaluate a machine learning model",
            successCriteria: "Model trained, test accuracy logged, and results documented in the notebook with key findings noted",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "tablecells.badge.ellipsis",
            task: "Work through a Kaggle notebook or data science project",
            successCriteria: "Notebook cells fully run, data explored, baseline model submitted or key findings written up",
            preferredDuration: 45 * 60
        ),
        SuggestedTemplate(
            icon: "gamecontroller",
            task: "Build my game in Unity or Godot",
            successCriteria: "Targeted feature or level implemented, playable in the editor, and no new critical bugs introduced",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text",
            task: "Write my game design document",
            successCriteria: "Core gameplay loop, player goals, mechanics, and win/lose conditions all documented clearly",
            preferredDuration: 45 * 60
        ),
        SuggestedTemplate(
            icon: "wrench.and.screwdriver",
            task: "Complete my engineering problem set",
            successCriteria: "All assigned problems attempted, worked solutions shown with units, and answers checked against any known answers",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "ruler",
            task: "Work on my CAD model or technical drawing",
            successCriteria: "Target component modeled or drawing completed with dimensions, tolerances, and annotations added",
            preferredDuration: 45 * 60
        ),
        SuggestedTemplate(
            icon: "note.text",
            task: "Write up my therapy session notes",
            successCriteria: "All sessions documented with presenting concerns, interventions used, progress toward goals, and next-session plan",
            preferredDuration: 30 * 60
        ),
        SuggestedTemplate(
            icon: "brain",
            task: "Work on my CBT worksheets or treatment planning",
            successCriteria: "Thought records, behavioral experiments, or treatment plan section completed and ready for review in supervision",
            preferredDuration: 45 * 60
        ),
    ]
}
