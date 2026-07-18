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
    ]
}
