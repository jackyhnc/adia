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
        // Supply Chain
        SuggestedTemplate(
            icon: "shippingbox.fill",
            task: "Complete a supply chain management assignment or logistics case study",
            successCriteria: "Assigned scenarios analyzed, supply chain flows mapped or procurement strategies outlined, supporting calculations completed, and work saved in final draft format for submission",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "chart.bar.doc.horizontal.fill",
            task: "Study for the CPIM or CSCP supply chain certification exam",
            successCriteria: "Target module reviewed (planning, procurement, or logistics), key concepts and frameworks summarized, and at least 25 practice questions completed with incorrect answers corrected and understood",
            preferredDuration: 60 * 60
        ),
        // Communication Studies
        SuggestedTemplate(
            icon: "bubble.left.and.bubble.right.fill",
            task: "Write a communication theory paper or research assignment",
            successCriteria: "Thesis or research question clearly stated, relevant theories and studies cited, argument developed across body sections, and paper completed and saved in final draft format for review",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "text.bubble.fill",
            task: "Study for a communication studies exam or complete a comm assignment",
            successCriteria: "Target content reviewed (interpersonal, mass communication, or rhetoric), key concepts and theorists summarized, and at least 20 practice questions or review exercises completed with corrections",
            preferredDuration: 45 * 60
        ),
        // Healthcare Administration
        SuggestedTemplate(
            icon: "cross.vial.fill",
            task: "Complete a healthcare administration case study or health informatics assignment",
            successCriteria: "Patient flow, revenue cycle, or EHR scenario analyzed and documented, policy recommendations or workflow improvements outlined, and completed work saved for submission",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "stethoscope",
            task: "Study for the RHIA, RHIT, or health information management certification exam",
            successCriteria: "Target domain reviewed (health data management, coding, or compliance), key regulations and standards summarized, and at least 30 practice questions completed with corrections",
            preferredDuration: 60 * 60
        ),
        // Neuroscience
        SuggestedTemplate(
            icon: "brain.head.profile",
            task: "Write a neuroscience paper or complete a neuro assignment",
            successCriteria: "Thesis stated, neuroscientific evidence cited from at least three peer-reviewed sources, argument developed across body sections, and paper saved in final draft format for review",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "brain",
            task: "Study for a neuroscience or neuroanatomy exam",
            successCriteria: "Target brain regions or neural systems reviewed, key pathways and functions summarized, and at least 25 practice questions or diagram labeling exercises completed with corrections",
            preferredDuration: 60 * 60
        ),
        // Ethnic Studies
        SuggestedTemplate(
            icon: "person.3.fill",
            task: "Write an ethnic studies, gender studies, or women's studies research paper",
            successCriteria: "Research question clearly stated, relevant theoretical frameworks applied, primary and secondary sources cited, argument developed across body sections, and paper saved in final draft format for review",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "globe.americas.fill",
            task: "Study for an ethnic studies, cultural studies, or gender studies exam",
            successCriteria: "Target unit reviewed (critical race theory, intersectionality, feminist theory, or postcolonial studies), key theorists and concepts summarized, and at least 20 review questions or discussion prompts completed",
            preferredDuration: 45 * 60
        ),
        // Human Factors / Ergonomics
        SuggestedTemplate(
            icon: "person.and.background.dotted",
            task: "Complete a human factors engineering assignment or ergonomics assessment",
            successCriteria: "Task analysis or workstation assessment completed, human factors principles applied, findings documented with recommendations, and report written and saved for submission",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "figure.stand.line.dotted.figure.stand",
            task: "Study for the BCPE exam or complete a human factors course assignment",
            successCriteria: "Target content area reviewed (biomechanics, cognitive ergonomics, or systems design), key principles summarized, and at least 20 practice questions or application exercises completed with corrections",
            preferredDuration: 60 * 60
        ),
        // Behavioral Economics
        SuggestedTemplate(
            icon: "brain",
            task: "Write a behavioral economics analysis or research paper",
            successCriteria: "Research question clearly stated, key cognitive biases or behavioral mechanisms identified and explained, relevant studies cited, argument developed across body sections, and paper saved in final draft format for review",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "chart.line.uptrend.xyaxis",
            task: "Study for a behavioral economics exam or complete a behavioral science assignment",
            successCriteria: "Target concepts reviewed (nudge theory, prospect theory, or cognitive biases), key theorists and frameworks summarized, and at least 20 practice questions or application examples completed with corrections",
            preferredDuration: 45 * 60
        ),
        // Translational Research
        SuggestedTemplate(
            icon: "flask.fill",
            task: "Write a translational research proposal or bench-to-bedside project plan",
            successCriteria: "Research question framed in translational context (T1–T4), gap in knowledge identified, methodology and translation pathway outlined, and proposal draft completed and saved for review",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "cross.vial.fill",
            task: "Analyze translational research data or complete a clinical translation assignment",
            successCriteria: "Dataset or study analyzed using appropriate methods, findings interpreted in clinical context, key implications for patient care identified, and analysis written up and saved for review",
            preferredDuration: 60 * 60
        ),
        // Healthcare Law
        SuggestedTemplate(
            icon: "cross.case.fill",
            task: "Write a healthcare law memo or bioethics analysis",
            successCriteria: "Legal issue identified and framed, relevant statutes and regulations cited (HIPAA, ACA, or state law), argument developed with counterarguments addressed, and memo or analysis saved in final format for review",
            preferredDuration: 45 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Study for a health law exam or complete a healthcare regulation assignment",
            successCriteria: "Target content area reviewed (patient rights, HIPAA, Medicare, or medical malpractice), key cases and regulations summarized, and at least 20 practice questions completed with corrections",
            preferredDuration: 60 * 60
        ),
        // International Trade Law
        SuggestedTemplate(
            icon: "globe.americas.fill",
            task: "Write an international trade law brief or comparative law analysis",
            successCriteria: "Trade dispute or regulatory issue identified, relevant WTO rules or treaty provisions cited, argument structured with supporting cases, and brief or analysis completed and saved for review",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "building.columns.fill",
            task: "Study for an international law exam or complete a trade compliance assignment",
            successCriteria: "Target international law topic reviewed (trade law, treaty interpretation, or international arbitration), key frameworks and case law summarized, and at least 20 practice questions completed with corrections",
            preferredDuration: 60 * 60
        ),
        // Cosmetology
        SuggestedTemplate(
            icon: "scissors",
            task: "Study for my cosmetology state board exam",
            successCriteria: "Target content area reviewed (hair coloring, chemical services, or skin care), key techniques and safety procedures summarized, and at least 20 practice questions completed with corrections",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "sparkles",
            task: "Practice and review esthetics or nail tech techniques for class",
            successCriteria: "Target skill reviewed (waxing, facials, nail art, or manicure/pedicure), technique steps outlined and practiced on reference materials, and class assignment or lab prep completed",
            preferredDuration: 45 * 60
        ),
        // Personal Training
        SuggestedTemplate(
            icon: "figure.strengthtraining.traditional",
            task: "Study for the NASM or ACE personal training certification exam",
            successCriteria: "Target chapter reviewed (anatomy, exercise science, or program design), key concepts and terminology summarized, and at least 25 practice questions completed with corrections",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Design a client training program for my personal training practicum",
            successCriteria: "Client needs assessment completed, periodization model selected, weekly program outlined with sets/reps/intensity, and program saved in shareable format for review",
            preferredDuration: 45 * 60
        ),
        // Dental Lab
        SuggestedTemplate(
            icon: "cross.case.fill",
            task: "Study for the NBDALE or complete a dental laboratory assignment",
            successCriteria: "Target content area reviewed (crown-and-bridge, ceramics, or removable prosthodontics), key fabrication steps summarized, and at least 20 practice questions completed with corrections",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "waveform.path.ecg",
            task: "Complete a dental ceramics or crown-and-bridge lab project",
            successCriteria: "Lab procedure followed step-by-step, fabrication notes completed and documented, and finished project photographed or submitted for instructor review",
            preferredDuration: 90 * 60
        ),
        // Landscape Architecture
        SuggestedTemplate(
            icon: "leaf.fill",
            task: "Develop a planting plan or site design for my landscape architecture project",
            successCriteria: "Site analysis completed, plant palette selected with species and spacing, grading and hardscape elements noted, and design drawing or digital model saved for review",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "mountain.2.fill",
            task: "Study for the CLARB exam or complete a landscape architecture assignment",
            successCriteria: "Target content area reviewed (site design, grading, or environmental systems), key principles and standards summarized, and at least 20 practice questions completed with corrections",
            preferredDuration: 60 * 60
        ),
        // Immigration Law
        SuggestedTemplate(
            icon: "globe.americas.fill",
            task: "Prepare a visa petition or immigration case brief",
            successCriteria: "Client facts and immigration history documented, applicable visa category identified with statutory basis, supporting evidence outlined, and petition or brief drafted and saved for review",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "doc.fill",
            task: "Study for an immigration law exam or complete an immigration law assignment",
            successCriteria: "Target topic reviewed (asylum law, visa procedures, removal defense, or naturalization), key cases and regulations summarized, and at least 20 practice questions completed with corrections",
            preferredDuration: 60 * 60
        ),
        // Music Education
        SuggestedTemplate(
            icon: "music.note",
            task: "Write a lesson plan or unit plan for music class",
            successCriteria: "Lesson objectives aligned to standards, instructional sequence outlined with timing, materials and repertoire listed, and completed plan saved for supervisor or cooperating teacher review",
            preferredDuration: 45 * 60
        ),
        SuggestedTemplate(
            icon: "graduationcap.fill",
            task: "Study for the Praxis music education exam or complete a music methods assignment",
            successCriteria: "Target content area reviewed (music history, theory, pedagogy, or conducting), key concepts summarized, and at least 25 practice questions completed with corrections",
            preferredDuration: 60 * 60
        ),
        // Massage Therapy
        SuggestedTemplate(
            icon: "hand.raised.fill",
            task: "Study for the MBLEx or massage therapy state board exam",
            successCriteria: "Target content area reviewed (anatomy, kinesiology, pathology, or ethics), key concepts and contraindications summarized, and at least 25 practice questions completed with corrections",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Complete my massage therapy coursework or practice session notes",
            successCriteria: "Assigned readings finished and notes taken, technique steps reviewed or documented, and assignment or session notes submitted or saved for review",
            preferredDuration: 45 * 60
        ),
        // Medical Laboratory Science
        SuggestedTemplate(
            icon: "cross.vial.fill",
            task: "Study for the ASCP or medical laboratory science board exam",
            successCriteria: "Target content area reviewed (hematology, microbiology, blood bank, or clinical chemistry), key procedures and reference ranges summarized, and at least 25 practice questions completed with corrections",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "waveform.path.ecg",
            task: "Complete a clinical laboratory science lab report or coursework",
            successCriteria: "Lab procedure followed and observations recorded, results calculated and interpreted, report drafted with discussion of normal vs. abnormal findings, and saved for submission",
            preferredDuration: 45 * 60
        ),
        // Radiologic Technology
        SuggestedTemplate(
            icon: "rays",
            task: "Study for the ARRT or radiologic technology certification exam",
            successCriteria: "Target content area reviewed (patient care, image production, or radiation protection), key positioning concepts and technical factors summarized, and at least 25 practice questions completed with corrections",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Complete my radiographic positioning or diagnostic imaging coursework",
            successCriteria: "Assigned positioning chapter reviewed, landmark identification and projections noted, practice positioning scenarios worked through, and assignment or study notes saved for review",
            preferredDuration: 45 * 60
        ),
        // Intellectual Property Law
        SuggestedTemplate(
            icon: "lock.doc.fill",
            task: "Draft a patent application or IP litigation brief",
            successCriteria: "Invention disclosure or case facts organized, claims drafted or arguments outlined with relevant statutes and case law, draft reviewed for completeness, and saved for attorney or supervisor review",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "doc.badge.gearshape",
            task: "Study for the patent bar exam or complete an intellectual property law assignment",
            successCriteria: "Target MPEP chapter or IP topic reviewed, key rules and case holdings summarized, and at least 25 practice questions completed with corrections",
            preferredDuration: 90 * 60
        ),
        // Sign Language / ASL
        SuggestedTemplate(
            icon: "hand.wave.fill",
            task: "Practice ASL vocabulary and sign language skills",
            successCriteria: "Target vocabulary set drilled with at least 85% accuracy, handshape and movement notes reviewed, and practice session logged or recorded for self-review",
            preferredDuration: 30 * 60
        ),
        SuggestedTemplate(
            icon: "graduationcap.fill",
            task: "Study for an ASL or sign language exam or complete a sign language assignment",
            successCriteria: "Target content area reviewed (grammar, vocabulary, Deaf culture, or interpreting), key concepts summarized, and assignment or practice sentences completed and saved",
            preferredDuration: 45 * 60
        ),
        // Acupuncture / TCM
        SuggestedTemplate(
            icon: "staroflife.fill",
            task: "Study acupuncture points or TCM theory for class or board prep",
            successCriteria: "Target meridian or TCM topic reviewed (channel pathways, point locations, herbal formulas, or diagnostic theory), key points summarized, and at least 20 practice questions completed with corrections",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Complete an acupuncture or traditional Chinese medicine school assignment",
            successCriteria: "Assigned readings finished and notes taken, case study or theory questions answered, and assignment saved or submitted for review",
            preferredDuration: 45 * 60
        ),
        // Art Education
        SuggestedTemplate(
            icon: "paintpalette.fill",
            task: "Write an art lesson plan or unit plan for visual arts class",
            successCriteria: "Lesson objectives aligned to standards, materials and media listed, instructional sequence outlined with timing, and completed plan saved for cooperating teacher or supervisor review",
            preferredDuration: 45 * 60
        ),
        SuggestedTemplate(
            icon: "graduationcap.fill",
            task: "Study for the Praxis art education exam or complete an art methods assignment",
            successCriteria: "Target content area reviewed (art history, studio media, pedagogy, or assessment), key concepts summarized, and at least 20 practice questions completed with corrections",
            preferredDuration: 60 * 60
        ),
        // Environmental Law
        SuggestedTemplate(
            icon: "leaf.fill",
            task: "Write an environmental law brief or policy analysis",
            successCriteria: "Relevant statute or regulation identified (NEPA, Clean Air Act, Clean Water Act, or Superfund), legal argument outlined with supporting case law, draft completed, and saved for review",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.magnifyingglass",
            task: "Study for an environmental law exam or complete an environmental regulation assignment",
            successCriteria: "Target statute or topic reviewed, key provisions and landmark cases summarized, and at least 20 practice questions completed with corrections",
            preferredDuration: 60 * 60
        ),
        // Family Law
        SuggestedTemplate(
            icon: "house.fill",
            task: "Draft a family law brief or domestic relations memo",
            successCriteria: "Relevant facts organized, applicable statutes and case law identified (divorce, custody, adoption, or support), legal argument drafted, and saved for attorney or supervisor review",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "doc.fill",
            task: "Study for a family law exam or complete a domestic relations assignment",
            successCriteria: "Target topic reviewed (divorce, custody, child support, adoption, or parental rights), key rules and cases summarized, and at least 20 practice questions completed with corrections",
            preferredDuration: 60 * 60
        ),
        // Nuclear Medicine Technology
        SuggestedTemplate(
            icon: "atom",
            task: "Study nuclear medicine imaging protocols or prepare for the CNMT board exam",
            successCriteria: "Target imaging protocol or body system reviewed (PET, SPECT, thyroid, bone scan, or cardiac), radiopharmaceuticals and patient prep summarized, and at least 20 practice questions completed with corrections",
            preferredDuration: 90 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Complete a nuclear medicine technology school assignment or patient imaging report",
            successCriteria: "Assigned content reviewed (imaging protocol, radiopharmacy, or radiation safety), questions answered, and assignment saved or submitted for review",
            preferredDuration: 45 * 60
        ),
        // Diagnostic Medical Sonography
        SuggestedTemplate(
            icon: "waveform.path.ecg",
            task: "Study for the ARDMS registry exam or review sonography scanning techniques",
            successCriteria: "Target anatomy or scanning protocol reviewed (abdominal, OB, vascular, or cardiac), key sonographic findings summarized, and at least 20 practice questions completed with corrections",
            preferredDuration: 90 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Complete a diagnostic medical sonography school assignment or imaging lab report",
            successCriteria: "Assigned scanning topic reviewed, sonographic anatomy and pathology notes written, and assignment saved or submitted for instructor review",
            preferredDuration: 45 * 60
        ),
        // Cardiovascular Technology
        SuggestedTemplate(
            icon: "heart.fill",
            task: "Study for the CCI board exam or review cardiac catheterization lab procedures",
            successCriteria: "Target procedure or cardiology topic reviewed (cardiac cath, echo, EKG, or hemodynamics), key concepts and normal values summarized, and at least 20 practice questions completed with corrections",
            preferredDuration: 90 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Complete a cardiovascular technology school assignment or cardiac imaging report",
            successCriteria: "Assigned cardiology topic reviewed, procedure steps and documentation requirements outlined, and assignment saved or submitted for review",
            preferredDuration: 45 * 60
        ),
        // Surgical Technology
        SuggestedTemplate(
            icon: "cross.case.fill",
            task: "Study surgical instrumentation and sterile field techniques for the CST exam",
            successCriteria: "Target surgical specialty reviewed (general, ortho, OB, or neuro), instrument names and uses memorized, sterile field principles reviewed, and at least 20 practice questions completed with corrections",
            preferredDuration: 90 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Complete a surgical technology school assignment or surgical case study",
            successCriteria: "Assigned surgical topic reviewed (instrumentation, anatomy, or procedure steps), case study questions answered, and assignment saved or submitted for instructor review",
            preferredDuration: 45 * 60
        ),
        // Art Therapy
        SuggestedTemplate(
            icon: "paintbrush.fill",
            task: "Write art therapy session notes or a treatment plan for a client case",
            successCriteria: "Client goals and art directives documented, session observations and responses recorded, progress toward therapeutic goals assessed, and notes saved in the appropriate format",
            preferredDuration: 30 * 60
        ),
        SuggestedTemplate(
            icon: "graduationcap.fill",
            task: "Study for the ATR board exam or complete an art therapy school assignment",
            successCriteria: "Target content area reviewed (art therapy theory, assessment tools, ethics, or population-specific approaches), key concepts summarized, and at least 20 practice questions completed with corrections",
            preferredDuration: 60 * 60
        ),
        // Polysomnography
        SuggestedTemplate(
            icon: "moon.fill",
            task: "Study sleep scoring and polysomnography protocols or prepare for the RPSGT exam",
            successCriteria: "Target sleep stage or disorder reviewed (REM, NREM, apnea, arousal index), EEG/EOG/EMG scoring rules summarized, and at least 20 practice questions completed with corrections",
            preferredDuration: 90 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Complete a polysomnography school assignment or sleep study case report",
            successCriteria: "Assigned PSG topic reviewed (sleep staging, equipment setup, or patient preparation), case questions answered, and assignment saved or submitted for instructor review",
            preferredDuration: 45 * 60
        ),
        // Nursing Informatics
        SuggestedTemplate(
            icon: "network",
            task: "Complete a nursing informatics assignment or EHR implementation case study",
            successCriteria: "Assigned informatics topic reviewed (EHR workflow, clinical decision support, or health data standards), analysis written, and assignment saved or submitted for review",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "graduationcap.fill",
            task: "Study for a nursing informatics exam or clinical informatics certification",
            successCriteria: "Target content area reviewed (nursing terminology, EHR systems, data governance, or informatics theory), key standards summarized, and at least 20 practice questions completed with corrections",
            preferredDuration: 60 * 60
        ),
        // Music Therapy
        SuggestedTemplate(
            icon: "music.note",
            task: "Write music therapy session notes or a treatment plan for a client case",
            successCriteria: "Client goals and music interventions documented, session observations and responses recorded, progress toward therapeutic outcomes assessed, and notes saved in the appropriate format",
            preferredDuration: 30 * 60
        ),
        SuggestedTemplate(
            icon: "graduationcap.fill",
            task: "Study for the MT-BC board exam or complete a music therapy school assignment",
            successCriteria: "Target content area reviewed (music therapy theory, clinical populations, assessment tools, or ethics), key concepts summarized, and at least 20 practice questions completed with corrections",
            preferredDuration: 60 * 60
        ),
        // Drama/Theatre Education
        SuggestedTemplate(
            icon: "theatermasks.fill",
            task: "Write a drama lesson plan or theatre education curriculum unit",
            successCriteria: "Learning objectives defined, theatre technique or dramatic literature chosen, activities and assessment plan written, and lesson plan saved or submitted for review",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Study for the Praxis drama exam or complete a playwriting or theatre history assignment",
            successCriteria: "Target topic reviewed (theatre history, playwriting craft, dramatic theory, or stage design), key concepts summarized, and assignment or practice questions completed with corrections",
            preferredDuration: 60 * 60
        ),
        // Wine Studies / Sommelier
        SuggestedTemplate(
            icon: "wineglass",
            task: "Study wine regions and varietals to prepare for a WSET or sommelier exam",
            successCriteria: "Target region or grape variety reviewed (flavor profile, growing conditions, key producers, and food pairings documented), and at least 20 practice questions completed with corrections",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "list.bullet.clipboard",
            task: "Practice blind tasting or complete a viticulture and enology coursework assignment",
            successCriteria: "Structured tasting notes written using the WSET or SAT framework for at least three wines, or assigned viticulture/enology topic reviewed and assignment saved for submission",
            preferredDuration: 45 * 60
        ),
        // Gerontology / Aging Studies
        SuggestedTemplate(
            icon: "person.crop.circle",
            task: "Complete a gerontology or aging studies assignment on social or biological aging",
            successCriteria: "Assigned aging topic reviewed (social gerontology, age-related disease, or geriatric care), analysis or response written, and assignment saved or submitted for instructor review",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "graduationcap.fill",
            task: "Study for a geriatrics exam or complete a gerontology course assignment",
            successCriteria: "Target content area reviewed (aging biology, dementia care, eldercare policy, or gerontological theory), key concepts summarized, and at least 20 practice questions completed with corrections",
            preferredDuration: 60 * 60
        ),
        // Addiction Counseling / Behavioral Health
        SuggestedTemplate(
            icon: "heart.text.square.fill",
            task: "Write addiction counseling session notes or a substance use disorder treatment plan",
            successCriteria: "Client substance use history and counseling goals documented, intervention strategies identified, progress assessed, and notes saved in appropriate format for instructor or supervisor review",
            preferredDuration: 30 * 60
        ),
        SuggestedTemplate(
            icon: "graduationcap.fill",
            task: "Study for the CADC, NAADAC, or addiction counseling certification exam",
            successCriteria: "Target content area reviewed (addiction theory, motivational interviewing, relapse prevention, or dual diagnosis), key concepts summarized, and at least 20 practice questions completed with corrections",
            preferredDuration: 60 * 60
        ),
        // Oral Surgery / OMFS
        SuggestedTemplate(
            icon: "cross.case.fill",
            task: "Study for an oral surgery exam or review OMFS procedures and techniques",
            successCriteria: "Target procedure or concept reviewed (orthognathic surgery, dentoalveolar surgery, impacted teeth, or implant surgery), key steps and anatomy summarized, and at least 15 practice questions completed with corrections",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Complete an oral surgery coursework assignment or case write-up",
            successCriteria: "Assigned oral surgery topic reviewed, case details or analysis documented, and assignment saved or submitted for instructor or supervisor review",
            preferredDuration: 45 * 60
        ),
        // Public Health Law
        SuggestedTemplate(
            icon: "doc.plaintext.fill",
            task: "Write a public health law memo or analyze a public health regulation",
            successCriteria: "Assigned public health law topic researched (quarantine law, FDA regulation, vaccine mandates, or food and drug law), analysis written with statutory and case references, and memo saved or submitted for review",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "graduationcap.fill",
            task: "Study for a public health law exam or complete a public health law assignment",
            successCriteria: "Target content area reviewed (public health statutes, regulatory agencies, infectious disease law, or global health law), key legal standards summarized, and assignment or practice questions completed with corrections",
            preferredDuration: 60 * 60
        ),
        // Diagnostic Medical Physics / Health Physics
        SuggestedTemplate(
            icon: "atom",
            task: "Study for the ABR medical physics board exam or complete a dosimetry assignment",
            successCriteria: "Target content area reviewed (radiation physics, dosimetry, or imaging systems), key formulas and concepts summarized, and at least 20 practice questions completed with corrections",
            preferredDuration: 90 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Complete a diagnostic medical physics or health physics coursework assignment",
            successCriteria: "Assigned radiation physics or dosimetry topic reviewed, analysis or problem set written, and assignment saved or submitted for instructor review",
            preferredDuration: 60 * 60
        ),
        // Perfusion Technology
        SuggestedTemplate(
            icon: "heart.fill",
            task: "Study for the PBSE or cardiovascular perfusion certification exam",
            successCriteria: "Target content reviewed (cardiopulmonary bypass, pump operation, or anticoagulation management), key concepts summarized, and at least 15 practice questions completed with corrections",
            preferredDuration: 90 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Complete a perfusion technology or cardiovascular perfusion school assignment",
            successCriteria: "Assigned bypass perfusion topic reviewed, case analysis or lab notes written, and assignment saved or submitted for instructor review",
            preferredDuration: 60 * 60
        ),
        // Ophthalmic Medical Technology
        SuggestedTemplate(
            icon: "eye.fill",
            task: "Study for the JCAHPO COT, COA, or COMT ophthalmic technology certification exam",
            successCriteria: "Target content reviewed (refraction, tonometry, visual fields, or ocular motility testing), key procedures summarized, and at least 20 practice questions completed with corrections",
            preferredDuration: 90 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Complete an ophthalmic medical technology school assignment or patient workup documentation",
            successCriteria: "Assigned ophthalmic procedure or topic reviewed, documentation or analysis written, and assignment saved or submitted for instructor review",
            preferredDuration: 45 * 60
        ),
        // Central Sterile Processing
        SuggestedTemplate(
            icon: "cross.case.fill",
            task: "Study for the CBSPD or CRCST central sterile processing certification exam",
            successCriteria: "Target content reviewed (sterilization methods, instrument decontamination, or quality control protocols), key standards summarized, and at least 20 practice questions completed with corrections",
            preferredDuration: 90 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Complete a central sterile processing school assignment or sterilization case study",
            successCriteria: "Assigned sterile processing topic reviewed (autoclave operation, tray assembly, or infection control), documentation written, and assignment saved or submitted for instructor review",
            preferredDuration: 45 * 60
        ),
        // Opticianry
        SuggestedTemplate(
            icon: "eyeglasses",
            task: "Study for the ABO-NCLE opticianry certification exam",
            successCriteria: "Target content reviewed (ophthalmic optics, contact lens, or dispensing regulations), key concepts summarized, and at least 20 practice questions completed with corrections",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Complete an opticianry school assignment or optical dispensing case study",
            successCriteria: "Assigned topic reviewed (lens prescription, frame selection, or spectacle dispensing), documentation or analysis written, and assignment saved or submitted for instructor review",
            preferredDuration: 45 * 60
        ),
        // Dance/Movement Therapy
        SuggestedTemplate(
            icon: "figure.walk",
            task: "Write dance therapy session notes or a treatment plan for a client case",
            successCriteria: "Session observations documented, movement interventions described, clinical rationale written, and notes or plan saved or submitted for supervisor review",
            preferredDuration: 30 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Study for the ADTA dance therapy board exam or complete a dance movement therapy assignment",
            successCriteria: "Target content reviewed (movement analysis, therapeutic process, or DMT theory), key concepts summarized, and at least one practice item completed with self-correction",
            preferredDuration: 60 * 60
        ),
        // Recreational Therapy
        SuggestedTemplate(
            icon: "figure.outdoor.cycle",
            task: "Write a therapeutic recreation treatment plan or recreation therapy session notes",
            successCriteria: "Client goals documented, leisure education or adaptive activity plan written, progress notes completed, and documentation saved or submitted for supervisor review",
            preferredDuration: 30 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Study for the CTRS exam or complete a recreational therapy school assignment",
            successCriteria: "Target content reviewed (therapeutic recreation process, ICF, or evidence-based practice), key concepts summarized, and at least 20 practice questions completed with corrections",
            preferredDuration: 60 * 60
        ),
        // Horticultural Therapy
        SuggestedTemplate(
            icon: "leaf.fill",
            task: "Write horticultural therapy session notes or a therapeutic horticulture program plan",
            successCriteria: "Session observations documented, plant-based interventions described, client goals addressed, and notes or plan saved or submitted for supervisor review",
            preferredDuration: 30 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Study for the HTR credential exam or complete a horticultural therapy school assignment",
            successCriteria: "Target content reviewed (therapeutic horticulture theory, program design, or population-specific techniques), key concepts summarized, and at least one practice item completed",
            preferredDuration: 60 * 60
        ),
        // Dietetic Technology
        SuggestedTemplate(
            icon: "fork.knife",
            task: "Study for the DTR exam or complete a dietetic technician school assignment",
            successCriteria: "Target content reviewed (nutrition screening, menu planning, or food service management), key concepts summarized, and at least 20 practice questions completed with corrections",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Complete a dietary analysis or nutrition screening assignment for dietetic technician class",
            successCriteria: "Assigned dietary intake or food service topic reviewed, analysis written, and assignment saved or submitted for instructor review",
            preferredDuration: 45 * 60
        ),
        // Occupational Medicine
        SuggestedTemplate(
            icon: "cross.case.fill",
            task: "Complete an occupational medicine case report or industrial hygiene assessment",
            successCriteria: "Assigned case or assessment written, occupational exposures or work-related conditions documented, relevant regulations or guidelines addressed, and report saved or submitted for instructor review",
            preferredDuration: 45 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Study for the ACOEM boards or complete an occupational medicine course assignment",
            successCriteria: "Target content reviewed (occupational disease, industrial hygiene, or workplace health), key concepts summarized, and at least one practice item or case completed",
            preferredDuration: 60 * 60
        ),
        // Integrative Medicine
        SuggestedTemplate(
            icon: "leaf.fill",
            task: "Write an integrative or functional medicine case study or patient case report",
            successCriteria: "Case study written, integrative treatment approach described, evidence reviewed, and report saved or submitted for instructor review",
            preferredDuration: 45 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Study for an integrative medicine board exam or complete a holistic health course assignment",
            successCriteria: "Target content reviewed (integrative modalities, CAM therapies, or functional medicine frameworks), key concepts summarized, and at least one practice question or case completed",
            preferredDuration: 60 * 60
        ),
        // Genetic Counseling
        SuggestedTemplate(
            icon: "dna",
            task: "Write a genetic counseling case report or variant interpretation summary",
            successCriteria: "Case summary written, variant classification or risk assessment documented, family history addressed, and report saved or submitted for supervisor review",
            preferredDuration: 30 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Study for the ABGC board or CGC exam or complete a genetic counseling school assignment",
            successCriteria: "Target content reviewed (inheritance patterns, variant interpretation, counseling skills, or ethical issues), key concepts summarized, and at least 20 practice questions completed",
            preferredDuration: 90 * 60
        ),
        // Behavioral Health Promotion
        SuggestedTemplate(
            icon: "heart.fill",
            task: "Design a health promotion program or write a community health education assignment",
            successCriteria: "Program design or assignment written, target population identified, behavioral theory applied, and work saved or submitted for instructor review",
            preferredDuration: 45 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Study for the CHES exam or complete a health education specialist certification assignment",
            successCriteria: "Target content reviewed (health behavior theories, program planning models, or community health worker competencies), key concepts summarized, and at least 20 practice questions completed with corrections",
            preferredDuration: 60 * 60
        ),
        // Dental Public Health
        SuggestedTemplate(
            icon: "cross.fill",
            task: "Write a dental public health analysis or oral health policy assignment",
            successCriteria: "Assigned topic analyzed, oral health disparities or community dental needs addressed, evidence cited, and paper saved or submitted for instructor review",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Study for the dental public health board exam or complete a community dentistry assignment",
            successCriteria: "Target content reviewed (dental epidemiology, oral health policy, or community program planning), key concepts summarized, and at least one practice item completed",
            preferredDuration: 60 * 60
        ),
        // Playwriting
        SuggestedTemplate(
            icon: "pencil",
            task: "Write or revise a scene or act for my stage play",
            successCriteria: "Target scene or act drafted or revised, dialogue and stage directions written, and pages saved in my playwriting software or document",
            preferredDuration: 45 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Outline or develop the structure of my one-act or full-length play",
            successCriteria: "Play outline or story structure developed, key scenes or beats mapped, character arcs sketched, and outline document saved for revision",
            preferredDuration: 30 * 60
        ),
        // Sports Medicine
        SuggestedTemplate(
            icon: "cross.case.fill",
            task: "Complete a sports medicine or athletic training clinical case report",
            successCriteria: "Assigned case or injury scenario documented, SOAP or HPOP notes written, relevant assessment findings recorded, and report saved or submitted for clinical supervisor review",
            preferredDuration: 45 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Study for the BOC exam or complete a sports medicine school assignment",
            successCriteria: "Target content reviewed (injury evaluation, rehabilitation, immediate care, or professional development), key concepts summarized, and at least 20 practice questions completed with corrections",
            preferredDuration: 60 * 60
        ),
        // Naturopathic Medicine
        SuggestedTemplate(
            icon: "leaf.fill",
            task: "Complete a naturopathic medicine assignment or botanical medicine case study",
            successCriteria: "Assigned topic completed (botanical materia medica, homeopathy case, or naturopathic treatment plan), key concepts documented, and work saved or submitted for instructor review",
            preferredDuration: 45 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Study for the NPLEX exam or naturopathic school board prep",
            successCriteria: "Target content reviewed (clinical sciences, naturopathic principles, botanical medicine, or homeopathy), key concepts summarized, and at least 20 practice questions completed with corrections",
            preferredDuration: 90 * 60
        ),
        // Midwifery
        SuggestedTemplate(
            icon: "heart.fill",
            task: "Write birth plans, prenatal notes, or postpartum charting for midwifery clinical",
            successCriteria: "Assigned documentation written (birth preferences, prenatal assessment, or postpartum visit notes), clinical details accurately recorded, and notes saved or submitted for preceptor review",
            preferredDuration: 30 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Study for the AMCB exam or complete a midwifery school assignment",
            successCriteria: "Target content reviewed (normal physiologic birth, prenatal care, postpartum care, or pharmacology), key concepts summarized, and at least 20 practice questions completed with corrections",
            preferredDuration: 90 * 60
        ),
        // Clinical Psychology
        SuggestedTemplate(
            icon: "brain.head.profile",
            task: "Write a neuropsychological or psychological assessment report",
            successCriteria: "Assessment report drafted, behavioral observations, test results, and clinical impressions documented, and report saved or submitted for supervisor review",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Work on my APPIC internship application or clinical psychology doctoral materials",
            successCriteria: "Target APPIC essays, cover letters, or application materials drafted or revised, and documents saved for review or submission",
            preferredDuration: 60 * 60
        ),
        // Theatre Sound
        SuggestedTemplate(
            icon: "waveform",
            task: "Study live sound engineering, FOH mixing, or audio tech program coursework",
            successCriteria: "Target audio tech or live sound content reviewed (signal flow, system gain structure, EQ, or mixing concepts), key concepts summarized, and notes saved",
            preferredDuration: 45 * 60
        ),
        SuggestedTemplate(
            icon: "speaker.wave.3.fill",
            task: "Complete a sound design or theatre audio assignment for class",
            successCriteria: "Assigned sound design documentation, mix notes, or audio tech assignment completed, and work submitted or saved for review",
            preferredDuration: 60 * 60
        ),
        // Dance Science
        SuggestedTemplate(
            icon: "figure.dance",
            task: "Complete a dance anatomy, dance kinesiology, or Laban Movement Analysis assignment",
            successCriteria: "Assigned movement analysis, anatomy content, or LMA observation completed, documented, and saved or submitted",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Study dance science concepts: somatic movement, dance biomechanics, or dance physiology",
            successCriteria: "Target content reviewed (somatic principles, injury prevention, or movement analysis methods), key concepts summarized, and notes saved",
            preferredDuration: 45 * 60
        ),
        // Forensic Nursing
        SuggestedTemplate(
            icon: "cross.case.fill",
            task: "Study for the SANE exam or complete a forensic nursing school assignment",
            successCriteria: "Target content reviewed (forensic evidence collection, documentation standards, or SANE competencies), key concepts summarized, and at least 15 practice questions completed with corrections",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Write forensic nursing case documentation or SANE patient encounter notes",
            successCriteria: "Forensic nursing encounter notes, injury documentation, or case write-up completed, reviewed for accuracy, and saved or submitted for supervisor review",
            preferredDuration: 30 * 60
        ),
        // Midwifery Assisting / Doula
        SuggestedTemplate(
            icon: "heart.fill",
            task: "Study for the DONA doula certification exam or complete a doula training assignment",
            successCriteria: "Target doula content reviewed (comfort measures, labor support, or postpartum care), key concepts summarized, and training assignment completed or practice questions answered",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Write a birth doula or postpartum doula reflection, care plan, or client support documentation",
            successCriteria: "Doula client documentation, birth reflection, or postpartum support plan written, reviewed for completeness, and saved for program submission or client file",
            preferredDuration: 30 * 60
        ),
        // Interpreting
        SuggestedTemplate(
            icon: "person.2.wave.2.fill",
            task: "Study for the RID interpreter certification exam or complete an interpreting program assignment",
            successCriteria: "Target interpreting content reviewed (consecutive or simultaneous techniques, ethical practice, or language pair concepts), key concepts summarized, and practice exercises completed",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Practice and document simultaneous or consecutive interpreting skills for my certification program",
            successCriteria: "Interpreting practice session completed (minimum 3 practice passages or recordings), performance notes documented, and areas for improvement identified and saved",
            preferredDuration: 45 * 60
        ),
        // Drama Therapy
        SuggestedTemplate(
            icon: "theatermasks.fill",
            task: "Write drama therapy session notes or a psychodrama treatment plan",
            successCriteria: "Drama therapy session documentation, psychodrama session write-up, or treatment plan completed, reviewed for completeness, and saved for supervisor review or program submission",
            preferredDuration: 30 * 60
        ),
        SuggestedTemplate(
            icon: "book.fill",
            task: "Study for the NADT drama therapy exam or complete a drama therapy coursework assignment",
            successCriteria: "Target drama therapy or psychodrama content reviewed (theory, methods, or techniques), key concepts summarized, and coursework assignment or practice questions completed",
            preferredDuration: 60 * 60
        ),
        // Horsemanship / Equestrian
        SuggestedTemplate(
            icon: "figure.equestrian.sports",
            task: "Complete an equestrian science or horsemanship coursework assignment",
            successCriteria: "Equestrian science or horsemanship assignment completed (horse management, equine nutrition, or riding technique analysis), key concepts documented, and work saved or submitted",
            preferredDuration: 45 * 60
        ),
        SuggestedTemplate(
            icon: "book.fill",
            task: "Study equine management, horse training theory, or dressage techniques for my equestrian program",
            successCriteria: "Target equestrian content reviewed (horse training methods, equine science, or riding discipline), key concepts summarized, and notes saved for exam or practical application",
            preferredDuration: 60 * 60
        ),
        // Glassblowing / Glass Arts
        SuggestedTemplate(
            icon: "flame.fill",
            task: "Plan and document a glassblowing or flameworking studio project",
            successCriteria: "Glass arts project plan or studio documentation completed (technique notes, design sketches, or process documentation), written portion saved or submitted for review",
            preferredDuration: 45 * 60
        ),
        SuggestedTemplate(
            icon: "book.fill",
            task: "Study glassblowing techniques, glass arts history, or kiln-formed glass methods for class",
            successCriteria: "Target glass arts content reviewed (hot glass techniques, kiln-formed methods, or studio safety), key concepts summarized, and notes saved for exam or studio application",
            preferredDuration: 30 * 60
        ),
        // Land Surveying Technology
        SuggestedTemplate(
            icon: "map.fill",
            task: "Complete a land surveying technology assignment or boundary survey problem set",
            successCriteria: "Survey calculations, boundary description, or lab assignment completed, work checked for accuracy, and solutions documented and saved or submitted",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "book.fill",
            task: "Study for the Fundamentals of Surveying (FS) exam or complete a land surveying program assignment",
            successCriteria: "Target surveying content reviewed (GPS/GNSS methods, traverse calculations, or property boundary law), key concepts summarized, and at least 15 practice problems completed with corrections",
            preferredDuration: 90 * 60
        ),
        // Environmental Engineering
        SuggestedTemplate(
            icon: "drop.fill",
            task: "Complete an environmental engineering assignment on wastewater treatment, water quality, or air quality control",
            successCriteria: "Environmental engineering problem set or lab report completed (wastewater design, pollutant transport, or air quality calculations), work checked for accuracy, and solutions saved or submitted",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "book.fill",
            task: "Study environmental engineering concepts: remediation, stormwater management, or environmental impact assessment",
            successCriteria: "Target environmental engineering content reviewed (remediation methods, stormwater design, or EIA process), key concepts summarized, and notes saved for exam or design application",
            preferredDuration: 45 * 60
        ),
        // Technical Writing
        SuggestedTemplate(
            icon: "doc.plaintext.fill",
            task: "Write or revise a user manual, API documentation, or technical guide for a software or product",
            successCriteria: "Technical document drafted or revised (user manual, API reference, or how-to guide), reviewed for clarity and accuracy, and saved or submitted to project repository",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "book.fill",
            task: "Study for the CPTC technical writing certification or complete a technical communication coursework assignment",
            successCriteria: "Target technical writing content reviewed (docs-as-code, user research, or information architecture), key concepts summarized, and assignment or practice exercises completed",
            preferredDuration: 45 * 60
        ),
        // Health Coaching
        SuggestedTemplate(
            icon: "heart.text.square.fill",
            task: "Study for the NBHWC health and wellness coaching certification exam",
            successCriteria: "Target NBHWC content reviewed (health behavior change models, motivational interviewing, or coaching competencies), key concepts summarized, and at least 10 practice questions completed with review",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Complete a health coaching coursework assignment or wellness coaching session documentation",
            successCriteria: "Health coaching assignment completed (behavior change plan, client coaching notes, or wellness assessment), reviewed for completeness, and saved or submitted for program review",
            preferredDuration: 45 * 60
        ),
        // Podiatry
        SuggestedTemplate(
            icon: "cross.fill",
            task: "Study for the APMLE podiatry board exam or complete a podiatric medicine school assignment",
            successCriteria: "Target podiatry content reviewed (foot anatomy, podiatric surgery, or APMLE practice questions), key concepts summarized, and at least 15 board-style questions completed with corrections",
            preferredDuration: 90 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Write up podiatric medicine case notes, a patient encounter summary, or a clinical rotation report",
            successCriteria: "Podiatry case documentation, SOAP note, or clinical rotation write-up completed, reviewed for completeness and accuracy, and saved for supervisor review or program submission",
            preferredDuration: 30 * 60
        ),
        // Classical Studies
        SuggestedTemplate(
            icon: "text.book.closed.fill",
            task: "Translate a Latin or ancient Greek passage and write a commentary or close reading",
            successCriteria: "Target passage translated (at least one paragraph of Latin or Greek), grammatical analysis completed, commentary written, and work saved or submitted for class",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "book.fill",
            task: "Study classical studies content: ancient history, classical literature, or classical archaeology for an exam or paper",
            successCriteria: "Target classical studies material reviewed (ancient Rome, ancient Greece, or classical literature), key themes and arguments summarized, and notes saved for exam or essay writing",
            preferredDuration: 45 * 60
        ),
        SuggestedTemplate(
            icon: "stethoscope",
            task: "Study for the ABPMR physiatry board exam or complete a PM&R residency assignment",
            successCriteria: "Target ABPMR board topics reviewed (spinal cord injury, TBI, musculoskeletal rehab, or electrodiagnostics), practice questions completed, and notes saved for next study session",
            preferredDuration: 90 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Write up PM&R patient case notes, a rehabilitation evaluation, or a physiatry SOAP note",
            successCriteria: "PM&R documentation completed (SOAP note, functional assessment, or rehabilitation plan written), clinical reasoning documented, and write-up saved or submitted",
            preferredDuration: 30 * 60
        ),
        SuggestedTemplate(
            icon: "fork.knife",
            task: "Study for the CSSD board exam or complete a sports dietetics or performance nutrition coursework assignment",
            successCriteria: "Target CSSD board topics reviewed (periodization, macronutrient timing, hydration protocols, or supplement evidence), practice questions completed, and notes saved",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "figure.run",
            task: "Design an athlete fueling plan or sports nutrition intervention for a team or client",
            successCriteria: "Athlete fueling plan drafted (pre/intra/post-workout protocols, hydration strategy, and race-day or competition nutrition outlined), plan reviewed, and document saved",
            preferredDuration: 45 * 60
        ),
        SuggestedTemplate(
            icon: "leaf.fill",
            task: "Complete my horticulture science assignment on plant physiology, pest management, or crop production",
            successCriteria: "Target horticulture science material covered (plant physiology, IPM, soil science, or crop systems), assignment questions answered, and work saved or submitted",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "tree.fill",
            task: "Study for the ISA arborist certification, PCA exam, or horticulture science licensing exam",
            successCriteria: "Target exam content reviewed (tree biology, pest identification, plant diagnostics, or horticulture science), practice questions completed, and notes saved for next session",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "globe",
            task: "Write an international development policy memo or NGO program proposal",
            successCriteria: "Policy memo or program proposal drafted (problem statement, theory of change, intervention design, and M&E framework outlined), document reviewed, and file saved",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "books.vertical.fill",
            task: "Study for a global health governance or international development exam",
            successCriteria: "Target international development material reviewed (SDGs, development economics, humanitarian frameworks, or global health governance), key concepts summarized, and notes saved",
            preferredDuration: 45 * 60
        ),
        SuggestedTemplate(
            icon: "sailboat.fill",
            task: "Study for the USCG licensing exam or complete a maritime studies coursework assignment",
            successCriteria: "Target maritime studies material reviewed (navigation, maritime law, STCW standards, or port management), practice questions completed, and notes saved for next session",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "ferry.fill",
            task: "Work on a maritime law, port management, or maritime transportation class project",
            successCriteria: "Maritime class project completed (case analysis, policy memo, or research paper drafted), argument or analysis documented, and work saved or submitted",
            preferredDuration: 45 * 60
        ),
        SuggestedTemplate(
            icon: "thermometer.and.liquid.waves",
            task: "Study for the EPA 608 HVAC certification exam or complete an HVAC technology coursework assignment",
            successCriteria: "Target EPA 608 or HVAC content reviewed (refrigerant types, recovery procedures, system components, or safety regulations), practice questions completed, and notes saved",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "wind",
            task: "Work through HVAC systems, refrigeration cycles, or air conditioning coursework for my trade program",
            successCriteria: "HVAC trade program assignment completed (system schematics reviewed, troubleshooting steps documented, or theory questions answered), and work saved or submitted",
            preferredDuration: 45 * 60
        ),
        SuggestedTemplate(
            icon: "building.2.fill",
            task: "Complete a construction management assignment on scheduling, estimating, or project planning",
            successCriteria: "Construction management assignment completed (project schedule drafted, cost estimate calculated, or project plan outlined), reasoning documented, and work saved or submitted",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "chart.bar.doc.horizontal",
            task: "Study for the CCM exam or work on a construction project management class project",
            successCriteria: "Target CCM board topics reviewed (project delivery methods, risk management, scheduling, or contract law), practice questions completed, and notes saved for next session",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "camera.macro",
            task: "Complete a floral design project or study for a floristry program exam",
            successCriteria: "Floral design assignment completed (arrangement plan sketched, technique documented, or exam material reviewed), work saved, and notes prepared for next session",
            preferredDuration: 45 * 60
        ),
        SuggestedTemplate(
            icon: "heart.fill",
            task: "Work on wedding planning coursework, a venue proposal, or an event floral design project",
            successCriteria: "Wedding planning or event floral assignment completed (proposal drafted, design plan sketched, or vendor coordination notes written), and work saved or submitted",
            preferredDuration: 45 * 60
        ),
        SuggestedTemplate(
            icon: "flask.fill",
            task: "Work through a cosmetic chemistry formulation assignment or skincare product development project",
            successCriteria: "Cosmetic chemistry assignment completed (formulation drafted, ingredient function documented, or emulsification procedure written), and work saved or submitted",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "testtube.2",
            task: "Study cosmetic science concepts: emulsification, preservation systems, or ingredient chemistry for an exam",
            successCriteria: "Target cosmetic science material reviewed (emulsion theory, preservative systems, surfactant chemistry, or raw material safety), practice questions completed, and notes saved",
            preferredDuration: 45 * 60
        ),
        SuggestedTemplate(
            icon: "car.fill",
            task: "Study for the ASE certification exam or complete an automotive technology coursework assignment",
            successCriteria: "Target ASE content reviewed (engine diagnostics, brake systems, electrical systems, or transmission), practice questions completed, and notes saved for next session",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "wrench.and.screwdriver.fill",
            task: "Work through automotive service lab exercises: engine diagnostics, brake systems, or electrical systems",
            successCriteria: "Automotive lab assignment completed (diagnostic steps documented, system inspection notes written, or service procedure outlined), and work saved or submitted",
            preferredDuration: 45 * 60
        ),
        SuggestedTemplate(
            icon: "flame.fill",
            task: "Study for the AWS welding certification or CWI exam",
            successCriteria: "Target welding content reviewed (welding processes, weld quality standards, inspection criteria, or safety procedures), practice questions completed, and notes saved",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "hammer.fill",
            task: "Complete a welding technology program assignment: welding procedures, weld testing, or safety",
            successCriteria: "Welding assignment completed (procedure documented, weld testing steps outlined, or safety analysis written), and work saved or submitted",
            preferredDuration: 45 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Write the specific aims or research narrative for my NIH or NSF grant application",
            successCriteria: "Specific aims page drafted or research narrative section completed, argument is clear and organized, and document is saved with tracked changes or version note",
            preferredDuration: 90 * 60
        ),
        SuggestedTemplate(
            icon: "pencil.and.list.clipboard",
            task: "Draft a grant proposal or foundation funding application for my research project",
            successCriteria: "Grant proposal section completed (background, significance, aims, or budget narrative drafted), argument documented, and work saved or submitted",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "hare.fill",
            task: "Complete an animal husbandry or livestock management coursework assignment",
            successCriteria: "Assignment completed (livestock production problem set solved, animal management plan written, or exam material reviewed), and work saved or submitted",
            preferredDuration: 45 * 60
        ),
        SuggestedTemplate(
            icon: "pawprint.fill",
            task: "Study for my animal science production exam: swine, poultry, beef, or dairy",
            successCriteria: "Target livestock production content reviewed (species-specific management, nutrition, reproduction, or health), practice questions completed, and notes saved",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "briefcase.fill",
            task: "Study for the CLA or CP paralegal certification exam",
            successCriteria: "Target paralegal content reviewed (legal research, civil procedure, ethics, or substantive law area), practice questions completed, and notes saved for next session",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "folder.fill",
            task: "Complete a paralegal studies assignment: legal research, document drafting, or case analysis",
            successCriteria: "Paralegal assignment completed (research memo drafted, legal document outlined, or case analysis written), and work saved or submitted",
            preferredDuration: 45 * 60
        ),
        SuggestedTemplate(
            icon: "chart.pie.fill",
            task: "Study for the CFP exam or complete a financial planning coursework module",
            successCriteria: "Target CFP content reviewed (financial planning process, investment, insurance, tax, retirement, or estate planning), practice questions completed, and notes saved for next session",
            preferredDuration: 90 * 60
        ),
        SuggestedTemplate(
            icon: "dollarsign.circle.fill",
            task: "Build a client financial plan or case study for my financial planning program",
            successCriteria: "Financial plan section completed (goals, net worth statement, cash flow analysis, or recommendations written), and work saved or submitted",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "leaf.fill",
            task: "Complete a soil science lab report, field description, or pedology coursework assignment",
            successCriteria: "Lab report or field description completed (soil horizon descriptions, profile sketch, or taxonomy classification written), and work saved or submitted",
            preferredDuration: 45 * 60
        ),
        SuggestedTemplate(
            icon: "square.3.layers.3d.down.forward.fill",
            task: "Study for my soil science exam or work through soil taxonomy and classification materials",
            successCriteria: "Target soil science content reviewed (soil orders, classification criteria, horizon nomenclature, or formation processes), practice questions completed, and notes saved",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "shield.lefthalf.filled",
            task: "Complete my industrial hygiene or occupational safety coursework assignment",
            successCriteria: "Assignment completed (hazard analysis written, safety program section drafted, OSHA regulation review completed, or problem set solved), and work saved or submitted",
            preferredDuration: 45 * 60
        ),
        SuggestedTemplate(
            icon: "exclamationmark.triangle.fill",
            task: "Study for the CIH exam or review OSHA regulations and industrial safety standards",
            successCriteria: "Target industrial hygiene content reviewed (hazard recognition, evaluation, control, OSHA standards, or toxicology), practice questions completed, and notes saved",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "fork.knife",
            task: "Study for the ServSafe certification exam or complete a food safety coursework assignment",
            successCriteria: "Target food safety content reviewed (foodborne illness, HACCP principles, temperature control, sanitation, or personal hygiene), practice questions completed, and notes saved",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "checkmark.seal.fill",
            task: "Write a HACCP plan or complete a food safety audit assignment",
            successCriteria: "HACCP plan section completed or audit report drafted (hazard analysis, critical control points, corrective actions, or monitoring procedures written), and work saved",
            preferredDuration: 45 * 60
        ),
        SuggestedTemplate(
            icon: "music.note",
            task: "Practice and prepare my repertoire for my music jury or audition",
            successCriteria: "Target repertoire sections practiced (scales, etudes, or solo pieces worked through), performance notes or recordings saved, and preparation checklist updated",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "waveform.badge.mic",
            task: "Work through applied music lessons, scales, and technique exercises",
            successCriteria: "Lesson assignment or technique exercises completed (scales, etudes, sight-reading, or specific passages practiced and recorded in practice log)",
            preferredDuration: 45 * 60
        ),
        SuggestedTemplate(
            icon: "wineglass.fill",
            task: "Complete a winemaking lab report or fermentation process assignment",
            successCriteria: "Lab report or fermentation analysis completed (process parameters recorded, data analyzed, or cellar operations procedure documented), and work saved or submitted",
            preferredDuration: 45 * 60
        ),
        SuggestedTemplate(
            icon: "drop.fill",
            task: "Study winery operations and wine production techniques for my winemaking course",
            successCriteria: "Target winemaking content reviewed (fermentation, cellar operations, wine chemistry, or vineyard management), practice questions completed, and notes saved",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "tree.fill",
            task: "Complete my forestry or silviculture assignment, lab report, or timber cruise analysis",
            successCriteria: "Assignment completed (forest inventory analysis, silvicultural prescription written, timber cruise data processed, or management plan section drafted), and work saved or submitted",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "leaf.circle.fill",
            task: "Study for my forestry exam or review forest management and dendrology materials",
            successCriteria: "Target forestry content reviewed (silviculture principles, tree identification, forest inventory methods, or management prescriptions), practice questions completed, and notes saved",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "fish.fill",
            task: "Complete my fisheries biology or aquatic science assignment, lab report, or data analysis",
            successCriteria: "Assignment completed (fish population data analyzed, aquaculture system design drafted, limnology lab report written, or fisheries management plan section completed), and work saved",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "water.waves",
            task: "Study for my fisheries or aquatic science exam and review aquaculture or limnology materials",
            successCriteria: "Target aquatic science content reviewed (aquaculture systems, fish ecology, water quality, fisheries management, or limnology concepts), practice questions completed, and notes saved",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "cross.case.fill",
            task: "Study for the CEN exam or complete an emergency nursing assignment",
            successCriteria: "Target emergency nursing content reviewed (triage, trauma assessment, ENPC/TNCC procedures, or CEN exam questions practiced), notes saved for next session",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "staroflife.fill",
            task: "Write up my emergency nursing case notes or TNCC/ENPC coursework assignment",
            successCriteria: "Case notes or coursework assignment completed (trauma assessment written, SBAR documentation finished, emergency scenario analysis done), and work saved or submitted",
            preferredDuration: 30 * 60
        ),
        SuggestedTemplate(
            icon: "heart.text.square.fill",
            task: "Complete my community nutrition or public health nutrition assignment",
            successCriteria: "Assignment completed (community nutrition assessment written, WIC counseling plan drafted, nutrition education materials developed, or policy brief section completed), and work saved",
            preferredDuration: 45 * 60
        ),
        SuggestedTemplate(
            icon: "person.3.fill",
            task: "Study for my public health nutrition exam or review community nutrition and WIC program materials",
            successCriteria: "Target public health nutrition content reviewed (community assessment, WIC program guidelines, nutrition policy, maternal/infant nutrition, or food security concepts), notes saved",
            preferredDuration: 60 * 60
        ),
        // plumbingtech templates
        SuggestedTemplate(
            icon: "wrench.adjustable.fill",
            task: "Study for the journeyman or master plumber exam and review NCCER plumbing or plumbing code materials",
            successCriteria: "Target plumbing content reviewed (plumbing code sections, pipe sizing, drainage systems, or NCCER exam questions practiced), notes saved for next session",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "drop.fill",
            task: "Complete a plumbing technology class assignment on pipe systems, fittings, or plumbing code compliance",
            successCriteria: "Assignment completed (pipe system diagrams drawn, code compliance questions answered, or lab report written), and work saved",
            preferredDuration: 45 * 60
        ),
        // electricaltechnology templates
        SuggestedTemplate(
            icon: "bolt.fill",
            task: "Study for the journeyman or master electrician exam and review NEC code sections for my electrical apprenticeship",
            successCriteria: "Target electrical content reviewed (NEC code articles, wiring methods, load calculations, or journeyman exam questions practiced), notes saved",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "powerplug.fill",
            task: "Complete an electrical theory or electrical code assignment for my electrician program or IBEW apprenticeship",
            successCriteria: "Assignment completed (code compliance problems solved, wiring diagrams drawn, electrical theory questions answered), and work saved",
            preferredDuration: 45 * 60
        ),
        // materialscience templates
        SuggestedTemplate(
            icon: "atom",
            task: "Complete a materials science lab report or problem set on phase diagrams, mechanical properties, or crystallography",
            successCriteria: "Lab report or problem set completed (phase diagrams interpreted, mechanical property calculations done, or crystallography analysis written), and work saved",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "cube.fill",
            task: "Study for my materials science or materials engineering exam and review metallurgy, polymer science, or composite materials",
            successCriteria: "Target materials content reviewed (phase diagrams, mechanical properties, polymer chains, composite structures, or metallurgy concepts), notes saved",
            preferredDuration: 60 * 60
        ),
        // networkengineering templates
        SuggestedTemplate(
            icon: "network",
            task: "Study for the CCNA, CCNP, or CompTIA Network+ exam and review networking concepts and protocols",
            successCriteria: "Target networking content reviewed (subnetting, routing protocols, switching, or CCNA/Network+ exam questions practiced), notes saved for next session",
            preferredDuration: 90 * 60
        ),
        SuggestedTemplate(
            icon: "antenna.radiowaves.left.and.right",
            task: "Complete a network engineering assignment on IP addressing, routing protocols, or network infrastructure design",
            successCriteria: "Assignment completed (network diagrams drawn, IP addressing scheme designed, routing configuration written, or lab scenario completed), and work saved",
            preferredDuration: 60 * 60
        ),
        // environmentalhealth templates
        SuggestedTemplate(
            icon: "leaf.fill",
            task: "Study for the REHS exam or complete an environmental health science class assignment on food safety, water quality, or environmental toxicology",
            successCriteria: "Target environmental health content reviewed (REHS prep, food safety regulations, water quality standards, or environmental toxicology concepts), notes saved",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "magnifyingglass.circle.fill",
            task: "Write an environmental health report or case study on community environmental health assessment or public health inspection protocols",
            successCriteria: "Environmental health report or case study written (community assessment completed, inspection protocols documented, or policy analysis finished), and work saved",
            preferredDuration: 45 * 60
        ),
        // constructiontech templates
        SuggestedTemplate(
            icon: "hammer.fill",
            task: "Study for the contractor license exam or complete a construction technology program assignment on carpentry, masonry, or concrete",
            successCriteria: "Target construction tech content reviewed (contractor exam sections, carpentry techniques, masonry principles, or concrete specifications), notes saved",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "building.2.fill",
            task: "Complete a building trades class assignment on wood framing, structural systems, or construction inspection",
            successCriteria: "Assignment completed (framing diagram drawn, construction inspection checklist completed, or structural analysis written), and work saved",
            preferredDuration: 45 * 60
        ),
        // urbandesign templates
        SuggestedTemplate(
            icon: "map.fill",
            task: "Design a streetscape or public space for my urban design studio project",
            successCriteria: "Urban design project work completed (streetscape sketches drawn, placemaking analysis written, public space program developed, or design diagrams created), and work saved",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "figure.walk",
            task: "Complete an urban design class assignment on placemaking, pedestrian design, or public realm analysis",
            successCriteria: "Assignment completed (site analysis written, placemaking concept developed, pedestrian design documented, or urban design critique drafted), and work saved",
            preferredDuration: 45 * 60
        ),
        // ceramicsandsculpture templates
        SuggestedTemplate(
            icon: "flame.fill",
            task: "Work on my ceramics project — wheel throwing, hand building, or preparing pieces for kiln firing",
            successCriteria: "Ceramics studio session completed (pottery wheel practice done, hand-built pieces completed, glazing applied, or pieces prepared for kiln), progress documented",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "square.3.layers.3d",
            task: "Study for my ceramics or sculpture class exam and review techniques, glaze chemistry, or art history context",
            successCriteria: "Target ceramics content reviewed (ceramic techniques, glaze chemistry, kiln firing processes, or art history concepts), notes saved",
            preferredDuration: 45 * 60
        ),
        // exercisescience templates
        SuggestedTemplate(
            icon: "heart.fill",
            task: "Study for the ACSM exam or complete an exercise science class assignment on exercise testing or metabolic assessment",
            successCriteria: "Target exercise science content reviewed (ACSM exam sections, graded exercise test protocols, metabolic testing concepts, or CEP competencies), notes saved",
            preferredDuration: 90 * 60
        ),
        SuggestedTemplate(
            icon: "figure.run",
            task: "Complete my exercise science lab report on exercise testing, VO2 max assessment, or metabolic measurement",
            successCriteria: "Lab report completed (exercise test data analyzed, VO2 max calculations done, metabolic assessment results written, or findings interpreted), and work saved",
            preferredDuration: 45 * 60
        ),
        // biochemistry templates
        SuggestedTemplate(
            icon: "atom",
            task: "Complete my biochemistry lab report on enzyme kinetics, protein assay, or metabolic pathway analysis",
            successCriteria: "Lab report completed (enzyme kinetics calculations done, Michaelis-Menten analysis written, protein assay results interpreted, or metabolic pathway diagram annotated), and work saved",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "testtube.2",
            task: "Study for my biochemistry exam and review enzyme kinetics, metabolic pathways, or biochemical assay techniques",
            successCriteria: "Target biochemistry content reviewed (enzyme kinetics, Km/Vmax calculations, metabolic pathways, assay principles, or biochemistry exam questions practiced), notes saved",
            preferredDuration: 60 * 60
        ),
        // agriculturalscience templates
        SuggestedTemplate(
            icon: "leaf.fill",
            task: "Complete my agricultural science assignment on agronomy, crop production, or precision agriculture",
            successCriteria: "Assignment completed (crop production analysis written, agronomy problem sets done, precision agriculture data reviewed, or soil fertility lab report drafted), and work saved",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "sun.max.fill",
            task: "Study for my agronomy exam and review crop science, soil fertility, and field crop management principles",
            successCriteria: "Target content reviewed (crop physiology, soil fertility concepts, field crop management, or precision agriculture principles), notes saved, and at least 20 practice questions completed",
            preferredDuration: 60 * 60
        ),
        // textilesfashion templates
        SuggestedTemplate(
            icon: "rectangle.pattern.checkered",
            task: "Work on my fiber arts or weaving project — hand weaving, tapestry, natural dyeing, or spinning",
            successCriteria: "Studio session completed (weaving progress documented, dye sample tested, spinning practice done, or tapestry section woven), and progress photographed or journaled",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "scissors",
            task: "Complete my textile science or textile engineering assignment on fabric structure, dyeing, or fiber properties",
            successCriteria: "Assignment completed (textile structure analysis written, dye chemistry notes reviewed, fiber property data recorded, or textile technology concepts summarized), and work saved",
            preferredDuration: 45 * 60
        ),
        // geographyearthed templates
        SuggestedTemplate(
            icon: "globe.americas.fill",
            task: "Study for my geography exam — AP Human Geography, world geography, or physical geography concepts",
            successCriteria: "Target geography content reviewed (human geography themes, physical geography processes, or AP Geography FRQ practice completed), notes organized and key concepts memorized",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "map.fill",
            task: "Complete my geography class assignment on human geography, cultural geography, or regional analysis",
            successCriteria: "Assignment completed (regional analysis written, cultural geography essay drafted, human geography case study summarized, or geography field report completed), and work saved",
            preferredDuration: 45 * 60
        ),
        // childlife templates
        SuggestedTemplate(
            icon: "heart.text.clipboard.fill",
            task: "Study for the CCLS board exam or complete a child life specialist certification assignment",
            successCriteria: "Target content reviewed (CCLS exam domains, therapeutic play theory, developmental assessments, or child life intervention models), notes saved, and at least 20 practice questions completed",
            preferredDuration: 90 * 60
        ),
        SuggestedTemplate(
            icon: "figure.and.child.holdinghands",
            task: "Write child life session notes or a therapeutic play treatment plan for my pediatric hospital internship",
            successCriteria: "Session notes or treatment plan completed (patient goals documented, intervention rationale written, therapeutic play activities planned, or developmental considerations addressed), and work saved",
            preferredDuration: 45 * 60
        ),
        // qualitymanagement templates
        SuggestedTemplate(
            icon: "checkmark.seal.fill",
            task: "Study for the ASQ CQE exam or complete a quality engineering assignment on statistical process control or ISO auditing",
            successCriteria: "Target content reviewed (CQE body of knowledge sections, SPC control charts, ISO 9001 audit principles, or FMEA methods), notes saved, and at least 20 practice questions completed",
            preferredDuration: 90 * 60
        ),
        SuggestedTemplate(
            icon: "chart.bar.doc.horizontal.fill",
            task: "Complete my quality management assignment on ISO 9001, quality assurance, or process improvement",
            successCriteria: "Assignment completed (quality management system analysis written, ISO audit findings documented, SPC chart analyzed, or process improvement report drafted), and work saved",
            preferredDuration: 60 * 60
        ),
        // quantumcomputing templates
        SuggestedTemplate(
            icon: "atom",
            task: "Build a quantum circuit or work through a quantum computing assignment using Qiskit or IBM Quantum",
            successCriteria: "Quantum circuit implemented or quantum algorithm problem completed (Qiskit code written, circuit gates configured, simulation run, or assignment questions answered), and work saved",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "cpu.fill",
            task: "Study quantum computing concepts — quantum gates, algorithms, or quantum error correction — for my class or exam",
            successCriteria: "Target quantum computing content reviewed (quantum gates, Grover's/Shor's algorithm, superposition/entanglement, or error correction schemes), notes saved, and key concepts summarized",
            preferredDuration: 45 * 60
        ),
        // cloudcomputing templates
        SuggestedTemplate(
            icon: "cloud.fill",
            task: "Study for my AWS, Azure, or GCP cloud certification exam and review cloud architecture concepts",
            successCriteria: "Target cloud certification content reviewed (services, architecture patterns, security, or cost optimization), notes saved, and at least 20 practice questions completed",
            preferredDuration: 90 * 60
        ),
        SuggestedTemplate(
            icon: "terminal.fill",
            task: "Complete a DevOps or cloud computing assignment using Terraform, Kubernetes, or Docker",
            successCriteria: "Assignment completed (infrastructure-as-code written, container configuration defined, pipeline configured, or cloud deployment documented), and work saved",
            preferredDuration: 60 * 60
        ),
        // softwaretesting templates
        SuggestedTemplate(
            icon: "checkmark.circle.fill",
            task: "Study for the ISTQB CTFL exam or complete a software testing assignment on test automation or QA engineering",
            successCriteria: "Target content reviewed (ISTQB syllabus chapters, test design techniques, or QA concepts), notes saved, and at least 20 practice questions completed",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "hammer.fill",
            task: "Write automated tests using Selenium, pytest, or JUnit for my software testing class or project",
            successCriteria: "Test cases written (at least 5 automated tests implemented, test suite runs without errors, assertions cover target functionality), and code saved",
            preferredDuration: 60 * 60
        ),
        // mechanicaldrafting templates
        SuggestedTemplate(
            icon: "ruler.fill",
            task: "Complete a mechanical drafting assignment — technical drawing, blueprint reading, or AutoCAD drafting for my program",
            successCriteria: "Drafting assignment completed (technical drawing finished, AutoCAD file saved with correct dimensions and views, blueprint reading questions answered, or drafting notes reviewed), and work saved",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "pencil.and.ruler.fill",
            task: "Study engineering drawing and blueprint reading for my drafting technology class or certification exam",
            successCriteria: "Target drafting content reviewed (orthographic projection, sectional views, dimensioning standards, GD&T symbols, or blueprint reading concepts), notes organized and key techniques summarized",
            preferredDuration: 45 * 60
        ),
        // dataengineering templates
        SuggestedTemplate(
            icon: "cylinder.split.1x2.fill",
            task: "Build an ETL pipeline or data engineering project using Apache Spark, Kafka, or Airflow",
            successCriteria: "Pipeline implemented or project milestone completed (ETL logic coded, Spark job runs, Airflow DAG defined, or data transformation steps documented), and code saved",
            preferredDuration: 90 * 60
        ),
        SuggestedTemplate(
            icon: "table.fill",
            task: "Complete my data engineering assignment on data warehouse design, dbt, Snowflake, or data modeling",
            successCriteria: "Assignment completed (data warehouse schema designed, dbt models defined, Snowflake queries written, or data modeling documentation completed), and work saved",
            preferredDuration: 60 * 60
        ),
        // robotics templates
        SuggestedTemplate(
            icon: "cpu.fill",
            task: "Build a robotics project or complete a robotics lab assignment using ROS or ROS2",
            successCriteria: "Robotics project milestone completed (ROS node written, robot simulation configured, sensor integration implemented, or path planning algorithm coded), and work saved",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "gearshape.2.fill",
            task: "Study for my robotics exam and review autonomous systems, robot kinematics, and motion planning concepts",
            successCriteria: "Target robotics content reviewed (kinematics, dynamics, path planning, SLAM, or sensor fusion concepts), notes organized, and at least 10 practice problems completed",
            preferredDuration: 60 * 60
        ),
        // artificialintelligence templates
        SuggestedTemplate(
            icon: "brain.head.profile",
            task: "Complete my artificial intelligence class assignment on search algorithms, knowledge representation, or planning",
            successCriteria: "AI assignment completed (algorithm implemented, knowledge base built, planning problem solved, or written analysis submitted), and work saved",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "text.bubble.fill",
            task: "Study AI ethics, responsible AI, or AI policy concepts and draft my reflection paper or case analysis",
            successCriteria: "Target AI ethics content reviewed (fairness, accountability, transparency, or AI governance concepts), and draft paper or case analysis completed with key arguments outlined",
            preferredDuration: 45 * 60
        ),
        // osteopathicmedicine templates
        SuggestedTemplate(
            icon: "stethoscope",
            task: "Study for the COMLEX exam or complete my osteopathic medicine school coursework",
            successCriteria: "Target COMLEX content reviewed (OMM techniques, osteopathic principles, or clinical science concepts), notes organized, and at least 20 practice questions completed",
            preferredDuration: 90 * 60
        ),
        SuggestedTemplate(
            icon: "cross.case.fill",
            task: "Write up my osteopathic manipulative medicine (OMM) session notes or DO clinical rotation documentation",
            successCriteria: "OMM notes or clinical documentation completed (SOAP note written, OMM technique findings documented, or rotation reflection submitted), and work saved",
            preferredDuration: 30 * 60
        ),
        // epidemiology templates
        SuggestedTemplate(
            icon: "chart.bar.doc.horizontal.fill",
            task: "Complete my epidemiology assignment — design a study, analyze data, or write an outbreak investigation report",
            successCriteria: "Epidemiology assignment completed (study design documented, data analysis run, odds/relative risk calculated, or outbreak report drafted), and work saved",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "waveform.path.ecg",
            task: "Study for my epidemiology or biostatistics exam and review study designs, measures of association, and epi concepts",
            successCriteria: "Target epi content reviewed (case-control, cohort, cross-sectional designs, epi curve, attributable risk, or biostatistics concepts), notes organized, and practice problems completed",
            preferredDuration: 60 * 60
        ),
        // bioethics templates
        SuggestedTemplate(
            icon: "doc.text.magnifyingglass",
            task: "Write my IRB protocol or research ethics application for my human subjects research study",
            successCriteria: "IRB protocol sections drafted (research design, risks and benefits, informed consent procedures, or privacy protections completed), and document saved for submission",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "books.vertical.fill",
            task: "Analyze a bioethics case or write a medical ethics paper on informed consent, autonomy, or end-of-life care",
            successCriteria: "Bioethics analysis completed (ethical framework applied, key principles (beneficence, nonmaleficence, autonomy, justice) discussed, and written argument with conclusion drafted), and work saved",
            preferredDuration: 60 * 60
        ),
        // blockchain templates
        SuggestedTemplate(
            icon: "link.circle.fill",
            task: "Build a smart contract or complete my blockchain development assignment using Solidity or Web3",
            successCriteria: "Smart contract or blockchain assignment completed (Solidity code written, contract tested, or dApp feature implemented), and work saved or committed to version control",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "network",
            task: "Study for my blockchain class exam and review distributed ledger, consensus algorithms, and smart contract concepts",
            successCriteria: "Target blockchain content reviewed (consensus algorithms, Ethereum/Solidity concepts, or DeFi/NFT topics), notes organized, and practice questions completed",
            preferredDuration: 60 * 60
        ),
        // digitalmarketing templates
        SuggestedTemplate(
            icon: "chart.line.uptrend.xyaxis",
            task: "Study for my Google Analytics or digital marketing certification exam",
            successCriteria: "Target digital marketing content reviewed (SEO, analytics, PPC, or social media marketing concepts), and practice questions or a mock exam completed",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "megaphone.fill",
            task: "Complete my digital marketing assignment on SEO, content marketing, or social media strategy",
            successCriteria: "Digital marketing assignment completed (SEO audit, content calendar, social media strategy, or marketing analytics report drafted), and work saved",
            preferredDuration: 45 * 60
        ),
        // projectmanagement templates
        SuggestedTemplate(
            icon: "checklist.checked",
            task: "Study for the PMP, CAPM, or agile certification exam and review PMBOK concepts",
            successCriteria: "Target project management content reviewed (PMBOK knowledge areas, agile methodology, or scrum/kanban frameworks), and at least 20 practice questions completed",
            preferredDuration: 90 * 60
        ),
        SuggestedTemplate(
            icon: "calendar.badge.checkmark",
            task: "Complete my project management class assignment on project charter, WBS, or agile sprint planning",
            successCriteria: "Project management assignment completed (project charter drafted, WBS created, sprint backlog organized, or risk register updated), and work saved",
            preferredDuration: 60 * 60
        ),
        // riskmanagement templates
        SuggestedTemplate(
            icon: "exclamationmark.shield.fill",
            task: "Study for my RIMS-CRMP or enterprise risk management certification exam",
            successCriteria: "Target risk management content reviewed (ERM frameworks, risk assessment methodologies, ISO 31000, or governance and compliance concepts), and practice questions completed",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "chart.bar.fill",
            task: "Complete my risk management class assignment on risk assessment, risk analysis, or GRC frameworks",
            successCriteria: "Risk management assignment completed (risk register updated, risk matrix built, risk assessment report drafted, or GRC framework analysis completed), and work saved",
            preferredDuration: 60 * 60
        ),
        // speechcommunication templates
        SuggestedTemplate(
            icon: "mic.fill",
            task: "Write and rehearse my speech or public speaking class presentation",
            successCriteria: "Speech written and outlined (introduction, main points, conclusion structured), key transitions memorized, and at least two full rehearsals completed",
            preferredDuration: 45 * 60
        ),
        SuggestedTemplate(
            icon: "person.2.wave.2.fill",
            task: "Prepare my debate arguments and rebuttal points for my debate class or competitive event",
            successCriteria: "Debate case prepared (affirmative or negative position outlined, key arguments drafted, evidence researched, and at least three potential rebuttal points noted), and work saved",
            preferredDuration: 45 * 60
        ),
        // audiology templates
        SuggestedTemplate(
            icon: "ear.fill",
            task: "Study for the PRAXIS audiology exam and review audiometric testing, hearing disorders, and intervention approaches",
            successCriteria: "At least two audiology topic areas reviewed (e.g., pure-tone audiometry, hearing loss types, cochlear implant candidacy), practice questions attempted, and notes updated",
            preferredDuration: 90 * 60
        ),
        SuggestedTemplate(
            icon: "waveform",
            task: "Write up my audiology clinical notes or audiology externship documentation",
            successCriteria: "Clinical notes or externship documentation completed (patient audiogram results summarized, intervention plan documented, or externship reflection written) and saved",
            preferredDuration: 30 * 60
        ),
        // behavioranalysis templates
        SuggestedTemplate(
            icon: "person.fill.checkmark",
            task: "Complete my applied behavior analysis assignment or write a behavior intervention plan",
            successCriteria: "ABA assignment completed or behavior intervention plan drafted (problem behavior defined, antecedents and consequences identified, intervention strategy outlined) and saved",
            preferredDuration: 45 * 60
        ),
        SuggestedTemplate(
            icon: "brain.head.profile",
            task: "Study for the BCBA or RBT certification exam and review ABA concepts, verbal behavior, and ethics",
            successCriteria: "At least two ABA topic areas studied (e.g., reinforcement schedules, discrete trial training, functional behavior assessment), practice questions completed, and notes updated",
            preferredDuration: 60 * 60
        ),
        // radiationtherapy templates
        SuggestedTemplate(
            icon: "rays",
            task: "Study for the ARRT radiation therapy exam and review dosimetry, treatment planning, and radiation oncology concepts",
            successCriteria: "At least two radiation therapy topic areas reviewed (e.g., radiation physics, dosimetry calculations, treatment planning systems), practice questions attempted, and notes updated",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "waveform.path",
            task: "Complete my radiation therapy class assignment on treatment planning or linear accelerator operation",
            successCriteria: "Radiation therapy assignment completed (treatment plan drafted, dosimetry calculation worked through, or LINAC procedure documented) and saved",
            preferredDuration: 45 * 60
        ),
        // orthotics templates
        SuggestedTemplate(
            icon: "figure.walk",
            task: "Complete my orthotics and prosthetics class assignment on device design, fabrication, or patient fitting",
            successCriteria: "O&P assignment completed (orthotic or prosthetic device design documented, fabrication steps outlined, or patient fitting case study written) and saved",
            preferredDuration: 45 * 60
        ),
        SuggestedTemplate(
            icon: "person.crop.square",
            task: "Study for the CPO or CPT board exam and review O&P concepts, biomechanics, and clinical practice",
            successCriteria: "At least two O&P topic areas studied (e.g., lower limb prosthetics, spinal orthotics, patient gait analysis), practice questions completed, and notes updated",
            preferredDuration: 60 * 60
        ),
        // healthphysics templates
        SuggestedTemplate(
            icon: "shield.fill",
            task: "Study for the CHP board exam or medical physics certification and review radiation protection, dosimetry, and shielding",
            successCriteria: "At least two health physics topic areas reviewed (e.g., radiation measurement, shielding design, biological effects), practice problems completed, and notes updated",
            preferredDuration: 90 * 60
        ),
        SuggestedTemplate(
            icon: "rays",
            task: "Complete my health physics or radiation safety assignment on shielding calculations or radiation monitoring",
            successCriteria: "Health physics assignment completed (shielding calculation worked through, radiation monitoring protocol documented, or safety analysis report drafted) and saved",
            preferredDuration: 60 * 60
        ),
        // informationsystems templates
        SuggestedTemplate(
            icon: "server.rack",
            task: "Complete my MIS or information systems assignment on systems analysis, database design, or enterprise systems",
            successCriteria: "IS assignment completed (system requirements documented, ERD or data flow diagram drafted, or SAP ERP process mapped) and saved",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "building.columns",
            task: "Study for my information systems or MIS class exam and review systems analysis, data modeling, and IT governance concepts",
            successCriteria: "At least two IS topic areas reviewed (e.g., SDLC phases, database normalization, ERP systems), practice questions attempted, and notes updated",
            preferredDuration: 60 * 60
        ),
        // businessintelligence templates
        SuggestedTemplate(
            icon: "chart.bar.xaxis",
            task: "Build a Tableau or Power BI dashboard for my business intelligence class or BI certification project",
            successCriteria: "BI dashboard created or meaningfully progressed (data connected, at least two visualizations built, and key insights captured), and work saved",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "chart.line.uptrend.xyaxis",
            task: "Study for my Tableau or Power BI certification exam and review data visualization, dashboard design, and analytics concepts",
            successCriteria: "At least two BI topic areas studied (e.g., calculated fields, data blending, visual best practices), practice exercises completed, and notes updated",
            preferredDuration: 60 * 60
        ),
        // internationalrelations templates
        SuggestedTemplate(
            icon: "globe",
            task: "Write my international relations paper or analysis on foreign policy, IR theory, or global governance",
            successCriteria: "IR paper or analysis meaningfully advanced (thesis articulated, at least two IR theories applied, and argument structured with supporting evidence) and saved",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "person.3.fill",
            task: "Study for my international relations exam and review IR theory, foreign policy analysis, and global governance concepts",
            successCriteria: "At least two IR topic areas reviewed (e.g., realism, liberalism, constructivism, international organizations), practice questions attempted, and notes updated",
            preferredDuration: 60 * 60
        ),
        // publicadministration templates
        SuggestedTemplate(
            icon: "building.2.fill",
            task: "Write a policy memo or public administration paper for my MPA class or public sector management course",
            successCriteria: "Policy memo or paper meaningfully advanced (problem statement defined, policy options analyzed, at least one recommendation drafted) and saved",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "checkmark.seal.fill",
            task: "Study for my civil service exam or MPA class exam and review public administration, nonprofit management, and government operations concepts",
            successCriteria: "At least two public administration topic areas reviewed (e.g., administrative law, public budgeting, nonprofit governance), practice questions attempted, and notes updated",
            preferredDuration: 60 * 60
        ),
        // laborlaw templates
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Write my employment law or labor law paper analyzing NLRA, collective bargaining, or workplace discrimination law",
            successCriteria: "Labor law paper meaningfully advanced (legal issue identified, relevant statutes and cases cited, argument structured) and saved",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "briefcase.fill",
            task: "Study for my employment law or HR law class exam and review labor relations, wage and hour law, and employment discrimination concepts",
            successCriteria: "At least two employment law topic areas reviewed (e.g., FLSA, Title VII, NLRA, FMLA), practice questions completed, and notes updated",
            preferredDuration: 60 * 60
        ),
        // veterinarytechnology templates
        SuggestedTemplate(
            icon: "pawprint.fill",
            task: "Study for the VTNE or vet tech class exam and review animal anatomy, physiology, pharmacology, and clinical procedures",
            successCriteria: "At least two veterinary technology topic areas reviewed (e.g., pharmacology, radiology, anesthesia, surgical nursing), practice questions attempted, and notes updated",
            preferredDuration: 90 * 60
        ),
        SuggestedTemplate(
            icon: "cross.case.fill",
            task: "Complete my veterinary technology class assignment on patient care, drug calculations, or clinical procedures",
            successCriteria: "Vet tech assignment meaningfully advanced (calculations checked, procedure steps outlined, or case study answered) and saved",
            preferredDuration: 45 * 60
        ),
        // dentalradiology templates
        SuggestedTemplate(
            icon: "rays",
            task: "Study for the DANB RHS dental radiography exam and review intraoral, bitewing, and panoramic radiograph techniques",
            successCriteria: "At least two dental radiography topic areas reviewed (e.g., radiation safety, exposure settings, film placement, panoramic technique), practice questions attempted, and notes updated",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Complete my dental radiography class assignment on radiation safety, image quality, or radiographic anatomy",
            successCriteria: "Dental radiography assignment meaningfully advanced (radiation safety principles reviewed, image critique completed, or anatomy identified) and saved",
            preferredDuration: 45 * 60
        ),
        // medicalscribing templates
        SuggestedTemplate(
            icon: "pencil.and.outline",
            task: "Practice medical scribing by transcribing a patient encounter and documenting the chief complaint, HPI, assessment, and plan",
            successCriteria: "At least one complete patient encounter note drafted (SOAP or H&P format) with chief complaint, HPI, and assessment/plan sections completed accurately",
            preferredDuration: 30 * 60
        ),
        SuggestedTemplate(
            icon: "checkmark.seal.fill",
            task: "Study for my medical scribe certification and review medical terminology, anatomy abbreviations, and documentation standards",
            successCriteria: "At least two medical scribing topic areas reviewed (e.g., medical terminology, chart structure, specialty-specific templates, EHR navigation), practice scenarios completed, and notes updated",
            preferredDuration: 45 * 60
        ),
        // communityhealth templates
        SuggestedTemplate(
            icon: "person.3.fill",
            task: "Study for the CHES or CHW certification exam and review community health education, behavior change theories, and program planning",
            successCriteria: "At least two community health topic areas reviewed (e.g., health behavior models, community assessment, program evaluation, cultural competency), practice questions attempted, and notes updated",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "heart.text.clipboard.fill",
            task: "Complete my community health or CHW class assignment on health outreach, patient navigation, or health education program design",
            successCriteria: "Community health assignment meaningfully advanced (outreach plan drafted, health education materials outlined, or community assessment section completed) and saved",
            preferredDuration: 45 * 60
        ),
        // toxicology templates
        SuggestedTemplate(
            icon: "flask.fill",
            task: "Study for my toxicology class exam and review dose-response relationships, toxicokinetics, and mechanisms of toxicity",
            successCriteria: "At least two toxicology topic areas reviewed (e.g., dose-response, absorption/distribution, organ-specific toxicity, forensic toxicology methods), practice questions attempted, and notes updated",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "doc.plaintext.fill",
            task: "Complete my toxicology lab report or assignment on analytical methods, tox screen interpretation, or forensic case analysis",
            successCriteria: "Toxicology assignment meaningfully advanced (lab data analyzed, tox screen results interpreted, or forensic case findings organized) and saved",
            preferredDuration: 60 * 60
        ),
        // performanceanalysis templates
        SuggestedTemplate(
            icon: "film.stack",
            task: "Analyze game film or match footage using Dartfish or Hudl and produce a performance analysis report for my team or class",
            successCriteria: "At least one full game or match reviewed, key performance metrics or tactical patterns identified, clips tagged, and written or visual summary report drafted",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "chart.xyaxis.line",
            task: "Complete my sports performance analysis class assignment on notational analysis, tactical patterns, or coaching analytics",
            successCriteria: "Performance analysis assignment meaningfully advanced (data coded, notation system applied, or tactical report section completed) and saved",
            preferredDuration: 45 * 60
        ),
        // musicbusiness templates
        SuggestedTemplate(
            icon: "music.note.list",
            task: "Study for my music business or music industry class exam and review music publishing, licensing, royalties, and artist management",
            successCriteria: "At least two music business topic areas reviewed (e.g., publishing deals, sync licensing, ASCAP/BMI royalties, record label structures, artist management), practice questions attempted, and notes updated",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Write my music business class paper or assignment on music publishing, entertainment law contracts, or the music industry ecosystem",
            successCriteria: "Music business paper meaningfully advanced (core argument defined, industry examples cited, at least one section drafted) and saved",
            preferredDuration: 45 * 60
        ),
        // dentalanesthesia templates
        SuggestedTemplate(
            icon: "syringe.fill",
            task: "Study for the COMS or DOCS dental anesthesia board exam and review sedation protocols, pharmacology, and patient monitoring",
            successCriteria: "At least two dental anesthesia topic areas reviewed (e.g., IV sedation protocols, drug interactions, emergency management, monitoring parameters), practice questions attempted, and notes updated",
            preferredDuration: 90 * 60
        ),
        SuggestedTemplate(
            icon: "waveform.path.ecg",
            task: "Complete my dental anesthesia class assignment on sedation techniques, patient assessment, or anesthesia pharmacology",
            successCriteria: "Dental anesthesia assignment meaningfully advanced (sedation protocol outlined, pharmacology reviewed, or patient case analyzed) and saved",
            preferredDuration: 45 * 60
        ),
        // palliativecare templates
        SuggestedTemplate(
            icon: "heart.fill",
            task: "Study for the CHPN exam and review palliative care principles, pain management, symptom control, and end-of-life care",
            successCriteria: "At least two palliative care topic areas reviewed (e.g., pain management, communication, symptom control, goals of care, grief support), practice questions attempted, and notes updated",
            preferredDuration: 90 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Write up my palliative care or hospice nursing notes, care plan, or end-of-life care class assignment",
            successCriteria: "Palliative care notes or assignment meaningfully advanced (care plan updated, symptom management goals documented, or assignment section drafted) and saved",
            preferredDuration: 30 * 60
        ),
        // cognitivescience templates
        SuggestedTemplate(
            icon: "brain.head.profile",
            task: "Study for my cognitive science class exam and review cognitive modeling, language and cognition, and mind-brain theory",
            successCriteria: "At least two cognitive science topic areas reviewed (e.g., cognitive architectures, attention models, language processing, consciousness theories), practice questions attempted, and notes updated",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Write my cogsci paper or cognitive science assignment on human cognition, computational mind, or cognitive systems",
            successCriteria: "Cognitive science paper meaningfully advanced (thesis stated, theoretical framework described, at least one section drafted and saved)",
            preferredDuration: 60 * 60
        ),
        // informationassurance
        SuggestedTemplate(
            icon: "lock.shield.fill",
            task: "Study for the CISM, CRISC, CASP+, or CISA certification exam — review RMF, DoD 8570 requirements, security governance frameworks, or NIST CSF",
            successCriteria: "At least two information assurance topic areas reviewed (e.g., risk management framework, security governance, cybersecurity policy, access control), practice questions attempted, and notes updated",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Complete my information assurance class assignment on security governance, RMF, DoD 8570 compliance, or cybersecurity policy",
            successCriteria: "IA assignment meaningfully advanced (key concepts outlined, governance framework described, at least one section drafted and saved)",
            preferredDuration: 60 * 60
        ),
        // hrmanagement
        SuggestedTemplate(
            icon: "person.2.fill",
            task: "Study for the SHRM-CP, SHRM-SCP, PHR, or SPHR certification exam — review talent management, compensation, employee relations, or HR analytics",
            successCriteria: "At least two HR management topic areas reviewed (e.g., staffing, compensation and benefits, employee development, labor relations), practice questions attempted, and notes updated",
            preferredDuration: 90 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Complete my human resource management class assignment on talent acquisition, compensation and benefits, employee relations, or workforce planning",
            successCriteria: "HR management assignment meaningfully advanced (key concepts outlined, HR framework described, at least one section drafted and saved)",
            preferredDuration: 60 * 60
        ),
        // changemanagement
        SuggestedTemplate(
            icon: "arrow.triangle.2.circlepath",
            task: "Study for the Prosci ADKAR, CCMP, or APMG change management certification exam — review change models, Kotter's 8 steps, stakeholder engagement, or organizational development",
            successCriteria: "At least two change management topic areas reviewed (e.g., ADKAR model, Kotter framework, change resistance, communication planning), practice questions attempted, and notes updated",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Complete my organizational change or change management class assignment on change leadership, stakeholder analysis, or organizational development",
            successCriteria: "Change management assignment meaningfully advanced (key concepts outlined, change framework applied, at least one section drafted and saved)",
            preferredDuration: 45 * 60
        ),
        // economics
        SuggestedTemplate(
            icon: "chart.line.uptrend.xyaxis",
            task: "Study for my microeconomics or macroeconomics class exam — review supply and demand, market structures, GDP, monetary policy, or econometrics",
            successCriteria: "At least two economics topic areas reviewed (e.g., price elasticity, market equilibrium, fiscal policy, regression analysis), practice problems attempted, and notes updated",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Complete my economics problem set or econometrics assignment — work through regression analysis, demand estimation, or macro model problems",
            successCriteria: "Economics assignment meaningfully advanced (at least three problems attempted, work shown, and answers written up)",
            preferredDuration: 60 * 60
        ),
        // iopsychology
        SuggestedTemplate(
            icon: "building.2.fill",
            task: "Study for my industrial-organizational psychology class exam — review personnel selection, job analysis, performance appraisal, motivation at work, or organizational behavior",
            successCriteria: "At least two I/O psychology topic areas reviewed (e.g., selection and assessment, training and development, leadership, organizational culture), practice questions attempted, and notes updated",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Write my I/O psychology paper or organizational psychology assignment on personnel selection, job analysis, performance management, or workplace motivation",
            successCriteria: "I/O psychology paper meaningfully advanced (thesis stated, theoretical framework described, at least one section drafted and saved)",
            preferredDuration: 60 * 60
        ),
        // criminallaw
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Analyze a criminal law hypothetical or brief a criminal law case on homicide, theft, or defenses",
            successCriteria: "Criminal law analysis meaningfully advanced (issue identified, rule stated, analysis applied via IRAC, at least one case briefed and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "book.fill",
            task: "Study for my criminal law class exam — review mens rea, actus reus, homicide, defenses, and the Model Penal Code",
            successCriteria: "At least two criminal law topic areas reviewed (e.g., homicide, theft offenses, defenses, MPC provisions), case law reviewed, notes updated",
            preferredDuration: 60 * 60
        ),
        // civilprocedure
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Analyze a civil procedure hypothetical on jurisdiction, pleading, discovery, or summary judgment",
            successCriteria: "Civil procedure analysis meaningfully advanced (issue identified, rule applied, FRCP provision cited, at least one analysis section drafted and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "book.fill",
            task: "Study for my civil procedure class exam — review personal jurisdiction, subject matter jurisdiction, Erie doctrine, pleading, and discovery rules",
            successCriteria: "At least two civil procedure topic areas reviewed (e.g., personal jurisdiction, SMJ, Erie, FRCP pleading standards, discovery), notes updated",
            preferredDuration: 60 * 60
        ),
        // constitutionallaw
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Analyze a constitutional law problem on judicial review, due process, equal protection, or First Amendment issues",
            successCriteria: "Constitutional law analysis meaningfully advanced (issue identified, doctrine applied, case law cited, at least one analysis section drafted and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "book.fill",
            task: "Study for my constitutional law class exam — review judicial review, First and Fourteenth Amendment, due process, equal protection, and federalism",
            successCriteria: "At least two constitutional law topic areas reviewed (e.g., judicial review, due process, equal protection, free speech, commerce clause), cases reviewed, notes updated",
            preferredDuration: 60 * 60
        ),
        // evidencelaw
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Analyze an evidence law hypothetical on hearsay, authentication, expert witnesses, or the Federal Rules of Evidence",
            successCriteria: "Evidence analysis meaningfully advanced (issue identified, FRE rule cited, hearsay analysis applied, at least one section drafted and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "book.fill",
            task: "Study for my evidence law class exam — review hearsay and its exceptions, authentication, privilege, character evidence, and expert witnesses",
            successCriteria: "At least two evidence topic areas reviewed (e.g., hearsay, authentication, privilege, expert witnesses, relevance), notes updated",
            preferredDuration: 60 * 60
        ),
        // tortlaw
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Analyze a torts hypothetical on negligence, intentional torts, products liability, or strict liability",
            successCriteria: "Torts analysis meaningfully advanced (issue identified, elements applied, damages addressed, at least one analysis section drafted and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "book.fill",
            task: "Study for my torts class exam — review negligence, intentional torts, strict liability, products liability, proximate cause, and defenses",
            successCriteria: "At least two torts topic areas reviewed (e.g., negligence, intentional torts, proximate cause, strict liability, defenses), case law reviewed, notes updated",
            preferredDuration: 60 * 60
        ),
        // architecturaldesign
        SuggestedTemplate(
            icon: "pencil.and.ruler.fill",
            task: "Develop my architectural design concept and produce design drawings for my studio project",
            successCriteria: "Design concept developed (parti/concept statement drafted), at least one design drawing or diagram produced and saved (plan, section, or elevation sketch)",
            preferredDuration: 90 * 60
        ),
        SuggestedTemplate(
            icon: "doc.richtext.fill",
            task: "Build out my architecture portfolio with project documentation and design narrative",
            successCriteria: "At least one portfolio project advanced (drawings selected or updated, design narrative drafted or refined, layout adjusted and saved)",
            preferredDuration: 60 * 60
        ),
        // historicpreservation
        SuggestedTemplate(
            icon: "building.columns.fill",
            task: "Complete my historic preservation survey or HABS documentation for a historic structure",
            successCriteria: "Survey or documentation meaningfully advanced (at least one structure researched, photos cataloged, or HABS form sections completed and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "book.fill",
            task: "Study for my historic preservation exam — review the Secretary of Interior Standards, NRHP criteria, adaptive reuse principles, and preservation technology",
            successCriteria: "At least two preservation topic areas reviewed (e.g., SOI standards, NRHP criteria, adaptive reuse, materials conservation), notes updated",
            preferredDuration: 60 * 60
        ),
        // sustainabledesign
        SuggestedTemplate(
            icon: "leaf.fill",
            task: "Work on my LEED project documentation or sustainable design studio assignment",
            successCriteria: "LEED scorecard or sustainable design deliverable meaningfully advanced (at least one credit category documented, energy model run, or design section drafted and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "book.fill",
            task: "Study for the LEED exam or a sustainable design class — review passive design, energy modeling, net-zero strategies, and green building rating systems",
            successCriteria: "At least two sustainable design topic areas reviewed (e.g., passive design, energy modeling, LEED credits, biophilic design, embodied carbon), notes updated",
            preferredDuration: 60 * 60
        ),
        // exhibitdesign
        SuggestedTemplate(
            icon: "theatermasks.fill",
            task: "Design an exhibit layout, visitor experience flow, or museum installation plan",
            successCriteria: "Exhibit design meaningfully advanced (floor plan or visitor flow diagram drafted, panel layout or display concept developed, and at least one deliverable saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "doc.richtext.fill",
            task: "Write exhibit label copy, interpretive text, or wayfinding signage content for my museum or gallery project",
            successCriteria: "At least two exhibit labels or a wayfinding sign system section drafted (text written, edited for reading level, and saved in the working document)",
            preferredDuration: 45 * 60
        ),
        // lightingdesign
        SuggestedTemplate(
            icon: "lightbulb.fill",
            task: "Develop a lighting design plan or photometric analysis for my architectural or theatrical lighting project",
            successCriteria: "Lighting plan or photometric calculation meaningfully advanced (fixture schedule drafted, lighting zones defined, or photometric report generated and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "book.fill",
            task: "Study for the NCQLP lighting certification exam or a lighting design class — review luminaire types, photometric principles, daylighting, and lighting standards",
            successCriteria: "At least two lighting topic areas reviewed (e.g., photometrics, daylighting, luminaire types, color temperature, IES standards), notes updated",
            preferredDuration: 60 * 60
        ),
        // socialentrepreneurship
        SuggestedTemplate(
            icon: "globe.americas.fill",
            task: "Develop my social enterprise business model, impact theory of change, or B-corp certification plan",
            successCriteria: "Social enterprise deliverable meaningfully advanced (business model canvas updated, theory of change drafted, or B-corp assessment section completed and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "book.fill",
            task: "Study for my social entrepreneurship or impact investing class — review social enterprise models, ESG frameworks, and mission-driven venture strategy",
            successCriteria: "At least two social entrepreneurship topic areas reviewed (e.g., B-corp, ESG, theory of change, impact measurement, social venture models), notes updated",
            preferredDuration: 45 * 60
        ),
        // yogapilates
        SuggestedTemplate(
            icon: "figure.yoga",
            task: "Study anatomy, sequencing, or teaching methodology for my yoga teacher training (RYT 200/500) program",
            successCriteria: "Yoga teacher training study session completed (at least one anatomy or sequencing topic reviewed, teaching methodology notes updated, and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "checkmark.seal.fill",
            task: "Prepare for my Pilates instructor certification exam — review repertoire, anatomy, cueing, and contraindications",
            successCriteria: "Pilates certification study meaningfully advanced (at least two topic areas reviewed, exam notes updated, and saved)",
            preferredDuration: 60 * 60
        ),
        // ayurvedic
        SuggestedTemplate(
            icon: "leaf.fill",
            task: "Study Ayurvedic principles, doshas, and herbal formulas for my Ayurvedic practitioner program or NAMA exam prep",
            successCriteria: "Ayurveda study session completed (at least one dosha, herbal formula, or treatment protocol reviewed and notes updated)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Complete my Ayurvedic medicine class assignment or write a patient intake and prakruti assessment",
            successCriteria: "Assignment or assessment meaningfully advanced (intake form drafted, prakruti analysis written, or class deliverable section completed and saved)",
            preferredDuration: 45 * 60
        ),
        // positivepsychology
        SuggestedTemplate(
            icon: "sun.max.fill",
            task: "Study for my positive psychology class exam — review the PERMA model, character strengths, flourishing theory, and Seligman's framework",
            successCriteria: "At least two positive psychology topics reviewed (e.g., PERMA, character strengths, well-being theory, grit, resilience, self-determination theory), notes updated",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Write a positive psychology paper or research assignment on character strengths, well-being, or flourishing",
            successCriteria: "Paper or assignment meaningfully advanced (outline drafted, at least one section written with key literature cited, and saved)",
            preferredDuration: 60 * 60
        ),
        // policeacademy
        SuggestedTemplate(
            icon: "shield.fill",
            task: "Study for the police officer entrance exam or POST certification — review laws, procedures, ethics, and scenario-based questions",
            successCriteria: "Exam prep meaningfully advanced (at least two subject areas reviewed, practice questions attempted, notes updated and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "doc.plaintext.fill",
            task: "Complete my police academy or law enforcement training assignment — review use-of-force policy, community policing, or report writing",
            successCriteria: "Training assignment meaningfully advanced (at least one policy area studied or report writing exercise completed and saved)",
            preferredDuration: 45 * 60
        ),
        // nursepractitioner
        SuggestedTemplate(
            icon: "stethoscope",
            task: "Study for the AANP or ANCC FNP-BC certification exam — review pharmacology, diagnostics, and primary care clinical guidelines",
            successCriteria: "Exam prep meaningfully advanced (at least two clinical topic areas reviewed, practice questions attempted, and notes updated and saved)",
            preferredDuration: 90 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Write up my NP clinical rotation SOAP notes or patient encounter summaries",
            successCriteria: "At least two patient encounter summaries or SOAP notes drafted, reviewed for clinical accuracy, and saved in the working document",
            preferredDuration: 30 * 60
        ),
        // mortuaryscience
        SuggestedTemplate(
            icon: "building.columns.fill",
            task: "Study for the NBE (National Board Examination) — review embalming science, funeral service law, and restorative art",
            successCriteria: "NBE prep meaningfully advanced (at least two subject areas reviewed, practice questions attempted, notes updated and saved)",
            preferredDuration: 90 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Complete my mortuary science class assignment or review embalming techniques, restorative art, or funeral home operations",
            successCriteria: "Mortuary science assignment meaningfully advanced (at least one topic area studied, key procedures or regulations reviewed, and notes saved)",
            preferredDuration: 45 * 60
        ),
        // polyvagaltheory
        SuggestedTemplate(
            icon: "brain.head.profile",
            task: "Study polyvagal theory concepts, somatic experiencing modules, or IFS therapy principles for my training program",
            successCriteria: "Somatic therapy training study session completed (at least one module or concept area reviewed, notes updated, and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Write up my somatic therapy session notes, IFS parts work reflection, or polyvagal theory assignment",
            successCriteria: "Assignment or session notes meaningfully advanced (key concepts documented, reflection written, or assignment section completed and saved)",
            preferredDuration: 45 * 60
        ),
        // virtualreality
        SuggestedTemplate(
            icon: "visionpro",
            task: "Build and test a VR or AR scene in my XR development project using Unity XR or Unreal Engine",
            successCriteria: "VR/AR scene meaningfully advanced (at least one scene element built or interaction scripted, project saved and tested in the headset or simulator)",
            preferredDuration: 90 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Study for my virtual reality or augmented reality development class and complete a practical assignment",
            successCriteria: "XR class work meaningfully advanced (concepts reviewed, assignment section completed or code committed and saved)",
            preferredDuration: 60 * 60
        ),
        // clinicalresearch
        SuggestedTemplate(
            icon: "cross.case.fill",
            task: "Study for the ACRP or SOCRA clinical research certification exam — review GCP principles, regulatory requirements, and trial operations",
            successCriteria: "Exam prep meaningfully advanced (at least two topic areas reviewed, practice questions attempted, and notes updated and saved)",
            preferredDuration: 90 * 60
        ),
        SuggestedTemplate(
            icon: "doc.plaintext.fill",
            task: "Review a clinical trial protocol, draft CRF completion guidelines, or complete a clinical research class assignment",
            successCriteria: "Clinical research work meaningfully advanced (protocol reviewed or assignment section completed and saved)",
            preferredDuration: 45 * 60
        ),
        // homeopathy
        SuggestedTemplate(
            icon: "leaf.fill",
            task: "Study homeopathic materia medica, practice remedy selection, or prepare for the CCH certification exam",
            successCriteria: "Homeopathy study session completed (at least two remedies or miasmatic concepts reviewed, notes updated and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Work through a homeopathic case analysis, write a case report, or study classical prescribing principles",
            successCriteria: "Homeopathic case work meaningfully advanced (case analysis written or at least one prescribing principle studied and notes saved)",
            preferredDuration: 45 * 60
        ),
        // recreationaltherapy
        SuggestedTemplate(
            icon: "figure.outdoor.cycle",
            task: "Study for the NCTRC CTRS certification exam — review therapeutic recreation practice areas and facilitation techniques",
            successCriteria: "CTRS exam prep meaningfully advanced (at least two topic areas reviewed, practice questions attempted, and notes updated and saved)",
            preferredDuration: 90 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Write up my recreational therapy session notes, treatment plan, or complete a TR program assignment",
            successCriteria: "TR clinical documentation or assignment meaningfully advanced (session notes drafted or treatment plan section completed and saved)",
            preferredDuration: 30 * 60
        ),
        // tibetanmedicine
        SuggestedTemplate(
            icon: "drop.fill",
            task: "Study Tibetan medicine theory — review Sowa Rigpa principles, the Gyushi, the three humors (loong, tripa, beken), or Tibetan herbal formulas",
            successCriteria: "Tibetan medicine study session completed (at least one chapter or concept area reviewed, notes updated and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Complete my Tibetan medicine class assignment or write up a patient case analysis using TTM diagnostic principles",
            successCriteria: "Assignment or case write-up meaningfully advanced (at least one diagnostic principle applied, notes written and saved)",
            preferredDuration: 45 * 60
        ),
        // waterresources
        SuggestedTemplate(
            icon: "drop.triangle.fill",
            task: "Solve water resources engineering problem sets — hydraulics, stormwater, or hydrology calculations",
            successCriteria: "Engineering problem set meaningfully advanced (at least three problems attempted with work shown, calculations saved or written up)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Complete a water treatment, water distribution, or hydraulic design assignment for my water resources class",
            successCriteria: "Assignment meaningfully advanced (design calculations or written sections completed and saved)",
            preferredDuration: 45 * 60
        ),
        // biophysics
        SuggestedTemplate(
            icon: "atom",
            task: "Work through biophysics problem sets — thermodynamics of living systems, membrane potential calculations, or protein kinetics",
            successCriteria: "Biophysics problem set meaningfully advanced (at least three problems worked through with derivations shown and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Write a biophysics lab report or complete a biophysics assignment on single-molecule methods or force spectroscopy",
            successCriteria: "Lab report or assignment meaningfully advanced (methods and results sections drafted or calculations completed and saved)",
            preferredDuration: 45 * 60
        ),
        // psychopharmacology
        SuggestedTemplate(
            icon: "brain.filled.head.profile",
            task: "Study psychopharmacology — review drug mechanisms, receptor pharmacology, and neurotransmitter systems for my class or exam",
            successCriteria: "Psychopharmacology study session completed (at least two drug classes or receptor mechanisms reviewed, notes updated and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Write a psychopharmacology paper or complete an assignment on psychiatric drug mechanisms, side effects, or clinical applications",
            successCriteria: "Assignment meaningfully advanced (at least one drug class analyzed in detail, key concepts written up and saved)",
            preferredDuration: 45 * 60
        ),
        // mediationarbitration
        SuggestedTemplate(
            icon: "person.2.fill",
            task: "Study alternative dispute resolution (ADR) principles and prepare for my mediation or arbitration certification exam",
            successCriteria: "ADR exam prep meaningfully advanced (at least two topic areas reviewed, practice scenarios considered, and notes updated and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Complete a mediation training assignment, write an arbitration brief, or prepare a dispute resolution case analysis",
            successCriteria: "ADR work meaningfully advanced (case analysis written or assignment section completed and saved)",
            preferredDuration: 45 * 60
        ),
        // sportslaw
        SuggestedTemplate(
            icon: "figure.run",
            task: "Study sports law concepts — review NCAA compliance, athlete contracts, sports governance, and Title IX for my class or exam",
            successCriteria: "Sports law study session completed (at least two topic areas reviewed, notes updated and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Complete a sports law assignment — analyze an athlete contract, write a sports governance memo, or work through a case study",
            successCriteria: "Sports law assignment meaningfully advanced (case analysis written or memo section completed and saved)",
            preferredDuration: 45 * 60
        ),
        // animalassistedtherapy
        SuggestedTemplate(
            icon: "pawprint.fill",
            task: "Study for animal-assisted therapy (AAT/AAI) certification — review protocols, ethics, handling techniques, and best practices",
            successCriteria: "AAT/AAI certification prep meaningfully advanced (at least two topic areas reviewed, handling protocols studied, notes updated and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Complete my therapy animal handling class assignment or write up an AAT session observation report",
            successCriteria: "Assignment or observation report meaningfully advanced (key sections drafted or one full observation write-up completed and saved)",
            preferredDuration: 30 * 60
        ),
        // constructionlaw
        SuggestedTemplate(
            icon: "building.columns.fill",
            task: "Study construction law concepts — AIA contracts, mechanics liens, payment bonds, surety, and construction claims for my class or exam",
            successCriteria: "Construction law study session completed (at least two topic areas reviewed, key contract clauses or lien rules understood, notes updated and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Complete a construction law assignment — analyze a contract dispute, draft a mechanics lien analysis, or work through a construction defect claim",
            successCriteria: "Construction law assignment meaningfully advanced (dispute analysis written or lien/claim section completed and saved)",
            preferredDuration: 45 * 60
        ),
        // healtheconomics
        SuggestedTemplate(
            icon: "chart.bar.xaxis",
            task: "Study health economics concepts — QALY calculations, ICER ratios, cost-effectiveness analysis, and health technology assessment frameworks",
            successCriteria: "Health economics study session completed (at least two analytical frameworks reviewed, sample calculations worked through, notes updated and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Complete a pharmacoeconomics or health technology assessment assignment for my health economics class",
            successCriteria: "Assignment meaningfully advanced (cost-effectiveness model built or written analysis section completed and saved)",
            preferredDuration: 45 * 60
        ),
        // insurancefinance
        SuggestedTemplate(
            icon: "shield.fill",
            task: "Study for my insurance licensing exam or CPCU/LOMA designation — review underwriting principles, policy provisions, and coverage concepts",
            successCriteria: "Insurance exam prep meaningfully advanced (at least two topic areas reviewed, practice questions attempted, notes updated and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Complete my insurance principles or risk and insurance class assignment — analyze a policy, underwriting case, or coverage scenario",
            successCriteria: "Assignment meaningfully advanced (policy analysis written or underwriting case section completed and saved)",
            preferredDuration: 45 * 60
        ),
        // environmentalplanning
        SuggestedTemplate(
            icon: "leaf.fill",
            task: "Study NEPA and CEQA environmental review processes — review EIS/EIA requirements, scoping, alternatives analysis, and mitigation measures",
            successCriteria: "Environmental planning study session completed (at least two regulatory frameworks reviewed, key procedural steps understood, notes updated and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Draft sections of an environmental impact statement (EIS) or complete an environmental permitting assignment for my planning class",
            successCriteria: "EIS draft or permitting assignment meaningfully advanced (at least one substantive section written or permit application component completed and saved)",
            preferredDuration: 45 * 60
        ),
        // tesol
        SuggestedTemplate(
            icon: "globe",
            task: "Study for my TESOL or TEFL certification — review second language acquisition theories, lesson planning methods, and assessment strategies",
            successCriteria: "TESOL/TEFL certification prep meaningfully advanced (at least two topic areas reviewed, practice activities or sample lessons drafted, notes updated and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Plan and write ESL lesson materials — create a lesson plan, develop activities, or complete my TESOL practicum assignment",
            successCriteria: "ESL lesson plan or practicum assignment meaningfully advanced (lesson objectives written, at least two activities planned, or assignment section completed and saved)",
            preferredDuration: 45 * 60
        ),
        // specialeducation
        SuggestedTemplate(
            icon: "person.crop.circle.badge.checkmark",
            task: "Study for my special education credential or PRAXIS special education exam — review IDEA/IDEIA, IEP process, disability categories, and inclusion strategies",
            successCriteria: "Special education exam prep meaningfully advanced (at least two topic areas reviewed, key legal requirements understood, notes updated and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Write IEP goals and objectives or complete a special education case study assignment for my SPED class",
            successCriteria: "IEP goals drafted or case study assignment meaningfully advanced (at least two measurable goals written or one case study section completed and saved)",
            preferredDuration: 45 * 60
        ),
        // foodscience
        SuggestedTemplate(
            icon: "flame.fill",
            task: "Study for my food science exam — review food chemistry, food microbiology, food processing, and sensory evaluation concepts",
            successCriteria: "Food science study session completed (at least two topic areas reviewed, key reactions or processes understood, notes updated and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Complete a food science lab report or product development assignment — analyze food chemistry data, sensory evaluation results, or processing parameters",
            successCriteria: "Food science lab report or assignment meaningfully advanced (data analyzed, results section drafted, or product formulation documented and saved)",
            preferredDuration: 45 * 60
        ),
        // animalwelfare
        SuggestedTemplate(
            icon: "pawprint.fill",
            task: "Study animal welfare science concepts — review IACUC protocols, animal enrichment, zoo management, and welfare legislation for my class or exam",
            successCriteria: "Animal welfare study session completed (at least two topic areas reviewed, key welfare principles or IACUC requirements understood, notes updated and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Complete an animal welfare or zoo science assignment — write an IACUC protocol, enrichment plan, or wildlife rehabilitation care report",
            successCriteria: "Animal welfare assignment meaningfully advanced (protocol, plan, or care report section completed and saved)",
            preferredDuration: 45 * 60
        ),
        // epidemiologicalmodeling
        SuggestedTemplate(
            icon: "chart.line.uptrend.xyaxis",
            task: "Build or analyze an epidemiological model — implement a SIR/SEIR compartmental model, estimate R\u{2080}, or complete a disease dynamics assignment",
            successCriteria: "Epidemic model meaningfully advanced (model implemented or coded, parameters estimated, or assignment section completed and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Study mathematical epidemiology concepts — review compartmental models, transmission dynamics, reproduction numbers, and intervention modeling for my class",
            successCriteria: "Mathematical epidemiology study session completed (at least two modeling concepts reviewed, key equations understood, notes updated and saved)",
            preferredDuration: 45 * 60
        ),
        // educationalleadership
        SuggestedTemplate(
            icon: "person.badge.key.fill",
            task: "Complete my educational leadership coursework — review ISLLC or PSEL standards, principal preparation theory, or school administration concepts for my EdD program or certificate",
            successCriteria: "Educational leadership study session completed (at least two standards or concepts reviewed, key leadership frameworks understood, notes updated and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Write an educational leadership assignment — develop a school improvement plan, analyze an administrative case study, or draft a reflective leadership paper",
            successCriteria: "Educational leadership assignment meaningfully advanced (school improvement plan section drafted, case study analysis written, or reflective paper section completed and saved)",
            preferredDuration: 45 * 60
        ),
        // medicalhumanities
        SuggestedTemplate(
            icon: "book.closed.fill",
            task: "Read and analyze a medical humanities text — close-read an illness narrative, explore the history of medicine, or analyze medicine in literature for my class or paper",
            successCriteria: "Medical humanities reading session completed (text meaningfully engaged, key themes or arguments identified, notes or annotations updated and saved)",
            preferredDuration: 45 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Write a medical humanities paper or response — analyze a patient narrative, connect narrative medicine theory to clinical practice, or examine a historical medical ethics case",
            successCriteria: "Medical humanities paper meaningfully advanced (analysis drafted, argument developed, or response section completed and saved)",
            preferredDuration: 45 * 60
        ),
        // healthequity
        SuggestedTemplate(
            icon: "heart.text.square.fill",
            task: "Study health equity concepts — review social determinants of health, health disparities frameworks, structural racism in healthcare, and equity-centered policy for my class or research",
            successCriteria: "Health equity study session completed (at least two SDOH frameworks or disparity topics reviewed, key concepts understood, notes updated and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Write a health equity paper or assignment — analyze health disparities data, apply SDOH frameworks, or develop a health equity intervention proposal",
            successCriteria: "Health equity assignment meaningfully advanced (analysis drafted, disparity data interpreted, or intervention proposal section completed and saved)",
            preferredDuration: 45 * 60
        ),
        // neurolaw
        SuggestedTemplate(
            icon: "brain.head.profile",
            task: "Study law and neuroscience concepts — review brain imaging evidence in court, adolescent culpability, criminal responsibility, and neuroethics for my class or seminar",
            successCriteria: "Neurolaw study session completed (at least two neuroscience-and-law topics reviewed, key cases or frameworks understood, notes updated and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Write a neurolaw paper or assignment — analyze how fMRI evidence affects criminal sentencing, evaluate neuroscience testimony standards, or examine adolescent brain and culpability doctrine",
            successCriteria: "Neurolaw assignment meaningfully advanced (analysis drafted, legal standards evaluated, or argument section completed and saved)",
            preferredDuration: 45 * 60
        ),
        // climatelaw
        SuggestedTemplate(
            icon: "leaf.fill",
            task: "Study climate law and international environmental agreements — review the Paris Agreement, carbon markets, emissions trading systems, and climate treaty frameworks for my class or exam",
            successCriteria: "Climate law study session completed (at least two treaty or carbon market frameworks reviewed, key legal obligations understood, notes updated and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Write a climate law assignment — analyze a carbon market regulation, critique international climate agreements, or research climate finance legal frameworks",
            successCriteria: "Climate law assignment meaningfully advanced (regulation analyzed, treaty critiqued, or climate finance research section completed and saved)",
            preferredDuration: 45 * 60
        ),
        // athletictraining
        SuggestedTemplate(
            icon: "figure.run",
            task: "Study athletic training concepts — review therapeutic modalities, taping and bracing techniques, or sport injury evaluation protocols for my ATC coursework or exam",
            successCriteria: "Athletic training study session completed (at least two modalities, techniques, or injury protocols reviewed, key concepts understood, notes updated and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Complete my athletic training program assignment — write up a sport injury evaluation, document a therapeutic modality treatment plan, or complete a taping lab report",
            successCriteria: "Athletic training assignment meaningfully advanced (injury evaluation documented, treatment plan written, or lab report section completed and saved)",
            preferredDuration: 45 * 60
        ),
        // biomechanics
        SuggestedTemplate(
            icon: "waveform.path.ecg",
            task: "Analyze biomechanics data — process motion capture results, interpret force plate data, or complete a gait analysis or kinematic analysis report for class",
            successCriteria: "Biomechanics analysis meaningfully advanced (data processed, key kinematic or kinetic variables calculated, interpretation written and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Study biomechanics concepts — review joint kinetics, kinematics, electromyography, or motion analysis methods for my biomechanics class or exam",
            successCriteria: "Biomechanics study session completed (at least two biomechanical principles or analysis methods reviewed, key equations or concepts understood, notes updated and saved)",
            preferredDuration: 45 * 60
        ),
        // zoology
        SuggestedTemplate(
            icon: "pawprint.fill",
            task: "Study zoology concepts — review animal taxonomy, invertebrate or vertebrate zoology, morphology, or comparative zoology for my class or exam",
            successCriteria: "Zoology study session completed (at least two taxonomic groups or zoological concepts reviewed, key identifications or principles understood, notes updated and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Complete a zoology lab report or assignment — write up a taxonomic classification exercise, animal morphology observation, or field zoology analysis",
            successCriteria: "Zoology assignment meaningfully advanced (classification completed, morphology described, or field observation written and saved)",
            preferredDuration: 45 * 60
        ),
        // militaryscience
        SuggestedTemplate(
            icon: "shield.fill",
            task: "Complete my military science or ROTC coursework — study leadership doctrine, review tactics class material, or prepare for an ROTC lab or leadership assessment",
            successCriteria: "Military science study session completed (leadership doctrine or tactics material reviewed, key concepts understood, lab prep or coursework notes updated and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Write a military science paper or ROTC assignment — analyze a leadership case study, complete a military tactics assignment, or write up a cadet training reflection",
            successCriteria: "Military science assignment meaningfully advanced (case study analyzed, tactics assignment drafted, or reflection written and saved)",
            preferredDuration: 45 * 60
        ),
        // healthinformatics
        SuggestedTemplate(
            icon: "chart.bar.xaxis",
            task: "Study health informatics concepts — review HL7 FHIR standards, health data interoperability, clinical decision support systems, or CPHIMS exam material for my program",
            successCriteria: "Health informatics study session completed (at least two interoperability standards or informatics concepts reviewed, key terms understood, notes updated and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Complete a health informatics assignment — analyze a FHIR implementation case, design a clinical data exchange workflow, or write up a health IT interoperability analysis",
            successCriteria: "Health informatics assignment meaningfully advanced (FHIR case analyzed, workflow designed, or interoperability analysis section completed and saved)",
            preferredDuration: 45 * 60
        ),
        // cryptography
        SuggestedTemplate(
            icon: "lock.fill",
            task: "Study cryptography concepts — review AES and RSA algorithms, public-key cryptography, Diffie-Hellman key exchange, or number theory for my cryptography class or exam",
            successCriteria: "Cryptography study session completed (at least two cipher schemes or protocols reviewed, key mathematical properties understood, notes updated and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Complete a cryptography assignment — implement a cipher, analyze an encryption protocol, solve number theory problems, or write up a cryptographic security analysis",
            successCriteria: "Cryptography assignment meaningfully advanced (cipher implemented or analyzed, protocol security evaluated, or problem set section completed and saved)",
            preferredDuration: 60 * 60
        ),
        // appliedmathematics
        SuggestedTemplate(
            icon: "function",
            task: "Work through my applied mathematics assignment — solve differential equations, numerical methods problems, or a mathematical modeling problem set",
            successCriteria: "Applied math assignment meaningfully advanced (at least one ODE/PDE problem solved or numerical method implemented, work shown and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Study applied mathematics concepts — review differential equations, scientific computing methods, finite element analysis, or mathematical modeling techniques for my class or exam",
            successCriteria: "Applied math study session completed (at least two methods or techniques reviewed, key algorithms or solution approaches understood, notes updated and saved)",
            preferredDuration: 45 * 60
        ),
        // historicallinguistics
        SuggestedTemplate(
            icon: "text.book.closed.fill",
            task: "Study historical linguistics — review sound change laws (Grimm's Law, Verner's Law), proto-language reconstruction, diachronic phonology, or etymology for my class or exam",
            successCriteria: "Historical linguistics study session completed (at least two change laws or reconstruction principles reviewed, key patterns understood, notes updated and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Complete a historical linguistics assignment — trace sound changes, reconstruct proto-language forms, analyze semantic drift, or write a diachronic analysis paper",
            successCriteria: "Historical linguistics assignment meaningfully advanced (sound changes traced, proto-forms reconstructed, or paper section drafted and saved)",
            preferredDuration: 45 * 60
        ),
        // computationalfinance
        SuggestedTemplate(
            icon: "chart.line.uptrend.xyaxis",
            task: "Work on my quantitative finance assignment — derive the Black-Scholes model, build a Monte Carlo simulation for options pricing, or implement an algorithmic trading strategy",
            successCriteria: "Quant finance assignment meaningfully advanced (model derived, simulation coded or running, or strategy logic implemented and tested)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Study computational finance concepts — review stochastic calculus, options pricing, financial engineering models, or risk-neutral pricing for my quantitative finance program",
            successCriteria: "Computational finance study session completed (at least two models or pricing methods reviewed, key formulas understood, notes updated and saved)",
            preferredDuration: 60 * 60
        ),
        // globalpoliticaleconomy
        SuggestedTemplate(
            icon: "globe",
            task: "Study international political economy (IPE) — review world systems theory, dependency theory, comparative political economy, or global governance frameworks for my class or exam",
            successCriteria: "IPE study session completed (at least two frameworks or theoretical perspectives reviewed, key arguments understood, notes updated and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Write a political economy paper or assignment — analyze a global economic governance issue, apply IPE theory to a case study, or critique dependency theory arguments",
            successCriteria: "Political economy assignment meaningfully advanced (theoretical framework applied, case study analyzed, or argument section drafted and saved)",
            preferredDuration: 60 * 60
        ),
        // geopolitics
        SuggestedTemplate(
            icon: "globe.europe.africa.fill",
            task: "Write a geopolitical analysis — assess geopolitical risk, analyze great power competition, or evaluate geopolitical strategy in a regional context",
            successCriteria: "Geopolitical analysis meaningfully advanced (risk factors identified, strategic dynamics analyzed, or argument section drafted and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Complete a geopolitics assignment or research paper — analyze geopolitical tensions, map rivalry dynamics, or evaluate a geopolitical forecast",
            successCriteria: "Geopolitics assignment meaningfully advanced (key arguments articulated, evidence incorporated, or analysis section drafted and saved)",
            preferredDuration: 45 * 60
        ),
        // computationalbiology
        SuggestedTemplate(
            icon: "waveform.path.ecg",
            task: "Work on a computational biology project — build a systems biology model, simulate population dynamics, or analyze a biological network",
            successCriteria: "Computational biology project meaningfully advanced (model coded or running, simulation output generated, or network analysis section completed and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Study computational biology concepts — review systems biology, mathematical biology, biological network analysis, or ODE modeling for my class or exam",
            successCriteria: "Computational biology study session completed (at least two modeling approaches reviewed, key concepts understood, notes updated and saved)",
            preferredDuration: 45 * 60
        ),
        // philosophyofmind
        SuggestedTemplate(
            icon: "brain.head.profile",
            task: "Write a philosophy of mind paper — argue a position on consciousness, qualia, the mind-body problem, functionalism, or phenomenal experience",
            successCriteria: "Philosophy of mind paper meaningfully advanced (thesis stated, key argument laid out with supporting evidence, or a section drafted and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Study philosophy of mind — review consciousness theories, qualia, the hard problem, functionalism, or phenomenology for my class or exam",
            successCriteria: "Philosophy of mind study session completed (at least two theories or positions reviewed, key distinctions understood, notes updated and saved)",
            preferredDuration: 45 * 60
        ),
        // digitalhumanities
        SuggestedTemplate(
            icon: "doc.richtext.fill",
            task: "Work on a digital humanities project — run text mining or topic modeling on a corpus, build a network analysis of historical texts, or develop a cultural analytics workflow",
            successCriteria: "Digital humanities project meaningfully advanced (analysis pipeline running, initial results reviewed, or findings section drafted and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Study digital humanities methods — review distant reading, corpus analysis, spatial humanities, or digital archive tools for my class or project",
            successCriteria: "Digital humanities study session completed (at least two methods reviewed, tool or technique practiced, notes updated and saved)",
            preferredDuration: 45 * 60
        ),
        // environmentalpolicy
        SuggestedTemplate(
            icon: "leaf.fill",
            task: "Write an environmental policy paper — analyze climate legislation, evaluate a carbon tax or cap-and-trade scheme, or assess environmental governance frameworks",
            successCriteria: "Environmental policy paper meaningfully advanced (policy analyzed, argument structured, or a key section drafted and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Study environmental policy concepts — review climate policy instruments, environmental regulation, carbon markets, or climate adaptation frameworks for my class or exam",
            successCriteria: "Environmental policy study session completed (at least two policy instruments or frameworks reviewed, key tradeoffs understood, notes updated and saved)",
            preferredDuration: 45 * 60
        ),
        // cognitivelinguistics
        SuggestedTemplate(
            icon: "text.bubble.fill",
            task: "Write a cognitive linguistics analysis — apply conceptual metaphor theory, frame semantics, or construction grammar to a language phenomenon",
            successCriteria: "Cognitive linguistics analysis meaningfully advanced (theoretical framework applied, linguistic evidence analyzed, or a key section drafted and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Study cognitive linguistics — review Lakoff's metaphor theory, Langacker's cognitive grammar, Fillmore's frame semantics, or conceptual blending for my class or exam",
            successCriteria: "Cognitive linguistics study session completed (at least two frameworks reviewed, key concepts understood, notes updated and saved)",
            preferredDuration: 45 * 60
        ),
        // environmentaljustice
        SuggestedTemplate(
            icon: "leaf.circle.fill",
            task: "Write an environmental justice paper — analyze cumulative environmental burdens, environmental racism, EJ mapping, or just transition policy",
            successCriteria: "Environmental justice paper meaningfully advanced (EJ framework applied, case evidence incorporated, or a key section drafted and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Study environmental justice concepts — review EJ frameworks, sacrifice zone cases, EJSCREEN methodology, or environmental health disparities for my class or exam",
            successCriteria: "Environmental justice study session completed (at least two EJ concepts or cases reviewed, key frameworks understood, notes updated and saved)",
            preferredDuration: 45 * 60
        ),
        // schoolcounseling
        SuggestedTemplate(
            icon: "person.2.fill",
            task: "Complete my school counseling practicum notes or CACREP-based case conceptualization for my supervised hours",
            successCriteria: "Practicum notes or case conceptualization completed and saved (client goals documented, interventions recorded, or progress section drafted)",
            preferredDuration: 45 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Study for my school counseling licensure exam or complete a school counseling or student affairs coursework assignment",
            successCriteria: "Study session completed (at least two counseling theories or career development models reviewed, notes updated and saved)",
            preferredDuration: 60 * 60
        ),
        // cognitivepsychology
        SuggestedTemplate(
            icon: "brain.head.profile",
            task: "Study cognitive psychology — review working memory models, attention and perception, cognitive load theory, or information processing for my class or exam",
            successCriteria: "Cognitive psychology study session completed (at least two cognitive models reviewed, key distinctions understood, notes updated and saved)",
            preferredDuration: 45 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Write a cognitive psychology paper or complete a cognitive research methods assignment — working memory, selective attention, dual-process theory, or cognitive aging",
            successCriteria: "Cognitive psychology paper or assignment meaningfully advanced (research question framed, evidence reviewed, or a key section drafted and saved)",
            preferredDuration: 60 * 60
        ),
        // developmentalpsychology
        SuggestedTemplate(
            icon: "figure.and.child.holdinghands",
            task: "Study developmental psychology — review Vygotsky's ZPD, Erikson's psychosocial stages, Kohlberg's moral development, or lifespan developmental milestones for my class or exam",
            successCriteria: "Developmental psychology study session completed (at least two theorists or developmental stages reviewed, key distinctions understood, notes updated and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Write a developmental psychology paper — analyze child development theory, lifespan stages, zone of proximal development, or adolescent identity formation",
            successCriteria: "Developmental psychology paper meaningfully advanced (theoretical lens applied, developmental evidence cited, or a key section drafted and saved)",
            preferredDuration: 60 * 60
        ),
        // paleontology
        SuggestedTemplate(
            icon: "magnifyingglass",
            task: "Analyze fossil evidence and complete my paleontology lab report or field notes — taphonomy, biostratigraphy, or paleobiology",
            successCriteria: "Paleontology lab report or field notes meaningfully advanced (fossil evidence interpreted, taphonomic or stratigraphic analysis documented, or a key section drafted and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Study for my paleontology exam — review the fossil record, geologic time periods, invertebrate or vertebrate paleontology, or trace fossils",
            successCriteria: "Paleontology study session completed (at least two time periods, fossil types, or taphonomic concepts reviewed, notes updated and saved)",
            preferredDuration: 45 * 60
        ),
        // experimentalphysics
        SuggestedTemplate(
            icon: "atom",
            task: "Write my physics lab report — analyze experimental data from optics, mechanics, electromagnetism, or thermodynamics lab",
            successCriteria: "Physics lab report meaningfully advanced (data analyzed, graphs produced, error analysis included, or a key section — introduction, methods, results, or discussion — drafted and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "waveform.path",
            task: "Complete my quantum mechanics or classical mechanics problem set for my physics class",
            successCriteria: "Physics problem set meaningfully advanced (at least three problems attempted with work shown, or a full problem section completed and checked)",
            preferredDuration: 60 * 60
        ),
        // informationscience
        SuggestedTemplate(
            icon: "folder.fill",
            task: "Complete my information science assignment — information retrieval, knowledge management, digital curation, or information organization",
            successCriteria: "Information science assignment meaningfully advanced (retrieval model applied, knowledge structure documented, or a key section drafted and saved)",
            preferredDuration: 45 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Study for my information science exam or complete coursework on information retrieval, metadata, or digital curation",
            successCriteria: "Information science study session completed (at least two frameworks or retrieval models reviewed, key concepts understood, notes updated and saved)",
            preferredDuration: 45 * 60
        ),
        // socialepidemiology
        SuggestedTemplate(
            icon: "heart.text.clipboard.fill",
            task: "Write a social epidemiology paper — analyze social determinants of health, health disparities, or health inequities in a population",
            successCriteria: "Social epidemiology paper meaningfully advanced (SDoH framework applied, disparity evidence cited, or a key section drafted and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Study social epidemiology concepts — social determinants of health, health disparities research, the social gradient of health, or life-course epidemiology",
            successCriteria: "Social epidemiology study session completed (at least two SDoH frameworks or health disparity concepts reviewed, notes updated and saved)",
            preferredDuration: 45 * 60
        ),
        // cognitiveneuroscience
        SuggestedTemplate(
            icon: "brain",
            task: "Analyze my fMRI or EEG data for my cognitive neuroscience research project — BOLD signal, functional connectivity, or event-related potentials",
            successCriteria: "Cognitive neuroscience data analysis meaningfully advanced (neuroimaging pipeline run, ERP waveforms plotted, or a key results section drafted and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Study cognitive neuroscience — review fMRI methodology, BOLD signal, EEG/ERP study design, or neuroimaging analysis for my class or exam",
            successCriteria: "Cognitive neuroscience study session completed (at least two neuroimaging methods or cognitive-brain frameworks reviewed, notes updated and saved)",
            preferredDuration: 45 * 60
        ),
        // nanotechnology
        SuggestedTemplate(
            icon: "atom",
            task: "Complete my nanotechnology lab report or assignment — nanomaterials characterization, nanofabrication, quantum dots, or carbon nanotubes",
            successCriteria: "Nanotechnology lab report or assignment meaningfully advanced (characterization data analyzed, synthesis results documented, or a key section drafted and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Study for my nanotechnology exam — nanoscale imaging, quantum confinement, nanomaterials properties, or nanofabrication techniques",
            successCriteria: "Nanotechnology study session completed (at least two nanoscale concepts or characterization methods reviewed, notes updated and saved)",
            preferredDuration: 45 * 60
        ),
        // appliedlinguistics
        SuggestedTemplate(
            icon: "text.bubble.fill",
            task: "Write my applied linguistics paper — second language acquisition theory, language pedagogy, discourse analysis, or language assessment",
            successCriteria: "Applied linguistics paper meaningfully advanced (SLA framework applied, language data analyzed, or a key section drafted and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Study applied linguistics — second language acquisition, language policy, interlanguage theory, or language testing for my class or exam",
            successCriteria: "Applied linguistics study session completed (at least two SLA theories or language assessment frameworks reviewed, notes updated and saved)",
            preferredDuration: 45 * 60
        ),
        // radiobiology
        SuggestedTemplate(
            icon: "waveform.path",
            task: "Complete my radiobiology assignment or lab report — DNA damage mechanisms, survival curves, linear energy transfer, or radiation-induced cell death",
            successCriteria: "Radiobiology assignment meaningfully advanced (radiation effect data analyzed, survival curves plotted, or a key section drafted and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Study radiobiology — ionizing radiation biology, DNA repair mechanisms, relative biological effectiveness, or fractionated radiation effects",
            successCriteria: "Radiobiology study session completed (at least two radiation biology mechanisms or dosimetry concepts reviewed, notes updated and saved)",
            preferredDuration: 45 * 60
        ),
        // translationstudies
        SuggestedTemplate(
            icon: "character.book.closed.fill",
            task: "Work on my literary translation or translation studies project — translate a passage, apply a translation theory, or use CAT tools like Trados or MemoQ",
            successCriteria: "Translation project meaningfully advanced (at least one passage translated with annotations, a translation theory applied, or a segment completed in CAT tool and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Study translation theory or complete my translation studies coursework — equivalence, domestication/foreignization, CAT tools, or localization methods",
            successCriteria: "Translation studies session completed (at least two translation theories reviewed, a text analyzed, or coursework notes updated and saved)",
            preferredDuration: 45 * 60
        ),
        // ecologyconservation
        SuggestedTemplate(
            icon: "leaf.fill",
            task: "Write a conservation biology report or complete an ecology lab — species management, habitat restoration, population viability analysis, or wildlife corridor design",
            successCriteria: "Conservation biology assignment meaningfully advanced (field data analyzed, species management plan drafted, or a key section of the report written and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Study conservation ecology — restoration ecology, biodiversity conservation, wildlife management, or landscape ecology for my class or exam",
            successCriteria: "Conservation ecology study session completed (at least two conservation frameworks or species management methods reviewed, notes updated and saved)",
            preferredDuration: 45 * 60
        ),
        // astrobiology
        SuggestedTemplate(
            icon: "sparkles",
            task: "Complete my astrobiology assignment — extremophiles, planetary habitability, biosignatures, prebiotic chemistry, or SETI science",
            successCriteria: "Astrobiology assignment meaningfully advanced (at least one key concept analyzed, lab data reviewed, or a section of the report written and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Study astrobiology — origin of life, habitable zones, biosignatures, or extremophile biology for my class or exam",
            successCriteria: "Astrobiology study session completed (at least two topics reviewed, notes updated and saved)",
            preferredDuration: 45 * 60
        ),
        // materialscharacterization
        SuggestedTemplate(
            icon: "waveform.path.ecg",
            task: "Analyze and write up my materials characterization data — XRD patterns, SEM/TEM images, FTIR or Raman spectra, or thermal analysis results",
            successCriteria: "Materials characterization report meaningfully advanced (data analyzed, spectra assigned, or a key section of the lab report written and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Study materials characterization techniques — XRD, SEM/TEM, spectroscopy, or thermal analysis for my class or exam",
            successCriteria: "Materials characterization study session completed (at least two techniques reviewed, notes updated and saved)",
            preferredDuration: 45 * 60
        ),
        // toxicogenomics
        SuggestedTemplate(
            icon: "chart.bar.fill",
            task: "Analyze my toxicogenomics data — gene expression under toxic exposure, AhR pathway, TOXCAST dataset, or omics-level toxicology assignment",
            successCriteria: "Toxicogenomics assignment meaningfully advanced (data analyzed, pathways annotated, or a key section of the report written and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Study toxicogenomics — gene expression profiling under toxic exposure, dose-response genomics, or adverse outcome pathways for my class or exam",
            successCriteria: "Toxicogenomics study session completed (at least two concepts reviewed, notes updated and saved)",
            preferredDuration: 45 * 60
        ),
        // developmentalbiology
        SuggestedTemplate(
            icon: "circle.hexagongrid.fill",
            task: "Complete my developmental biology assignment — morphogen gradients, Hox genes, fate mapping, organogenesis, or zebrafish/drosophila embryo analysis",
            successCriteria: "Developmental biology assignment meaningfully advanced (at least one key mechanism analyzed or a section of the lab report written and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Study developmental biology — morphogenesis, cell fate specification, Hox genes, gastrulation, or gene regulatory networks for my class or exam",
            successCriteria: "Developmental biology study session completed (at least two developmental mechanisms reviewed, notes updated and saved)",
            preferredDuration: 45 * 60
        ),
        // drugdiscovery
        SuggestedTemplate(
            icon: "pills.fill",
            task: "Work on my drug discovery assignment — lead optimization, ADMET analysis, structure-activity relationships, or virtual screening for a medicinal chemistry project",
            successCriteria: "Drug discovery assignment meaningfully advanced (at least one SAR analysis completed, docking results reviewed, or a section of the report written and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Study drug discovery and medicinal chemistry — lead optimization, high-throughput screening, ADMET, pharmacophore modeling, or SAR for my class or exam",
            successCriteria: "Drug discovery study session completed (at least two concepts reviewed, notes updated and saved)",
            preferredDuration: 45 * 60
        ),
        // organicchemistry
        SuggestedTemplate(
            icon: "atom",
            task: "Complete my organic chemistry problem set — reaction mechanisms, SN1/SN2/E1/E2, aldol condensation, Diels-Alder, or Grignard reagents",
            successCriteria: "Organic chemistry problem set meaningfully advanced (at least one mechanism drawn correctly or a section of the lab report written and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Study organic chemistry for my exam — review NMR spectroscopy, stereochemistry, synthesis planning, or retrosynthetic analysis",
            successCriteria: "Orgo study session completed (at least two reaction types or mechanisms reviewed, notes updated and saved)",
            preferredDuration: 45 * 60
        ),
        // botany
        SuggestedTemplate(
            icon: "leaf.fill",
            task: "Complete my botany lab report or assignment — plant taxonomy, plant physiology, herbarium specimens, or plant ecology fieldwork",
            successCriteria: "Botany assignment meaningfully advanced (at least one plant identification or physiological analysis completed and written up)",
            preferredDuration: 45 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Study plant biology for my botany exam — review plant anatomy, plant systematics, ethnobotany, or plant pathology",
            successCriteria: "Botany study session completed (at least two plant biology topics reviewed, notes updated and saved)",
            preferredDuration: 45 * 60
        ),
        // operationsresearch
        SuggestedTemplate(
            icon: "chart.bar.fill",
            task: "Work on my operations research problem set — linear programming, integer programming, network flow models, or queueing theory",
            successCriteria: "Operations research problem set meaningfully advanced (at least one LP/IP model formulated and solved, or a queueing analysis written and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Study operations research for my exam — review linear programming, simplex method, transportation models, or stochastic optimization",
            successCriteria: "OR study session completed (at least two OR techniques reviewed with worked examples, notes updated and saved)",
            preferredDuration: 45 * 60
        ),
        // internalaudit
        SuggestedTemplate(
            icon: "checkmark.seal.fill",
            task: "Study for the CIA certification exam — review IIA standards, internal controls, risk-based audit, audit planning, or control testing",
            successCriteria: "CIA exam study session completed (at least two IIA standard domains reviewed, practice questions attempted and notes updated)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Complete my internal audit assignment — write an audit report, test internal controls, review SOX compliance, or analyze audit findings",
            successCriteria: "Internal audit assignment meaningfully advanced (at least one audit procedure documented or a section of the report written and saved)",
            preferredDuration: 45 * 60
        ),
        // healthcarequality
        SuggestedTemplate(
            icon: "heart.text.square.fill",
            task: "Study for the CPHQ exam — review patient safety principles, quality improvement tools, Joint Commission standards, or healthcare accreditation",
            successCriteria: "CPHQ study session completed (at least two quality domains reviewed, practice questions attempted and notes updated)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Complete my healthcare quality improvement project — write a QI proposal, analyze patient safety data, apply PDSA cycles, or prepare a root cause analysis",
            successCriteria: "Healthcare quality project meaningfully advanced (at least one QI tool applied, data analyzed, or a section of the project written and saved)",
            preferredDuration: 45 * 60
        ),
        // nursinganesthesia
        SuggestedTemplate(
            icon: "staroflife.fill",
            task: "Study for the NBCRNA exam or CRNA school coursework — review anesthesia pharmacology, anesthesia equipment, or clinical anesthesia concepts",
            successCriteria: "Nurse anesthesia study session completed (at least two anesthesia concepts reviewed, practice questions attempted and notes updated)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Complete my nurse anesthesia clinical notes, case summaries, or CRNA program coursework assignments",
            successCriteria: "Nurse anesthesia assignment meaningfully advanced (at least one clinical case documented or a section of coursework written and saved)",
            preferredDuration: 45 * 60
        ),
        // physicalchemistry
        SuggestedTemplate(
            icon: "atom",
            task: "Work through my physical chemistry problem set — Gibbs energy, chemical kinetics, partition functions, molecular orbital theory, or quantum chemistry",
            successCriteria: "Pchem problem set meaningfully advanced (at least two problems worked through with steps shown and notes saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Study physical chemistry for my exam — review thermodynamics of reactions, chemical kinetics, statistical thermodynamics, or the Schrödinger equation",
            successCriteria: "Pchem study session completed (at least two concepts reviewed with worked examples and notes saved)",
            preferredDuration: 45 * 60
        ),
        // inorganicchemistry
        SuggestedTemplate(
            icon: "atom",
            task: "Complete my inorganic chemistry problem set — coordination complexes, crystal field theory, ligand field, d-block elements, or organometallic chemistry",
            successCriteria: "Inorganic chemistry assignment meaningfully advanced (at least two problems solved or a section of the lab report written and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Study inorganic chemistry for my exam — review crystal field splitting, coordination chemistry, molecular symmetry, or main group chemistry",
            successCriteria: "Inorganic chemistry study session completed (at least two inorganic concepts reviewed with examples and notes saved)",
            preferredDuration: 45 * 60
        ),
        // analyticalchemistry
        SuggestedTemplate(
            icon: "chart.line.uptrend.xyaxis",
            task: "Complete my analytical chemistry lab report or problem set — HPLC, GC-MS, titration, gravimetric analysis, or mass spectrometry data analysis",
            successCriteria: "Analytical chemistry assignment meaningfully advanced (at least one technique analyzed or a section of the lab report written and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Study analytical chemistry for my exam — review chromatography methods, titration, spectroscopy techniques, or quantitative analysis",
            successCriteria: "Analytical chemistry study session completed (at least two techniques reviewed with worked examples and notes saved)",
            preferredDuration: 45 * 60
        ),
        // nuclearchemistry
        SuggestedTemplate(
            icon: "rays",
            task: "Work through my nuclear chemistry problem set — radioactive decay, half-life calculations, nuclear equations, fission, or fusion reactions",
            successCriteria: "Nuclear chemistry problem set meaningfully advanced (at least two decay or reaction problems solved correctly and notes saved)",
            preferredDuration: 45 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Study nuclear chemistry for my exam — review radioactive isotopes, alpha/beta/gamma decay, nuclear binding energy, and decay series",
            successCriteria: "Nuclear chemistry study session completed (at least two nuclear concepts reviewed with worked examples and notes saved)",
            preferredDuration: 45 * 60
        ),
        // electrochemistry
        SuggestedTemplate(
            icon: "bolt.circle.fill",
            task: "Work through my electrochemistry problem set — galvanic cells, Nernst equation, electrode potentials, electrolysis, or cyclic voltammetry",
            successCriteria: "Electrochemistry problem set completed (at least three problems solved with cell diagrams or half-reactions worked out and notes saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "bolt.circle.fill",
            task: "Study electrochemistry for my exam — review electrochemical cells, Nernst equation, standard reduction potentials, electrolytic cells, and Faraday's laws",
            successCriteria: "Electrochemistry study session completed (galvanic and electrolytic cells understood, Nernst equation practiced, notes saved)",
            preferredDuration: 45 * 60
        ),
        // polymerchemistry
        SuggestedTemplate(
            icon: "link.circle.fill",
            task: "Work through my polymer chemistry problem set — polymerization reactions, molecular weight distribution, polydispersity index, or chain-growth mechanisms",
            successCriteria: "Polymer chemistry problem set completed (at least three problems solved with polymerization mechanisms drawn and notes saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "link.circle.fill",
            task: "Study polymer chemistry for my exam — review addition and condensation polymerization, molar mass distribution, polydispersity, and polymer characterization",
            successCriteria: "Polymer chemistry study session completed (at least two polymerization types reviewed with mechanisms and notes saved)",
            preferredDuration: 45 * 60
        ),
        // maternalhealth
        SuggestedTemplate(
            icon: "heart.text.square.fill",
            task: "Complete my maternal health or OB nursing assignment — obstetric nursing care plans, prenatal care protocols, maternal-fetal assessment, or postpartum nursing notes",
            successCriteria: "Maternal health assignment completed (care plan or assessment written, at least two maternal health concepts applied with sources cited)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "heart.text.square.fill",
            task: "Study maternal health for my OB nursing exam — review prenatal care, intrapartum nursing, postpartum care, maternal mortality, or obstetric complications",
            successCriteria: "Maternal health study session completed (at least three OB nursing topics reviewed with clinical rationales and notes saved)",
            preferredDuration: 45 * 60
        ),
        // globalhealthpolicy
        SuggestedTemplate(
            icon: "globe.americas.fill",
            task: "Work on my global health policy paper or assignment — health systems strengthening, universal health coverage, global burden of disease, or international health regulations",
            successCriteria: "Global health policy work completed (at least two policy frameworks analyzed, paper section drafted or outline completed with citations saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "globe.americas.fill",
            task: "Study global health policy for my exam — review health systems strengthening, UHC frameworks, WHO governance, global health financing, and SDG health targets",
            successCriteria: "Global health policy study session completed (at least two global health frameworks reviewed with key concepts and examples noted)",
            preferredDuration: 45 * 60
        ),
        // processengineering
        SuggestedTemplate(
            icon: "gearshape.2.fill",
            task: "Work through my unit operations or chemical process engineering problem set — mass and energy balances, reactor design, transport phenomena, or distillation",
            successCriteria: "Process engineering problem set completed (at least three problems solved with unit ops calculations and Aspen Plus results or hand calculations saved)",
            preferredDuration: 75 * 60
        ),
        SuggestedTemplate(
            icon: "gearshape.2.fill",
            task: "Study process engineering for my exam — review unit operations, reactor design (PFR/CSTR), transport phenomena, mass and energy balances, and process control",
            successCriteria: "Process engineering study session completed (at least two unit operations topics reviewed with worked examples and notes saved)",
            preferredDuration: 60 * 60
        ),
        // civilengineering
        SuggestedTemplate(
            icon: "building.columns.fill",
            task: "Work through my civil engineering problem set — structural analysis, reinforced concrete design, geotechnical engineering, beam loading, or truss analysis",
            successCriteria: "Civil engineering problem set completed (at least three problems solved with structural calculations, load diagrams, or geotechnical analysis saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "building.columns.fill",
            task: "Study civil engineering for my exam — review structural analysis, reinforced concrete design, soil mechanics, foundation design, and seismic or transportation engineering",
            successCriteria: "Civil engineering study session completed (at least two structural or geotechnical topics reviewed with worked examples and notes saved)",
            preferredDuration: 60 * 60
        ),
        // syntheticbiology
        SuggestedTemplate(
            icon: "circle.hexagongrid.fill",
            task: "Work on my synthetic biology project — design a genetic circuit, build a metabolic pathway, plan an iGEM construct, or assemble BioBrick parts",
            successCriteria: "Synthetic biology work completed (genetic circuit designed or BioBrick construct planned, at least one design iteration documented with rationale saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "circle.hexagongrid.fill",
            task: "Study synthetic biology for my exam — review genetic circuit design, metabolic engineering principles, BioBrick assembly, iGEM project structure, or protein engineering",
            successCriteria: "Synthetic biology study session completed (at least two synbio topics reviewed with design logic and examples noted)",
            preferredDuration: 45 * 60
        ),
        // proteomics
        SuggestedTemplate(
            icon: "waveform.path.ecg",
            task: "Analyze my proteomics data — interpret LC-MS/MS spectra, identify peptides and proteins, perform label-free quantification, or write up my mass spectrometry results",
            successCriteria: "Proteomics analysis completed (protein identification list generated or quantification results interpreted, results documented with at least two validation checks)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "waveform.path.ecg",
            task: "Study proteomics for my exam — review shotgun proteomics workflows, 2D-PAGE, LC-MS/MS, peptide fragmentation, and protein quantification methods",
            successCriteria: "Proteomics study session completed (at least two MS-based proteomics techniques reviewed with experimental workflow and notes saved)",
            preferredDuration: 45 * 60
        ),
        // metabolomics
        SuggestedTemplate(
            icon: "atom",
            task: "Analyze my metabolomics data — interpret NMR or LC-MS metabolite profiles, identify biomarkers, perform metabolic pathway analysis, or write up my metabolomics results",
            successCriteria: "Metabolomics analysis completed (at least five metabolites annotated or pathway enrichment analysis documented with results saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "atom",
            task: "Study metabolomics for my exam — review NMR-based and LC-MS metabolomics workflows, metabolite annotation, pathway analysis, and metabolic flux analysis methods",
            successCriteria: "Metabolomics study session completed (at least two metabolomics analytical platforms reviewed with workflow steps and notes saved)",
            preferredDuration: 45 * 60
        ),
        // electrophysiology
        SuggestedTemplate(
            icon: "waveform",
            task: "Analyze my electrophysiology data — sort spikes from a single-unit recording, analyze patch clamp traces, interpret local field potentials, or write up my MEA results",
            successCriteria: "Electrophysiology analysis completed (at least one recording session analyzed, spike sorted or trace interpreted, key results documented and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "waveform",
            task: "Study electrophysiology for my exam — review patch clamp techniques, action potential recording, voltage and current clamp, spike sorting, and in vivo recording methods",
            successCriteria: "Electrophysiology study session completed (at least two recording techniques reviewed with principles, protocols, and notes saved)",
            preferredDuration: 45 * 60
        ),
        // aerospacengineering
        SuggestedTemplate(
            icon: "airplane",
            task: "Work on my aerospace engineering assignment — aerodynamics, propulsion, orbital mechanics, spacecraft design, gas dynamics, or compressible flow problems",
            successCriteria: "Aerospace engineering work session completed (at least three problems solved or one design analysis written up with key results documented and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "airplane",
            task: "Study aerospace engineering for my exam — review aerodynamics principles, propulsion systems, orbital mechanics, flight dynamics, and compressible flow concepts",
            successCriteria: "Aerospace engineering study session completed (at least two major topic areas reviewed with notes, diagrams, and key formulas saved)",
            preferredDuration: 45 * 60
        ),
        // electricalengineering
        SuggestedTemplate(
            icon: "bolt",
            task: "Work on my electrical engineering problem set — circuit analysis, Kirchhoff's laws, op-amps, digital electronics, signal processing, or electromagnetic fields",
            successCriteria: "EE problem set session completed (at least three circuit problems solved or one lab analysis written up with results documented and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "bolt",
            task: "Study electrical engineering for my exam — review circuit analysis, Thevenin/Norton equivalents, op-amp circuits, signal processing, and electromagnetic field theory",
            successCriteria: "Electrical engineering study session completed (at least two major topic areas reviewed with notes, circuit diagrams, and key methods saved)",
            preferredDuration: 45 * 60
        ),
        // genetics
        SuggestedTemplate(
            icon: "dna",
            task: "Work through my genetics problem set — Punnett squares, Hardy-Weinberg equilibrium, genetic linkage, pedigree analysis, or population genetics problems",
            successCriteria: "Genetics problem set session completed (at least five genetics problems solved with solutions and reasoning documented and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "dna",
            task: "Study genetics for my exam — review Mendelian inheritance, Hardy-Weinberg equilibrium, genetic linkage, sex-linked traits, epistasis, and population genetics",
            successCriteria: "Genetics study session completed (at least two major topic areas reviewed with notes, practice problems, and key concepts saved)",
            preferredDuration: 45 * 60
        ),
        // microbiology
        SuggestedTemplate(
            icon: "microbe",
            task: "Complete my microbiology lab report or assignment — gram staining, bacterial identification, aseptic technique, culture plate analysis, or zone of inhibition interpretation",
            successCriteria: "Microbiology lab work completed (lab report written or bacterial identification documented with observations, results, and conclusions saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "microbe",
            task: "Study microbiology for my exam — review gram staining, bacterial culture methods, microbial growth, bacteriology, virology, and clinical microbiology concepts",
            successCriteria: "Microbiology study session completed (at least two major topic areas reviewed with notes, diagrams, and key identification criteria saved)",
            preferredDuration: 45 * 60
        ),
        // immunology
        SuggestedTemplate(
            icon: "cross.vial.fill",
            task: "Study immunology for my exam — review innate and adaptive immunity, B/T cell activation, antigen presentation, antibody structure, complement system, and hypersensitivity reactions",
            successCriteria: "Immunology study session completed (at least two immunity pathways reviewed with notes, diagrams, and key mechanisms documented and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "cross.vial.fill",
            task: "Work through my immunology assignment or problem set — immune cell functions, MHC pathways, cytokine signaling, autoimmunity mechanisms, or immunology case studies",
            successCriteria: "Immunology work session completed (assignment written or problem set answered with key immune mechanisms explained and saved)",
            preferredDuration: 45 * 60
        ),
        // parasitology
        SuggestedTemplate(
            icon: "waveform.path.ecg",
            task: "Complete my parasitology lab report or assignment — parasite identification, helminth morphology, protozoa classification, life cycle diagrams, or microscopic exam of specimens",
            successCriteria: "Parasitology lab work completed (lab report written or parasite identification documented with morphology descriptions, life cycle stages, and conclusions saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "waveform.path.ecg",
            task: "Study parasitology for my exam — review protozoa and helminth classification, parasite life cycles, disease mechanisms, host-parasite interactions, and clinical manifestations",
            successCriteria: "Parasitology study session completed (at least two major parasite groups reviewed with notes, life cycle diagrams, and key identification criteria saved)",
            preferredDuration: 45 * 60
        ),
        // embryology
        SuggestedTemplate(
            icon: "circle.grid.cross.fill",
            task: "Study embryology for my exam — review germ layer formation, organogenesis, neurulation, extraembryonic membranes, fetal development stages, and teratology",
            successCriteria: "Embryology study session completed (at least two developmental stages reviewed with notes, diagrams, and key events in organogenesis documented and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "circle.grid.cross.fill",
            task: "Work through my embryology assignment — draw and label developmental stages, explain organogenesis sequences, analyze teratogen effects, or complete embryology case studies",
            successCriteria: "Embryology assignment completed (diagrams labeled, developmental sequences explained, and case studies answered with key embryological concepts documented)",
            preferredDuration: 45 * 60
        ),
        // histology
        SuggestedTemplate(
            icon: "magnifyingglass.circle.fill",
            task: "Practice histology slide identification — identify tissue types, epithelial classifications, connective tissue variants, H&E staining patterns, and organ-specific histology",
            successCriteria: "Histology practice session completed (at least 10 slides or tissue types reviewed with identification criteria, H&E stain characteristics, and key distinguishing features documented)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "magnifyingglass.circle.fill",
            task: "Study histology for my practical exam — review epithelial tissue types, connective tissues, muscle histology, bone histology, and organ-specific microscopic anatomy",
            successCriteria: "Histology study session completed (at least two tissue categories reviewed with staining patterns, identification criteria, and distinguishing microscopic features saved)",
            preferredDuration: 45 * 60
        ),
        // pathology
        SuggestedTemplate(
            icon: "cross.case.fill",
            task: "Study pathology for my exam — review disease mechanisms, gross and microscopic pathology, neoplasia, inflammation, cellular injury, and organ-system pathological changes",
            successCriteria: "Pathology study session completed (at least two pathological processes reviewed with mechanisms, gross and microscopic findings, and clinical correlations documented)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "cross.case.fill",
            task: "Work through my pathology lab or assignment — analyze pathology slides, write up gross pathology findings, review histopathology cases, or complete pathology case studies",
            successCriteria: "Pathology work session completed (slides analyzed or case studies answered with gross and microscopic findings, disease mechanisms, and diagnostic criteria documented)",
            preferredDuration: 45 * 60
        ),
        // neuroanatomy
        SuggestedTemplate(
            icon: "brain.head.profile",
            task: "Study neuroanatomy for my exam — review brain regions, cranial nerves, spinal cord anatomy, neural pathways, brainstem anatomy, limbic system, and basal ganglia",
            successCriteria: "Neuroanatomy study session completed (at least two major brain regions or neural systems reviewed with location, function, pathway connections, and clinical relevance documented)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "brain.head.profile",
            task: "Practice neuroanatomy identification — label brain atlas diagrams, identify cranial nerve functions, trace spinal cord tracts, or map neural pathways from origin to termination",
            successCriteria: "Neuroanatomy practice session completed (at least 12 cranial nerves, major brain regions, or spinal cord tracts identified with functions, origins, and pathways documented)",
            preferredDuration: 45 * 60
        ),
        // chemicalkinetics
        SuggestedTemplate(
            icon: "waveform.path.ecg",
            task: "Work through my chemical kinetics problem set — derive integrated rate laws, solve Arrhenius equation problems, determine reaction orders, and calculate rate constants from experimental data",
            successCriteria: "Chemical kinetics problem set completed (at least five rate law problems solved with correct integrated rate expressions, activation energy calculated, and reaction order determined)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "waveform.path.ecg",
            task: "Study chemical kinetics for my chemistry exam — review rate laws, reaction orders, Arrhenius equation, collision theory, transition state theory, and integrated rate expressions",
            successCriteria: "Chemical kinetics study session completed (rate law derivations reviewed, Arrhenius equation practiced, and key mechanism concepts summarized with notes saved)",
            preferredDuration: 45 * 60
        ),
        // computationalchemistry
        SuggestedTemplate(
            icon: "cpu.fill",
            task: "Run and analyze my computational chemistry calculation — set up a DFT or ab initio job in GAUSSIAN or ORCA, optimize a molecular geometry, and interpret the output for my assignment",
            successCriteria: "Computational chemistry calculation completed (input file submitted, geometry optimization converged, output analyzed, and key results such as energy, geometry, or spectra documented)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "cpu.fill",
            task: "Study computational chemistry methods for my exam — review density functional theory, ab initio methods, basis sets, molecular dynamics, and force field molecular mechanics",
            successCriteria: "Computational chemistry study session completed (DFT approximations reviewed, basis set selection criteria summarized, and key computational methods compared with notes saved)",
            preferredDuration: 45 * 60
        ),
        // ecology
        SuggestedTemplate(
            icon: "leaf.fill",
            task: "Study ecology for my exam — review community ecology, ecosystem dynamics, trophic levels, food webs, species interactions, nutrient cycling, and ecological succession",
            successCriteria: "Ecology study session completed (at least two major ecological concepts reviewed with diagrams, species interaction types explained, and trophic structure summarized in notes)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "leaf.fill",
            task: "Complete my ecology lab or assignment — analyze food web data, model predator-prey dynamics, calculate species diversity indices, or write an ecological succession field observation report",
            successCriteria: "Ecology assignment completed (data analyzed or field observations documented, ecological concepts applied, and lab report or assignment write-up completed and saved)",
            preferredDuration: 45 * 60
        ),
        // pharmacology
        SuggestedTemplate(
            icon: "pills.fill",
            task: "Study pharmacology for my exam — review drug receptor mechanisms, pharmacokinetics, pharmacodynamics, dose-response relationships, agonists and antagonists, and drug metabolism",
            successCriteria: "Pharmacology study session completed (at least two drug class mechanisms reviewed with receptor binding, pharmacokinetic parameters, and therapeutic index concepts summarized in notes)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "pills.fill",
            task: "Work through my pharmacology assignment — analyze dose-response curves, classify receptor types, compare pharmacokinetic profiles, or complete drug mechanism case studies",
            successCriteria: "Pharmacology assignment completed (drug mechanisms explained, pharmacokinetic or pharmacodynamic calculations performed, and case study questions answered with receptor concepts applied)",
            preferredDuration: 45 * 60
        ),
        // physiology
        SuggestedTemplate(
            icon: "heart.fill",
            task: "Study physiology for my exam — review cardiovascular, respiratory, renal, endocrine, and gastrointestinal physiology, organ system regulation, and homeostatic mechanisms",
            successCriteria: "Physiology study session completed (at least two organ systems reviewed with regulatory mechanisms, feedback loops described, and key physiological parameters summarized in notes)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "heart.fill",
            task: "Complete my physiology lab or assignment — analyze physiological data, interpret action potentials or membrane transport, work through organ system case studies, or complete physiology problem sets",
            successCriteria: "Physiology assignment completed (physiological data interpreted, organ system mechanisms applied, and lab report or problem set answers documented and saved)",
            preferredDuration: 45 * 60
        ),
        // mechanicalengineering
        SuggestedTemplate(
            icon: "gearshape.2.fill",
            task: "Complete my mechanical engineering problem set — solve machine design problems, dynamics equations, vibrations analysis, kinematics, statics, or mechanism design",
            successCriteria: "ME problem set completed (at least 5 problems solved with free body diagrams, dynamics equations, or design calculations documented and verified)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "gearshape.2.fill",
            task: "Study mechanical engineering for my exam — review dynamics, statics, vibrations, kinematics, machine design, and manufacturing processes",
            successCriteria: "ME study session complete (at least two topics reviewed with equations, diagrams, and example problems worked through in notes)",
            preferredDuration: 60 * 60
        ),
        // nuclearengineering
        SuggestedTemplate(
            icon: "atom",
            task: "Work through my nuclear engineering problem set — neutron transport, reactor physics, thermal hydraulics, criticality calculations, or nuclear fuel cycle",
            successCriteria: "Nuclear engineering problem set completed (at least 4 problems solved with neutron balance equations, criticality conditions, or thermal hydraulic calculations documented)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "atom",
            task: "Study nuclear engineering for my exam — review reactor physics, neutron transport, thermal hydraulics, nuclear fuel design, and reactor safety",
            successCriteria: "Nuclear engineering study session completed (reactor physics concepts reviewed, key equations noted, and sample problems worked through with criticality and neutron flux concepts)",
            preferredDuration: 45 * 60
        ),
        // materialstesting
        SuggestedTemplate(
            icon: "hammer.fill",
            task: "Complete my materials testing lab — analyze tensile test data, plot stress-strain curves, calculate yield strength and ultimate tensile strength, or interpret Charpy impact results",
            successCriteria: "Materials testing lab report completed (stress-strain curve plotted, material properties calculated from test data, Charpy or hardness results tabulated and written up)",
            preferredDuration: 45 * 60
        ),
        SuggestedTemplate(
            icon: "hammer.fill",
            task: "Study materials testing for my exam — review tensile and compressive testing, hardness tests, Charpy impact, fatigue testing, and fracture toughness concepts",
            successCriteria: "Materials testing study session completed (testing methods reviewed, key equations and mechanical property definitions noted, and sample data interpretation problems worked through)",
            preferredDuration: 45 * 60
        ),
        // biomedicalengineering
        SuggestedTemplate(
            icon: "cross.case.fill",
            task: "Complete my biomedical engineering assignment — biomechanics analysis, biomaterials selection, medical device design, bioinstrumentation, or biosignal processing",
            successCriteria: "BME assignment completed (design parameters documented, biomechanical or material analysis performed, and results written up with engineering calculations)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "cross.case.fill",
            task: "Study biomedical engineering for my exam — review biomechanics, biomaterials, tissue engineering, medical device design, and physiological modeling",
            successCriteria: "BME study session completed (at least two topics reviewed with equations, design principles, and clinical application examples noted)",
            preferredDuration: 60 * 60
        ),
        // chemicalengineering
        SuggestedTemplate(
            icon: "flask.fill",
            task: "Work through my chemical engineering problem set — transport phenomena, unit operations, mass transfer, heat transfer, or reaction engineering",
            successCriteria: "ChE problem set completed (at least 5 problems solved with material and energy balances, transport equations, or reaction rate calculations documented)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "flask.fill",
            task: "Study chemical engineering for my exam — review transport phenomena, unit operations, mass transfer, thermodynamics, heat transfer, and reaction engineering",
            successCriteria: "ChE study session completed (at least two topic areas reviewed with governing equations, constitutive relations, and sample problems worked through)",
            preferredDuration: 60 * 60
        ),
        // oceanography
        SuggestedTemplate(
            icon: "water.waves",
            task: "Study oceanography for my exam — review ocean circulation, thermohaline conveyor, physical and chemical oceanography, Ekman transport, and geostrophic flow",
            successCriteria: "Oceanography study session completed (at least two major topics reviewed with diagrams, governing equations, and key oceanographic concepts summarized in notes)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "water.waves",
            task: "Complete my oceanography lab or assignment — analyze ocean circulation data, plot sea surface temperature, interpret salinity profiles, or work through physical oceanography problems",
            successCriteria: "Oceanography assignment completed (ocean data interpreted, circulation patterns identified, and lab write-up or problem solutions documented and saved)",
            preferredDuration: 45 * 60
        ),
        // geochemistry
        SuggestedTemplate(
            icon: "mountain.2.fill",
            task: "Study geochemistry for my exam — review isotope geochemistry, trace-element analysis, geochemical modeling, and fluid-rock interaction",
            successCriteria: "Geochemistry study session completed (at least two topics reviewed with geochemical equations, isotope ratio concepts, and trace-element interpretation summarized in notes)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "mountain.2.fill",
            task: "Complete my geochemistry lab or assignment — analyze isotope ratio data, interpret XRF or ICP-MS results, apply geochemical modeling, or work through trace-element problem sets",
            successCriteria: "Geochemistry assignment completed (geochemical data analyzed, isotope or element ratios calculated and interpreted, and lab report or problem solutions documented)",
            preferredDuration: 45 * 60
        ),
        // thermodynamics
        SuggestedTemplate(
            icon: "flame.fill",
            task: "Work through my thermodynamics problem set — Rankine cycle, Carnot efficiency, steam tables, Otto or Diesel cycle, refrigeration systems, or entropy and enthalpy calculations",
            successCriteria: "Thermodynamics problem set completed (at least 5 problems solved with cycle diagrams, steam-table lookups, or entropy/enthalpy calculations clearly documented)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "flame.fill",
            task: "Study thermodynamics for my exam — review Rankine and Carnot cycles, steam tables, laws of thermodynamics, refrigeration cycles, and heat-engine efficiency",
            successCriteria: "Thermodynamics study session completed (at least two cycle types reviewed with T-s/P-v diagrams, governing equations, and sample problems worked through in notes)",
            preferredDuration: 60 * 60
        ),
        // radiologyrotation
        SuggestedTemplate(
            icon: "xray",
            task: "Complete my radiology reading room session — interpret CT, MRI, or plain film radiographs, write up radiology reports, and review cases with my attending",
            successCriteria: "Radiology reading session completed (at least 5 cases reviewed, key findings identified on each image, and radiology report or interpretation notes written up)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "xray",
            task: "Study radiology for my rotation exam — review systematic image interpretation, CT and MRI anatomy, common radiologic findings, and normal vs. abnormal patterns",
            successCriteria: "Radiology study session completed (at least two imaging modalities reviewed with systematic interpretation framework, normal landmarks identified, and key pathology patterns noted)",
            preferredDuration: 45 * 60
        ),
        // anesthesiology
        SuggestedTemplate(
            icon: "waveform.path.ecg",
            task: "Study anesthesiology for my rotation or CRNA exam — review anesthetic pharmacology, volatile agents, airway management, regional anesthesia, and MAC values",
            successCriteria: "Anesthesiology study session completed (at least two topics reviewed with drug mechanisms, pharmacokinetic parameters, dosing principles, and clinical pearls summarized in notes)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "waveform.path.ecg",
            task: "Complete my anesthesiology assignment or case prep — review anesthetic agents, pre-op assessment, intraoperative monitoring, or airway management protocols",
            successCriteria: "Anesthesiology assignment completed (case or topic reviewed with anesthetic plan, drug selection rationale, monitoring parameters, and key clinical considerations documented)",
            preferredDuration: 45 * 60
        ),
        // structuralbiology
        SuggestedTemplate(
            icon: "atom",
            task: "Work on my structural biology research — analyze cryo-EM data, interpret protein structures in the PDB, run homology models, or study protein folding and X-ray crystallography methods",
            successCriteria: "Structural biology session completed (at least one protein structure analyzed, key structural features documented, and research findings or methods notes saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "atom",
            task: "Study structural biology for my class or exam — review cryo-EM, X-ray crystallography, protein NMR, SAXS, protein folding, and structure determination workflows",
            successCriteria: "Structural biology study session completed (at least two methods reviewed with technique principles, resolution limits, sample requirements, and key structural concepts summarized in notes)",
            preferredDuration: 45 * 60
        ),
        // biochemistrylab
        SuggestedTemplate(
            icon: "flask.fill",
            task: "Complete my biochemistry lab report or notebook — analyze SDS-PAGE or enzyme kinetics results, write up column chromatography data, or complete a protein assay analysis",
            successCriteria: "Biochemistry lab report or notebook completed (data analyzed, results interpreted with controls accounted for, conclusions drawn with supporting calculations, and write-up saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "flask.fill",
            task: "Study biochemistry lab techniques for my exam or practical — review SDS-PAGE, enzyme kinetics, Bradford/BCA assays, column chromatography, and biochemistry experimental methods",
            successCriteria: "Biochemistry lab techniques study session completed (at least two techniques reviewed with principles, protocols, controls, and data-interpretation methods summarized in notes)",
            preferredDuration: 45 * 60
        ),
        // clinicalneurology
        SuggestedTemplate(
            icon: "brain.head.profile",
            task: "Complete my neurology rotation work — write up neuro case notes, prepare for rounds, review neurological exam findings, or study EEG interpretation and lumbar puncture technique",
            successCriteria: "Neurology rotation session completed (case notes written or cases reviewed, key neurological findings documented, and rotation prep or write-up saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "brain.head.profile",
            task: "Study neurology for my rotation exam — review neurological exam technique, common neurological syndromes, EEG interpretation, neuro imaging patterns, and lumbar puncture indications",
            successCriteria: "Clinical neurology study session completed (at least two neurological syndromes or exam findings reviewed with localization, clinical features, and management pearls summarized in notes)",
            preferredDuration: 45 * 60
        ),
        // dermatologyrotation
        SuggestedTemplate(
            icon: "person.fill.questionmark",
            task: "Complete my dermatology rotation work — review skin lesion cases, practice dermoscopy pattern recognition, write up derm case notes, or study common dermatological conditions",
            successCriteria: "Dermatology rotation session completed (at least 5 cases or lesion types reviewed, dermoscopic or clinical features noted, and rotation write-up or case notes saved)",
            preferredDuration: 45 * 60
        ),
        SuggestedTemplate(
            icon: "person.fill.questionmark",
            task: "Study dermatology for my rotation exam — review skin lesion classification, ABCDE melanoma criteria, dermoscopy patterns, common inflammatory conditions, and skin biopsy interpretation",
            successCriteria: "Dermatology study session completed (at least two disease categories reviewed with clinical presentation, diagnostic findings, and management approach summarized in notes)",
            preferredDuration: 45 * 60
        ),
        // psychiatryrotation
        SuggestedTemplate(
            icon: "brain",
            task: "Complete my psychiatry rotation work — write psychiatric case formulations, document mental status exams, prepare DSM-5 differential diagnoses, or study inpatient psychiatry notes",
            successCriteria: "Psychiatry rotation session completed (at least one case formulated with MSE, DSM-5 diagnosis, biopsychosocial framework, and treatment plan documented and saved)",
            preferredDuration: 45 * 60
        ),
        SuggestedTemplate(
            icon: "brain",
            task: "Study psychiatry for my rotation exam — review DSM-5 diagnostic criteria, mental status exam components, biopsychosocial model, and common psychiatric syndromes and their management",
            successCriteria: "Clinical psychiatry study session completed (at least two psychiatric conditions reviewed with diagnostic criteria, MSE findings, differential diagnosis, and management principles noted)",
            preferredDuration: 45 * 60
        ),
        // surgeryrotation
        SuggestedTemplate(
            icon: "cross.case.fill",
            task: "Complete my surgery rotation work — write operative notes or H&Ps, prepare pre-op assessments, review surgical cases for rounds, or study operative indications and post-op care",
            successCriteria: "Surgery rotation session completed (at least one operative note or H&P written, or two surgical cases reviewed with indication, procedure, and post-op management summarized and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "cross.case.fill",
            task: "Study surgery for my clerkship shelf exam — review surgical indications, common operative procedures, post-op complications, wound management, and surgical anatomy",
            successCriteria: "Surgery shelf study session completed (at least two surgical topics reviewed with indications, procedure overview, common complications, and management principles noted)",
            preferredDuration: 60 * 60
        ),
        // pediatricsrotation
        SuggestedTemplate(
            icon: "figure.child",
            task: "Complete my pediatrics rotation work — write pediatric case notes, document well-child visits, review developmental milestones, or prepare for peds rounds",
            successCriteria: "Pediatrics rotation session completed (at least one case write-up or well-child visit note completed, or three developmental milestone categories reviewed with age-appropriate benchmarks saved)",
            preferredDuration: 45 * 60
        ),
        SuggestedTemplate(
            icon: "figure.child",
            task: "Study pediatrics for my clerkship shelf exam — review developmental milestones, common pediatric illnesses, vaccination schedules, pediatric vital sign norms, and growth charts",
            successCriteria: "Pediatrics shelf study session completed (at least two pediatric topics reviewed with age-specific presentation, diagnosis, and management principles noted)",
            preferredDuration: 45 * 60
        ),
        // internalmedicine
        SuggestedTemplate(
            icon: "stethoscope",
            task: "Complete my internal medicine rotation work — write H&Ps or SOAP notes, prepare for medicine rounds, review patient cases, or work through medicine shelf practice questions",
            successCriteria: "Internal medicine rotation session completed (at least one H&P or SOAP note written, or two patient cases reviewed with differential diagnosis, workup, and management plan noted and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "stethoscope",
            task: "Study internal medicine for my clerkship shelf exam — review common inpatient conditions, diagnostic workups, evidence-based management, and medicine clinical reasoning",
            successCriteria: "Internal medicine shelf study session completed (at least two medicine topics reviewed with pathophysiology, clinical presentation, diagnostic approach, and management summarized)",
            preferredDuration: 60 * 60
        ),
        // obgynrotation
        SuggestedTemplate(
            icon: "waveform.path.ecg",
            task: "Complete my OB/GYN rotation work — write labor and delivery notes, document prenatal visits, review gynecologic cases, or prepare for OB/GYN rounds",
            successCriteria: "OB/GYN rotation session completed (at least one L&D note or gynecologic case write-up completed, or three OB/GYN clinical scenarios reviewed with relevant management documented and saved)",
            preferredDuration: 45 * 60
        ),
        SuggestedTemplate(
            icon: "waveform.path.ecg",
            task: "Study OB/GYN for my clerkship shelf exam — review normal obstetrics, common pregnancy complications, gynecologic conditions, and obstetric emergencies",
            successCriteria: "OB/GYN shelf study session completed (at least two OB or GYN topics reviewed with clinical presentation, diagnostic approach, and management principles noted)",
            preferredDuration: 45 * 60
        ),
        // familymedicine
        SuggestedTemplate(
            icon: "person.2.fill",
            task: "Complete my family medicine rotation work — write continuity clinic notes, complete preventive care documentation, review chronic disease management cases, or prepare for FM rounds",
            successCriteria: "Family medicine rotation session completed (at least one clinic note written or two chronic disease management cases reviewed with preventive care, treatment adjustments, and follow-up plan documented and saved)",
            preferredDuration: 45 * 60
        ),
        SuggestedTemplate(
            icon: "person.2.fill",
            task: "Study family medicine for my clerkship shelf exam — review preventive care guidelines, chronic disease management, common acute presentations, and family medicine clinical reasoning",
            successCriteria: "Family medicine shelf study session completed (at least two FM topics reviewed with screening recommendations, management guidelines, and clinical reasoning approach summarized)",
            preferredDuration: 45 * 60
        ),
        // emergencymedicinerotation
        SuggestedTemplate(
            icon: "cross.fill",
            task: "Complete my emergency medicine rotation work — write shift notes, document EM cases, review emergency protocols, or prepare for EM rounds",
            successCriteria: "Emergency medicine rotation session completed (at least one shift note or EM case write-up completed, or three emergency presentations reviewed with assessment, management, and disposition documented and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "cross.fill",
            task: "Study emergency medicine for my clerkship shelf exam — review emergency presentations, ABCDE approach, acute management algorithms, toxicology, and EM clinical decision-making",
            successCriteria: "Emergency medicine shelf study session completed (at least two EM topics reviewed with presentation, stabilization approach, differential diagnosis, and management algorithm summarized)",
            preferredDuration: 60 * 60
        ),
        // virology
        SuggestedTemplate(
            icon: "allergens",
            task: "Complete my virology assignment or lab — analyze viral replication cycles, identify viral pathogens, interpret virology lab results, or write up my virology lab report",
            successCriteria: "Virology session completed (at least one viral pathogen or replication cycle fully analyzed with key steps, host interactions, and clinical relevance documented and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "allergens",
            task: "Study virology for my exam — review viral replication cycles, viral pathogenesis, major viral families, host immune evasion strategies, and antiviral mechanisms",
            successCriteria: "Virology study session completed (at least two viral families or replication mechanisms reviewed with structure, entry, replication, assembly, and pathogenesis summarized)",
            preferredDuration: 45 * 60
        ),
        // clinicalmicrobiology
        SuggestedTemplate(
            icon: "flask.fill",
            task: "Complete my clinical microbiology lab work — interpret culture results, read antibiograms, analyze susceptibility testing data, or document infection control cases",
            successCriteria: "Clinical microbiology session completed (at least two culture results or antibiograms interpreted with organism identified, susceptibility pattern analyzed, and clinical significance documented and saved)",
            preferredDuration: 45 * 60
        ),
        SuggestedTemplate(
            icon: "flask.fill",
            task: "Study clinical microbiology for my exam — review culture interpretation, antibiogram reading, susceptibility testing, infection control principles, and nosocomial pathogen identification",
            successCriteria: "Clinical microbiology study session completed (at least two topics reviewed with identification methods, susceptibility patterns, and infection control implications summarized)",
            preferredDuration: 45 * 60
        ),
        // medicinalchemistry
        SuggestedTemplate(
            icon: "atom",
            task: "Complete my medicinal chemistry assignment — analyze structure-activity relationships, optimize lead compounds, apply Lipinski's rule of five, or work through drug design problem sets",
            successCriteria: "Medicinal chemistry session completed (at least one SAR analysis or lead optimization problem worked through with pharmacophore identified, key modifications evaluated, and ADMET implications noted and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "atom",
            task: "Study medicinal chemistry for my exam — review structure-activity relationships, drug design principles, pharmacophore modeling, prodrug strategies, and ADMET optimization",
            successCriteria: "Medicinal chemistry study session completed (at least two drug design topics reviewed with key SAR features, design strategies, and pharmacokinetic considerations summarized)",
            preferredDuration: 60 * 60
        ),
        // cellandmolecularbiology
        SuggestedTemplate(
            icon: "circle.hexagongrid.fill",
            task: "Complete my cell biology lab or assignment — analyze cell division stages, identify organelles, interpret microscopy images, or work through cell biology problem sets",
            successCriteria: "Cell biology session completed (at least one lab report section completed or two cell biology mechanisms — mitosis/meiosis stages, organelle functions, or cell signaling pathways — fully reviewed and documented)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "circle.hexagongrid.fill",
            task: "Study cell biology for my exam — review cell cycle regulation, organelle functions, cytoskeleton dynamics, cell signaling pathways, and membrane biology",
            successCriteria: "Cell biology study session completed (at least two cell biology topics reviewed with molecular mechanisms, key proteins, and physiological significance summarized)",
            preferredDuration: 45 * 60
        ),
        // biochemistry2
        SuggestedTemplate(
            icon: "atom",
            task: "Work through my advanced biochemistry problem set — signal transduction pathways, lipid metabolism, fatty acid oxidation, cholesterol biosynthesis, nucleotide metabolism, or urea cycle",
            successCriteria: "Advanced biochemistry session completed (at least one pathway fully worked through with key enzymes, regulation points, and metabolic significance documented and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "atom",
            task: "Study advanced biochemistry for my exam — review signal transduction cascades, lipid and nucleotide metabolism pathways, cholesterol biosynthesis, and urea cycle regulation",
            successCriteria: "Advanced biochemistry study session completed (at least two metabolic pathways reviewed with key enzymes, regulation, and clinical relevance summarized)",
            preferredDuration: 60 * 60
        ),
        // physicalchemistrylab
        SuggestedTemplate(
            icon: "thermometer.medium",
            task: "Complete my physical chemistry lab report or notebook — analyze calorimetry data, interpret spectroscopy results, document kinetics experiment results, or write up my pchem lab",
            successCriteria: "Physical chemistry lab session completed (at least one pchem experiment documented with raw data analyzed, calculations shown, graphs produced, and results section written and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "thermometer.medium",
            task: "Prepare for my physical chemistry lab — review calorimetry experiment procedure, spectroscopy techniques, kinetics methods, or pre-lab questions for my pchem lab",
            successCriteria: "Physical chemistry lab prep completed (pre-lab questions answered, relevant equations and procedures summarized, and expected results or safety notes documented and saved)",
            preferredDuration: 45 * 60
        ),
        // organicchemistrylab
        SuggestedTemplate(
            icon: "flask.fill",
            task: "Complete my organic chemistry lab report — write up my distillation, recrystallization, TLC, column chromatography, or IR/NMR spectroscopy results",
            successCriteria: "Orgo lab report completed (introduction, procedure summary, results with data analysis and spectra interpreted, discussion with yield and purity assessment written and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "flask.fill",
            task: "Prepare for my organic chemistry lab — review distillation or recrystallization procedures, TLC technique, melting point determination, or pre-lab questions for my orgo lab",
            successCriteria: "Orgo lab prep completed (pre-lab questions answered, reaction mechanism or procedure summarized, safety hazards identified, and expected observations or calculations documented and saved)",
            preferredDuration: 30 * 60
        ),
        // immunologycourse
        SuggestedTemplate(
            icon: "shield.fill",
            task: "Study advanced immunology for my exam — review regulatory T cells, complement cascade, immunotherapy mechanisms, checkpoint inhibitors, NK cell biology, and pattern recognition receptors",
            successCriteria: "Advanced immunology study session completed (at least two advanced topics reviewed with molecular mechanisms, signaling pathways, and clinical relevance summarized)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "shield.fill",
            task: "Work through my advanced immunology assignment — analyze T-reg cell suppression, complement pathway activation, immunotherapy case study, or checkpoint inhibitor mechanism",
            successCriteria: "Immunology assignment completed (at least one advanced immunology topic fully analyzed with pathway steps, key molecules, and clinical application documented and saved)",
            preferredDuration: 45 * 60
        ),
        // neurobiologylab
        SuggestedTemplate(
            icon: "brain.head.profile",
            task: "Complete my neurobiology lab report or notebook — write up patch clamp recordings, neural tracing results, calcium imaging data, or brain slice preparation observations",
            successCriteria: "Neurobiology lab report completed (methods, results with figures, and discussion of electrophysiological or imaging findings written and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "brain.head.profile",
            task: "Prepare for my neurobiology lab — review patch clamp technique, neural tracing protocols, calcium imaging methods, or pre-lab questions for my neurobiology experiment",
            successCriteria: "Neurobiology lab prep completed (pre-lab questions answered, experimental protocol reviewed, relevant background on electrophysiology or imaging technique summarized and saved)",
            preferredDuration: 30 * 60
        ),
        // astronomylab
        SuggestedTemplate(
            icon: "star.fill",
            task: "Complete my observational astronomy lab — plot star charts, analyze telescope data, calculate stellar magnitudes, measure light curves, or write up my astronomical observation report",
            successCriteria: "Astronomy lab completed (star chart plotted or telescope data analyzed, calculations shown, and lab report section or observation write-up completed and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "star.fill",
            task: "Prepare for my astronomy observing session — review celestial coordinate systems, telescope operation, stellar classification, magnitude calculations, or pre-lab questions for my observatory session",
            successCriteria: "Astronomy lab prep completed (pre-lab questions answered, coordinate systems or telescope procedures reviewed, and observing targets or sky chart prepared and saved)",
            preferredDuration: 30 * 60
        ),
        // geologylab
        SuggestedTemplate(
            icon: "mountain.2.fill",
            task: "Complete my geology lab report — identify rock and mineral specimens, analyze thin sections under the microscope, interpret geologic cross sections, or write up my field geology observations",
            successCriteria: "Geology lab report completed (rock or mineral identifications documented, thin section observations or field data recorded, and lab report section written and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "mountain.2.fill",
            task: "Prepare for my geology lab — review rock identification techniques, mineral properties and cleavage, thin section petrography, geologic map reading, or pre-lab questions for my geology field lab",
            successCriteria: "Geology lab prep completed (pre-lab questions answered, key rock and mineral properties reviewed, and relevant geologic terminology or identification criteria documented and saved)",
            preferredDuration: 30 * 60
        ),
        // environmentalscience
        SuggestedTemplate(
            icon: "leaf.fill",
            task: "Complete my environmental science assignment or lab — analyze biogeochemical cycles, earth systems data, environmental sampling results, or write up an environmental monitoring report",
            successCriteria: "Environmental science assignment completed (data analyzed or report section written, biogeochemical cycle or earth systems concept fully explained, and work saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "leaf.fill",
            task: "Study environmental science for my exam — review earth systems, biogeochemical cycles (carbon, nitrogen, phosphorus), ecosystem services, and environmental monitoring methods",
            successCriteria: "Environmental science study session completed (at least two earth systems or biogeochemical cycles reviewed with key processes, drivers, and environmental significance summarized and saved)",
            preferredDuration: 45 * 60
        ),
        // anthropology
        SuggestedTemplate(
            icon: "person.3.fill",
            task: "Write my anthropology paper or ethnography — analyze cultural practices, kinship systems, ritual behavior, or complete a participant observation write-up for my anthropology class",
            successCriteria: "Anthropology writing completed (at least one section drafted with thesis, ethnographic or analytical evidence, and anthropological theory applied — saved to file)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "person.3.fill",
            task: "Study anthropology for my exam — review cultural anthropology theories, physical anthropology concepts, ethnographic methods, kinship systems, and key theorists (Boas, Mead, Geertz, Lévi-Strauss)",
            successCriteria: "Anthropology study session completed (at least two theoretical frameworks or key anthropologists reviewed with core concepts, methods, and examples summarized and saved)",
            preferredDuration: 45 * 60
        ),
        // sociology
        SuggestedTemplate(
            icon: "network",
            task: "Write my sociology paper — apply a sociological theory (conflict, functionalism, symbolic interactionism), analyze social stratification or inequality, or complete a sociological analysis for class",
            successCriteria: "Sociology paper section completed (thesis stated, sociological theory applied with examples, and at least one body paragraph drafted with evidence and analysis — saved to file)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "network",
            task: "Study sociology for my exam — review sociological theories, social structures and stratification, deviance and social control, and key thinkers (Marx, Durkheim, Weber, Goffman, Parsons)",
            successCriteria: "Sociology study session completed (at least two sociological theories or key thinkers reviewed with core arguments, concepts, and real-world applications summarized and saved)",
            preferredDuration: 45 * 60
        ),
        // biostatistics
        SuggestedTemplate(
            icon: "chart.xyaxis.line",
            task: "Work through my biostatistics problem set — survival analysis, Kaplan-Meier curves, Cox regression, power analysis, clinical trial design, or odds ratio and relative risk calculations",
            successCriteria: "Biostatistics problem set completed (at least two problems fully worked with method identified, calculations shown, and interpretation written — saved to file)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "chart.xyaxis.line",
            task: "Study biostatistics for my exam — review survival analysis, Kaplan-Meier estimator, Cox proportional hazards model, power analysis, sample size calculation, and interpreting clinical trial statistics",
            successCriteria: "Biostatistics study session completed (at least two methods reviewed with assumptions, formulas, and interpretation of results summarized and saved)",
            preferredDuration: 45 * 60
        ),
        // marinebiology2
        SuggestedTemplate(
            icon: "drop.fill",
            task: "Complete my marine biology lab work — identify plankton samples, document tidepool species observations, write up benthic survey data, or analyze marine organism dissection results",
            successCriteria: "Marine biology lab work completed (organisms identified or data recorded, observations written up with scientific names and ecological notes, and lab section saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "drop.fill",
            task: "Prepare for my marine biology lab — review plankton identification keys, tidepool ecology, intertidal zonation, or pre-lab questions for my ocean field sampling or marine organism dissection",
            successCriteria: "Marine biology lab prep completed (plankton ID keys or tidepool species reviewed, key ecological concepts documented, and pre-lab questions answered and saved)",
            preferredDuration: 30 * 60
        ),
        // moleculargeneticslab
        SuggestedTemplate(
            icon: "dna",
            task: "Complete my molecular genetics lab work — analyze restriction fragment patterns, build a DNA restriction map, interpret karyotype results, or write up my DNA fingerprinting lab report",
            successCriteria: "Molecular genetics lab work completed (restriction map drawn or karyotype interpreted, results documented with explanation of method and interpretation — saved to file)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "dna",
            task: "Prepare for my molecular genetics lab — review restriction enzyme digestion, agarose gel electrophoresis in genetics context, karyotyping techniques, or RFLP analysis pre-lab questions",
            successCriteria: "Molecular genetics lab prep completed (restriction digestion or karyotyping procedure reviewed, key concepts documented, and pre-lab questions answered and saved)",
            preferredDuration: 30 * 60
        ),
        // evolutionarybiology
        SuggestedTemplate(
            icon: "arrow.triangle.branch",
            task: "Study evolutionary biology for my exam — review phylogenetic tree construction (parsimony, maximum likelihood), speciation mechanisms, adaptive radiation, evo-devo concepts, and molecular evolution",
            successCriteria: "Evolutionary biology study session completed (at least two concepts reviewed with mechanisms, examples, and key terminology summarized and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "arrow.triangle.branch",
            task: "Work on my evolutionary biology assignment — build or interpret a phylogenetic tree, analyze a speciation case study, or complete a problem set on natural selection mechanisms and molecular evolution",
            successCriteria: "Evolutionary biology assignment completed (phylogenetic tree drawn or speciation analysis written, with method explained and results interpreted — saved to file)",
            preferredDuration: 45 * 60
        ),
        // biochemistry3
        SuggestedTemplate(
            icon: "atom",
            task: "Study advanced biochemistry cofactors and coenzymes — review vitamins as coenzymes (thiamine, riboflavin, niacin, pyridoxine, B12, folate, biotin, pantothenic acid), heme biosynthesis, and bile acid synthesis",
            successCriteria: "Biochemistry cofactor study completed (at least two vitamin-coenzyme relationships reviewed with biochemical role, reaction type, and metabolic context summarized and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "atom",
            task: "Work through my advanced biochemistry problem set on cofactors — porphyrin and heme biosynthesis pathway steps, bile acid synthesis, one-carbon metabolism, methylation cycle, or vitamin cofactor mechanisms",
            successCriteria: "Biochemistry cofactor problem set completed (at least two pathway problems worked with steps, cofactors, and biochemical significance documented — saved to file)",
            preferredDuration: 45 * 60
        ),
        // atmosphericscience
        SuggestedTemplate(
            icon: "cloud.bolt",
            task: "Study atmospheric science for my exam — review synoptic meteorology, atmospheric dynamics, boundary layer processes, thermodynamic diagrams, NWP model fundamentals, and mesoscale weather systems",
            successCriteria: "Atmospheric science study session completed (at least two topics reviewed with key concepts, equations, and examples summarized and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "cloud.bolt",
            task: "Complete my meteorology or atmospheric science assignment — analyze synoptic weather maps, interpret sounding data, work through atmospheric dynamics problems, or write up my NWP model analysis",
            successCriteria: "Atmospheric science assignment completed (weather map analysis or dynamics problem solved, with interpretation documented and saved to file)",
            preferredDuration: 45 * 60
        ),
        // ecologicalfieldwork
        SuggestedTemplate(
            icon: "leaf",
            task: "Analyze my field ecology data — process transect or quadrat survey results, calculate species richness and diversity indices, perform mark-recapture population estimates, and write up my field ecology lab report",
            successCriteria: "Field ecology data analysis completed (diversity indices calculated or population estimates written up, methods and results documented and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "leaf",
            task: "Prepare for my ecological fieldwork lab — review transect and quadrat sampling methods, mark-recapture techniques, biodiversity indices (Shannon, Simpson), and species identification keys",
            successCriteria: "Field ecology lab prep completed (sampling methods reviewed, biodiversity index formulas documented, and pre-lab questions answered and saved)",
            preferredDuration: 30 * 60
        ),
        // quantummechanics
        SuggestedTemplate(
            icon: "atom",
            task: "Work through my quantum mechanics problem set — solve wave function problems, apply the Schrödinger equation, work out energy eigenvalues for particle-in-a-box or harmonic oscillator, or practice bra-ket notation",
            successCriteria: "Quantum mechanics problem set completed (at least two problems solved with wave functions, operators, or energy levels derived and checked — saved to file)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "atom",
            task: "Study quantum mechanics for my exam — review postulates of quantum mechanics, operators and observables, uncertainty principle, quantum tunneling, perturbation theory, and angular momentum",
            successCriteria: "Quantum mechanics study session completed (at least two topics reviewed with key concepts, equations, and problem-solving strategies summarized and saved)",
            preferredDuration: 60 * 60
        ),
        // solidstatephysics
        SuggestedTemplate(
            icon: "square.grid.3x3.fill",
            task: "Study solid state physics for my exam — review crystal lattice structures, reciprocal lattice and Brillouin zones, band theory, phonons, Fermi level and electron distribution, and semiconductor physics",
            successCriteria: "Solid state physics study completed (at least two topics reviewed with key concepts, diagrams, and equations summarized and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "square.grid.3x3.fill",
            task: "Work through my condensed matter or solid state physics problem set — solve band structure problems, calculate phonon dispersion relations, or analyze Fermi surfaces and semiconductor carrier densities",
            successCriteria: "Solid state physics problem set completed (at least two problems worked with crystal structure or band theory analysis documented — saved to file)",
            preferredDuration: 60 * 60
        ),
        // classicalmechanics
        SuggestedTemplate(
            icon: "gyroscope",
            task: "Work through my classical mechanics problem set — set up Lagrangians, derive equations of motion using Euler-Lagrange, solve central force problems, or analyze rigid body rotation with inertia tensors",
            successCriteria: "Classical mechanics problem set completed (at least two problems solved with Lagrangian/Hamiltonian formulation, equations of motion derived and checked — saved to file)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "gyroscope",
            task: "Study classical mechanics for my exam — review Lagrangian and Hamiltonian formulations, generalized coordinates, constraints, rigid body dynamics, and canonical transformations",
            successCriteria: "Classical mechanics study session completed (at least two topics reviewed with key concepts, formulas, and problem strategies summarized and saved)",
            preferredDuration: 60 * 60
        ),
        // astrophysics
        SuggestedTemplate(
            icon: "sparkles",
            task: "Work through my astrophysics problem set — solve stellar evolution equations, compute orbital mechanics, analyze cosmological models, or work through N-body gravitational dynamics problems",
            successCriteria: "Astrophysics problem set completed (at least two problems solved with astrophysical derivations checked — saved to file)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "sparkles",
            task: "Study astrophysics for my exam — review stellar structure and evolution, galaxy formation, dark matter and dark energy, gravitational waves, and cosmological models",
            successCriteria: "Astrophysics study session completed (at least two topics reviewed with key concepts, equations, and physical interpretations summarized and saved)",
            preferredDuration: 60 * 60
        ),
        // atmosphericchemistry
        SuggestedTemplate(
            icon: "smoke",
            task: "Analyze my atmospheric chemistry data — model ozone depletion mechanisms, aerosol chemistry reactions, tropospheric oxidation pathways, or VOC photochemical cycles",
            successCriteria: "Atmospheric chemistry analysis completed (reaction mechanisms or model results documented, chemical pathways explained and saved to file)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "smoke",
            task: "Work through my atmospheric chemistry problem set — ozone photolysis cycles, OH radical reaction rates, stratospheric halogen chemistry, or air quality modeling",
            successCriteria: "Atmospheric chemistry problem set completed (at least two reaction mechanisms or rate calculations worked out and documented — saved to file)",
            preferredDuration: 45 * 60
        ),
        // optics
        SuggestedTemplate(
            icon: "rays",
            task: "Work through my optics problem set — solve wave interference and diffraction problems, apply Snell's law and Fresnel equations, analyze Fabry-Pérot cavities, or calculate optical fiber modes",
            successCriteria: "Optics problem set completed (at least two problems solved with wave optics or geometric optics analysis checked — saved to file)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "rays",
            task: "Study optics or photonics for my exam — review wave optics, interference, diffraction, Fourier optics, laser fundamentals, optical fibers, and nonlinear optics concepts",
            successCriteria: "Optics study session completed (at least two topics reviewed with key equations, diagrams, and physical interpretations summarized and saved)",
            preferredDuration: 60 * 60
        ),
        // electromagnetism
        SuggestedTemplate(
            icon: "bolt.circle",
            task: "Work through my electromagnetism problem set — apply Gauss's law, Ampere's law, Faraday's law, and Maxwell's equations to solve electric and magnetic field problems",
            successCriteria: "Electromagnetism problem set completed (at least two problems solved with field equations derived and boundary conditions applied — saved to file)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "bolt.circle",
            task: "Study electromagnetism for my exam — review Maxwell's equations, electrostatics, magnetostatics, electromagnetic waves, and boundary conditions in dielectrics and conductors",
            successCriteria: "Electromagnetism study session completed (at least two topics reviewed with key equations, physical interpretations, and example problems summarized and saved)",
            preferredDuration: 60 * 60
        ),
        // neuroimaging
        SuggestedTemplate(
            icon: "brain.head.profile",
            task: "Run my neuroimaging analysis pipeline — preprocess fMRI data with FSL or SPM, perform motion correction and normalization, run first-level GLM analysis, or process DTI tractography",
            successCriteria: "Neuroimaging analysis completed (preprocessing pipeline run, key outputs checked for quality, and results directory organized and documented)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "brain.head.profile",
            task: "Work on my neuroimaging class assignment — analyze BOLD signal data, interpret brain connectivity maps, review fMRI study design, or write up my neuroimaging lab report",
            successCriteria: "Neuroimaging assignment completed (analysis written up or lab report drafted with methods, results, and interpretation documented — saved to file)",
            preferredDuration: 45 * 60
        ),
        // geophysics
        SuggestedTemplate(
            icon: "waveform.path",
            task: "Work through my geophysics problem set — interpret seismic reflection profiles, model gravity anomalies, analyze magnetic survey data, or apply resistivity inversion methods",
            successCriteria: "Geophysics problem set completed (at least two problems solved with seismic, gravity, or magnetic data analysis documented — saved to file)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "waveform.path",
            task: "Study geophysics for my exam — review seismic methods, gravity and magnetic surveys, electrical resistivity, well logging, and geophysical inversion theory",
            successCriteria: "Geophysics study session completed (at least two survey methods reviewed with key equations, data examples, and interpretation notes summarized and saved)",
            preferredDuration: 60 * 60
        ),
        // mineralogy
        SuggestedTemplate(
            icon: "diamond",
            task: "Study mineralogy for my exam — review crystal systems, mineral optical properties, Mohs hardness, cleavage and fracture, streak tests, and common silicate and oxide mineral groups",
            successCriteria: "Mineralogy study session completed (at least two mineral groups reviewed with identifying properties, crystal habits, and optical characteristics summarized and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "diamond",
            task: "Complete my mineralogy lab or assignment — identify unknown minerals using optical properties, describe crystal symmetry and habit, or work through a crystallographic problem set",
            successCriteria: "Mineralogy assignment completed (minerals identified with supporting observations or crystallography problems worked — identification sheet or lab report saved to file)",
            preferredDuration: 45 * 60
        ),
        // petrology
        SuggestedTemplate(
            icon: "mountain.2",
            task: "Study petrology for my exam — review igneous, metamorphic, and sedimentary rock classification, Bowen's reaction series, metamorphic facies, and petrographic description methods",
            successCriteria: "Petrology study session completed (at least two rock types reviewed with classification criteria, formation environments, and key minerals summarized and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "mountain.2",
            task: "Complete my petrology assignment — write a petrographic description of an igneous or metamorphic rock, classify a sample using a TAS or QAP diagram, or work through a P-T path problem",
            successCriteria: "Petrology assignment completed (rock description written or classification diagram applied with mineral assemblage and textural observations documented — saved to file)",
            preferredDuration: 60 * 60
        ),
        // hydrogeology
        SuggestedTemplate(
            icon: "drop.triangle",
            task: "Work through my hydrogeology problem set — apply Darcy's law, analyze pumping test data, calculate aquifer transmissivity and storativity, or use the Theis equation for well hydraulics",
            successCriteria: "Hydrogeology problem set completed (at least two problems solved with groundwater flow calculations and aquifer parameters derived — saved to file)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "drop.triangle",
            task: "Study hydrogeology for my exam — review groundwater flow equations, Darcy's law, aquifer types, pumping test analysis, groundwater contamination transport, and MODFLOW modeling concepts",
            successCriteria: "Hydrogeology study session completed (at least two topics reviewed with key equations, aquifer diagrams, and example problem solutions summarized and saved)",
            preferredDuration: 60 * 60
        ),
        // stratigraphy
        SuggestedTemplate(
            icon: "square.3.layers.3d",
            task: "Study stratigraphy for my exam — review lithostratigraphy, biostratigraphy, sequence stratigraphy, Walther's law, stratigraphic correlation methods, and unconformity types",
            successCriteria: "Stratigraphy study session completed (at least two stratigraphic concepts reviewed with key principles, correlation methods, and example sections summarized and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "square.3.layers.3d",
            task: "Complete my stratigraphy assignment — draw a stratigraphic column, correlate two or more sections, apply sequence stratigraphy concepts, or identify unconformities in a rock record",
            successCriteria: "Stratigraphy assignment completed (stratigraphic column drawn or sections correlated with unit descriptions, boundaries, and depositional environment interpretations — saved to file)",
            preferredDuration: 45 * 60
        ),
        // systemsbiology
        SuggestedTemplate(
            icon: "network",
            task: "Work on my systems biology modeling assignment — build a genome-scale metabolic model, run flux balance analysis, construct a Boolean gene-regulatory network, or analyze metabolic flux distributions",
            successCriteria: "Systems biology assignment completed (model built or FBA simulation run with flux distributions analyzed, results interpreted, and findings documented — saved to file)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "network",
            task: "Study systems biology for my exam — review flux balance analysis, Boolean network modeling, genome-scale metabolic models, network motifs, and systems pharmacology principles",
            successCriteria: "Systems biology study session completed (at least two modeling frameworks reviewed with key concepts, example networks, and interpretation notes summarized and saved)",
            preferredDuration: 60 * 60
        ),
        // microbiologylab
        SuggestedTemplate(
            icon: "testtube.2",
            task: "Work through my microbiology lab — perform disk diffusion or Kirby-Bauer antibiotic sensitivity testing, count colonies from a serial dilution, or identify an unknown bacterium using biochemical tests",
            successCriteria: "Microbiology lab completed (colony counts recorded or unknown bacterium identified with biochemical test results documented and lab report written — saved to file)",
            preferredDuration: 45 * 60
        ),
        SuggestedTemplate(
            icon: "testtube.2",
            task: "Study for my microbiology lab practical — review CFU counting methods, serial dilution calculations, Gram staining interpretation, disk diffusion zone-of-inhibition reading, and unknown-bacteria identification flowcharts",
            successCriteria: "Microbiology lab practical study completed (all major lab techniques reviewed with key protocols, calculation examples, and identification charts summarized and saved)",
            preferredDuration: 45 * 60
        ),
        // ecophysiology
        SuggestedTemplate(
            icon: "thermometer.sun",
            task: "Study ecophysiology for my exam — review thermal performance curves, metabolic rate scaling, water potential and desiccation tolerance, ectotherm vs endotherm strategies, and physiological ecology frameworks",
            successCriteria: "Ecophysiology study session completed (at least two physiological ecology topics reviewed with key concepts, equations, and organism examples summarized and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "thermometer.sun",
            task: "Work on my ecophysiology assignment — analyze thermal performance data, model metabolic rate vs temperature, interpret osmotic stress experiments, or write up a physiological ecology case study",
            successCriteria: "Ecophysiology assignment completed (analysis written up or case study drafted with data interpretation, physiological mechanisms explained, and conclusions documented — saved to file)",
            preferredDuration: 45 * 60
        ),
        // plantphysiology
        SuggestedTemplate(
            icon: "leaf",
            task: "Study plant physiology for my exam — review phytohormone signaling (auxin, gibberellin, cytokinin, ABA), stomatal conductance, xylem and phloem transport, water potential, and source-sink dynamics",
            successCriteria: "Plant physiology study session completed (at least two topics reviewed with hormone pathways, transport mechanisms, and key equations summarized and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "leaf",
            task: "Work on my plant physiology assignment — analyze stomatal conductance data, trace xylem and phloem transport pathways, apply water potential calculations, or write up a phytohormone signaling problem",
            successCriteria: "Plant physiology assignment completed (problem solved or lab report written with transport mechanisms, hormone effects, and calculations documented — saved to file)",
            preferredDuration: 45 * 60
        ),
        // animalphysiology
        SuggestedTemplate(
            icon: "pawprint",
            task: "Study animal physiology for my exam — review osmoregulation, thermoregulation strategies, countercurrent exchange, gas exchange in gills and lungs, ion regulation, and comparative vertebrate physiology",
            successCriteria: "Animal physiology study session completed (at least two physiological systems reviewed with mechanisms, comparative examples, and key equations summarized and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "pawprint",
            task: "Work on my animal physiology assignment — analyze osmoregulation data across species, model thermoregulation strategies, apply countercurrent exchange principles, or write up a comparative physiology case study",
            successCriteria: "Animal physiology assignment completed (analysis written up or case study drafted with physiological mechanisms explained, comparative data interpreted, and conclusions documented — saved to file)",
            preferredDuration: 45 * 60
        ),
        // cellsignaling
        SuggestedTemplate(
            icon: "arrow.triangle.branch",
            task: "Study cell signaling for my exam — review receptor tyrosine kinase pathways, MAPK/ERK cascade, PI3K-Akt-mTOR, Wnt/β-catenin, Notch, Hedgehog, and JAK-STAT signaling mechanisms",
            successCriteria: "Cell signaling study session completed (at least two signaling pathways reviewed with receptor, effectors, downstream targets, and biological outcomes summarized and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "arrow.triangle.branch",
            task: "Work through my cell signaling assignment — diagram a MAPK cascade, trace a GPCR second-messenger pathway, analyze Wnt or Notch signaling crosstalk, or complete a kinase pathway problem set",
            successCriteria: "Cell signaling assignment completed (pathway diagram drawn or problem set worked with receptor activation, signal propagation, and cellular response documented — saved to file)",
            preferredDuration: 45 * 60
        ),
        // humangeneticsclass
        SuggestedTemplate(
            icon: "person.2.badge.gearshape",
            task: "Study human genetics for my exam — review pedigree analysis, chromosomal disorders, Hardy-Weinberg equilibrium, genomic imprinting, copy number variation, and OMIM disease inheritance patterns",
            successCriteria: "Human genetics study session completed (at least two topics reviewed with inheritance patterns, chromosomal mechanisms, and example disorders summarized and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "person.2.badge.gearshape",
            task: "Work on my human genetics problem set — draw and interpret pedigree charts, apply Hardy-Weinberg to a population genetics problem, classify a chromosomal disorder, or analyze a copy number variation case",
            successCriteria: "Human genetics problem set completed (pedigrees drawn or problems worked with inheritance mode, genotype frequencies, or chromosomal mechanism explained — saved to file)",
            preferredDuration: 45 * 60
        ),
        // immunogenetics
        SuggestedTemplate(
            icon: "shield.lefthalf.filled",
            task: "Study immunogenetics for my exam — review HLA typing, MHC class I and II pathways, histocompatibility principles, transplant immunology, graft rejection mechanisms, and autoimmune genetics",
            successCriteria: "Immunogenetics study session completed (at least two topics reviewed with HLA/MHC structure, antigen presentation, transplant rejection mechanisms, and clinical implications summarized and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "shield.lefthalf.filled",
            task: "Work on my immunogenetics assignment — analyze HLA haplotype data, interpret graft rejection mechanisms, classify MHC class I vs II antigen presentation, or write up a transplant immunology case study",
            successCriteria: "Immunogenetics assignment completed (HLA analysis or transplant case written up with MHC pathways, rejection mechanisms, and immunological principles documented — saved to file)",
            preferredDuration: 45 * 60
        ),
        // neurologylab
        SuggestedTemplate(
            icon: "waveform.path.ecg",
            task: "Complete my neurology lab work — interpret EEG recordings, analyze nerve conduction study results, practice cranial nerve examination, or write up my neurology lab report",
            successCriteria: "Neurology lab completed (EEG or NCS results interpreted, cranial nerve findings documented, or lab report written with clinical neurophysiology findings explained — saved to file)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "waveform.path.ecg",
            task: "Study for my neurology lab practical — review nerve conduction velocity interpretation, EEG waveform recognition, cranial nerve exam technique, and reflex testing for the neurology practicum",
            successCriteria: "Neurology lab practical prep completed (NCS interpretation, EEG waveforms, cranial nerve exam steps, and reflex testing methods reviewed and summarized — saved to file)",
            preferredDuration: 45 * 60
        ),
        // socialpsychology
        SuggestedTemplate(
            icon: "person.3",
            task: "Study social psychology for my exam — review attitude formation and change, social influence, conformity, obedience, bystander effect, cognitive dissonance, attribution theory, and social identity theory",
            successCriteria: "Social psychology study session completed (at least two social psych topics reviewed with key theories, classic experiments, and real-world applications summarized and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "person.3",
            task: "Work on my social psychology assignment — apply attribution theory to a case study, analyze the Milgram or Asch experiments, write up a cognitive dissonance scenario, or complete a persuasion and attitude change analysis",
            successCriteria: "Social psychology assignment completed (theory applied or experiment analyzed with key social psych mechanisms, influencing variables, and implications documented — saved to file)",
            preferredDuration: 45 * 60
        ),
        // geriatricrotation
        SuggestedTemplate(
            icon: "person.and.background.dotted",
            task: "Complete geriatric rotation tasks — write up a comprehensive geriatric assessment (CGA), document a polypharmacy review, assess fall risk and frailty in patients, or write a geriatric ward note",
            successCriteria: "Geriatric rotation task completed (CGA write-up, polypharmacy review, or ward note finished with functional status, frailty score, medication list, and clinical plan documented — saved to file)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "person.and.background.dotted",
            task: "Study for geriatric rotation — review frailty syndrome and assessment tools, delirium vs. dementia differentiation, age-related pharmacokinetics, comprehensive geriatric assessment components, and fall prevention",
            successCriteria: "Geriatric rotation study completed (frailty, delirium/dementia, CGA components, age-related pharmacokinetics, and fall risk topics reviewed with key clinical points summarized and saved)",
            preferredDuration: 45 * 60
        ),
        // neurochemistry
        SuggestedTemplate(
            icon: "brain.head.profile",
            task: "Study neurochemistry for my exam — review neurotransmitter synthesis and degradation, monoamine pathways (dopamine, serotonin, norepinephrine), synaptic vesicle cycling, GABA/glutamate balance, and neuropeptide signaling",
            successCriteria: "Neurochemistry study session completed (at least two neurotransmitter systems reviewed with synthesis pathways, degradation enzymes, receptor types, and clinical pharmacology implications summarized and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "brain.head.profile",
            task: "Work through my neurochemistry assignment — trace the dopamine or serotonin synthesis pathway, map catecholamine biosynthesis, analyze MAO inhibitor mechanisms, or diagram synaptic vesicle cycling steps",
            successCriteria: "Neurochemistry assignment completed (neurotransmitter pathway traced or MAO mechanism analyzed with all enzymatic steps, cofactors, and pharmacological relevance documented — saved to file)",
            preferredDuration: 45 * 60
        ),
        // psychobiologyclass
        SuggestedTemplate(
            icon: "brain",
            task: "Study biopsychology for my exam — review brain structure and function, hemispheric lateralization, hormones and behavior, genetics and behavior, sensation and perception, and neurobiological bases of emotion",
            successCriteria: "Biopsychology study session completed (at least two topics reviewed with brain-behavior relationships, cortical functions, lateralization evidence, and hormonal/genetic influences summarized and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "brain",
            task: "Work on my biological psychology assignment — map cortical functions and lobes, analyze a case study on brain lesion and behavior, compare hemispheric specialization evidence, or trace a hormones-and-behavior pathway",
            successCriteria: "Biological psychology assignment completed (brain-behavior analysis or case study written with cortical regions, lateralization, and neurobiological mechanisms documented — saved to file)",
            preferredDuration: 45 * 60
        ),
        // abnormalpsychology
        SuggestedTemplate(
            icon: "list.clipboard",
            task: "Study abnormal psychology for my exam — review DSM-5 criteria for anxiety, mood, psychotic, and personality disorders, etiology models, case conceptualization frameworks, and differential diagnosis principles",
            successCriteria: "Abnormal psychology study session completed (at least two disorder categories reviewed with DSM criteria, etiology, prevalence, and differential diagnosis points summarized and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "list.clipboard",
            task: "Work on my abnormal psychology assignment — apply DSM-5 diagnostic criteria to a case vignette, write a case conceptualization, analyze disorder etiology, or compare differential diagnoses for a clinical scenario",
            successCriteria: "Abnormal psychology assignment completed (DSM criteria applied and case conceptualization or differential diagnosis written with etiological factors, symptom presentation, and diagnostic rationale documented — saved to file)",
            preferredDuration: 45 * 60
        ),
        // healthpsychology
        SuggestedTemplate(
            icon: "heart.text.clipboard",
            task: "Study health psychology for my exam — review the biopsychosocial model, psychoneuroimmunology, stress and health pathways, pain psychology, illness behavior, and coping mechanisms for chronic illness",
            successCriteria: "Health psychology study session completed (at least two topics reviewed with biopsychosocial framework, PNI mechanisms, stress-health links, and coping strategies summarized and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "heart.text.clipboard",
            task: "Work on my health psychology assignment — apply the biopsychosocial model to a patient case, analyze coping strategies and health outcomes, write a psychoneuroimmunology summary, or evaluate a placebo effect study",
            successCriteria: "Health psychology assignment completed (biopsychosocial analysis or coping/PNI case written with psychological, biological, and social factors documented with evidence-based health implications — saved to file)",
            preferredDuration: 45 * 60
        ),
        // linearalgebra
        SuggestedTemplate(
            icon: "function",
            task: "Study linear algebra for my exam — review eigenvectors and eigenvalues, matrix decompositions (LU, QR, SVD), vector spaces, linear independence, span and basis, linear transformations, and diagonalization",
            successCriteria: "Linear algebra study session completed (at least two topics reviewed with key theorems, worked examples, and conceptual explanations of eigenvectors, matrix factorizations, or vector spaces summarized and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "function",
            task: "Work on my linear algebra problem set — solve eigenvalue problems, compute LU or QR decompositions, prove linear independence, find null space or column space, apply Gram-Schmidt orthogonalization, or diagonalize a matrix",
            successCriteria: "Linear algebra problem set completed (eigenvalue/eigenvector problems, matrix decompositions, or vector space proofs solved with all steps shown and answers verified — saved to file)",
            preferredDuration: 45 * 60
        ),
        // differentialequations
        SuggestedTemplate(
            icon: "waveform",
            task: "Study differential equations for my exam — review separation of variables, integrating factor method, Laplace transforms, first- and second-order ODEs, systems of ODEs, Fourier series, and the heat and wave equations",
            successCriteria: "Differential equations study session completed (at least two ODE/PDE methods reviewed with solution steps, worked examples, and key formulas for Laplace transforms or Fourier series summarized and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "waveform",
            task: "Work on my differential equations problem set — solve first- or second-order ODEs using separation of variables or integrating factors, apply Laplace transforms, analyze systems of ODEs, or solve a heat/wave PDE with Fourier series",
            successCriteria: "Differential equations problem set completed (ODEs or PDEs solved with all integration steps, boundary conditions applied, and Laplace or Fourier methods demonstrated — saved to file)",
            preferredDuration: 45 * 60
        ),
        // neuropsychology
        SuggestedTemplate(
            icon: "brain.head.profile",
            task: "Study neuropsychology for my exam — review neuropsychological assessment batteries (Wechsler, Trail Making Test, Stroop), executive function models, memory assessment, cortical functions and lateralization, and neuropsychological rehabilitation",
            successCriteria: "Neuropsychology study session completed (at least two assessment approaches reviewed with key test batteries, scoring principles, cortical function correlates, and clinical interpretation summarized and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "brain.head.profile",
            task: "Work on my neuropsychology assignment — interpret neuropsychological test results, apply executive function assessment frameworks, analyze a cortical lesion case, complete a neuropsychological battery overview, or write up a neuropsych report",
            successCriteria: "Neuropsychology assignment completed (test interpretation or case analysis written with assessment battery results, executive function findings, cortical correlates, and clinical implications documented — saved to file)",
            preferredDuration: 45 * 60
        ),
        // developmentalpsych
        SuggestedTemplate(
            icon: "figure.and.child.holdinghands",
            task: "Study developmental psychology for my exam — review Piaget's cognitive stages (sensorimotor through formal operational), attachment theory (Bowlby and Ainsworth), theory of mind, infant cognition, and object permanence",
            successCriteria: "Developmental psychology study session completed (at least two developmental topics reviewed with Piaget stage criteria, attachment patterns, theory of mind milestones, and key theorists' contributions summarized and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "figure.and.child.holdinghands",
            task: "Work on my developmental psychology assignment — apply Piaget's cognitive stage theory to a case, analyze Strange Situation attachment classifications, evaluate theory of mind research, or write up infant cognition findings",
            successCriteria: "Developmental psychology assignment completed (Piaget stage analysis or attachment classification applied with theoretical framework, supporting evidence, and developmental implications documented — saved to file)",
            preferredDuration: 45 * 60
        ),
        // militarymedicine
        SuggestedTemplate(
            icon: "cross.case",
            task: "Study tactical combat casualty care (TCCC) — review the MARCH algorithm, care-under-fire protocols, tactical field care, tourniquet application and hemorrhage control, airway management in the field, and casualty evacuation procedures",
            successCriteria: "TCCC study session completed (MARCH algorithm phases reviewed, care-under-fire and tactical field care protocols, hemorrhage control and airway management steps, and casualty evacuation procedures summarized and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "cross.case",
            task: "Complete my combat medicine training tasks — write up a TCCC case scenario using MARCH, document tourniquet and hemorrhage control technique steps, review prolonged field care protocols, or practice a tactical medicine scenario",
            successCriteria: "Combat medicine training task completed (TCCC case write-up or protocol documentation finished with MARCH phases, hemorrhage control priorities, airway and hypothermia management, and casualty care steps documented — saved to file)",
            preferredDuration: 45 * 60
        ),
        // complexanalysis
        SuggestedTemplate(
            icon: "function",
            task: "Study complex analysis for my exam — review Cauchy-Riemann equations, contour integration, residue theorem, Cauchy's integral formula, analytic and holomorphic functions, Laurent series, and conformal mappings",
            successCriteria: "Complex analysis study session completed (at least two topics reviewed with Cauchy-Riemann conditions, residue theorem applications, contour integration techniques, and key theorems summarized and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "function",
            task: "Work on my complex analysis problem set — compute contour integrals using residues, verify Cauchy-Riemann equations, apply Cauchy's integral formula, classify singularities, or construct conformal mappings",
            successCriteria: "Complex analysis problem set completed (contour integrals, residue calculations, or conformal mapping problems solved with full working shown and answers verified — saved to file)",
            preferredDuration: 45 * 60
        ),
        // realanalysis
        SuggestedTemplate(
            icon: "function",
            task: "Study real analysis for my exam — review epsilon-delta definitions, metric spaces, Cauchy sequences, uniform convergence, compactness (Heine-Borel), Lebesgue integration, and measure theory foundations",
            successCriteria: "Real analysis study session completed (at least two topics reviewed with epsilon-delta proofs, metric space properties, convergence criteria, and Lebesgue integration concepts summarized and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "function",
            task: "Work on my real analysis problem set — write epsilon-delta proofs, prove convergence in metric spaces, apply Heine-Borel compactness, demonstrate uniform convergence, or work through Lebesgue integration problems",
            successCriteria: "Real analysis problem set completed (epsilon-delta proofs or metric space/convergence problems solved with rigorous justification at each step — saved to file)",
            preferredDuration: 45 * 60
        ),
        // discretemath
        SuggestedTemplate(
            icon: "network",
            task: "Study discrete math for my exam — review proof by induction, graph theory fundamentals, combinatorics (permutations/combinations), propositional logic, pigeonhole principle, recurrence relations, and inclusion-exclusion",
            successCriteria: "Discrete math study session completed (at least two topics reviewed with proof techniques, graph theory properties, combinatorial formulas, and logic rules summarized and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "network",
            task: "Work on my discrete math problem set — write proofs by induction, solve graph theory problems, apply combinatorics counting techniques, evaluate propositional logic expressions, or solve recurrence relations",
            successCriteria: "Discrete math problem set completed (induction proofs, graph theory or combinatorics problems solved with clear logical steps and verified answers — saved to file)",
            preferredDuration: 45 * 60
        ),
        // probabilitytheory
        SuggestedTemplate(
            icon: "chart.bar",
            task: "Study probability theory for my exam — review sigma-algebras, random variables, expectation and variance, conditional probability, moment generating functions, central limit theorem, and law of large numbers",
            successCriteria: "Probability theory study session completed (at least two topics reviewed with measure-theoretic definitions, random variable properties, CLT conditions, and key theorems summarized and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "chart.bar",
            task: "Work on my probability theory problem set — derive moment generating functions, prove convergence theorems, compute conditional expectations, work with sigma-algebras, or apply the central limit theorem",
            successCriteria: "Probability theory problem set completed (measure-theoretic probability problems solved with rigorous derivations, convergence arguments, or CLT applications documented — saved to file)",
            preferredDuration: 45 * 60
        ),
        // numericalanalysis
        SuggestedTemplate(
            icon: "number",
            task: "Study numerical analysis for my exam — review floating-point arithmetic, Newton's method, bisection method, numerical integration (Gaussian quadrature, Simpson's rule), finite differences, interpolation, and error analysis",
            successCriteria: "Numerical analysis study session completed (at least two methods reviewed with algorithm steps, convergence rates, error bounds, and floating-point considerations summarized and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "number",
            task: "Work on my numerical analysis problem set — implement Newton's method or bisection, compute numerical integrals, apply finite difference schemes, construct interpolating polynomials, or analyze truncation and round-off error",
            successCriteria: "Numerical analysis problem set completed (root-finding, integration, or interpolation problems solved with algorithm steps, error estimates, and numerical results documented — saved to file)",
            preferredDuration: 45 * 60
        ),
        // statisticalmethods
        SuggestedTemplate(
            icon: "chart.bar.xaxis",
            task: "Study applied statistics for my exam — review experimental design, ANOVA, Bayesian inference, nonparametric methods, and time series analysis",
            successCriteria: "Applied statistics study session completed (at least two methods reviewed with design principles, test assumptions, Bayesian updating rules, or nonparametric procedures summarized and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "chart.bar.xaxis",
            task: "Work on my statistical methods assignment — apply design of experiments, run ANOVA or nonparametric tests, or derive Bayesian posterior distributions",
            successCriteria: "Statistical methods assignment completed (experimental design, ANOVA table, Bayesian derivation, or nonparametric test results documented with interpretations — saved to file)",
            preferredDuration: 45 * 60
        ),
        // topology
        SuggestedTemplate(
            icon: "circle.dashed",
            task: "Study topology for my exam — review open and closed sets, compactness, connectedness, homeomorphisms, homotopy, and quotient spaces",
            successCriteria: "Topology study session completed (at least two topics reviewed with definitions, theorems, and proof strategies for compactness, connectedness, and homeomorphisms summarized and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "circle.dashed",
            task: "Work on my topology problem set — prove compactness or connectedness, construct homeomorphisms, analyze open and closed sets, or work with quotient spaces",
            successCriteria: "Topology problem set completed (compactness proofs, homeomorphism constructions, or quotient space arguments written with rigorous justification at each step — saved to file)",
            preferredDuration: 45 * 60
        ),
        // abstractalgebra
        SuggestedTemplate(
            icon: "square.grid.3x3",
            task: "Study abstract algebra for my exam — review group theory, ring theory, field theory, Galois theory, homomorphisms, isomorphism theorems, and Sylow theorems",
            successCriteria: "Abstract algebra study session completed (at least two topics reviewed with group/ring/field definitions, key theorems, and proof strategies for isomorphism and Sylow theorems summarized and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "square.grid.3x3",
            task: "Work on my abstract algebra problem set — prove group isomorphisms, classify quotient groups, apply Sylow theorems, or work with ring and field extensions",
            successCriteria: "Abstract algebra problem set completed (group theory proofs, isomorphism arguments, Sylow calculations, or ring/field extension problems solved with rigorous justification — saved to file)",
            preferredDuration: 45 * 60
        ),
        // seismology
        SuggestedTemplate(
            icon: "waveform.path",
            task: "Study seismology for my exam — review seismic waves (P/S/surface), earthquake location methods, focal mechanisms, seismogram analysis, and seismograph station networks",
            successCriteria: "Seismology study session completed (at least two topics reviewed with wave propagation properties, location algorithm steps, focal mechanism interpretation, and seismogram reading techniques summarized and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "waveform.path",
            task: "Work through my seismology problem set — locate earthquakes from arrival times, interpret focal mechanisms, analyze seismograms, or apply seismic wave theory",
            successCriteria: "Seismology problem set completed (earthquake location calculations, focal mechanism analysis, seismogram interpretation, or wave propagation problems solved and documented — saved to file)",
            preferredDuration: 60 * 60
        ),
        // volcanology
        SuggestedTemplate(
            icon: "flame",
            task: "Study volcanology for my exam — review magma eruption dynamics, pyroclastic flows, lahars, volcanic hazard assessment, tephra deposits, and caldera formation",
            successCriteria: "Volcanology study session completed (at least two topics reviewed with eruption styles, volcanic product classifications, hazard zones, and process mechanisms summarized and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "flame",
            task: "Work on my volcanology assignment — analyze pyroclastic flow deposits, assess volcanic hazards, interpret tephra stratigraphy, or model eruption dynamics",
            successCriteria: "Volcanology assignment completed (volcanic hazard assessment, pyroclastic deposit analysis, tephra interpretation, or eruption dynamics calculations documented — saved to file)",
            preferredDuration: 45 * 60
        ),
        // geomorphology
        SuggestedTemplate(
            icon: "mountain.2",
            task: "Study geomorphology for my exam — review fluvial, glacial, and aeolian geomorphology, landform analysis, hillslope processes, drainage basin morphology, and DEM analysis",
            successCriteria: "Geomorphology study session completed (at least two process domains reviewed with landform types, driving mechanisms, and morphometric analysis techniques summarized and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "mountain.2",
            task: "Work on my geomorphology assignment — analyze landforms from DEMs, interpret fluvial or glacial processes, characterize drainage basin morphology, or map hillslope processes",
            successCriteria: "Geomorphology assignment completed (landform analysis, DEM interpretation, drainage basin characterization, or process mapping documented with observations and conclusions — saved to file)",
            preferredDuration: 45 * 60
        ),
        // sedimentology
        SuggestedTemplate(
            icon: "square.stack.3d.down.right",
            task: "Study sedimentology for my exam — review grain size analysis, sedimentary structures, fluvial/deltaic/turbidite facies, sediment transport, and provenance analysis",
            successCriteria: "Sedimentology study session completed (at least two facies or processes reviewed with grain size classification, sedimentary structure interpretation, and transport mechanisms summarized and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "square.stack.3d.down.right",
            task: "Work on my sedimentology assignment — interpret sedimentary structures, classify grain sizes, analyze facies associations, or write up sedimentary basin analysis",
            successCriteria: "Sedimentology assignment completed (sedimentary structure interpretation, facies analysis, grain size classification, or basin analysis documented with evidence and conclusions — saved to file)",
            preferredDuration: 45 * 60
        ),
        // structuralgeology
        SuggestedTemplate(
            icon: "arrow.triangle.branch",
            task: "Study structural geology for my exam — review fault analysis, fold geometry, stereonet analysis, stress and strain fields, kinematic indicators, and deformation mechanisms",
            successCriteria: "Structural geology study session completed (at least two topics reviewed with fault/fold classifications, stereonet plotting steps, kinematic indicators, and deformation mechanism descriptions summarized and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "arrow.triangle.branch",
            task: "Work on my structural geology problem set — plot stereonets, analyze fault kinematics, interpret fold geometry, determine stress orientations, or characterize shear zones",
            successCriteria: "Structural geology problem set completed (stereonet plots, fault kinematic analysis, fold interpretation, or stress/strain calculations completed with labeled diagrams and written conclusions — saved to file)",
            preferredDuration: 45 * 60
        ),
        // functionalanalysis
        SuggestedTemplate(
            icon: "function",
            task: "Study functional analysis for my exam — review Banach and Hilbert spaces, bounded and compact operators, spectral theory, Fourier analysis, and the open mapping and closed graph theorems",
            successCriteria: "Functional analysis study session completed (at least two topics reviewed with space definitions, key theorems such as Hahn-Banach or spectral theorem, and proof strategies summarized and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "function",
            task: "Work on my functional analysis problem set — prove properties of Banach/Hilbert spaces, analyze bounded operators, apply spectral theory, or derive Fourier analysis results",
            successCriteria: "Functional analysis problem set completed (space proofs, operator analysis, spectral calculations, or Fourier problems solved with rigorous justification at each step — saved to file)",
            preferredDuration: 45 * 60
        ),
        // differentialgeometry
        SuggestedTemplate(
            icon: "circle.and.line.horizontal",
            task: "Study differential geometry for my exam — review Riemannian manifolds, curvature tensors, geodesics, differential forms, covariant derivatives, and Christoffel symbols",
            successCriteria: "Differential geometry study session completed (at least two topics reviewed with manifold definitions, curvature formulas, geodesic equations, and differential form operations summarized and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "circle.and.line.horizontal",
            task: "Work on my differential geometry problem set — compute Christoffel symbols, derive geodesic equations, calculate curvature tensors, or work with differential forms on manifolds",
            successCriteria: "Differential geometry problem set completed (Christoffel symbol calculations, geodesic derivations, curvature tensor computations, or differential form problems solved with all steps shown — saved to file)",
            preferredDuration: 45 * 60
        ),
        // cosmology
        SuggestedTemplate(
            icon: "moon.stars",
            task: "Study cosmology for my exam — review Friedmann equations, Hubble constant, dark matter and dark energy, cosmic microwave background, inflationary cosmology, and large-scale structure",
            successCriteria: "Cosmology study session completed (at least two topics reviewed with Friedmann equation derivations, CMB features, inflation mechanisms, and large-scale structure descriptions summarized and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "moon.stars",
            task: "Work on my cosmology problem set — solve Friedmann equations, calculate Hubble parameter evolution, analyze CMB power spectra, or work through primordial nucleosynthesis",
            successCriteria: "Cosmology problem set completed (Friedmann equation solutions, Hubble evolution calculations, CMB analysis, or nucleosynthesis problems solved with all work shown — saved to file)",
            preferredDuration: 45 * 60
        ),
        // planetaryscience
        SuggestedTemplate(
            icon: "globe",
            task: "Study planetary science for my exam — review solar system formation, planetary geology, planetary atmospheres, impact cratering, exoplanet characterization, and habitability criteria",
            successCriteria: "Planetary science study session completed (at least two topics reviewed with formation models, geological processes, atmospheric compositions, and habitability factors summarized and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "globe",
            task: "Work on my planetary science assignment — analyze planetary geology, characterize exoplanet atmospheres, model solar system formation, or assess planetary habitability",
            successCriteria: "Planetary science assignment completed (planetary geology analysis, exoplanet characterization, formation model assessment, or habitability evaluation documented with evidence and conclusions — saved to file)",
            preferredDuration: 45 * 60
        ),
        // particlephysics
        SuggestedTemplate(
            icon: "atom",
            task: "Study particle physics for my exam — review the Standard Model, Feynman diagrams, gauge theories, quarks and leptons, weak and strong interactions, and Higgs mechanism",
            successCriteria: "Particle physics study session completed (at least two topics reviewed with Standard Model particles, Feynman diagram rules, gauge symmetry principles, and interaction descriptions summarized and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "atom",
            task: "Work on my particle physics or QFT problem set — draw Feynman diagrams, calculate scattering amplitudes, analyze symmetry breaking, or work through gauge theory problems",
            successCriteria: "Particle physics problem set completed (Feynman diagrams drawn, amplitudes calculated, symmetry breaking analyzed, or gauge theory problems solved with all steps shown — saved to file)",
            preferredDuration: 45 * 60
        ),
        // statisticalmechanics
        SuggestedTemplate(
            icon: "chart.bar",
            task: "Study statistical mechanics for my exam — review partition functions, Boltzmann distribution, canonical and grand canonical ensembles, Fermi-Dirac and Bose-Einstein statistics, and phase transitions",
            successCriteria: "Statistical mechanics study session completed (at least two topics reviewed with ensemble definitions, partition function derivations, distribution functions, and phase transition descriptions summarized and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "chart.bar",
            task: "Work on my statistical mechanics problem set — evaluate partition functions, derive thermodynamic quantities, analyze Fermi-Dirac or Bose-Einstein distributions, or model phase transitions",
            successCriteria: "Statistical mechanics problem set completed (partition function evaluations, thermodynamic derivations, quantum statistics calculations, or phase transition analyses completed with all steps shown — saved to file)",
            preferredDuration: 45 * 60
        ),
        // environmentalchemistry
        SuggestedTemplate(
            icon: "leaf.arrow.triangle.circlepath",
            task: "Study environmental chemistry for my exam — review contaminant fate and transport, water quality chemistry, soil chemistry, Henry's law, green chemistry principles, and aquatic chemistry",
            successCriteria: "Environmental chemistry study session completed (at least two topics reviewed with fate/transport mechanisms, water quality parameters, soil sorption processes, and Henry's law applications summarized and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "leaf.arrow.triangle.circlepath",
            task: "Work on my environmental chemistry assignment — model contaminant fate and transport, analyze water quality chemistry, apply Henry's law calculations, or assess pollutant behavior in aquatic systems",
            successCriteria: "Environmental chemistry assignment completed (contaminant transport model, water quality analysis, Henry's law calculations, or aquatic pollutant assessment documented with methods and results — saved to file)",
            preferredDuration: 45 * 60
        ),
        // radioastronomy
        SuggestedTemplate(
            icon: "antenna.radiowaves.left.and.right",
            task: "Study radio astronomy for my exam — review radio telescope design, aperture synthesis, VLBI, pulsar timing, 21cm line observations, synchrotron radiation, and interferometric imaging",
            successCriteria: "Radio astronomy study session completed (at least two topics reviewed with telescope principles, interferometry theory, pulsar timing methods, and emission mechanisms summarized and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "antenna.radiowaves.left.and.right",
            task: "Work on my radio astronomy assignment — reduce VLBI data, analyze pulsar timing residuals, construct aperture synthesis maps, or interpret radio continuum emission",
            successCriteria: "Radio astronomy assignment completed (data reduction pipeline, timing analysis, aperture synthesis map, or emission interpretation documented with methods and results — saved to file)",
            preferredDuration: 45 * 60
        ),
        // astrochemistry
        SuggestedTemplate(
            icon: "sparkles",
            task: "Study astrochemistry for my exam — review interstellar medium chemistry, molecular cloud composition, chemical evolution, interstellar molecules, and protostellar chemistry",
            successCriteria: "Astrochemistry study session completed (at least two topics reviewed with ISM chemistry mechanisms, molecular cloud abundances, chemical network reactions, and observational signatures summarized and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "sparkles",
            task: "Work on my astrochemistry assignment — analyze interstellar molecular abundances, model chemical networks in molecular clouds, or interpret spectral line data for ISM chemistry",
            successCriteria: "Astrochemistry assignment completed (molecular abundance analysis, chemical network model, or ISM spectral line interpretation documented with methods and conclusions — saved to file)",
            preferredDuration: 45 * 60
        ),
        // nuclearphysics
        SuggestedTemplate(
            icon: "atom",
            task: "Study nuclear physics for my exam — review nuclear structure, radioactive decay, alpha/beta/gamma decay, nuclear reactions, fission and fusion energetics, and the nuclear shell model",
            successCriteria: "Nuclear physics study session completed (at least two topics reviewed with binding energy calculations, decay chain derivations, nuclear reaction Q-values, and shell model descriptions summarized and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "atom",
            task: "Work on my nuclear physics problem set — calculate radioactive decay chains, determine Q-values for nuclear reactions, analyze fission or fusion energetics, or apply the nuclear shell model",
            successCriteria: "Nuclear physics problem set completed (decay chain calculations, Q-value determinations, fission/fusion energy analysis, or shell model applications solved with all steps shown — saved to file)",
            preferredDuration: 45 * 60
        ),
        // plasmaphysics
        SuggestedTemplate(
            icon: "bolt.horizontal",
            task: "Study plasma physics for my exam — review Debye shielding, plasma oscillations, MHD equations, magnetic confinement in tokamaks and stellarators, Alfvén waves, and fusion plasma behavior",
            successCriteria: "Plasma physics study session completed (at least two topics reviewed with Debye length derivations, MHD equation structures, confinement principles, and Alfvén wave properties summarized and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "bolt.horizontal",
            task: "Work on my plasma physics problem set — derive Debye shielding lengths, solve MHD equilibrium equations, analyze tokamak confinement, or model plasma wave propagation",
            successCriteria: "Plasma physics problem set completed (Debye length derivation, MHD equilibrium solution, confinement analysis, or wave propagation calculation completed with all steps shown — saved to file)",
            preferredDuration: 45 * 60
        ),
        // computationalfluidynamics
        SuggestedTemplate(
            icon: "wind",
            task: "Study computational fluid dynamics for my exam — review Navier-Stokes equations, finite volume methods, turbulence modeling (RANS, LES), boundary layer theory, and CFD simulation workflow",
            successCriteria: "CFD study session completed (at least two topics reviewed with NS equation discretization, finite volume schemes, turbulence model closures, and simulation setup principles summarized and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "wind",
            task: "Work on my CFD assignment — discretize Navier-Stokes equations using finite volume methods, set up turbulence models, run flow simulations in OpenFOAM or ANSYS Fluent, or analyze convergence",
            successCriteria: "CFD assignment completed (NS discretization, turbulence model setup, simulation results, or convergence analysis documented with mesh details, boundary conditions, and post-processing results — saved to file)",
            preferredDuration: 60 * 60
        ),
        // glaciology
        SuggestedTemplate(
            icon: "snowflake",
            task: "Study glaciology for my exam — review glacier dynamics, ice sheet mechanics, mass balance equations, ice core analysis, glacial landforms, cryosphere processes, and sea ice extent",
            successCriteria: "Glaciology study session completed (at least two topics reviewed with glacier flow laws, mass balance calculations, ice core proxy records, glacial erosion features, and cryosphere feedbacks summarized and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "snowflake",
            task: "Work on my glaciology assignment — analyze glacier mass balance data, model ice sheet flow, interpret ice core records, map glacial landforms, or assess permafrost and sea ice extent",
            successCriteria: "Glaciology assignment completed (mass balance analysis, ice flow model, ice core interpretation, glacial mapping, or permafrost assessment completed with data sources, methods, and results documented — saved to file)",
            preferredDuration: 45 * 60
        ),
        // hydrology
        SuggestedTemplate(
            icon: "drop.fill",
            task: "Study hydrology for my exam — review the hydrological cycle, streamflow analysis, flood frequency, hydrograph methods, unit hydrograph theory, baseflow separation, and evapotranspiration estimation",
            successCriteria: "Hydrology study session completed (at least two topics reviewed with hydrological cycle stages, streamflow calculation steps, flood frequency methods, and hydrograph derivation principles summarized and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "drop.fill",
            task: "Work on my hydrology assignment — analyze watershed runoff, compute flood frequency curves, derive unit hydrographs, estimate evapotranspiration, or apply the rational method to a drainage basin",
            successCriteria: "Hydrology assignment completed (watershed runoff analysis, flood frequency computation, unit hydrograph derivation, or rational method calculation completed with all assumptions, data inputs, and results documented — saved to file)",
            preferredDuration: 45 * 60
        ),
        // climatology
        SuggestedTemplate(
            icon: "sun.haze.fill",
            task: "Study climatology for my exam — review climate models, radiative forcing, climate sensitivity, ENSO, Hadley cell circulation, paleoclimate evidence, climate feedbacks, and the global energy balance",
            successCriteria: "Climatology study session completed (at least two topics reviewed with radiative forcing mechanisms, climate sensitivity values, ENSO dynamics, Hadley cell structure, and feedback processes summarized and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "sun.haze.fill",
            task: "Work on my climatology assignment — analyze climate model output, calculate radiative forcing, examine paleoclimate proxies, interpret ENSO indices, or assess climate sensitivity scenarios",
            successCriteria: "Climatology assignment completed (model analysis, radiative forcing calculation, paleoclimate proxy examination, ENSO interpretation, or sensitivity assessment completed with data, methods, and conclusions documented — saved to file)",
            preferredDuration: 45 * 60
        ),
        // photochemistry
        SuggestedTemplate(
            icon: "sparkles",
            task: "Study photochemistry for my exam — review photochemical reactions, excited states, Jablonski diagrams, quantum yield, singlet and triplet states, fluorescence, phosphorescence, and energy transfer mechanisms",
            successCriteria: "Photochemistry study session completed (at least two topics reviewed with Jablonski diagram transitions, quantum yield calculations, excited state lifetimes, and energy transfer principles summarized and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "sparkles",
            task: "Work on my photochemistry assignment — analyze excited-state decay pathways, compute quantum yields, draw Jablonski diagrams, examine Förster energy transfer, or solve photolysis reaction mechanisms",
            successCriteria: "Photochemistry assignment completed (decay pathway analysis, quantum yield computation, Jablonski diagram, FRET analysis, or photolysis mechanism completed with energy levels, rate constants, and all steps shown — saved to file)",
            preferredDuration: 45 * 60
        ),
        // electromagnetictheory
        SuggestedTemplate(
            icon: "bolt.fill",
            task: "Study electromagnetic theory for my exam — review Maxwell's equations in full generality, vector and scalar potentials, gauge invariance, retarded potentials, multipole expansion, radiation, and relativistic electrodynamics",
            successCriteria: "Electromagnetic theory study session completed (at least two topics reviewed with potential derivations, gauge transformation steps, retarded potential integrals, multipole terms, and Larmor radiation formula summarized and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "bolt.fill",
            task: "Work on my electromagnetic theory problem set — derive retarded potentials, compute multipole expansions, analyze radiation from accelerating charges, apply gauge transformations, or solve relativistic field problems",
            successCriteria: "Electromagnetic theory problem set completed (retarded potential derivation, multipole computation, radiation analysis, gauge transformation, or relativistic field solution completed with all vector calculus steps shown — saved to file)",
            preferredDuration: 60 * 60
        ),
        // operatingsystems
        SuggestedTemplate(
            icon: "cpu.fill",
            task: "Study operating systems for my exam — review process scheduling, virtual memory, page replacement algorithms, file systems, system calls, deadlock detection and prevention, synchronization primitives, and the kernel architecture",
            successCriteria: "Operating systems study session completed (at least two topics reviewed with process scheduling algorithms, virtual memory paging steps, page replacement policies, and synchronization mechanisms summarized and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "cpu.fill",
            task: "Work on my operating systems assignment — implement a process scheduler, simulate virtual memory with page replacement, write a kernel module, analyze deadlock scenarios, or solve synchronization problems using semaphores and mutexes",
            successCriteria: "Operating systems assignment completed (scheduler implementation, page replacement simulation, kernel module, deadlock analysis, or synchronization solution completed with design decisions, test cases, and results documented — saved to file)",
            preferredDuration: 45 * 60
        ),
        // algorithms
        SuggestedTemplate(
            icon: "arrow.triangle.branch",
            task: "Study algorithms for my exam — review dynamic programming, divide and conquer, greedy algorithms, graph algorithms, computational complexity, amortized analysis, NP-completeness, and algorithm correctness proofs",
            successCriteria: "Algorithms study session completed (at least two topics reviewed with recurrence relations, complexity analysis, graph algorithm steps, and NP-completeness reduction techniques summarized and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "arrow.triangle.branch",
            task: "Work on my algorithms problem set — prove algorithm correctness, analyze time and space complexity, design a dynamic programming solution, implement a graph algorithm, or write a polynomial-time reduction for NP-completeness",
            successCriteria: "Algorithms problem set completed (correctness proof, complexity analysis, DP solution, graph algorithm implementation, or NP reduction completed with all steps, invariants, and big-O derivations shown — saved to file)",
            preferredDuration: 60 * 60
        ),
        // databasesystems
        SuggestedTemplate(
            icon: "cylinder.fill",
            task: "Study database systems for my exam — review relational model, ER diagrams, SQL, normalization, query optimization, transaction management, ACID properties, indexing, and B-tree structures",
            successCriteria: "Database systems study session completed (at least two topics reviewed with ER diagram notation, normalization forms, SQL query patterns, transaction isolation levels, and B-tree index operations summarized and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "cylinder.fill",
            task: "Work on my database systems assignment — design an ER diagram, write and optimize SQL queries, normalize a schema to 3NF/BCNF, analyze transaction isolation levels, or implement a stored procedure",
            successCriteria: "Database systems assignment completed (ER diagram, SQL queries, normalization schema, transaction analysis, or stored procedure completed with design rationale, all steps, and test queries shown — saved to file)",
            preferredDuration: 45 * 60
        ),
        // computernetworks
        SuggestedTemplate(
            icon: "network",
            task: "Study computer networks for my exam — review OSI model, TCP/IP stack, routing protocols, IP addressing and subnetting, transport layer protocols, socket programming, data link layer, and network security fundamentals",
            successCriteria: "Computer networks study session completed (at least two topics reviewed with OSI layer functions, TCP/IP header fields, routing algorithm steps, subnetting calculations, and socket API calls summarized and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "network",
            task: "Work on my computer networks assignment — implement a socket program, analyze packet captures in Wireshark, calculate subnets and routing tables, simulate a network topology, or trace TCP connection state machines",
            successCriteria: "Computer networks assignment completed (socket program, Wireshark analysis, subnet calculation, network simulation, or TCP state trace completed with protocol headers, routing decisions, and results documented — saved to file)",
            preferredDuration: 45 * 60
        ),
        // computervision
        SuggestedTemplate(
            icon: "camera.fill",
            task: "Study computer vision for my exam — review image filtering, edge detection, feature extraction, optical flow, stereo vision, object detection architectures, image segmentation, and convolutional neural network fundamentals",
            successCriteria: "Computer vision study session completed (at least two topics reviewed with convolution kernel math, feature descriptor steps, optical flow equations, and CNN layer operations summarized and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "camera.fill",
            task: "Work on my computer vision project — implement an object detector with OpenCV or PyTorch, train an image classifier, apply semantic segmentation, compute optical flow, or build a stereo depth estimator",
            successCriteria: "Computer vision project completed (object detector, image classifier, segmentation model, optical flow computation, or depth estimator implemented and tested with sample images, evaluation metrics, and code saved to file)",
            preferredDuration: 60 * 60
        ),
        // softwareengineering
        SuggestedTemplate(
            icon: "hammer.fill",
            task: "Study software engineering for my exam — review UML class diagrams, design patterns (GoF), SOLID principles, agile methodologies, software requirements engineering, software testing strategies, and the software development lifecycle",
            successCriteria: "Software engineering study session completed (at least two topics reviewed with UML diagram notation, design pattern structure diagrams, SOLID principle examples, and agile/waterfall lifecycle stages summarized and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "hammer.fill",
            task: "Work on my software engineering assignment — draw UML class and sequence diagrams, apply design patterns to a system design, write software requirements specifications, or analyze a software architecture against SOLID principles",
            successCriteria: "Software engineering assignment completed (UML diagrams, design pattern application, requirements specification, or architecture analysis completed with design rationale, pattern roles labeled, and all diagrams saved to file)",
            preferredDuration: 45 * 60
        ),
        // humancomputerinteraction
        SuggestedTemplate(
            icon: "hand.tap.fill",
            task: "Study human-computer interaction for my exam — review usability heuristics, cognitive walkthroughs, think-aloud protocols, affinity diagrams, Fitts's law, mental models, user-centered design, and accessibility guidelines",
            successCriteria: "HCI study session completed (at least two topics reviewed with Nielsen heuristics listed, cognitive walkthrough steps explained, Fitts's law formula, and UCD process stages summarized and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "hand.tap.fill",
            task: "Work on my HCI assignment — conduct a heuristic evaluation, plan or analyze a think-aloud usability study, build an affinity diagram from user research data, or apply cognitive walkthrough to a prototype",
            successCriteria: "HCI assignment completed (heuristic evaluation, usability study plan, affinity diagram, or cognitive walkthrough completed with findings documented, severity ratings assigned, and results saved to file)",
            preferredDuration: 45 * 60
        ),
        // machinelearning
        SuggestedTemplate(
            icon: "brain.head.profile",
            task: "Study machine learning for my exam — review supervised and unsupervised learning, gradient descent, linear and logistic regression, SVMs, decision trees, random forests, bias-variance tradeoff, regularization, and cross-validation",
            successCriteria: "Machine learning study session completed (at least two algorithms reviewed with cost function derivations, update rules, geometric intuitions, and cross-validation procedures summarized and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "brain.head.profile",
            task: "Work on my machine learning assignment — implement a classifier or regressor from scratch, tune hyperparameters with cross-validation, analyze bias-variance tradeoff, or apply regularization and evaluate model performance",
            successCriteria: "Machine learning assignment completed (classifier/regressor implementation, hyperparameter tuning, bias-variance analysis, or regularization experiment completed with training/validation curves, metrics, and code saved to file)",
            preferredDuration: 60 * 60
        ),
        // distributedsystems
        SuggestedTemplate(
            icon: "network.badge.shield.half.filled",
            task: "Study distributed systems for my exam — review consensus protocols (Paxos, Raft), the CAP theorem, fault tolerance, replication strategies, eventual consistency, distributed transactions, leader election, and Byzantine fault tolerance",
            successCriteria: "Distributed systems study session completed (at least two topics reviewed with Paxos/Raft protocol phases, CAP theorem proof sketch, replication strategies, and 2PC/3PC steps summarized and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "network.badge.shield.half.filled",
            task: "Work on my distributed systems assignment — implement a Raft leader election, simulate a Byzantine fault scenario, analyze CAP theorem tradeoffs for a given system, or design a replication and consistency strategy",
            successCriteria: "Distributed systems assignment completed (Raft implementation, Byzantine fault simulation, CAP analysis, or replication design completed with correctness arguments, failure scenarios handled, and solution saved to file)",
            preferredDuration: 60 * 60
        ),
        // computersecurity
        SuggestedTemplate(
            icon: "lock.shield.fill",
            task: "Study computer security for my exam — review buffer overflows and stack smashing, return-oriented programming, memory safety techniques, software vulnerability classes, secure coding practices, access control models, and authentication mechanisms",
            successCriteria: "Computer security study session completed (at least two vulnerability classes reviewed with attack mechanics, memory layout diagrams, mitigation techniques like ASLR/stack canaries/DEP, and secure coding countermeasures summarized and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "lock.shield.fill",
            task: "Work on my computer security assignment — analyze a buffer overflow exploit, implement a secure coding fix, perform a software vulnerability analysis, apply access control policies, or assess authentication mechanism weaknesses",
            successCriteria: "Computer security assignment completed (exploit analysis, secure coding fix, vulnerability assessment, access control policy, or authentication analysis completed with attack steps, root cause, mitigation applied, and solution saved to file)",
            preferredDuration: 45 * 60
        ),
        // programminglanguages
        SuggestedTemplate(
            icon: "character.cursor.ibeam",
            task: "Study programming languages theory for my exam — review type systems and type inference, lambda calculus and reduction rules, operational and denotational semantics, formal grammars, programming paradigms (functional, logic, imperative), and language design principles",
            successCriteria: "PL theory study session completed (at least two topics reviewed with type derivation trees, lambda calculus reduction examples, operational semantics rules, and formal grammar productions summarized and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "character.cursor.ibeam",
            task: "Work on my programming languages assignment — derive types using inference rules, reduce lambda calculus expressions, construct formal semantics for a small language, prove type safety properties, or implement an interpreter for a given language specification",
            successCriteria: "PL assignment completed (type derivation, lambda calculus reduction, formal semantics construction, type safety proof, or interpreter implementation completed with derivation trees, reduction sequences, and solution saved to file)",
            preferredDuration: 60 * 60
        ),
        // compilerdesign
        SuggestedTemplate(
            icon: "chevron.left.forwardslash.chevron.right",
            task: "Study compiler design for my exam — review lexical analysis and tokenization, top-down and bottom-up parsing, abstract syntax tree construction, semantic analysis, intermediate representations, code generation, register allocation, and compiler optimization passes",
            successCriteria: "Compilers study session completed (at least two phases reviewed with lexer rules, parsing table construction, AST examples, IR generation steps, and register allocation strategy summarized and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "chevron.left.forwardslash.chevron.right",
            task: "Work on my compiler design assignment — implement a lexer or parser for a given grammar, build an AST from parse output, generate intermediate representation code, apply dataflow analysis, or implement a register allocator or optimization pass",
            successCriteria: "Compilers assignment completed (lexer/parser implementation, AST construction, IR generation, dataflow analysis, or register allocation completed with grammar rules satisfied, test cases passing, and solution saved to file)",
            preferredDuration: 60 * 60
        ),
        // computergraphics
        SuggestedTemplate(
            icon: "cube.transparent",
            task: "Study computer graphics for my exam — review the rendering pipeline, rasterization and ray tracing algorithms, 3D transformations and homogeneous coordinates, shading models (Phong, Blinn-Phong), texture mapping, clipping algorithms, and global illumination",
            successCriteria: "Computer graphics study session completed (at least two topics reviewed with pipeline stage diagrams, ray-triangle intersection derivation, transformation matrix derivations, shading model equations, and clipping algorithm steps summarized and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "cube.transparent",
            task: "Work on my computer graphics assignment — implement a ray tracer with reflection and refraction, write vertex and fragment shaders in GLSL, apply 3D transformation matrices to a scene, implement texture mapping, or build a rasterizer for a set of triangles",
            successCriteria: "Computer graphics assignment completed (ray tracer, shader implementation, transformation pipeline, texture mapping, or rasterizer completed with rendered output saved, transformation matrices verified, and code saved to file)",
            preferredDuration: 60 * 60
        ),
        // embeddedsystems
        SuggestedTemplate(
            icon: "cpu",
            task: "Study embedded systems for my exam — review microcontroller architecture, interrupt handling and ISRs, RTOS scheduling (preemptive, round-robin, priority-based), memory-mapped I/O, device drivers, communication protocols (SPI, I2C, UART), and real-time constraints",
            successCriteria: "Embedded systems study session completed (at least two topics reviewed with ISR entry/exit sequence, RTOS scheduling algorithm diagrams, memory map layout, communication protocol timing diagrams, and real-time deadline analysis summarized and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "cpu",
            task: "Work on my embedded systems assignment — implement an interrupt-driven device driver, configure an RTOS task scheduler, write bare-metal firmware for a microcontroller peripheral, implement SPI or I2C communication, or analyze real-time scheduling feasibility",
            successCriteria: "Embedded systems assignment completed (ISR implementation, RTOS task setup, peripheral firmware, communication protocol driver, or scheduling analysis completed with timing verified, hardware interaction confirmed, and solution saved to file)",
            preferredDuration: 60 * 60
        ),
        // formalverification
        SuggestedTemplate(
            icon: "checkmark.seal.fill",
            task: "Study formal verification for my exam — review Hoare logic and Hoare triples, weakest precondition calculus, temporal logic (LTL and CTL), model checking algorithms, theorem proving techniques, and the use of proof assistants like Coq or Isabelle",
            successCriteria: "Formal verification study session completed (at least two topics reviewed with Hoare triple examples, wp-calculus derivations, LTL/CTL formula translations, model checking algorithm steps, and at least one Coq or Isabelle proof sketch summarized and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "checkmark.seal.fill",
            task: "Work on my formal verification assignment — prove program correctness using Hoare logic, derive weakest preconditions for a program, write LTL or CTL specifications for a system, run model checking on a finite-state model, or construct a machine-checked proof in Coq or Isabelle",
            successCriteria: "Formal verification assignment completed (Hoare logic proof, wp derivation, temporal logic specification, model checking run, or proof assistant proof completed with all proof obligations discharged, counterexamples ruled out, and solution saved to file)",
            preferredDuration: 60 * 60
        ),
        // computationtheory
        SuggestedTemplate(
            icon: "cpu.fill",
            task: "Study theory of computation for my exam — review DFA/NFA construction and equivalence, pushdown automata and context-free grammars, Turing machines and decidability, the halting problem, P vs NP, NP-completeness and polynomial reductions",
            successCriteria: "Theory of computation study session completed (at least two topics reviewed with DFA/NFA state diagrams, CFL pumping lemma examples, Turing machine transitions, decidability proofs, and NP-completeness reduction sketches summarized and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "cpu.fill",
            task: "Work on my theory of computation assignment — construct a DFA or NFA for a regular language, convert NFA to DFA, design a pushdown automaton for a context-free language, write a Turing machine for a decidable language, or prove NP-completeness via polynomial reduction",
            successCriteria: "Theory of computation assignment completed (DFA/NFA construction, NFA→DFA conversion, PDA design, Turing machine description, or NP-completeness reduction completed with formal definitions, state transition tables, and solution saved to file)",
            preferredDuration: 60 * 60
        ),
        // softwarearchitecture
        SuggestedTemplate(
            icon: "building.columns",
            task: "Study software architecture for my exam — review architectural patterns (layered, microservices, event-driven, hexagonal, clean), domain-driven design, CQRS, event sourcing, system design trade-offs, and quality attributes (scalability, reliability, maintainability)",
            successCriteria: "Software architecture study session completed (at least two patterns reviewed with context diagrams, trade-off analysis, DDD building blocks, CQRS command/query separation, and quality attribute scenarios summarized and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "building.columns",
            task: "Work on my software architecture assignment — design a system using a specified architectural pattern, apply domain-driven design to a bounded context, model a CQRS or event-sourced system, evaluate trade-offs between architectural options, or document an architecture decision record",
            successCriteria: "Software architecture assignment completed (architecture diagram, DDD context map, CQRS model, trade-off analysis, or ADR completed with component responsibilities, inter-component interfaces, and design rationale documented and saved)",
            preferredDuration: 60 * 60
        ),
        // informationretrieval
        SuggestedTemplate(
            icon: "magnifyingglass.circle",
            task: "Study information retrieval for my exam — review Boolean and vector space retrieval models, TF-IDF weighting, BM25 ranking, inverted index construction, query expansion, relevance feedback, evaluation metrics (precision, recall, nDCG), and web crawling",
            successCriteria: "Information retrieval study session completed (at least two topics reviewed with TF-IDF derivations, BM25 formula, inverted index posting lists, precision/recall curves, and nDCG calculation examples summarized and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "magnifyingglass.circle",
            task: "Work on my information retrieval assignment — implement a TF-IDF retrieval system, build an inverted index over a document collection, apply BM25 ranking, compute precision/recall/nDCG for a query set, or implement query expansion with relevance feedback",
            successCriteria: "Information retrieval assignment completed (TF-IDF system, inverted index, BM25 ranker, evaluation metric computation, or query expansion completed with ranked result lists, evaluation scores computed, and solution saved to file)",
            preferredDuration: 60 * 60
        ),
        // naturallanguageprocessing
        SuggestedTemplate(
            icon: "text.bubble",
            task: "Study natural language processing for my exam — review tokenization and text normalization, n-gram language models, part-of-speech tagging, named entity recognition, dependency parsing, word embeddings (Word2Vec, GloVe), transformer architectures, and sequence-to-sequence models",
            successCriteria: "NLP study session completed (at least two topics reviewed with tokenization examples, n-gram probability derivations, POS tagging algorithms, NER sequence labeling, and transformer attention mechanism summarized and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "text.bubble",
            task: "Work on my NLP assignment — implement a text classifier, build an n-gram language model, apply a POS tagger or NER model, train word embeddings, implement a dependency parser, or analyze a transformer model's attention patterns on a text dataset",
            successCriteria: "NLP assignment completed (text classifier, language model, POS tagger, NER implementation, word embedding training, or attention analysis completed with evaluation metrics reported, examples demonstrated, and solution saved to file)",
            preferredDuration: 60 * 60
        ),
        // computerarchitecture
        SuggestedTemplate(
            icon: "memorychip",
            task: "Study computer architecture for my exam — review the instruction pipeline stages (fetch, decode, execute, memory, write-back), hazard detection, branch prediction, out-of-order execution, cache hierarchy and coherence protocols, memory hierarchy, and RISC vs CISC design principles",
            successCriteria: "Computer architecture study session completed (at least two topics reviewed with pipeline diagrams, hazard detection logic, branch predictor designs, cache coherence protocol states, and memory hierarchy latency tables summarized and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "memorychip",
            task: "Work on my computer architecture assignment — analyze pipeline hazards in a given instruction sequence, simulate a branch predictor, calculate cache hit rates for a given access pattern, design a cache coherence protocol state machine, or evaluate out-of-order execution on a trace",
            successCriteria: "Computer architecture assignment completed (hazard analysis, branch predictor simulation, cache hit rate calculation, coherence protocol design, or OOO execution evaluation completed with data path diagrams, timing analysis, and solution saved to file)",
            preferredDuration: 60 * 60
        ),
        // photonics
        SuggestedTemplate(
            icon: "laser.burst",
            task: "Study photonics for my exam — review fiber optic waveguide modes and attenuation, laser physics (rate equations, threshold condition, gain media), nonlinear optical effects (SPM, XPM, FWM), optical amplifiers (EDFA), integrated photonics building blocks, and photonic crystal band gaps",
            successCriteria: "Photonics study session completed (at least two topics reviewed with waveguide mode diagrams, laser rate equation derivations, nonlinear coefficient calculations, EDFA gain curve, and photonic crystal dispersion relation summarized and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "laser.burst",
            task: "Work on my photonics assignment — design a single-mode fiber optic link (loss budget, dispersion budget), analyze laser threshold and slope efficiency, compute nonlinear phase accumulation in a fiber, design a Mach-Zehnder modulator, or simulate a photonic crystal waveguide",
            successCriteria: "Photonics assignment completed (fiber link design, laser threshold analysis, nonlinear phase calculation, modulator design, or photonic crystal simulation completed with device parameters, signal budget calculations, and solution saved to file)",
            preferredDuration: 60 * 60
        ),
        // acousticsengineering
        SuggestedTemplate(
            icon: "waveform",
            task: "Study acoustics engineering for my exam — review sound wave propagation (wave equation, impedance, reflection/transmission), room acoustics (reverberation time, Sabine's formula, modal analysis), psychoacoustics (equal-loudness contours, masking), noise control (transmission loss, barriers, absorption), and vibration analysis",
            successCriteria: "Acoustics engineering study session completed (at least two topics reviewed with wave impedance derivations, RT60 calculations, loudness contour examples, transmission loss measurements, and vibration mode shapes summarized and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "waveform",
            task: "Work on my acoustics engineering assignment — calculate room reverberation time using Sabine's and Eyring's formulas, design a noise barrier for a given insertion loss target, analyze vibration modes of a structure, compute acoustic impedance mismatch at an interface, or design an anechoic treatment",
            successCriteria: "Acoustics engineering assignment completed (RT60 calculation, barrier design, vibration mode analysis, impedance computation, or anechoic treatment design completed with material absorption coefficients, insertion loss curves, and solution saved to file)",
            preferredDuration: 60 * 60
        ),
        // petroleumengineering
        SuggestedTemplate(
            icon: "cylinder.fill",
            task: "Study petroleum engineering for my exam — review reservoir fluid properties (PVT, equation of state), Darcy's law and reservoir flow regimes, well logging (gamma ray, resistivity, neutron-density), petrophysics (porosity, permeability, water saturation), material balance equations, and enhanced oil recovery methods",
            successCriteria: "Petroleum engineering study session completed (at least two topics reviewed with Darcy flow derivations, log interpretation charts, material balance calculations, EOR mechanism descriptions, and reservoir property tables summarized and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "cylinder.fill",
            task: "Work on my petroleum engineering assignment — interpret a suite of well logs to determine porosity and water saturation, solve a material balance problem for oil recovery factor, design a hydraulic fracturing program, calculate inflow performance relationships (IPR), or run a reservoir simulation case",
            successCriteria: "Petroleum engineering assignment completed (log interpretation, material balance solution, fracture design, IPR calculation, or simulation case completed with petrophysical cross-plots, recovery factor curves, and solution saved to file)",
            preferredDuration: 60 * 60
        ),
        // sportspsychology
        SuggestedTemplate(
            icon: "figure.mind.and.body",
            task: "Study sports psychology for my exam — review mental skills training frameworks (goal setting, imagery, self-talk, arousal regulation), flow state theory, pre-competition anxiety models (catastrophe theory, IZOF), attention and concentration, confidence and self-efficacy in sport, and coach-athlete communication",
            successCriteria: "Sports psychology study session completed (at least two topics reviewed with goal-setting SMART criteria, imagery script examples, anxiety-performance models, flow channel diagram, and self-efficacy sources summarized and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "figure.mind.and.body",
            task: "Work on my sports psychology assignment — design a mental skills training program for an athlete, write a psychological skills inventory case analysis, apply arousal regulation techniques to a competition scenario, analyze a case study using IZOF theory, or develop a pre-competition routine using imagery and self-talk",
            successCriteria: "Sports psychology assignment completed (mental skills program, case analysis, arousal regulation plan, IZOF application, or pre-competition routine completed with psychological theory citations, intervention rationale, and solution saved to file)",
            preferredDuration: 60 * 60
        ),
        // limnology
        SuggestedTemplate(
            icon: "drop.fill",
            task: "Study limnology for my exam — review lake thermal stratification and turnover, phosphorus and nitrogen cycling (Redfield ratio, eutrophication mechanisms), primary productivity measurement, benthic macroinvertebrate communities as bioassessment indicators, dissolved oxygen dynamics, and watershed hydrology inputs",
            successCriteria: "Limnology study session completed (at least two topics reviewed with thermal profile diagrams, nutrient cycle flowcharts, P-E curve examples, benthic tolerance indices, DO deficit calculations, and watershed water balance summarized and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "drop.fill",
            task: "Work on my limnology assignment — analyze a lake thermal profile to identify epilimnion, metalimnion, and hypolimnion, calculate phosphorus loading and trophic state index, identify benthic macroinvertebrate assemblages from a sample to assess water quality, compute dissolved oxygen saturation, or model nutrient retention in a watershed",
            successCriteria: "Limnology assignment completed (thermal profile analysis, trophic state calculation, macroinvertebrate identification, DO saturation computation, or nutrient retention model completed with field data tables, trophic classification, and solution saved to file)",
            preferredDuration: 60 * 60
        ),
        // astrodynamics
        SuggestedTemplate(
            icon: "moon.stars.fill",
            task: "Study astrodynamics for my exam — review Keplerian orbit elements and two-body problem solutions, vis-viva equation and orbital energy, Hohmann transfer orbits and delta-v budgeting, Lambert's problem and orbit determination, ground track analysis, and spacecraft navigation fundamentals",
            successCriteria: "Astrodynamics study session completed (at least two topics reviewed with orbit element tables, vis-viva derivations, Hohmann transfer delta-v calculations, Lambert arc diagrams, and ground track sketches summarized and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "moon.stars.fill",
            task: "Work on my astrodynamics problem set — solve a two-body orbit determination problem, calculate delta-v for a Hohmann transfer or plane change, compute orbit elements from position/velocity vectors, solve Lambert's problem for a rendezvous, or design a multi-burn trajectory",
            successCriteria: "Astrodynamics problem set completed (orbit determination, delta-v calculation, orbit element conversion, Lambert solution, or trajectory design completed with state vector tables, transfer diagrams, and solution saved to file)",
            preferredDuration: 60 * 60
        ),
        // biomaterials
        SuggestedTemplate(
            icon: "cross.case.fill",
            task: "Study biomaterials for my exam — review biocompatibility criteria and ISO standards, implant material classes (metals, ceramics, polymers, composites), surface functionalization and cell-material interactions, biodegradable polymers for scaffold design, osseointegration mechanisms, and corrosion and wear of implant alloys",
            successCriteria: "Biomaterials study session completed (at least two topics reviewed with biocompatibility test flowchart, material property comparison table, surface modification schemes, scaffold design criteria, osseointegration diagram, and corrosion mechanism summary saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "cross.case.fill",
            task: "Work on my biomaterials assignment — evaluate a biomaterial for biocompatibility and mechanical match to tissue, design a scaffold with target porosity and degradation rate, analyze corrosion behavior of an implant alloy, assess surface modification strategies for a titanium implant, or complete a case study on a failed medical device",
            successCriteria: "Biomaterials assignment completed (biocompatibility evaluation, scaffold design, corrosion analysis, surface modification plan, or device failure case study completed with material property data, design rationale, and solution saved to file)",
            preferredDuration: 60 * 60
        ),
        // crystallography
        SuggestedTemplate(
            icon: "diamond.fill",
            task: "Study crystallography for my exam — review crystal lattice types and Bravais lattices, Miller indices and crystallographic directions, Bragg's law and X-ray diffraction geometry, systematic absences and space groups, powder diffraction pattern indexing, and reciprocal lattice construction",
            successCriteria: "Crystallography study session completed (at least two topics reviewed with lattice parameter diagrams, Miller index calculations, Bragg equation derivations, space group symmetry element lists, powder pattern indexing steps, and reciprocal lattice construction summarized and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "diamond.fill",
            task: "Work on my crystallography assignment — index a powder X-ray diffraction pattern to determine lattice parameters, calculate d-spacings using Bragg's law, assign Miller indices to crystal planes, identify systematic absences to determine space group, or solve a crystal structure problem from diffraction data",
            successCriteria: "Crystallography assignment completed (powder pattern indexing, d-spacing calculation, Miller index assignment, space group determination, or structure solution completed with diffraction data table, lattice parameter values, and solution saved to file)",
            preferredDuration: 60 * 60
        ),
        // spectroscopy
        SuggestedTemplate(
            icon: "waveform",
            task: "Study spectroscopy for my exam — review NMR spectroscopy (chemical shift, coupling constants, splitting patterns, COSY/HMBC correlation), IR spectroscopy (functional group absorptions), mass spectrometry (fragmentation patterns, molecular ion, base peak), UV-Vis spectroscopy (chromophores, Beer-Lambert law), and Raman spectroscopy fundamentals",
            successCriteria: "Spectroscopy study session completed (at least two techniques reviewed with NMR shift table, IR absorption correlation chart, mass spec fragmentation mechanism examples, UV-Vis chromophore structures, and Beer-Lambert calculations summarized and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "waveform",
            task: "Work on my spectroscopy assignment — interpret a 1H NMR spectrum to determine a molecular structure, identify functional groups from an IR spectrum, determine molecular formula and structure from a mass spectrum, calculate unknown concentration from UV-Vis absorbance, or solve a multi-spectral structure elucidation problem",
            successCriteria: "Spectroscopy assignment completed (NMR interpretation, IR functional group identification, mass spectrum analysis, UV-Vis concentration calculation, or structure elucidation completed with spectral annotations, structural assignment rationale, and solution saved to file)",
            preferredDuration: 60 * 60
        ),
        // industrialengineering
        SuggestedTemplate(
            icon: "chart.bar.doc.horizontal",
            task: "Study industrial engineering for my exam — review operations research methods (linear programming, simplex method, transportation model), queueing theory (M/M/1, M/M/c models), facilities layout and material handling, work measurement and time study, lean manufacturing and six sigma principles, and reliability engineering",
            successCriteria: "Industrial engineering study session completed (at least two topics reviewed with LP formulation and simplex tableau, M/M/1 performance metric derivations, facilities layout diagrams, time study calculations, lean/six-sigma tool summaries, and reliability block diagram summarized and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "chart.bar.doc.horizontal",
            task: "Work on my industrial engineering assignment — formulate and solve a linear programming problem, analyze a queueing system using M/M/1 or M/M/c model, design a facilities layout using systematic layout planning, conduct a time study and compute standard time, apply lean tools (value stream mapping, 5S) to a process, or perform a reliability block diagram analysis",
            successCriteria: "Industrial engineering assignment completed (LP solution, queueing analysis, facilities layout, time study, lean analysis, or reliability analysis completed with formulation tables, sensitivity analysis, layout diagram, and solution saved to file)",
            preferredDuration: 60 * 60
        ),
        // psycholinguistics
        SuggestedTemplate(
            icon: "brain.head.profile",
            task: "Study psycholinguistics for my exam — review sentence processing models (serial vs. parallel, garden-path theory), mental lexicon organization and lexical access, language acquisition theories (nativist, connectionist, usage-based), speech perception and word recognition, syntactic parsing strategies, reading comprehension models, and ERP components for language (N400, P600)",
            successCriteria: "Psycholinguistics study session completed (at least two topics reviewed with sentence processing diagram, lexical access model sketches, acquisition theory comparison table, ERP waveform descriptions, parsing strategy examples, and reading comprehension model summarized and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "brain.head.profile",
            task: "Work on my psycholinguistics assignment — analyze a garden-path sentence and explain the reanalysis cost, design a priming experiment to test lexical access, evaluate competing language acquisition theories using empirical evidence, interpret ERP data from a language processing study, or write a critical review of a classic psycholinguistics paper",
            successCriteria: "Psycholinguistics assignment completed (garden-path analysis, priming experiment design, acquisition theory evaluation, ERP interpretation, or paper review completed with theoretical rationale, empirical support, and solution saved to file)",
            preferredDuration: 60 * 60
        ),
        // photogrammetry
        SuggestedTemplate(
            icon: "camera.aperture",
            task: "Study photogrammetry for my exam — review image geometry and collinearity equations, camera calibration and lens distortion, structure from motion (SfM) pipeline and bundle adjustment, stereophotogrammetry and epipolar geometry, LiDAR point cloud processing and classification, orthorectification and digital elevation model generation, and UAV/drone mapping workflows",
            successCriteria: "Photogrammetry study session completed (at least two topics reviewed with collinearity equation derivations, camera calibration diagrams, SfM workflow summary, epipolar geometry sketches, point cloud processing steps, DEM generation procedure, and UAV flight planning summarized and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "camera.aperture",
            task: "Work on my photogrammetry assignment — process a set of drone images using SfM to generate a point cloud and orthophoto, calibrate a camera model and correct for lens distortion, perform bundle adjustment on a photogrammetric network, classify a LiDAR point cloud into ground/vegetation/building returns, or compute a digital elevation model and extract contours",
            successCriteria: "Photogrammetry assignment completed (SfM processing, camera calibration, bundle adjustment, point cloud classification, or DEM extraction completed with accuracy assessment, error statistics, output files, and solution report saved to file)",
            preferredDuration: 60 * 60
        ),
        // tectonics
        SuggestedTemplate(
            icon: "globe.americas.fill",
            task: "Study tectonics for my exam — review plate boundary types (convergent, divergent, transform) and associated processes, subduction zone mechanics and arc volcanism, continental drift and paleomagnetism evidence, isostasy and flexural rigidity, mantle convection and driving forces, fault mechanics (Anderson's theory, Byerlee's law), and tectonic geomorphology",
            successCriteria: "Tectonics study session completed (at least two topics reviewed with plate boundary diagrams, subduction cross-sections, paleomagnetic reversal timescale, isostasy derivation, convection cell sketches, fault stress diagrams, and tectonic geomorphology examples summarized and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "globe.americas.fill",
            task: "Work on my tectonics assignment — reconstruct past plate positions using paleomagnetism and hot spot tracks, analyze a focal mechanism solution to determine fault type and slip direction, calculate convergence rates from GPS data and magnetic anomalies, evaluate isostatic rebound following deglaciation, or interpret a geologic cross-section showing fold-and-thrust belt geometry",
            successCriteria: "Tectonics assignment completed (plate reconstruction, focal mechanism analysis, convergence rate calculation, isostatic rebound evaluation, or cross-section interpretation completed with maps/diagrams, velocity vectors, and solution saved to file)",
            preferredDuration: 60 * 60
        ),
        // tribology
        SuggestedTemplate(
            icon: "gearshape.2.fill",
            task: "Study tribology for my exam — review friction laws (Amontons, Coulomb), adhesion and ploughing components of friction, Archard wear equation and wear mechanisms (adhesive, abrasive, fatigue, corrosive), Hertzian contact mechanics and stress distributions, hydrodynamic and elastohydrodynamic lubrication theory (Reynolds equation, Stribeck curve), and surface roughness characterization",
            successCriteria: "Tribology study session completed (at least two topics reviewed with friction law derivations, wear mechanism diagrams, Archard equation application, Hertz contact stress calculations, Stribeck curve annotations, Reynolds equation summary, and surface roughness parameter table saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "gearshape.2.fill",
            task: "Work on my tribology assignment — calculate Hertzian contact stress and deformation for a sphere-on-flat geometry, apply the Archard wear equation to predict wear volume, analyze a Stribeck curve to identify lubrication regimes, solve a Reynolds equation problem for journal bearing pressure distribution, or select materials and coatings to minimize wear in a given tribological contact",
            successCriteria: "Tribology assignment completed (contact stress calculation, wear volume prediction, Stribeck curve analysis, bearing pressure distribution, or material selection completed with numerical results, diagrams, design rationale, and solution saved to file)",
            preferredDuration: 60 * 60
        ),
        // radiochemistry
        SuggestedTemplate(
            icon: "atom",
            task: "Study radiochemistry for my exam — review radioactive decay laws and decay chains, radiocarbon and other isotope dating techniques (K-Ar, U-Pb, Rb-Sr), radioactive tracer principles and applications in biochemistry and environmental science, radiolabeling methods (synthesis, purification, quality control), radiation chemistry (radiolysis, free radical formation), and gamma/alpha/beta spectroscopy",
            successCriteria: "Radiochemistry study session completed (at least two topics reviewed with decay law derivations, dating method comparison table, tracer experiment design examples, radiolabeling synthesis schemes, radiolysis mechanism, and spectroscopy energy range summary saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "atom",
            task: "Work on my radiochemistry assignment — calculate the age of a sample using radiocarbon or K-Ar dating, design a radioactive tracer experiment to track a metabolic pathway, solve decay chain equations for ingrowth of a daughter nuclide, analyze a gamma spectrum to identify unknown radionuclides and calculate activity, or evaluate radiolabeling yield and radiochemical purity",
            successCriteria: "Radiochemistry assignment completed (isotope dating calculation, tracer experiment design, decay chain solution, gamma spectrum analysis, or radiolabeling evaluation completed with numerical results, decay diagrams, spectral annotations, and solution saved to file)",
            preferredDuration: 60 * 60
        ),
        // signalprocessing
        SuggestedTemplate(
            icon: "waveform",
            task: "Study signal processing for my exam — review Fourier transforms, Z-transforms, FIR/IIR filter design, sampling theorem, Nyquist criterion, convolution, and LTI system analysis",
            successCriteria: "Signal processing study session completed (at least two topics reviewed with Fourier/Z-transform derivations, filter design steps, sampling theorem explanation, convolution examples, and key formulas saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "waveform",
            task: "Complete my DSP assignment — work through signal processing problems involving FFT computation, FIR or IIR filter design, spectral analysis, or LTI system response",
            successCriteria: "DSP assignment completed (FFT computed or filter designed, frequency response plotted, system analysis documented, and results verified with at least two problems solved and saved)",
            preferredDuration: 60 * 60
        ),
        // controlengineering
        SuggestedTemplate(
            icon: "slider.horizontal.3",
            task: "Study control engineering for my exam — review PID controllers, transfer functions, root locus, Bode plots, Nyquist stability criterion, and state-space representation",
            successCriteria: "Control engineering study session completed (at least two topics reviewed with transfer function derivations, root locus sketches, Bode plot annotations, PID tuning rules, and stability criteria summarized and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "slider.horizontal.3",
            task: "Complete my control systems assignment — design a feedback controller, analyze closed-loop stability, sketch a root locus or Bode plot, or model a dynamic system in state-space",
            successCriteria: "Control systems assignment completed (controller designed or stability analyzed, root locus or Bode plot drawn, gain and phase margins computed, and results documented with at least two problems solved and saved)",
            preferredDuration: 60 * 60
        ),
        // aerostructures
        SuggestedTemplate(
            icon: "airplane",
            task: "Study aerostructures for my exam — review shear flow in thin-walled sections, monocoque and semi-monocoque structures, composite airframe analysis, buckling of panels, and aeroelasticity concepts",
            successCriteria: "Aerostructures study session completed (at least two topics reviewed with shear flow calculations, buckling load derivations, monocoque structure diagrams, composite layup analysis, and aeroelastic flutter summary saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "airplane",
            task: "Complete my aircraft structures assignment — compute shear flows in a thin-walled section, analyze buckling of a stiffened panel, evaluate a composite airframe layup, or assess fatigue life of an aircraft component",
            successCriteria: "Aerostructures assignment completed (shear flow computed, buckling load calculated, composite layup evaluated, or fatigue life estimated with numerical results, structural diagrams, and solution saved to file)",
            preferredDuration: 60 * 60
        ),
        // optogenetics
        SuggestedTemplate(
            icon: "flashlight.on.fill",
            task: "Study optogenetics for my exam — review channelrhodopsin and halorhodopsin mechanisms, viral vector delivery strategies, fiber-optic brain stimulation, opsin expression verification, and neural circuit dissection methods",
            successCriteria: "Optogenetics study session completed (at least two topics reviewed with opsin photocycle diagrams, viral vector serotype comparison, fiber-optic implant schematic, behavioral paradigm examples, and key experimental controls summarized and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "flashlight.on.fill",
            task: "Write my optogenetics lab report — describe opsin selection and viral vector delivery, analyze light-stimulation data, quantify opsin expression from histology, and interpret neural circuit findings",
            successCriteria: "Optogenetics lab report completed (methods section written with opsin choice rationale and vector details, stimulation data analyzed and plotted, expression quantified from images, and circuit-level interpretation of behavioral results saved)",
            preferredDuration: 60 * 60
        ),
        // demography
        SuggestedTemplate(
            icon: "person.3.fill",
            task: "Study demography for my exam — review the demographic transition model, life tables, age pyramids, total fertility rate, net reproduction rate, migration analysis, and population growth models",
            successCriteria: "Demography study session completed (at least two topics reviewed with demographic transition stage diagrams, life table construction steps, age pyramid interpretation, fertility and mortality rate formulas, and population model comparisons saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "person.3.fill",
            task: "Complete my demography assignment — construct or analyze a life table, build an age pyramid from census data, compute demographic rates (TFR, NRR, IMR), or model population growth with a cohort-component projection",
            successCriteria: "Demography assignment completed (life table or age pyramid constructed, demographic rates computed, population projection modeled, and written analysis explaining trends and policy implications saved to file)",
            preferredDuration: 60 * 60
        ),
        // compositematerials
        SuggestedTemplate(
            icon: "square.stack.3d.up.fill",
            task: "Study composite materials for my exam — review fiber-reinforced polymer types and manufacturing, classical lamination theory, laminate stiffness and compliance matrices, failure criteria (Tsai-Wu, Tsai-Hill, Hashin), micromechanics, and fatigue behavior of composites",
            successCriteria: "Composite materials study session completed (at least two topics reviewed with CLT derivation steps, laminate stiffness ABD matrix setup, failure envelope diagrams, micromechanics equations, and worked examples saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "square.stack.3d.up.fill",
            task: "Complete my composite materials assignment — apply classical lamination theory to compute laminate stiffness, perform a failure analysis using Tsai-Wu or Hashin criteria, analyze a filament-wound pressure vessel, or characterize composite fatigue response",
            successCriteria: "Composite materials assignment completed (ABD matrix computed, failure analysis performed with margin of safety, pressure vessel or fatigue analysis results tabulated, and written explanation of failure mode and design implications saved to file)",
            preferredDuration: 60 * 60
        ),
        // powerelectronics
        SuggestedTemplate(
            icon: "bolt.fill",
            task: "Study power electronics for my exam — review DC-DC converter topologies (buck, boost, buck-boost), PWM control principles, inductor and capacitor sizing, converter efficiency, inverter modulation strategies, and rectifier circuits",
            successCriteria: "Power electronics study session completed (at least two converter topologies reviewed with switching waveforms, steady-state voltage conversion ratio derivations, inductor ripple current calculations, and worked design examples saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "bolt.fill",
            task: "Complete my power electronics assignment — design a buck or boost DC-DC converter (duty cycle, inductor, capacitor sizing), analyze a PWM switching circuit, evaluate converter efficiency, or simulate an inverter modulation scheme",
            successCriteria: "Power electronics assignment completed (converter designed with component values calculated, switching waveforms analyzed, efficiency computed, and written design rationale with circuit schematic saved to file)",
            preferredDuration: 60 * 60
        ),
        // geotechnicalengineering
        SuggestedTemplate(
            icon: "mountain.2.fill",
            task: "Study geotechnical engineering for my exam — review soil classification (USCS/AASHTO), consolidation theory (Terzaghi), bearing capacity (Terzaghi, Meyerhof), slope stability (Bishop, Fellenius), lateral earth pressure (Rankine, Coulomb), and permeability",
            successCriteria: "Geotechnical engineering study session completed (at least two topics reviewed with soil classification charts, consolidation settlement equations, bearing capacity factor tables, slope stability analysis steps, and worked examples saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "mountain.2.fill",
            task: "Complete my geotechnical engineering assignment — analyze consolidation settlement, compute bearing capacity of a shallow or deep foundation, perform a slope stability analysis, design a retaining wall under lateral earth pressure, or interpret a triaxial or standard penetration test",
            successCriteria: "Geotechnical engineering assignment completed (consolidation, bearing capacity, or slope stability calculation performed with labeled soil profile, factor of safety computed, and written summary of design assumptions and results saved to file)",
            preferredDuration: 60 * 60
        ),
        // structuralanalysis
        SuggestedTemplate(
            icon: "building.columns.fill",
            task: "Study structural analysis for my exam — review shear force and bending moment diagrams, beam deflection formulas, method of sections and joints for trusses, influence lines, moment distribution method, slope-deflection equations, and the matrix stiffness method",
            successCriteria: "Structural analysis study session completed (at least two topics reviewed with free-body diagrams, SFD/BMD drawn for sample beams, truss analysis by sections, influence line construction, and worked examples of indeterminate structures saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "building.columns.fill",
            task: "Complete my structural analysis problem set — draw shear and bending moment diagrams, analyze a truss by method of sections or joints, compute beam deflection using virtual work or moment distribution, solve an indeterminate beam by slope-deflection method, or assemble and solve a frame stiffness matrix",
            successCriteria: "Structural analysis problem set completed (SFD/BMD drawn with labeled values, truss member forces computed, deflection or reaction calculated, and worked solutions with equilibrium checks and unit annotations saved to file)",
            preferredDuration: 60 * 60
        ),
        // miningengineering
        SuggestedTemplate(
            icon: "hammer.fill",
            task: "Study mining engineering for my exam — review mine planning principles, open pit and underground mining methods (room-and-pillar, longwall, block caving), rock mechanics (strength criteria, support design), ore processing (flotation, comminution, gravity separation), and mine ventilation",
            successCriteria: "Mining engineering study session completed (at least two topics reviewed with mine layout diagrams, rock mass classification tables, flotation circuit schematics, ventilation network concepts, and worked examples saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "hammer.fill",
            task: "Complete my mining engineering assignment — design a mine excavation sequence or blast pattern, analyze rock mechanics data (RMR, Q-system), perform an ore processing mass balance (flotation or comminution circuit), size a ventilation fan, or evaluate tailings storage facility design",
            successCriteria: "Mining engineering assignment completed (mine design, rock mass classification, mass balance, or ventilation calculation performed with labeled cross-sections or flow diagrams, key parameters computed, and written design rationale saved to file)",
            preferredDuration: 60 * 60
        ),
        // wastewatertreatment
        SuggestedTemplate(
            icon: "drop.fill",
            task: "Study wastewater treatment for my exam — review activated sludge process design, biological nutrient removal (nitrification, denitrification, EBPR), membrane bioreactor systems, primary and secondary treatment unit operations, sedimentation and clarifier design, anaerobic digestion, and disinfection",
            successCriteria: "Wastewater treatment study session completed (at least two unit processes reviewed with flow diagrams, mass balance equations, BOD/COD removal calculations, sludge production estimates, and worked WWTP design examples saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "drop.fill",
            task: "Complete my wastewater treatment assignment — design or analyze an activated sludge reactor (SRT, HRT, aeration requirements), perform a biological nutrient removal process calculation, size a clarifier or membrane bioreactor, model anaerobic digestion, or evaluate effluent quality against discharge limits",
            successCriteria: "Wastewater treatment assignment completed (reactor sizing, clarifier design, or BNR calculation performed with labeled process flow diagram, design parameters tabulated, effluent quality checked against standards, and written design justification saved to file)",
            preferredDuration: 60 * 60
        ),
        // airpollutioncontrol
        SuggestedTemplate(
            icon: "wind",
            task: "Study air pollution control for my exam — review particulate matter control (electrostatic precipitators, baghouse filters, cyclone separators), NOx and SOx control technologies (SCR, SNCR, wet and dry scrubbers, FGD), PM2.5 and PM10 emission standards, and air dispersion modeling",
            successCriteria: "Air pollution control study session completed (at least two control technologies reviewed with efficiency equations, pressure drop formulas, design sizing steps, emission limit comparisons, and worked examples saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "wind",
            task: "Complete my air pollution control assignment — design or size an electrostatic precipitator, baghouse filter, cyclone separator, or wet/dry scrubber; analyze SCR or FGD system performance; calculate collection efficiency and pressure drop; or evaluate compliance with PM2.5, NOx, or SOx emission standards",
            successCriteria: "Air pollution control assignment completed (control device designed with sizing equations and key parameters computed, collection efficiency calculated, compliance with emission standard evaluated, and written design rationale with schematic saved to file)",
            preferredDuration: 60 * 60
        ),
        // renewableenergy
        SuggestedTemplate(
            icon: "sun.max.fill",
            task: "Study renewable energy for my exam — review solar photovoltaic system design (I-V curves, MPPT, inverter sizing), wind turbine aerodynamics (Betz limit, power coefficient, wake effects), hydropower fundamentals, energy storage technologies, grid integration challenges, and LCOE analysis",
            successCriteria: "Renewable energy study session completed (at least two energy technologies reviewed with power output equations, capacity factor analysis, LCOE comparison, storage dispatch logic, and worked system design examples saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "sun.max.fill",
            task: "Complete my renewable energy assignment — size a solar PV array (panel count, inverter, battery storage), analyze wind turbine power output using Weibull distribution, calculate LCOE for a renewable project, evaluate grid integration and storage requirements, or compare life-cycle energy and cost for solar versus wind",
            successCriteria: "Renewable energy assignment completed (system sized or LCOE calculated with energy yield estimate, key assumptions stated, comparison table or sensitivity analysis included, and written design rationale with system diagram saved to file)",
            preferredDuration: 60 * 60
        ),
        // navalarchitecture
        SuggestedTemplate(
            icon: "ferry.fill",
            task: "Study naval architecture for my exam — review ship stability fundamentals (metacentric height, righting lever curves, IMO criteria), hull resistance and propulsion (Froude number, resistance components, propeller design), ship structures (loads, section modulus, frame spacing), trim analysis, and offshore structure design",
            successCriteria: "Naval architecture study session completed (at least two topics reviewed with stability curve diagrams, resistance prediction equations, hull form parameters, structural load calculations, and worked ship design examples saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "ferry.fill",
            task: "Complete my naval architecture assignment — analyze ship stability (GM, GZ curve, angle of vanishing stability), calculate hull resistance using empirical methods, design a propeller for a given speed and power, perform a trim and displacement calculation, or evaluate structural loads on a ship cross-section",
            successCriteria: "Naval architecture assignment completed (stability analysis, resistance calculation, or structural evaluation performed with labeled diagrams, key hydrostatic parameters tabulated, IMO criteria checked where applicable, and written design summary saved to file)",
            preferredDuration: 60 * 60
        ),
        // mechatronics
        SuggestedTemplate(
            icon: "gearshape.2.fill",
            task: "Study mechatronics for my exam — review sensors and actuators (encoders, resolvers, DC motors, stepper motors), PLC programming (ladder logic, function block, structured text), servo control systems (PID tuning, position and velocity loops), motion control, and hydraulic and pneumatic circuit design",
            successCriteria: "Mechatronics study session completed (at least two topics reviewed with sensor selection criteria, PLC ladder logic diagrams, PID controller design steps, motion profile calculations, and worked system integration examples saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "gearshape.2.fill",
            task: "Complete my mechatronics assignment — design a PLC ladder logic program for a control sequence, tune a PID servo controller (position or velocity loop), select sensors and actuators for a motion control application, model a hydraulic or pneumatic circuit, or analyze encoder feedback for a precision positioning system",
            successCriteria: "Mechatronics assignment completed (PLC program, PID tuning parameters, or circuit design produced with logic diagram or block diagram, performance analysis included, and written design rationale explaining component selection and control strategy saved to file)",
            preferredDuration: 60 * 60
        ),
        // structuraldynamics
        SuggestedTemplate(
            icon: "waveform.path",
            task: "Study structural dynamics for my exam — review free vibration of SDOF systems (natural frequency, damping ratio, logarithmic decrement), modal analysis and mode shapes of MDOF systems, forced vibration and frequency response, earthquake response spectra, Newmark-beta time integration, and Rayleigh damping",
            successCriteria: "Structural dynamics study session completed (at least two topics reviewed with free body diagrams, equations of motion, mode shape sketches, response spectrum curves, Newmark integration tables, and worked numerical examples saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "waveform.path",
            task: "Complete my structural dynamics assignment — solve free and forced vibration problems for SDOF or MDOF systems, compute natural frequencies and mode shapes using stiffness/mass matrices, perform earthquake response spectrum analysis, apply Newmark-beta integration to find time-history response, or analyze damping effects on structural performance",
            successCriteria: "Structural dynamics assignment completed (equations of motion formulated, natural frequencies and mode shapes computed, response spectrum or time-history results obtained, worked calculations clearly presented, and written solution summary with labeled diagrams saved to file)",
            preferredDuration: 60 * 60
        ),
        // bioprocessengineering
        SuggestedTemplate(
            icon: "flask.fill",
            task: "Study bioprocess engineering for my exam — review microbial growth kinetics (Monod model, yield coefficients, substrate inhibition), bioreactor types and design (CSTR, batch, fed-batch, airlift), mass transfer (oxygen transfer rate, kLa), downstream processing (centrifugation, filtration, chromatography), and cell culture scale-up considerations",
            successCriteria: "Bioprocess engineering study session completed (at least two topics reviewed with kinetic model equations, bioreactor design parameters, oxygen transfer correlations, downstream processing flowsheets, and worked fermentation design examples saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "flask.fill",
            task: "Complete my bioprocess engineering assignment — model microbial growth using Monod kinetics (compute μmax, Ks, yields), design a bioreactor (volume, aeration, agitation for OTR), analyze fed-batch feeding strategies, perform a mass balance for downstream processing, or evaluate chromatography column design for protein purification",
            successCriteria: "Bioprocess engineering assignment completed (kinetic parameters estimated or bioreactor designed with material balance, OTR/kLa calculation, process flow diagram, key assumptions stated, and written design rationale with numerical results saved to file)",
            preferredDuration: 60 * 60
        ),
        // systemsengineering
        SuggestedTemplate(
            icon: "cpu.fill",
            task: "Study systems engineering for my exam — review the systems engineering V-model (requirements through verification/validation), model-based systems engineering (MBSE) and SysML diagrams (block definition, internal block, activity, sequence), requirements management (functional/performance/interface requirements), tradespace analysis, and system integration testing",
            successCriteria: "Systems engineering study session completed (at least two topics reviewed with V-model diagram, SysML notation examples, requirements hierarchy tables, tradespace matrix, interface control document structure, and worked system decomposition examples saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "cpu.fill",
            task: "Complete my systems engineering assignment — develop a system concept of operations (ConOps), decompose a system into functional and physical architecture using SysML block definition diagrams, write measurable system requirements, create an interface control document, or perform a tradespace analysis comparing design alternatives",
            successCriteria: "Systems engineering assignment completed (ConOps or SysML diagrams produced, requirements written with verification method, tradespace matrix or ICD completed, and written design rationale explaining architectural decisions and requirement traceability saved to file)",
            preferredDuration: 60 * 60
        ),
        // transportationplanning
        SuggestedTemplate(
            icon: "car.fill",
            task: "Study transportation planning for my exam — review the four-step travel demand model (trip generation with ITE rates, trip distribution with gravity model, mode choice with logit model, traffic assignment with user equilibrium), VMT and level of service calculation, land use and transportation interaction, and MPO planning processes",
            successCriteria: "Transportation planning study session completed (at least two steps of the four-step model reviewed with production/attraction equations, gravity model calibration, logit model calculation, traffic assignment convergence, and worked demand forecasting examples saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "car.fill",
            task: "Complete my transportation planning assignment — build or calibrate a trip generation model (regression or cross-classification), apply the gravity model for trip distribution, compute mode split probabilities using a logit model, perform traffic assignment to a network, or analyze travel demand model outputs to evaluate a land use or transportation policy scenario",
            successCriteria: "Transportation planning assignment completed (model step computed with calibrated parameters, calculated trips/probabilities/assigned volumes, sensitivity analysis or scenario comparison included, and written report with model assumptions, results table, and interpretation saved to file)",
            preferredDuration: 60 * 60
        ),
        // architecturalengineering
        SuggestedTemplate(
            icon: "building.2.fill",
            task: "Study architectural engineering for my exam — review building systems integration (structural, HVAC, plumbing, electrical), building envelope performance (thermal resistance, air barrier, moisture control), daylighting and electrical lighting design (illuminance levels, daylight factor, lumen method), passive design strategies, and building energy analysis methods",
            successCriteria: "Architectural engineering study session completed (at least two systems reviewed with R-value calculations, HVAC load estimation steps, illuminance calculations, energy balance concepts, and worked building performance examples saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "building.2.fill",
            task: "Complete my architectural engineering assignment — perform a heating/cooling load calculation (ASHRAE method), design a daylighting scheme (window-to-wall ratio, daylight factor, glare control), analyze building envelope thermal performance (U-value, condensation risk), model MEP system coordination for a building floor plan, or evaluate passive design strategies to reduce energy use",
            successCriteria: "Architectural engineering assignment completed (load calculation, daylighting analysis, or envelope evaluation performed with quantitative results, building cross-section or system diagram labeled, key assumptions documented, and written design rationale with performance summary saved to file)",
            preferredDuration: 60 * 60
        ),
        // environmentalhydrology
        SuggestedTemplate(
            icon: "cloud.rain.fill",
            task: "Study environmental hydrology for my exam — review stormwater hydrology concepts (rational method, SCS curve number, TR-55), HEC-HMS watershed modeling (sub-basin delineation, loss methods, routing), SWMM stormwater network simulation, detention and retention pond design, culvert hydraulics, and flood frequency analysis",
            successCriteria: "Environmental hydrology study session completed (at least two topics reviewed with CN table lookups, HEC-HMS model parameters, TR-55 calculations, detention pond sizing, culvert design tables, and worked runoff estimation examples saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "cloud.rain.fill",
            task: "Complete my environmental hydrology assignment — compute peak runoff using the rational method or SCS-CN method, build or calibrate a HEC-HMS watershed model, design a detention pond for a target release rate, perform SWMM simulation for a stormwater network, or size a culvert for a design storm event",
            successCriteria: "Environmental hydrology assignment completed (runoff calculations with design storm input, HEC-HMS or SWMM model built or calibrated, detention pond or culvert sized with hydraulic checks, and written design summary with labeled diagrams and numerical results saved to file)",
            preferredDuration: 60 * 60
        ),
        // geoenvironmentalengineering
        SuggestedTemplate(
            icon: "leaf.fill",
            task: "Study geoenvironmental engineering for my exam — review contaminated site characterization and remediation (pump-and-treat, soil vapor extraction, bioremediation), groundwater contaminant transport (advection-dispersion equation, retardation factor, Darcy flow in soil), landfill liner design (geosynthetics, leachate collection), and regulatory frameworks (RCRA, CERCLA)",
            successCriteria: "Geoenvironmental engineering study session completed (at least two topics reviewed with advection-dispersion equations, contaminant plume sketches, remediation system design parameters, landfill liner cross-section diagrams, and worked transport calculation examples saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "leaf.fill",
            task: "Complete my geoenvironmental engineering assignment — model a contaminant plume using the advection-dispersion equation, design a pump-and-treat or SVE remediation system, calculate retardation factors and travel times for a contaminated aquifer, size a landfill liner system with leachate collection, or evaluate bioremediation feasibility for a site",
            successCriteria: "Geoenvironmental engineering assignment completed (contaminant transport modeled with plume extent or concentration profiles, remediation system designed with well spacing or extraction rates, material balance and regulatory compliance checked, and written design rationale with supporting calculations saved to file)",
            preferredDuration: 60 * 60
        ),
        // earthquakeengineering
        SuggestedTemplate(
            icon: "waveform",
            task: "Study earthquake engineering for my exam — review probabilistic seismic hazard analysis (PSHA, ground motion prediction equations, hazard curves), site amplification and site response analysis, liquefaction potential evaluation (Seed-Idriss simplified method, cyclic stress ratio), seismic design categories per ASCE 7, and earthquake-resistant structural detailing",
            successCriteria: "Earthquake engineering study session completed (at least two topics reviewed with PSHA calculation steps, GMPE equations, liquefaction triggering charts, site class definitions, seismic design category tables, and worked seismic hazard examples saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "waveform",
            task: "Complete my earthquake engineering assignment — perform probabilistic seismic hazard analysis for a site, evaluate liquefaction potential using the simplified Seed-Idriss procedure, compute site amplification factors, determine the seismic design category and design spectral accelerations per ASCE 7, or analyze ground motion records for PGA and spectral ordinates",
            successCriteria: "Earthquake engineering assignment completed (PSHA or liquefaction evaluation completed with supporting calculations, design spectral acceleration determined, and written report with hazard curve, liquefaction factor of safety, or seismic design parameter table saved to file)",
            preferredDuration: 60 * 60
        ),
        // computationalstructuralmechanics
        SuggestedTemplate(
            icon: "grid",
            task: "Study computational structural mechanics and FEA for my exam — review finite element formulation (element stiffness matrix assembly, isoparametric elements, Gaussian quadrature), weak form and Galerkin method, mesh convergence and h/p-refinement, contact mechanics and nonlinear FEA (material and geometric nonlinearity), and ABAQUS/ANSYS workflow",
            successCriteria: "Computational structural mechanics study session completed (at least two topics reviewed with stiffness matrix derivation, isoparametric shape functions, convergence plots, contact formulation notes, nonlinear solution procedure steps, and worked FEA examples saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "grid",
            task: "Complete my finite element analysis assignment — derive or assemble element stiffness matrices for a structural problem, build and solve a truss or beam FEA model in ABAQUS or ANSYS, perform a mesh convergence study, analyze contact stress distribution, solve a nonlinear FEA problem with large deformations or plasticity, or verify FEA results against analytical solutions",
            successCriteria: "Finite element analysis assignment completed (FEA model built with correct boundary conditions and loads, convergence verified, stress and displacement results post-processed, and written report with mesh diagram, convergence plot, stress contour, and comparison to analytical solution saved to file)",
            preferredDuration: 60 * 60
        ),
        // coastalengineeringocean
        SuggestedTemplate(
            icon: "water.waves",
            task: "Study coastal engineering for my exam — review linear wave theory (Airy waves, dispersion relation, wave celerity, group velocity), nearshore wave transformation (shoaling, refraction, diffraction, breaking), coastal sediment transport and longshore drift, breakwater and revetment design, wave runup and overtopping, and storm surge analysis",
            successCriteria: "Coastal engineering study session completed (at least two topics reviewed with wave dispersion equations, shoaling coefficient calculations, sediment transport formulas, breakwater armor sizing, wave runup charts, and worked coastal design examples saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "water.waves",
            task: "Complete my coastal engineering assignment — apply linear wave theory to compute wave properties at a given depth, calculate wave transformation from offshore to nearshore using shoaling and refraction analysis, estimate longshore sediment transport rates, design a rubble mound breakwater or beach nourishment scheme, or compute wave runup and overtopping rates for a coastal structure",
            successCriteria: "Coastal engineering assignment completed (wave calculations with dispersion solution, nearshore transformation computed, structure designed or sediment budget estimated, and written design report with wave rose, cross-section diagram, armor sizing, and numerical results saved to file)",
            preferredDuration: 60 * 60
        ),
        // corrosionengineering
        SuggestedTemplate(
            icon: "bolt.shield.fill",
            task: "Study corrosion engineering for my exam — review electrochemical corrosion mechanisms, the galvanic series, Pourbaix diagrams, corrosion rates and Faraday's law, cathodic and anodic protection, corrosion inhibitors, stress corrosion cracking (SCC), pitting and crevice corrosion, and passivation",
            successCriteria: "Corrosion engineering study session completed (at least two corrosion mechanisms reviewed with Pourbaix diagram construction, corrosion rate calculations, cathodic protection design parameters, SCC susceptibility conditions, and mitigation strategies summarized and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "bolt.shield.fill",
            task: "Work on my corrosion engineering assignment — construct a Pourbaix diagram for a given metal-solution system, calculate corrosion current density and rate using Faraday's law, design a cathodic protection system (impressed current or sacrificial anode), analyze a stress corrosion cracking failure scenario, or evaluate corrosion inhibitor effectiveness",
            successCriteria: "Corrosion engineering assignment completed (Pourbaix diagram constructed, corrosion rate computed, cathodic protection system designed, SCC failure scenario analyzed, or inhibitor evaluation completed with thermodynamic data, Tafel slopes, protection potentials, and written analysis saved to file)",
            preferredDuration: 60 * 60
        ),
        // acousticalengineering
        SuggestedTemplate(
            icon: "ear.fill",
            task: "Study acoustical engineering for my exam — review the Sabine and Eyring reverberation equations, absorption coefficients and NRC values, sound transmission loss, STC ratings, flanking transmission paths, noise criteria (NC) curves, speech intelligibility (STI), room acoustic design principles, and noise isolation class (NIC)",
            successCriteria: "Acoustical engineering study session completed (at least two topics reviewed with Sabine RT60 calculations, absorption coefficient lookup, STC/NRC table use, NC curve construction, STI prediction, and noise isolation design for at least one room type summarized and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "ear.fill",
            task: "Work on my acoustical engineering assignment — calculate RT60 using Sabine or Eyring formula for a given room volume and absorption data, determine STC rating for a wall assembly, map flanking transmission paths in a building section, compute speech intelligibility index for a classroom, or design acoustic treatment (panel placement, absorption targets) to meet an NC criterion",
            successCriteria: "Acoustical engineering assignment completed (RT60 calculated with room volume and absorption data, STC determined, flanking paths mapped, STI computed, or acoustic treatment designed with absorption schedule, NC curve comparison, and written design report saved to file)",
            preferredDuration: 60 * 60
        ),
        // microfluidics
        SuggestedTemplate(
            icon: "square.3.layers.3d",
            task: "Study microfluidics for my exam — review Reynolds number in microchannels, electroosmotic and electrophoretic flow, Stokes flow and pressure-driven profiles, Dean flow in curved channels, PDMS device fabrication via soft lithography, droplet and digital microfluidics, capillary electrophoresis, and lab-on-chip integration strategies",
            successCriteria: "Microfluidics study session completed (at least two topics reviewed with low-Re flow regime derivation, electroosmotic velocity calculations, PDMS soft lithography steps, Dean flow secondary pattern sketches, droplet generation mechanism, and capillary electrophoresis separation principles summarized and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "square.3.layers.3d",
            task: "Work on my microfluidics assignment — design a microchannel network for a given flow rate and pressure drop using Stokes flow analysis, calculate electroosmotic flow velocity for a given electric field and zeta potential, design a PDMS soft-lithography fabrication process, model droplet formation in a T-junction, or analyze species separation in a capillary electrophoresis chip",
            successCriteria: "Microfluidics assignment completed (microchannel design with hydraulic resistance network, EOF velocity computed, PDMS fabrication protocol written, droplet model analyzed, or CE separation resolved with mobility calculations, channel dimensions, applied voltage, and results saved to file)",
            preferredDuration: 60 * 60
        ),
        // marinehydrodynamics
        SuggestedTemplate(
            icon: "ferry.fill",
            task: "Study marine hydrodynamics for my exam — review potential flow theory, added mass and radiation damping coefficients, wave-body interaction (radiation/diffraction), strip theory for seakeeping, propeller thrust and torque theory (open-water characteristics), hydrodynamic wave resistance, and panel methods for submerged body analysis",
            successCriteria: "Marine hydrodynamics study session completed (at least two topics reviewed with potential flow derivation, added mass tensor construction, radiation/diffraction problem setup, strip theory equation of motion, propeller KT/KQ curve interpretation, and wave resistance Froude number dependence summarized and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "ferry.fill",
            task: "Work on my marine hydrodynamics assignment — compute added mass coefficients for a given body geometry using potential flow theory, solve a strip theory seakeeping equation for heave or pitch motion, analyze propeller open-water characteristics using KT/KQ diagrams, set up a radiation/diffraction panel method boundary value problem, or compute wave resistance for a given ship hull form",
            successCriteria: "Marine hydrodynamics assignment completed (added mass computed, seakeeping equation solved with RAO derivation, propeller performance point determined, panel method BVP formulated, or wave resistance computed with Froude number series, results plotted, and written analysis saved to file)",
            preferredDuration: 60 * 60
        ),
        // thermofluidscombustion
        SuggestedTemplate(
            icon: "flame.fill",
            task: "Study combustion engineering for my exam — review combustion stoichiometry, adiabatic flame temperature calculation, premixed and diffusion flames, laminar burning velocity, equivalence ratio and fuel-air ratio, NOx formation mechanisms (thermal, prompt, fuel NOx), ignition delay, flammability limits, and Damköhler number",
            successCriteria: "Combustion engineering study session completed (at least two topics reviewed with stoichiometric coefficient balancing, adiabatic flame temperature energy balance, burning velocity Markstein number, equivalence ratio ϕ definition, NOx formation pathway sketch, and ignition delay correlation summarized and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "flame.fill",
            task: "Work on my combustion engineering assignment — calculate adiabatic flame temperature for a given fuel/oxidizer mixture using enthalpy balance, determine equivalence ratio and products composition for a given fuel-air ratio, analyze a premixed laminar flame structure using asymptotic theory, estimate NOx emissions for a given combustor inlet condition, or apply flammability limits to a burner safety analysis",
            successCriteria: "Combustion engineering assignment completed (adiabatic flame temperature calculated, equivalence ratio and product composition determined, premixed flame structure analyzed, NOx estimate computed, or flammability safety analysis completed with species balance, thermochemical data, reaction pathway, and written solution saved to file)",
            preferredDuration: 60 * 60
        ),
        // quantumfieldtheory
        SuggestedTemplate(
            icon: "atom",
            task: "Study quantum field theory for my exam — review canonical quantization of scalar fields, Feynman diagram rules for QED, propagators (Feynman, retarded, advanced), S-matrix and LSZ reduction formula, one-loop renormalization, gauge invariance and Ward identities, path integral formulation, and Wick's theorem",
            successCriteria: "QFT study session completed (at least two topics reviewed with Feynman rules derived, S-matrix element computed, propagator expressions written, renormalization counterterms identified, LSZ formula applied, and key derivations saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "atom",
            task: "Work on my quantum field theory problem set — apply Feynman rules to compute a scattering amplitude at tree level, evaluate a one-loop diagram using dimensional regularization, derive the LSZ reduction formula for a given field, compute the Feynman propagator via path integral, or demonstrate gauge invariance for a given interaction",
            successCriteria: "QFT problem set completed (scattering amplitude computed with Feynman rules, loop diagram evaluated with counterterms, propagator derived, or gauge invariance demonstrated with Lagrangian density, momentum-space expressions, and written solution saved to file)",
            preferredDuration: 60 * 60
        ),
        // rfengineering
        SuggestedTemplate(
            icon: "antenna.radiowaves.left.and.right",
            task: "Study RF engineering for my exam — review transmission line theory (wave equations, reflection coefficient, VSWR), Smith chart impedance transformations, S-parameter definitions and measurement, impedance matching networks (stub tuning, quarter-wave transformer), two-port network analysis, antenna fundamentals (radiation pattern, gain, directivity), and waveguide modes",
            successCriteria: "RF engineering study session completed (at least two topics reviewed with transmission line equations derived, Smith chart impedance plotted, S-parameter matrix constructed, matching network designed, antenna directivity computed, and key formulas saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "antenna.radiowaves.left.and.right",
            task: "Work on my RF engineering assignment — design an impedance matching network using stub tuning or quarter-wave transformer, compute S-parameters for a given two-port circuit, use the Smith chart to find the reflection coefficient and VSWR, analyze a waveguide for its dominant mode cutoff frequency, or compute the far-field radiation pattern and gain for a dipole or patch antenna",
            successCriteria: "RF engineering assignment completed (matching network designed, S-parameters computed, Smith chart transformation completed, waveguide mode analyzed, or antenna gain and pattern calculated with transmission line equations, network matrix, and written solution saved to file)",
            preferredDuration: 60 * 60
        ),
        // fluidmechanics
        SuggestedTemplate(
            icon: "wind",
            task: "Study fluid mechanics for my exam — review fluid statics (pressure distribution, manometers, buoyancy), continuity and Bernoulli equations, Reynolds number and flow regimes, Navier-Stokes equations, pipe flow (Darcy-Weisbach, Moody chart, minor losses), boundary layer theory (Blasius, displacement thickness), and drag and lift on submerged bodies",
            successCriteria: "Fluid mechanics study session completed (at least two topics reviewed with Bernoulli application, pipe friction factor from Moody chart, boundary layer thickness derivation, drag coefficient lookup, Reynolds number calculation, and worked examples saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "wind",
            task: "Work on my fluid mechanics assignment — analyze flow in a pipe network using the Darcy-Weisbach equation and Moody chart, apply the Bernoulli equation and continuity to a nozzle or venturi problem, estimate boundary layer thickness on a flat plate using Blasius solution, compute drag force on a cylinder or sphere, or solve a fluid statics problem with manometer or buoyancy analysis",
            successCriteria: "Fluid mechanics assignment completed (pipe network solved with friction factors, Bernoulli application completed, boundary layer thickness estimated, drag computed, or statics problem solved with free-body diagram, pressure distribution, and written numerical solution saved to file)",
            preferredDuration: 60 * 60
        ),
        // heattransfer
        SuggestedTemplate(
            icon: "thermometer.sun.fill",
            task: "Study heat transfer for my exam — review Fourier's law and thermal resistance networks, convection heat transfer coefficient (Newton's law, Nusselt correlation), radiation (Stefan-Boltzmann, emissivity, view factors), fin analysis (fin efficiency, extended surface), heat exchanger design (LMTD method, NTU-effectiveness), and transient conduction (Biot number, lumped capacitance)",
            successCriteria: "Heat transfer study session completed (at least two topics reviewed with thermal resistance calculation, Nusselt correlation application, fin efficiency derivation, view factor determination, LMTD calculation, Biot number check, and worked examples saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "thermometer.sun.fill",
            task: "Work on my heat transfer assignment — design a fin array to achieve a target heat dissipation rate, size a shell-and-tube heat exchanger using the LMTD or NTU-effectiveness method, compute the transient temperature response of a lumped-capacitance body, determine view factors and radiation heat exchange between surfaces, or analyze combined convection and conduction through a composite wall",
            successCriteria: "Heat transfer assignment completed (fin array designed with efficiency and total heat rate, heat exchanger sized with LMTD or NTU calculation, transient response computed, radiation exchange determined, or composite wall analyzed with thermal resistance network and written numerical solution saved to file)",
            preferredDuration: 60 * 60
        ),
        // powersystems
        SuggestedTemplate(
            icon: "powerplug.fill",
            task: "Study power systems engineering for my exam — review per-unit system, bus admittance matrix (Y-bus) formulation, load flow analysis (Gauss-Seidel, Newton-Raphson), power factor correction, symmetrical components (positive/negative/zero sequence), short-circuit fault analysis, transformer equivalent circuits, and economic dispatch",
            successCriteria: "Power systems study session completed (at least two topics reviewed with per-unit conversion, Y-bus matrix assembled, load flow iteration demonstrated, symmetrical component transformation, fault current computed, economic dispatch Lagrangian solved, and worked examples saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "powerplug.fill",
            task: "Work on my power systems assignment — formulate and solve a load flow problem using Newton-Raphson or Gauss-Seidel iteration, compute fault currents for a three-phase or single-line-to-ground fault using symmetrical components, assemble the Y-bus matrix for a given network, design a capacitor bank for power factor correction to a target value, or solve an economic dispatch problem for a multi-generator system",
            successCriteria: "Power systems assignment completed (load flow converged with per-unit values, fault current computed with sequence networks, Y-bus assembled, power factor corrected to target, or economic dispatch solved with lambda iteration and written solution with bus voltages, fault levels, and numerical results saved to file)",
            preferredDuration: 60 * 60
        ),
        // nuclearreactorphysics
        SuggestedTemplate(
            icon: "atom",
            task: "Study reactor physics for my exam — review neutron transport theory, the four-factor and six-factor formulas, reactor criticality analysis (keff, multiplication factor), reactor kinetics and point kinetics equations, delayed neutron groups and their precursors, xenon and samarium poisoning, control rod worth, group diffusion theory, and neutron flux distribution in a bare reactor",
            successCriteria: "Reactor physics study session completed (at least two topics reviewed with four-factor formula components identified, keff calculation set up, point kinetics equations written, delayed neutron parameters listed, xenon transient described, control rod reactivity worth estimated, and key derivations saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "atom",
            task: "Work on my reactor physics assignment — calculate keff using the four-factor formula for a given fuel-moderator system, solve the point kinetics equations for a step reactivity insertion, estimate xenon poisoning reactivity worth at peak xenon, determine control rod worth using perturbation theory or the modified one-group model, or solve the one-group neutron diffusion equation for a specified reactor geometry",
            successCriteria: "Reactor physics assignment completed (keff calculated with four-factor components, point kinetics solved numerically or analytically, xenon peak estimated, control rod worth determined, or diffusion equation solved with boundary conditions and neutron flux profile saved to file)",
            preferredDuration: 60 * 60
        ),
        // optoelectronics
        SuggestedTemplate(
            icon: "light.max",
            task: "Study optoelectronics for my exam — review semiconductor band gap and band structure, p-n junction physics under forward bias, LED physics (spontaneous emission, quantum efficiency, Shockley equation), photodiode and photodetector operation (responsivity, dark current, noise), laser diode gain spectrum and threshold condition, electroluminescence and photoluminescence spectroscopy, solar cell I-V characteristics, and optical fiber coupling efficiency",
            successCriteria: "Optoelectronics study session completed (at least two topics reviewed with band gap energy diagram sketched, LED quantum efficiency calculated, photodetector responsivity derived, laser threshold gain condition written, solar cell fill factor defined, EL/PL peak identified, and worked examples saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "light.max",
            task: "Work on my optoelectronics assignment — calculate the quantum efficiency and radiant flux for a given LED operating point, determine the responsivity and noise-equivalent power for a specified photodiode, find the threshold current density for a double-heterostructure laser diode, analyze the spectral output of a semiconductor using photoluminescence data, or compute the short-circuit current and power conversion efficiency for a solar cell under AM1.5 illumination",
            successCriteria: "Optoelectronics assignment completed (LED quantum efficiency computed, photodiode responsivity and NEP calculated, laser threshold current estimated, PL spectrum analyzed for band gap, or solar cell efficiency determined with I-V characteristics, fill factor, and written numerical solution saved to file)",
            preferredDuration: 60 * 60
        ),
        // magneticresonance
        SuggestedTemplate(
            icon: "waveform.path.ecg",
            task: "Study MRI physics for my exam — review nuclear magnetic resonance fundamentals, Larmor frequency and precession, Bloch equations and magnetization dynamics, spin-echo and gradient-echo pulse sequences, k-space trajectory and image reconstruction via inverse Fourier transform, T1 and T2 relaxation mechanisms, slice selection and frequency/phase encoding, and signal-to-noise ratio in MRI",
            successCriteria: "MRI physics study session completed (at least two topics reviewed with Larmor frequency calculated, Bloch equation solution written, spin-echo timing diagram drawn, k-space trajectory sketched, T1/T2 relaxation curves labeled, encoding gradient derived, and key equations saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "waveform.path.ecg",
            task: "Work on my MRI/NMR assignment — derive the Bloch equations solution for a spin-echo experiment and calculate the echo amplitude at a given TE/TR, determine the k-space coordinates sampled by a given gradient waveform, compute the Larmor frequency for a specified nucleus and field strength, estimate T1 and T2 from inversion recovery or CPMG data, or reconstruct a 1D image from sampled k-space data using the discrete inverse Fourier transform",
            successCriteria: "MRI/NMR assignment completed (Bloch equation solution derived with echo amplitude computed, k-space coordinates mapped from gradient waveform, Larmor frequency calculated, T1/T2 fitted from experimental data, or 1D image reconstructed from k-space with timing diagram and written numerical solution saved to file)",
            preferredDuration: 60 * 60
        ),
        // computationalelectromagnetics
        SuggestedTemplate(
            icon: "antenna.radiowaves.left.and.right.circle.fill",
            task: "Study computational electromagnetics for my exam — review FDTD method (Yee grid, Courant stability, absorbing boundary conditions), method of moments (Green's function, basis functions, impedance matrix), finite element method for EM (weak form, tetrahedral meshing, penalty terms), HFSS/CST simulation workflow, numerical dispersion and convergence, antenna radiation pattern computation via near-to-far field transformation, and radar cross section estimation",
            successCriteria: "CEM study session completed (at least two topics reviewed with FDTD update equations derived, MoM impedance matrix assembled, FEM weak form written, HFSS workflow steps listed, CFL stability condition verified, near-to-far field transform outlined, and key formulas saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "antenna.radiowaves.left.and.right.circle.fill",
            task: "Work on my computational electromagnetics assignment — implement or analyze a 1D FDTD simulation for a specified pulse propagation problem and verify numerical dispersion, set up the method-of-moments impedance matrix for a wire dipole antenna and compute the current distribution, apply the FEM weak form to a waveguide eigenvalue problem, use HFSS or CST to simulate an antenna and extract S11 and radiation pattern, or estimate the radar cross section of a canonical scatterer",
            successCriteria: "CEM assignment completed (FDTD simulation verified with dispersion analysis, MoM matrix assembled with current distribution computed, FEM eigenvalue solved, antenna S11 and pattern extracted from simulation, or RCS estimated with near-to-far field transform and written solution with field plots saved to file)",
            preferredDuration: 60 * 60
        ),
        // thermoelectrics
        SuggestedTemplate(
            icon: "thermometer.and.lightning.bolt",
            task: "Study thermoelectrics for my exam — review the Seebeck effect and Seebeck coefficient, Peltier effect and Peltier heat, Thomson effect, thermoelectric figure of merit ZT and its components (electrical conductivity, Seebeck coefficient, thermal conductivity), thermoelectric generator efficiency and power output, thermoelectric cooler COP and maximum temperature difference, Wiedemann-Franz law, bismuth telluride and other thermoelectric materials, and module characterization",
            successCriteria: "Thermoelectrics study session completed (at least two topics reviewed with Seebeck voltage calculated, ZT expression written with all three transport coefficients, TEG efficiency formula applied, TEC COP derived, Wiedemann-Franz relation used, material properties compared, and worked examples saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "thermometer.and.lightning.bolt",
            task: "Work on my thermoelectrics assignment — calculate the open-circuit Seebeck voltage and maximum power output for a thermoelectric generator at specified hot/cold-side temperatures, determine the coefficient of performance and maximum temperature difference for a thermoelectric cooler at a given current, compute ZT from measured electrical conductivity, Seebeck coefficient, and thermal conductivity data, or compare efficiency of two thermoelectric materials using their ZT values at operating temperature",
            successCriteria: "Thermoelectrics assignment completed (Seebeck voltage and TEG power output calculated, TEC COP and ΔTmax determined, ZT computed from measured transport data, or material efficiency compared with ZT analysis, Carnot efficiency reference, and written numerical solution with parameter table saved to file)",
            preferredDuration: 60 * 60
        ),
        // nucleardynamics
        SuggestedTemplate(
            icon: "atom",
            task: "Study reactor dynamics for my exam — review the point kinetics equations (prompt and delayed neutron contributions), reactivity feedback mechanisms (Doppler broadening, moderator temperature coefficient, void coefficient), xenon-135 buildup and oscillation dynamics, temperature coefficient of reactivity, subcritical multiplication, scram analysis, RELAP/TRACE transient simulation methodology, and reactor control principles",
            successCriteria: "Reactor dynamics study session completed (at least two topics reviewed with point kinetics equations written, Doppler coefficient sign and mechanism explained, xenon oscillation condition derived, MTC and void coefficient calculated, subcritical multiplication formula applied, scram transient described, and key formulas saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "atom",
            task: "Work on my reactor dynamics assignment — solve the point kinetics equations for a specified reactivity insertion (prompt jump approximation and delayed neutron equations), calculate the temperature coefficient of reactivity using Doppler broadening for a given fuel composition, analyze xenon-135 transient behavior following a power change, determine subcritical multiplication for a subcritical assembly, or interpret RELAP/TRACE transient simulation output for a loss-of-coolant scenario",
            successCriteria: "Reactor dynamics assignment completed (point kinetics solved with prompt jump and delayed neutron contributions, temperature feedback coefficient calculated, xenon transient analyzed with buildup/decay rates, subcritical multiplication determined, or RELAP/TRACE output interpreted with power, temperature, and reactivity traces described and written solution saved)",
            preferredDuration: 60 * 60
        ),
        // additivemfg
        SuggestedTemplate(
            icon: "cube.fill",
            task: "Study additive manufacturing for my exam — review FDM process parameters (layer height, infill density, print speed, nozzle temperature), stereolithography (SLA) photopolymerization and cure depth, selective laser sintering (SLS) and powder bed fusion energy density, direct metal laser sintering (DMLS) process, design for additive manufacturing (DFAM) principles, support structure requirements, post-processing methods, and comparison of AM processes by material class",
            successCriteria: "Additive manufacturing study session completed (at least two AM processes reviewed with FDM parameters identified, SLA cure depth equation written, SLS energy density calculated, DFAM design rules listed, support structure placement criteria explained, post-processing steps described for one process, and key comparison table saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "cube.fill",
            task: "Work on my additive manufacturing assignment — select and justify an AM process (FDM, SLA, SLS, or DMLS) for a given part geometry and material requirement, determine optimal FDM parameters (layer height, infill, orientation) for a structural component, redesign a conventionally manufactured part for additive manufacturing using DFAM principles (topology optimization, lattice structures, part consolidation), or compare surface finish and mechanical properties for parts printed with different AM processes",
            successCriteria: "Additive manufacturing assignment completed (AM process selected with justification, FDM parameters determined with rationale, part redesigned with DFAM topology/lattice applied and material savings quantified, or AM process comparison documented with surface finish and mechanical property data, and written solution with design sketches or parameter table saved)",
            preferredDuration: 60 * 60
        ),
        // batterytechnology
        SuggestedTemplate(
            icon: "battery.100.bolt",
            task: "Study battery technology for my exam — review lithium-ion battery electrochemistry (intercalation mechanism, cathode and anode materials), SEI layer formation and its role in cycle life, solid-state battery advantages and solid electrolyte options, electrochemical impedance spectroscopy (EIS) interpretation, C-rate effects on capacity, Ragone plot (energy vs. power density), coulombic efficiency, calendar aging, and battery management system fundamentals",
            successCriteria: "Battery technology study session completed (at least two topics reviewed with Li-ion intercalation mechanism described, SEI formation explained, cathode/anode materials listed with voltage ranges, EIS Nyquist plot features identified, C-rate capacity relationship sketched, Ragone plot axes labeled, coulombic efficiency calculated, and key formulas saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "battery.100.bolt",
            task: "Work on my battery technology assignment — calculate the theoretical specific capacity and energy density of a given cathode/anode pair, interpret an EIS Nyquist plot to extract ohmic resistance, charge transfer resistance, and Warburg diffusion impedance, determine coulombic efficiency from charge/discharge data, analyze cycle life degradation using capacity fade curves, compare solid-state and liquid-electrolyte batteries for a given application, or design a simple electrode stack for a target energy and power requirement",
            successCriteria: "Battery technology assignment completed (specific capacity and energy density calculated, EIS features extracted with physical interpretation, coulombic efficiency determined, capacity fade analyzed quantitatively, or electrode stack design specified with area, thickness, and active material loading, and written solution with equations and results saved to file)",
            preferredDuration: 60 * 60
        ),
        // semiconductordevices
        SuggestedTemplate(
            icon: "circuit.board",
            task: "Study semiconductor devices for my exam — review p-n junction theory (depletion approximation, built-in potential, depletion width, I-V characteristic), MOSFET operation (threshold voltage, linear and saturation regions, body effect), BJT device physics (Ebers-Moll model, current gain, Early effect), minority carrier transport (drift-diffusion equation, diffusion length), Shockley ideal diode equation, junction breakdown mechanisms (avalanche and Zener), and small-signal models",
            successCriteria: "Semiconductor devices study session completed (at least two devices reviewed with p-n junction depletion width derived, MOSFET threshold voltage and drain current equations written, BJT Ebers-Moll equations stated, minority carrier diffusion length calculated, Shockley equation applied, breakdown mechanisms explained, and small-signal parameters listed)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "circuit.board",
            task: "Work on my semiconductor devices assignment — calculate depletion width and built-in potential for a specified p-n junction doping profile, derive or apply the MOSFET drain current in linear and saturation regions for given threshold voltage and device parameters, compute BJT current gain from minority carrier lifetimes and device geometry using the Ebers-Moll model, determine minority carrier concentration profile and diffusion current for a given injection level, or calculate avalanche breakdown voltage for a p-n junction",
            successCriteria: "Semiconductor devices assignment completed (depletion width and built-in potential calculated, MOSFET drain current derived in both regions, BJT current gain computed with Ebers-Moll, minority carrier profile sketched with diffusion current integrated, or breakdown voltage calculated, and written solution with energy band diagrams and equations saved to file)",
            preferredDuration: 60 * 60
        ),
        // vlsidesign
        SuggestedTemplate(
            icon: "cpu",
            task: "Study VLSI design for my exam — review CMOS logic design (static CMOS, pass-transistor logic, transmission gates), standard cell library methodology, transistor sizing for performance and power, static timing analysis (setup/hold time, slack, critical path), place-and-route flow (floorplanning, power grid, routing), logic synthesis with Synopsys Design Compiler, Cadence Virtuoso layout workflow, design rule checking (DRC), and layout versus schematic (LVS) verification",
            successCriteria: "VLSI design study session completed (at least two topics reviewed with CMOS gate sizing derived, standard cell characterization explained, critical path identified with slack calculated, place-and-route stages listed, logic synthesis flow described, Cadence/Synopsys tool flow outlined, DRC/LVS checks explained, and key timing equations saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "cpu",
            task: "Work on my VLSI design assignment — size CMOS transistors for a target propagation delay using the logical effort method, identify the critical path and compute setup-time slack in a given pipeline stage, write RTL for a digital module and run logic synthesis targeting a standard cell library with area or timing constraints, perform static timing analysis on a synthesized netlist, create or analyze a custom IC layout in Cadence Virtuoso satisfying DRC and LVS, or design a CMOS standard cell (inverter, NAND, NOR) with drive strength sizing",
            successCriteria: "VLSI design assignment completed (transistor sizes determined via logical effort, critical path slack computed, RTL synthesized and timing report generated, STA results interpreted with setup/hold margins documented, layout created with DRC/LVS clean, or standard cell designed with schematic and layout matching, and written solution or tool output saved to file)",
            preferredDuration: 60 * 60
        ),

        // spaceweather
        SuggestedTemplate(
            icon: "sun.max",
            task: "Study space weather for my exam — review solar wind structure and propagation, coronal mass ejections (CME initiation, propagation, ICME structure), geomagnetic storm phases (sudden commencement, main phase, recovery), Kp and Dst indices, Van Allen radiation belts and dynamics, magnetosphere-ionosphere coupling, solar energetic particle events, space weather impacts on satellites and power grids, and forecasting with real-time data (NOAA SWPC, ACE, DSCOVR)",
            successCriteria: "Space weather study session completed (at least two topics reviewed with solar wind–magnetosphere coupling explained, Kp and Dst indices defined with storm phases outlined, CME propagation time estimated, Van Allen belt particle trapping described, ionospheric effects summarized, and key space weather impacts on infrastructure listed and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "sun.max",
            task: "Work on my space weather assignment — compute geomagnetic storm arrival time from CME speed and solar distance, calculate Kp index threshold for given Dst values, analyze solar wind plasma parameters (density, velocity, Bz) from DSCOVR data, model particle flux in the radiation belts, estimate ionospheric TEC perturbations during a geomagnetic storm, evaluate satellite drag enhancement from thermospheric heating, or write a space weather impact assessment for a power grid or satellite system",
            successCriteria: "Space weather assignment completed (CME transit time calculated, Kp/Dst relationship quantified, solar wind parameters analyzed with expected magnetosphere response described, radiation belt flux or ionospheric TEC perturbation estimated, and written solution or analysis report saved to file)",
            preferredDuration: 60 * 60
        ),

        // nanophotonics
        SuggestedTemplate(
            icon: "waveform",
            task: "Study nanophotonics for my exam — review surface plasmon polaritons (dispersion relation, coupling conditions, Kretschmann/Otto configuration), localized surface plasmon resonance (Mie theory, Fröhlich condition), photonic crystals (band structure, bandgap, photonic density of states), near-field optics (evanescent waves, SNOM/NSOM), extraordinary optical transmission through subwavelength apertures, optical antennas, and quantum dot photophysics (Purcell effect, cavity QED)",
            successCriteria: "Nanophotonics study session completed (at least two topics reviewed with SPP dispersion relation derived, LSPR resonance condition explained for metal nanoparticle, photonic bandgap formation described, near-field evanescent decay derived, EOT mechanism explained, and key equations or diagrams saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "waveform",
            task: "Work on my nanophotonics assignment — compute the SPP dispersion relation and propagation length for a given metal-dielectric interface, calculate Mie scattering cross-section for a metal nanosphere at resonance, design a photonic crystal with a specified bandgap using plane-wave expansion, determine the near-field intensity enhancement for a nanoparticle dimer, evaluate the Purcell factor for a quantum dot in a microcavity, or analyze extraordinary optical transmission spectra for a subwavelength aperture array",
            successCriteria: "Nanophotonics assignment completed (SPP or LSPR resonance condition solved, Mie cross-section or photonic bandgap computed, near-field enhancement or Purcell factor calculated, transmission spectra analyzed and mechanism explained, and written solution or numerical result saved to file)",
            preferredDuration: 60 * 60
        ),

        // microelectromechanicalsystems
        SuggestedTemplate(
            icon: "cpu",
            task: "Study MEMS for my exam — review electrostatic actuation (parallel-plate and comb-drive, pull-in instability), piezoelectric transduction (d-coefficients, cantilever tip deflection), capacitive sensing (sensitivity, noise floor), surface micromachining (sacrificial layer, release etch), bulk micromachining (KOH anisotropic etch, DRIE Bosch process), MEMS resonators (Q factor, anchor loss), pressure sensors (diaphragm stress, Wheatstone bridge), accelerometers, and gyroscopes (Coriolis sensing)",
            successCriteria: "MEMS study session completed (at least two topics reviewed with pull-in voltage derived for parallel-plate actuator, piezoelectric cantilever deflection formula stated, capacitive sensitivity and noise floor estimated, microfabrication process flow described with at least three steps, DRIE Bosch etch profile explained, and key MEMS device performance equations saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "cpu",
            task: "Work on my MEMS assignment — derive pull-in voltage for a parallel-plate electrostatic actuator with given dimensions, compute tip deflection and resonant frequency of a piezoelectric cantilever, calculate capacitive sensitivity and minimum detectable signal for a comb-drive accelerometer, design a surface micromachining process flow for a MEMS resonator, estimate etch depth and sidewall angle for a DRIE Bosch process run, or analyze stress in a MEMS pressure sensor diaphragm and compute bridge output voltage",
            successCriteria: "MEMS assignment completed (pull-in voltage or piezoelectric deflection calculated, capacitive sensitivity or SNR estimated, process flow designed with etch conditions specified, DRIE etch parameters evaluated, or stress/bridge output computed, and written solution with labeled diagrams or numerical results saved to file)",
            preferredDuration: 60 * 60
        ),

        // photovoltaicsenergy
        SuggestedTemplate(
            icon: "bolt.fill",
            task: "Study photovoltaics for my exam — review p-n junction solar cell physics (photocurrent generation, minority carrier diffusion, depletion width), I-V characteristics (short-circuit current Isc, open-circuit voltage Voc, fill factor FF, maximum power point), bandgap engineering and spectrum matching, heterojunction solar cells, multi-junction/tandem cells, perovskite solar cells (ABX3 structure, ion migration, stability), dye-sensitized solar cells (Grätzel cell), external/internal quantum efficiency, and loss mechanisms (recombination, reflection, series resistance)",
            successCriteria: "Photovoltaics study session completed (at least two topics reviewed with Isc, Voc, and FF defined with ideal diode equation written, bandgap–wavelength relationship derived, heterojunction band alignment sketched, tandem cell current-matching condition explained, perovskite ABX3 structure described, and key efficiency limits noted and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "bolt.fill",
            task: "Work on my photovoltaics assignment — compute Isc, Voc, and fill factor from an I-V curve dataset, calculate the Shockley-Queisser efficiency limit for a given bandgap, design a two-junction tandem solar cell with current-matched subcells, analyze EQE spectrum to identify loss mechanisms, determine series and shunt resistance from I-V curve fitting, evaluate perovskite vs silicon heterojunction stability trade-offs, or estimate annual energy yield from a solar module given irradiance data",
            successCriteria: "Photovoltaics assignment completed (Isc, Voc, and FF extracted from I-V data, efficiency limit or tandem current match calculated, EQE loss mechanism identified, series/shunt resistance extracted, or annual yield estimated, and written solution or analysis with numerical results saved to file)",
            preferredDuration: 60 * 60
        ),

        // biomechatronics
        SuggestedTemplate(
            icon: "figure.walk",
            task: "Study biomechatronics for my exam — review EMG signal acquisition and processing (electrode placement, signal conditioning, feature extraction, pattern classification), prosthetic limb control strategies (myoelectric control, direct control, pattern recognition), upper/lower limb prosthetics (terminal devices, socket fitting, actuation), neural interfaces (EEG, ECoG, Utah array, spiking neural signals), brain-computer interfaces (P300, motor imagery, SSVEP), rehabilitation robotics (exoskeletons, assist-as-needed control), and surgical robotics (da Vinci kinematics, haptic feedback)",
            successCriteria: "Biomechatronics study session completed (at least two topics reviewed with EMG signal processing pipeline described, myoelectric control strategy explained, prosthetic socket-limb interface outlined, BCI signal acquisition and decoding steps listed, exoskeleton assist-as-needed control law written, and key biomechatronics device examples noted and saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "figure.walk",
            task: "Work on my biomechatronics assignment — design an EMG-based prosthetic hand control algorithm (electrode placement, feature extraction, classifier), analyze neural interface recording quality (SNR, spike sorting, decoding accuracy), simulate exoskeleton joint torque assistance for gait rehabilitation, evaluate myoelectric control vs pattern recognition trade-offs for upper limb prosthetics, compute kinematic workspace for a surgical robotic arm, or design an assist-as-needed impedance control law for a lower limb exoskeleton",
            successCriteria: "Biomechatronics assignment completed (EMG classifier designed or evaluated, neural interface SNR analyzed, exoskeleton torque or impedance control law derived, prosthetic control strategy compared with performance metrics, or surgical robot workspace computed, and written solution or simulation results saved to file)",
            preferredDuration: 60 * 60
        ),
        // condensedmatterphysics
        SuggestedTemplate(
            icon: "atom",
            task: "Study condensed matter physics for my exam — review Fermi liquid theory (quasiparticles, effective mass, Landau parameters), quantum Hall effect (integer and fractional, Landau levels, filling factor, edge states), topological insulators (bulk-boundary correspondence, Z2 invariant, surface Dirac cone), Berry phase and Berry curvature, Weyl semimetals (Weyl nodes, Fermi arc surface states, chirality), Kondo effect (Kondo temperature, heavy fermions), and strongly correlated electron systems (Mott insulator, Hubbard model)",
            successCriteria: "Advanced condensed matter study session completed (at least two topics reviewed with Fermi liquid quasiparticle concept explained, Landau level degeneracy derived, topological invariant classification stated, Berry phase formula written, quantum Hall conductivity plateau explained, Kondo temperature estimate discussed, and notes saved to file)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "atom",
            task: "Work on my condensed matter physics assignment — derive Landau level energies for a 2D electron gas in a magnetic field, calculate the filling factor and Hall conductance for integer quantum Hall states, determine the Z2 topological invariant for a model topological insulator Hamiltonian, analyze Berry curvature and anomalous Hall conductivity, solve the Kondo renormalization group equations to find the Kondo temperature, or compute the phase boundary of a Mott insulating transition in the Hubbard model",
            successCriteria: "Condensed matter physics assignment completed (Landau level spectrum derived, integer quantum Hall conductance computed, topological invariant evaluated, Berry phase or curvature calculated, Kondo temperature estimated, or Mott-Hubbard phase boundary determined, with full derivations written and saved)",
            preferredDuration: 60 * 60
        ),
        // energymaterials
        SuggestedTemplate(
            icon: "bolt.fill",
            task: "Study energy materials for my exam — review solid oxide fuel cells (SOFC) (electrolyte conductivity, polarization losses, operating temperature, yttria-stabilized zirconia), hydrogen storage materials (metal hydrides, MOF adsorbents, gravimetric/volumetric density, thermodynamics), thermoelectric materials (Seebeck coefficient, ZT figure of merit, Peltier effect, phonon engineering, half-Heusler alloys), and electrocatalysis (oxygen reduction reaction, hydrogen evolution reaction, overpotential, Tafel slope, volcano plot)",
            successCriteria: "Energy materials study session completed (at least two topics reviewed with SOFC operating principle and losses described, hydrogen storage mechanism and thermodynamics explained, ZT formula and trade-offs stated, ORR/HER mechanism and Tafel slope analysis outlined, and notes saved to file)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "bolt.fill",
            task: "Work on my energy materials assignment — calculate the Nernst potential and efficiency of an SOFC at operating temperature, compute gravimetric hydrogen storage capacity for a metal hydride and compare to DOE targets, optimize ZT for a thermoelectric material by balancing Seebeck coefficient and thermal conductivity, analyze a Tafel plot to extract exchange current density and overpotential for an ORR electrocatalyst, or evaluate the volcano plot position of a proposed catalyst using d-band center theory",
            successCriteria: "Energy materials assignment completed (SOFC efficiency computed, hydrogen storage capacity evaluated against targets, ZT optimized with trade-off analysis, Tafel slope and exchange current extracted from polarization data, or volcano plot position determined, with full written solution saved to file)",
            preferredDuration: 60 * 60
        ),
        // computationalneuroscience
        SuggestedTemplate(
            icon: "brain.head.profile",
            task: "Study computational neuroscience for my exam — review the Hodgkin-Huxley model (sodium/potassium conductance equations, action potential generation, gating variables m/h/n), integrate-and-fire neuron models (leaky IF, exponential IF, threshold dynamics), neural population models (mean-field theory, Wilson-Cowan equations, firing rate models), spike train analysis (Poisson process, ISI distribution, Fano factor, cross-correlogram), connectome analysis (graph measures, degree distribution, motifs), and reservoir computing (echo state networks, liquid state machines)",
            successCriteria: "Computational neuroscience study session completed (at least two topics reviewed with HH gating variable equations written, LIF membrane potential dynamics described, Wilson-Cowan steady-state analyzed, Poisson ISI distribution derived, graph centrality measure explained, and reservoir computing readout mechanism outlined, with notes saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "brain.head.profile",
            task: "Work on my computational neuroscience assignment — simulate the Hodgkin-Huxley model to reproduce an action potential and compute firing rate vs current (f-I curve), fit an integrate-and-fire model to spike train data, derive the mean-field equations for a Wilson-Cowan network and find its fixed points, analyze a spike train for Fano factor and cross-correlation, compute graph-theoretic measures (clustering coefficient, path length, small-world index) for a connectome dataset, or train a reservoir network to generate a target temporal pattern",
            successCriteria: "Computational neuroscience assignment completed (HH simulation run and f-I curve plotted, LIF model fit to data, Wilson-Cowan fixed points identified, spike train statistics computed, connectome graph measures reported, or reservoir readout weights trained, with code and output figures saved to file)",
            preferredDuration: 60 * 60
        ),
        // biophysicslab
        SuggestedTemplate(
            icon: "eyedropper.halffull",
            task: "Study for my experimental biophysics lab — review optical tweezers (gradient force trapping, stiffness calibration, power spectrum method, force-extension curves for DNA/proteins), patch clamp electrophysiology (whole-cell and single-channel modes, pipette resistance, series resistance compensation, ion channel conductance), FRET (Förster radius, efficiency-distance relationship, donor/acceptor pair selection, single-molecule FRET), super-resolution microscopy (STORM/PALM localization, STED, diffraction limit, blinking kinetics), and single-molecule fluorescence (photobleaching, step detection, burst analysis)",
            successCriteria: "Biophysics lab study session completed (at least two techniques reviewed with optical trap stiffness calibration method described, patch clamp recording mode explained, FRET efficiency-distance formula written, STORM localization principle outlined, single-molecule blinking kinetics analyzed, and lab notebook updated with key equations and protocols)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "eyedropper.halffull",
            task: "Work on my experimental biophysics lab report — analyze optical tweezers power spectrum data to extract trap stiffness and calibrate force, process patch clamp recordings to identify single-channel conductance states and open/close dwell times, compute FRET efficiency from donor/acceptor intensity traces and convert to inter-dye distance using the Förster radius, reconstruct a super-resolution image from STORM localizations using a Gaussian fitting algorithm, or detect photobleaching steps in a single-molecule fluorescence trace to count labeled subunits",
            successCriteria: "Biophysics lab report completed (trap stiffness extracted from power spectrum, ion channel conductance states identified from patch clamp trace, FRET efficiency and distance calculated, super-resolution image reconstructed or localization precision quoted, photobleaching step count determined, with analysis code, figures, and written report saved to file)",
            preferredDuration: 60 * 60
        ),
        // solidmechanics
        SuggestedTemplate(
            icon: "wrench.and.screwdriver",
            task: "Study solid mechanics for my exam — review stress and strain tensors (normal/shear stress, principal stresses, stress transformation), Mohr's circle construction (2D and 3D), elastic constitutive relations (Young's modulus, Poisson's ratio, shear modulus, Hooke's law in 3D), yield criteria (von Mises and Tresca), plastic deformation (isotropic/kinematic hardening), fracture mechanics (stress intensity factor K_I, fracture toughness K_Ic, energy release rate G, Griffith criterion), fatigue analysis (S-N curve, Goodman criterion, Paris law for crack growth), and continuum mechanics foundations (deformation gradient, principal strains)",
            successCriteria: "Solid mechanics study session completed (at least two topics reviewed with Mohr's circle construction described, von Mises yield criterion formula written, fracture toughness and mode-I stress intensity factor defined, plastic hardening type explained, Paris law crack-growth exponents noted, and key equations saved to study notes)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "wrench.and.screwdriver",
            task: "Work on my solid mechanics assignment — compute principal stresses and maximum shear stress from a given stress tensor using Mohr's circle or eigenvalue analysis, determine whether a stressed state causes yielding under von Mises or Tresca criterion, calculate mode-I stress intensity factor for an edge crack in a finite plate, find the critical crack length for a material with known fracture toughness, apply the Paris law to estimate fatigue life under cyclic loading, or derive the deflection of a statically indeterminate beam using compatibility equations",
            successCriteria: "Solid mechanics assignment completed (principal stresses and max shear computed, yield criterion applied with pass/fail conclusion, stress intensity factor or critical crack length found, fatigue life estimate calculated or beam deflection derived, with solution steps, free-body diagrams, and final numerical answers saved to file)",
            preferredDuration: 60 * 60
        ),
        // stochasticprocesses
        SuggestedTemplate(
            icon: "chart.line.uptrend.xyaxis",
            task: "Study stochastic processes for my exam — review probability space foundations (filtration, adapted process), discrete-time Markov chains (transition matrix, Chapman-Kolmogorov equations, stationary distribution, absorption, ergodicity, hitting times), continuous-time Markov chains (generator matrix, Kolmogorov forward/backward equations, birth-death process), Poisson process (interarrival times, superposition, thinning, compound Poisson), Brownian motion (construction, reflection principle, properties), martingales (definition, optional stopping theorem, Doob's maximal inequality), and stochastic calculus basics (Itô integral, Itô's lemma, geometric Brownian motion SDE)",
            successCriteria: "Stochastic processes study session completed (at least two topics reviewed with Markov chain stationary distribution computed, Poisson process properties listed, Brownian motion characteristic function written, martingale definition and optional stopping conditions stated, Itô's lemma formula recorded, and key results saved to study notes)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "chart.line.uptrend.xyaxis",
            task: "Work on my stochastic processes assignment — find the stationary distribution of a finite Markov chain from its transition matrix, compute mean hitting time from state i to state j using first-step equations, derive the distribution of Poisson process event counts and prove the memoryless property, calculate the probability that Brownian motion hits level b before level -a using the optional stopping theorem, verify the martingale property for a given process, apply Itô's lemma to derive the SDE for a function of a Brownian motion, or solve a Kolmogorov forward equation for a birth-death chain",
            successCriteria: "Stochastic processes assignment completed (stationary distribution or hitting time computed, Poisson event distribution derived, Brownian motion boundary probability calculated, martingale property verified, Itô's lemma applied correctly, or birth-death equation solved, with full derivation steps and final answer saved to file)",
            preferredDuration: 60 * 60
        ),
        // quantumchemistry
        SuggestedTemplate(
            icon: "atom",
            task: "Study quantum chemistry for my exam — review the Schrödinger equation for molecules (Born-Oppenheimer approximation, separation of nuclear/electronic motion), variational principle and basis set expansion (LCAO-MO theory), Hartree-Fock theory (HF equations, Fock operator, self-consistent field procedure, Roothaan equations, Slater determinant), electron correlation methods (configuration interaction, MP2 perturbation theory, coupled cluster CCSD(T)), density functional theory (Hohenberg-Kohn theorems, Kohn-Sham equations, exchange-correlation functionals), basis sets (STO vs GTO, Pople sets, cc-pVXZ), and molecular properties (dipole moment, geometry optimization, vibrational frequencies from the Hessian)",
            successCriteria: "Quantum chemistry study session completed (at least two topics reviewed with Born-Oppenheimer approximation explained, HF SCF procedure outlined, MP2 energy correction formula written, DFT Kohn-Sham equations described, CCSD(T) hierarchy placed, basis set notation decoded, and key equations saved to study notes)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "atom",
            task: "Work on my quantum chemistry assignment — apply the variational method to minimize energy for a trial wavefunction (e.g. He atom with screening constant), solve the Roothaan equations iteratively for a minimal-basis H₂ or HeH⁺ calculation, compute the Hartree-Fock energy and equilibrium bond length for a small molecule using a specified basis set, derive the MP2 correlation energy correction from second-order perturbation theory, evaluate exchange-correlation energy for a simple electron density using an LDA functional, interpret a DFT geometry optimization output to extract bond lengths and vibrational modes, or compare HF/DFT/CCSD(T) energies for a reaction and explain the source of discrepancies",
            successCriteria: "Quantum chemistry assignment completed (variational energy minimized, HF energy computed or Roothaan equations stepped through, MP2 correction derived, DFT functional applied and energy reported, geometry optimization output interpreted, or method comparison table completed, with derivation steps and computed values saved to file)",
            preferredDuration: 60 * 60
        ),
        // opticalengineering
        SuggestedTemplate(
            icon: "camera.aperture",
            task: "Study optical engineering for my exam — review geometrical optics fundamentals (ray transfer matrix method ABCD, refraction at spherical surfaces, principal planes, nodal points), Gaussian beam propagation (beam waist, Rayleigh range, q-parameter, ABCD law for Gaussian beams, M² factor), aberration theory (Seidel/primary aberrations: spherical aberration, coma, astigmatism, field curvature, distortion; chromatic aberration), wavefront description (Zernike polynomials, Zernike coefficients, RMS wavefront error, Strehl ratio), wavefront sensing (Shack-Hartmann sensor principle, reconstructor), optical interferometry (Michelson, Mach-Zehnder, Fizeau; fringe pattern interpretation; phase-shifting interferometry), and adaptive optics concepts (deformable mirror, closed-loop correction)",
            successCriteria: "Optical engineering study session completed (at least two topics reviewed with ray transfer matrix for a thick lens written, Gaussian beam q-parameter propagation formula stated, five Seidel aberrations listed, first three Zernike modes defined, Shack-Hartmann sensing principle described, interferogram fringe spacing formula noted, and key equations saved to study notes)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "camera.aperture",
            task: "Work on my optical engineering assignment — trace paraxial rays through a multi-element lens system using ABCD ray transfer matrices to find effective focal length and principal-plane positions, propagate a Gaussian beam through a sequence of lenses using the ABCD formalism to find the output beam waist and location, decompose a measured wavefront map into Zernike polynomials and report the RMS wavefront error and Strehl ratio, design a simple two-lens system in Zemax to meet a specified F/# and field-of-view while minimizing spherical aberration, analyze a Shack-Hartmann sensor output to reconstruct the aberrated wavefront, or process phase-shifted interferograms to extract the OPD map and identify the dominant Seidel aberration",
            successCriteria: "Optical engineering assignment completed (ray matrix EFL and principal planes computed, Gaussian beam output waist found, Zernike decomposition and RMS WFE reported, Zemax design meeting specs saved, Shack-Hartmann wavefront reconstructed, or OPD map extracted from interferograms, with figures and numerical results saved to file)",
            preferredDuration: 60 * 60
        ),
        // quantumoptics
        SuggestedTemplate(
            icon: "rays",
            task: "Study quantum optics for my exam — review fundamentals of quantum states of light (Fock states, coherent states, squeezed states, thermal states; Wigner function and phase-space representations; photon number statistics: sub-Poissonian, Poissonian, super-Poissonian; Mandel Q parameter), light-matter interaction (Jaynes-Cummings model: rotating wave approximation, vacuum Rabi splitting, dressed states, Rabi oscillations; cavity QED strong-coupling regime; spontaneous emission enhancement/suppression; Purcell effect), quantum optical phenomena (Hong-Ou-Mandel effect, two-photon interference; entangled photon pairs from SPDC; Bell state measurement; quantum key distribution BB84 protocol; no-cloning theorem), and detection (photon counting, homodyne detection, heterodyne detection, correlation functions g1 and g2)",
            successCriteria: "Quantum optics study session completed (at least two topics reviewed with Fock state definition written, coherent state Poissonian statistics explained, Jaynes-Cummings Hamiltonian stated, vacuum Rabi frequency formula given, Wigner function of a coherent state described, Hong-Ou-Mandel dip explained, SPDC entangled pair generation outlined, and key equations saved to study notes)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "rays",
            task: "Work on my quantum optics assignment — derive the Jaynes-Cummings eigenstates and eigenvalues in the rotating-wave approximation and compute the vacuum Rabi splitting for a given coupling constant, calculate the Wigner function of a specified quantum state (coherent state, Fock state, or squeezed state) and identify negativity signatures of non-classicality, analyze a homodyne or photon-counting measurement record to extract the quadrature variance and determine whether the state is squeezed, model Hong-Ou-Mandel interference visibility for partially distinguishable photons as a function of temporal overlap, design a BB84 QKD protocol specifying basis choices and compute the theoretical secure key rate, or calculate the Purcell factor for a cavity with given Q and mode volume and estimate the enhanced emission rate",
            successCriteria: "Quantum optics assignment completed (Jaynes-Cummings eigenstates and Rabi splitting derived, Wigner function computed and non-classicality assessed, homodyne variance analyzed, HOM visibility calculated, BB84 secure key rate estimated, or Purcell factor computed, with derivations and numerical results saved to file)",
            preferredDuration: 60 * 60
        ),
        // marinechemistry
        SuggestedTemplate(
            icon: "water.waves",
            task: "Study marine chemistry for my exam — review seawater composition and salinity (conservative and non-conservative elements; chlorinity-salinity relationship; major ion ratios; residence times), the carbonate system (dissolved CO₂, carbonic acid, bicarbonate, carbonate; Henry's law; first and second dissociation constants Ka1/Ka2; alkalinity definition; Revelle factor; pCO₂-pH-DIC relationships), ocean acidification (anthropogenic CO₂ uptake; aragonite and calcite saturation states Ω; saturation horizon; biological impacts), dissolved gases (oxygen minimum zone; apparent oxygen utilization AOU; nitrogen and phosphorus cycles; Redfield ratio), trace metal geochemistry (scavenging and nutrient-type distributions; biological uptake; organic complexation; hydrothermal input), and analytical methods (titration for alkalinity, spectrophotometric pH, discrete vs. underway pCO₂ measurements)",
            successCriteria: "Marine chemistry study session completed (at least two topics reviewed with carbonate system equilibria written, alkalinity definition stated, Revelle factor explained, aragonite saturation state formula given, Redfield ratio stated, AOU definition given, and key equations saved to study notes)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "water.waves",
            task: "Work on my marine chemistry assignment — calculate the speciation of the carbonate system (CO₂, HCO₃⁻, CO₃²⁻, pH, alkalinity) from given temperature, salinity, and two carbonate parameters using equilibrium constants, determine the aragonite and calcite saturation states Ω from alkalinity and DIC data and identify the saturation horizon depth, apply Henry's law to compute air-sea CO₂ flux from pCO₂ data and estimate annual ocean uptake for a given region, use the Redfield ratio to calculate nutrient drawdown and AOU from oxygen and nutrient profiles, analyze trace metal depth profiles to classify an element as conservative, nutrient-type, or scavenged and estimate its residence time, or design an alkalinity titration procedure and propagate measurement uncertainties through the carbonate system calculations",
            successCriteria: "Marine chemistry assignment completed (carbonate speciation computed at given conditions, saturation states Ω calculated and horizon identified, air-sea CO₂ flux estimated, AOU and nutrient drawdown from Redfield ratio derived, trace metal distribution type classified with residence time, or alkalinity titration procedure designed with uncertainty analysis, with results and plots saved to file)",
            preferredDuration: 60 * 60
        ),
        // bioinorganicchemistry
        SuggestedTemplate(
            icon: "atom",
            task: "Study bioinorganic chemistry for my exam — review metalloenzyme structure and function (active-site metal coordination geometry; role of protein environment in tuning redox potential; entatic state concept), oxygen-binding and transport proteins (hemoglobin and myoglobin cooperative binding; Hill equation and coefficient; T- and R-state allosteric model; cooperative O₂ binding; CO poisoning; heme electronic structure), iron-sulfur cluster proteins (2Fe-2S, 3Fe-4S, 4Fe-4S cluster structures and electronic states; rubredoxin; ferredoxin; aconitase mechanism), nitrogen fixation (nitrogenase structure; FeMo-cofactor; MoFe-protein and Fe-protein; ATP hydrolysis; proton and electron delivery), carbonic anhydrase mechanism (zinc-hydroxide mechanism; Brønsted catalysis; proton shuttle; second-shell interactions), and metal-based drugs (cisplatin mechanism; DNA platination; resistance mechanisms; anticancer metal complexes)",
            successCriteria: "Bioinorganic chemistry study session completed (at least two topics reviewed with hemoglobin Hill equation written, T/R state model described, 4Fe-4S cluster structure drawn, nitrogenase FeMo-cofactor described, carbonic anhydrase zinc-hydroxide mechanism stated, cisplatin DNA adduct described, and key concepts saved to study notes)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "atom",
            task: "Work on my bioinorganic chemistry assignment — derive the Hill equation and fit experimental O₂-binding data for hemoglobin to extract the Hill coefficient n and P₅₀, then quantify cooperativity and compare T-state vs. R-state affinities; model the electronic structure of a 4Fe-4S cluster in two different oxidation states and predict the EPR signature; analyze the proposed mechanism of carbonic anhydrase by identifying the rate-determining step, the role of the zinc-bound water, and the Brønsted base in proton shuttling; compare coordination environments of the FeMo-cofactor iron and molybdenum centers and discuss their role in N₂ activation; evaluate the mechanism by which cisplatin forms 1,2-d(GpG) intrastrand crosslinks with DNA, and propose structural features of a next-generation platinum drug that reduce nephrotoxicity while retaining cytotoxicity",
            successCriteria: "Bioinorganic chemistry assignment completed (Hill equation fitted with n and P₅₀ extracted, 4Fe-4S cluster oxidation states analyzed, carbonic anhydrase mechanism rate-determining step identified, FeMo-cofactor coordination discussed, and cisplatin DNA crosslink mechanism analyzed with next-generation drug proposal, with derivations and structural diagrams saved to file)",
            preferredDuration: 60 * 60
        ),
        // informationtheory
        SuggestedTemplate(
            icon: "waveform.path",
            task: "Study information theory for my exam — review entropy and information measures (Shannon entropy H(X); joint entropy H(X,Y); conditional entropy H(X|Y); mutual information I(X;Y) and chain rule; relative entropy/KL divergence; data processing inequality; Fano's inequality), source coding (source coding theorem; prefix-free codes; Kraft inequality; Huffman algorithm and optimality; entropy rate of stationary sources; arithmetic coding; Lempel-Ziv universality), channel coding (channel capacity C=max_{p(x)} I(X;Y); channel coding theorem (Shannon); symmetric channel capacity; BSC and BEC capacities; achievability via random coding; converse proof sketch; sphere-packing bound), and advanced coding (turbo codes and iterative decoding; LDPC codes and belief propagation; polar codes and channel polarization; rate-distortion theory: R(D) for Gaussian and binary sources)",
            successCriteria: "Information theory study session completed (at least two topics reviewed with Shannon entropy formula written, mutual information I(X;Y) defined via chain rule, Kraft inequality stated, Huffman code constructed for a simple source, BSC capacity formula C=1-H(p) derived, channel coding theorem statement written, and key definitions saved to study notes)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "waveform.path",
            task: "Work on my information theory assignment — construct an optimal Huffman code for a given source probability distribution, compute the average code length, and verify it lies between H(X) and H(X)+1; prove that mutual information I(X;Y) is always non-negative using the log-sum inequality or Jensen's inequality; calculate the channel capacity of a given discrete memoryless channel (binary symmetric, binary erasure, or Z-channel) by optimizing the input distribution and verify via the KKT conditions; apply the data-processing inequality to show that a processing step cannot increase mutual information; derive the rate-distortion function R(D) for a Bernoulli source with Hamming distortion; or analyze an LDPC factor graph, run one round of belief-propagation message passing, and compute the log-likelihood ratios at each variable node",
            successCriteria: "Information theory assignment completed (Huffman code constructed with average length computed, I(X;Y)≥0 proof completed, channel capacity optimized with KKT verification, data-processing inequality applied, R(D) derived for specified source-distortion pair, or LDPC belief-propagation round computed, with derivations and numerical results saved to file)",
            preferredDuration: 60 * 60
        ),
        // mathematicalstatistics
        SuggestedTemplate(
            icon: "function",
            task: "Study mathematical statistics for my exam — review sufficiency and completeness (factorization theorem; minimal sufficient statistics; complete statistics; Basu's theorem; exponential family form and its properties), unbiased estimation (UMVUE via Rao-Blackwell theorem and Lehmann-Scheffé theorem; Cramér-Rao lower bound; Fisher information I(θ); efficiency of estimators; method of moments vs. MLE properties), hypothesis testing (Neyman-Pearson lemma and most powerful tests; uniformly most powerful (UMP) tests; likelihood ratio tests; generalized likelihood ratio; size and power; p-values; Wald, score (Rao), and likelihood ratio test statistics), and distribution theory (order statistics: pdf of kth order statistic, joint density; convergence in probability, almost surely, in distribution; delta method; Slutsky's theorem; continuous mapping theorem)",
            successCriteria: "Mathematical statistics study session completed (at least two topics reviewed with factorization theorem stated, Rao-Blackwell theorem stated, Cramér-Rao bound formula written, exponential family canonical form given, Neyman-Pearson lemma conditions stated, UMP test definition given, and key theorems saved to study notes)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "function",
            task: "Work on my mathematical statistics assignment — find the sufficient and minimal sufficient statistic for a given parametric family using the factorization theorem, then determine whether it is complete; apply Rao-Blackwell and Lehmann-Scheffé to find the UMVUE of a specified estimand and verify it achieves the Cramér-Rao lower bound; derive the Neyman-Pearson most powerful test at level α for a simple vs. simple hypothesis and compute its power function; construct the generalized likelihood ratio test for a composite hypothesis and derive its asymptotic χ² distribution under H₀; derive the distribution of the k-th order statistic from a given continuous distribution and use the delta method to find the asymptotic distribution of a given sample functional; or prove consistency and asymptotic normality of the MLE for a regular parametric family using Fisher information",
            successCriteria: "Mathematical statistics assignment completed (sufficient statistic found and minimality/completeness verified, UMVUE derived and Cramér-Rao bound achieved, NP most powerful test constructed with power computed, GLRT asymptotic distribution derived, order statistic distribution found or delta method applied, or MLE consistency/asymptotic normality proved, with full derivations saved to file)",
            preferredDuration: 60 * 60
        ),
        // surfacechemistry
        SuggestedTemplate(
            icon: "bubbles.and.sparkles",
            task: "Study surface chemistry for my exam — review surface thermodynamics (Gibbs adsorption equation, surface excess, surface tension, wetting and contact angle, Young's equation, Dupré work of adhesion, spreading coefficient), adsorption isotherms (Langmuir model assumptions and derivation, Freundlich isotherm, BET multilayer adsorption, BET surface area measurement, Type I–VI physisorption isotherms), surface kinetics (Langmuir-Hinshelwood, Eley-Rideal, and Mars-van Krevelen mechanisms; Arrhenius analysis of surface rate constants; TOF and site density), surface characterization techniques (XPS binding energy shifts, Auger electron spectroscopy, LEED surface structure, temperature-programmed desorption/TPD analysis), and surface structure (surface reconstruction, relaxation, adsorbate-induced restructuring)",
            successCriteria: "Surface chemistry study session completed (at least two topics reviewed with Langmuir isotherm derivation outlined, BET surface area method explained, Langmuir-Hinshelwood rate expression written, TPD peak temperature-to-desorption-energy relation stated, Young's equation for contact angle written, XPS principle explained, and key equations saved to study notes)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "bubbles.and.sparkles",
            task: "Work on my surface chemistry assignment — fit experimental adsorption data to the Langmuir isotherm to extract K_eq and monolayer capacity θ_max, apply the BET equation to a nitrogen physisorption dataset to determine specific surface area and pore size, derive the Langmuir-Hinshelwood rate expression for a bimolecular surface reaction and extract activation energy from an Arrhenius plot, analyze a TPD spectrum to determine the desorption activation energy and pre-exponential factor using Redhead analysis, interpret an XPS spectrum to identify surface oxidation states and quantify surface elemental composition, or calculate the work of adhesion and spreading coefficient for a liquid-solid system from contact angle measurements",
            successCriteria: "Surface chemistry assignment completed (Langmuir fit parameters extracted, BET surface area computed, LH rate expression derived and Arrhenius analysis done, TPD desorption energy obtained via Redhead analysis, XPS oxidation states identified or spreading coefficient calculated, with data plots, fitted parameters, and written analysis saved to file)",
            preferredDuration: 60 * 60
        ),
        // historicalgeology
        SuggestedTemplate(
            icon: "clock.arrow.circlepath",
            task: "Study historical geology for my exam — review geologic time scale (eons/eras/periods/epochs and their boundaries), geochronology methods (radiometric dating: U-Pb concordia diagram, K-Ar, Rb-Sr, Sm-Nd; decay equations; isotopic systems and closure temperature), Precambrian geology (Hadean, Archean, Proterozoic; BIF and Great Oxidation Event, stromatolites, Snowball Earth, Ediacaran biota), Paleozoic era (Cambrian explosion, Ordovician glaciation, Devonian land plants and extinction, Carboniferous coal swamps, Permian–Triassic mass extinction), Mesozoic era (Pangea breakup, Jurassic marine transgressions, K-Pg extinction event and Chicxulub impactor, Cretaceous chalk), Cenozoic era (Paleogene volcanism and PETM, Neogene hominins, Pleistocene glaciations and LGM), paleogeography and plate tectonic history, and key stratigraphic principles applied in historical context (superposition, cross-cutting relationships, index fossils)",
            successCriteria: "Historical geology study session completed (at least two eras reviewed with geologic time scale written out, one radiometric dating method explained with decay equation, Cambrian explosion significance stated, K-Pg extinction cause summarized, Pangea assembly/breakup timeline sketched, Pleistocene glacial cycles described, and key era boundaries and events saved to study notes)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "clock.arrow.circlepath",
            task: "Work on my historical geology assignment — calculate absolute ages using the radiometric decay equation from given parent/daughter isotope ratios and half-lives, plot isotope data on a concordia diagram to determine crystallization age and degree of Pb loss, reconstruct a paleogeographic map for a specified geological period using paleomagnetic data and fossil assemblages, correlate stratigraphic sections across two localities using index fossils and lithological markers, analyze a geologic cross-section to identify unconformities and determine relative ages of rock units, or summarize the biotic and environmental changes across a specified mass extinction boundary using primary literature",
            successCriteria: "Historical geology assignment completed (absolute age calculated with decay equation and uncertainty, concordia age or paleogeographic reconstruction provided with supporting data, stratigraphic correlation documented with index fossils, unconformities identified in cross-section with relative ages determined, or mass extinction boundary summary with supporting evidence saved to file)",
            preferredDuration: 60 * 60
        ),
        // agriculturalchemistry
        SuggestedTemplate(
            icon: "leaf.circle",
            task: "Study agricultural chemistry for my exam — review soil chemistry fundamentals (cation exchange capacity, soil pH and buffer capacity, soil colloids and clay mineralogy, organic matter decomposition and humus formation, soil solution equilibria), fertilizer chemistry (nitrogen fertilizers: urea hydrolysis, ammonium nitrate, nitrification inhibitors; phosphorus fertilizers: superphosphate, triple superphosphate, soil P fixation and release; potassium fertilizers and luxury uptake), nutrient cycling (nitrogen cycle: mineralization, nitrification, denitrification, volatilization, leaching; phosphorus cycle: weathering, mineralization, sorption; carbon cycle in soil), pesticide chemistry (organophosphate and carbamate mechanisms, herbicide modes of action: ALS inhibition, photosystem II inhibition, EPSPS/glyphosate inhibition; persistence and half-life, soil sorption Kd/Koc coefficients), and plant-soil nutrient interactions (Liebig's law of the minimum, nutrient antagonism, critical tissue concentrations)",
            successCriteria: "Agricultural chemistry study session completed (at least two topics reviewed with CEC definition and units stated, urea hydrolysis reaction written, nitrogen cycle stages labeled with key transformations, one herbicide mode of action explained, Kd/Koc sorption concept defined, and key equations and nutrient cycle diagrams saved to study notes)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "leaf.circle",
            task: "Work on my agricultural chemistry assignment — calculate the amount of nitrogen fertilizer required to supply a target N rate given product analysis and application efficiency, determine soil pH change and lime requirement using a buffer pH method and lime neutralizing equivalents, analyze a soil test report to diagnose nutrient deficiencies using critical soil test levels and sufficiency ranges, compute pesticide half-life and persistence from degradation rate constants and model dissipation from a single application, derive sorption coefficients (Kd, Koc) from a batch equilibrium experiment dataset, or calculate ion activity products for phosphate mineral precipitation/dissolution equilibria in a soil solution",
            successCriteria: "Agricultural chemistry assignment completed (fertilizer N rate calculated with product-analysis conversion and units, lime requirement computed or soil nutrient diagnosis provided with recommendations, pesticide half-life derived or sorption coefficient determined from data, ion activity product vs. Ksp compared or nitrogen cycle budget balanced, with all calculations and interpretation saved to file)",
            preferredDuration: 60 * 60
        ),
        // digitalcommunications
        SuggestedTemplate(
            icon: "antenna.radiowaves.left.and.right",
            task: "Study digital communications for my exam — review digital modulation schemes (BPSK, QPSK, 16-QAM, 64-QAM; signal constellations, spectral efficiency, bandwidth, Eb/N0 vs. BER curves and Q-function), matched filter receiver and maximum likelihood detection (correlator receiver, signal space geometry, Euclidean distance, decision regions, union bound on BER), channel models (AWGN, Rayleigh fading, Rician fading; coherence bandwidth and coherence time, delay spread), OFDM fundamentals (DFT-based modulation, cyclic prefix length and ISI elimination, subcarrier spacing, peak-to-average power ratio), MIMO systems (spatial multiplexing, diversity-multiplexing tradeoff, Alamouti STBC diversity gain, ergodic capacity), channel coding (convolutional codes and free distance, Viterbi algorithm, turbo codes, LDPC, polar codes; coding gain), and spread spectrum (DSSS, FHSS, processing gain, CDMA near-far problem)",
            successCriteria: "Digital communications study session completed (at least two modulation schemes compared on constellation and BER vs. Eb/N0, matched filter principle stated, OFDM cyclic prefix purpose explained, Alamouti STBC described, Viterbi algorithm steps outlined, BER expression for BPSK in AWGN written, and key formulas saved to study notes)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "antenna.radiowaves.left.and.right",
            task: "Work on my digital communications assignment — derive the BER expression for BPSK modulation in AWGN using the matched filter receiver and Q-function, compare spectral efficiency and minimum Eb/N0 for a target BER across BPSK/QPSK/16-QAM/64-QAM constellations, design an OFDM system with given bandwidth and channel delay spread (compute number of subcarriers, subcarrier spacing, cyclic prefix length, and spectral efficiency), analyze a MIMO 2×2 system using the Alamouti STBC and compute diversity and coding gain over uncoded BPSK, derive the free distance of a rate-1/2 convolutional code and compute its coding gain, or evaluate channel capacity for a SISO AWGN link and compare with Shannon limit",
            successCriteria: "Digital communications assignment completed (BER expression derived with Q-function and Eb/N0 formula, modulation comparison table with spectral efficiency and BER computed, OFDM system parameters determined, Alamouti diversity gain stated or convolutional code free distance derived, Shannon capacity computed with comparison, and all derivations and numerical results saved to file)",
            preferredDuration: 60 * 60
        ),
        // contractlaw
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Study contract law for my exam — review contract formation elements (offer: definiteness and communication requirements; acceptance: mirror image rule, mailbox rule, silence as acceptance; consideration: bargained-for exchange, adequacy vs. sufficiency, past consideration, moral obligation, pre-existing duty rule; promissory estoppel/detrimental reliance), defenses to formation (incapacity: minors and mental incompetence; misrepresentation: fraudulent vs. innocent; duress; undue influence; unconscionability: procedural and substantive; illegality; statute of frauds: SWAP mnemonic for covered contracts, part performance and reliance exceptions), contract interpretation (plain meaning rule, parol evidence rule and exceptions: fraud/misrepresentation/collateral agreement/ambiguity; UCC gap-fillers; course of dealing, course of performance, trade usage), conditions and performance (express/constructive/implied conditions, substantial performance doctrine, anticipatory repudiation), and remedies (expectation damages: benefit of the bargain, lost profits, incidental and consequential damages, Hadley foreseeability; reliance damages; restitution; specific performance and injunctions; liquidated damages clauses)",
            successCriteria: "Contract law study session completed (at least two topics reviewed with offer/acceptance elements listed, consideration definition and exceptions stated, statute of frauds categories named with SWAP mnemonic, expectation vs. reliance damages distinguished, promissory estoppel elements written, Hadley v. Baxendale foreseeability rule explained, and key rules saved to outline or study notes)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.fill",
            task: "Work on my contracts assignment or brief a contracts case — analyze whether a contract was formed on given facts (identify offer, acceptance, and consideration or promissory estoppel basis), apply the statute of frauds to determine if a writing is required and whether part performance or reliance exceptions save the agreement, apply the parol evidence rule to determine what extrinsic evidence a court will admit to interpret a written contract, calculate expectation damages for a breach of contract scenario using the benefit-of-the-bargain formula and Hadley foreseeability analysis, analyze whether a frustration-of-purpose or impossibility-of-performance defense succeeds on given facts, or brief a landmark contracts case (Carlill v. Carbolic, Hamer v. Sidway, Frigaliment Importing Co. v. B.N.S., Jacob & Youngs v. Kent, Hadley v. Baxendale)",
            successCriteria: "Contracts assignment completed (contract formation analyzed with each element addressed or statute of frauds/parol evidence rule applied with exceptions discussed, damages calculated with lost profits, incidental costs, and Hadley foreseeability applied, frustration or impossibility defense analyzed, or case briefed with issue/rule/analysis/conclusion saved to file)",
            preferredDuration: 60 * 60
        ),
        // propertylaw
        SuggestedTemplate(
            icon: "house.fill",
            task: "Study property law for my exam — review present estates (fee simple absolute, fee simple determinable/on condition subsequent/on executory limitation, life estate, leasehold estates), future interests (possibility of reverter, right of entry/power of termination, reversion, remainder: vested vs. contingent, executory interests: springing and shifting; Shelley's Case, doctrine of worthier title), the Rule Against Perpetuities (common law RAP: no interest valid unless it must vest within 21 years of a life in being at creation; fertile octogenarian, unborn widow, and slothful executor problems; wait-and-see and USRAP reforms), adverse possession (elements: actual, exclusive, open and notorious, adverse/hostile, continuous for statutory period; color of title; tacking doctrine), easements (creation: express grant/reservation, implication from prior use, necessity, prescription; appurtenant vs. in gross; dominant and servient tenements; scope, transferability, and extinguishment), concurrent ownership (tenancy in common, joint tenancy with JTROS, tenancy by the entirety; severance of joint tenancy by conveyance or partition), and landlord-tenant law (types of tenancy; landlord duties: implied warranty of habitability; tenant defenses: constructive eviction, rent withholding)",
            successCriteria: "Property law study session completed (at least two topics reviewed with present estates and future interests table written, RAP three-step analysis explained with an example, adverse possession elements listed with tacking explained, one easement creation method described, joint tenancy vs. tenancy in common distinguished with severance rules, and key rules and classic RAP problems saved to outline or study notes)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "house.fill",
            task: "Work on my property law assignment or brief a property case — classify the present estates and identify all future interests created by a given conveyance and apply the Rule Against Perpetuities to determine which interests are valid or void, analyze whether adverse possession elements are met on given facts and determine if tacking applies to satisfy the statutory period, determine whether an easement was created by implication or necessity given a deed and parcel map, analyze a landlord-tenant dispute involving implied warranty of habitability, constructive eviction, wrongful holdover, or unlawful detainer, apply concurrent ownership rules to determine what interests survive a severance or partition attempt, or brief a landmark property case (Pierson v. Post, Kelo v. City of New London, Moore v. Regents of UC, Garner v. Gerrish, Javins v. First National Realty Corp.)",
            successCriteria: "Property law assignment completed (estates identified and future interests classified with RAP analysis and validity determination, adverse possession elements addressed with tacking considered, easement or landlord-tenant issue analyzed with rule stated and applied to facts, or case briefed with issue/rule/analysis/conclusion saved to file)",
            preferredDuration: 60 * 60
        ),
        // metamaterials
        SuggestedTemplate(
            icon: "waveform.badge.magnifyingglass",
            task: "Study metamaterials for my exam — review electromagnetic metamaterials fundamentals (negative permittivity ε and permeability μ; double-negative (DNG) media and left-handed materials; Veselago's prediction; negative refraction and the reversed Snell's law; Drude and Lorentz dispersion models for ε(ω) and μ(ω); frequency dispersion and loss), metamaterial unit cells (split-ring resonator (SRR) and its LC-circuit analogy; magnetic resonance frequency; SRR effective permeability; wire medium for negative ε; complementary SRR; coupled SRR arrays; fabrication at microwave and optical scales), effective medium theory and homogenization (Maxwell Garnett mixing formula; retrieval of effective ε and μ from S-parameters; validity bounds on homogenization; spatial dispersion; bianisotropy), metasurfaces and flat optics (phase-gradient metasurfaces; generalized Snell's law; geometric and resonant phase control; Huygens' metasurfaces; beam steering and anomalous refraction; metalenses; holography), and transformation optics (form invariance of Maxwell's equations; coordinate transformation to engineered material parameters; perfect lens and electromagnetic cloak; carpet cloak; TO-based waveguide design)",
            successCriteria: "Metamaterials study session completed (at least two topics reviewed with Veselago DNG conditions stated, SRR LC resonance frequency derived, effective medium retrieval method described, negative refraction Snell's law written, generalized Snell's law for metasurface stated, and key dispersion models and cloak transformation equations saved to study notes)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "waveform.badge.magnifyingglass",
            task: "Work on my metamaterials assignment — derive the effective permittivity of a wire medium using the Drude model and determine the plasma frequency and the frequency range of negative ε; use the LC-circuit analogy of a split-ring resonator to calculate the magnetic resonance frequency for given geometry parameters and construct the effective permeability μ(ω) curve; retrieve complex ε_eff and μ_eff from simulated or measured S-parameters (S11 and S21) of a metamaterial slab using the standard NRW or modified retrieval algorithm; apply the generalized Snell's law to design a phase-gradient metasurface that deflects normally-incident light at a target angle and specify the required phase profile across unit cells; or apply transformation optics to design an electromagnetic carpet cloak for a triangular bump, specifying the required spatially-varying anisotropic material parameters",
            successCriteria: "Metamaterials assignment completed (wire medium plasma frequency derived or SRR resonance frequency computed with geometry parameters, effective ε and μ retrieved from S-parameters with causality check, phase-gradient metasurface designed with unit-cell phase profile specified, or transformation-optics cloak material parameters derived with spatial map saved to file)",
            preferredDuration: 60 * 60
        ),
        // nondestructivetesting
        SuggestedTemplate(
            icon: "sensor.tag.radiowaves.forward",
            task: "Study nondestructive testing for my exam — review NDT fundamentals and methodology (definition of NDT/NDE; product quality vs. integrity inspection; discontinuity vs. defect vs. flaw; destructive vs. nondestructive comparison; ASNT certification levels I/II/III), ultrasonic testing (pulse-echo and through-transmission modes; A-scan, B-scan, C-scan displays; transducer types: contact, immersion, angle-beam; UT beam angle and refraction; Snell's law at interface; frequency selection and penetration vs. resolution tradeoff; phased-array UT; TOFD technique; scanning patterns; calibration blocks), radiographic testing (X-ray vs. gamma-ray sources; film and digital detectors; sensitivity; image quality indicators; penetrameters; exposure geometry; scattered radiation; safety), eddy current testing (Faraday induction; skin depth δ; coil impedance plane; lift-off effect; conductivity and permeability effects; frequency selection; flaw detection in non-ferrous materials), magnetic particle inspection (wet/dry method; fluorescent particles; AC vs. DC magnetization; circular vs. longitudinal fields; demagnetization), and dye penetrant testing (penetrant, emulsifier, developer steps; Type I fluorescent vs. Type II visible; sensitivity levels; surface preparation)",
            successCriteria: "NDT study session completed (at least two methods reviewed with pulse-echo UT mode described, Snell's law at interface stated, phased-array UT advantage explained, eddy current skin-depth formula written, MPI magnetization direction rule stated, penetrant testing four-step process listed, and key equations and ASNT level scope saved to study notes)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "sensor.tag.radiowaves.forward",
            task: "Work on my nondestructive testing assignment — calculate the refracted shear-wave angle and identify the critical angles for a UT angle-beam probe on a given steel sample using Snell's law at the acrylic-steel interface; select the appropriate UT frequency for a given material and flaw-size requirement by analyzing the tradeoff between near-field length, beam spread, and minimum detectable flaw; interpret a phased-array UT B-scan or S-scan image to identify flaw depth, through-wall extent, and lateral position; calculate skin depth at a given frequency and conductivity, select eddy current frequency to detect a near-surface flaw in aluminum at a specified depth, and sketch the impedance plane trajectory for a clean vs. flawed area; evaluate radiographic sensitivity by computing the minimum detectable wall-thickness change for a given IQI type and film-focus distance; or write an inspection procedure for a given component and flaw type specifying the NDT method, surface preparation, acceptance criteria, and documentation requirements",
            successCriteria: "NDT assignment completed (UT refracted angle calculated with critical angles identified, phased-array image interpreted with flaw dimensions reported, eddy current skin depth computed and frequency selected, radiographic sensitivity evaluated or inspection procedure written with method/parameters/acceptance criteria documented and saved to file)",
            preferredDuration: 60 * 60
        ),
        // optimalcontrol
        SuggestedTemplate(
            icon: "arrow.trianglehead.clockwise",
            task: "Study optimal control for my exam — review variational calculus foundations (Euler-Lagrange equation; functional derivative; transversality conditions; endpoint constraints; Legendre-Clebsch condition for minimum), Pontryagin's maximum/minimum principle (state equations; costate equations; Hamiltonian; stationarity condition; boundary conditions; transversality; bang-bang control; singular arcs; minimum-time and minimum-fuel problems), Hamilton-Jacobi-Bellman equation (dynamic programming principle; HJB PDE; value function; optimality conditions; sufficient conditions for optimality; Bellman's principle), linear-quadratic regulator (LQR: quadratic cost; Algebraic Riccati Equation (ARE); steady-state optimal gain K; closed-loop eigenvalue placement; infinite-horizon vs. finite-horizon LQR; frequency-domain interpretation; guaranteed stability margins), linear-quadratic-Gaussian control (LQG: separation principle; Kalman-Bucy filter design; optimal observer gain; loop transfer recovery (LTR); robustness limitations), and model predictive control (MPC: receding horizon philosophy; finite-horizon quadratic program; hard and soft constraints; stability via terminal constraint or cost; robust MPC; explicit MPC)",
            successCriteria: "Optimal control study session completed (at least two topics reviewed with Euler-Lagrange equation stated, Pontryagin Hamiltonian defined, costate equations written, HJB equation stated, Algebraic Riccati Equation written, LQR gain formula K=R⁻¹B^T P stated, separation principle for LQG explained, and MPC receding-horizon concept described with key equations saved to study notes)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "arrow.trianglehead.clockwise",
            task: "Work on my optimal control assignment — apply Pontryagin's minimum principle to a minimum-time or minimum-fuel problem (write the Hamiltonian, derive costate equations, apply stationarity condition, determine switching structure and bang-bang control law, and solve the two-point boundary value problem); solve the finite-horizon LQR problem for a given second-order system by integrating the Riccati differential equation backward from the terminal condition and computing the time-varying gain K(t); solve the infinite-horizon LQR by finding the positive-definite solution P of the Algebraic Riccati Equation, computing the optimal gain K=R⁻¹B^T P, and verifying closed-loop stability by checking that A−BK has all eigenvalues in the left half-plane; design a Kalman-Bucy filter for a given linear system with process and measurement noise covariances Q_w and R_v, and verify the separation principle by combining filter and regulator; or formulate and solve a constrained MPC problem for a simple integrator or double-integrator plant with input and state constraints, specifying the finite-horizon quadratic program and discussing the stability terminal-constraint",
            successCriteria: "Optimal control assignment completed (Pontryagin PMP applied with Hamiltonian, costate equations, and bang-bang law derived; or LQR Riccati equation solved with gain K computed and closed-loop eigenvalues verified; or Kalman-Bucy filter gain designed with separation principle verified; or MPC QP formulated with constraint handling described, with all derivations and numerical results saved to file)",
            preferredDuration: 60 * 60
        ),
        // rocketpropulsion
        SuggestedTemplate(
            icon: "flame.fill",
            task: "Study rocket propulsion for my exam — review rocket fundamentals (thrust equation T=ṁ_e v_e + (p_e−p_a)A_e; specific impulse I_sp = T/(ṁ g_0); effective exhaust velocity c = I_sp g_0; mass flow rate continuity; Tsiolkovsky rocket equation Δv = c ln(m_0/m_f); staging and mass fractions; payload ratio and structural coefficient), nozzle thermodynamics and design (isentropic flow relations; area-Mach number relation; throat conditions; de Laval nozzle geometry; exit area ratio A_e/A*; thrust coefficient C_F; overexpanded/underexpanded/optimally-expanded conditions; nozzle efficiency; bell vs. aerospike nozzle; divergence loss), propellant chemistry (liquid bipropellant: LOX/LH₂, LOX/RP-1, N₂O₄/UDMH; specific impulse and combustion temperature; oxidizer-to-fuel ratio; characteristic velocity c*; density specific impulse; solid propellant: HTPB/AP/Al grain; burn rate regression r=aP^n; regression rate and chamber pressure relation; monopropellant: hydrazine decomposition; green propellants), and electric propulsion (specific impulse advantage; ion thruster: acceleration voltage and I_sp = √(2eV/m_i)/g_0; Hall-effect thruster; resistojet; power-to-thrust ratio; mission applicability)",
            successCriteria: "Rocket propulsion study session completed (at least two topics reviewed with thrust equation written, I_sp definition stated, Tsiolkovsky equation derived, throat-condition isentropic relations applied, C_F definition stated, one bipropellant pair named with approximate I_sp given, solid propellant burn rate law written, ion thruster I_sp equation stated, and key equations saved to study notes)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "flame.fill",
            task: "Work on my rocket propulsion assignment — apply the Tsiolkovsky rocket equation to a multi-stage vehicle: given structural coefficients, propellant mass fractions, and individual stage I_sp values, compute the total ΔV and optimize staging for a given payload fraction; design a de Laval nozzle for a given chamber pressure, chamber temperature, propellant molecular weight, and γ: compute the throat and exit areas for sea-level and vacuum adaptation, the expansion ratio A_e/A*, the thrust coefficient C_F, and the vacuum specific impulse; analyze a solid propellant grain to determine the burn rate at a given chamber pressure using Saint-Robert's law r=aP^n, compute the mass flow rate, chamber pressure evolution, and burn time; compare LOX/LH₂ and LOX/RP-1 bipropellant combinations at the same chamber pressure and expansion ratio by computing characteristic velocity c*, C_F, and I_sp using the CEA approach or equilibrium chemistry tables; or estimate the ΔV budget and wet/dry mass of an ion-propulsion spacecraft given thrust, I_sp, power, and mission duration",
            successCriteria: "Rocket propulsion assignment completed (multi-stage Tsiolkovsky ΔV computed with optimal staging determined, nozzle geometry designed with C_F and I_sp calculated, solid grain burn rate and chamber pressure evolution analyzed, bipropellant c* and I_sp compared, or ion spacecraft ΔV budget and mass fraction computed, with derivations and numerical results saved to file)",
            preferredDuration: 60 * 60
        ),
        // reliabilityengineering
        SuggestedTemplate(
            icon: "chart.line.uptrend.xyaxis",
            task: "Study reliability engineering for my exam — review reliability fundamentals (reliability function R(t); failure density f(t); hazard rate h(t)=f(t)/R(t); bathtub curve (infant mortality, useful life, wear-out phases); MTBF; MTTF; MTTR; availability A=MTTF/(MTTF+MTTR); exponential failure model: constant hazard rate, R(t)=e^{−λt}, MTTF=1/λ), Weibull distribution (two-parameter and three-parameter forms; shape parameter β: β<1 infant mortality, β=1 exponential, β>1 wear-out; scale parameter η; median life; characteristic life; Weibull probability plot; parameter estimation via least squares and MLE; confidence bounds), failure analysis methods (FMEA: failure modes, effects, and criticality; severity/occurrence/detection ratings; RPN; FMECA extensions; fault tree analysis (FTA): AND/OR gates; minimal cut sets; top-event probability; quantitative vs. qualitative FTA), system reliability (series and parallel configurations; R_series = ∏R_i; R_parallel = 1−∏(1−R_i); k-out-of-n systems; redundancy strategies: active, standby; common-cause failure; importance measures: Birnbaum, RAW, RRW), and accelerated life testing (ALT: Arrhenius model for temperature acceleration; Eyring model; inverse power law; acceleration factor AF; test-to-field time translation; censored data and statistical analysis of field returns)",
            successCriteria: "Reliability engineering study session completed (at least two topics reviewed with R(t) and h(t) relationship derived, bathtub curve phases labeled, exponential MTTF=1/λ stated, Weibull β interpretation explained, FMEA RPN formula written, FTA AND/OR gate probability formulas stated, series vs. parallel reliability formulas compared, and Arrhenius acceleration factor formula saved to study notes)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "chart.line.uptrend.xyaxis",
            task: "Work on my reliability engineering assignment — fit a Weibull distribution to a given failure dataset using a Weibull probability plot (compute median ranks, plot on Weibull paper, estimate β and η by linear regression, and interpret the shape parameter to identify the failure mode); construct and quantify a fault tree for a given system: identify the top event, define intermediate events and basic failure events, assign failure probabilities, compute the top-event probability using Boolean algebra and minimal cut sets, and compare to Monte Carlo simulation; perform a failure modes and effects analysis (FMEA) for a given component or subsystem, assign severity, occurrence, and detection ratings, compute RPN scores, and prioritize corrective actions; compute the system reliability at a given mission time for a series-parallel system with given component reliabilities and identify the minimum-reliability bottleneck; or design an accelerated life test using the Arrhenius model for a given activation energy and temperature test levels, compute acceleration factors, and estimate the B10 life at the use condition from accelerated test data",
            successCriteria: "Reliability engineering assignment completed (Weibull β and η estimated from probability plot with failure mode identified, fault tree top-event probability computed via minimal cut sets, FMEA RPN scores computed with top risks prioritized, series-parallel system reliability calculated at mission time, or Arrhenius acceleration factor computed with B10 life estimated at use condition, with all calculations and plots saved to file)",
            preferredDuration: 60 * 60
        ),
        // measuretheory
        SuggestedTemplate(
            icon: "function",
            task: "Study measure theory for my exam — review sigma-algebras (definition; closure under complements and countable unions; generated sigma-algebra σ(𝒞); Borel sigma-algebra ℬ(ℝ) generated by open sets; measurable spaces (X,𝒜)), measure theory fundamentals (measure μ: non-negativity, countable additivity, μ(∅)=0; probability measures; Lebesgue measure λ on ℝ: translation invariance, regularity; outer measure and Carathéodory extension theorem; Hausdorff measure H^s and Hausdorff dimension), measurable functions (definition; continuous ⟹ measurable; composition of measurable functions; pointwise limits of measurable functions are measurable; simple functions and their approximation of non-negative measurables), Lebesgue integration (integral of simple functions; monotone convergence theorem; Fatou's lemma; dominated convergence theorem; comparison to Riemann integral; null sets and almost-everywhere), and classical results (Radon-Nikodym theorem; absolute continuity μ≪ν; Hahn decomposition; Jordan decomposition; L^p spaces: Hölder's inequality, Minkowski's inequality, completeness (Riesz-Fischer); Fubini-Tonelli theorem for product measures)",
            successCriteria: "Measure theory study session completed (at least two topics reviewed with sigma-algebra closure properties stated, Lebesgue measure defined and compared to Riemann, Carathéodory extension theorem stated, MCT and DCT conditions listed, Radon-Nikodym statement written, L^p Hölder inequality stated, and key definitions saved to study notes)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "function",
            task: "Work on my measure theory problem set — prove or disprove that a given collection of subsets forms a sigma-algebra (check closure under complement and countable unions; identify the smallest sigma-algebra containing the collection); compute the Lebesgue measure of a given set (use regularity, translation invariance, and countable additivity; handle Cantor sets by showing measure zero); show that a given function is measurable by verifying preimages of Borel sets lie in the sigma-algebra; evaluate a Lebesgue integral of a given non-negative function using monotone convergence or dominated convergence (construct an approximating sequence of simple functions, take the limit, verify uniform domination for DCT); prove the Radon-Nikodym theorem for a given pair of measures (show μ≪ν, construct the Radon-Nikodym derivative dμ/dν, verify the integral identity); or prove that a given function space is complete by showing every Cauchy sequence in L^p converges to an L^p function using Riesz-Fischer",
            successCriteria: "Measure theory problem set completed (sigma-algebra membership verified or disproved with closure properties checked, Lebesgue measure computed for given set with steps shown, measurability verified via preimage argument, Lebesgue integral evaluated via MCT or DCT with dominating function identified, Radon-Nikodym derivative constructed and verified, or L^p Cauchy sequence convergence proven, with all proofs written in complete mathematical notation and saved to file)",
            preferredDuration: 90 * 60
        ),
        // algebraictopology
        SuggestedTemplate(
            icon: "circles.hexagonpath",
            task: "Study algebraic topology for my exam — review homotopy theory (homotopy between maps; homotopy equivalence; deformation retracts; contractible spaces; fundamental group π₁(X,x₀): definition via loops; group structure by concatenation; dependence on base point; simply connected spaces: S^n for n≥2, ℝ^n; π₁(S¹)≅ℤ), van Kampen theorem and covering spaces (Seifert-van Kampen theorem: π₁(A∪B,x₀) ≅ π₁(A,x₀) *_{π₁(A∩B)} π₁(B,x₀); applications to wedge sums, torus, Klein bottle; covering spaces: covering map; universal cover; deck transformations; correspondence between subgroups of π₁ and covers), CW complexes (cell attachment; CW structure of S^n, RP^n, T², K; Euler characteristic χ=V−E+F), homology (singular homology H_n(X); chain complex; boundary operator ∂; cycle and boundary groups; relative homology; Mayer-Vietoris sequence; long exact sequence of a pair; Brouwer fixed-point theorem; invariance of domain), and cohomology (singular cohomology H^n(X;G); universal coefficients theorem; cup product; Poincaré duality for closed orientable manifolds; de Rham cohomology identification for smooth manifolds; Betti numbers b_k=rank H_k)",
            successCriteria: "Algebraic topology study session completed (at least two topics reviewed with π₁(S¹)≅ℤ stated and proven via covering map, van Kampen statement written with amalgamated product form, CW Euler characteristic computed for at least one space, Mayer-Vietoris sequence written out, Brouwer fixed-point theorem stated, and key homology groups H_n(S^k) listed and saved to study notes)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "circles.hexagonpath",
            task: "Work on my algebraic topology assignment — compute the fundamental group of a given space using van Kampen's theorem (identify the open cover A, B and their intersection, read off generators and relations, simplify the amalgamated free product); classify covering spaces of a given base space by listing subgroups of π₁(B) up to conjugacy (construct the universal cover, identify deck transformations, describe the corresponding covers); compute singular homology groups H_n(X) for a given CW complex (build the cellular chain complex, write boundary matrices, compute kernels and images, apply the structure theorem to identify ℤ, ℤ/mℤ summands); apply the Mayer-Vietoris sequence to compute homology of a space expressed as a union (identify the two open sets, write the sequence, chase the maps, resolve exactness); or prove or disprove that two given spaces are homotopy equivalent (compute invariants: fundamental group, homology groups, Euler characteristic; show maps realizing the equivalence or find an invariant that distinguishes them)",
            successCriteria: "Algebraic topology assignment completed (fundamental group computed via van Kampen with generators and relations simplified, covering spaces classified by π₁ subgroup lattice, cellular chain complex built and H_n computed with torsion identified, Mayer-Vietoris sequence chased with boundary map computed, or homotopy type distinguished by homological invariant, with all proofs written in complete notation and saved to file)",
            preferredDuration: 90 * 60
        ),
        // numbertheory
        SuggestedTemplate(
            icon: "number",
            task: "Study number theory for my exam — review divisibility and primes (division algorithm; gcd and lcm; Euclidean algorithm and extended Euclidean; Bézout's identity; unique factorization theorem; infinitely many primes (Euclid's proof); prime counting function π(x) and prime number theorem π(x)~x/ln(x)); modular arithmetic (congruence classes ℤ/nℤ; Chinese remainder theorem: system x≡a_i (mod n_i) with pairwise coprime n_i; Fermat's little theorem: a^p≡a (mod p); Euler's theorem: a^{φ(n)}≡1 (mod n) when gcd(a,n)=1; Euler's totient function φ: multiplicativity, formula φ(n)=n∏(1−1/p)); quadratic residues (Legendre symbol (a/p); quadratic reciprocity law; Euler's criterion a^{(p-1)/2}≡(a/p) (mod p); Jacobi symbol extension; quadratic congruences x²≡a (mod p) and mod prime powers); primitive roots (definition; order of an element mod n; primitive root theorem: ℤ/pℤ* cyclic; existence for p, 2p^k, 2, 4; discrete logarithm); and arithmetic functions (multiplicative functions; Möbius function μ; Möbius inversion; Liouville function λ; Dirichlet series and formal convolution; sum formulas ∑_{d|n} φ(d)=n)",
            successCriteria: "Number theory study session completed (at least two topics reviewed with Euclidean algorithm traced for a specific gcd, CRT solution written for a sample system, Fermat's little theorem applied to compute a^{p-1} mod p, Euler totient computed for a specific n, Legendre symbol evaluated via Euler's criterion, primitive root identified for a small prime, and Möbius function values listed and saved to study notes)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "number",
            task: "Work on my number theory problem set — solve a system of simultaneous congruences using the Chinese remainder theorem (verify pairwise coprimality, compute each modular inverse, assemble the solution and verify mod n₁n₂…n_k); apply Fermat's little theorem or Euler's theorem to simplify a large power a^k mod n (factor n, compute φ(n), reduce the exponent mod φ(n), handle edge cases gcd(a,n)>1); determine whether a given integer a is a quadratic residue mod a prime p (compute the Legendre symbol via Euler's criterion a^{(p-1)/2} mod p; apply quadratic reciprocity to evaluate (p/q)(q/p) for odd primes; find square roots of a mod p when they exist using the Tonelli-Shanks algorithm); find a primitive root mod p for a given prime (factor p−1, test candidate generators by verifying g^{(p-1)/q}≢1 (mod p) for each prime factor q of p−1); or prove a Diophantine equation has no solutions using modular arithmetic or infinite descent (show the equation forces a contradiction mod some n, or derive an infinite decreasing sequence of positive-integer solutions)",
            successCriteria: "Number theory problem set completed (CRT solution assembled and verified, Fermat/Euler exponent reduction applied with φ(n) computed, Legendre symbol evaluated via Euler criterion and quadratic reciprocity applied, primitive root found with order verified at each prime factor of p−1, or Diophantine no-solution proof completed via modular argument or descent, with all steps written in complete notation and saved to file)",
            preferredDuration: 90 * 60
        ),
        // orthopedicsrotation
        SuggestedTemplate(
            icon: "figure.walk",
            task: "Write up my orthopedics rotation notes and case presentations — complete SOAP notes or H&P for each ortho patient seen today (chief complaint, mechanism of injury, neurovascular exam, imaging findings, diagnosis, treatment plan including weight-bearing status, immobilization, or surgical indication); write a formal case presentation for a fracture or MSK case (summarize mechanism, classify the fracture using AO/OTA or relevant system, describe radiographic findings, outline non-operative vs. operative management with indications, and list anticipated follow-up milestones); review operative cases from the day (procedure performed, approach, fixation construct or implant used, post-op weight-bearing protocol, and complications to watch for); complete any required ortho clerkship feedback forms or portfolio entries; or prepare a focused teaching presentation on a common ortho topic (rotator cuff tears, ACL reconstruction, hip fracture management, or hand/wrist injuries)",
            successCriteria: "Orthopedics rotation write-up completed (SOAP/H&P notes finalized for each patient seen, fracture classification documented with AO/OTA system applied, operative report reviewed and key steps recorded, clerkship portfolio or case log updated, or teaching presentation outline completed with management algorithm and post-op protocol saved to file)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "figure.walk",
            task: "Study orthopedics for my shelf exam — review fracture management principles (fracture classification systems: AO/OTA long bone, Garden for hip, Neer for proximal humerus, Schatzker for tibial plateau; closed vs. open fracture management: Gustilo-Anderson classification, timing of debridement and IV antibiotics; reduction principles: traction, angulation correction, rotation; immobilization: casting, splinting, traction; operative indications: ORIF, IM nailing, external fixation; compartment syndrome: clinical signs, pressure threshold, fasciotomy), common ortho conditions (osteoarthritis: Kellgren-Lawrence grading, TKA and THA indications; rotator cuff: tear classification, physical exam tests — Neer, Hawkins, empty can, drop arm; ACL tear: Lachman, anterior drawer, pivot shift; meniscus tear: McMurray, Thessaly; carpal tunnel syndrome: Phalen's, Tinel's; hip fracture: Garden classification, fixation vs. arthroplasty by displacement and age), and pediatric ortho (physeal fractures: Salter-Harris I–V; Legg-Calvé-Perthes; slipped capital femoral epiphysis: Southwick angle; developmental dysplasia of the hip; scoliosis: Cobb angle, Risser staging)",
            successCriteria: "Orthopedics shelf study session completed (at least two topics reviewed with AO/OTA classification applied to a sample fracture, Gustilo-Anderson open fracture grade assigned, compartment syndrome fasciotomy threshold stated, rotator cuff special tests named with maneuver described, ACL Lachman and pivot shift explained, Salter-Harris classification drawn and described, and key shelf exam facts saved to study notes)",
            preferredDuration: 60 * 60
        ),
        // cardiologyrotation
        SuggestedTemplate(
            icon: "heart.fill",
            task: "Write up my cardiology rotation notes and case presentations — complete SOAP notes or H&P for each cardiology patient seen today (chief complaint, cardiac history, relevant medications including anticoagulation and antiarrhythmics, EKG interpretation, echo findings, cardiac biomarkers, diagnosis, and management plan); write a formal case presentation for a cardiology admission (ACS, heart failure exacerbation, arrhythmia, or valvular disease — summarize presentation, review EKG for rate/rhythm/axis/intervals/ST changes, describe echo parameters including EF and wall motion, outline guideline-directed medical therapy or procedural plan); review cath lab cases from the day (coronary anatomy, stenosis location and severity, PCI procedure performed, stent type, and post-procedure antiplatelet regimen); complete any required cardiology clerkship feedback forms or procedure logs; or prepare a focused teaching presentation on a common cardiology topic (STEMI management, heart failure with reduced EF, atrial fibrillation rate vs. rhythm control, or hypertensive emergency)",
            successCriteria: "Cardiology rotation write-up completed (SOAP/H&P notes finalized for each patient with EKG interpretation documented, echo parameters including EF recorded, cath lab procedure and stent details noted, clerkship portfolio or procedure log updated, or teaching presentation outline completed with guideline-directed management algorithm saved to file)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "heart.fill",
            task: "Study cardiology for my shelf exam — review ACS management (STEMI: EKG criteria (≥1mm ST elevation in ≥2 contiguous leads or new LBBB), door-to-balloon time <90 min, primary PCI vs. fibrinolysis indications, antiplatelet and anticoagulation regimens, post-MI medications: aspirin, P2Y12 inhibitor, statin, ACE-I/ARB, beta-blocker; NSTEMI/UA: TIMI risk score, early invasive vs. conservative strategy, fondaparinux vs. heparin); heart failure (HFrEF: EF<40%, GDMT — ACE-I/ARB/ARNI + beta-blocker + MRA + SGLT2i; HFpEF: EF≥50%, diuresis and comorbidity management; Framingham criteria; NYHA class; BNP/NT-proBNP; decompensated HF: diuresis, afterload reduction, vasodilators; cardiogenic shock: PA catheter wedge pressure, CI, vasopressors vs. inotropes); arrhythmias (AFib: rate vs. rhythm control, CHA₂DS₂-VASc score, anticoagulation choice — DOAC vs. warfarin; SVT: adenosine termination; VT: amiodarone, cardioversion, ICD indications; Brugada, LQTS, WPW); and valvular disease (aortic stenosis: murmur, valve area <1.0 cm², AVR vs. TAVR; mitral regurgitation: severity grading, surgical vs. MitraClip; echocardiography: EF estimation, diastolic function grading, wall motion abnormalities)",
            successCriteria: "Cardiology shelf study session completed (at least two topics reviewed with STEMI EKG criteria stated and door-to-balloon time cited, GDMT for HFrEF four-drug classes listed, CHA₂DS₂-VASc score calculated for a sample patient, AFib rate vs. rhythm control indications compared, aortic stenosis valve area threshold stated, and key shelf exam facts saved to study notes)",
            preferredDuration: 60 * 60
        ),
        // nephrologyrotation
        SuggestedTemplate(
            icon: "drop.fill",
            task: "Write up my nephrology rotation notes and case presentations — complete SOAP notes or H&P for each renal patient seen today (chief complaint, relevant history including CKD stage or AKI timeline, renal function trends: creatinine/BUN/GFR, electrolyte abnormalities, urine studies: UA, urine protein-to-creatinine ratio, urine electrolytes; diagnosis and nephrology management plan); write a formal presentation for a nephrology admission (AKI: prerenal vs. intrinsic vs. postrenal — FENa, urine osmolality, urine sodium, BUN/Cr ratio; CKD: staging by GFR and albuminuria, complications — anemia of CKD, renal osteodystrophy, metabolic acidosis, hyperkalemia; glomerulonephritis: nephritic vs. nephrotic pattern, ANCA/anti-GBM/complement workup; dialysis: HD vs. PD indications, access, adequacy); review renal biopsy findings if applicable; or complete nephrology clerkship procedure logs and feedback forms",
            successCriteria: "Nephrology rotation write-up completed (SOAP/H&P notes finalized for each patient with creatinine trend documented, AKI stage assigned using KDIGO criteria or CKD stage confirmed by GFR and albuminuria, key urine study results recorded, nephrology management plan written including any dialysis details, and clerkship portfolio updated)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "drop.fill",
            task: "Study nephrology for my shelf exam — review AKI management (prerenal: BUN/Cr >20, FENa <1%, low urine sodium, IV fluids; intrinsic: ATN most common — FENa >2%, granular casts, muddy brown casts, myoglobinuria in rhabdomyolysis; postrenal: bladder outlet obstruction, hydronephrosis on ultrasound; KDIGO AKI staging by creatinine and urine output; RIFLE criteria); CKD staging (GFR categories G1–G5 + albuminuria A1–A3; complications: anemia — EPO deficiency, treat with ESA; hyperkalemia — dietary restriction, sodium bicarbonate, fludrocortisone, loop diuretics, dialysis; metabolic acidosis — sodium bicarbonate; renal osteodystrophy — vitamin D, phosphate binders; hypertension — ACE-I/ARB first-line for proteinuric CKD); glomerulonephritis (nephrotic syndrome: FSGS, MCD, membranous, diabetic nephropathy — hypoalbuminemia, proteinuria >3.5g/day, edema, hyperlipidemia; nephritic syndrome: IgA nephropathy, post-strep GN, MPGN, ANCA vasculitis, anti-GBM/Goodpasture — hematuria, red blood cell casts, hypertension, proteinuria); and dialysis indications (AEIOU: Acidosis refractory, Electrolyte disturbance refractory, Intoxication, Overload refractory, Uremic symptoms)",
            successCriteria: "Nephrology shelf study session completed (at least two topics reviewed with KDIGO AKI staging criteria stated, FENa cutoffs applied to a prerenal vs. ATN case, CKD complication management outlined for anemia and hyperkalemia, nephrotic vs. nephritic syndrome distinguished with key lab findings, dialysis indications listed using AEIOU mnemonic, and key shelf exam facts saved to study notes)",
            preferredDuration: 60 * 60
        ),
        // endocrinologyrotation
        SuggestedTemplate(
            icon: "cross.case.fill",
            task: "Write up my endocrinology rotation notes and case presentations — complete SOAP notes or H&P for each endocrine patient seen today (chief complaint, relevant history, pertinent hormone labs: TSH/free T4, cortisol/ACTH, HbA1c/fasting glucose, IGF-1/GH, PTH/calcium, aldosterone/renin; diagnosis and endocrinology management plan); write a formal presentation for an endocrinology admission (diabetes: type 1 vs. type 2 management, DKA vs. HHS — glucose, osmolality, pH, anion gap, ketones; thyroid: hypothyroidism — TSH elevated, free T4 low, levothyroxine dosing; hyperthyroidism — TSH suppressed, Graves' antibody, RAI vs. antithyroid drugs vs. surgery; thyroid nodule workup — ultrasound characteristics, FNA criteria, Bethesda classification; adrenal: Cushing's syndrome workup — 24h urine cortisol, low-dose dexamethasone suppression test, ACTH level; adrenal insufficiency — cosyntropin stimulation test, hydrocortisone replacement; pheochromocytoma — plasma metanephrines; primary hyperaldosteronism — aldosterone-to-renin ratio); or complete endocrinology clerkship logs",
            successCriteria: "Endocrinology rotation write-up completed (SOAP/H&P notes finalized for each patient with relevant hormone labs documented, diagnosis confirmed with correct diagnostic criteria cited, management plan written with medication doses or procedural plan noted, and clerkship portfolio updated)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "cross.case.fill",
            task: "Study endocrinology for my shelf exam — review diabetes management (type 1: insulin regimens — basal-bolus, carb counting, sick day rules; type 2: metformin first-line, SGLT2i/GLP-1 RA for CV or renal benefit, insulin when HbA1c uncontrolled; DKA: glucose >250, pH <7.3, bicarbonate <15, anion gap metabolic acidosis, ketonemia, IV fluids + insulin drip, potassium replacement; HHS: glucose >600, hyperosmolar, minimal ketosis, IV fluids); thyroid disease (hypothyroidism: primary — elevated TSH, low free T4, levothyroxine 1.6 mcg/kg/day; subclinical — TSH 4-10 with normal free T4; Hashimoto's — anti-TPO antibody; hyperthyroidism: Graves' — TSI antibody, exophthalmos, pretibial myxedema; toxic nodular goiter; thyroid storm — high-dose PTU, propranolol, iodine, steroids; thyroid cancer: papillary most common, total thyroidectomy); adrenal disorders (Cushing's: obesity, buffalo hump, striae, HTN, hyperglycemia; workup: 1mg overnight DST then 24h urine cortisol, ACTH level, pituitary vs. ectopic vs. adrenal source; Addison's: cosyntropin stim test, fludrocortisone + hydrocortisone; primary hyperaldosteronism: HTN + hypokalemia, ARR >30, adrenal CT, AVS); and calcium (hyperparathyroidism: elevated PTH + calcium, osteoporosis, renal stones, parathyroidectomy indications)",
            successCriteria: "Endocrinology shelf study session completed (at least two topics reviewed with DKA diagnostic criteria stated and insulin drip protocol outlined, thyroid workup algorithm applied to a sample patient, Cushing's workup sequence described step-by-step, primary hyperaldosteronism ARR threshold stated, and key shelf exam facts saved to study notes)",
            preferredDuration: 60 * 60
        ),
        // hematologyoncology
        SuggestedTemplate(
            icon: "cross.vial.fill",
            task: "Write up my hematology oncology rotation notes and case presentations — complete SOAP notes or H&P for each heme/onc patient seen today (chief complaint, relevant oncology history including cancer type/stage/prior treatment lines, pertinent labs: CBC with differential, peripheral blood smear, LDH, uric acid, tumor markers, flow cytometry results; current treatment regimen and cycle; diagnosis and management plan); write a formal presentation for a heme/onc admission (AML/ALL: bone marrow biopsy blast percentage, cytogenetics/molecular markers: FLT3, NPM1, BCR-ABL, FISH results; induction regimen chosen; CML: BCR-ABL p210, TKI selection — imatinib vs. dasatinib vs. ponatinib; lymphoma: Hodgkin vs. NHL — Ann Arbor staging, PET-CT response, R-CHOP vs. ABVD; multiple myeloma: CRAB criteria, SPEP/immunofixation, bone marrow plasma cell percentage, ISS stage, VRd regimen); review bone marrow biopsy or peripheral smear findings; or complete heme/onc clerkship procedure logs",
            successCriteria: "Hematology oncology rotation write-up completed (SOAP/H&P notes finalized for each patient with CBC differential trends documented, cancer type and current treatment cycle recorded, bone marrow or flow cytometry result interpretation noted, management plan written with any chemotherapy cycle details, and clerkship portfolio updated)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "cross.vial.fill",
            task: "Study hematology oncology for my shelf exam — review leukemias (AML: >20% blasts in bone marrow, Auer rods on smear, induction with 7+3 cytarabine/anthracycline, good risk: CBF-AML; ALL: TdT positive, lymphoblasts, Ph+ ALL treat with TKI, CNS prophylaxis; CML: BCR-ABL p210, Philadelphia chromosome t(9;22), imatinib/dasatinib first-line TKI, blast crisis; CLL: CD5+/CD19+/CD23+ B-cells, smudge cells on smear, Rai/Binet staging, watch-and-wait vs. ibrutinib/venetoclax); lymphomas (Hodgkin: Reed-Sternberg cells, bimodal age distribution, B symptoms, Ann Arbor staging, ABVD chemotherapy; NHL: DLBCL most common — R-CHOP; follicular lymphoma — indolent, grade 1-3A, rituximab; Burkitt — c-MYC translocation, starry-sky pattern, highly aggressive); multiple myeloma (CRAB: hyperCalcemia, Renal failure, Anemia, Bone lesions; SPEP M-spike, Bence-Jones protein, bone marrow >10% plasma cells; ISS staging; VRd induction; stem cell transplant eligibility); coagulation (DIC: prolonged PT/PTT, low fibrinogen, elevated D-dimer, schistocytes; TTP: ADAMTS13 deficiency, thrombocytopenia, MAHA, fever, renal failure, neurologic — treat with PLEX; ITP: isolated thrombocytopenia, IVIG or steroids); and iron-deficiency vs. thalassemia vs. ACD on CBC",
            successCriteria: "Hematology oncology shelf study session completed (at least two topics reviewed with AML vs. ALL key distinguishing features stated, Hodgkin vs. NHL distinguishing pathology described, CRAB criteria for myeloma listed, DIC vs. TTP differentiated by lab pattern, and key shelf exam facts saved to study notes)",
            preferredDuration: 60 * 60
        ),
        // advancedlinearalgebra
        SuggestedTemplate(
            icon: "function",
            task: "Study advanced linear algebra for my exam — review Jordan canonical form (minimal polynomial, characteristic polynomial, Jordan blocks, Jordan normal form theorem: every matrix over algebraically closed field is similar to its Jordan form; finding Jordan basis; matrix of nilpotent operator; generalized eigenvectors and Jordan chains; example: find JNF and Jordan basis for 4x4 nilpotent matrix), spectral theorem (self-adjoint operators on inner product spaces: real eigenvalues, orthogonal eigenvectors for distinct eigenvalues; spectral decomposition; orthonormal basis of eigenvectors for symmetric/Hermitian matrices; normal matrices: A*A = AA*, unitary diagonalizable; singular value decomposition from spectral theorem applied to A*A), dual spaces and bilinear forms (dual space V*, natural pairing, double dual V**, transpose/adjoint; bilinear forms: symmetric, skew-symmetric, Hermitian; matrix of a bilinear form; congruence of matrices; Sylvester's law of inertia; signature; Gram matrix; positive definite forms), and tensor products (universal property of tensor product V⊗W; rank-1 tensors; dimension formula; multilinear maps factoring through tensor product; tensor product of linear maps; relation to Kronecker product for matrices)",
            successCriteria: "Advanced linear algebra study session completed (at least two topics reviewed with Jordan block structure drawn for a sample minimal polynomial, spectral decomposition stated for a symmetric matrix, Sylvester's law of inertia applied to a bilinear form to find signature, dual basis defined and computed for a sample basis, and key exam facts saved to study notes)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "function",
            task: "Complete my advanced linear algebra problem set — problems may include: finding the Jordan canonical form and Jordan basis for a given matrix (compute characteristic polynomial, factor over C, find minimal polynomial, determine Jordan block sizes from eigenspace dimensions, build Jordan chains); proving that a self-adjoint operator on a finite-dimensional inner product space is diagonalizable by an orthonormal basis and computing the spectral decomposition; computing the SVD of a given matrix (find A*A, diagonalize, take square roots of eigenvalues for singular values, build U and V from eigenvectors); showing the universal property of a tensor product (proving the existence of a bilinear map factoring uniquely through the tensor product); finding the signature of a bilinear form using Sylvester's law of inertia (bring the Gram matrix to diagonal form over R by congruence, count positive, negative, zero diagonal entries); or proving a stated theorem about dual spaces, adjoint maps, or the relationship between the trace and the sum of eigenvalues counted with multiplicity",
            successCriteria: "Advanced linear algebra problem set completed (each assigned problem attempted: JNF computed with Jordan basis constructed, spectral decomposition derived for self-adjoint operator, SVD factorization written out with singular values computed, bilinear form signature identified, and all solutions written up with full proofs or justifications saved to file)",
            preferredDuration: 90 * 60
        ),
        // neurologyrotation
        SuggestedTemplate(
            icon: "brain.head.profile",
            task: "Write my neurology rotation notes — complete SOAP or H&P documentation for today's cases (stroke, seizure, headache, movement disorder, or peripheral neuropathy), including chief complaint, HPI with timeline of neurological symptoms, relevant neuro exam findings (mental status, cranial nerves II-XII, motor strength by muscle group, sensory testing, cerebellar testing, reflexes, gait), pertinent diagnostic data (MRI/CT findings, EEG report, EMG/NCS results, lumbar puncture CSF analysis, NIHSS score for stroke), assessment and differential diagnosis with neuroanatomical localization, and plan with medication, monitoring, and disposition",
            successCriteria: "Neurology rotation notes completed (at least one full SOAP or H&P written with neuroanatomical localization documented, chief complaint and HPI recorded, neuro exam findings by domain listed, diagnostic results interpreted, assessment with localization-based differential written, and plan saved to EMR or notes file)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "brain.head.profile",
            task: "Study for my neurology shelf exam — review the major neurology topics: stroke and TIA (ischemic vs hemorrhagic, NIHSS, tPA eligibility criteria, ASPECT score, mechanical thrombectomy criteria, secondary prevention); seizure and epilepsy (classification, status epilepticus management, AED mechanisms and side effects); headache syndromes (migraine with vs without aura, cluster, tension-type, secondary causes: SAH vs thunderclap headache, IIH, temporal arteritis); movement disorders (Parkinson's disease: dopaminergic degeneration, bradykinesia/rigidity/resting tremor, L-dopa therapy; essential tremor; Huntington's; ataxia); dementia (Alzheimer's, Lewy body, frontotemporal, vascular, reversible causes: B12/thyroid/NPH); neuromuscular diseases (GBS: ascending weakness, albuminocytologic dissociation; myasthenia gravis: fatigable weakness, Tensilon test, crisis management; ALS: UMN+LMN signs); MS (optic neuritis, internuclear ophthalmoplegia, Uhthoff's, McDonald criteria, DMTs); and spinal cord syndromes (Brown-Séquard, central cord, anterior cord, conus vs cauda)",
            successCriteria: "Neurology shelf study session completed (at least three topic areas reviewed with key facts memorized: tPA eligibility criteria, status epilepticus treatment steps, migraine abortive and preventive agents, Parkinson's cardinal features, GBS vs MG distinguishing features, MS lesion dissemination criteria, and differential diagnosis for acute focal neurological deficit — with facts saved to study notes)",
            preferredDuration: 90 * 60
        ),
        // surgicalpathology
        SuggestedTemplate(
            icon: "doc.text.magnifyingglass",
            task: "Complete my surgical pathology rotation documentation — gross description of specimens received today (organ/tissue type, dimensions in three planes, weight if organ, color, consistency, margins, cut surface appearance, representative section sampling plan), microscopic review of H&E slides (tissue architecture, cell type, nuclear features: size/shape/chromatin pattern/nucleoli, mitotic rate, presence of necrosis/invasion/lymphovascular invasion, inflammatory infiltrate), correlation with IHC or special stains if applicable, formulation of the pathological diagnosis using WHO classification, and synoptic CAP protocol completion for tumor cases (histologic type, grade, margins, lymph node status, TNM staging, lymphovascular invasion, perineural invasion)",
            successCriteria: "Surgical pathology rotation documentation completed (at least one gross description written with measurements and sampling plan, H&E slide reviewed with nuclear and architectural features recorded, final diagnosis formulated using appropriate WHO classification, and synoptic CAP report completed with staging elements filled in — all saved to rotation case log or pathology report)",
            preferredDuration: 90 * 60
        ),
        SuggestedTemplate(
            icon: "doc.text.magnifyingglass",
            task: "Study surgical pathology for my rotation or board exam — review gross and microscopic features of the most high-yield entities: colon adenocarcinoma (polyp types: tubular/villous/tubulovillous, dysplasia grading, invasive adenocarcinoma: gland formation grading, microsatellite instability, Lynch syndrome, CAP synoptic elements), breast pathology (DCIS vs LCIS vs invasive ductal vs invasive lobular, Nottingham grading system: tubule formation + nuclear pleomorphism + mitotic rate, ER/PR/HER2 status, sentinel lymph node, margins), lung pathology (adenocarcinoma vs squamous vs small cell vs large cell, KRAS/EGFR/ALK/ROS1 mutations, IASLC/ATS/ERS adenocarcinoma classification, pleural invasion), prostate adenocarcinoma (Gleason pattern 1-5 and grade group 1-5, perineural invasion, seminal vesicle involvement), frozen section indications and limitations (intraoperative diagnosis, margin assessment, lymph node sampling), and quality metrics in surgical pathology (turn-around time, discordance rates)",
            successCriteria: "Surgical pathology study session completed (at least two tumor entities reviewed with gross and microscopic features memorized, grading systems applied correctly, CAP synoptic elements listed for a sample tumor type, frozen section limitations articulated, and key diagnostic criteria saved to study notes)",
            preferredDuration: 60 * 60
        ),
        // gametheory
        SuggestedTemplate(
            icon: "gamecontroller",
            task: "Study game theory for my exam — review the core concepts and solution concepts: normal form games (players, strategies, payoff functions, best response correspondence, iterated elimination of strictly dominated strategies, Nash equilibrium: existence via Kakutani fixed-point theorem, pure vs mixed strategy Nash equilibrium, expected payoff calculation for mixed strategies, zero-sum games: minimax theorem, saddle points), extensive form games (game tree, information sets, subgame perfect Nash equilibrium via backward induction, one-deviation property, rollback equilibrium), Bayesian games (types, beliefs, Bayesian Nash equilibrium, signaling games: separating vs pooling equilibria, Beer-Quiche game), repeated games (finitely repeated Prisoner's Dilemma: unraveling, infinitely repeated games, folk theorem, trigger strategies, grim trigger, tit-for-tat), and mechanism design (revelation principle, VCG mechanism, Myerson's optimal auction, incentive compatibility, individual rationality)",
            successCriteria: "Game theory study session completed (at least two solution concepts reviewed with examples solved: Nash equilibrium computed for a 2×2 matrix game with pure and mixed strategies, backward induction applied to a 3-stage extensive form game, Bayesian Nash equilibrium stated for a signaling game, folk theorem conditions listed for infinitely repeated game, and key facts saved to study notes)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "gamecontroller",
            task: "Complete my game theory problem set — problems may include: finding all Nash equilibria (pure and mixed) of a given normal form game (set up best response functions, find intersections; for mixed strategies, make opponent indifferent between pure strategies, solve for mixing probabilities, verify equilibrium conditions); solving an extensive form game by backward induction (identify terminal nodes, compute payoffs, apply backward induction for subgame perfect Nash equilibrium, check one-deviation property); finding a Bayesian Nash equilibrium in a static game of incomplete information (identify player types and prior beliefs, compute expected payoffs, find best responses as functions of type, solve for equilibrium strategies); analyzing a repeated game (show cooperation can be sustained by grim trigger if discount factor δ ≥ threshold: compute one-shot deviation payoff vs cooperation payoff, derive δ condition); or applying a mechanism design result (show VCG mechanism is incentive-compatible, compute optimal auction reserve price via Myerson's formula, or verify revelation principle for a specific mechanism)",
            successCriteria: "Game theory problem set completed (each assigned problem attempted: Nash equilibrium computed with work shown for best response functions, backward induction solution written out for extensive form game, Bayesian Nash equilibrium derived with type-contingent strategy profile, δ condition for cooperation derived for repeated game, and all solutions with full reasoning saved to file)",
            preferredDuration: 90 * 60
        ),
        // forensicchemistry
        SuggestedTemplate(
            icon: "flask",
            task: "Study forensic chemistry for my exam — review the analytical chemistry methods used in forensic laboratories: controlled substance identification (presumptive color tests: Marquis, Duquenois-Levine, Scott, cobalt thiocyanate, para-dimethylaminobenzaldehyde; confirmatory methods: GC-MS, FTIR, LC-MS/MS; drug scheduling and structural analogs), arson and fire investigation (accelerant evidence collection, GC-MS headspace analysis, accelerant classification: petroleum distillates, oxygenated solvents, aromatic solvents, fire debris extraction methods: passive headspace concentration, dynamic headspace, solvent extraction), trace evidence analysis (glass fracture analysis: refractive index by GRIM3/oil immersion, elemental analysis by SEM-EDX; fiber analysis: polarized light microscopy, FTIR microspectroscopy, color comparison; paint analysis: physical fit, PDQ database, elemental analysis; GSR: SEM-EDX, primer components), toxicological chemistry in forensic context (blood alcohol: Henry's law, headspace GC, Widmark formula, retrograde extrapolation; drug detection windows by matrix: blood/urine/hair; immunoassay screening and GC-MS/LC-MS confirmation), and forensic serology (presumptive tests: Kastle-Meyer, Luminol; confirmatory: Ouchterlony, ABAcard; species determination: precipitin test)",
            successCriteria: "Forensic chemistry study session completed (at least two analytical method categories reviewed with presumptive and confirmatory tests named, GC-MS detection logic explained for drug identification and arson accelerants, trace evidence comparison criteria listed for glass/fiber/paint, Widmark formula applied to a sample calculation, and key exam facts saved to study notes)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "flask",
            task: "Complete my forensic chemistry lab report or assignment — this may include: interpreting GC-MS data for controlled substance identification (identify retention time, molecular ion [M+], base peak, fragmentation pattern, compare against NIST library for drug or arson accelerant classification), writing a full forensic chemistry bench report (evidence description, chain of custody, analytical methods performed, QC data: calibration curve, %RSD, LOD/LOQ, results with uncertainty, interpretation, opinion); solving quantitative forensic problems (blood alcohol: apply Widmark formula with volume of distribution, body weight factor r for male/female, number of drinks and time elapsed — calculate peak BAC, retrograde BAC at time of incident, or time to legal limit; drug concentration from LC-MS/MS quantitative data); interpreting trace evidence results (classify glass fragments by RI comparison to control, determine fiber type from PLM birefringence and sign of elongation, analyze paint layer sequence from SEM cross-section); or writing a method validation summary (linearity, accuracy, precision, specificity, LOD/LOQ per SWGTOX or SWGMAT guidelines)",
            successCriteria: "Forensic chemistry lab report or assignment completed (GC-MS spectrum interpreted with molecular ion and fragments identified, confirmatory classification written, bench report sections completed with QC data interpreted, quantitative calculation shown with Widmark or LC-MS/MS data, trace evidence comparison conclusion stated with scientific basis — all saved to course submission file)",
            preferredDuration: 90 * 60
        ),
        // neuropharmacology
        SuggestedTemplate(
            icon: "pills",
            task: "Study neuropharmacology for my exam — review CNS drug mechanisms organized by neurotransmitter system: dopamine system (D1–D5 receptor subtypes and signal transduction; antipsychotics: typical — D2 blockade, EPS, tardive dyskinesia; atypical — D2/5-HT2A balance, metabolic effects; Parkinson's pharmacotherapy: L-dopa/carbidopa, dopamine agonists, MAO-B inhibitors, COMT inhibitors, amantadine), serotonin system (5-HT1A–7 receptor subtypes; SSRIs: mechanism, SIADH, serotonin syndrome DDIs; SNRIs; TCAs: anticholinergic/antihistamine/alpha1 side effects; MAOIs: tyramine interaction; buspirone: 5-HT1A partial agonist), GABA system (GABA-A: chloride channel, BZD binding site, barbiturate binding site; benzodiazepines: mechanism, tolerance, withdrawal, overdose reversal with flumazenil; Z-drugs; GABA-B: baclofen), glutamate system (NMDA receptor: Mg2+ block, voltage-gated, Ca2+ influx; ketamine, memantine, PCP; AMPA receptor; mGluR subtypes), opioid system (mu/kappa/delta receptor G-protein coupling, endogenous opioids, morphine/fentanyl/methadone/buprenorphine pharmacokinetics, naloxone reversal, opioid tolerance mechanisms), and acetylcholine system in CNS (nicotinic and muscarinic pathways, Alzheimer's cholinergic hypothesis, AChE inhibitors: donepezil/rivastigmine, memantine for moderate-severe AD)",
            successCriteria: "Neuropharmacology study session completed (at least three neurotransmitter systems reviewed with receptor subtypes named, drug mechanisms explained at receptor level, key side effects linked to off-target receptor binding, and clinical comparisons written — e.g., typical vs atypical antipsychotic profiles, SSRI vs TCA vs MAOI, BZD vs barbiturate — with study notes saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "pills",
            task: "Complete my neuropharmacology problem set — problems may include: explaining the mechanism of action of a CNS drug at the molecular level (e.g., how SSRIs cause delayed therapeutic onset despite immediate SIRT block — autoreceptor desensitization hypothesis; how D2 antagonism produces both therapeutic antipsychotic effects and EPS — mesolimbic vs nigrostriatal pathway selectivity; how ketamine produces dissociative anesthesia via open-channel NMDA block vs Mg2+ block); predicting drug interactions based on receptor profiles (e.g., MAO-A inhibitor + tyramine-containing food → hypertensive crisis; SSRI + tramadol → serotonin syndrome risk — mechanism; benzodiazepine + alcohol → additive GABA-A potentiation — which binding sites); applying pharmacokinetic reasoning to clinical scenarios (opioid tolerance: receptor internalization and G-protein uncoupling explaining loss of analgesic effect; L-dopa CNS uptake: large neutral amino acid competition, dietary protein timing); or comparing drug classes (typical vs atypical antipsychotics: receptor binding affinities, EPS/TD risk, metabolic risk; BZDs vs Z-drugs: receptor subunit selectivity — α1 for hypnosis, α2/α3 for anxiolysis — pharmacokinetic differences; AChE inhibitors vs memantine: complementary mechanisms in Alzheimer's)",
            successCriteria: "Neuropharmacology problem set completed (each assigned problem attempted with receptor-level mechanism explained, pharmacokinetic or pharmacodynamic reasoning applied to clinical scenario, drug interaction mechanism identified from receptor profiles, and all solutions with supporting molecular rationale saved to file)",
            preferredDuration: 90 * 60
        ),
        // clinicaltoxicology
        SuggestedTemplate(
            icon: "cross.case",
            task: "Write clinical toxicology rotation notes — document my shift on the tox consult service or poison control center: patient presentation (ingestion/exposure history, timing, dose, coingestants, route, intentional vs accidental, vital signs, GCS), toxidrome identification (opioid: miosis, respiratory depression, CNS depression — antidote: naloxone 0.4–2 mg IV/IM/IN with repeat dosing; cholinergic: SLUDGE/DUMBELS mnemonics, bradycardia, lacrimation, urination, defecation, GI cramping, emesis — antidote: atropine titrated to secretions + pralidoxime within 24–48h of organophosphate; anticholinergic: mydriasis, tachycardia, dry flushed skin, hyperthermia, delirium, urinary retention — antidote: physostigmine with caution; sympathomimetic: mydriasis, tachycardia, hypertension, diaphoresis, hyperthermia; serotonin: tachycardia, diaphoresis, clonus, hyperthermia, altered mental status; sedative-hypnotic: CNS/respiratory depression without opioid signs — supportive care, flumazenil rarely indicated), management plan (activated charcoal indications/contraindications, whole bowel irrigation for sustained-release or heavy metals, enhanced elimination: urinary alkalinization for salicylates/herbicides, HD indications: methanol/ethylene glycol/lithium/salicylates — EXTRIP criteria), poison control communication and disposition plan",
            successCriteria: "Clinical toxicology rotation note completed (patient encounter documented with toxidrome correctly identified and antidote/management plan written, poison control consultation documented if applicable, enhanced elimination rationale stated, disposition documented — H&P or SOAP saved to rotation file)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "cross.case",
            task: "Study clinical toxicology for my shelf or certification — review high-yield toxicology: toxic alcohols (methanol/ethylene glycol: osmol gap, anion gap metabolic acidosis, optic nerve/renal toxicity — fomepizole vs ethanol competition; isopropanol: ketosis without acidosis, osmol gap); salicylates (early respiratory alkalosis then mixed disturbance, Done nomogram, urinary alkalinization with bicarbonate, HD for severe toxicity); acetaminophen (Rumack-Matthew nomogram, N-acetylcysteine within 8–10h, fulminant hepatic failure); tricyclic antidepressants (Na-channel blockade: QRS widening, hypotension, seizures — sodium bicarbonate, avoid physostigmine); beta-blocker/CCB toxicity (high-dose insulin euglycemia therapy, calcium, glucagon, lipid emulsion, VA-ECMO); carbon monoxide (cherry red skin unreliable, SpO2 unreliable, carboxyhemoglobin level, 100% O2, hyperbaric indications); cyanide (cellular hypoxia, hydroxocobalamin antidote); heavy metals (lead: dimercaprol/succimer; arsenic: dimercaprol; mercury: chelation); plant and mushroom toxins (Amanita phalloides: Amatoxin — delayed GI then liver failure — silibinin; Gyromitra: false morel — INH-like mechanism — pyridoxine)",
            successCriteria: "Clinical toxicology study session completed (at least three toxin categories reviewed with toxidrome signs, antidote/mechanism, and specific antidote dose or indication criteria noted — study notes saved for rotation shelf or ABEM/ABPM exam preparation)",
            preferredDuration: 90 * 60
        ),
        // globalenvironmentalgovernance
        SuggestedTemplate(
            icon: "globe.europe.africa",
            task: "Study global environmental governance and international environmental law for my exam — review the multilateral environmental agreement (MEA) system: UNEP structure and its role in launching MEA negotiations; biodiversity cluster (Convention on Biological Diversity/CBD: Nagoya Protocol on ABS — access and benefit sharing, genetic resources; CITES/Convention on International Trade in Endangered Species: appendix classification I/II/III, CITES permitting); chemicals and wastes cluster (Basel Convention on Hazardous Wastes: transboundary movement and disposal, prior informed consent, Bamako Convention extension to Africa; Rotterdam Convention on PIC — Prior Informed Consent — for hazardous chemicals and pesticides; Stockholm Convention on POPs — persistent organic pollutants: dirty dozen, global elimination schedules, exemptions); oceans governance (UNCLOS: EEZ, continental shelf, high seas, Area mining, BBNJ agreement — beyond national jurisdiction; London Protocol on ocean dumping); atmosphere beyond climate (Montreal Protocol: ozone-depleting substances, phaseout schedules, HFC Kigali Amendment, Multilateral Fund, technology transfer); global commons governance theory (common but differentiated responsibilities, CBDR-RC, common heritage of mankind, public goods framing); international institutions (IPBES — biodiversity science-policy interface parallel to IPCC; UNEA — UN Environment Assembly, UNEP member states; INC plastics treaty process); trade-environment interface (WTO and environmental exceptions: GATT Article XX, shrimp-turtle and tuna-dolphin cases, SPS/TBT agreements and environmental measures); compliance and dispute settlement in MEAs (non-compliance procedures, facilitative vs punitive branches, treaty bodies, reporting obligations)",
            successCriteria: "Global environmental governance study session completed (at least three MEA clusters reviewed with treaty names, key obligations, compliance mechanisms, and science-policy interface noted; CBDR principle explained; one WTO-environment trade case analyzed — study notes saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "globe.europe.africa",
            task: "Write my global environmental governance paper or assignment — this may include: analyzing a specific MEA's effectiveness (CBD implementation: Aichi Targets failure analysis, Kunming-Montreal GBF 30×30 targets, implementation gaps in developing countries, funding mechanism — GEF contributions; or Stockholm Convention effectiveness: POPs monitoring data, PTS and PFAS listing battles, Article 3 unintentional releases vs Article 6 disposal obligations); comparing treaty design choices (differentiated obligations in climate vs biodiversity: quantified targets vs qualitative commitments; Montreal Protocol vs Kyoto Protocol institutional design — why one succeeded; compliance mechanism design: facilitative-first in Basel vs enforcement-first in CITES appendix I listings); applying CBDR-RC to a case study (historical emissions responsibility, differential obligations, equity arguments in MEA negotiations, technology transfer provisions, Multilateral Fund as precedent); analyzing the trade-environment nexus (GATT Article XX(b)/(g) balancing test applied to a case: necessity test, chapeau requirements, disguised restriction — apply to a hypothetical eco-label scheme or import ban); or writing a policy memo on the BBNJ Agreement (high seas marine protected area establishment process, EIA requirements for ABNJ activities, benefit sharing for marine genetic resources, relationship to UNCLOS)",
            successCriteria: "Global environmental governance paper or assignment completed (thesis stated, relevant MEA treaty text cited, CBDR or compliance mechanism analysis incorporated, policy recommendations grounded in comparative treaty evidence — saved to course submission file)",
            preferredDuration: 90 * 60
        ),
        // corporatelaw
        SuggestedTemplate(
            icon: "building.2",
            task: "Study corporate law and business organizations for my exam — review the forms of business entities (sole proprietorship, general/limited partnership, LLC, corporation: formation, liability shield, management structure, tax treatment); corporate governance (board of directors: duty of care — BJR standard, gross negligence threshold, Smith v Van Gorkom; duty of loyalty — interested-director transactions, self-dealing, entire fairness review vs BJR; duty of good faith — Disney decision; shareholder derivative suits: standing, demand requirement, futility, SLC review); fiduciary duties in close corporations (oppression doctrine, reasonable expectations test, minority shareholder protections: buy-sell agreements, supermajority provisions, dissolution rights); M&A fundamentals (asset purchase vs stock purchase vs merger: tax and liability implications; triangular mergers: forward/reverse triangular; tender offer mechanics: Williams Act, 20-day offer period, best-price rule, SEC Schedule TO; freezeout mergers: entire fairness review for controlling shareholder transactions — Weinberger, MFW framework: dual committee and majority-of-minority vote for BJR protection); Delaware jurisprudence (Revlon duties: enhanced scrutiny when sale of company is inevitable — deal protections: matching rights, termination fees, no-shop provisions; Unocal/Unitrin: intermediate scrutiny for defensive measures — proportionality to threat; poison pill/rights plan structure and judicial treatment); LLC law (operating agreement flexibility, default rules, charging orders, management vs member-managed, statutory LLC in Delaware vs other jurisdictions)",
            successCriteria: "Corporate law study session completed (at least two governance standards reviewed with elements, cases, and applications identified; one M&A transaction structure analyzed with tax and liability treatment noted; fiduciary duty standards for BJR, entire fairness, and Revlon duties distinguished — study notes saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "building.2",
            task: "Complete my corporate law problem set or case analysis — problems may include: analyzing a board decision under the business judgment rule (identify whether duty of care, loyalty, or good faith is at issue; apply BJR vs entire fairness standard based on conflict; if director conflict present, determine if safe harbor under DGCL §144 available: disinterested director approval, informed shareholder ratification, or fair transaction; compute damages under entire fairness — fair dealing + fair price); evaluating a defensive measure under Unocal (identify the threat — coercive, structurally coercive, or just inadequate price; is response proportionate and within range of reasonableness; does poison pill or lockup implicate Revlon?); structuring an M&A transaction (recommend asset vs stock vs merger based on liability, tax basis step-up, third-party consents, tax treatment of gain recognition; or design a freezeout merger to comply with MFW — independent committee, majority of minority vote, full disclosure — to obtain BJR rather than entire fairness); analyzing an LLC operating agreement dispute (identify gap in operating agreement, apply state default rules, analyze charging order proceeding, evaluate dissolution claim for oppression or deadlock); or writing a memo on a derivative suit (demand futility analysis under Aronson test: independence of board, whether challenged transaction is result of valid exercise of business judgment — or Rales test when no board decision at issue; analyze SLC independence and good faith investigation)",
            successCriteria: "Corporate law problem set completed (each problem answered with governing standard identified — BJR, entire fairness, Unocal, Revlon, MFW — applicable facts mapped to elements, outcome stated with reasoning, and relevant case law cited — all solutions saved to course submission file)",
            preferredDuration: 90 * 60
        ),
        // taxlaw
        SuggestedTemplate(
            icon: "dollarsign.circle",
            task: "Study federal income tax law for my exam — review gross income and exclusions (IRC §61 broad definition: all income from whatever source derived; §102 gifts/inheritances excluded — donative intent test, Duberstein; §104 personal injury recoveries; §105/106 employer health benefits; §119 meals and lodging; §132 fringe benefits: no-additional-cost, qualified employee discount, working condition, de minimis; §117 scholarships and fellowship); deductions (§162 ordinary and necessary business expenses: Welch vs Helvering, travel and entertainment limits post-TCJA, home office §280A; §167/168 depreciation: MACRS, bonus depreciation §179; §212 investment expenses; §163 interest — SALT cap; §165 losses: hobby loss limits §183; §262 personal expenses not deductible; §274 meals/entertainment — 50% limit; above-the-line vs below-the-line deductions, standard deduction vs itemized); capital gains (§1221 capital asset definition, excluded assets; §1231 quasi-capital assets; §1245/1250 recapture; §1(h) preferential rates: 0%/15%/20%; §1014 stepped-up basis at death; §1015 gift basis carry-over and loss limitation; §1001 realization, recognition, §1031 like-kind exchange, §1033 involuntary conversion; installment sales §453); assignment of income doctrine (Lucas v Earl, Horst doctrine, anticipatory assignment); timing (annual accounting period, cash vs accrual methods, claim of right doctrine, tax benefit rule); corporate and pass-through taxation overview (C-corp double taxation, S-corp/partnership pass-through, §199A QBI deduction, §1202 QSBS exclusion)",
            successCriteria: "Federal income tax law study session completed (at least three IRC sections reviewed with statutory text interpreted, leading case applied, and hypothetical fact pattern analyzed; timing doctrine and capital gains characterization distinguished — study notes saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "dollarsign.circle",
            task: "Complete my tax law problem set or memo — problems may include: computing gross income from a transaction (determine if §61 income realized — Old Colony Trust, imputed income, below-market loans §7872, cancellation of debt income §108 and insolvency exclusion); determining the deductibility of a business expense (apply §162 ordinary and necessary test — capital expenditure vs current deduction: INDOPCO; startup costs §195; home office §280A and exclusive use test; meals 50% limitation); analyzing a capital asset transaction (classify property under §1221; compute adjusted basis; apply §1245/1250 recapture on depreciated property; determine §1231 gain/loss character; apply §1(h) preferential rate; analyze §1031 like-kind exchange — identify boot, compute realized/recognized gain, determine substituted basis in replacement property); applying assignment of income doctrine (determine who earns income — Lucas v Earl anticipatory assignment; Horst doctrine for transferred property rights; gift vs sale distinction); analyzing a fringe benefit for includability under §132 (apply each §132(a) exclusion in order; check whether no-additional-cost, qualified discount, working condition, or de minimis test is met; compute includable amount and W-2 reporting); or drafting a tax research memo (identify issue, relevant code sections, regulations — Treasury Regulations as interpretive authority, IRS guidance hierarchy: PLRs not precedential, Rev Ruls binding, cases from Tax Court, Circuit, and Supreme Court; present argument and counterargument with conclusion)",
            successCriteria: "Tax law problem set completed (each problem answered with applicable IRC section cited, basis computation shown, character of income/gain/loss stated, and policy rationale explained — all solutions saved to course submission file)",
            preferredDuration: 90 * 60
        ),
        // administrativelaw
        SuggestedTemplate(
            icon: "building.columns",
            task: "Study administrative law for my exam — review the framework of administrative agencies and the APA: agency authority (express vs implied delegation, intelligible principle doctrine and the nondelegation doctrine — Whitman v American Trucking, West Virginia v EPA major questions doctrine — courts now skeptical of agencies claiming novel authority in major economic and political questions without clear congressional authorization); rulemaking (informal/notice-and-comment rulemaking under APA §553: NPRM, comment period, final rule must respond to significant comments, logical outgrowth doctrine; formal rulemaking §556-557: on-the-record requirement; hybrid rulemaking; procedural rules, guidance documents, and policy statements — not binding but practically significant; negotiated rulemaking); adjudication (formal adjudication: §554 evidentiary hearings, ALJ procedures, bias and independence; informal adjudication; Mathews v Eldridge due process balancing: private interest, risk of erroneous deprivation, government interest; constitutional procedural due process in licensing and benefit termination — Goldberg v Kelly); judicial review (reviewability: committed to agency discretion §701(a)(2) — Heckler v Chaney enforcement inaction presumption; finality and ripeness — Abbott Laboratories; standing requirements under APA §702; scope of review standards: hard look/arbitrary-and-capricious review under §706(2)(A) — State Farm Motor Vehicle Safety, agency must consider relevant factors and examine important aspects of problem; Skidmore deference for agency interpretations in informal guidance; Loper Bright overruling Chevron — courts now interpret statutes de novo, agency technical expertise still informs but does not bind); separation of powers (Humphrey's Executor, Morrison v Olson, Seila Law — removal protections for independent agency heads; legislative veto INS v Chadha; Appointments Clause for principal vs inferior officers)",
            successCriteria: "Administrative law study session completed (at least two rulemaking/review standards reviewed with APA section cited, leading case applied, and the major questions doctrine distinguished from ordinary Chevron-step analysis; separation of powers limitation identified — study notes saved)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "building.columns",
            task: "Write my administrative law case brief, outline section, or paper — this may include: briefing a landmark case (State Farm Motor Vehicle Safety — identify the agency action at issue: rescission of passive restraint requirement; apply hard look review — Motor Vehicle Safety Act standard, APA §706(2)(A); agency must consider the alternative of requiring airbags alone, failure to consider obvious alternatives is arbitrary and capricious; explain why this illustrates reasoned decisionmaking requirement); analyzing judicial deference post-Loper Bright (explain Chevron two-step as it existed — unambiguous statute at step one, reasonable interpretation at step two; explain why Loper Bright overrules Chevron — courts must exercise independent judgment on statutory interpretation, agency expertise is a consideration but not the standard; compare Skidmore — thoroughness of reasoning and consistency earn respect but not binding deference; identify what role agency technical expertise still plays); applying the major questions doctrine to a hypothetical (agency claims novel regulatory authority over a major industry — identify: agency cited a broadly worded enabling statute; the policy has vast economic and political significance; no clear statement from Congress — under West Virginia v EPA, court rejects agency claim absent clear congressional authorization; distinguish from ordinary statutory ambiguity); analyzing a procedural due process claim (apply Mathews v Eldridge three-factor test to a license revocation, benefit termination, or regulatory sanction — identify private interest at stake, risk of error and value of additional procedure, and government interest; recommend what process is constitutionally required — notice, opportunity to respond, neutral decision-maker); or writing a rulemaking-validity memo (identify APA §553 procedural requirements, assess whether logical outgrowth doctrine was satisfied, identify substantial comment not responded to, evaluate whether agency adequately explained departure from prior policy under FCC v Fox)",
            successCriteria: "Administrative law paper, case brief, or outline section completed (APA section number cited, applicable review standard stated and applied, major cases cited with key holdings, policy argument grounded in administrative law doctrine — saved to course submission file)",
            preferredDuration: 90 * 60
        ),
        // riemanniangeometry
        SuggestedTemplate(
            icon: "globe",
            task: "Study Riemannian geometry for my exam — review Riemannian metrics and the Levi-Civita connection (Riemannian metric tensor g: symmetry, positive definiteness, smooth dependence on point; length of curves, geodesic distance; Levi-Civita connection: unique connection satisfying metric compatibility ∇g = 0 and torsion-freeness T = 0; Christoffel symbols Γ^k_ij in local coordinates; covariant derivative of vector fields along curves; parallel transport: parallel transport is an isometry, holonomy), geodesics (geodesic equation in local coordinates; geodesics as locally length-minimizing curves; exponential map exp_p: T_pM → M; normal coordinates; geodesic completeness and the Hopf-Rinow theorem: equivalent conditions for completeness — metric completeness, geodesic completeness, bounded closed sets are compact), curvature (Riemann curvature tensor R(X,Y)Z = ∇_X∇_YZ − ∇_Y∇_XZ − ∇_{[X,Y]}Z; sectional curvature K(σ); Ricci tensor Ric and scalar curvature S; constant curvature space forms: S^n (K=+1), R^n (K=0), H^n (K=-1); Gauss-Bonnet theorem in 2D: ∫_M K dA + ∫_∂M κ_g ds = 2πχ(M)), and Jacobi fields (Jacobi equation, conjugate points, first conjugate point, Cartan-Hadamard theorem for non-positive sectional curvature, Bishop-Gromov comparison)",
            successCriteria: "Riemannian geometry study session completed (at least two topics reviewed with Levi-Civita connection uniqueness theorem stated, geodesic equation written in local coordinates, Riemann curvature tensor formula stated and sectional curvature defined for a 2-plane, Hopf-Rinow theorem equivalent conditions listed, Gauss-Bonnet formula stated with Euler characteristic for S² computed, and key exam facts saved to study notes)",
            preferredDuration: 60 * 60
        ),
        SuggestedTemplate(
            icon: "globe",
            task: "Complete my Riemannian geometry problem set — problems may include: computing Christoffel symbols for a given Riemannian metric in local coordinates and verifying metric compatibility; finding geodesics of a specified metric (e.g., hyperbolic plane in half-space or disk model, round sphere, surface of revolution) by solving the geodesic equations or using symmetry arguments; computing the Riemann curvature tensor and sectional curvature of a given space (e.g., showing S^2 with round metric has K=1/r²); proving the Gauss-Bonnet theorem for a surface or applying it to compute the integral of Gaussian curvature over a given compact surface; showing that parallel transport around a loop induces a rotation by the holonomy angle equal to the enclosed area times the curvature; analyzing Jacobi fields along a geodesic to locate conjugate points; or proving a comparison theorem (e.g., Bonnet-Myers for positive Ricci curvature implying compactness, or Cartan-Hadamard for non-positive sectional curvature implying contractibility of universal cover)",
            successCriteria: "Riemannian geometry problem set completed (each assigned problem attempted: Christoffel symbols computed and verified, geodesic equations derived and solved for the given metric, Riemann tensor components calculated or sectional curvature confirmed, Gauss-Bonnet applied to a surface with Euler characteristic correctly identified, Jacobi field analysis written up, and all solutions with full proofs saved to file)",
            preferredDuration: 90 * 60
        ),
    ]
}
