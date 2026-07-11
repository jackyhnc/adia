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
        SuggestedTemplate(
            icon: "staroflife.fill",
            task: "Study for the NREMT or EMT certification exam",
            successCriteria: "Target topic reviewed, key protocols and interventions summarized in own words, and at least 10 practice questions completed with explanations",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "cross.case.fill",
            task: "Complete my paramedic or EMS training assignment",
            successCriteria: "Assignment fully written, clinical scenarios or protocols addressed, key interventions documented, and document saved for submission",
            preferredDuration: 45 * 60
        ),
        SuggestedTemplate(
            icon: "person.2.fill",
            task: "Write case notes or intake assessment for field placement",
            successCriteria: "Case notes or intake assessment written, key presenting issues and interventions documented, and document saved or ready for supervisor review",
            preferredDuration: 45 * 60
        ),
        SuggestedTemplate(
            icon: "book.fill",
            task: "Study for my social work licensing exam or MSW coursework",
            successCriteria: "Target chapter or topic covered, key concepts summarized in own words, and at least 10 practice questions completed with corrections",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "hand.raised.fill",
            task: "Write up my OT session notes or treatment plan",
            successCriteria: "Session notes or treatment plan written with goals, client progress, and interventions documented, and notes saved or ready for supervisor review",
            preferredDuration: 30 * 60
        ),
        SuggestedTemplate(
            icon: "brain.head.profile",
            task: "Study for the NBCOT or occupational therapy school exam",
            successCriteria: "Target domain reviewed, key concepts in occupational performance and intervention summarized, and at least 10 practice questions completed with corrections",
            preferredDuration: 60 * 60
        ),
        // Dental
        SuggestedTemplate(
            icon: "mouth.fill",
            task: "Study for the NBDE or dental school boards",
            successCriteria: "Target subject reviewed (anatomy, pathology, or clinical dentistry), key concepts summarized in notes, and at least 15 board-style questions completed with corrections",
            preferredDuration: 90 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Write dental SOAP notes or complete clinical chart entries",
            successCriteria: "All patient encounter notes written in SOAP format with chief complaint, assessment, treatment plan, and next steps documented and chart updated",
            preferredDuration: 30 * 60
        ),
        // Pharmacy
        SuggestedTemplate(
            icon: "pill.fill",
            task: "Study for the NAPLEX or pharmacy school exam",
            successCriteria: "Target drug class or therapeutics area reviewed, key pharmacokinetics and mechanisms summarized, and at least 10 NAPLEX-style questions completed with corrections",
            preferredDuration: 90 * 60
        ),
        SuggestedTemplate(
            icon: "cross.vial.fill",
            task: "Review drug interactions and pharmacology for rotation",
            successCriteria: "Drug class or interaction category reviewed, mechanism and clinical significance summarized in notes, and top drug interactions memorized with at least 5 case-based questions done",
            preferredDuration: 45 * 60
        ),
        // Optometry
        SuggestedTemplate(
            icon: "eye.fill",
            task: "Study for the NBEO or optometry school boards",
            successCriteria: "Target clinical topic reviewed (visual optics, ocular disease, or contact lens), key concepts summarized, and at least 10 board-style questions completed with corrections",
            preferredDuration: 90 * 60
        ),
        SuggestedTemplate(
            icon: "doc.plaintext.fill",
            task: "Write optometry clinical notes or visual assessment documentation",
            successCriteria: "Patient encounter documented with visual acuity, refraction findings, ocular health assessment, and plan recorded in SOAP format and chart updated",
            preferredDuration: 30 * 60
        ),
        // Cybersecurity
        SuggestedTemplate(
            icon: "lock.shield.fill",
            task: "Complete a CTF challenge or penetration testing lab",
            successCriteria: "At least one challenge or lab fully solved with the flag captured or vulnerability confirmed exploited, and findings documented in notes",
            preferredDuration: 90 * 60
        ),
        SuggestedTemplate(
            icon: "checkmark.seal.fill",
            task: "Study for the CompTIA Security+ or cybersecurity certification exam",
            successCriteria: "Target domain reviewed (network security, threats, or cryptography), key concepts summarized in notes, and at least 10 practice questions completed with corrections",
            preferredDuration: 60 * 60
        ),
        // Screenwriting / Creative Writing
        SuggestedTemplate(
            icon: "film.fill",
            task: "Write a scene or chapter for my screenplay or novel",
            successCriteria: "At least one full scene or chapter draft written with dialogue and action beats (screenplay) or narrative and dialogue (novel), saved to the working document",
            preferredDuration: 45 * 60
        ),
        SuggestedTemplate(
            icon: "text.bubble.fill",
            task: "Outline or develop my story structure",
            successCriteria: "Story structure or outline updated with act breaks, key plot points, or character arcs mapped out, and outline document saved with at least 5 beats clearly defined",
            preferredDuration: 30 * 60
        ),
        // Graphic Design / Branding
        SuggestedTemplate(
            icon: "paintbrush.pointed.fill",
            task: "Design a logo and visual identity for a brand",
            successCriteria: "Logo concept created with at least 2 variations, color palette and typography defined, and design saved to the working file in vector format",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "rectangle.3.group.fill",
            task: "Create an infographic or poster for a design project",
            successCriteria: "Infographic or poster layout complete with all content placed, typography and color palette finalized, and export-ready file saved",
            preferredDuration: 45 * 60
        ),
        // Interior Design
        SuggestedTemplate(
            icon: "house.fill",
            task: "Create a space plan or floor layout for an interior design project",
            successCriteria: "Floor plan with dimensions and furniture placement finalized and saved in design software, ready for client review or critique",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "book.closed.fill",
            task: "Study for the NCIDQ or interior design school exam",
            successCriteria: "Target content area reviewed, key concepts summarized in notes, and at least 10 practice questions completed with corrections",
            preferredDuration: 60 * 60
        ),
        // Speech-Language Pathology
        SuggestedTemplate(
            icon: "waveform.and.mic",
            task: "Write up my speech therapy session notes or progress reports",
            successCriteria: "All client session notes written with goals, client performance, and next steps documented, and notes saved or ready for supervisor review",
            preferredDuration: 30 * 60
        ),
        SuggestedTemplate(
            icon: "ear.badge.checkmark",
            task: "Study for the PRAXIS SLP exam or speech-language pathology coursework",
            successCriteria: "Target domain reviewed (articulation, language disorders, or fluency), key concepts summarized in notes, and at least 10 practice questions completed with corrections",
            preferredDuration: 60 * 60
        ),
        // Real Estate
        SuggestedTemplate(
            icon: "house.circle.fill",
            task: "Prep for my real estate licensing exam",
            successCriteria: "Target exam section reviewed, key concepts (contracts, agency, fair housing) summarized in notes, and at least 20 practice questions completed with corrections noted",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Write a comparative market analysis or listing presentation",
            successCriteria: "CMA or listing presentation completed with comparable properties researched, pricing narrative written, and document saved and ready for client review",
            preferredDuration: 45 * 60
        ),
        // Education / Teaching
        SuggestedTemplate(
            icon: "graduationcap.fill",
            task: "Write my lesson plans for the week",
            successCriteria: "All required lesson plans drafted with learning objectives, activities, and assessment strategies, and plans saved in the lesson planning tool or document",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "pencil.and.ruler.fill",
            task: "Study for my teaching certification exam (Praxis)",
            successCriteria: "Target content area reviewed, key concepts summarized in notes, and at least 15 Praxis-style practice questions completed with corrections",
            preferredDuration: 60 * 60
        ),
        // Actuarial Science
        SuggestedTemplate(
            icon: "function",
            task: "Study for my actuarial exam (Exam P, FM, or IFM)",
            successCriteria: "Target problem type or formula set reviewed, at least 10 practice problems completed and checked against solutions manual, and weak areas noted for next session",
            preferredDuration: 90 * 60
        ),
        SuggestedTemplate(
            icon: "chart.bar.xaxis",
            task: "Work through actuarial practice problems or loss models",
            successCriteria: "Problem set completed with all solutions worked out, incorrect problems reviewed and corrected, and key formulas or methods annotated in study notes",
            preferredDuration: 60 * 60
        ),
        // Journalism / Media Studies
        SuggestedTemplate(
            icon: "newspaper.fill",
            task: "Write and file a news article or investigative report",
            successCriteria: "Article written with headline, lede, body, and sources properly cited, and submitted or saved in the publication system",
            preferredDuration: 45 * 60
        ),
        SuggestedTemplate(
            icon: "mic.fill",
            task: "Study for a journalism exam or media ethics assignment",
            successCriteria: "Target content area reviewed, key journalism ethics or media law concepts summarized in notes, and practice questions completed",
            preferredDuration: 45 * 60
        ),
        // Theology / Religious Studies
        SuggestedTemplate(
            icon: "text.book.closed.fill",
            task: "Analyze a scripture passage or write a theological essay",
            successCriteria: "Target passage analyzed using exegetical method, key themes documented, and essay or response paper drafted with thesis and supporting arguments",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "building.columns.fill",
            task: "Study for a seminary exam or divinity school assignment",
            successCriteria: "Target theology topic reviewed, key doctrines or historical figures summarized in notes, and at least one practice exam section completed",
            preferredDuration: 60 * 60
        ),
        // Criminal Justice / Criminology
        SuggestedTemplate(
            icon: "shield.fill",
            task: "Complete a criminology or criminal justice assignment",
            successCriteria: "Assignment prompt addressed with relevant theory and case evidence, sources cited, and completed draft saved",
            preferredDuration: 45 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.magnifyingglass",
            task: "Study for a criminal justice exam or analyze a crime case",
            successCriteria: "Target content area reviewed, key criminological theories and case examples summarized, and practice questions or case study questions completed",
            preferredDuration: 60 * 60
        ),
        // Physician Assistant
        SuggestedTemplate(
            icon: "stethoscope",
            task: "Study for the PANCE or PA school clinical exam",
            successCriteria: "Target organ system or clinical domain reviewed, key diagnoses and treatment algorithms summarized, and at least 15 PANCE-style questions completed with corrections",
            preferredDuration: 90 * 60
        ),
        SuggestedTemplate(
            icon: "cross.case.fill",
            task: "Write up my PA clinical rotation SOAP notes or patient encounter summaries",
            successCriteria: "All patient encounter notes written in SOAP format with subjective, objective, assessment, and plan documented, and notes saved or submitted for preceptor review",
            preferredDuration: 30 * 60
        ),
        // Chiropractic
        SuggestedTemplate(
            icon: "figure.stand",
            task: "Study for the NBCE chiropractic boards",
            successCriteria: "At least one NBCE subject area reviewed, key anatomical structures and adjustment techniques summarized, and at least 20 board-style practice questions completed with review",
            preferredDuration: 90 * 60
        ),
        SuggestedTemplate(
            icon: "note.text",
            task: "Write chiropractic SOAP notes or complete a clinical case assignment",
            successCriteria: "Patient encounter documented in SOAP format with history, examination findings, assessment, and treatment plan completed, and notes saved for review",
            preferredDuration: 30 * 60
        ),
        // Respiratory Therapy
        SuggestedTemplate(
            icon: "lungs.fill",
            task: "Study for the NBRC respiratory therapy credentialing exam",
            successCriteria: "Target content domain reviewed, key ventilator parameters and clinical protocols summarized, and at least 20 NBRC-style questions completed with corrections",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "waveform.path.ecg",
            task: "Complete a respiratory therapy patient assessment or clinical assignment",
            successCriteria: "Patient respiratory status assessed and documented, ABG values or ventilator settings analyzed with clinical rationale, and findings written up and saved",
            preferredDuration: 30 * 60
        ),
        // Psychology
        SuggestedTemplate(
            icon: "brain.head.profile",
            task: "Write a psychology research paper or literature review",
            successCriteria: "Research question defined, key studies and theoretical frameworks summarized, argument outlined, and at least one full section of the paper drafted",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "book.closed.fill",
            task: "Study for a psychology exam or complete a psych assignment",
            successCriteria: "Target chapters or topic areas reviewed, key theories and landmark studies summarized, and practice questions or application examples completed",
            preferredDuration: 45 * 60
        ),
        // Geology / Earth Science
        SuggestedTemplate(
            icon: "mountain.2.fill",
            task: "Write a geological report or complete an earth science assignment",
            successCriteria: "Geological data analyzed, key formations or processes described with supporting evidence, and a complete written report saved and ready to submit",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "globe.americas.fill",
            task: "Study for my geology exam or review rock and mineral identification",
            successCriteria: "Target mineral groups or geological units reviewed, identification criteria for at least 15 samples memorized, and practice questions or diagrams completed",
            preferredDuration: 45 * 60
        ),
        // Bioinformatics
        SuggestedTemplate(
            icon: "dna",
            task: "Analyze a genomics dataset or run a bioinformatics pipeline",
            successCriteria: "Pipeline executed without errors, output files reviewed and quality-checked, key findings summarized and noted for the final report",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "chart.bar.doc.horizontal",
            task: "Study bioinformatics tools or complete a sequence analysis assignment",
            successCriteria: "Target algorithms or bioinformatics tools reviewed, sequence alignment or annotation task completed, and results interpreted and written up",
            preferredDuration: 45 * 60
        ),
        // Urban Planning
        SuggestedTemplate(
            icon: "building.2.crop.circle.fill",
            task: "Write a comprehensive plan section or urban planning policy analysis",
            successCriteria: "Policy goals and land use recommendations clearly articulated, supporting data cited, and at least one complete section of the plan or analysis written and saved",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "mappin.and.ellipse",
            task: "Study for the AICP exam or complete an urban planning assignment",
            successCriteria: "Target AICP domain or planning topic reviewed, key concepts summarized, and at least 20 practice questions completed with corrections noted",
            preferredDuration: 60 * 60
        ),
        // Dental Hygiene
        SuggestedTemplate(
            icon: "mouth.fill",
            task: "Study for the NBDHE dental hygiene boards",
            successCriteria: "Target content domain reviewed, key periodontal classifications and oral health assessment criteria summarized, and at least 25 NBDHE-style practice questions completed with corrections",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "note.text",
            task: "Complete my periodontal charting or oral health assessment assignment",
            successCriteria: "Patient periodontal chart completed with pocket depths, bleeding points, and recession documented, clinical findings written up and ready for instructor review",
            preferredDuration: 30 * 60
        ),
        // Molecular Biology
        SuggestedTemplate(
            icon: "atom",
            task: "Analyze PCR results or write up a molecular biology lab report",
            successCriteria: "Gel image or PCR data interpreted, results section written with band sizes or Ct values documented, and discussion drafted explaining outcomes relative to expected results",
            preferredDuration: 45 * 60
        ),
        SuggestedTemplate(
            icon: "book.fill",
            task: "Study for a molecular biology or cell biology exam",
            successCriteria: "Target chapters reviewed, key techniques and molecular pathways summarized, and at least 20 practice questions or diagrams completed",
            preferredDuration: 60 * 60
        ),
        // Forensic Accounting
        SuggestedTemplate(
            icon: "magnifyingglass.circle.fill",
            task: "Study for the CFE exam or complete a forensic accounting assignment",
            successCriteria: "Target topic reviewed, key fraud schemes and detection methods summarized, and at least 20 CFE-style practice questions completed with corrections noted",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.magnifyingglass",
            task: "Analyze a financial fraud case or write a forensic accounting report",
            successCriteria: "Case details reviewed, evidence trail documented, findings written up in report format, and key conclusions clearly articulated",
            preferredDuration: 60 * 60
        ),
        // Public Relations / Communications
        SuggestedTemplate(
            icon: "megaphone.fill",
            task: "Write a PR strategy, press kit, or media pitch",
            successCriteria: "Key messages clearly defined, target audience identified, and press kit or pitch fully drafted and ready for review",
            preferredDuration: 45 * 60
        ),
        SuggestedTemplate(
            icon: "book.closed.fill",
            task: "Study for a communications exam or complete a PR class assignment",
            successCriteria: "Target communications concepts reviewed, key PR frameworks summarized, and assignment or study guide completed and saved",
            preferredDuration: 45 * 60
        ),
        // Physical Education / Sport Coaching
        SuggestedTemplate(
            icon: "figure.run",
            task: "Write my lesson plans or coaching plans for the week",
            successCriteria: "At least 3 lesson or coaching plans written with objectives, activities, and progressions outlined and saved for review",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "sportscourt.fill",
            task: "Study for my coaching certification or PE teacher exam",
            successCriteria: "Target content domain reviewed, key coaching or PE concepts summarized, and at least 20 practice questions completed with corrections noted",
            preferredDuration: 60 * 60
        ),
        // Library Science
        SuggestedTemplate(
            icon: "books.vertical.fill",
            task: "Complete my library science or MLIS coursework assignment",
            successCriteria: "Assignment prompt addressed, key cataloging or reference concepts applied, and written work completed and saved for submission",
            preferredDuration: 45 * 60
        ),
        SuggestedTemplate(
            icon: "archivebox.fill",
            task: "Work on archival research or library collection development project",
            successCriteria: "Archival materials reviewed or collection proposal drafted, metadata or annotations completed, and findings documented and saved",
            preferredDuration: 60 * 60
        ),
        // Dental Assisting
        SuggestedTemplate(
            icon: "cross.case.fill",
            task: "Study for the DANB exam or dental assisting certification",
            successCriteria: "Target content area reviewed, key dental assisting procedures and materials summarized, and at least 20 DANB-style practice questions completed with corrections",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "note.text",
            task: "Complete my dental assisting class notes or chairside assisting assignment",
            successCriteria: "Class notes reviewed and organized, chairside procedures or infection control protocols summarized, and assignment written up and ready for submission",
            preferredDuration: 30 * 60
        ),
        // Film Studies
        SuggestedTemplate(
            icon: "film",
            task: "Write a film analysis essay or film criticism paper",
            successCriteria: "Target film analyzed with key scenes, cinematic techniques, and theoretical frameworks addressed; essay draft written with argument structure clear and saved for revision",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "play.rectangle.fill",
            task: "Study for a film studies exam or take critical notes on an assigned film",
            successCriteria: "Key film theories, movements, or directors reviewed; critical notes taken covering cinematography, editing, and narrative structure; study guide completed and saved",
            preferredDuration: 60 * 60
        ),
        // Performing Arts
        SuggestedTemplate(
            icon: "theatermasks.fill",
            task: "Rehearse a monologue, scene, or dance routine",
            successCriteria: "Full performance prepared from memory, key blocking or choreographic sequences executed cleanly, and notes on problem areas documented for next rehearsal",
            preferredDuration: 45 * 60
        ),
        SuggestedTemplate(
            icon: "music.note.list",
            task: "Write a dramaturgy report or theater analysis paper",
            successCriteria: "Performance or script analyzed with historical context, staging choices, and character development addressed; written analysis completed and saved for submission",
            preferredDuration: 60 * 60
        ),
        // Astronomy / Astrophysics
        SuggestedTemplate(
            icon: "sparkles",
            task: "Complete an astrophysics problem set or astronomy lab report",
            successCriteria: "All assigned problems attempted, key equations applied correctly with work shown, and solutions documented and ready for submission",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "moon.stars.fill",
            task: "Study for an astronomy exam or analyze observational data",
            successCriteria: "Target concepts reviewed, key physical principles summarized, and at least 20 practice problems or data questions completed with corrections noted",
            preferredDuration: 60 * 60
        ),
        // Mathematics (Pure Math / Proofs)
        SuggestedTemplate(
            icon: "function",
            task: "Write or revise a mathematical proof",
            successCriteria: "Target theorem identified, proof strategy outlined, complete formal proof written in correct notation, and at least one alternative approach considered",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "sum",
            task: "Complete a mathematics problem set or number theory assignment",
            successCriteria: "All assigned problems attempted with full work shown, key theorems applied correctly, and solutions written in proper mathematical notation and ready for submission",
            preferredDuration: 60 * 60
        ),
        // Linguistics
        SuggestedTemplate(
            icon: "text.bubble.fill",
            task: "Write a linguistics analysis paper or phonetics assignment",
            successCriteria: "Target language phenomenon analyzed with key evidence identified, written analysis completed with proper linguistic notation and citations, and saved for submission",
            preferredDuration: 45 * 60
        ),
        SuggestedTemplate(
            icon: "character.book.closed.fill",
            task: "Study for a linguistics exam or work through a discourse analysis",
            successCriteria: "Key frameworks and terminology reviewed, target corpus or text analyzed, and study guide or analytical notes completed and saved",
            preferredDuration: 60 * 60
        ),
        // Art History
        SuggestedTemplate(
            icon: "paintpalette.fill",
            task: "Write an art history essay or art criticism paper",
            successCriteria: "Target artwork or period analyzed with historical context, stylistic features, and theoretical framework addressed; essay draft written with clear argument and saved for revision",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "photo.artframe",
            task: "Study for an art history exam or review a major art movement",
            successCriteria: "Key artists, works, and periods reviewed, art movement characteristics summarized, and at least 20 identification or short-answer practice questions completed with corrections",
            preferredDuration: 60 * 60
        ),
        // Marine Biology / Oceanography
        SuggestedTemplate(
            icon: "fish.fill",
            task: "Write a marine biology lab report or oceanography assignment",
            successCriteria: "Experimental data or field observations analyzed, key findings interpreted with supporting evidence, and full lab report written with methods and conclusions saved for submission",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "water.waves",
            task: "Study for a marine biology or oceanography exam",
            successCriteria: "Target content area reviewed, key species, ecosystems, or oceanographic processes summarized, and at least 20 practice questions completed with corrections noted",
            preferredDuration: 60 * 60
        ),
        // Speech Arts / Debate
        SuggestedTemplate(
            icon: "mic.fill",
            task: "Prep a debate case or speech tournament argument",
            successCriteria: "Core argument structured with evidence blocks, rebuttals drafted for likely counter-arguments, and full case flow written and ready for practice round",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "person.wave.2.fill",
            task: "Prepare for a Model UN conference or public speaking competition",
            successCriteria: "Research completed, position paper or speech outline finalized, key talking points memorized, and at least one full run-through of the speech or opening statement completed",
            preferredDuration: 60 * 60
        ),
        // Forensic Science
        SuggestedTemplate(
            icon: "magnifyingglass",
            task: "Complete a forensic science lab report or crime scene analysis",
            successCriteria: "Evidence samples or scenarios analyzed using correct forensic procedures, findings documented with supporting data, and full lab report written and ready for submission",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "flask.fill",
            task: "Study for a forensic science exam or FEPAC certification prep",
            successCriteria: "Target forensic discipline reviewed (biology, chemistry, or toxicology), key procedures and case law summarized, and at least 20 practice questions completed with corrections noted",
            preferredDuration: 60 * 60
        ),
        // Accounting
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Complete an accounting homework assignment or problem set",
            successCriteria: "All assigned journal entries, ledger postings, or financial statement problems completed with work shown, reconciled to correct balances, and saved for submission",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "chart.bar.doc.horizontal.fill",
            task: "Study for the CMA exam or an accounting course exam",
            successCriteria: "Target content area reviewed (financial reporting, management accounting, or cost analysis), key frameworks summarized, and at least 20 practice questions completed with corrections noted",
            preferredDuration: 90 * 60
        ),
        // Sports Management
        SuggestedTemplate(
            icon: "trophy.fill",
            task: "Write a sports management case study or strategic analysis",
            successCriteria: "Target sports organization or scenario analyzed, key strategic recommendations drafted with supporting evidence, and case write-up completed and saved for submission",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "sportscourt.fill",
            task: "Study for a sports management or sports marketing exam",
            successCriteria: "Key frameworks reviewed (sports finance, marketing mix, or event management), key concepts summarized, and at least 20 practice questions completed with corrections noted",
            preferredDuration: 60 * 60
        ),
        // Art Restoration / Conservation
        SuggestedTemplate(
            icon: "paintbrush.pointed.fill",
            task: "Write a conservation treatment report or condition assessment",
            successCriteria: "Artwork condition documented with observations noted, proposed treatment plan written with materials and methods justified, and report completed and saved for review",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "building.columns.fill",
            task: "Study for an art conservation exam or conservation science coursework",
            successCriteria: "Target conservation discipline reviewed (paintings, works on paper, or preventive care), key materials and treatment methods summarized, and at least 20 practice questions completed",
            preferredDuration: 60 * 60
        ),
        // Computational Science
        SuggestedTemplate(
            icon: "cpu.fill",
            task: "Write or debug a scientific simulation or HPC program",
            successCriteria: "Target simulation coded or debugged, job submitted to scheduler or run locally, output verified against expected results, and code with comments saved to repository",
            preferredDuration: 90 * 60
        ),
        SuggestedTemplate(
            icon: "waveform.path",
            task: "Complete a computational science problem set or numerical methods assignment",
            successCriteria: "All assigned algorithms implemented or analyzed, numerical results validated with error estimates, and solutions written up with code and figures saved for submission",
            preferredDuration: 60 * 60
        ),
        // Forensic Psychology
        SuggestedTemplate(
            icon: "person.crop.rectangle.fill",
            task: "Write a forensic psychological assessment report or case notes",
            successCriteria: "Assessment data organized and interpreted, key findings documented with relevant legal standards addressed, and full report written in professional format and saved for review",
            preferredDuration: 45 * 60
        ),
        SuggestedTemplate(
            icon: "brain.head.profile",
            task: "Study for the EPPP exam or forensic psychology coursework",
            successCriteria: "Target content area reviewed (criminal behavior, legal standards, or assessment methods), key concepts and case law summarized, and at least 20 practice questions completed with corrections",
            preferredDuration: 90 * 60
        ),
        // Geospatial Science
        SuggestedTemplate(
            icon: "map.fill",
            task: "Complete a GIS analysis or spatial data project",
            successCriteria: "Spatial layers loaded and processed in GIS software, analysis run and results validated, map or output exported in required format and saved to project folder",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "globe.americas.fill",
            task: "Study for the GISP exam or complete a geospatial science assignment",
            successCriteria: "Target topic reviewed (remote sensing, spatial analysis, or cartography), key concepts summarized with examples, and at least one practice exercise or problem set completed",
            preferredDuration: 60 * 60
        ),
        // Fashion Design
        SuggestedTemplate(
            icon: "scissors",
            task: "Sketch a fashion collection or draft garment patterns for a design project",
            successCriteria: "At least three complete design sketches or one garment pattern drafted, construction notes annotated, and designs photographed or digitized and saved to portfolio folder",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "tag.fill",
            task: "Study for a fashion design exam or complete a fashion merchandising assignment",
            successCriteria: "Target content reviewed (fashion history, textiles, or merchandising principles), key terminology summarized, and assignment written or study notes compiled and saved",
            preferredDuration: 45 * 60
        ),
        // Hospitality Management
        SuggestedTemplate(
            icon: "building.2.fill",
            task: "Complete a hospitality management case study or hotel operations assignment",
            successCriteria: "Case scenario analyzed, key issues identified, recommendations written with supporting rationale, and final report formatted and saved for submission",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "star.fill",
            task: "Study for a hospitality or tourism management exam",
            successCriteria: "Target chapters reviewed and summarized, key concepts and industry terminology noted, and at least one set of practice questions or self-quizzes completed",
            preferredDuration: 60 * 60
        ),
        // Sports Analytics
        SuggestedTemplate(
            icon: "chart.bar.fill",
            task: "Build a sports analytics model or analyze player performance data",
            successCriteria: "Dataset cleaned and loaded, analysis pipeline coded and run, key metrics calculated and visualized, and findings summarized with interpretation saved to notebook or report",
            preferredDuration: 90 * 60
        ),
        SuggestedTemplate(
            icon: "sportscourt.fill",
            task: "Complete a sports analytics assignment or sabermetrics problem set",
            successCriteria: "All assigned problems or analyses completed, statistical methods applied correctly, results interpreted in sports context, and work saved for submission",
            preferredDuration: 60 * 60
        ),
        // Emergency Management
        SuggestedTemplate(
            icon: "exclamationmark.triangle.fill",
            task: "Write an emergency management plan or disaster response protocol",
            successCriteria: "Hazard scenarios identified, response procedures drafted with roles and resources defined, plan reviewed against relevant standards (ICS/FEMA), and document saved for submission or review",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "shield.fill",
            task: "Study for FEMA certification or an emergency management course exam",
            successCriteria: "Target content area reviewed (incident command, hazard mitigation, or disaster recovery), key concepts and frameworks summarized, and at least 20 practice questions completed with corrections",
            preferredDuration: 60 * 60
        ),
        // Aviation
        SuggestedTemplate(
            icon: "airplane",
            task: "Study for the FAA private pilot written exam",
            successCriteria: "Target knowledge area reviewed (weather, regulations, navigation, or aircraft systems), key concepts summarized, and at least 30 practice questions completed with incorrect answers corrected and understood",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "cloud.sun.fill",
            task: "Complete a ground school lesson or aviation training assignment",
            successCriteria: "Assigned lesson or module completed, notes taken on key concepts (airspace, aerodynamics, or flight planning), and review quiz or self-check passed with at least 80% accuracy",
            preferredDuration: 45 * 60
        ),
        // Product Design
        SuggestedTemplate(
            icon: "cube.fill",
            task: "Sketch concepts and develop a product design proposal",
            successCriteria: "At least five concept sketches completed, one direction selected and refined with annotated orthographic views, and design rationale written and saved to project folder",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "ruler.fill",
            task: "Build or refine a physical or digital prototype for my product design project",
            successCriteria: "Prototype built or model iterated in CAD or foam, key ergonomic and functional issues documented, and revised design photographed or exported and saved for critique",
            preferredDuration: 90 * 60
        ),
        // Tax Preparation
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Complete and file my tax return",
            successCriteria: "All income documents gathered and entered, deductions and credits reviewed, return reviewed for accuracy, and either filed electronically with confirmation number saved or exported for review by preparer",
            preferredDuration: 90 * 60
        ),
        SuggestedTemplate(
            icon: "briefcase.fill",
            task: "Study for the EA (Enrolled Agent) exam or complete a tax preparation assignment",
            successCriteria: "Target section reviewed (individual taxation, business taxation, or representation), key rules and limits summarized, and at least 30 practice questions completed with corrections",
            preferredDuration: 60 * 60
        ),
        // Medical Billing and Coding
        SuggestedTemplate(
            icon: "cross.case.fill",
            task: "Practice medical coding with CPT and ICD-10 codes",
            successCriteria: "At least 20 coding scenarios completed, codes verified against official codebook guidelines, accuracy rate calculated, and errors reviewed with correct code rationale noted",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "checklist",
            task: "Study for the CPC exam or complete a medical billing and coding assignment",
            successCriteria: "Target chapter or code section reviewed, key guidelines and conventions summarized, and at least one full practice exercise or mock scenario set completed and graded",
            preferredDuration: 60 * 60
        ),
        // Military Studies
        SuggestedTemplate(
            icon: "shield.lefthalf.filled",
            task: "Write a military history paper or defense studies analysis",
            successCriteria: "Thesis clearly stated, primary and secondary sources cited and integrated, argument developed across all body sections, and paper completed and saved in final draft format for review",
            preferredDuration: 90 * 60
        ),
        SuggestedTemplate(
            icon: "star.circle.fill",
            task: "Study for the ASVAB or complete a military science / ROTC assignment",
            successCriteria: "Target ASVAB section or ROTC topic reviewed, key concepts summarized, and at least 30 practice questions completed with corrections and weak areas identified for further review",
            preferredDuration: 60 * 60
        ),
    ]
}
