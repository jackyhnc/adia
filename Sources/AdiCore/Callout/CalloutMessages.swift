import Foundation

// MARK: - Tiered generic callout pools

extension CalloutManager {
    // Tier 1 (callouts 1–2): friendly but direct
    static let tier1Callouts: [String] = [
        "yo, what are you doing?",
        "stop.",
        "back to work.",
        "that's not why you're here.",
        "focus.",
        "you literally just started.",
        "seriously?",
        "get off that.",
        "c'mon.",
    ]

    // Tier 2 (callouts 3–4): noticeably stronger
    static let tier2Callouts: [String] = [
        "this is the third time.",
        "stop procrastinating.",
        "you keep getting distracted.",
        "get back to work. now.",
        "we're not playing around.",
        "close that. open your work.",
        "still?",
        "what are you doing to yourself.",
    ]

    // Tier 3 (callout 5+): harshest, no-nonsense
    static let tier3Callouts: [String] = [
        "STOP.",
        "you're wasting your own time.",
        "every minute here hurts you.",
        "you asked me to hold you accountable.",
        "the work is not going to do itself.",
        "put it down. right now.",
        "I am not letting this slide.",
    ]
}

// MARK: - Task-aware callout pools

extension CalloutManager {
    /// Returns task-specific callout strings for the given keyword and tier.
    /// Exposed `internal` so unit tests can inspect message content directly.
    internal func taskAwareCallouts(keyword: String, tier: Int) -> [String] {
        switch keyword {
        case "essay":     return essayCallouts(tier: tier)
        case "studying":  return studyingCallouts(tier: tier)
        case "reading":   return readingCallouts(tier: tier)
        case "email":     return emailCallouts(tier: tier)
        case "writing":   return writingCallouts(tier: tier)
        case "code":      return codeCallouts(tier: tier)
        case "presentation": return presentationCallouts(tier: tier)
        case "homework":  return homeworkCallouts(tier: tier)
        case "research":  return researchCallouts(tier: tier)
        case "project":   return projectCallouts(tier: tier)
        case "proposal":  return proposalCallouts(tier: tier)
        case "interview": return interviewCallouts(tier: tier)
        case "meeting":   return meetingCallouts(tier: tier)
        case "resume":    return resumeCallouts(tier: tier)
        case "application": return applicationCallouts(tier: tier)
        case "paper":     return paperCallouts(tier: tier)
        case "thesis":    return thesisCallouts(tier: tier)
        case "deadline":  return deadlineCallouts(tier: tier)
        case "video":     return videoCallouts(tier: tier)
        case "design":    return designCallouts(tier: tier)
        case "report":    return reportCallouts(tier: tier)
        case "budget":    return budgetCallouts(tier: tier)
        case "tutor":     return tutorCallouts(tier: tier)
        case "practice":  return practiceCallouts(tier: tier)
        case "planning":  return planningCallouts(tier: tier)
        case "musicproduction": return musicProductionCallouts(tier: tier)
        case "musictheory":    return musicTheoryCallouts(tier: tier)
        case "language":  return languageCallouts(tier: tier)
        case "fitness":   return fitnessCallouts(tier: tier)
        case "podcast":   return podcastCallouts(tier: tier)
        case "art":       return artCallouts(tier: tier)
        case "journaling": return journalingCallouts(tier: tier)
        case "legal":        return legalCallouts(tier: tier)
        case "premed":       return premedCallouts(tier: tier)
        case "architecture": return architectureCallouts(tier: tier)
        case "startup":      return startupCallouts(tier: tier)
        case "nursing":      return nursingCallouts(tier: tier)
        case "photography":  return photographyCallouts(tier: tier)
        case "datascience":  return datascienceCallouts(tier: tier)
        case "gamedev":      return gamedevCallouts(tier: tier)
        case "engineering":    return engineeringCallouts(tier: tier)
        case "therapy":        return therapyCallouts(tier: tier)
        case "socialscience":  return socialScienceCallouts(tier: tier)
        case "nutrition":      return nutritionCallouts(tier: tier)
        case "culinary":       return culinaryCallouts(tier: tier)
        case "philosophy":     return philosophyCallouts(tier: tier)
        case "enviro":         return enviroCallouts(tier: tier)
        case "finance":        return financeCallouts(tier: tier)
        case "policy":         return policyCallouts(tier: tier)
        case "ux":             return uxCallouts(tier: tier)
        case "statistics":     return statisticsCallouts(tier: tier)
        case "kinesiology":    return kinesiologyCallouts(tier: tier)
        case "veterinary":           return veterinaryCallouts(tier: tier)
        case "business":             return businessCallouts(tier: tier)
        case "publicheath":          return publichealthCallouts(tier: tier)
        case "paramedicine":         return paramedicineCallouts(tier: tier)
        case "socialwork":           return socialworkCallouts(tier: tier)
        case "occupationaltherapy":  return occupationaltherapyCallouts(tier: tier)
        case "dental":               return dentalCallouts(tier: tier)
        case "pharmacy":             return pharmacyCallouts(tier: tier)
        case "optometry":            return optometryCallouts(tier: tier)
        case "cybersecurity":        return cybersecurityCallouts(tier: tier)
        case "screenwriting":        return screenwritingCallouts(tier: tier)
        case "graphicdesign":        return graphicdesignCallouts(tier: tier)
        case "interiordesign":       return interiordesignCallouts(tier: tier)
        case "speechpathology":        return speechpathologyCallouts(tier: tier)
        case "physicianassistant":     return physicianassistantCallouts(tier: tier)
        case "realestate":             return realestateCallouts(tier: tier)
        case "education":              return educationCallouts(tier: tier)
        case "actuarial":              return actuarialCallouts(tier: tier)
        case "journalism":             return journalismCallouts(tier: tier)
        case "theology":               return theologyCallouts(tier: tier)
        case "criminaljustice":        return criminaljusticeCallouts(tier: tier)
        case "chiropractic":           return chiropracticCallouts(tier: tier)
        case "respiratorytherapy":     return respiratorytherapyCallouts(tier: tier)
        case "psychology":             return psychologyCallouts(tier: tier)
        case "geology":                return geologyCallouts(tier: tier)
        case "bioinformatics":         return bioinformaticsCallouts(tier: tier)
        case "urbanplanning":          return urbanplanningCallouts(tier: tier)
        case "dentalhygiene":          return dentalhygieneCallouts(tier: tier)
        case "molecularbiology":       return molecularbiologyCallouts(tier: tier)
        case "forensicaccounting":     return forensicaccountingCallouts(tier: tier)
        case "publicrelations":        return publicrelationsCallouts(tier: tier)
        case "physed":                 return physedCallouts(tier: tier)
        case "libraryscience":         return libraryscienceCallouts(tier: tier)
        case "dentalassisting":        return dentalassistingCallouts(tier: tier)
        case "filmstudies":            return filmstudiesCallouts(tier: tier)
        case "performingarts":         return performingArtsCallouts(tier: tier)
        case "astronomy":              return astronomyCallouts(tier: tier)
        case "mathematics":            return mathematicsCallouts(tier: tier)
        case "linguistics":            return linguisticsCallouts(tier: tier)
        case "arthistory":             return arthistoryCallouts(tier: tier)
        case "marinebiology":          return marinebiologyCallouts(tier: tier)
        case "speecharts":             return speechartsCallouts(tier: tier)
        case "forensicscience":        return forensicscienceCallouts(tier: tier)
        case "accounting":             return accountingCallouts(tier: tier)
        case "sportsmanagement":       return sportsmanagementCallouts(tier: tier)
        case "artrestoration":         return artrestorationCallouts(tier: tier)
        case "computationalscience":   return computationalscienceCallouts(tier: tier)
        case "forensicpsychology":     return forensicpsychologyCallouts(tier: tier)
        case "geospatial":             return geospatialCallouts(tier: tier)
        case "fashiondesign":          return fashiondesignCallouts(tier: tier)
        case "hospitality":            return hospitalityCallouts(tier: tier)
        case "sportsanalytics":        return sportsanalyticsCallouts(tier: tier)
        case "emergencymanagement":    return emergencymanagementCallouts(tier: tier)
        case "aviation":               return aviationCallouts(tier: tier)
        case "productdesign":          return productdesignCallouts(tier: tier)
        case "taxprep":                return taxprepCallouts(tier: tier)
        case "medicalbilling":         return medicalbillingCallouts(tier: tier)
        case "militarystudies":        return militarystudiesCallouts(tier: tier)
        case "supplychain":            return supplychainCallouts(tier: tier)
        case "communicationstudies":   return communicationstudiesCallouts(tier: tier)
        case "healthcareadmin":        return healthcareadminCallouts(tier: tier)
        case "neuroscience":           return neuroscienceCallouts(tier: tier)
        case "ethnicstudies":          return ethnicstudiesCallouts(tier: tier)
        case "humanfactors":           return humanfactorsCallouts(tier: tier)
        case "behavioraleconomics":    return behavioraleconomicsCallouts(tier: tier)
        case "translationalresearch":  return translationalresearchCallouts(tier: tier)
        case "healthcarelaw":          return healthcarelawCallouts(tier: tier)
        case "tradelaw":               return tradelawCallouts(tier: tier)
        case "cosmetology":            return cosmetologyCallouts(tier: tier)
        case "personaltraining":       return personaltrainingCallouts(tier: tier)
        case "dentallab":              return dentallabCallouts(tier: tier)
        case "landscapearchitecture":  return landscapearchitectureCallouts(tier: tier)
        case "immigrationlaw":         return immigrationlawCallouts(tier: tier)
        case "musiceducation":         return musiceducationCallouts(tier: tier)
        case "massagetherapy":         return massagetherapyCallouts(tier: tier)
        case "medicallabscience":      return medicallabscienceCallouts(tier: tier)
        case "radiologictechnology":   return radiologictechnologyCallouts(tier: tier)
        case "intellectualproperty":   return intellectualpropertyCallouts(tier: tier)
        case "signlanguage":           return signlanguageCallouts(tier: tier)
        case "acupuncture":            return acupunctureCallouts(tier: tier)
        case "arteducation":           return arteducationCallouts(tier: tier)
        case "environmentallaw":       return environmentallawCallouts(tier: tier)
        case "familylaw":              return familylawCallouts(tier: tier)
        case "nuclearmedtech":         return nuclearmedtechCallouts(tier: tier)
        case "sonography":             return sonographyCallouts(tier: tier)
        case "cardiovasculartech":     return cardiovasculartechCallouts(tier: tier)
        case "surgicaltech":           return surgicaltechCallouts(tier: tier)
        case "polysomnography":        return polysomnographyCallouts(tier: tier)
        case "diagnosticphysics":      return diagnosticphysicsCallouts(tier: tier)
        case "perfusiontechnology":    return perfusiontechnologyCallouts(tier: tier)
        case "ophthalmic":             return ophthalmicCallouts(tier: tier)
        case "centralsterile":         return centralsterileCallouts(tier: tier)
        case "nursinginformatics":     return nursinginformaticsCallouts(tier: tier)
        case "opticianry":             return opticianryCallouts(tier: tier)
        case "musictherapy":           return musictherapyCallouts(tier: tier)
        case "dancetherapy":           return dancetherapyCallouts(tier: tier)
        case "arttherapy":             return arttherapyCallouts(tier: tier)
        case "recreationtherapy":      return recreationtherapyCallouts(tier: tier)
        case "horticulturetherapy":    return horticulturetherapyCallouts(tier: tier)
        case "dietetictechnology":     return dietetictechnologyCallouts(tier: tier)
        case "dramaeducation":         return dramaeducationCallouts(tier: tier)
        case "winesommelier":          return winesommelierCallouts(tier: tier)
        case "gerontology":                 return gerontologyCallouts(tier: tier)
        case "addictioncounseling":         return addictioncounselingCallouts(tier: tier)
        case "oralsurgery":                 return oralsurgeryCallouts(tier: tier)
        case "publichealthlaw":             return publichealthlawCallouts(tier: tier)
        case "occupationalmedicine":        return occupationalmedicineCallouts(tier: tier)
        case "integrativemedicine":         return integrativemedicineCallouts(tier: tier)
        case "geneticcounseling":           return geneticcounselingCallouts(tier: tier)
        case "behavioralhealthpromotion":   return behavioralhealthpromotionCallouts(tier: tier)
        case "dentalpublichealth":          return dentalpublichealthCallouts(tier: tier)
        case "playwriting":                 return playwrightingCallouts(tier: tier)
        case "sportsmedicine":              return sportsmedicineCallouts(tier: tier)
        case "naturopathicmedicine":        return naturopathicmedicineCallouts(tier: tier)
        case "midwifery":                   return midwiferyCallouts(tier: tier)
        case "clinicalpsychology":          return clinicalpsychologyCallouts(tier: tier)
        case "theatresound":                return theatresoundCallouts(tier: tier)
        case "dancescience":                return dancescienceCallouts(tier: tier)
        case "forensicnursing":             return forensicnursingCallouts(tier: tier)
        case "midwiferyassisting":          return midwiferyassistingCallouts(tier: tier)
        case "interpreting":                return interpretingCallouts(tier: tier)
        case "dramatherapy":                return dramatherapyCallouts(tier: tier)
        case "horsemanship":                return horsemanshipCallouts(tier: tier)
        case "glassblowing":                return glassblowingCallouts(tier: tier)
        case "landsurveyingtech":           return landsurveyingtechCallouts(tier: tier)
        case "environmentalengineering":    return environmentalengineeringCallouts(tier: tier)
        case "techwriting":                 return techwritingCallouts(tier: tier)
        case "healthcoaching":              return healthcoachingCallouts(tier: tier)
        case "podiatry":                    return podiatryCallouts(tier: tier)
        case "classicalstudies":            return classicalstudiesCallouts(tier: tier)
        case "pmrehabilitation":            return pmrehabilitationCallouts(tier: tier)
        case "performancenutrition":        return performancenutritionCallouts(tier: tier)
        case "horticulturescience":         return horticulturecienceCallouts(tier: tier)
        case "globalhealthdev":             return globalhealthdevCallouts(tier: tier)
        case "maritimestudies":             return maritimestudiesCallouts(tier: tier)
        case "hvactechnology":              return hvactechnologyCallouts(tier: tier)
        case "constructionmanagement":      return constructionmanagementCallouts(tier: tier)
        case "floristryweddingplanning":    return floristryweddingplanningCallouts(tier: tier)
        case "cosmeticchemistry":           return cosmeticchemistryCallouts(tier: tier)
        case "automotivetech":              return automotivetechCallouts(tier: tier)
        case "weldingtechnology":           return weldingtechnologyCallouts(tier: tier)
        case "grantwriting":                return grantwritingCallouts(tier: tier)
        case "animalhusbandry":             return animalhusbandryCallouts(tier: tier)
        case "paralegal":                   return paralegalCallouts(tier: tier)
        case "certifiedfinancialplanner":   return certifiedfinancialplannerCallouts(tier: tier)
        case "soilscience":                 return soilscienceCallouts(tier: tier)
        case "industrialsafety":            return industrialsafetyCallouts(tier: tier)
        case "foodsafety":                  return foodsafetyCallouts(tier: tier)
        case "appliedmusic":                return appliedmusicCallouts(tier: tier)
        case "winemaking":                  return winemakingCallouts(tier: tier)
        case "forestry":                    return forestryCallouts(tier: tier)
        case "aquaticscience":              return aquaticscienceCallouts(tier: tier)
        case "emergencynursing":            return emergencynursingCallouts(tier: tier)
        case "publichealthnutrition":       return publichealthnutritionCallouts(tier: tier)
        case "plumbingtech":                return plumbingtechCallouts(tier: tier)
        case "electricaltechnology":        return electricaltechnologyCallouts(tier: tier)
        case "materialscience":             return materialscienceCallouts(tier: tier)
        case "networkengineering":          return networkengineeringCallouts(tier: tier)
        case "quantumcomputing":            return quantumcomputingCallouts(tier: tier)
        case "cloudcomputing":              return cloudcomputingCallouts(tier: tier)
        case "softwaretesting":             return softwaretestingCallouts(tier: tier)
        case "mechanicaldrafting":          return mechanicaldraftingCallouts(tier: tier)
        case "dataengineering":             return dataengineeringCallouts(tier: tier)
        case "environmentalhealth":         return environmentalhealthCallouts(tier: tier)
        case "constructiontech":            return constructiontechCallouts(tier: tier)
        case "urbandesign":                 return urbandesignCallouts(tier: tier)
        case "ceramicsandsculpture":        return ceramicsandsculptureCallouts(tier: tier)
        case "exercisescience":             return exercisescienceCallouts(tier: tier)
        case "biochemistry":               return biochemistryCallouts(tier: tier)
        case "agriculturalscience":        return agriculturalscienceCallouts(tier: tier)
        case "textilesfashion":            return textilesfashionCallouts(tier: tier)
        case "geographyearthed":           return geographyearthedCallouts(tier: tier)
        case "childlife":                  return childlifeCallouts(tier: tier)
        case "qualitymanagement":          return qualitymanagementCallouts(tier: tier)
        case "robotics":                   return roboticsCallouts(tier: tier)
        case "artificialintelligence":     return artificialintelligenceCallouts(tier: tier)
        case "osteopathicmedicine":        return osteopathicmedicineCallouts(tier: tier)
        case "epidemiology":               return epidemiologyCallouts(tier: tier)
        case "bioethics":                  return bioethicsCallouts(tier: tier)
        case "blockchain":                 return blockchainCallouts(tier: tier)
        case "digitalmarketing":           return digitalmarketingCallouts(tier: tier)
        case "projectmanagement":          return projectmanagementCallouts(tier: tier)
        case "riskmanagement":             return riskmanagementCallouts(tier: tier)
        case "speechcommunication":        return speechcommunicationCallouts(tier: tier)
        case "audiology":                  return audiologyCallouts(tier: tier)
        case "behavioranalysis":           return behavioranalysisCallouts(tier: tier)
        case "radiationtherapy":           return radiationtherapyCallouts(tier: tier)
        case "orthotics":                  return orthoticsCallouts(tier: tier)
        case "healthphysics":              return healthphysicsCallouts(tier: tier)
        case "informationsystems":         return informationsystemsCallouts(tier: tier)
        case "businessintelligence":       return businessintelligenceCallouts(tier: tier)
        case "internationalrelations":     return internationalrelationsCallouts(tier: tier)
        case "publicadministration":       return publicadministrationCallouts(tier: tier)
        case "laborlaw":                   return laborlawCallouts(tier: tier)
        case "veterinarytechnology":  return veterinarytechnologyCallouts(tier: tier)
        case "dentalradiology":       return dentalradiologyCallouts(tier: tier)
        case "medicalscribing":       return medicalscribingCallouts(tier: tier)
        case "communityhealth":       return communityhealthCallouts(tier: tier)
        case "toxicology":            return toxicologyCallouts(tier: tier)
        case "performanceanalysis":   return performanceanalysisCallouts(tier: tier)
        case "musicbusiness":         return musicbusinessCallouts(tier: tier)
        case "dentalanesthesia":      return dentalanesthesiaCallouts(tier: tier)
        case "palliativecare":        return palliativecareCallouts(tier: tier)
        case "cognitivescience":      return cognitivescienceCallouts(tier: tier)
        case "informationassurance":  return informationassuranceCallouts(tier: tier)
        case "hrmanagement":          return hrmanagementCallouts(tier: tier)
        case "changemanagement":      return changemanagementCallouts(tier: tier)
        case "economics":             return economicsCallouts(tier: tier)
        case "iopsychology":          return iopsychologyCallouts(tier: tier)
        default:               return genericKeywordCallouts(keyword: keyword, tier: tier)
        }
    }

    // MARK: - Per-keyword message pools

