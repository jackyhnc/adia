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
        SuggestedTemplate(
            icon: "globe",
            task: "Work on my political science or sociology paper",
            successCriteria: "Argument clearly stated, at least one section drafted with supporting evidence cited from peer-reviewed sources",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "doc.badge.plus",
            task: "Prepare for the LSAT",
            successCriteria: "One full practice section completed, answers reviewed, and key patterns or mistakes documented for follow-up",
            preferredDuration: 90 * 60
        ),
        SuggestedTemplate(
            icon: "fork.knife",
            task: "Complete my dietetics or food science assignment",
            successCriteria: "All required questions answered or case study analysis written up with appropriate dietary recommendations cited",
            preferredDuration: 45 * 60
        ),
        SuggestedTemplate(
            icon: "chart.bar",
            task: "Track and analyze my daily nutrition intake",
            successCriteria: "All meals logged with macronutrient breakdown complete and a brief written reflection on patterns or gaps",
            preferredDuration: 30 * 60
        ),
        SuggestedTemplate(
            icon: "flame",
            task: "Develop and test a new recipe",
            successCriteria: "Recipe written with ingredients, quantities, and step-by-step instructions; tested at least once with notes on what to adjust next time",
            preferredDuration: 45 * 60
        ),
        SuggestedTemplate(
            icon: "doc.badge.checkmark",
            task: "Study for a culinary school exam or technique quiz",
            successCriteria: "All required material reviewed, key techniques and terms memorized, and a short self-quiz completed with corrections noted",
            preferredDuration: 30 * 60
        ),
        SuggestedTemplate(
            icon: "text.quote",
            task: "Analyze a philosophical argument or write a response paper",
            successCriteria: "Core argument clearly identified and reconstructed, your position stated, and at least one objection with a rebuttal drafted",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "books.vertical",
            task: "Read and take notes on a philosophy text",
            successCriteria: "Assigned reading complete, key concepts summarized in your own words, and at least three questions or observations noted for discussion",
            preferredDuration: 45 * 60
        ),
        SuggestedTemplate(
            icon: "music.note.list",
            task: "Produce and mix a track in my DAW",
            successCriteria: "Arrangement finalized, mix leveled and exported as a WAV or MP3 file visible in Finder with correct filename",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "waveform",
            task: "Practice ear training and music theory exercises",
            successCriteria: "At least 20 interval or chord identification exercises completed, accuracy score recorded, and one scale or chord progression drilled",
            preferredDuration: 30 * 60
        ),
        SuggestedTemplate(
            icon: "leaf",
            task: "Write a field ecology or environmental science report",
            successCriteria: "Report structure complete — introduction, methods, results, and at least a draft discussion section with citations for all data sources",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "sun.haze",
            task: "Study for my environmental science exam",
            successCriteria: "All assigned chapters reviewed, key concepts and processes summarized in notes, and a short self-quiz completed with corrections",
            preferredDuration: 45 * 60
        ),
        SuggestedTemplate(
            icon: "chart.line.uptrend.xyaxis",
            task: "Complete a financial analysis or modeling assignment",
            successCriteria: "Financial model complete with all assumptions documented, key metrics calculated, and a brief written summary of findings",
            preferredDuration: 45 * 60
        ),
        SuggestedTemplate(
            icon: "building.columns",
            task: "Study for the CPA or CFA exam",
            successCriteria: "All assigned material reviewed, practice problems completed with corrections, and a summary of weak areas noted for further review",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "chart.bar.xaxis",
            task: "Build a DCF model or investment banking analysis",
            successCriteria: "Model fully built with revenue projections, cost assumptions, WACC calculated, terminal value estimated, and valuation range summarized in a short written commentary",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text",
            task: "Write a policy memo or brief",
            successCriteria: "Memo complete with executive summary, problem statement, analysis of at least two policy options, and a clear recommendation with supporting evidence",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "magnifyingglass.circle",
            task: "Analyze a regulatory framework or policy document",
            successCriteria: "Document reviewed, key provisions summarized, implications identified, and at least two paragraphs of critical analysis written with citations",
            preferredDuration: 45 * 60
        ),
        SuggestedTemplate(
            icon: "person.2.fill",
            task: "Conduct user research and synthesize findings",
            successCriteria: "All interviews or surveys completed, notes organized, key themes identified in an affinity diagram or synthesis document, and a clear summary of insights written up",
            preferredDuration: 45 * 60
        ),
        SuggestedTemplate(
            icon: "rectangle.on.rectangle",
            task: "Map out a user flow or wireframe a feature in Figma",
            successCriteria: "Complete user flow or wireframe screens created for the target feature, with all key states and edge cases covered and a brief annotation explaining design decisions",
            preferredDuration: 45 * 60
        ),
        SuggestedTemplate(
            icon: "chart.xyaxis.line",
            task: "Run a statistical analysis in R or SPSS",
            successCriteria: "Dataset loaded, analysis script complete and run without errors, results table or output visible, and a brief interpretation of findings written",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "function",
            task: "Complete a statistics problem set or lab report",
            successCriteria: "All problems answered with correct statistical tests shown, interpretation written for each result, and assignment submitted or saved for submission",
            preferredDuration: 45 * 60
        ),
        SuggestedTemplate(
            icon: "figure.run",
            task: "Complete my kinesiology or exercise physiology assignment",
            successCriteria: "All questions answered, movement analysis or lab report written with references to physiological mechanisms, and assignment saved or submitted",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "heart.text.clipboard",
            task: "Study for the CSCS exam or kinesiology test",
            successCriteria: "Target chapter or topic reviewed, key concepts summarized in own words, and at least 10 practice questions completed with corrections",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "pawprint.fill",
            task: "Complete my veterinary school assignment or case notes",
            successCriteria: "Case notes or assignment written up completely, key clinical findings documented, and differential diagnoses or treatment plan recorded",
            preferredDuration: 45 * 60
        ),
        SuggestedTemplate(
            icon: "stethoscope",
            task: "Study for the NAVLE or veterinary school exam",
            successCriteria: "Target subject reviewed, key pharmacology or pathology concepts summarized, and at least 15 practice questions completed with explanations",
            preferredDuration: 90 * 60
        ),
        SuggestedTemplate(
            icon: "briefcase.fill",
            task: "Work on an MBA case analysis or strategic management assignment",
            successCriteria: "Case analysis fully written with problem identification, frameworks applied (SWOT, Porter's Five Forces, or similar), strategic recommendations clear, and document saved for submission",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "graduationcap.fill",
            task: "Prep for the GMAT or business school entrance exam",
            successCriteria: "At least one full practice section completed, incorrect answers reviewed and error patterns identified, and key concepts or formulas for that section noted for further review",
            preferredDuration: 90 * 60
        ),
        SuggestedTemplate(
            icon: "cross.circle.fill",
            task: "Study for my public health or epidemiology exam",
            successCriteria: "Target chapter covered, key concepts (epidemiological measures, study designs, or community health frameworks) summarized in own words, and at least 10 practice questions completed with corrections",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "globe.europe.africa.fill",
            task: "Work on my epidemiology assignment or community health project",
            successCriteria: "Assignment fully written with data analysis or case study completed, citations added for key claims, and document saved for submission",
            preferredDuration: 45 * 60
        ),
    ]
}