    private func essayCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "this isn't your essay.",
            "get back to your essay.",
            "your essay won't write itself.",
            "close this and write your essay.",
        ]
        case 2: return [
            "stop avoiding your essay.",
            "you need to write your essay, not browse.",
            "your essay isn't going to write itself — get back to it.",
        ]
        default: return [
            "CLOSE THIS. your essay won't write itself.",
            "your essay deadline is real.",
            "put the phone down. your essay is waiting.",
        ]
        }
    }

    private func studyingCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "get back to studying.",
            "you're not studying right now.",
            "studying won't do itself.",
        ]
        case 2: return [
            "stop putting off studying.",
            "you need to be studying, not doing this.",
        ]
        default: return [
            "CLOSE THIS. Start studying.",
            "your study session is ticking away.",
        ]
        }
    }

    private func readingCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "get back to reading.",
            "you're not reading right now.",
            "that reading won't do itself.",
        ]
        case 2: return [
            "stop putting off your reading.",
            "you need to be reading, not doing this.",
        ]
        default: return [
            "CLOSE THIS. Get back to reading.",
            "the reading deadline isn't moving.",
        ]
        }
    }

    private func emailCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those emails aren't going to write themselves.",
            "get back to your email.",
            "close this and go handle that email.",
        ]
        case 2: return [
            "stop avoiding your inbox.",
            "you have emails waiting — not this.",
        ]
        default: return [
            "CLOSE THIS. Go handle your email.",
            "your inbox isn't going to clear itself.",
        ]
        }
    }

    private func writingCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "get back to your writing.",
            "that post isn't going to write itself.",
            "close this and start writing.",
        ]
        case 2: return [
            "stop putting off your writing.",
            "you need to write, not browse.",
        ]
        default: return [
            "CLOSE THIS. Open your draft.",
            "your writing isn't getting done.",
        ]
        }
    }

    private func codeCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "get back to your code.",
            "this isn't your code.",
            "that code isn't going to ship itself.",
        ]
        case 2: return [
            "stop procrastinating on your code.",
            "you need to be writing code, not browsing.",
        ]
        default: return [
            "CLOSE THIS. Commit the code.",
            "your code won't write itself.",
        ]
        }
    }

    private func presentationCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "get back to your presentation.",
            "this isn't your presentation.",
            "your presentation isn't going to build itself.",
        ]
        case 2: return [
            "stop avoiding your presentation.",
            "you need to be working on your presentation, not this.",
        ]
        default: return [
            "CLOSE THIS. Finish the presentation.",
            "your presentation won't finish itself.",
        ]
        }
    }

    private func homeworkCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "get back to your homework.",
            "this isn't your homework.",
            "your homework isn't going to do itself.",
        ]
        case 2: return [
            "stop putting off your homework.",
            "you need to do your homework, not this.",
        ]
        default: return [
            "CLOSE THIS. Go finish your homework.",
            "your homework deadline isn't moving.",
        ]
        }
    }

    private func researchCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "get back to your research.",
            "this isn't your research.",
            "your research isn't going to do itself.",
        ]
        case 2: return [
            "stop avoiding your research.",
            "you need to be doing your research, not this.",
        ]
        default: return [
            "CLOSE THIS. Get back to your research.",
            "your research deadline isn't moving.",
        ]
        }
    }

    private func projectCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "get back to your project.",
            "this isn't your project.",
            "your project isn't going to finish itself.",
        ]
        case 2: return [
            "stop avoiding your project.",
            "you need to work on your project, not this.",
        ]
        default: return [
            "CLOSE THIS. Go finish your project.",
            "your project deadline is real.",
        ]
        }
    }

    private func proposalCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "get back to your proposal.",
            "this isn't your proposal.",
            "your proposal won't write itself.",
        ]
        case 2: return [
            "stop putting off your proposal.",
            "you need to write your proposal, not browse.",
        ]
        default: return [
            "CLOSE THIS. Go finish your proposal.",
            "your proposal deadline isn't moving.",
        ]
        }
    }

    private func interviewCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "get back to interview prep.",
            "your interview isn't going to prep itself.",
            "close this and practice.",
        ]
        case 2: return [
            "stop putting off interview prep.",
            "you need to be practicing, not browsing.",
        ]
        default: return [
            "CLOSE THIS. Go prep for that interview.",
            "your interview is coming — this isn't helping.",
        ]
        }
    }

    private func resumeCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "get back to your résumé.",
            "that résumé isn't going to write itself.",
            "close this and keep writing.",
        ]
        case 2: return [
            "stop putting off your résumé.",
            "you need to be writing your résumé, not browsing.",
        ]
        default: return [
            "CLOSE THIS. Finish your résumé.",
            "your résumé deadline isn't moving.",
        ]
        }
    }

    private func applicationCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "get back to your application.",
            "that application isn't going to submit itself.",
            "close this and keep writing.",
        ]
        case 2: return [
            "stop putting off your application.",
            "you need to finish your application, not browse.",
        ]
        default: return [
            "CLOSE THIS. Submit the application.",
            "your application deadline isn't moving.",
        ]
        }
    }

    private func deadlineCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "you have a deadline. act like it.",
            "the clock is ticking. get back to work.",
            "deadline incoming — stop.",
        ]
        case 2: return [
            "you're burning deadline time.",
            "you set this deadline. honor it.",
        ]
        default: return [
            "CLOSE THIS. Your deadline is real.",
            "your deadline doesn't care that you're here.",
        ]
        }
    }

    private func videoCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "get back to your video.",
            "that video isn't going to edit itself.",
            "close this and keep editing.",
        ]
        case 2: return [
            "stop putting off your video.",
            "you need to be editing, not watching.",
        ]
        default: return [
            "CLOSE THIS. Finish the video.",
            "your video deadline isn't moving.",
        ]
        }
    }

    private func designCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "get back to your design.",
            "that design isn't going to finish itself.",
            "close this and keep designing.",
        ]
        case 2: return [
            "stop avoiding your design.",
            "you need to be designing, not browsing.",
        ]
        default: return [
            "CLOSE THIS. Go finish the design.",
            "your design won't complete itself.",
        ]
        }
    }

    private func reportCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "get back to your report.",
            "that report isn't going to write itself.",
            "this isn't your report.",
        ]
        case 2: return [
            "stop avoiding your report.",
            "you need to be writing your report, not browsing.",
        ]
        default: return [
            "CLOSE THIS. Go finish the report.",
            "your report deadline isn't moving.",
        ]
        }
    }

    private func paperCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "get back to your paper.",
            "that paper won't write itself.",
            "close this. write the paper.",
            "this isn't your paper.",
        ]
        case 2: return [
            "stop avoiding your paper.",
            "you need to be writing your paper, not browsing.",
            "your paper won't finish itself.",
        ]
        default: return [
            "CLOSE THIS. Your paper is waiting.",
            "your paper deadline is real.",
            "put it down. your paper needs you.",
        ]
        }
    }

    private func thesisCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "get back to your thesis.",
            "your thesis won't write itself.",
            "close this and work on your thesis.",
        ]
        case 2: return [
            "stop avoiding your thesis.",
            "you need to be writing your thesis, not this.",
            "your thesis isn't going to write itself.",
        ]
        default: return [
            "CLOSE THIS. Your thesis needs you.",
            "your thesis deadline is not moving.",
            "years on this thesis. don't blow it now.",
        ]
        }
    }

    private func meetingCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "you have a meeting to prep for.",
            "your agenda isn't going to write itself.",
            "get back to your meeting prep.",
            "close this and prep for your meeting.",
        ]
        case 2: return [
            "stop avoiding your meeting prep.",
            "the meeting is coming — prep, not this.",
            "your meeting won't go well if you're here.",
        ]
        default: return [
            "CLOSE THIS. You have a meeting to prepare for.",
            "you'll walk in unprepared. close it now.",
            "your meeting doesn't care that you got distracted.",
        ]
        }
    }

    private func budgetCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "get back to your budget.",
            "those numbers aren't going to enter themselves.",
            "close this and work on your finances.",
        ]
        case 2: return [
            "stop putting off your finances.",
            "your budget won't balance itself.",
            "you need to work on your finances, not browse.",
        ]
        default: return [
            "CLOSE THIS. Your finances need attention.",
            "your budget deadline isn't moving.",
            "the numbers won't add up while you're here.",
        ]
        }
    }

    private func planningCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "get back to your planning.",
            "that plan isn't going to make itself.",
            "close this and keep planning.",
        ]
        case 2: return [
            "stop putting off your planning.",
            "you need to be planning, not browsing.",
            "your plans won't make themselves.",
        ]
        default: return [
            "CLOSE THIS. Go finish your plan.",
            "your planning isn't done yet.",
            "put it down. the plan needs work.",
        ]
        }
    }

    private func tutorCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "get back to your students.",
            "your lesson plan isn't going to write itself.",
            "close this and prep for your class.",
            "your students are counting on you to be ready.",
        ]
        case 2: return [
            "stop browsing. your students need you prepared.",
            "you're supposed to be planning a lesson, not this.",
            "those students deserve your full attention.",
        ]
        default: return [
            "CLOSE THIS. Your students need this prep.",
            "your class starts and you're browsing. close it.",
            "put it down. they're counting on you.",
        ]
        }
    }

    private func practiceCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "get back to practicing.",
            "the reps don't count themselves.",
            "close this and keep practicing.",
            "you don't improve by stopping.",
        ]
        case 2: return [
            "you get better by doing, not browsing.",
            "close this and put in the reps.",
            "you need the practice, not this.",
        ]
        default: return [
            "CLOSE THIS. Put in the practice.",
            "you won't improve by being here.",
            "close it. go practice.",
        ]
        }
    }

    private func musicProductionCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "your track isn't going to mix itself.",
            "those lyrics won't write themselves.",
            "close this and get back to the DAW.",
            "the beat won't finish itself — get back.",
        ]
        case 2: return [
            "stop browsing. get back in the session.",
            "you can't produce if you're not in your DAW.",
            "close this and finish the song.",
        ]
        default: return [
            "CLOSE THIS. Open your DAW.",
            "the track won't mix itself — get back.",
            "put it down. your session is waiting.",
        ]
        }
    }

    private func musicTheoryCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "your ear won't train itself — close this.",
            "get back to your theory work.",
            "sight reading won't improve by scrolling.",
            "close this and do your scales.",
        ]
        case 2: return [
            "stop. your chord progressions aren't going to memorize themselves.",
            "you can't hear intervals from here — get back.",
            "close this and keep drilling.",
        ]
        default: return [
            "CLOSE THIS. Do your ear training.",
            "theory mastery takes reps, not scrolling.",
            "no one learns counterpoint by browsing — back to work.",
        ]
        }
    }

    private func enviroCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "the ecosystem isn't going to study itself.",
            "get back to your environmental science work.",
            "close this and get back to your field notes.",
            "your lab report won't write itself.",
        ]
        case 2: return [
            "stop. your ecology notes won't review themselves.",
            "you can't understand climate data from here — close this.",
            "get back to your environmental science.",
        ]
        default: return [
            "CLOSE THIS. Open your field notes.",
            "ecosystems need your attention — not your feed.",
            "no one saves the planet by scrolling — back to work.",
        ]
        }
    }

    private func languageCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "get back to practicing.",
            "fluency takes daily reps — close this.",
            "your vocab won't grow by browsing.",
            "close this and get back to your lesson.",
        ]
        case 2: return [
            "stop avoiding the hard part. keep going.",
            "you can't get fluent by being here.",
            "close this and do the next exercise.",
        ]
        default: return [
            "CLOSE THIS. Go practice your language.",
            "consistency is the only thing that works. close it.",
            "fluency is built rep by rep — go back.",
        ]
        }
    }

    private func fitnessCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "get back to your workout.",
            "the reps don't count themselves.",
            "close this and get moving.",
            "you won't make gains from here.",
        ]
        case 2: return [
            "stop delaying. put in the work.",
            "you're supposed to be working out, not browsing.",
            "close this and finish your session.",
        ]
        default: return [
            "CLOSE THIS. Go finish your workout.",
            "progress is made in the gym, not here.",
            "put it down. the work is waiting.",
        ]
        }
    }

    private func podcastCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "get back to your episode.",
            "those show notes won't write themselves.",
            "close this and keep recording.",
            "the episode isn't going to edit itself.",
        ]
        case 2: return [
            "stop browsing. finish the episode.",
            "you can't produce a podcast from here.",
            "close this and get back to the recording.",
        ]
        default: return [
            "CLOSE THIS. Go finish your episode.",
            "the podcast won't produce itself.",
            "put it down. your listeners are waiting.",
        ]
        }
    }

    private func artCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "get back to your drawing.",
            "the canvas won't fill itself.",
            "close this and keep creating.",
            "your work isn't going to make itself.",
        ]
        case 2: return [
            "stop browsing. pick up the pen.",
            "you can't make art from here.",
            "close this and get back to your piece.",
        ]
        default: return [
            "CLOSE THIS. Go finish your work.",
            "the piece won't paint itself.",
            "put it down. the canvas is waiting.",
        ]
        }
    }

    private func journalingCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "your journal's still empty.",
            "thoughts don't write themselves.",
            "go back to your journal.",
            "close this and write.",
        ]
        case 2: return [
            "stop. open your journal.",
            "this isn't your journal entry.",
            "you came here to write. so write.",
        ]
        default: return [
            "CLOSE THIS. your journal is waiting.",
            "you opened Adia to journal. that's not this.",
            "the entry won't write itself. get back.",
        ]
        }
    }

    private func legalCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "your brief isn't going to write itself.",
            "get back to your legal work.",
            "close this and open your brief.",
            "the deadline won't move.",
        ]
        case 2: return [
            "stop. your brief is waiting.",
            "this isn't case prep.",
            "you're billing distraction time right now.",
        ]
        default: return [
            "CLOSE THIS. open your brief.",
            "you're not going to pass the bar by scrolling.",
            "the brief doesn't write itself. get back.",
        ]
        }
    }

    private func premedCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "the MCAT isn't going to prep itself.",
            "that's not your anatomy notes.",
            "get back to your med school work.",
            "your future patients are counting on you.",
        ]
        case 2: return [
            "stop. anatomy waits for no one.",
            "this isn't MCAT prep.",
            "you can't diagnose patients if you don't study.",
        ]
        default: return [
            "CLOSE THIS. open your anatomy notes.",
            "the boards don't care what you were scrolling. get back.",
            "med school doesn't pause. neither should you.",
        ]
        }
    }

    private func architectureCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "your drawings won't finish themselves.",
            "get back to the studio work.",
            "that model isn't building itself.",
            "close this. keep designing.",
        ]
        case 2: return [
            "stop. the crit is coming.",
            "you can't get pinned up by scrolling.",
            "your design won't finish itself — get back.",
        ]
        default: return [
            "CLOSE THIS. open your drawings.",
            "the deadline doesn't move. your model does.",
            "your studio crit is coming — this isn't prep.",
        ]
        }
    }

    private func startupCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "your pitch deck isn't going to write itself.",
            "get back to building your startup.",
            "your co-founder is working. you're not.",
            "close this and work on your business.",
        ]
        case 2: return [
            "stop. your pitch won't close itself.",
            "this isn't building your startup.",
            "investors don't fund distraction. get back.",
        ]
        default: return [
            "CLOSE THIS. your deck is waiting.",
            "no one funds a founder who's scrolling.",
            "the startup doesn't build itself. back to work.",
        ]
        }
    }

    private func nursingCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that care plan isn't going to write itself.",
            "get back to your nursing notes.",
            "your patients need you focused. so does your care plan.",
            "close this and get back to charting.",
        ]
        case 2: return [
            "stop. your care plan is due.",
            "this isn't your clinical documentation.",
            "nurses stay focused. get back to work.",
        ]
        default: return [
            "CLOSE THIS. open your care plan.",
            "you can't care for patients by scrolling. get back.",
            "your clinical notes don't write themselves — back to work.",
        ]
        }
    }

    private func photographyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those photos aren't going to edit themselves.",
            "get back to Lightroom.",
            "close this and open your editing.",
            "your raw files are waiting for you.",
        ]
        case 2: return [
            "stop. your client wants these edits.",
            "this isn't your color grade.",
            "you can't ship photos by scrolling — get back.",
        ]
        default: return [
            "CLOSE THIS. open your RAW files.",
            "your client is waiting for these edits — get back.",
            "the photos don't grade themselves. back to Lightroom.",
        ]
        }
    }

    private func datascienceCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "your model isn't going to train itself.",
            "get back to your notebook.",
            "the data won't analyze itself — close this.",
            "your jupyter notebook is waiting.",
        ]
        case 2: return [
            "stop. your model is waiting.",
            "this isn't your training run.",
            "your dataset doesn't clean itself — get back.",
        ]
        default: return [
            "CLOSE THIS. open your jupyter notebook.",
            "no one trains models by scrolling.",
            "your model won't converge while you're here — back to work.",
        ]
        }
    }

    private func gamedevCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "your game isn't going to build itself.",
            "get back to your game project.",
            "close this and open your game engine.",
            "your levels aren't going to design themselves.",
        ]
        case 2: return [
            "stop. your game jam deadline is real.",
            "this isn't your game dev work.",
            "you can't ship a game from here.",
        ]
        default: return [
            "CLOSE THIS. open Unity.",
            "no one ships games by scrolling.",
            "your build won't compile itself — back to work.",
        ]
        }
    }

    private func engineeringCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "your design isn't going to solve itself.",
            "get back to your engineering work.",
            "close this and open your CAD file.",
            "that circuit isn't going to design itself.",
        ]
        case 2: return [
            "stop. your lab report won't write itself.",
            "this isn't your engineering homework.",
            "you can't solve a free-body diagram from here.",
        ]
        default: return [
            "CLOSE THIS. open SolidWorks.",
            "no one passes statics by scrolling.",
            "your simulation won't run itself — back to work.",
        ]
        }
    }

    private func therapyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those therapy notes aren't going to write themselves.",
            "get back to your case notes.",
            "your clients deserve your focus. close this.",
            "your progress notes are waiting.",
        ]
        case 2: return [
            "stop. your notes are due before supervision.",
            "this isn't your treatment plan.",
            "case conceptualization doesn't write itself.",
        ]
        default: return [
            "CLOSE THIS. open your case notes.",
            "your clinical hours matter. get back.",
            "your clients are counting on your focus — back to work.",
        ]
        }
    }

    private func socialScienceCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "this isn't your political science work.",
            "get back to your social science assignment.",
            "your LSAT prep won't do itself.",
            "that research won't write itself — close this.",
        ]
        case 2: return [
            "stop. your poli sci paper is waiting.",
            "this isn't your anthropology homework.",
            "close this and get back to your social science work.",
        ]
        default: return [
            "CLOSE THIS. open your political science notes.",
            "your LSAT score won't improve from here.",
            "your social science work is waiting — back to it.",
        ]
        }
    }

    private func nutritionCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those macros aren't going to track themselves.",
            "get back to your nutrition work.",
            "your food journal isn't going to write itself.",
            "your dietetics notes are waiting.",
        ]
        case 2: return [
            "stop. your clinical nutrition assignment is due.",
            "this isn't your nutrition work.",
            "close this and get back to your dietary analysis.",
        ]
        default: return [
            "CLOSE THIS. open your nutrition notes.",
            "your food science work won't do itself — back to it.",
            "your dietitian notes are waiting. get back.",
        ]
        }
    }

    private func culinaryCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those recipes aren't going to test themselves.",
            "get back to your culinary work.",
            "close this and get back in the kitchen.",
            "your mise en place isn't going to prep itself.",
        ]
        case 2: return [
            "stop. your culinary assignment is waiting.",
            "this isn't your recipe development.",
            "close this and get back to your kitchen work.",
        ]
        default: return [
            "CLOSE THIS. open your recipe notes.",
            "no one develops recipes by scrolling.",
            "your culinary skills won't sharpen themselves — back to work.",
        ]
        }
    }

    private func philosophyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those arguments aren't going to analyze themselves.",
            "get back to your philosophy work.",
            "Kant didn't write the Critique by scrolling. close this.",
            "your philosophical argument won't write itself.",
        ]
        case 2: return [
            "stop. your philosophy paper is waiting.",
            "this isn't your Socratic dialogue.",
            "close this and get back to your philosophy work.",
        ]
        default: return [
            "CLOSE THIS. open your philosophy notes.",
            "no one writes a dialectical argument by browsing.",
            "your philosophy paper won't write itself — back to work.",
        ]
        }
    }

    private func financeCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "your DCF model isn't going to build itself.",
            "get back to your finance work.",
            "this isn't your Bloomberg Terminal.",
            "your CFA prep isn't going to do itself.",
        ]
        case 2: return [
            "stop. your financial analysis is waiting.",
            "no one passes the CPA or CFA by browsing.",
            "close this and get back to your finance work.",
        ]
        default: return [
            "CLOSE THIS. open your financial model.",
            "no one cracks investment banking by scrolling.",
            "your LBO assumptions won't fill themselves — back to work.",
        ]
        }
    }

    private func policyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "your policy memo isn't going to write itself.",
            "get back to your policy work.",
            "this isn't your policy brief.",
            "your policy analysis is waiting.",
        ]
        case 2: return [
            "stop. your policy memo is due.",
            "this isn't your policy work.",
            "close this and get back to your analysis.",
        ]
        default: return [
            "CLOSE THIS. open your policy memo.",
            "your regulatory analysis won't write itself — back to work.",
            "no one writes policy briefs by scrolling.",
        ]
        }
    }

    private func uxCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "your user research isn't going to conduct itself.",
            "get back to your UX work.",
            "those flows won't map themselves.",
            "your users are waiting for a better experience.",
        ]
        case 2: return [
            "stop. your UX deliverable is waiting.",
            "this isn't your Figma file.",
            "close this and get back to your user research.",
        ]
        default: return [
            "CLOSE THIS. open your design tool.",
            "no one ships great UX by browsing — back to work.",
            "your usability report won't write itself — close this.",
        ]
        }
    }

    private func statisticsCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "your statistical analysis isn't going to do itself.",
            "get back to your stats work.",
            "those regressions won't run themselves.",
            "close this and open your dataset.",
        ]
        case 2: return [
            "stop. your analysis is waiting.",
            "this isn't your R studio.",
            "close this and get back to your statistics work.",
        ]
        default: return [
            "CLOSE THIS. open your stats software.",
            "no one passes their stats exam by scrolling.",
            "your regression isn't going to run itself — back to work.",
        ]
        }
    }

    private func kinesiologyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "your biomechanics assignment isn't going to finish itself.",
            "get back to your kinesiology work.",
            "those movement analyses won't write themselves.",
            "close this and open your physiology notes.",
        ]
        case 2: return [
            "stop. your kinesiology assignment is waiting.",
            "this isn't your exercise physiology textbook.",
            "close this and get back to your sports science work.",
        ]
        default: return [
            "CLOSE THIS. open your kinesiology notes.",
            "no one passes the CSCS exam by scrolling.",
            "your physiology report won't write itself — back to work.",
        ]
        }
    }

    private func veterinaryCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "your patients need you focused — get back to your vet work.",
            "those case notes aren't going to write themselves.",
            "close this and open your veterinary notes.",
            "your vet school work is waiting.",
        ]
        case 2: return [
            "stop. your veterinary assignment is waiting.",
            "this isn't your anatomy atlas.",
            "close this and get back to your vet school work.",
        ]
        default: return [
            "CLOSE THIS. open your veterinary notes.",
            "no one passes NAVLE by scrolling.",
            "your animal science work won't do itself — back to it.",
        ]
        }
    }

    private func businessCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "your case analysis isn't going to write itself.",
            "get back to your business work.",
            "McKinsey recruits don't get there by browsing.",
            "your MBA coursework is waiting.",
        ]
        case 2: return [
            "stop. your business assignment is due.",
            "this isn't your case study.",
            "close this and get back to your management work.",
        ]
        default: return [
            "CLOSE THIS. open your case analysis.",
            "no one gets their MBA by scrolling.",
            "your business strategy won't write itself — back to work.",
        ]
        }
    }

    private func publichealthCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "this isn't your epidemiology assignment.",
            "get back to your public health work.",
            "your community health project won't do itself.",
            "close this and study epidemiology.",
        ]
        case 2: return [
            "you're not making anyone healthier by scrolling.",
            "stop avoiding your public health work.",
            "your epidemiology problem set is waiting — close this.",
        ]
        default: return [
            "CLOSE THIS. open your epidemiology notes.",
            "no one gets their MPH by scrolling.",
            "disease doesn't wait. neither should you.",
        ]
        }
    }

    private func paramedicineCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those protocols aren't going to memorize themselves.",
            "get back to your EMS training.",
            "your NREMT prep won't do itself.",
            "close this and study your paramedic material.",
        ]
        case 2: return [
            "stop. your EMT exam is waiting.",
            "this isn't your trauma assessment.",
            "close this and get back to your EMS coursework.",
        ]
        default: return [
            "CLOSE THIS. open your paramedic notes.",
            "no one passes the NREMT by scrolling.",
            "your future patients need you sharp — back to training.",
        ]
        }
    }

    private func socialworkCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "your clients need you focused — get back to your case notes.",
            "those case files aren't going to write themselves.",
            "close this and get back to your social work.",
            "your field placement work is waiting.",
        ]
        case 2: return [
            "stop. your case management notes are due.",
            "this isn't your intake assessment.",
            "close this and get back to your social work assignment.",
        ]
        default: return [
            "CLOSE THIS. open your case notes.",
            "no one earns their MSW by scrolling.",
            "your clients are waiting — back to work.",
        ]
        }
    }

    private func occupationaltherapyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "your OT notes aren't going to write themselves.",
            "get back to your occupational therapy work.",
            "your NBCOT prep is waiting.",
            "close this and open your OT materials.",
        ]
        case 2: return [
            "stop. your OT fieldwork notes are due.",
            "this isn't your ADL assessment.",
            "close this and get back to your occupational therapy coursework.",
        ]
        default: return [
            "CLOSE THIS. open your OT notes.",
            "no one passes the NBCOT by scrolling.",
            "your future clients need you studying — not browsing.",
        ]
        }
    }

    private func dentalCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those dental boards aren't going to pass themselves.",
            "your NBDE prep is waiting — close this.",
            "your future patients are counting on you studying.",
            "get back to your dental school work.",
        ]
        case 2: return [
            "stop. your dental charts aren't going to write themselves.",
            "this isn't your clinical notes.",
            "close this and get back to your dental coursework.",
        ]
        default: return [
            "CLOSE THIS. open your dental school notes.",
            "no one passes the NBDE by scrolling.",
            "your patients can't wait — and neither can your boards.",
        ]
        }
    }

    private func pharmacyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those drug interactions aren't going to memorize themselves.",
            "your NAPLEX prep is waiting — close this.",
            "your future patients need you to know this.",
            "get back to your pharmacy coursework.",
        ]
        case 2: return [
            "stop. your pharmacokinetics notes aren't going to write themselves.",
            "this isn't your drug therapy review.",
            "close this and get back to your pharmacy rotation prep.",
        ]
        default: return [
            "CLOSE THIS. open your pharmacy textbook.",
            "no one passes the NAPLEX by scrolling.",
            "medication errors happen when pharmacists don't study — close this.",
        ]
        }
    }

    private func optometryCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those NBEO questions won't answer themselves.",
            "your optometry boards are waiting — close this.",
            "your future patients need you to know this.",
            "get back to your optometry coursework.",
        ]
        case 2: return [
            "stop. your clinical optometry notes aren't going to write themselves.",
            "this isn't your visual acuity assessment.",
            "close this and get back to your optometry rotation prep.",
        ]
        default: return [
            "CLOSE THIS. open your optometry notes.",
            "no one passes the NBEO by scrolling.",
            "your patients' vision depends on you studying — close this.",
        ]
        }
    }

    private func cybersecurityCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those security concepts aren't going to memorize themselves.",
            "your certification prep is waiting — close this.",
            "your CTF isn't going to solve itself.",
            "get back to your cybersecurity work.",
        ]
        case 2: return [
            "stop. your vulnerability assessment isn't going to write itself.",
            "this isn't your penetration testing lab.",
            "close this and get back to your security coursework.",
        ]
        default: return [
            "CLOSE THIS. open your security tools.",
            "no one passes Security+ by scrolling.",
            "the network isn't going to audit itself — close this.",
        ]
        }
    }

    private func screenwritingCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that screenplay isn't going to write itself.",
            "your story isn't going to tell itself — close this.",
            "your characters are waiting. get back to the page.",
            "your draft is open somewhere — go find it.",
        ]
        case 2: return [
            "stop. your script isn't going to finish itself.",
            "this isn't your story world.",
            "close this and get back to your screenplay.",
        ]
        default: return [
            "CLOSE THIS. open your screenplay.",
            "your deadline doesn't care what you're watching.",
            "great writers write. close this and be one.",
        ]
        }
    }

    private func graphicdesignCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that logo isn't going to design itself.",
            "your brand identity is waiting — get back to your design file.",
            "close this and get back to your design.",
            "your client doesn't care what you're browsing — get back to work.",
        ]
        case 2: return [
            "stop. your design work isn't going to finish itself.",
            "this isn't your design file.",
            "close this and get back to your project.",
        ]
        default: return [
            "CLOSE THIS. open your design tool.",
            "your client deadline is real — stop scrolling.",
            "great designers design. close this and be one.",
        ]
        }
    }

    private func interiordesignCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that space isn't going to plan itself.",
            "your floor plan is waiting — close this and get back to it.",
            "close this and get back to your design project.",
            "your client is waiting for that layout — focus.",
        ]
        case 2: return [
            "stop. your interior project isn't going to finish itself.",
            "this isn't your floor plan.",
            "close this and get back to your space planning.",
        ]
        default: return [
            "CLOSE THIS. open your design software.",
            "your deadline doesn't care about your scroll habit.",
            "NCIDQ or not — you still need to close this and work.",
        ]
        }
    }

    private func speechpathologyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "your clients deserve your full attention — close this.",
            "those therapy notes aren't going to write themselves.",
            "close this and get back to your clinical work.",
            "your supervisor isn't going to write your notes for you.",
        ]
        case 2: return [
            "stop. your SLP work isn't going to finish itself.",
            "this isn't your session notes.",
            "close this and get back to your speech therapy work.",
        ]
        default: return [
            "CLOSE THIS. open your therapy notes.",
            "no one earns their CCC-SLP by scrolling.",
            "your clients need you present — close this and focus.",
        ]
        }
    }

    private func physicianassistantCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those PANCE questions aren't going to answer themselves.",
            "your PA school work is waiting — close this.",
            "your future patients are counting on you studying.",
            "get back to your PA coursework.",
        ]
        case 2: return [
            "stop. your clinical rotation notes aren't going to write themselves.",
            "this isn't your SOAP notes.",
            "close this and get back to your PA school work.",
        ]
        default: return [
            "CLOSE THIS. open your PA school notes.",
            "no one passes the PANCE by scrolling.",
            "your patients deserve a PA who studied — close this.",
        ]
        }
    }

    private func realestateCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that listing isn't going to write itself.",
            "get back to your real estate prep.",
            "those property notes aren't going to review themselves.",
            "close this and prep your CMA.",
        ]
        case 2: return [
            "your real estate exam isn't going to pass itself.",
            "stop browsing — get back to your real estate work.",
            "those closing docs aren't going to review themselves.",
        ]
        default: return [
            "CLOSE THIS. open your real estate study materials.",
            "no one gets their license by scrolling.",
            "your clients deserve an agent who actually studied — close this.",
        ]
        }
    }

    private func educationCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those lesson plans aren't going to write themselves.",
            "get back to your curriculum work.",
            "your students deserve a prepared teacher — close this.",
            "close this and get back to your lesson planning.",
        ]
        case 2: return [
            "your teaching cert exam isn't going to pass itself.",
            "stop — your lesson plans need your attention, not this.",
            "close this and get back to your education coursework.",
        ]
        default: return [
            "CLOSE THIS. open your lesson plans.",
            "no one passes Praxis by scrolling.",
            "your future students are counting on you to study — close this.",
        ]
        }
    }

    private func actuarialCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those actuarial problems aren't going to solve themselves.",
            "your exam P isn't going to pass itself.",
            "get back to your actuarial work.",
            "close this and open your actuarial study materials.",
        ]
        case 2: return [
            "stop — your FSA isn't going to earn itself.",
            "your loss models need your attention, not this.",
            "close this and get back to actuarial exam prep.",
        ]
        default: return [
            "CLOSE THIS. open your actuarial exam prep.",
            "no one earns their FSA by scrolling.",
            "your actuarial exam is real — close this.",
        ]
        }
    }

    private func journalismCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that article isn't going to write itself.",
            "get back to your reporting.",
            "those sources aren't going to find themselves.",
            "close this and get back to your news story.",
        ]
        case 2: return [
            "your deadline isn't going to move — close this.",
            "stop — your press release needs your attention, not this.",
            "close this and get back to your journalism work.",
        ]
        default: return [
            "CLOSE THIS. open your article.",
            "no one becomes a journalist by scrolling.",
            "your editor is waiting — close this and write.",
        ]
        }
    }

    private func theologyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those scripture passages aren't going to analyze themselves.",
            "get back to your theology work.",
            "your exegesis isn't going to write itself.",
            "close this and get back to your biblical studies.",
        ]
        case 2: return [
            "your divinity exam isn't going to pass itself.",
            "stop — your theology paper needs your focus, not this.",
            "close this and get back to your seminary work.",
        ]
        default: return [
            "CLOSE THIS. open your theology notes.",
            "no one gets their M.Div by scrolling.",
            "your faith calls you to focus — close this.",
        ]
        }
    }

    private func criminaljusticeCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that case isn't going to analyze itself.",
            "get back to your criminology work.",
            "those crime stats aren't going to interpret themselves.",
            "close this and get back to your criminal justice assignment.",
        ]
        case 2: return [
            "your criminal justice exam isn't going to pass itself.",
            "stop — your case analysis needs your attention, not this.",
            "close this and get back to your criminology notes.",
        ]
        default: return [
            "CLOSE THIS. open your criminal justice notes.",
            "no one masters criminology by scrolling.",
            "justice requires focus — close this.",
        ]
        }
    }

    private func chiropracticCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "your chiropractic notes aren't going to write themselves.",
            "those NBCE questions won't answer themselves.",
            "your patients' adjustments need you to focus — close this.",
            "your chiropractic exam isn't going to prep itself.",
        ]
        case 2: return [
            "stop this and get back to your chiropractic studies.",
            "your NBCE prep is suffering while you scroll.",
            "those subluxation notes won't study themselves.",
        ]
        default: return [
            "CLOSE THIS. open your chiropractic notes.",
            "no one passes the NBCE by scrolling.",
            "your spinal anatomy won't learn itself — get back to work.",
        ]
        }
    }

    private func respiratorytherapyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "your RT notes aren't going to write themselves.",
            "those ventilator settings won't memorize themselves.",
            "your NBRC prep is waiting — close this.",
            "your patients' airways deserve your full focus.",
        ]
        case 2: return [
            "stop scrolling and get back to your respiratory therapy work.",
            "your NBRC exam isn't going to prep itself.",
            "those ABG values won't interpret themselves.",
        ]
        default: return [
            "CLOSE THIS. open your respiratory therapy notes.",
            "no one passes the NBRC by scrolling.",
            "your ventilator protocols won't review themselves — get back to work.",
        ]
        }
    }

    private func psychologyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "your psychology paper isn't going to write itself.",
            "those research methods won't study themselves.",
            "your psych exam isn't going to prep itself.",
            "your psychology notes are waiting — close this.",
        ]
        case 2: return [
            "stop scrolling and get back to your psych work.",
            "your psychology assignment needs you, not this.",
            "you're supposed to be studying psychology, not wasting time.",
        ]
        default: return [
            "CLOSE THIS. open your psychology textbook.",
            "no one aces psych by scrolling.",
            "your research won't design itself — get back to it.",
        ]
        }
    }

    private func geologyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those rock samples won't identify themselves.",
            "your geological report isn't going to write itself.",
            "get back to your earth science notes.",
            "your geology exam isn't going to prep itself.",
        ]
        case 2: return [
            "stop scrolling and get back to your geology work.",
            "those tectonic processes won't study themselves.",
            "your geological survey notes are waiting — close this.",
        ]
        default: return [
            "CLOSE THIS. open your geology textbook.",
            "no one passes the ASBOG by scrolling.",
            "the earth isn't going to study itself — close this.",
        ]
        }
    }

    private func bioinformaticsCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those sequences won't align themselves.",
            "your bioinformatics pipeline isn't going to run itself.",
            "get back to your genomics work.",
            "your data isn't going to analyze itself.",
        ]
        case 2: return [
            "stop scrolling and get back to your bioinformatics work.",
            "those variant calls won't interpret themselves.",
            "your pipeline isn't going to debug itself — close this.",
        ]
        default: return [
            "CLOSE THIS. open your bioinformatics tools.",
            "no one builds a genome assembly by scrolling.",
            "your sequences aren't going to align themselves — close this.",
        ]
        }
    }

    private func urbanplanningCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that zoning ordinance isn't going to analyze itself.",
            "your comprehensive plan won't write itself.",
            "get back to your urban planning work.",
            "your AICP prep isn't going to happen on its own.",
        ]
        case 2: return [
            "stop scrolling and get back to your urban planning work.",
            "those land use policies won't draft themselves.",
            "your planning report needs you, not this.",
        ]
        default: return [
            "CLOSE THIS. open your planning documents.",
            "no one passes the AICP by scrolling.",
            "cities don't plan themselves — close this.",
        ]
        }
    }

    private func dentalhygieneCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those dental hygiene boards aren't going to pass themselves.",
            "your periodontal charting won't do itself.",
            "get back to your dental hygiene notes.",
            "your NBDHE prep isn't going to happen on its own.",
        ]
        case 2: return [
            "stop scrolling and get back to your dental hygiene work.",
            "your oral health assessment notes are waiting.",
            "the NBDHE exam is real — close this.",
        ]
        default: return [
            "CLOSE THIS. open your dental hygiene notes.",
            "no one passes the NBDHE by scrolling.",
            "your patients deserve a prepared hygienist — close this.",
        ]
        }
    }

    private func molecularbiologyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those gel results won't analyze themselves.",
            "your PCR protocol isn't going to run itself.",
            "get back to your molecular biology work.",
            "your lab write-up won't write itself.",
        ]
        case 2: return [
            "stop scrolling and get back to your molecular biology work.",
            "those Western blots won't interpret themselves.",
            "your molecular biology assignment needs you.",
        ]
        default: return [
            "CLOSE THIS. open your lab notebook.",
            "no one gets their biology degree by scrolling.",
            "your experiment isn't going to analyze itself — close this.",
        ]
        }
    }

    private func forensicaccountingCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that fraud case isn't going to investigate itself.",
            "your CFE prep won't happen while you're scrolling.",
            "forensic accountants catch fraud — not distraction.",
            "close this and open your case files.",
        ]
        case 2: return [
            "no one cracks fraud cases by scrolling.",
            "your forensic accounting notes won't write themselves.",
            "the evidence trail isn't here — close this.",
        ]
        default: return [
            "CLOSE THIS. open your forensic accounting work.",
            "no one passes the CFE by browsing.",
            "CLOSE THIS. your fraud case won't crack itself.",
        ]
        }
    }

    private func publicrelationsCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that press kit isn't going to write itself.",
            "your PR strategy won't build itself while you scroll.",
            "great communicators communicate — close this.",
            "your media pitch is waiting.",
        ]
        case 2: return [
            "no one breaks into PR by browsing.",
            "your communications plan won't write itself.",
            "the pitch won't land if you don't write it — close this.",
        ]
        default: return [
            "CLOSE THIS. open your PR notes.",
            "no one earns a communications career by scrolling.",
            "CLOSE THIS. your pitch isn't writing itself.",
        ]
        }
    }

    private func physedCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those lesson plans aren't going to write themselves.",
            "great coaches plan — close this and get to it.",
            "your PE curriculum won't build itself.",
            "coaching theory doesn't learn itself while you scroll.",
        ]
        case 2: return [
            "no one becomes a great coach by scrolling.",
            "your lesson plans won't write themselves.",
            "your athletes are counting on your prep — close this.",
        ]
        default: return [
            "CLOSE THIS. open your coaching or PE notes.",
            "no one earns their coaching certification by browsing.",
            "CLOSE THIS. your athletes deserve your full prep.",
        ]
        }
    }

    private func libraryscienceCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those catalogs aren't going to organize themselves.",
            "your MLIS won't earn itself while you scroll.",
            "great librarians know where things are — including their focus.",
            "your reference skills won't sharpen by browsing.",
        ]
        case 2: return [
            "no one earns their MLIS by scrolling.",
            "your library science notes won't write themselves.",
            "the catalog isn't going to build itself — close this.",
        ]
        default: return [
            "CLOSE THIS. open your library science notes.",
            "no one becomes a great librarian by browsing.",
            "CLOSE THIS. your catalog isn't going to build itself.",
        ]
        }
    }

    private func dentalassistingCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those dental assisting notes aren't going to review themselves.",
            "your DANB prep won't happen while you scroll.",
            "chairside skills don't sharpen by browsing.",
            "close this and get back to your dental assisting work.",
        ]
        case 2: return [
            "no one passes the DANB by scrolling.",
            "your dental assisting notes won't study themselves.",
            "your patients deserve a prepared assistant — close this.",
        ]
        default: return [
            "CLOSE THIS. open your dental assisting notes.",
            "no one becomes a dental assistant by browsing.",
            "CLOSE THIS. your patients deserve your full focus.",
        ]
        }
    }

    private func filmstudiesCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that film essay isn't going to write itself.",
            "your film analysis won't happen while you scroll.",
            "great film critics watch and write — close this.",
            "your mise-en-scène notes won't analyze themselves.",
        ]
        case 2: return [
            "no one earns their film degree by scrolling.",
            "close this and open your film analysis.",
            "the camera doesn't stop rolling — neither should you.",
        ]
        default: return [
            "CLOSE THIS. open your film analysis.",
            "no one becomes a film critic by watching YouTube.",
            "CLOSE THIS. your professor doesn't grade Netflix time.",
        ]
        }
    }

    private func performingArtsCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that scene isn't going to rehearse itself.",
            "great actors show up — close this and get back to work.",
            "your choreography won't perfect itself while you scroll.",
            "the curtain goes up whether you're ready or not.",
        ]
        case 2: return [
            "no one books the role by scrolling.",
            "your lines won't learn themselves — close this.",
            "your director is counting on your prep.",
        ]
        default: return [
            "CLOSE THIS. open your script or rehearsal notes.",
            "no one earns a stage role by browsing.",
            "CLOSE THIS. the stage doesn't wait.",
        ]
        }
    }

    private func astronomyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "the universe doesn't study itself — you have to.",
            "those equations won't solve themselves.",
            "you won't discover anything while you scroll.",
            "great astronomers observe — close this and focus.",
        ]
        case 2: return [
            "no one maps the cosmos by scrolling.",
            "your astrophysics problem set won't do itself.",
            "close this — the data isn't going to analyze itself.",
        ]
        default: return [
            "CLOSE THIS. open your astronomy notes.",
            "no one earns their astrophysics degree by browsing.",
            "CLOSE THIS. the stars don't wait.",
        ]
        }
    }

    private func mathematicsCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that proof isn't going to write itself.",
            "your problem set won't solve itself while you scroll.",
            "theorems don't prove themselves — close this.",
            "great mathematicians think. close this and start thinking.",
        ]
        case 2: return [
            "no one cracks abstract algebra by scrolling.",
            "your proof won't appear while you browse.",
            "close this and open your math notes.",
        ]
        default: return [
            "CLOSE THIS. open your proof.",
            "no one earns their math degree by scrolling.",
            "CLOSE THIS. the theorem is waiting.",
        ]
        }
    }

    private func linguisticsCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that language analysis isn't going to write itself.",
            "your phonetics problem set won't do itself.",
            "great linguists observe and analyze — close this.",
            "your corpus won't build itself while you scroll.",
        ]
        case 2: return [
            "no one earns their linguistics degree by scrolling.",
            "your analysis won't write itself — close this.",
            "close this and open your linguistics notes.",
        ]
        default: return [
            "CLOSE THIS. open your linguistics notes.",
            "no one masters language structure by browsing.",
            "CLOSE THIS. your analysis is waiting.",
        ]
        }
    }

    private func arthistoryCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that art history essay isn't going to write itself.",
            "get back to your art history work.",
            "your art analysis isn't going to happen on its own.",
            "close this and open your art history notes.",
        ]
        case 2: return [
            "you're not going to understand the baroque by scrolling.",
            "art criticism doesn't write itself — close this.",
            "your art history exam is waiting.",
        ]
        default: return [
            "CLOSE THIS. open your art history notes.",
            "no one learns art history by scrolling.",
            "CLOSE THIS. get back to your analysis.",
        ]
        }
    }

    private func marinebiologyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that marine biology assignment isn't going to finish itself.",
            "get back to your ocean science work.",
            "your marine biology notes aren't going to write themselves.",
            "close this and open your marine biology materials.",
        ]
        case 2: return [
            "the ocean doesn't study itself — you have to.",
            "no marine biologist got there by scrolling.",
            "your oceanography exam is waiting.",
        ]
        default: return [
            "CLOSE THIS. open your marine biology notes.",
            "no one maps the ocean by scrolling.",
            "CLOSE THIS. get back to your lab report.",
        ]
        }
    }

    private func speechartsCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "your debate prep isn't going to happen by scrolling.",
            "get back to your speech and debate work.",
            "your argument isn't going to build itself.",
            "close this and get back to your case.",
        ]
        case 2: return [
            "no one wins a debate tournament by scrolling.",
            "your speech isn't going to write itself — close this.",
            "your Model UN resolution is waiting.",
        ]
        default: return [
            "CLOSE THIS. open your debate notes.",
            "no one wins nationals by scrolling.",
            "CLOSE THIS. get back to your case prep.",
        ]
        }
    }

    private func forensicscienceCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that forensic science assignment isn't going to finish itself.",
            "get back to your forensic science work.",
            "your evidence analysis isn't going to write itself.",
            "close this and open your forensic science notes.",
        ]
        case 2: return [
            "no forensic scientist got there by scrolling.",
            "your crime lab report is waiting — close this.",
            "evidence doesn't analyze itself.",
        ]
        default: return [
            "CLOSE THIS. open your forensic science notes.",
            "no one passes FEPAC by scrolling.",
            "CLOSE THIS. get back to your lab analysis.",
        ]
        }
    }

    private func accountingCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those journal entries aren't going to balance themselves.",
            "get back to your accounting work.",
            "your debits and credits won't reconcile themselves.",
            "close this and open your accounting textbook.",
        ]
        case 2: return [
            "no one passes the CMA by scrolling.",
            "your accounting assignment isn't going to do itself — get back to it.",
            "stop avoiding the ledger.",
        ]
        default: return [
            "CLOSE THIS. open your accounting work.",
            "your accounting deadline is real.",
            "CLOSE THIS. those accounts won't balance themselves.",
        ]
        }
    }

    private func sportsmanagementCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "your sports management case isn't going to write itself.",
            "get back to your sports management work.",
            "the game plan starts with actually doing the work.",
            "close this and open your sports business assignment.",
        ]
        case 2: return [
            "athletic directors don't get there by scrolling.",
            "your sports management project isn't going to finish itself.",
            "stop stalling — your case study is waiting.",
        ]
        default: return [
            "CLOSE THIS. open your sports management work.",
            "no one runs a sports org by browsing.",
            "CLOSE THIS. get back to your sports business assignment.",
        ]
        }
    }

    private func artrestorationCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that painting isn't going to conserve itself.",
            "get back to your conservation work.",
            "your treatment plan won't write itself.",
            "close this and open your conservation notes.",
        ]
        case 2: return [
            "no conservator got there by scrolling.",
            "your conservation assignment isn't going to do itself.",
            "stop avoiding your lab report.",
        ]
        default: return [
            "CLOSE THIS. open your conservation work.",
            "art waits for no one — neither does your deadline.",
            "CLOSE THIS. get back to your conservation lab.",
        ]
        }
    }

    private func computationalscienceCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that simulation isn't going to run itself.",
            "get back to your computational work.",
            "your HPC job won't submit itself.",
            "close this and open your simulation code.",
        ]
        case 2: return [
            "supercomputers don't do the thinking for you.",
            "your computational model isn't going to converge itself.",
            "stop procrastinating — your job queue is waiting.",
        ]
        default: return [
            "CLOSE THIS. open your simulation code.",
            "no one cracks HPC by scrolling.",
            "CLOSE THIS. get back to your computational work.",
        ]
        }
    }

    private func forensicpsychologyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those case notes aren't going to write themselves.",
            "get back to your forensic psychology work.",
            "your competency evaluation won't complete itself.",
            "close this and open your forensic psych notes.",
        ]
        case 2: return [
            "no one passes the EPPP by scrolling.",
            "your forensic assessment report isn't going to write itself.",
            "stop avoiding your case notes.",
        ]
        default: return [
            "CLOSE THIS. open your forensic psychology work.",
            "criminal profilers don't get there by browsing.",
            "CLOSE THIS. get back to your forensic psych assignment.",
        ]
        }
    }

    private func geospatialCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that spatial analysis isn't going to run itself.",
            "get back to your GIS work.",
            "your map isn't going to build itself.",
            "close this and open your GIS software.",
        ]
        case 2: return [
            "geospatial scientists don't get there by scrolling.",
            "your spatial data isn't going to analyze itself.",
            "stop avoiding your GIS assignment.",
        ]
        default: return [
            "CLOSE THIS. open your GIS project.",
            "no one earns their GISP by browsing.",
            "CLOSE THIS. get back to your spatial analysis.",
        ]
        }
    }

    private func fashiondesignCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that collection isn't going to design itself.",
            "get back to your fashion work.",
            "your garment won't drape itself.",
            "close this and open your design sketches.",
        ]
        case 2: return [
            "great designers design — close this and be one.",
            "your portfolio isn't going to build itself.",
            "stop procrastinating — your tech pack is waiting.",
        ]
        default: return [
            "CLOSE THIS. open your fashion design work.",
            "no one builds a fashion career by scrolling.",
            "CLOSE THIS. get back to your pattern drafting.",
        ]
        }
    }

    private func hospitalityCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that hotel case study isn't going to write itself.",
            "get back to your hospitality coursework.",
            "your guests deserve better — so does your assignment.",
            "close this and open your hospitality notes.",
        ]
        case 2: return [
            "five-star hospitality starts with actually doing the work.",
            "your event plan isn't going to write itself.",
            "stop stalling — your tourism assignment is waiting.",
        ]
        default: return [
            "CLOSE THIS. open your hospitality work.",
            "no one runs a hotel by scrolling.",
            "CLOSE THIS. get back to your hospitality assignment.",
        ]
        }
    }

    private func sportsanalyticsCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those player stats aren't going to analyze themselves.",
            "get back to your sports analytics work.",
            "your model won't train itself on sports data.",
            "close this and open your analytics notebook.",
        ]
        case 2: return [
            "sabermetrics won't come to you by browsing.",
            "your sports data analysis isn't going to do itself.",
            "stop avoiding your analytics assignment.",
        ]
        default: return [
            "CLOSE THIS. open your sports analytics project.",
            "no one builds a sports data career by scrolling.",
            "CLOSE THIS. get back to your player tracking analysis.",
        ]
        }
    }

    private func emergencymanagementCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that emergency plan isn't going to write itself.",
            "get back to your emergency management work.",
            "your disaster response protocol won't draft itself.",
            "close this and open your FEMA coursework.",
        ]
        case 2: return [
            "emergency managers don't get certified by scrolling.",
            "your hazard mitigation plan isn't going to write itself.",
            "stop avoiding your incident command assignment.",
        ]
        default: return [
            "CLOSE THIS. open your emergency management work.",
            "no one passes FEMA certification by browsing.",
            "CLOSE THIS. get back to your disaster response plan.",
        ]
        }
    }

    private func genericKeywordCallouts(keyword: String, tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "get back to your \(keyword).",
            "this isn't your \(keyword).",
            "your \(keyword) isn't going to finish itself.",
        ]
        case 2: return [
            "stop putting off your \(keyword).",
            "you need to work on your \(keyword), not this.",
        ]
        default: return [
            "CLOSE THIS. open your \(keyword).",
            "your \(keyword) deadline isn't moving.",
        ]
        }
    }

    private func aviationCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that checkride isn't going to pass itself.",
            "get back to your flight training.",
            "your FAA exam won't study for itself.",
            "close this and open your ground school materials.",
        ]
        case 2: return [
            "pilots don't get certified by scrolling.",
            "your written test isn't going to prep itself.",
            "stop stalling — your aviation coursework is waiting.",
        ]
        default: return [
            "CLOSE THIS. open your aviation study materials.",
            "no one earns a pilot certificate by browsing.",
            "CLOSE THIS. get back to your flight training.",
        ]
        }
    }

    private func productdesignCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that product isn't going to design itself.",
            "get back to your industrial design work.",
            "your design model won't build itself.",
            "close this and open your product design project.",
        ]
        case 2: return [
            "great designers design — close this and be one.",
            "your ID sketches aren't going to draw themselves.",
            "stop avoiding your product design assignment.",
        ]
        default: return [
            "CLOSE THIS. open your product design work.",
            "no one builds a design career by scrolling.",
            "CLOSE THIS. get back to your product design project.",
        ]
        }
    }

    private func taxprepCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those taxes aren't going to file themselves.",
            "get back to your tax return.",
            "the IRS isn't going to wait — close this.",
            "close this and open your tax software.",
        ]
        case 2: return [
            "tax season doesn't pause for browsing.",
            "your tax return isn't going to finish itself.",
            "stop putting it off — your taxes are waiting.",
        ]
        default: return [
            "CLOSE THIS. open your tax return.",
            "no one files their taxes by scrolling.",
            "CLOSE THIS. get back to your tax prep.",
        ]
        }
    }

    private func medicalbillingCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those CPT codes aren't going to memorize themselves.",
            "get back to your medical billing work.",
            "your CPC exam prep won't do itself.",
            "close this and open your coding materials.",
        ]
        case 2: return [
            "medical coders don't pass the CPC by scrolling.",
            "your billing assignment isn't going to complete itself.",
            "stop avoiding your medical coding practice.",
        ]
        default: return [
            "CLOSE THIS. open your medical billing materials.",
            "no one passes the CPC by browsing.",
            "CLOSE THIS. get back to your medical coding work.",
        ]
        }
    }

    private func militarystudiesCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that mission brief isn't going to write itself.",
            "get back to your military studies.",
            "your ASVAB prep won't study for itself.",
            "close this and open your military coursework.",
        ]
        case 2: return [
            "officers don't get commissioned by scrolling.",
            "your military history paper isn't going to write itself.",
            "stop stalling — your ROTC assignment is waiting.",
        ]
        default: return [
            "CLOSE THIS. open your military studies materials.",
            "no one passes the ASVAB by browsing.",
            "CLOSE THIS. get back to your military coursework.",
        ]
        }
    }

    private func supplychainCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "your supply chain isn't going to optimize itself.",
            "get back to your logistics assignment.",
            "your CPIM prep won't do itself.",
            "close this and open your SCM notes.",
        ]
        case 2: return [
            "supply chain professionals don't get their CPIM by scrolling.",
            "your logistics assignment isn't going to complete itself.",
            "stop avoiding your supply chain work.",
        ]
        default: return [
            "CLOSE THIS. open your supply chain notes.",
            "no one gets their CPIM by browsing.",
            "CLOSE THIS. get back to your logistics work.",
        ]
        }
    }

    private func communicationstudiesCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that communication paper isn't going to write itself.",
            "get back to your comm notes.",
            "your communication theory exam won't study itself.",
            "close this and open your comm textbook.",
        ]
        case 2: return [
            "comm majors don't ace theory by scrolling.",
            "your communication assignment isn't going to complete itself.",
            "stop putting off your comm work.",
        ]
        default: return [
            "CLOSE THIS. open your communication studies notes.",
            "no one aces communication theory by browsing.",
            "CLOSE THIS. get back to your comm assignment.",
        ]
        }
    }

    private func healthcareadminCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those EHR records aren't going to manage themselves.",
            "get back to your healthcare administration work.",
            "your RHIA prep won't do itself.",
            "close this and open your health informatics notes.",
        ]
        case 2: return [
            "health information managers don't pass the RHIA by scrolling.",
            "your healthcare admin assignment isn't going to complete itself.",
            "stop avoiding your health informatics work.",
        ]
        default: return [
            "CLOSE THIS. open your healthcare administration notes.",
            "no one gets their RHIA by browsing.",
            "CLOSE THIS. get back to your health informatics work.",
        ]
        }
    }

    private func neuroscienceCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those neurons won't study themselves.",
            "get back to your neuroscience notes.",
            "your neuro exam won't prep itself.",
            "close this and open your neuroscience textbook.",
        ]
        case 2: return [
            "neuroscientists don't understand the brain by scrolling.",
            "your neuroscience assignment isn't going to complete itself.",
            "stop procrastinating on your neuro work.",
        ]
        default: return [
            "CLOSE THIS. open your neuroscience notes.",
            "no one aces neuroanatomy by browsing.",
            "CLOSE THIS. get back to your neuro study.",
        ]
        }
    }

    private func ethnicstudiesCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that ethnic studies paper isn't going to write itself.",
            "get back to your gender studies notes.",
            "your critical race theory reading won't do itself.",
            "close this and open your ethnic studies textbook.",
        ]
        case 2: return [
            "critical scholars don't build their analysis by scrolling.",
            "your ethnic studies assignment isn't going to complete itself.",
            "stop avoiding your gender studies work.",
        ]
        default: return [
            "CLOSE THIS. open your ethnic studies notes.",
            "no one masters intersectionality theory by browsing.",
            "CLOSE THIS. get back to your ethnic studies work.",
        ]
        }
    }

    private func humanfactorsCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those ergonomics concepts won't memorize themselves.",
            "get back to your human factors assignment.",
            "your HFE exam won't prep itself.",
            "close this and open your human factors notes.",
        ]
        case 2: return [
            "human factors engineers don't design safer systems by scrolling.",
            "your ergonomics assignment isn't going to complete itself.",
            "stop avoiding your human factors work.",
        ]
        default: return [
            "CLOSE THIS. open your human factors notes.",
            "no one passes the BCPE by browsing.",
            "CLOSE THIS. get back to your ergonomics assignment.",
        ]
        }
    }

    private func behavioraleconomicsCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those cognitive biases won't study themselves.",
            "get back to your behavioral economics notes.",
            "your behavioral econ exam won't prep itself.",
            "close this and open your behavioral economics textbook.",
        ]
        case 2: return [
            "behavioral economists don't understand bias by scrolling.",
            "your behavioral economics assignment isn't going to complete itself.",
            "stop procrastinating on your behavioral econ work.",
        ]
        default: return [
            "CLOSE THIS. open your behavioral economics notes.",
            "no one understands nudge theory by browsing.",
            "CLOSE THIS. Kahneman didn't write Thinking Fast and Slow by scrolling.",
        ]
        }
    }

    private func translationalresearchCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that research won't translate itself.",
            "get back to your translational research work.",
            "your bench-to-bedside project won't progress itself.",
            "close this and open your research notes.",
        ]
        case 2: return [
            "translational researchers don't advance medicine by scrolling.",
            "your clinical translation assignment isn't going to complete itself.",
            "stop avoiding your translational research.",
        ]
        default: return [
            "CLOSE THIS. open your translational research notes.",
            "no one advances medicine by browsing.",
            "CLOSE THIS. your bench-to-bedside work won't happen without you.",
        ]
        }
    }

    private func healthcarelawCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that health law brief isn't going to write itself.",
            "get back to your healthcare law notes.",
            "your health law exam won't prep itself.",
            "close this and open your healthcare law textbook.",
        ]
        case 2: return [
            "health lawyers don't master HIPAA by scrolling.",
            "your healthcare law assignment isn't going to complete itself.",
            "stop avoiding your health law work.",
        ]
        default: return [
            "CLOSE THIS. open your health law notes.",
            "no one passes the health law exam by browsing.",
            "CLOSE THIS. get back to your healthcare regulation assignment.",
        ]
        }
    }

    private func tradelawCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that trade law brief isn't going to write itself.",
            "get back to your international law notes.",
            "your trade law exam won't prep itself.",
            "close this and open your international law textbook.",
        ]
        case 2: return [
            "international lawyers don't master WTO rules by scrolling.",
            "your trade law assignment isn't going to complete itself.",
            "stop avoiding your international law work.",
        ]
        default: return [
            "CLOSE THIS. open your trade law notes.",
            "no one masters international arbitration by browsing.",
            "CLOSE THIS. get back to your trade compliance assignment.",
        ]
        }
    }

    private func cosmetologyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those clients aren't going to style themselves.",
            "get back to your cosmetology textbook.",
            "your state board exam won't prep itself.",
            "close this and open your milady chapter.",
        ]
        case 2: return [
            "cosmetologists don't pass state boards by scrolling.",
            "your clients deserve a licensed professional — focus.",
            "stop avoiding your cosmetology notes.",
        ]
        default: return [
            "CLOSE THIS. open your cosmetology study materials.",
            "no one passes their state board by browsing.",
            "CLOSE THIS. get back to your esthetics or nail tech work.",
        ]
        }
    }

    private func personaltrainingCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those clients aren't going to train themselves.",
            "your NASM exam won't prep itself.",
            "get back to your personal training certification materials.",
            "close this and open your program design notes.",
        ]
        case 2: return [
            "personal trainers don't get certified by scrolling.",
            "your clients need you focused — get back to your study materials.",
            "stop avoiding your training program design work.",
        ]
        default: return [
            "CLOSE THIS. open your NASM or ACE study guide.",
            "no one passes a fitness certification by browsing.",
            "CLOSE THIS. get back to your personal training materials.",
        ]
        }
    }

    private func dentallabCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those crowns aren't going to fabricate themselves.",
            "get back to your dental lab notes.",
            "your NBDALE exam won't prep itself.",
            "close this and open your dental ceramics work.",
        ]
        case 2: return [
            "dental lab techs don't get certified by scrolling.",
            "your crown-and-bridge assignment isn't going to complete itself.",
            "stop avoiding your dental lab work.",
        ]
        default: return [
            "CLOSE THIS. open your dental lab materials.",
            "no one passes the NBDALE by browsing.",
            "CLOSE THIS. get back to your dental laboratory work.",
        ]
        }
    }

    private func landscapearchitectureCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that planting plan isn't going to draw itself.",
            "get back to your landscape architecture project.",
            "your CLARB exam won't prep itself.",
            "close this and open your site design work.",
        ]
        case 2: return [
            "landscape architects don't get licensed by scrolling.",
            "your planting design isn't going to complete itself.",
            "stop avoiding your landscape architecture assignment.",
        ]
        default: return [
            "CLOSE THIS. open your landscape architecture project.",
            "no one passes the CLARB by browsing.",
            "CLOSE THIS. get back to your site design or planting plan.",
        ]
        }
    }

    private func immigrationlawCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those visa petitions aren't going to file themselves.",
            "get back to your immigration law notes.",
            "your immigration case isn't going to prepare itself.",
            "close this and open your USCIS forms.",
        ]
        case 2: return [
            "immigration clients need you focused — get back to their case.",
            "your asylum brief isn't going to write itself.",
            "stop avoiding your immigration law assignment.",
        ]
        default: return [
            "CLOSE THIS. open your immigration law materials.",
            "no one masters immigration law by browsing.",
            "CLOSE THIS. get back to your visa petition or removal defense.",
        ]
        }
    }

    private func musiceducationCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "your students are counting on you — close this.",
            "get back to your music education notes.",
            "your Praxis music exam won't prep itself.",
            "close this and open your music methods materials.",
        ]
        case 2: return [
            "music teachers don't get certified by scrolling.",
            "your lesson plans aren't going to write themselves.",
            "stop avoiding your music education assignment.",
        ]
        default: return [
            "CLOSE THIS. open your music education study guide.",
            "no one passes Praxis music by browsing.",
            "CLOSE THIS. get back to your music teaching notes.",
        ]
        }
    }

    private func massagetherapyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those clients aren't going to relax themselves.",
            "get back to your massage therapy notes.",
            "your MBLEx exam won't prep itself.",
            "close this and open your massage therapy materials.",
        ]
        case 2: return [
            "massage therapists don't get licensed by scrolling.",
            "your technique notes aren't going to review themselves.",
            "stop avoiding your massage therapy assignment.",
        ]
        default: return [
            "CLOSE THIS. open your massage therapy study guide.",
            "no one passes the MBLEx by browsing.",
            "CLOSE THIS. get back to your massage therapy notes.",
        ]
        }
    }

    private func medicallabscienceCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those lab results aren't going to analyze themselves.",
            "get back to your medical lab science notes.",
            "your ASCP exam won't prep itself.",
            "close this and open your clinical laboratory materials.",
        ]
        case 2: return [
            "medical lab scientists don't get certified by scrolling.",
            "your hematology notes aren't going to review themselves.",
            "stop avoiding your clinical laboratory assignment.",
        ]
        default: return [
            "CLOSE THIS. open your medical laboratory science study guide.",
            "no one passes the ASCP boards by browsing.",
            "CLOSE THIS. get back to your clinical lab materials.",
        ]
        }
    }

    private func radiologictechnologyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those images aren't going to read themselves.",
            "get back to your radiologic technology notes.",
            "your ARRT exam won't prep itself.",
            "close this and open your radiography materials.",
        ]
        case 2: return [
            "radiology techs don't get certified by scrolling.",
            "your positioning protocols aren't going to review themselves.",
            "stop avoiding your radiologic technology assignment.",
        ]
        default: return [
            "CLOSE THIS. open your radiologic technology study guide.",
            "no one passes the ARRT by browsing.",
            "CLOSE THIS. get back to your radiography notes.",
        ]
        }
    }

    private func intellectualpropertyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those patent claims aren't going to draft themselves.",
            "get back to your IP law notes.",
            "your patent bar exam won't prep itself.",
            "close this and open your intellectual property materials.",
        ]
        case 2: return [
            "IP attorneys don't get there by scrolling.",
            "your trademark brief isn't going to write itself.",
            "stop avoiding your intellectual property assignment.",
        ]
        default: return [
            "CLOSE THIS. open your IP law study materials.",
            "no one passes the patent bar by browsing.",
            "CLOSE THIS. get back to your patent prosecution notes.",
        ]
        }
    }

    private func signlanguageCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those signs aren't going to practice themselves.",
            "get back to your ASL notes.",
            "your sign language exam won't prep itself.",
            "close this and open your ASL study materials.",
        ]
        case 2: return [
            "sign language interpreters don't get certified by scrolling.",
            "your deaf community deserves your full attention — get back to your ASL work.",
            "stop avoiding your sign language assignment.",
        ]
        default: return [
            "CLOSE THIS. open your ASL study guide.",
            "no one masters sign language by browsing.",
            "CLOSE THIS. get back to your sign language notes.",
        ]
        }
    }

    private func acupunctureCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those acupuncture points aren't going to memorize themselves.",
            "get back to your TCM notes.",
            "your NCCAOM exam won't prep itself.",
            "close this and open your acupuncture study materials.",
        ]
        case 2: return [
            "acupuncturists don't get licensed by scrolling.",
            "your meridian theory notes aren't going to review themselves.",
            "stop avoiding your acupuncture or TCM assignment.",
        ]
        default: return [
            "CLOSE THIS. open your acupuncture or TCM study guide.",
            "no one passes the NCCAOM boards by browsing.",
            "CLOSE THIS. get back to your traditional Chinese medicine notes.",
        ]
        }
    }

    private func arteducationCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "your students are waiting — get back to your art curriculum.",
            "that art lesson plan isn't going to write itself.",
            "your Praxis art exam won't prep itself.",
            "close this and open your art education materials.",
        ]
        case 2: return [
            "art teachers don't get certified by scrolling.",
            "your visual arts lesson plans aren't going to design themselves.",
            "stop avoiding your art education assignment.",
        ]
        default: return [
            "CLOSE THIS. open your art education study guide.",
            "no one passes the Praxis art exam by browsing.",
            "CLOSE THIS. get back to your visual arts teaching notes.",
        ]
        }
    }

    private func environmentallawCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that environmental brief isn't going to write itself.",
            "get back to your environmental law notes.",
            "your environmental law exam won't prep itself.",
            "close this and open your environmental law materials.",
        ]
        case 2: return [
            "environmental lawyers don't master NEPA by scrolling.",
            "your Clean Air Act analysis isn't going to complete itself.",
            "stop avoiding your environmental law assignment.",
        ]
        default: return [
            "CLOSE THIS. open your environmental law notes.",
            "no one masters environmental regulation by browsing.",
            "CLOSE THIS. get back to your environmental law or climate litigation work.",
        ]
        }
    }

    private func familylawCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those family law briefs aren't going to write themselves.",
            "get back to your family law notes.",
            "your family law exam won't prep itself.",
            "close this and open your family law materials.",
        ]
        case 2: return [
            "family law attorneys don't master custody law by scrolling.",
            "your domestic relations brief isn't going to write itself.",
            "stop avoiding your family law assignment.",
        ]
        default: return [
            "CLOSE THIS. open your family law notes.",
            "no one masters family law by browsing.",
            "CLOSE THIS. get back to your divorce, custody, or adoption law work.",
        ]
        }
    }

    private func nuclearmedtechCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those nuclear medicine boards aren't going to prep themselves.",
            "get back to your nuclear medicine studies.",
            "your CNMT exam won't prep itself.",
            "close this and open your nuclear medicine study guide.",
        ]
        case 2: return [
            "nuclear medicine technologists don't get certified by scrolling.",
            "your radiopharmaceutical protocols won't memorize themselves.",
            "stop avoiding your nuclear medicine class work.",
        ]
        default: return [
            "CLOSE THIS. open your nuclear medicine or CNMT study guide.",
            "no one passes the CNMT by scrolling.",
            "CLOSE THIS. get back to your nuclear medicine school work.",
        ]
        }
    }

    private func sonographyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those sonography skills aren't going to develop themselves.",
            "get back to your ultrasound studies.",
            "your ARDMS exam won't prep itself.",
            "close this and open your sonography study guide.",
        ]
        case 2: return [
            "sonographers don't get certified by scrolling.",
            "your ultrasound physics won't memorize itself.",
            "stop avoiding your sonography class work.",
        ]
        default: return [
            "CLOSE THIS. open your sonography or ARDMS study guide.",
            "no one passes the ARDMS registry by scrolling.",
            "CLOSE THIS. get back to your diagnostic medical sonography work.",
        ]
        }
    }

    private func cardiovasculartechCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those cardiovascular tech exams aren't going to prep themselves.",
            "get back to your cardiovascular technology studies.",
            "your CCI board won't prep itself.",
            "close this and open your cardiovascular tech notes.",
        ]
        case 2: return [
            "cardiovascular technologists don't get certified by scrolling.",
            "your cardiac cath lab protocols won't learn themselves.",
            "stop avoiding your cardiovascular tech class work.",
        ]
        default: return [
            "CLOSE THIS. open your cardiovascular technology study guide.",
            "no one passes the CCI board by scrolling.",
            "CLOSE THIS. get back to your cardiovascular tech school work.",
        ]
        }
    }

    private func surgicaltechCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those surgical instruments aren't going to memorize themselves.",
            "get back to your surgical technology studies.",
            "your CST exam won't prep itself.",
            "close this and open your surgical tech notes.",
        ]
        case 2: return [
            "surgical technologists don't get certified by scrolling.",
            "your sterile field technique won't review itself.",
            "stop avoiding your surgical tech class work.",
        ]
        default: return [
            "CLOSE THIS. open your surgical technology study guide.",
            "no one passes the CST by scrolling.",
            "CLOSE THIS. get back to your surgical tech school work.",
        ]
        }
    }

    private func arttherapyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "your clients deserve your full attention — get back to your art therapy notes.",
            "that art therapy session plan isn't going to write itself.",
            "get back to your art therapy study materials.",
            "close this and open your art therapy notes.",
        ]
        case 2: return [
            "art therapists don't get credentialed by scrolling.",
            "your ATR board prep won't do itself.",
            "stop avoiding your art therapy class work.",
        ]
        default: return [
            "CLOSE THIS. open your art therapy or ATR study guide.",
            "no one earns their ATR by scrolling.",
            "CLOSE THIS. get back to your art therapy school work.",
        ]
        }
    }

    private func polysomnographyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those sleep scoring protocols aren't going to memorize themselves.",
            "get back to your polysomnography studies.",
            "your RPSGT exam won't prep itself.",
            "close this and open your sleep technology study guide.",
        ]
        case 2: return [
            "sleep technologists don't get certified by scrolling.",
            "your PSG scoring skills won't develop themselves.",
            "stop avoiding your polysomnography class work.",
        ]
        default: return [
            "CLOSE THIS. open your polysomnography or RPSGT study guide.",
            "no one passes the RPSGT by scrolling.",
            "CLOSE THIS. get back to your sleep technology school work.",
        ]
        }
    }

    private func nursinginformaticsCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that nursing informatics assignment isn't going to complete itself.",
            "get back to your clinical informatics study materials.",
            "your nursing informatics exam won't prep itself.",
            "close this and open your nursing informatics notes.",
        ]
        case 2: return [
            "nursing informaticists don't get certified by scrolling.",
            "your EHR implementation plan won't write itself.",
            "stop avoiding your nursing informatics class work.",
        ]
        default: return [
            "CLOSE THIS. open your nursing informatics or CNIO study guide.",
            "no one masters nursing informatics by browsing.",
            "CLOSE THIS. get back to your clinical informatics work.",
        ]
        }
    }

    private func musictherapyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "your clients deserve your full attention — get back to your music therapy notes.",
            "that music therapy session plan isn't going to write itself.",
            "get back to your MT-BC board study materials.",
            "close this and open your music therapy notes.",
        ]
        case 2: return [
            "music therapists don't get board-certified by scrolling.",
            "your MT-BC exam prep won't do itself.",
            "stop avoiding your music therapy class work.",
        ]
        default: return [
            "CLOSE THIS. open your music therapy or MT-BC study guide.",
            "no one earns their MT-BC by scrolling.",
            "CLOSE THIS. get back to your music therapy school work.",
        ]
        }
    }

    private func dramaeducationCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that drama lesson plan isn't going to write itself.",
            "get back to your theatre education work.",
            "your Praxis drama exam won't prep itself.",
            "close this and open your drama education notes.",
        ]
        case 2: return [
            "drama teachers don't master their craft by scrolling.",
            "your playwriting assignment won't finish itself.",
            "stop avoiding your theatre education class work.",
        ]
        default: return [
            "CLOSE THIS. open your drama education or Praxis theatre notes.",
            "no one becomes a drama teacher by browsing.",
            "CLOSE THIS. get back to your theatre education work.",
        ]
        }
    }

    private func winesommelierCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those wine regions aren't going to memorize themselves.",
            "get back to your sommelier study materials.",
            "your WSET exam won't prep itself.",
            "close this and open your wine education notes.",
        ]
        case 2: return [
            "sommeliers don't get certified by scrolling.",
            "your blind tasting skills won't develop themselves.",
            "stop avoiding your wine studies coursework.",
        ]
        default: return [
            "CLOSE THIS. open your sommelier or WSET study guide.",
            "no one passes the WSET by browsing.",
            "CLOSE THIS. get back to your wine education work.",
        ]
        }
    }

    private func gerontologyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those aging theories aren't going to study themselves.",
            "get back to your gerontology work.",
            "your geriatrics exam won't prep itself.",
            "close this and open your gerontology notes.",
        ]
        case 2: return [
            "gerontologists don't master aging science by scrolling.",
            "your aging studies assignment won't finish itself.",
            "stop avoiding your gerontology coursework.",
        ]
        default: return [
            "CLOSE THIS. open your gerontology or geriatrics notes.",
            "no one masters aging science by browsing.",
            "CLOSE THIS. get back to your gerontology work.",
        ]
        }
    }

    private func addictioncounselingCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "your clients need a focused counselor — get back to your notes.",
            "that CADC exam won't prep itself.",
            "your addiction counseling assignment isn't going to write itself.",
            "close this and open your substance use disorder notes.",
        ]
        case 2: return [
            "addiction counselors don't earn their credentials by scrolling.",
            "your dual diagnosis assignment won't finish itself.",
            "stop avoiding your addiction counseling coursework.",
        ]
        default: return [
            "CLOSE THIS. open your addiction counseling or NAADAC study guide.",
            "no one earns their CADC by browsing.",
            "CLOSE THIS. get back to your substance use disorder coursework.",
        ]
        }
    }

    private func oralsurgeryCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those oral surgery procedures aren't going to learn themselves.",
            "get back to your oral surgery coursework.",
            "your OMFS exam won't prep itself.",
            "close this and open your oral surgery notes.",
        ]
        case 2: return [
            "oral surgeons don't master their craft by scrolling.",
            "your orthognathic surgery assignment won't finish itself.",
            "stop avoiding your oral surgery coursework.",
        ]
        default: return [
            "CLOSE THIS. open your oral surgery or OMFS study guide.",
            "no one masters oral surgery by browsing.",
            "CLOSE THIS. get back to your dental surgery coursework.",
        ]
        }
    }

    private func publichealthlawCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that public health law brief isn't going to write itself.",
            "get back to your public health law coursework.",
            "your public health law exam won't prep itself.",
            "close this and open your public health law notes.",
        ]
        case 2: return [
            "public health lawyers don't master FDA regs by scrolling.",
            "your quarantine law assignment won't finish itself.",
            "stop avoiding your public health law coursework.",
        ]
        default: return [
            "CLOSE THIS. open your public health law notes.",
            "no one masters public health law by browsing.",
            "CLOSE THIS. get back to your public health law coursework.",
        ]
        }
    }

    private func diagnosticphysicsCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that dosimetry problem won't solve itself.",
            "get back to your medical physics coursework.",
            "your ABR physics exam won't prep itself.",
            "close this and open your medical physics notes.",
        ]
        case 2: return [
            "medical physicists don't get board certified by scrolling.",
            "your radiation protection assignment won't finish itself.",
            "stop avoiding your diagnostic physics coursework.",
        ]
        default: return [
            "CLOSE THIS. open your medical physics study guide.",
            "no one passes the ABR physics exam by browsing.",
            "CLOSE THIS. get back to your diagnostic medical physics coursework.",
        ]
        }
    }

    private func perfusiontechnologyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that bypass circuit isn't going to review itself.",
            "get back to your perfusion technology coursework.",
            "your PBSE certification exam won't prep itself.",
            "close this and open your perfusion notes.",
        ]
        case 2: return [
            "perfusionists don't get certified by scrolling.",
            "your cardiopulmonary bypass assignment won't finish itself.",
            "stop avoiding your perfusion coursework.",
        ]
        default: return [
            "CLOSE THIS. open your perfusion technology study guide.",
            "no one masters cardiovascular perfusion by browsing.",
            "CLOSE THIS. get back to your bypass perfusion coursework.",
        ]
        }
    }

    private func ophthalmicCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those ophthalmic procedures aren't going to learn themselves.",
            "get back to your ophthalmic medical technology coursework.",
            "your JCAHPO certification exam won't prep itself.",
            "close this and open your ophthalmic technology notes.",
        ]
        case 2: return [
            "ophthalmic technicians don't get certified by scrolling.",
            "your slit lamp and tonometry assignment won't finish itself.",
            "stop avoiding your ophthalmology technician coursework.",
        ]
        default: return [
            "CLOSE THIS. open your ophthalmic medical technology study guide.",
            "no one passes the COMT exam by browsing.",
            "CLOSE THIS. get back to your ophthalmic technician coursework.",
        ]
        }
    }

    private func centralsterileCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those sterilization protocols aren't going to memorize themselves.",
            "get back to your sterile processing coursework.",
            "your CRCST certification exam won't prep itself.",
            "close this and open your sterile processing notes.",
        ]
        case 2: return [
            "sterile processing technicians don't get certified by scrolling.",
            "your instrument decontamination assignment won't finish itself.",
            "stop avoiding your central sterile processing coursework.",
        ]
        default: return [
            "CLOSE THIS. open your central sterile processing study guide.",
            "no one passes the CBSPD exam by browsing.",
            "CLOSE THIS. get back to your sterile processing coursework.",
        ]
        }
    }

    private func opticianryCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those lens prescriptions aren't going to interpret themselves.",
            "get back to your opticianry coursework.",
            "your ABO exam won't prep itself.",
            "close this and open your opticianry study guide.",
        ]
        case 2: return [
            "dispensing opticians don't get licensed by scrolling.",
            "your optical dispensing assignment won't finish itself.",
            "stop avoiding your opticianry certification prep.",
        ]
        default: return [
            "CLOSE THIS. open your opticianry notes.",
            "no one passes the ABO-NCLE exam by browsing.",
            "CLOSE THIS. get back to your optical dispensing coursework.",
        ]
        }
    }

    private func dancetherapyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "your clients deserve your full attention — get back to your dance therapy notes.",
            "that treatment plan isn't going to write itself.",
            "your DMT board prep won't do itself.",
            "close this and open your dance therapy coursework.",
        ]
        case 2: return [
            "dance therapists don't get credentialed by scrolling.",
            "your dance therapy session notes won't write themselves.",
            "stop avoiding your dance movement therapy assignment.",
        ]
        default: return [
            "CLOSE THIS. open your dance therapy or ADTA study guide.",
            "no one earns the RDMT credential by browsing.",
            "CLOSE THIS. get back to your dance movement therapy coursework.",
        ]
        }
    }

    private func recreationtherapyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "your clients need you focused — get back to your recreation therapy notes.",
            "that CTRS study guide won't read itself.",
            "your therapeutic recreation assignment won't finish itself.",
            "close this and open your recreation therapy coursework.",
        ]
        case 2: return [
            "recreational therapists don't get certified by scrolling.",
            "your leisure education assignment won't complete itself.",
            "stop avoiding your CTRS exam prep.",
        ]
        default: return [
            "CLOSE THIS. open your recreation therapy study guide.",
            "no one passes the CTRS exam by browsing.",
            "CLOSE THIS. get back to your therapeutic recreation coursework.",
        ]
        }
    }

    private func horticulturetherapyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those plants aren't going to journal themselves — get back to your horticulture therapy notes.",
            "your HTR certification prep won't do itself.",
            "that therapeutic horticulture assignment isn't going to complete itself.",
            "close this and open your horticultural therapy coursework.",
        ]
        case 2: return [
            "horticultural therapists don't get registered by scrolling.",
            "your therapeutic gardening assignment won't finish itself.",
            "stop avoiding your horticultural therapy certification prep.",
        ]
        default: return [
            "CLOSE THIS. open your horticultural therapy study guide.",
            "no one earns the HTR credential by browsing.",
            "CLOSE THIS. get back to your therapeutic horticulture coursework.",
        ]
        }
    }

    private func dietetictechnologyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those nutrition assessments aren't going to write themselves.",
            "get back to your dietetic technician coursework.",
            "your DTR exam won't prep itself.",
            "close this and open your dietetic technician study guide.",
        ]
        case 2: return [
            "dietetic technicians don't get registered by scrolling.",
            "your NDTR exam prep won't do itself.",
            "stop avoiding your dietetic technology assignment.",
        ]
        default: return [
            "CLOSE THIS. open your dietetic technician notes.",
            "no one passes the DTR exam by browsing.",
            "CLOSE THIS. get back to your dietetic technician coursework.",
        ]
        }
    }

    private func occupationalmedicineCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those occupational medicine concepts aren't going to study themselves.",
            "your workplace health assessment report won't write itself.",
            "get back to your occupational medicine notes.",
            "close this and open your ACOEM study guide.",
        ]
        case 2: return [
            "occupational physicians don't pass their boards by scrolling.",
            "your industrial hygiene assignment won't complete itself.",
            "stop avoiding your occupational medicine coursework.",
        ]
        default: return [
            "CLOSE THIS. open your occupational medicine study guide.",
            "no one passes the ACOEM boards by browsing.",
            "CLOSE THIS. get back to your occupational and environmental medicine notes.",
        ]
        }
    }

    private func integrativemedicineCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that integrative medicine case study isn't going to write itself.",
            "your functional medicine coursework won't do itself.",
            "get back to your integrative health notes.",
            "close this and open your integrative medicine textbook.",
        ]
        case 2: return [
            "integrative practitioners don't get board certified by scrolling.",
            "your CAM therapy analysis won't complete itself.",
            "stop avoiding your holistic medicine assignment.",
        ]
        default: return [
            "CLOSE THIS. open your integrative medicine study guide.",
            "no one earns their ABIHM by browsing.",
            "CLOSE THIS. get back to your functional medicine coursework.",
        ]
        }
    }

    private func geneticcounselingCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those variant interpretations aren't going to analyze themselves.",
            "your genetic counseling case notes won't write themselves.",
            "get back to your ABGC exam prep.",
            "close this and open your genetics counseling notes.",
        ]
        case 2: return [
            "genetic counselors don't get board certified by scrolling.",
            "your hereditary cancer risk assessment won't do itself.",
            "stop avoiding your genetic counseling rotation notes.",
        ]
        default: return [
            "CLOSE THIS. open your genetic counseling study guide.",
            "no one passes the CGC board by browsing.",
            "CLOSE THIS. get back to your genomic counseling coursework.",
        ]
        }
    }

    private func behavioralhealthpromotionCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those health behavior theories aren't going to study themselves.",
            "your health education assignment won't write itself.",
            "get back to your CHES exam prep.",
            "close this and open your health promotion notes.",
        ]
        case 2: return [
            "health educators don't get certified by scrolling.",
            "your community health program plan won't design itself.",
            "stop avoiding your behavioral wellness coursework.",
        ]
        default: return [
            "CLOSE THIS. open your health promotion study guide.",
            "no one earns their CHES by browsing.",
            "CLOSE THIS. get back to your behavioral health education coursework.",
        ]
        }
    }

    private func dentalpublichealthCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that oral health policy brief isn't going to write itself.",
            "your dental public health assignment won't do itself.",
            "get back to your dental epidemiology notes.",
            "close this and open your dental public health study guide.",
        ]
        case 2: return [
            "oral health advocates don't get ahead by scrolling.",
            "your community dental program plan won't write itself.",
            "stop avoiding your dental public health coursework.",
        ]
        default: return [
            "CLOSE THIS. open your dental public health notes.",
            "no one masters dental epidemiology by browsing.",
            "CLOSE THIS. get back to your oral health policy work.",
        ]
        }
    }

    private func playwrightingCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that play isn't going to write itself.",
            "your characters are waiting — get back to your script.",
            "act 2 won't draft itself. close this.",
            "great playwrights write. close this and be one.",
        ]
        case 2: return [
            "your play is stalled while you scroll — get back to it.",
            "stop avoiding your script. open it now.",
            "the blank page is waiting. stop avoiding it.",
        ]
        default: return [
            "CLOSE THIS. open your play script.",
            "no one writes a great play by browsing.",
            "CLOSE THIS. your characters need you — not this.",
        ]
        }
    }

    private func sportsmedicineCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those athletes aren't going to assess themselves — get back to your notes.",
            "your sports medicine clinical notes won't write themselves.",
            "get back to your BOC exam prep.",
            "close this and open your sports medicine study guide.",
        ]
        case 2: return [
            "athletic trainers don't pass the BOC by scrolling.",
            "your sports injury assessment notes won't complete themselves.",
            "stop avoiding your sports medicine coursework.",
        ]
        default: return [
            "CLOSE THIS. open your sports medicine notes.",
            "no one passes the BOC by browsing.",
            "CLOSE THIS. get back to your athletic training clinical hours.",
        ]
        }
    }

    private func naturopathicmedicineCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those botanical medicine notes aren't going to study themselves.",
            "your NPLEX prep won't do itself — get back to your notes.",
            "get back to your naturopathic medicine coursework.",
            "close this and open your naturopathic study guide.",
        ]
        case 2: return [
            "naturopathic doctors don't pass the NPLEX by scrolling.",
            "your herbal medicine assignment won't write itself.",
            "stop avoiding your naturopathic school coursework.",
        ]
        default: return [
            "CLOSE THIS. open your NPLEX study guide.",
            "no one earns their ND by browsing.",
            "CLOSE THIS. get back to your botanical medicine notes.",
        ]
        }
    }

    private func midwiferyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those birth plans aren't going to write themselves.",
            "your AMCB prep won't do itself — get back to your notes.",
            "get back to your midwifery clinical notes.",
            "close this and open your midwifery study guide.",
        ]
        case 2: return [
            "midwives don't pass the AMCB by scrolling.",
            "your prenatal and postpartum notes won't write themselves.",
            "stop avoiding your midwifery coursework.",
        ]
        default: return [
            "CLOSE THIS. open your midwifery notes.",
            "no one earns their CNM by browsing.",
            "CLOSE THIS. get back to your birth plan documentation.",
        ]
        }
    }

    private func clinicalpsychologyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those assessment reports aren't going to write themselves.",
            "your APPIC internship application won't complete itself.",
            "get back to your clinical psychology practicum notes.",
            "close this and open your neuropsychological assessment materials.",
        ]
        case 2: return [
            "clinical psychologists don't match on internship by scrolling.",
            "your psychotherapy session notes won't write themselves.",
            "stop avoiding your clinical psychology doctoral work.",
        ]
        default: return [
            "CLOSE THIS. open your assessment report.",
            "no one completes a Psy.D by browsing.",
            "CLOSE THIS. get back to your clinical psychology coursework.",
        ]
        }
    }

    private func theatresoundCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that FOH mix isn't going to dial itself — get back to your notes.",
            "your sound design notes won't write themselves.",
            "get back to your live audio or audio tech coursework.",
            "close this and open your sound design study guide.",
        ]
        case 2: return [
            "audio engineers don't get hired by scrolling.",
            "your stage sound assignment won't complete itself.",
            "stop avoiding your audio tech coursework.",
        ]
        default: return [
            "CLOSE THIS. open your sound design notes.",
            "no one masters live audio by browsing.",
            "CLOSE THIS. get back to your theatre sound work.",
        ]
        }
    }

    private func dancescienceCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those movement analyses aren't going to write themselves — get back to your notes.",
            "your Laban movement analysis assignment won't complete itself.",
            "get back to your dance science or dance kinesiology coursework.",
            "close this and open your dance anatomy notes.",
        ]
        case 2: return [
            "dance scientists don't understand movement by scrolling.",
            "your somatic movement notes won't write themselves.",
            "stop avoiding your dance science coursework.",
        ]
        default: return [
            "CLOSE THIS. open your dance anatomy notes.",
            "no one learns Laban Movement Analysis by browsing.",
            "CLOSE THIS. get back to your dance science coursework.",
        ]
        }
    }

    private func forensicnursingCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "your patients need you focused — get back to your forensic nursing notes.",
            "those SANE exam prep materials aren't going to review themselves.",
            "get back to your forensic nursing documentation.",
            "close this and open your SANE certification study guide.",
        ]
        case 2: return [
            "forensic nurses don't pass the SANE exam by scrolling.",
            "your forensic nursing case notes won't write themselves.",
            "stop avoiding your forensic nursing coursework.",
        ]
        default: return [
            "CLOSE THIS. open your forensic nursing notes.",
            "no one earns their SANE credential by browsing.",
            "CLOSE THIS. get back to your forensic nursing documentation.",
        ]
        }
    }

    private func midwiferyassistingCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those doula training materials aren't going to study themselves.",
            "your DONA certification prep won't complete itself — get back to your notes.",
            "get back to your doula training or childbirth educator coursework.",
            "close this and open your doula training guide.",
        ]
        case 2: return [
            "birth doulas don't get certified by scrolling.",
            "your doula training assignment won't write itself.",
            "stop avoiding your doula certification coursework.",
        ]
        default: return [
            "CLOSE THIS. open your doula training notes.",
            "no one earns their DONA certification by browsing.",
            "CLOSE THIS. get back to your doula program coursework.",
        ]
        }
    }

    private func interpretingCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those interpreting skills aren't going to develop themselves — get back to practice.",
            "your RID certification prep won't complete itself.",
            "get back to your interpreting program coursework.",
            "close this and open your interpreting study guide.",
        ]
        case 2: return [
            "interpreters don't pass the RID exam by scrolling.",
            "your consecutive interpreting notes won't write themselves.",
            "stop avoiding your interpreter training coursework.",
        ]
        default: return [
            "CLOSE THIS. open your interpreting notes.",
            "no one earns RID certification by browsing.",
            "CLOSE THIS. get back to your interpreter training.",
        ]
        }
    }

    private func dramatherapyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those psychodrama techniques aren't going to learn themselves — get back to your notes.",
            "your drama therapy session notes won't write themselves.",
            "get back to your drama therapy or psychodrama coursework.",
            "close this and open your drama therapy study guide.",
        ]
        case 2: return [
            "drama therapists don't earn their credential by scrolling.",
            "your NADT exam prep won't complete itself.",
            "stop avoiding your drama therapy coursework.",
        ]
        default: return [
            "CLOSE THIS. open your drama therapy notes.",
            "no one earns their drama therapy credential by browsing.",
            "CLOSE THIS. get back to your psychodrama or drama therapy work.",
        ]
        }
    }

    private func horsemanshipCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those horse training techniques aren't going to learn themselves — get back to your notes.",
            "your equestrian coursework won't complete itself.",
            "get back to your horsemanship or equine science assignment.",
            "close this and open your equestrian study guide.",
        ]
        case 2: return [
            "equestrians don't ride better by scrolling.",
            "your horse management notes won't write themselves.",
            "stop avoiding your equestrian coursework.",
        ]
        default: return [
            "CLOSE THIS. open your horsemanship notes.",
            "no one masters equestrian skills by browsing.",
            "CLOSE THIS. get back to your equine science coursework.",
        ]
        }
    }

    private func glassblowingCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that glass isn't going to blow itself — get back to your notes.",
            "your glass arts coursework won't complete itself.",
            "get back to your glassblowing or glass arts assignment.",
            "close this and open your glass studio notes.",
        ]
        case 2: return [
            "glass artists don't master flameworking by scrolling.",
            "your glassblowing techniques won't learn themselves.",
            "stop avoiding your glass arts coursework.",
        ]
        default: return [
            "CLOSE THIS. open your glass studio notes.",
            "no one masters glassblowing by browsing.",
            "CLOSE THIS. get back to your glass arts coursework.",
        ]
        }
    }

    private func landsurveyingtechCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those survey calculations aren't going to work themselves out — get back to your notes.",
            "your land surveying coursework won't complete itself.",
            "get back to your survey technology or land surveying assignment.",
            "close this and open your surveying study guide.",
        ]
        case 2: return [
            "surveyors don't pass the FS exam by scrolling.",
            "your boundary survey notes won't write themselves.",
            "stop avoiding your land surveying coursework.",
        ]
        default: return [
            "CLOSE THIS. open your surveying notes.",
            "no one passes the fundamentals of surveying exam by browsing.",
            "CLOSE THIS. get back to your land surveying coursework.",
        ]
        }
    }

    private func environmentalengineeringCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that wastewater treatment design isn't going to write itself — get back to your notes.",
            "your environmental engineering coursework won't complete itself.",
            "get back to your water quality, air quality, or remediation assignment.",
            "close this and open your environmental engineering study guide.",
        ]
        case 2: return [
            "environmental engineers don't solve wastewater problems by scrolling.",
            "your remediation design notes won't write themselves.",
            "stop avoiding your environmental engineering coursework.",
        ]
        default: return [
            "CLOSE THIS. open your environmental engineering notes.",
            "no one designs wastewater treatment systems by browsing.",
            "CLOSE THIS. get back to your environmental engineering assignment.",
        ]
        }
    }

    private func techwritingCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that user manual isn't going to write itself — get back to your docs.",
            "your API documentation won't draft itself.",
            "get back to your technical writing or documentation assignment.",
            "close this and open your technical writing project.",
        ]
        case 2: return [
            "technical writers don't ship docs by scrolling.",
            "your user guide won't write itself.",
            "stop avoiding your technical documentation.",
        ]
        default: return [
            "CLOSE THIS. open your documentation project.",
            "no one earns the CPTC by browsing.",
            "CLOSE THIS. get back to your technical writing.",
        ]
        }
    }

    private func healthcoachingCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those behavior change techniques aren't going to master themselves — get back to your notes.",
            "your health coaching certification prep won't complete itself.",
            "get back to your wellness coaching or NBC-HWC exam study materials.",
            "close this and open your health coaching study guide.",
        ]
        case 2: return [
            "health coaches don't earn the NBHWC credential by scrolling.",
            "your behavior change coaching notes won't write themselves.",
            "stop avoiding your health coaching coursework.",
        ]
        default: return [
            "CLOSE THIS. open your health coaching notes.",
            "no one passes the NBHWC exam by browsing.",
            "CLOSE THIS. get back to your wellness coaching coursework.",
        ]
        }
    }

    private func podiatryCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those APMLE questions aren't going to answer themselves — get back to your notes.",
            "your podiatry school assignment won't complete itself.",
            "get back to your podiatric medicine or foot and ankle surgery coursework.",
            "close this and open your podiatry study guide.",
        ]
        case 2: return [
            "podiatrists don't earn their DPM by scrolling.",
            "your podiatric medicine notes won't write themselves.",
            "stop avoiding your podiatry school coursework.",
        ]
        default: return [
            "CLOSE THIS. open your podiatry notes.",
            "no one passes the APMLE by browsing.",
            "CLOSE THIS. get back to your podiatric medicine coursework.",
        ]
        }
    }

    private func classicalstudiesCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "Cicero didn't translate himself — get back to your Latin.",
            "that Greek text isn't going to translate itself.",
            "get back to your classical studies or ancient history assignment.",
            "close this and open your Latin or ancient Greek text.",
        ]
        case 2: return [
            "classical scholars don't master Latin by scrolling.",
            "your Greek translation won't write itself.",
            "stop avoiding your classical studies coursework.",
        ]
        default: return [
            "CLOSE THIS. open your Latin text.",
            "no one learns ancient Greek by browsing.",
            "CLOSE THIS. get back to your classical studies assignment.",
        ]
        }
    }

    private func pmrehabilitationCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those ABPMR board questions aren't going to answer themselves — get back to your notes.",
            "your PM&R coursework won't complete itself.",
            "get back to your physiatry or rehabilitation medicine assignment.",
            "close this and open your PM&R study guide.",
        ]
        case 2: return [
            "physiatrists don't earn board certification by scrolling.",
            "your rehabilitation medicine notes won't write themselves.",
            "stop avoiding your PM&R coursework.",
        ]
        default: return [
            "CLOSE THIS. open your physiatry notes.",
            "no one passes the ABPMR boards by browsing.",
            "CLOSE THIS. get back to your physical medicine and rehabilitation assignment.",
        ]
        }
    }

    private func performancenutritionCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those sports nutrition protocols aren't going to master themselves — get back to your notes.",
            "your performance nutrition coursework won't complete itself.",
            "get back to your sports dietetics or performance nutrition assignment.",
            "close this and open your CSSD study guide.",
        ]
        case 2: return [
            "sports dietitians don't earn the CSSD by scrolling.",
            "your athlete fueling notes won't write themselves.",
            "stop avoiding your performance nutrition coursework.",
        ]
        default: return [
            "CLOSE THIS. open your sports nutrition notes.",
            "no one passes the CSSD exam by browsing.",
            "CLOSE THIS. get back to your performance nutrition assignment.",
        ]
        }
    }

    private func horticulturecienceCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those plant science concepts aren't going to study themselves — get back to your notes.",
            "your horticulture science coursework won't complete itself.",
            "get back to your horticulture or plant science assignment.",
            "close this and open your horticulture study guide.",
        ]
        case 2: return [
            "horticulturists don't learn plant science by scrolling.",
            "your floriculture notes won't write themselves.",
            "stop avoiding your horticulture science coursework.",
        ]
        default: return [
            "CLOSE THIS. open your horticulture notes.",
            "no one passes the PCA exam or arborist certification by browsing.",
            "CLOSE THIS. get back to your horticulture science assignment.",
        ]
        }
    }

    private func globalhealthdevCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that development policy isn't going to write itself — get back to your notes.",
            "your international development coursework won't complete itself.",
            "get back to your global health or international development assignment.",
            "close this and open your development policy study guide.",
        ]
        case 2: return [
            "development professionals don't write proposals by scrolling.",
            "your NGO program notes won't write themselves.",
            "stop avoiding your international development coursework.",
        ]
        default: return [
            "CLOSE THIS. open your international development notes.",
            "no one gets into global health by browsing.",
            "CLOSE THIS. get back to your international development assignment.",
        ]
        }
    }

    private func maritimestudiesCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "your USCG license isn't going to earn itself — get back to your studies.",
            "those maritime charts aren't going to study themselves.",
            "your maritime coursework won't complete itself.",
            "close this and get back to your navigation or maritime class.",
        ]
        case 2: return [
            "seafarers don't earn their USCG certification by scrolling.",
            "your maritime notes won't write themselves.",
            "stop avoiding your maritime studies coursework.",
        ]
        default: return [
            "CLOSE THIS. open your maritime studies notes.",
            "no one earns a USCG license by scrolling.",
            "CLOSE THIS. get back to your maritime class assignment.",
        ]
        }
    }

    private func hvactechnologyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those EPA 608 questions aren't going to answer themselves — get back to your notes.",
            "your HVAC coursework won't complete itself.",
            "get back to your refrigeration or HVAC systems assignment.",
            "close this and open your HVAC study guide.",
        ]
        case 2: return [
            "HVAC technicians don't earn their certification by scrolling.",
            "your refrigeration notes won't memorize themselves.",
            "stop avoiding your HVAC coursework.",
        ]
        default: return [
            "CLOSE THIS. open your HVAC notes.",
            "no one passes the EPA 608 exam by browsing.",
            "CLOSE THIS. get back to your HVAC assignment.",
        ]
        }
    }

    private func constructionmanagementCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that construction project plan isn't going to write itself — get back to your assignment.",
            "your construction management coursework won't complete itself.",
            "get back to your estimating or scheduling assignment.",
            "close this and open your construction management study guide.",
        ]
        case 2: return [
            "construction managers don't earn their CCM by scrolling.",
            "your project schedule won't estimate itself.",
            "stop avoiding your construction management coursework.",
        ]
        default: return [
            "CLOSE THIS. open your construction management notes.",
            "no one earns the CCM by browsing.",
            "CLOSE THIS. get back to your construction project management assignment.",
        ]
        }
    }

    private func floristryweddingplanningCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those flower arrangements aren't going to design themselves — get back to your floral studies.",
            "your wedding planning coursework won't complete itself.",
            "get back to your floral design or wedding planning assignment.",
            "close this and open your floral design notes.",
        ]
        case 2: return [
            "AIFD-certified designers don't get there by scrolling.",
            "your wedding planning notes won't write themselves.",
            "stop avoiding your floral design coursework.",
        ]
        default: return [
            "CLOSE THIS. open your floral design notes.",
            "no one earns AIFD certification by browsing.",
            "CLOSE THIS. get back to your wedding planning or floral design assignment.",
        ]
        }
    }

    private func cosmeticchemistryCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those formulation notes aren't going to study themselves — get back to your cosmetic chemistry.",
            "your cosmetic science coursework won't complete itself.",
            "get back to your formulation or cosmetic chemistry assignment.",
            "close this and open your cosmetic chemistry notes.",
        ]
        case 2: return [
            "cosmetic chemists don't master formulation by scrolling.",
            "your ingredient notes won't write themselves.",
            "stop avoiding your cosmetic chemistry coursework.",
        ]
        default: return [
            "CLOSE THIS. open your cosmetic chemistry notes.",
            "no one becomes a cosmetic chemist by browsing.",
            "CLOSE THIS. get back to your cosmetic formulation assignment.",
        ]
        }
    }

    private func automotivetechCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those ASE study guides aren't going to read themselves.",
            "your engine isn't going to diagnose itself — get back to your auto tech coursework.",
            "close this and open your automotive technology notes.",
            "get back to your automotive service assignment.",
        ]
        case 2: return [
            "ASE technicians don't pass certification by browsing.",
            "your automotive lab notes won't write themselves.",
            "stop avoiding your auto tech coursework.",
        ]
        default: return [
            "CLOSE THIS. open your automotive technology notes.",
            "no one passes the ASE certification by scrolling.",
            "CLOSE THIS. get back to your engine diagnostics or automotive service assignment.",
        ]
        }
    }

    private func weldingtechnologyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those welding procedures aren't going to study themselves.",
            "your welds won't perfect themselves — get back to your welding coursework.",
            "close this and open your welding technology notes.",
            "get back to your welding certification prep.",
        ]
        case 2: return [
            "welding technicians don't pass the CWI by browsing.",
            "your welding lab notes won't write themselves.",
            "stop avoiding your welding technology coursework.",
        ]
        default: return [
            "CLOSE THIS. open your welding technology notes.",
            "no one passes the AWS or CWI certification by scrolling.",
            "CLOSE THIS. get back to your welding program assignment.",
        ]
        }
    }

    private func grantwritingCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that grant proposal isn't going to write itself.",
            "your NIH specific aims won't draft themselves — get back to your grant writing.",
            "close this and open your grant narrative.",
            "get back to your grant proposal.",
        ]
        case 2: return [
            "researchers don't land grants by scrolling.",
            "your grant application won't submit itself.",
            "stop avoiding your grant writing.",
        ]
        default: return [
            "CLOSE THIS. open your grant proposal.",
            "no one wins funding by browsing.",
            "CLOSE THIS. get back to your grant narrative or application.",
        ]
        }
    }

    private func animalhusbandryCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those livestock management notes aren't going to study themselves.",
            "your animal husbandry coursework won't complete itself — get back to it.",
            "close this and open your animal production notes.",
            "get back to your livestock management assignment.",
        ]
        case 2: return [
            "livestock producers don't learn animal husbandry by scrolling.",
            "your swine or poultry production notes won't write themselves.",
            "stop avoiding your animal science coursework.",
        ]
        default: return [
            "CLOSE THIS. open your animal husbandry notes.",
            "no one learns livestock management by browsing.",
            "CLOSE THIS. get back to your animal production assignment.",
        ]
        }
    }

    private func paralegalCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those CLA study materials aren't going to review themselves.",
            "your paralegal coursework won't complete itself — get back to it.",
            "close this and open your paralegal notes.",
            "get back to your paralegal studies assignment.",
        ]
        case 2: return [
            "paralegals don't earn their certification by browsing.",
            "your legal research notes won't write themselves.",
            "stop avoiding your paralegal coursework.",
        ]
        default: return [
            "CLOSE THIS. open your paralegal notes.",
            "no one passes the CLA or CP exam by scrolling.",
            "CLOSE THIS. get back to your paralegal studies assignment.",
        ]
        }
    }

    private func certifiedfinancialplannerCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that CFP study plan isn't going to complete itself.",
            "your financial planning clients deserve your full focus.",
            "close this and open your CFP study materials.",
            "get back to your financial planning coursework.",
        ]
        case 2: return [
            "financial planners don't earn CFP certification by scrolling.",
            "your financial planning notes won't review themselves.",
            "stop avoiding your CFP prep.",
        ]
        default: return [
            "CLOSE THIS. open your CFP study materials.",
            "no one passes the CFP exam by scrolling.",
            "CLOSE THIS. get back to your financial planning coursework.",
        ]
        }
    }

    private func soilscienceCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those soil profiles aren't going to classify themselves.",
            "your soil science coursework won't complete itself — get back to it.",
            "close this and open your soil science notes.",
            "get back to your pedology assignment.",
        ]
        case 2: return [
            "soil scientists don't earn their degree by scrolling.",
            "your soil taxonomy notes won't write themselves.",
            "stop avoiding your soil science coursework.",
        ]
        default: return [
            "CLOSE THIS. open your soil science notes.",
            "no one passes their soil science exam by scrolling.",
            "CLOSE THIS. get back to your soil characterization assignment.",
        ]
        }
    }

    private func industrialsafetyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those OSHA regulations aren't going to study themselves.",
            "your industrial safety coursework won't complete itself — get back to it.",
            "close this and open your industrial hygiene notes.",
            "get back to your occupational safety assignment.",
        ]
        case 2: return [
            "industrial hygienists don't earn CIH certification by scrolling.",
            "your hazard analysis notes won't write themselves.",
            "stop avoiding your industrial safety coursework.",
        ]
        default: return [
            "CLOSE THIS. open your industrial safety notes.",
            "no one earns their CIH certification by scrolling.",
            "CLOSE THIS. get back to your occupational safety assignment.",
        ]
        }
    }

    private func foodsafetyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that HACCP plan isn't going to write itself.",
            "your food safety coursework won't complete itself — get back to it.",
            "close this and open your food safety notes.",
            "get back to your ServSafe prep.",
        ]
        case 2: return [
            "food safety professionals don't pass ServSafe by scrolling.",
            "your food sanitation notes won't write themselves.",
            "stop avoiding your food safety coursework.",
        ]
        default: return [
            "CLOSE THIS. open your food safety notes.",
            "no one passes ServSafe by scrolling.",
            "CLOSE THIS. get back to your HACCP assignment.",
        ]
        }
    }

    private func appliedmusicCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that piece isn't going to practice itself.",
            "your audition rep won't learn itself — get back to the instrument.",
            "close this and go practice.",
            "your jury isn't going to pass itself.",
        ]
        case 2: return [
            "musicians don't get better by scrolling.",
            "your scales won't run themselves — put down the phone.",
            "stop avoiding the practice room.",
        ]
        default: return [
            "CLOSE THIS. go practice.",
            "no one passes their jury by scrolling.",
            "CLOSE THIS. pick up your instrument.",
        ]
        }
    }

    private func winemakingCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that wine isn't going to make itself.",
            "your cellar work won't finish itself — get back to it.",
            "close this and open your winemaking notes.",
            "your fermentation protocol isn't going to write itself.",
        ]
        case 2: return [
            "winemakers don't learn their craft by scrolling.",
            "your wine production assignment won't finish itself.",
            "stop avoiding your winemaking coursework.",
        ]
        default: return [
            "CLOSE THIS. open your winemaking lab notes.",
            "no one masters winemaking by scrolling.",
            "CLOSE THIS. get back to your cellar operations work.",
        ]
        }
    }

    private func forestryCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those trees aren't going to inventory themselves.",
            "your forestry assignment won't finish itself — get back to it.",
            "close this and open your silviculture notes.",
            "your timber cruise data isn't going to analyze itself.",
        ]
        case 2: return [
            "foresters don't manage forests by scrolling.",
            "your forest management plan won't write itself.",
            "stop avoiding your forestry coursework.",
        ]
        default: return [
            "CLOSE THIS. open your forestry notes.",
            "no one earns their forestry degree by scrolling.",
            "CLOSE THIS. get back to your forest inventory work.",
        ]
        }
    }

    private func aquaticscienceCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those fish aren't going to count themselves.",
            "your fisheries assignment won't finish itself — get back to it.",
            "close this and open your aquatic science notes.",
            "your aquaculture lab report isn't going to write itself.",
        ]
        case 2: return [
            "fisheries biologists don't study ecosystems by scrolling.",
            "your aquatic science coursework won't complete itself.",
            "stop avoiding your fisheries assignment.",
        ]
        default: return [
            "CLOSE THIS. open your aquatic science notes.",
            "no one earns their fisheries degree by scrolling.",
            "CLOSE THIS. get back to your aquaculture lab work.",
        ]
        }
    }

    private func emergencynursingCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those patients need you focused — close this.",
            "your CEN prep isn't going to do itself.",
            "close this and open your emergency nursing notes.",
            "your trauma nursing assignment won't finish itself.",
        ]
        case 2: return [
            "ER nurses don't pass the CEN by scrolling.",
            "your emergency nursing coursework won't complete itself.",
            "stop avoiding your trauma nursing notes.",
        ]
        default: return [
            "CLOSE THIS. open your emergency nursing notes.",
            "no one passes the CEN by scrolling.",
            "CLOSE THIS. get back to your trauma nursing work.",
        ]
        }
    }

    private func publichealthnutritionCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that community nutrition plan isn't going to write itself.",
            "your public health nutrition assignment won't finish itself — get back to it.",
            "close this and open your community nutrition notes.",
            "your WIC counseling coursework isn't going to complete itself.",
        ]
        case 2: return [
            "public health dietitians don't serve communities by scrolling.",
            "your nutrition education program won't complete itself.",
            "stop avoiding your public health nutrition coursework.",
        ]
        default: return [
            "CLOSE THIS. open your public health nutrition notes.",
            "no one serves their community by scrolling.",
            "CLOSE THIS. get back to your community nutrition work.",
        ]
        }
    }

    private func plumbingtechCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those plumbing code questions aren't going to answer themselves.",
            "your plumber exam isn't going to study itself.",
            "close this and open your plumbing notes.",
            "get back to your plumbing program coursework.",
        ]
        case 2: return [
            "journeyman plumbers don't earn their license by scrolling.",
            "your plumbing code notes won't write themselves.",
            "stop avoiding your plumbing coursework.",
        ]
        default: return [
            "CLOSE THIS. open your plumbing technology notes.",
            "no one passes the journeyman plumber exam by scrolling.",
            "plumbers don't get licensed by browsing.",
        ]
        }
    }

    private func electricaltechnologyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those NEC code questions aren't going to answer themselves.",
            "your journeyman exam isn't going to study itself.",
            "close this and open your electrical code notes.",
            "get back to your electrician program coursework.",
        ]
        case 2: return [
            "journeyman electricians don't earn their license by scrolling.",
            "your NEC code notes won't write themselves.",
            "stop avoiding your electrician coursework.",
        ]
        default: return [
            "CLOSE THIS. open your electrical technology notes.",
            "no one passes the journeyman electrician exam by scrolling.",
            "electricians don't get licensed by browsing.",
        ]
        }
    }

    private func materialscienceCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those phase diagrams aren't going to study themselves.",
            "your materials science lab report won't write itself.",
            "close this and open your materials science notes.",
            "get back to your materials engineering coursework.",
        ]
        case 2: return [
            "materials engineers don't master phase diagrams by scrolling.",
            "your crystallography notes won't write themselves.",
            "stop avoiding your materials science coursework.",
        ]
        default: return [
            "CLOSE THIS. open your materials science notes.",
            "no one masters metallurgy by scrolling.",
            "CLOSE THIS. get back to your materials engineering lab report.",
        ]
        }
    }

    private func networkengineeringCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those CCNA questions aren't going to answer themselves.",
            "your network exam isn't going to study itself.",
            "close this and open your networking notes.",
            "get back to your networking coursework.",
        ]
        case 2: return [
            "network engineers don't earn their CCNA by scrolling.",
            "your networking lab notes won't write themselves.",
            "stop avoiding your networking coursework.",
        ]
        default: return [
            "CLOSE THIS. open your networking notes.",
            "no one passes the CCNA by scrolling.",
            "CLOSE THIS. get back to your network engineering lab or exam prep.",
        ]
        }
    }

    private func environmentalhealthCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those REHS questions aren't going to answer themselves.",
            "your environmental health exam isn't going to study itself.",
            "close this and open your environmental health notes.",
            "get back to your environmental health coursework.",
        ]
        case 2: return [
            "environmental health specialists don't earn their REHS by scrolling.",
            "your environmental health notes won't write themselves.",
            "stop avoiding your environmental health coursework.",
        ]
        default: return [
            "CLOSE THIS. open your environmental health notes.",
            "no one passes the REHS exam by scrolling.",
            "CLOSE THIS. get back to your environmental health science assignment.",
        ]
        }
    }

    private func constructiontechCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those contractor exam questions aren't going to answer themselves.",
            "your construction tech assignment isn't going to finish itself.",
            "close this and open your construction technology notes.",
            "get back to your building trades coursework.",
        ]
        case 2: return [
            "contractors don't earn their license by scrolling.",
            "your carpentry notes won't write themselves.",
            "stop avoiding your construction tech coursework.",
        ]
        default: return [
            "CLOSE THIS. open your construction technology notes.",
            "no one earns their contractor license by scrolling.",
            "CLOSE THIS. get back to your building trades assignment.",
        ]
        }
    }

    private func urbandesignCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that streetscape isn't going to design itself.",
            "your urban design project isn't going to finish itself.",
            "close this and open your urban design studio notes.",
            "get back to your urban design coursework.",
        ]
        case 2: return [
            "urban designers don't shape public space by scrolling.",
            "your placemaking analysis won't write itself.",
            "stop avoiding your urban design work.",
        ]
        default: return [
            "CLOSE THIS. open your urban design notes.",
            "no one designs great public spaces by scrolling.",
            "CLOSE THIS. get back to your urban design studio project.",
        ]
        }
    }

    private func ceramicsandsculptureCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that pottery wheel isn't going to spin itself.",
            "your ceramics project isn't going to fire itself.",
            "close this and open your ceramics studio notes.",
            "get back to your ceramics coursework.",
        ]
        case 2: return [
            "ceramic artists don't master the wheel by scrolling.",
            "your clay isn't going to shape itself.",
            "stop avoiding your ceramics work.",
        ]
        default: return [
            "CLOSE THIS. get back to your pottery wheel.",
            "no one masters ceramics by scrolling.",
            "CLOSE THIS. open your ceramics notes.",
        ]
        }
    }

    private func exercisescienceCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those ACSM questions aren't going to answer themselves.",
            "your exercise science assignment isn't going to finish itself.",
            "close this and open your exercise science notes.",
            "get back to your exercise science coursework.",
        ]
        case 2: return [
            "exercise scientists don't earn their degree by scrolling.",
            "your exercise testing lab report won't write itself.",
            "stop avoiding your exercise science coursework.",
        ]
        default: return [
            "CLOSE THIS. open your exercise science notes.",
            "no one passes the ACSM exam by scrolling.",
            "CLOSE THIS. get back to your exercise science lab or exam prep.",
        ]
        }
    }

    private func biochemistryCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those enzyme kinetics questions aren't going to answer themselves.",
            "your biochemistry lab report isn't going to write itself.",
            "close this and open your biochemistry notes.",
            "get back to your biochemistry coursework.",
        ]
        case 2: return [
            "biochemists don't master enzyme kinetics by scrolling.",
            "your Michaelis-Menten analysis won't finish itself.",
            "stop avoiding your biochemistry lab work.",
        ]
        default: return [
            "CLOSE THIS. open your biochemistry lab notes.",
            "no one masters biochemistry by scrolling.",
            "CLOSE THIS. get back to your biochemistry assignment.",
        ]
        }
    }

    private func agriculturalscienceCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those agronomy questions aren't going to answer themselves.",
            "your crop science assignment won't finish itself.",
            "close this and open your agricultural science notes.",
            "get back to your agronomy coursework.",
        ]
        case 2: return [
            "agronomists don't master crop science by scrolling.",
            "your precision agriculture lab report won't write itself.",
            "stop avoiding your agricultural science assignment.",
        ]
        default: return [
            "CLOSE THIS. open your agronomy study guide.",
            "no one earns an agronomy degree by scrolling.",
            "CLOSE THIS. get back to your crop science coursework.",
        ]
        }
    }

    private func textilesfashionCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those fiber arts techniques aren't going to master themselves.",
            "your weaving project won't finish itself.",
            "close this and get back to your loom.",
            "that dyeing assignment isn't going to complete itself.",
        ]
        case 2: return [
            "weavers don't master their craft by scrolling.",
            "your textile engineering assignment won't finish itself.",
            "stop avoiding your fiber arts coursework.",
        ]
        default: return [
            "CLOSE THIS. get back to your weaving studio.",
            "no one masters fiber arts by scrolling.",
            "CLOSE THIS. open your textile science notes.",
        ]
        }
    }

    private func geographyearthedCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those geography concepts aren't going to memorize themselves.",
            "your human geography assignment won't finish itself.",
            "close this and open your geography notes.",
            "get back to your AP Geography coursework.",
        ]
        case 2: return [
            "geographers don't understand place by scrolling.",
            "your physical geography lab report won't write itself.",
            "stop avoiding your geography exam prep.",
        ]
        default: return [
            "CLOSE THIS. open your geography study guide.",
            "no one passes AP Human Geography by browsing.",
            "CLOSE THIS. get back to your geography coursework.",
        ]
        }
    }

    private func childlifeCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those CCLS exam questions aren't going to answer themselves.",
            "your child life session notes won't write themselves.",
            "close this and open your child life study guide.",
            "get back to your child life specialist coursework.",
        ]
        case 2: return [
            "child life specialists don't get certified by scrolling.",
            "your therapeutic play assignment won't finish itself.",
            "stop avoiding your CCLS board exam prep.",
        ]
        default: return [
            "CLOSE THIS. open your child life certification study guide.",
            "no one passes the CCLS exam by browsing.",
            "CLOSE THIS. get back to your child life coursework.",
        ]
        }
    }

    private func qualitymanagementCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those CQE exam questions aren't going to answer themselves.",
            "your quality management assignment won't finish itself.",
            "close this and open your ISO audit notes.",
            "get back to your quality engineering coursework.",
        ]
        case 2: return [
            "quality engineers don't earn their certification by scrolling.",
            "your statistical process control assignment won't do itself.",
            "stop avoiding your quality management exam prep.",
        ]
        default: return [
            "CLOSE THIS. open your CQE exam study guide.",
            "no one passes the ASQ CQE exam by browsing.",
            "CLOSE THIS. get back to your quality systems coursework.",
        ]
        }
    }

    private func quantumcomputingCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those quantum circuits aren't going to build themselves.",
            "your quantum algorithm assignment won't finish itself.",
            "close this and open your Qiskit notebook.",
            "get back to your quantum computing coursework.",
        ]
        case 2: return [
            "quantum computing pioneers didn't discover superposition by scrolling.",
            "your quantum gate assignment won't complete itself.",
            "stop avoiding your IBM Quantum lab.",
        ]
        default: return [
            "CLOSE THIS. open your quantum computing study guide.",
            "no one masters quantum algorithms by browsing.",
            "CLOSE THIS. get back to your quantum computing coursework.",
        ]
        }
    }

    private func cloudcomputingCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those AWS certification questions aren't going to answer themselves.",
            "your cloud architecture assignment won't finish itself.",
            "close this and open your cloud computing study guide.",
            "get back to your DevOps or cloud certification prep.",
        ]
        case 2: return [
            "cloud engineers don't earn their AWS certification by scrolling.",
            "your Terraform or Kubernetes assignment won't do itself.",
            "stop avoiding your cloud computing exam prep.",
        ]
        default: return [
            "CLOSE THIS. open your AWS or Azure certification guide.",
            "no one passes the cloud certification exam by browsing.",
            "CLOSE THIS. get back to your cloud computing coursework.",
        ]
        }
    }

    private func softwaretestingCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those ISTQB exam questions aren't going to answer themselves.",
            "your test automation assignment won't finish itself.",
            "close this and open your QA engineering study guide.",
            "get back to your software testing coursework.",
        ]
        case 2: return [
            "QA engineers don't earn their certification by scrolling.",
            "your Selenium or pytest lab won't complete itself.",
            "stop avoiding your software quality assurance exam prep.",
        ]
        default: return [
            "CLOSE THIS. open your software testing study guide.",
            "no one passes the ISTQB exam by browsing.",
            "CLOSE THIS. get back to your QA engineering coursework.",
        ]
        }
    }

    private func mechanicaldraftingCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those blueprints aren't going to read themselves.",
            "your technical drawing assignment won't finish itself.",
            "close this and open your drafting notes.",
            "get back to your mechanical drafting coursework.",
        ]
        case 2: return [
            "drafting technicians don't get certified by scrolling.",
            "your engineering drawing assignment won't complete itself.",
            "stop avoiding your blueprint reading and drafting exam prep.",
        ]
        default: return [
            "CLOSE THIS. open your drafting textbook.",
            "no one passes the drafting certification exam by browsing.",
            "CLOSE THIS. get back to your technical drawing coursework.",
        ]
        }
    }

    private func dataengineeringCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that ETL pipeline isn't going to build itself.",
            "your data engineering assignment won't finish itself.",
            "close this and open your Spark or Airflow project.",
            "get back to your data engineering coursework.",
        ]
        case 2: return [
            "data engineers don't build pipelines by scrolling.",
            "your data warehouse design won't complete itself.",
            "stop avoiding your data pipeline project.",
        ]
        default: return [
            "CLOSE THIS. open your data engineering project.",
            "no one masters Spark and Kafka by browsing.",
            "CLOSE THIS. get back to your data engineering coursework.",
        ]
        }
    }

    private func roboticsCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "your robot isn't going to program itself.",
            "get back to your robotics assignment.",
            "close this and open your ROS project.",
            "your robotics coursework won't finish itself.",
        ]
        case 2: return [
            "robots don't build themselves — close this and build yours.",
            "your autonomous systems project isn't going to code itself.",
            "stop avoiding your robotics lab.",
        ]
        default: return [
            "CLOSE THIS. open your robotics project.",
            "no one masters ROS by scrolling.",
            "CLOSE THIS. get back to your robotics coursework.",
        ]
        }
    }

    private func artificialintelligenceCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "your AI assignment isn't going to write itself.",
            "get back to your artificial intelligence coursework.",
            "close this and study your AI concepts.",
            "your AI ethics paper won't finish itself.",
        ]
        case 2: return [
            "AI pioneers didn't build the field by scrolling.",
            "your prompt engineering assignment isn't going to complete itself.",
            "stop avoiding your AI class materials.",
        ]
        default: return [
            "CLOSE THIS. open your AI coursework.",
            "no one understands AI by browsing — close this.",
            "CLOSE THIS. get back to your artificial intelligence assignment.",
        ]
        }
    }

    private func osteopathicmedicineCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those COMLEX questions aren't going to answer themselves.",
            "get back to your osteopathic medicine coursework.",
            "close this and open your OMM notes.",
            "your DO school assignment won't finish itself.",
        ]
        case 2: return [
            "osteopathic doctors don't pass COMLEX by scrolling.",
            "your OMM technique notes aren't going to review themselves.",
            "stop avoiding your osteopathic medicine coursework.",
        ]
        default: return [
            "CLOSE THIS. open your COMLEX study guide.",
            "no one passes COMLEX-USA by browsing.",
            "CLOSE THIS. get back to your osteopathic medicine notes.",
        ]
        }
    }

    private func epidemiologyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that epi analysis isn't going to write itself.",
            "get back to your epidemiology assignment.",
            "close this and open your epi coursework.",
            "your outbreak investigation won't finish itself.",
        ]
        case 2: return [
            "epidemiologists don't track outbreaks by scrolling.",
            "your case-control study isn't going to design itself.",
            "stop avoiding your epidemiology coursework.",
        ]
        default: return [
            "CLOSE THIS. open your epi notes.",
            "no one masters epidemiology methods by browsing.",
            "CLOSE THIS. get back to your epidemiology assignment.",
        ]
        }
    }

    private func bioethicsCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "your IRB protocol isn't going to write itself.",
            "get back to your bioethics assignment.",
            "close this and work on your research ethics paper.",
            "your bioethics paper won't finish itself.",
        ]
        case 2: return [
            "bioethicists don't resolve dilemmas by scrolling.",
            "your clinical ethics consultation notes aren't going to write themselves.",
            "stop avoiding your bioethics coursework.",
        ]
        default: return [
            "CLOSE THIS. open your bioethics notes.",
            "no one masters research ethics by browsing.",
            "CLOSE THIS. get back to your IRB protocol or bioethics paper.",
        ]
        }
    }

    private func blockchainCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "your smart contract isn't going to write itself.",
            "get back to your blockchain assignment.",
            "close this and open your Solidity project.",
            "your blockchain coursework won't finish itself.",
        ]
        case 2: return [
            "blockchain developers don't build dApps by scrolling.",
            "your smart contracts aren't going to deploy themselves.",
            "stop avoiding your blockchain coursework.",
        ]
        default: return [
            "CLOSE THIS. open your blockchain project.",
            "no one masters smart contracts by browsing.",
            "CLOSE THIS. get back to your Solidity or Web3 assignment.",
        ]
        }
    }

    private func digitalmarketingCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "your SEO campaign isn't going to optimize itself.",
            "get back to your digital marketing assignment.",
            "close this and open your marketing analytics dashboard.",
            "your digital marketing coursework won't finish itself.",
        ]
        case 2: return [
            "digital marketers don't earn certifications by scrolling.",
            "your Google Ads campaign isn't going to write itself.",
            "stop avoiding your digital marketing coursework.",
        ]
        default: return [
            "CLOSE THIS. open your digital marketing study guide.",
            "no one earns a Google Analytics certification by browsing.",
            "CLOSE THIS. get back to your digital marketing assignment.",
        ]
        }
    }

    private func projectmanagementCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "your PMP exam questions aren't going to answer themselves.",
            "get back to your project management assignment.",
            "close this and open your PMBOK study guide.",
            "your project management coursework won't finish itself.",
        ]
        case 2: return [
            "project managers don't earn their PMP by scrolling.",
            "your sprint plan isn't going to write itself.",
            "stop avoiding your project management coursework.",
        ]
        default: return [
            "CLOSE THIS. open your PMP study guide.",
            "no one earns agile certification by browsing.",
            "CLOSE THIS. get back to your project management assignment.",
        ]
        }
    }

    private func riskmanagementCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "your risk assessment isn't going to write itself.",
            "get back to your risk management assignment.",
            "close this and open your ERM coursework.",
            "your risk management exam prep won't do itself.",
        ]
        case 2: return [
            "risk managers don't earn their RIMS certification by scrolling.",
            "your risk framework isn't going to build itself.",
            "stop avoiding your risk management coursework.",
        ]
        default: return [
            "CLOSE THIS. open your risk management study guide.",
            "no one masters enterprise risk by browsing.",
            "CLOSE THIS. get back to your risk management assignment.",
        ]
        }
    }

    private func speechcommunicationCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "your speech isn't going to write itself.",
            "get back to your public speaking assignment.",
            "close this and prepare your speech.",
            "your debate prep won't do itself.",
        ]
        case 2: return [
            "great speakers practice — they don't scroll.",
            "your speech outline isn't going to write itself.",
            "stop avoiding your public speaking assignment.",
        ]
        default: return [
            "CLOSE THIS. open your speech notes.",
            "no one wins a debate by scrolling.",
            "CLOSE THIS. get back to your speech preparation.",
        ]
        }
    }

    private func audiologyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "your audiology notes aren't going to study themselves.",
            "get back to your audiology assignment.",
            "close this and open your audiometry materials.",
            "your audiology coursework won't finish itself.",
        ]
        case 2: return [
            "audiologists don't earn their AuD by scrolling.",
            "your hearing science notes aren't going to review themselves.",
            "stop avoiding your audiology coursework.",
        ]
        default: return [
            "CLOSE THIS. open your audiology notes.",
            "no one passes the PRAXIS audiology exam by scrolling.",
            "CLOSE THIS. get back to your audiology assignment.",
        ]
        }
    }

    private func behavioranalysisCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those behavior protocols aren't going to write themselves.",
            "get back to your ABA assignment.",
            "close this and open your behavior analysis notes.",
            "your BCBA exam prep won't do itself.",
        ]
        case 2: return [
            "no one earns their BCBA by scrolling.",
            "your behavior intervention plan isn't going to write itself.",
            "stop avoiding your ABA coursework.",
        ]
        default: return [
            "CLOSE THIS. open your ABA notes.",
            "no one masters applied behavior analysis by browsing.",
            "CLOSE THIS. get back to your behavior analysis assignment.",
        ]
        }
    }

    private func radiationtherapyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those treatment plans aren't going to write themselves.",
            "get back to your radiation therapy assignment.",
            "close this and open your dosimetry notes.",
            "your radiation therapy coursework won't finish itself.",
        ]
        case 2: return [
            "no one passes the ARRT by scrolling.",
            "your treatment planning notes aren't going to review themselves.",
            "stop avoiding your radiation therapy coursework.",
        ]
        default: return [
            "CLOSE THIS. open your radiation therapy notes.",
            "no one masters dosimetry by browsing.",
            "CLOSE THIS. get back to your radiation therapy assignment.",
        ]
        }
    }

    private func orthoticsCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those orthotic designs aren't going to draw themselves.",
            "get back to your O&P assignment.",
            "close this and open your orthotics and prosthetics notes.",
            "your CPO exam prep won't do itself.",
        ]
        case 2: return [
            "no one earns their CPO by scrolling.",
            "your prosthetic design notes aren't going to review themselves.",
            "stop avoiding your O&P coursework.",
        ]
        default: return [
            "CLOSE THIS. open your O&P notes.",
            "no one masters orthotics and prosthetics by browsing.",
            "CLOSE THIS. get back to your O&P assignment.",
        ]
        }
    }

    private func healthphysicsCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those shielding calculations aren't going to solve themselves.",
            "get back to your health physics assignment.",
            "close this and open your radiation protection notes.",
            "your CHP exam prep won't do itself.",
        ]
        case 2: return [
            "no one earns their CHP by scrolling.",
            "your radiation safety notes aren't going to review themselves.",
            "stop avoiding your health physics coursework.",
        ]
        default: return [
            "CLOSE THIS. open your health physics notes.",
            "no one masters medical physics by browsing.",
            "CLOSE THIS. get back to your health physics assignment.",
        ]
        }
    }

    private func informationsystemsCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that system design isn't going to document itself.",
            "get back to your MIS assignment.",
            "close this and open your systems analysis notes.",
            "your IS exam prep won't do itself.",
        ]
        case 2: return [
            "no one earns their MIS degree by scrolling.",
            "your ERD isn't going to draw itself — close this.",
            "stop avoiding your information systems coursework.",
        ]
        default: return [
            "CLOSE THIS. open your systems analysis notes.",
            "no one masters enterprise systems by browsing.",
            "CLOSE THIS. get back to your MIS assignment.",
        ]
        }
    }

    private func businessintelligenceCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that Power BI dashboard isn't going to build itself.",
            "get back to your BI assignment.",
            "close this and open your Tableau project.",
            "your BI certification prep won't do itself.",
        ]
        case 2: return [
            "no one earns their BI certification by scrolling.",
            "your dashboard isn't going to design itself — close this.",
            "stop avoiding your business intelligence coursework.",
        ]
        default: return [
            "CLOSE THIS. open your BI tools.",
            "no one masters Tableau or Power BI by browsing.",
            "CLOSE THIS. get back to your BI project.",
        ]
        }
    }

    private func internationalrelationsCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that foreign policy analysis isn't going to write itself.",
            "get back to your IR assignment.",
            "close this and open your international relations notes.",
            "your IR exam prep won't do itself.",
        ]
        case 2: return [
            "no one passes IR theory by scrolling.",
            "your foreign policy paper isn't going to write itself — close this.",
            "stop avoiding your international relations coursework.",
        ]
        default: return [
            "CLOSE THIS. open your IR notes.",
            "no one masters global governance by browsing.",
            "CLOSE THIS. get back to your international relations assignment.",
        ]
        }
    }

    private func publicadministrationCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that policy memo isn't going to write itself.",
            "get back to your MPA assignment.",
            "close this and open your public administration notes.",
            "your civil service exam prep won't do itself.",
        ]
        case 2: return [
            "no one earns their MPA by scrolling.",
            "your policy analysis isn't going to write itself — close this.",
            "stop avoiding your public administration coursework.",
        ]
        default: return [
            "CLOSE THIS. open your MPA notes.",
            "no one masters public sector management by browsing.",
            "CLOSE THIS. get back to your public administration assignment.",
        ]
        }
    }

    private func laborlawCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that employment law brief isn't going to write itself.",
            "get back to your labor law assignment.",
            "close this and open your employment law notes.",
            "your HR law exam prep won't do itself.",
        ]
        case 2: return [
            "no one passes the employment law bar by scrolling.",
            "your collective bargaining analysis isn't going to write itself — close this.",
            "stop avoiding your labor law coursework.",
        ]
        default: return [
            "CLOSE THIS. open your labor law notes.",
            "no one masters employment law by browsing.",
            "CLOSE THIS. get back to your labor law assignment.",
        ]
        }
    }

    private func veterinarytechnologyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those VTNE questions aren't going to answer themselves.",
            "get back to your vet tech notes.",
            "close this and open your veterinary technology study guide.",
            "your vet tech exam prep won't do itself.",
        ]
        case 2: return [
            "no one passes the VTNE by scrolling.",
            "your vet tech certification isn't going to earn itself — close this.",
            "stop avoiding your veterinary technology coursework.",
        ]
        default: return [
            "CLOSE THIS. open your VTNE prep.",
            "no one earns their CVT by browsing.",
            "CLOSE THIS. get back to your vet tech notes.",
        ]
        }
    }

    private func dentalradiologyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those radiograph techniques aren't going to master themselves.",
            "get back to your dental radiography notes.",
            "close this and open your dental radiology study guide.",
            "your DANB RHS prep won't do itself.",
        ]
        case 2: return [
            "no one passes the DANB RHS by scrolling.",
            "your bitewing technique isn't going to perfect itself — close this.",
            "stop avoiding your dental radiography coursework.",
        ]
        default: return [
            "CLOSE THIS. open your dental radiology notes.",
            "no one masters intraoral radiography by browsing.",
            "CLOSE THIS. get back to your dental radiography exam prep.",
        ]
        }
    }

    private func medicalscribingCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those patient encounter notes aren't going to write themselves.",
            "get back to your medical scribing practice.",
            "close this and open your scribe training materials.",
            "your scribe certification prep won't do itself.",
        ]
        case 2: return [
            "no one earns their scribe certification by scrolling.",
            "your clinical documentation skills won't improve themselves — close this.",
            "stop avoiding your medical scribing coursework.",
        ]
        default: return [
            "CLOSE THIS. open your scribe training materials.",
            "no one becomes a great medical scribe by browsing.",
            "CLOSE THIS. get back to your patient documentation practice.",
        ]
        }
    }

    private func communityhealthCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those CHES questions aren't going to answer themselves.",
            "get back to your community health notes.",
            "close this and open your CHW training materials.",
            "your community health educator exam prep won't do itself.",
        ]
        case 2: return [
            "no one earns their CHES certification by scrolling.",
            "your community health outreach plans won't write themselves — close this.",
            "stop avoiding your community health coursework.",
        ]
        default: return [
            "CLOSE THIS. open your community health notes.",
            "no one becomes a certified health educator by browsing.",
            "CLOSE THIS. get back to your CHES exam prep.",
        ]
        }
    }

    private func toxicologyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those dose-response curves aren't going to memorize themselves.",
            "get back to your toxicology notes.",
            "close this and open your toxicology study guide.",
            "your toxicology exam prep won't do itself.",
        ]
        case 2: return [
            "no one passes toxicology by scrolling.",
            "your forensic toxicology report isn't going to write itself — close this.",
            "stop avoiding your toxicology coursework.",
        ]
        default: return [
            "CLOSE THIS. open your toxicology notes.",
            "no one masters toxicokinetics by browsing.",
            "CLOSE THIS. get back to your toxicology exam prep.",
        ]
        }
    }

    private func performanceanalysisCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that game film isn't going to analyze itself.",
            "get back to your performance analysis notes.",
            "close this and open your Dartfish or Hudl session.",
            "your match analysis report won't write itself.",
        ]
        case 2: return [
            "no one becomes a performance analyst by scrolling.",
            "your video analysis isn't going to finish itself — close this.",
            "stop avoiding your coaching analytics work.",
        ]
        default: return [
            "CLOSE THIS. open your performance analysis software.",
            "no one passes performance analysis by watching other tabs.",
            "CLOSE THIS. get back to your match analysis.",
        ]
        }
    }

    private func musicbusinessCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "the music industry isn't going to wait for you.",
            "get back to your music business notes.",
            "close this and open your music business coursework.",
            "your music publishing assignment won't do itself.",
        ]
        case 2: return [
            "no one builds a music career by scrolling.",
            "your music business paper isn't going to write itself — close this.",
            "stop avoiding your music industry coursework.",
        ]
        default: return [
            "CLOSE THIS. open your music business notes.",
            "no one learns the music industry by browsing.",
            "CLOSE THIS. get back to your music publishing work.",
        ]
        }
    }

    private func dentalanesthesiaCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those anesthesia protocols aren't going to memorize themselves.",
            "get back to your dental anesthesia notes.",
            "close this and open your COMS/DOCS exam prep.",
            "your sedation dentistry coursework won't do itself.",
        ]
        case 2: return [
            "no one passes the COMS board by scrolling.",
            "your dental anesthesia notes aren't going to write themselves — close this.",
            "stop avoiding your sedation dentistry study materials.",
        ]
        default: return [
            "CLOSE THIS. open your dental anesthesia notes.",
            "no one earns their dental anesthesiology credential by browsing.",
            "CLOSE THIS. get back to your COMS exam prep.",
        ]
        }
    }

    private func palliativecareCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "your patients deserve your full attention — get back to your palliative care notes.",
            "close this and open your CHPN exam prep.",
            "that end-of-life care plan isn't going to write itself.",
            "get back to your hospice nursing coursework.",
        ]
        case 2: return [
            "no one passes the CHPN by scrolling.",
            "your palliative care assignment isn't going to finish itself — close this.",
            "stop avoiding your hospice care study materials.",
        ]
        default: return [
            "CLOSE THIS. open your palliative care notes.",
            "no one earns their CHPN by browsing.",
            "CLOSE THIS. get back to your end-of-life care coursework.",
        ]
        }
    }

    private func cognitivescienceCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that cognitive model isn't going to build itself.",
            "get back to your cognitive science notes.",
            "close this and open your cogsci coursework.",
            "your mind and brain assignment won't do itself.",
        ]
        case 2: return [
            "no one masters cognitive science by scrolling.",
            "your cogsci paper isn't going to write itself — close this.",
            "stop avoiding your cognitive systems coursework.",
        ]
        default: return [
            "CLOSE THIS. open your cognitive science notes.",
            "no one understands cognition by browsing — close this.",
            "CLOSE THIS. get back to your cogsci exam prep.",
        ]
        }
    }

    private func informationassuranceCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those IA concepts aren't going to master themselves.",
            "get back to your information assurance coursework.",
            "close this and open your CISM or RMF study guide.",
            "your cybersecurity governance assignment won't do itself.",
        ]
        case 2: return [
            "no one earns their CISM by scrolling.",
            "your IA exam prep isn't going to finish itself — close this.",
            "stop avoiding your information assurance notes.",
        ]
        default: return [
            "CLOSE THIS. open your information assurance notes.",
            "no one passes the CISM or CRISC by browsing.",
            "CLOSE THIS. get back to your IA certification prep.",
        ]
        }
    }

    private func hrmanagementCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that SHRM exam isn't going to study itself.",
            "get back to your HR management coursework.",
            "close this and open your PHR or SHRM-CP study guide.",
            "your talent management assignment won't do itself.",
        ]
        case 2: return [
            "no one earns their SHRM-CP by scrolling.",
            "your HR management exam prep isn't going to finish itself — close this.",
            "stop avoiding your human resource management notes.",
        ]
        default: return [
            "CLOSE THIS. open your HR management notes.",
            "no one passes the PHR or SPHR by browsing.",
            "CLOSE THIS. get back to your SHRM certification prep.",
        ]
        }
    }

    private func changemanagementCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that change initiative isn't going to manage itself.",
            "get back to your change management coursework.",
            "close this and open your Prosci or ADKAR study guide.",
            "your organizational change assignment won't do itself.",
        ]
        case 2: return [
            "no one earns their CCMP by scrolling.",
            "your change management exam prep isn't going to finish itself — close this.",
            "stop avoiding your organizational development notes.",
        ]
        default: return [
            "CLOSE THIS. open your change management notes.",
            "no one passes the Prosci certification by browsing.",
            "CLOSE THIS. get back to your ADKAR and Kotter coursework.",
        ]
        }
    }

    private func economicsCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those supply and demand curves aren't going to memorize themselves.",
            "get back to your economics notes.",
            "close this and open your econ textbook.",
            "your econometrics problem set won't do itself.",
        ]
        case 2: return [
            "no one masters micro or macro by scrolling.",
            "your economics paper isn't going to write itself — close this.",
            "stop avoiding your econ coursework.",
        ]
        default: return [
            "CLOSE THIS. open your economics notes.",
            "no one aces the econ exam by browsing.",
            "CLOSE THIS. get back to your econ problem set.",
        ]
        }
    }

    private func iopsychologyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those I/O concepts aren't going to apply themselves.",
            "get back to your organizational psychology notes.",
            "close this and open your I/O psych coursework.",
            "your personnel selection assignment won't do itself.",
        ]
        case 2: return [
            "no one masters I/O psychology by scrolling.",
            "your organizational psychology paper isn't going to write itself — close this.",
            "stop avoiding your industrial-organizational coursework.",
        ]
        default: return [
            "CLOSE THIS. open your I/O psychology notes.",
            "no one passes the I/O exam by browsing.",
            "CLOSE THIS. get back to your organizational psychology work.",
        ]
        }
    }
}
