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
        case "criminallaw":           return criminallawCallouts(tier: tier)
        case "civilprocedure":        return civilprocedureCallouts(tier: tier)
        case "constitutionallaw":     return constitutionallawCallouts(tier: tier)
        case "evidencelaw":           return evidencelawCallouts(tier: tier)
        case "tortlaw":               return tortlawCallouts(tier: tier)
        case "architecturaldesign":   return architecturaldesignCallouts(tier: tier)
        case "historicpreservation":  return historicpreservationCallouts(tier: tier)
        case "sustainabledesign":      return sustainabledesignCallouts(tier: tier)
        case "exhibitdesign":          return exhibitdesignCallouts(tier: tier)
        case "lightingdesign":         return lightingdesignCallouts(tier: tier)
        case "socialentrepreneurship": return socialentrepreneurshipCallouts(tier: tier)
        case "yogapilates":            return yogapilatesCallouts(tier: tier)
        case "ayurvedic":              return ayurvedicCallouts(tier: tier)
        case "positivepsychology":     return positivepsychologyCallouts(tier: tier)
        case "policeacademy":          return policeacademyCallouts(tier: tier)
        case "nursepractitioner":      return nursepractitionerCallouts(tier: tier)
        case "mortuaryscience":        return mortuaryscienceCallouts(tier: tier)
        case "polyvagaltheory":        return polyvagaltheoryCallouts(tier: tier)
        case "virtualreality":         return virtualrealityCallouts(tier: tier)
        case "clinicalresearch":       return clinicalresearchCallouts(tier: tier)
        case "homeopathy":             return homeopathyCallouts(tier: tier)
        case "recreationaltherapy":    return recreationaltherapyCallouts(tier: tier)
        case "tibetanmedicine":        return tibetanmedicineCallouts(tier: tier)
        case "waterresources":         return waterresourcesCallouts(tier: tier)
        case "biophysics":             return biophysicsCallouts(tier: tier)
        case "psychopharmacology":     return psychopharmacologyCallouts(tier: tier)
        case "mediationarbitration":   return mediationarbitrationCallouts(tier: tier)
        case "sportslaw":              return sportslawCallouts(tier: tier)
        case "animalassistedtherapy":  return animalassistedtherapyCallouts(tier: tier)
        case "constructionlaw":        return constructionlawCallouts(tier: tier)
        case "healtheconomics":        return healtheconomicsCallouts(tier: tier)
        case "insurancefinance":       return insurancefinanceCallouts(tier: tier)
        case "environmentalplanning":       return environmentalplanningCallouts(tier: tier)
        case "tesol":                       return tesolCallouts(tier: tier)
        case "specialeducation":            return specialeducationCallouts(tier: tier)
        case "foodscience":                 return foodscienceCallouts(tier: tier)
        case "animalwelfare":               return animalwelfareCallouts(tier: tier)
        case "epidemiologicalmodeling":     return epidemiologicalmodelingCallouts(tier: tier)
        case "educationalleadership":       return educationalleadershipCallouts(tier: tier)
        case "medicalhumanities":           return medicalhumanitiesCallouts(tier: tier)
        case "healthequity":                return healthequityCallouts(tier: tier)
        case "neurolaw":                    return neurolawCallouts(tier: tier)
        case "climatelaw":                  return climatelawCallouts(tier: tier)
        case "athletictraining":            return athletictrainingCallouts(tier: tier)
        case "biomechanics":               return biomechanicsCallouts(tier: tier)
        case "zoology":                    return zoologyCallouts(tier: tier)
        case "militaryscience":            return militaryscienceCallouts(tier: tier)
        case "healthinformatics":          return healthinformaticsCallouts(tier: tier)
        case "cryptography":               return cryptographyCallouts(tier: tier)
        case "appliedmathematics":         return appliedmathematicsCallouts(tier: tier)
        case "historicallinguistics":      return historicallinguisticsCallouts(tier: tier)
        case "computationalfinance":       return computationalfinanceCallouts(tier: tier)
        case "globalpoliticaleconomy":     return globalpoliticaleconomyCallouts(tier: tier)
        case "geopolitics":                return geopoliticsCallouts(tier: tier)
        case "computationalbiology":       return computationalbiologyCallouts(tier: tier)
        case "philosophyofmind":           return philosophyofmindCallouts(tier: tier)
        case "digitalhumanities":          return digitalhumanitiesCallouts(tier: tier)
        case "environmentalpolicy":        return environmentalpolicyCallouts(tier: tier)
        case "cognitivelinguistics":       return cognitivelinguisticsCallouts(tier: tier)
        case "environmentaljustice":       return environmentaljusticeCallouts(tier: tier)
        case "schoolcounseling":           return schoolcounselingCallouts(tier: tier)
        case "cognitivepsychology":        return cognitivepsychologyCallouts(tier: tier)
        case "developmentalpsychology":    return developmentalpsychologyCallouts(tier: tier)
        case "paleontology":               return paleontologyCallouts(tier: tier)
        case "experimentalphysics":        return experimentalphysicsCallouts(tier: tier)
        case "informationscience":         return informationscienceCallouts(tier: tier)
        case "socialepidemiology":         return socialepidemiologyCallouts(tier: tier)
        case "cognitiveneuroscience":      return cognitiveneuroscienceCallouts(tier: tier)
        case "nanotechnology":             return nanotechnologyCallouts(tier: tier)
        case "appliedlinguistics":         return appliedlinguisticsCallouts(tier: tier)
        case "radiobiology":               return radiobiologyCallouts(tier: tier)
        case "translationstudies":         return translationstudiesCallouts(tier: tier)
        case "ecologyconservation":        return ecologyconservationCallouts(tier: tier)
        case "astrobiology":               return astrobiologyCallouts(tier: tier)
        case "materialscharacterization":  return materialscharacterizationCallouts(tier: tier)
        case "toxicogenomics":             return toxicogenomicsCallouts(tier: tier)
        case "developmentalbiology":       return developmentalbiology_Callouts(tier: tier)
        case "drugdiscovery":              return drugdiscoveryCallouts(tier: tier)
        case "organicchemistry":           return organicchemistryCallouts(tier: tier)
        case "botany":                     return botanyCallouts(tier: tier)
        case "operationsresearch":         return operationsresearchCallouts(tier: tier)
        case "internalaudit":              return internalauditCallouts(tier: tier)
        case "healthcarequality":          return healthcarequalityCallouts(tier: tier)
        case "nursinganesthesia":          return nursinganesthesiaCallouts(tier: tier)
        case "physicalchemistry":          return physicalchemistryCallouts(tier: tier)
        case "inorganicchemistry":         return inorganicchemistryCallouts(tier: tier)
        case "analyticalchemistry":        return analyticalchemistryCallouts(tier: tier)
        case "nuclearchemistry":           return nuclearchemistryCallouts(tier: tier)
        case "electrochemistry":           return electrochemistryCallouts(tier: tier)
        case "polymerchemistry":           return polymerchemistryCallouts(tier: tier)
        case "maternalhealth":             return maternalhealthCallouts(tier: tier)
        case "globalhealthpolicy":         return globalhealthpolicyCallouts(tier: tier)
        case "processengineering":         return processengineeringCallouts(tier: tier)
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

    private func criminallawCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that criminal law hypo isn't going to analyze itself.",
            "your mens rea analysis isn't going to write itself.",
            "crim law doesn't master itself — close this.",
            "those Model Penal Code sections aren't going to memorize themselves."
        ]
        case 2: return [
            "no one passes the bar on criminal law by scrolling.",
            "your professor isn't going to brief that case for you.",
            "close this and get back to your crim law outline."
        ]
        default: return [
            "CLOSE THIS. open your criminal law notes.",
            "CLOSE THIS. your crim law hypo needs you.",
            "CLOSE THIS. you have law school to worry about."
        ]
        }
    }

    private func civilprocedureCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that civ pro hypo isn't going to analyze itself.",
            "the Erie doctrine won't memorize itself — close this.",
            "your civil procedure outline isn't going to write itself.",
            "personal jurisdiction isn't going to click without you closing this and studying."
        ]
        case 2: return [
            "no one masters civ pro by scrolling.",
            "your 12(b)(6) argument isn't going to draft itself.",
            "close this and get back to your civ pro notes."
        ]
        default: return [
            "CLOSE THIS. open your civil procedure notes.",
            "CLOSE THIS. your civ pro exam is coming.",
            "CLOSE THIS. you have law school to focus on."
        ]
        }
    }

    private func constitutionallawCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that con law analysis isn't going to write itself.",
            "the Constitution doesn't interpret itself — close this and get back to work.",
            "judicial review won't click without you actually studying it.",
            "your con law outline isn't going to fill itself."
        ]
        case 2: return [
            "no one passes con law by scrolling.",
            "close this and get back to your constitutional law notes.",
            "your professor isn't going to analyze that case for you."
        ]
        default: return [
            "CLOSE THIS. open your con law notes.",
            "CLOSE THIS. your constitutional law exam is real.",
            "CLOSE THIS. the Supreme Court expects you to know this."
        ]
        }
    }

    private func evidencelawCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those hearsay exceptions aren't going to memorize themselves.",
            "your evidence law outline isn't going to write itself.",
            "the Federal Rules of Evidence won't learn themselves — close this.",
            "that evidence hypo isn't going to analyze itself."
        ]
        case 2: return [
            "no one masters the FRE by scrolling.",
            "close this and get back to your evidence notes.",
            "your professor isn't going to spot that hearsay exception for you."
        ]
        default: return [
            "CLOSE THIS. open your evidence law notes.",
            "CLOSE THIS. your evidence exam is real.",
            "CLOSE THIS. you have evidentiary rules to master."
        ]
        }
    }

    private func tortlawCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that torts hypo isn't going to analyze itself.",
            "negligence doesn't master itself — close this and study.",
            "your torts outline isn't going to write itself.",
            "Palsgraf won't make sense until you actually study it."
        ]
        case 2: return [
            "no one passes torts by scrolling.",
            "close this and get back to your torts notes.",
            "your professor isn't going to work through that negligence analysis for you."
        ]
        default: return [
            "CLOSE THIS. open your torts notes.",
            "CLOSE THIS. your torts exam is real.",
            "CLOSE THIS. you have negligence elements to master."
        ]
        }
    }

    private func architecturaldesignCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that design concept isn't going to develop itself.",
            "your architecture portfolio isn't going to build itself.",
            "the charrette doesn't wait — close this and design.",
            "your studio critic won't be impressed if you haven't drawn anything."
        ]
        case 2: return [
            "no one wins a design competition by scrolling.",
            "close this and get back to your design drawings.",
            "your schematic isn't going to sketch itself."
        ]
        default: return [
            "CLOSE THIS. open your design files.",
            "CLOSE THIS. your architecture portfolio needs you.",
            "CLOSE THIS. the design deadline is real."
        ]
        }
    }

    private func historicpreservationCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those historic structures aren't going to document themselves.",
            "your preservation report isn't going to write itself.",
            "history is patient — your deadline isn't. close this.",
            "the Secretary of Interior Standards won't memorize themselves."
        ]
        case 2: return [
            "no one earns their preservation credential by scrolling.",
            "close this and get back to your preservation work.",
            "your HABS documentation isn't going to finish itself."
        ]
        default: return [
            "CLOSE THIS. open your preservation project.",
            "CLOSE THIS. your historic survey is waiting.",
            "CLOSE THIS. those buildings deserve your attention."
        ]
        }
    }

    private func sustainabledesignCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that LEED scorecard isn't going to fill itself.",
            "passive design requires active effort — close this and work.",
            "net-zero doesn't happen by scrolling.",
            "your energy model isn't going to run itself."
        ]
        case 2: return [
            "no one passes the LEED exam by scrolling.",
            "close this and get back to your sustainable design project.",
            "the planet needs you focused — close this."
        ]
        default: return [
            "CLOSE THIS. open your LEED project.",
            "CLOSE THIS. your sustainable design work is waiting.",
            "CLOSE THIS. net-zero takes real work."
        ]
        }
    }

    private func exhibitdesignCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that exhibit isn't going to design itself.",
            "your museum installation isn't going to plan itself.",
            "visitors deserve a great experience — close this and design it.",
            "that trade show booth won't design itself."
        ]
        case 2: return [
            "no one designs a great exhibit by scrolling.",
            "close this and get back to your exhibit project.",
            "your gallery installation won't come together on its own."
        ]
        default: return [
            "CLOSE THIS. open your exhibit design files.",
            "CLOSE THIS. your installation deadline is real.",
            "CLOSE THIS. that museum exhibit needs you."
        ]
        }
    }

    private func lightingdesignCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those luminaires aren't going to specify themselves.",
            "your lighting plan isn't going to draw itself.",
            "NCQLP prep doesn't happen by scrolling.",
            "that photometric analysis isn't going to run itself."
        ]
        case 2: return [
            "no one earns their lighting credential by scrolling.",
            "close this and get back to your lighting design.",
            "your light fixture schedule won't write itself."
        ]
        default: return [
            "CLOSE THIS. open your lighting design files.",
            "CLOSE THIS. your photometric plan is waiting.",
            "CLOSE THIS. that lighting spec needs you."
        ]
        }
    }

    private func socialentrepreneurshipCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that social enterprise isn't going to build itself.",
            "impact investors don't wait — close this and get to work.",
            "your business model for good won't write itself.",
            "you can't change the world by scrolling."
        ]
        case 2: return [
            "no one builds a social enterprise by scrolling.",
            "close this and get back to your impact work.",
            "your social venture notes aren't going to write themselves."
        ]
        default: return [
            "CLOSE THIS. open your social enterprise work.",
            "CLOSE THIS. your mission-driven work is waiting.",
            "CLOSE THIS. impact takes focus — give it yours."
        ]
        }
    }

    private func yogapilatesCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "your yoga teaching notes aren't going to study themselves.",
            "you can't earn your RYT by scrolling.",
            "your pilates certification won't come from this screen.",
            "close this and get back to your teacher training work."
        ]
        case 2: return [
            "no one earns their yoga teaching certification by scrolling.",
            "close this and get back to your training materials.",
            "your anatomy sequencing notes won't write themselves."
        ]
        default: return [
            "CLOSE THIS. open your teacher training notes.",
            "CLOSE THIS. your certification exam is real.",
            "CLOSE THIS. your students deserve a prepared teacher."
        ]
        }
    }

    private func ayurvedicCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those doshas aren't going to study themselves.",
            "your Ayurvedic notes won't write themselves — close this.",
            "NAMA certification doesn't come from scrolling.",
            "Ayurveda took thousands of years to develop — spend your hour on it."
        ]
        case 2: return [
            "no one earns their Ayurvedic practitioner certificate by scrolling.",
            "close this and get back to your Ayurveda notes.",
            "your panchakarma protocols won't memorize themselves."
        ]
        default: return [
            "CLOSE THIS. open your Ayurveda notes.",
            "CLOSE THIS. your Ayurvedic exam is real.",
            "CLOSE THIS. those herbal formulas need your attention."
        ]
        }
    }

    private func positivepsychologyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "you won't flourish by scrolling — Seligman literally wrote the book on this.",
            "your positive psychology notes aren't going to write themselves.",
            "character strengths don't develop from a screen break.",
            "the MAPP program is rigorous — close this and study."
        ]
        case 2: return [
            "no one masters positive psychology by scrolling.",
            "close this and get back to your well-being research.",
            "your PERMA analysis won't write itself."
        ]
        default: return [
            "CLOSE THIS. open your positive psychology notes.",
            "CLOSE THIS. your well-being research is waiting.",
            "CLOSE THIS. flourishing requires real effort — give it yours."
        ]
        }
    }

    private func policeacademyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those POST requirements aren't going to study themselves.",
            "the police academy doesn't wait for scrollers.",
            "your law enforcement exam prep won't happen on its own.",
            "no one passes the peace officer exam by browsing."
        ]
        case 2: return [
            "no one passes the police entrance exam by scrolling.",
            "close this and get back to your academy prep.",
            "your written exam notes won't write themselves."
        ]
        default: return [
            "CLOSE THIS. open your law enforcement training materials.",
            "CLOSE THIS. your police exam prep is real.",
            "CLOSE THIS. the academy expects you prepared — start now."
        ]
        }
    }

    private func nursepractitionerCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those AANP prep questions aren't going to answer themselves.",
            "your NP clinical notes aren't going to write themselves.",
            "your patients need a prepared nurse practitioner — close this.",
            "FNP board prep doesn't happen by scrolling."
        ]
        case 2: return [
            "no one earns their FNP-BC by scrolling.",
            "close this and get back to your NP coursework.",
            "your NP certification won't come from this screen."
        ]
        default: return [
            "CLOSE THIS. open your NP study materials.",
            "CLOSE THIS. your AANP exam is real.",
            "CLOSE THIS. your patients deserve a prepared provider."
        ]
        }
    }

    private func mortuaryscienceCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that NBE exam prep isn't going to do itself.",
            "those embalming techniques aren't going to study themselves.",
            "families deserve a prepared funeral service professional — close this.",
            "mortuary science board prep doesn't happen by scrolling."
        ]
        case 2: return [
            "no one passes the NBE by scrolling.",
            "close this and get back to your mortuary science coursework.",
            "your funeral service license won't come from this screen."
        ]
        default: return [
            "CLOSE THIS. open your mortuary science notes.",
            "CLOSE THIS. your NBE exam is real.",
            "CLOSE THIS. those families deserve your focus."
        ]
        }
    }

    private func polyvagaltheoryCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "your polyvagal theory notes aren't going to write themselves.",
            "somatic experiencing training takes real focus — close this.",
            "your clients deserve a trained practitioner — close this.",
            "IFS certification prep doesn't happen by scrolling."
        ]
        case 2: return [
            "no one masters somatic therapy by scrolling.",
            "close this and get back to your somatic training notes.",
            "your polyvagal theory coursework won't complete itself."
        ]
        default: return [
            "CLOSE THIS. open your somatic therapy training notes.",
            "CLOSE THIS. your certification program requires your focus.",
            "CLOSE THIS. your clients deserve a regulated, trained practitioner."
        ]
        }
    }

    private func virtualrealityCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "your VR scene isn't going to build itself.",
            "close this and open your XR project.",
            "nobody ships an AR app by scrolling.",
            "that immersive experience won't develop itself."
        ]
        case 2: return [
            "no one ships a VR app by watching reels.",
            "close this and get back to your virtual reality project.",
            "your XR deadline is real — close this."
        ]
        default: return [
            "CLOSE THIS. open your VR project.",
            "CLOSE THIS. your AR build is waiting.",
            "CLOSE THIS. the metaverse isn't going to populate itself."
        ]
        }
    }

    private func clinicalresearchCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "your CRC certification prep isn't going to happen by scrolling.",
            "close this and get back to your clinical trial study materials.",
            "GCP doesn't memorize itself — close this.",
            "those clinical research protocols won't review themselves."
        ]
        case 2: return [
            "no one passes the ACRP exam by scrolling.",
            "close this and get back to your clinical research notes.",
            "your study protocol isn't going to write itself."
        ]
        default: return [
            "CLOSE THIS. open your clinical research materials.",
            "CLOSE THIS. GCP compliance doesn't happen by scrolling.",
            "CLOSE THIS. your clinical trial career starts with this prep."
        ]
        }
    }

    private func homeopathyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those homeopathic remedies aren't going to learn themselves.",
            "close this and get back to your materia medica.",
            "classical homeopathy takes real study — close this.",
            "your CCH exam prep isn't going to happen by scrolling."
        ]
        case 2: return [
            "no one earns their CCH by scrolling.",
            "close this and get back to your homeopathic case work.",
            "Hahnemann didn't write the Organon by browsing."
        ]
        default: return [
            "CLOSE THIS. open your homeopathic materia medica.",
            "CLOSE THIS. your remedy selection work is waiting.",
            "CLOSE THIS. classical homeopathy demands your full attention."
        ]
        }
    }

    private func recreationaltherapyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "your CTRS exam prep isn't going to happen by scrolling.",
            "those TR session notes won't write themselves.",
            "close this and get back to your therapeutic recreation materials.",
            "your clients deserve a focused recreational therapist — close this."
        ]
        case 2: return [
            "no one passes the NCTRC exam by scrolling.",
            "close this and get back to your TR program work.",
            "your adaptive recreation plans won't write themselves."
        ]
        default: return [
            "CLOSE THIS. open your recreational therapy study materials.",
            "CLOSE THIS. your CTRS prep is waiting.",
            "CLOSE THIS. your clients deserve your focused attention."
        ]
        }
    }

    private func tibetanmedicineCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those Tibetan medicine concepts aren't going to memorize themselves.",
            "close this and get back to your Sowa Rigpa studies.",
            "the Gyushi won't study itself — close this.",
            "your Tibetan medicine program demands your focus."
        ]
        case 2: return [
            "no one masters Tibetan medicine by scrolling.",
            "close this and get back to your TTM coursework.",
            "your Tibetan herbal medicine notes won't write themselves."
        ]
        default: return [
            "CLOSE THIS. open your Tibetan medicine study materials.",
            "CLOSE THIS. Sowa Rigpa demands your full attention.",
            "CLOSE THIS. your patients deserve a focused Tibetan medicine practitioner."
        ]
        }
    }

    private func waterresourcesCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those hydraulic calculations aren't going to solve themselves.",
            "close this and get back to your water resources work.",
            "stormwater doesn't design itself — close this.",
            "your water engineering assignment needs you focused."
        ]
        case 2: return [
            "no one passes water resources engineering by scrolling.",
            "close this and open your hydrology notes.",
            "those stormwater plans won't write themselves."
        ]
        default: return [
            "CLOSE THIS. open your water resources engineering work.",
            "CLOSE THIS. hydraulics demands your full attention.",
            "CLOSE THIS. the watershed won't model itself."
        ]
        }
    }

    private func biophysicsCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those biophysics problems aren't going to solve themselves.",
            "close this and get back to your biophysics lab.",
            "membrane potentials don't derive themselves — close this.",
            "your biophysics exam is not going to study for itself."
        ]
        case 2: return [
            "no one masters biophysics by scrolling.",
            "close this and open your biophysics notes.",
            "the physics of life won't reveal itself while you scroll."
        ]
        default: return [
            "CLOSE THIS. open your biophysics problem set.",
            "CLOSE THIS. biophysics demands your full attention.",
            "CLOSE THIS. protein folding waits for no one."
        ]
        }
    }

    private func psychopharmacologyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those drug mechanisms aren't going to memorize themselves.",
            "close this and get back to your psychopharmacology notes.",
            "neurotransmitters don't explain themselves — close this.",
            "your psychopharmacology exam needs your full attention."
        ]
        case 2: return [
            "no one masters psychopharmacology by scrolling.",
            "close this and open your pharmacology notes.",
            "those receptor mechanisms won't learn themselves."
        ]
        default: return [
            "CLOSE THIS. open your psychopharmacology textbook.",
            "CLOSE THIS. drug-brain interactions demand your full attention.",
            "CLOSE THIS. psychiatric pharmacology won't study itself."
        ]
        }
    }

    private func mediationarbitrationCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those mediation skills aren't going to develop themselves.",
            "close this and get back to your ADR coursework.",
            "disputes don't resolve themselves — neither will your assignment.",
            "your arbitration exam needs you focused."
        ]
        case 2: return [
            "no one becomes a skilled mediator by scrolling.",
            "close this and open your dispute resolution notes.",
            "that arbitration brief won't write itself."
        ]
        default: return [
            "CLOSE THIS. open your mediation and arbitration materials.",
            "CLOSE THIS. ADR demands your full attention.",
            "CLOSE THIS. conflict resolution starts with closing this."
        ]
        }
    }

    private func sportslawCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those sports contracts aren't going to analyze themselves.",
            "close this and get back to your sports law assignment.",
            "NCAA compliance doesn't study itself — close this.",
            "your sports law exam needs your full focus."
        ]
        case 2: return [
            "no one passes sports law by scrolling.",
            "close this and open your sports law notes.",
            "that athlete contract analysis won't write itself."
        ]
        default: return [
            "CLOSE THIS. open your sports law materials.",
            "CLOSE THIS. sports governance demands your full attention.",
            "CLOSE THIS. the locker room doesn't need you — your textbook does."
        ]
        }
    }

    private func animalassistedtherapyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those therapy animal handling skills aren't going to practice themselves.",
            "close this and get back to your animal-assisted therapy coursework.",
            "your AAT certification prep needs your full attention.",
            "therapy animals depend on handlers who actually study — close this."
        ]
        case 2: return [
            "no one earns their therapy dog certification by scrolling.",
            "close this and open your AAT study materials.",
            "your clients need a prepared handler — close this."
        ]
        default: return [
            "CLOSE THIS. open your animal-assisted therapy materials.",
            "CLOSE THIS. therapy animals deserve prepared handlers.",
            "CLOSE THIS. your AAT exam prep won't happen by scrolling."
        ]
        }
    }

    private func constructionlawCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those AIA contract clauses aren't going to memorize themselves.",
            "close this and get back to your construction law assignment.",
            "construction disputes don't resolve themselves — neither will your coursework.",
            "your construction law exam needs your full attention."
        ]
        case 2: return [
            "no one masters construction law by scrolling.",
            "close this and open your construction law notes.",
            "that lien claim analysis won't write itself."
        ]
        default: return [
            "CLOSE THIS. open your construction law materials.",
            "CLOSE THIS. construction contracts demand your full attention.",
            "CLOSE THIS. the job site can wait — your law exam can't."
        ]
        }
    }

    private func healtheconomicsCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those QALY calculations aren't going to run themselves.",
            "close this and get back to your health economics assignment.",
            "ICER ratios don't compute themselves — close this.",
            "your health economics exam needs your full attention."
        ]
        case 2: return [
            "no one masters health economics by scrolling.",
            "close this and open your health economics notes.",
            "that cost-effectiveness analysis won't write itself."
        ]
        default: return [
            "CLOSE THIS. open your health economics materials.",
            "CLOSE THIS. pharmacoeconomics demands your full attention.",
            "CLOSE THIS. healthcare resources are finite — so is your study time."
        ]
        }
    }

    private func insurancefinanceCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those underwriting concepts aren't going to learn themselves.",
            "close this and get back to your insurance coursework.",
            "your insurance licensing exam needs your full attention.",
            "CPCU candidates don't pass by scrolling — close this."
        ]
        case 2: return [
            "no one earns their insurance designation by scrolling.",
            "close this and open your insurance study materials.",
            "those policy provisions won't memorize themselves."
        ]
        default: return [
            "CLOSE THIS. open your insurance licensing materials.",
            "CLOSE THIS. underwriting demands your full attention.",
            "CLOSE THIS. your CPCU or LOMA exam won't pass itself."
        ]
        }
    }

    private func environmentalplanningCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that EIS isn't going to write itself.",
            "close this and get back to your environmental planning coursework.",
            "CEQA compliance doesn't study itself — close this.",
            "your environmental review assignment needs your full attention."
        ]
        case 2: return [
            "no one masters environmental planning by scrolling.",
            "close this and open your NEPA or CEQA study materials.",
            "that environmental impact assessment won't draft itself."
        ]
        default: return [
            "CLOSE THIS. open your environmental planning materials.",
            "CLOSE THIS. environmental review demands your full attention.",
            "CLOSE THIS. the environment can't wait — neither can your assignment."
        ]
        }
    }

    private func tesolCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those language learners need a prepared teacher — close this.",
            "your TESOL certification prep isn't going to happen by scrolling.",
            "close this and get back to your ESL lesson planning.",
            "second language acquisition doesn't study itself — close this.",
        ]
        case 2: return [
            "no one earns their TESOL certification by scrolling.",
            "close this and open your ESL teaching materials.",
            "your language learners deserve a teacher who actually studies."
        ]
        default: return [
            "CLOSE THIS. open your TESOL or TEFL study materials.",
            "CLOSE THIS. your ESL students need a prepared teacher.",
            "CLOSE THIS. second language acquisition demands your full attention."
        ]
        }
    }

    private func specialeducationCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those IEPs aren't going to write themselves.",
            "your students with disabilities deserve a prepared teacher — close this.",
            "close this and get back to your special education coursework.",
            "IDEA compliance doesn't study itself — close this.",
        ]
        case 2: return [
            "no one earns their SPED credential by scrolling.",
            "close this and open your special education materials.",
            "your exceptional learners need you focused — close this."
        ]
        default: return [
            "CLOSE THIS. open your special education notes.",
            "CLOSE THIS. your IEP goals won't write themselves.",
            "CLOSE THIS. exceptional learners deserve your full attention."
        ]
        }
    }

    private func foodscienceCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that food product isn't going to develop itself.",
            "close this and get back to your food science coursework.",
            "food chemistry doesn't analyze itself — close this.",
            "your food science lab report needs your full attention.",
        ]
        case 2: return [
            "no one masters food science by scrolling.",
            "close this and open your food science notes.",
            "that sensory evaluation report won't write itself."
        ]
        default: return [
            "CLOSE THIS. open your food science study materials.",
            "CLOSE THIS. food microbiology demands your full attention.",
            "CLOSE THIS. your food science exam won't pass itself."
        ]
        }
    }

    private func animalwelfareCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those animals depend on handlers who actually study — close this.",
            "your zoo management coursework isn't going to complete itself.",
            "close this and get back to your animal welfare studies.",
            "IACUC protocols don't memorize themselves — close this.",
        ]
        case 2: return [
            "no one earns a zoo science credential by scrolling.",
            "close this and open your animal welfare study materials.",
            "wildlife rehab patients need prepared rehabilitators — close this."
        ]
        default: return [
            "CLOSE THIS. open your animal welfare materials.",
            "CLOSE THIS. animal care demands your full attention.",
            "CLOSE THIS. IACUC compliance won't study itself."
        ]
        }
    }

    private func epidemiologicalmodelingCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that SIR model isn't going to code itself.",
            "close this and get back to your epidemic modeling coursework.",
            "disease dynamics don't analyze themselves — close this.",
            "your epidemiological model won't build itself.",
        ]
        case 2: return [
            "no one masters disease modeling by scrolling.",
            "close this and open your epidemic modeling notes.",
            "that transmission rate won't estimate itself."
        ]
        default: return [
            "CLOSE THIS. open your disease modeling materials.",
            "CLOSE THIS. mathematical epidemiology demands your full attention.",
            "CLOSE THIS. your R\u{2080} won't calculate itself."
        ]
        }
    }

    private func educationalleadershipCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those principals don't lead themselves — close this.",
            "your EdD dissertation isn't going to write itself.",
            "close this and get back to your school leadership coursework.",
            "ISLLC standards won't memorize themselves — close this.",
        ]
        case 2: return [
            "no one earns their principal certification by scrolling.",
            "close this and open your educational leadership materials.",
            "your school won't lead itself — focus."
        ]
        default: return [
            "CLOSE THIS. open your educational leadership notes.",
            "CLOSE THIS. your principal exam won't pass itself.",
            "CLOSE THIS. educational leaders lead. close this and be one."
        ]
        }
    }

    private func medicalhumanitiesCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those illness narratives aren't going to read themselves.",
            "close this and get back to your medical humanities coursework.",
            "the history of medicine won't study itself — close this.",
            "narrative medicine demands presence — close this.",
        ]
        case 2: return [
            "no one masters medical humanities by scrolling.",
            "close this and open your narrative medicine materials.",
            "medicine and literature won't analyze themselves — focus."
        ]
        default: return [
            "CLOSE THIS. open your medical humanities notes.",
            "CLOSE THIS. illness narratives deserve your full attention.",
            "CLOSE THIS. the history of medicine won't write itself."
        ]
        }
    }

    private func healthequityCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "health disparities won't analyze themselves — close this.",
            "close this and get back to your health equity coursework.",
            "your community deserves an advocate who actually studies.",
            "those SDOH frameworks aren't going to read themselves.",
        ]
        case 2: return [
            "no one achieves health equity by scrolling.",
            "close this and open your health equity study materials.",
            "health justice demands your full attention — close this."
        ]
        default: return [
            "CLOSE THIS. open your health equity materials.",
            "CLOSE THIS. structural disparities won't close themselves.",
            "CLOSE THIS. your health equity research deserves your full attention."
        ]
        }
    }

    private func neurolawCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that brain-imaging evidence isn't going to analyze itself.",
            "close this and get back to your neurolaw coursework.",
            "criminal culpability and neuroscience won't study themselves.",
            "those fMRI court cases don't read themselves — close this.",
        ]
        case 2: return [
            "no one masters neurolaw by scrolling.",
            "close this and open your law and neuroscience materials.",
            "the brain's legal implications won't study themselves — focus."
        ]
        default: return [
            "CLOSE THIS. open your neurolaw study materials.",
            "CLOSE THIS. law and neuroscience demands your full attention.",
            "CLOSE THIS. brain science in court won't understand itself."
        ]
        }
    }

    private func climatelawCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those carbon market regulations aren't going to read themselves.",
            "close this and get back to your climate law coursework.",
            "the Paris Agreement won't analyze itself — close this.",
            "climate treaties don't interpret themselves — close this.",
        ]
        case 2: return [
            "no one masters climate law by scrolling.",
            "close this and open your climate law study materials.",
            "the planet's legal framework won't study itself — focus."
        ]
        default: return [
            "CLOSE THIS. open your climate law notes.",
            "CLOSE THIS. carbon market law demands your full attention.",
            "CLOSE THIS. climate treaties won't interpret themselves."
        ]
        }
    }

    private func athletictrainingCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those therapeutic modalities aren't going to study themselves.",
            "close this and get back to your athletic training coursework.",
            "your athletes need a trainer who actually studies — close this.",
            "taping techniques don't learn themselves — close this.",
        ]
        case 2: return [
            "no one earns their ATC credential by scrolling.",
            "close this and open your athletic training materials.",
            "sport injury evaluation won't memorize itself — focus."
        ]
        default: return [
            "CLOSE THIS. open your athletic training notes.",
            "CLOSE THIS. your ATC exam won't pass itself.",
            "CLOSE THIS. certified athletic trainers earn it — close this and study."
        ]
        }
    }

    private func biomechanicsCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those force plate results aren't going to analyze themselves.",
            "close this and get back to your biomechanics lab.",
            "joint kinetics won't calculate themselves — close this.",
            "motion capture data doesn't process itself — close this.",
        ]
        case 2: return [
            "no one masters biomechanics by scrolling.",
            "close this and open your biomechanics analysis.",
            "gait lab data won't interpret itself — focus."
        ]
        default: return [
            "CLOSE THIS. open your biomechanics lab work.",
            "CLOSE THIS. kinematic analysis demands your full attention.",
            "CLOSE THIS. force plates don't read themselves."
        ]
        }
    }

    private func zoologyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those taxonomic classifications aren't going to memorize themselves.",
            "close this and get back to your zoology coursework.",
            "invertebrate zoology won't study itself — close this.",
            "animal morphology doesn't describe itself — close this.",
        ]
        case 2: return [
            "no one passes their zoology exam by scrolling.",
            "close this and open your zoology study materials.",
            "taxonomic keys won't unlock themselves — focus."
        ]
        default: return [
            "CLOSE THIS. open your zoology notes.",
            "CLOSE THIS. species identification demands your full attention.",
            "CLOSE THIS. zoologists know their taxa — close this and study."
        ]
        }
    }

    private func militaryscienceCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those leadership lab requirements aren't going to complete themselves.",
            "close this and get back to your military science coursework.",
            "ROTC tactics don't study themselves — close this.",
            "cadet leadership doesn't develop itself — close this.",
        ]
        case 2: return [
            "no one earns their commission by scrolling.",
            "close this and open your military science materials.",
            "military tactics won't memorize themselves — focus."
        ]
        default: return [
            "CLOSE THIS. open your ROTC class notes.",
            "CLOSE THIS. military leaders lead — close this and study.",
            "CLOSE THIS. your cadet program demands your full attention."
        ]
        }
    }

    private func healthinformaticsCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those FHIR standards aren't going to implement themselves.",
            "close this and get back to your health informatics coursework.",
            "HL7 interoperability won't study itself — close this.",
            "health data exchange doesn't configure itself — close this.",
        ]
        case 2: return [
            "no one passes the CPHIMS exam by scrolling.",
            "close this and open your health informatics materials.",
            "clinical decision support won't build itself — focus."
        ]
        default: return [
            "CLOSE THIS. open your health informatics notes.",
            "CLOSE THIS. FHIR implementation demands your full attention.",
            "CLOSE THIS. health data won't interoperate itself."
        ]
        }
    }

    private func cryptographyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those cipher algorithms aren't going to analyze themselves.",
            "close this and get back to your cryptography coursework.",
            "public-key cryptography won't study itself — close this.",
            "RSA won't break itself — close this and study.",
        ]
        case 2: return [
            "no one cracks cryptography by scrolling.",
            "close this and open your crypto notes.",
            "your cipher schemes won't design themselves — focus."
        ]
        default: return [
            "CLOSE THIS. open your cryptography materials.",
            "CLOSE THIS. secure systems require focused study.",
            "CLOSE THIS. AES won't implement itself."
        ]
        }
    }

    private func appliedmathematicsCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those differential equations aren't going to solve themselves.",
            "close this and get back to your applied math coursework.",
            "PDEs won't model themselves — close this.",
            "numerical methods won't converge on their own — close this.",
        ]
        case 2: return [
            "no one passes applied math by scrolling.",
            "close this and open your mathematical modeling notes.",
            "your ODE problem sets won't finish themselves — focus."
        ]
        default: return [
            "CLOSE THIS. open your applied mathematics notes.",
            "CLOSE THIS. differential equations demand your full attention.",
            "CLOSE THIS. math modeling won't do itself."
        ]
        }
    }

    private func historicallinguisticsCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those sound change laws aren't going to memorize themselves.",
            "close this and get back to your historical linguistics coursework.",
            "proto-languages won't reconstruct themselves — close this.",
            "Grimm's Law won't apply itself — close this.",
        ]
        case 2: return [
            "no one masters diachronic linguistics by scrolling.",
            "close this and open your historical linguistics notes.",
            "language reconstruction won't happen on its own — focus."
        ]
        default: return [
            "CLOSE THIS. open your historical linguistics materials.",
            "CLOSE THIS. proto-Indo-European demands your full attention.",
            "CLOSE THIS. sound changes won't trace themselves."
        ]
        }
    }

    private func computationalfinanceCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that Black-Scholes model isn't going to derive itself.",
            "close this and get back to your quantitative finance coursework.",
            "your Monte Carlo simulation won't run itself — close this.",
            "stochastic calculus won't study itself — close this.",
        ]
        case 2: return [
            "no one becomes a quant by scrolling.",
            "close this and open your financial engineering notes.",
            "options pricing models won't build themselves — focus."
        ]
        default: return [
            "CLOSE THIS. open your quant finance materials.",
            "CLOSE THIS. financial mathematics demands your full attention.",
            "CLOSE THIS. algorithmic trading strategies won't write themselves."
        ]
        }
    }

    private func globalpoliticaleconomyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those IPE frameworks aren't going to analyze themselves.",
            "close this and get back to your political economy coursework.",
            "global political economy won't study itself — close this.",
            "world systems theory won't write itself — close this.",
        ]
        case 2: return [
            "no one masters IPE by scrolling.",
            "close this and open your political economy notes.",
            "comparative political economy won't analyze itself — focus."
        ]
        default: return [
            "CLOSE THIS. open your IPE study materials.",
            "CLOSE THIS. political economy demands your full attention.",
            "CLOSE THIS. dependency theory won't explain itself."
        ]
        }
    }

    private func geopoliticsCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that geopolitical analysis isn't going to write itself.",
            "close this and get back to your geopolitics work.",
            "great power competition doesn't wait for you to stop scrolling.",
            "your geopolitical risk assessment won't finish itself — close this.",
        ]
        case 2: return [
            "no one becomes a geopolitics expert by scrolling.",
            "close this and open your geopolitical analysis notes.",
            "the geopolitical landscape won't map itself — focus."
        ]
        default: return [
            "CLOSE THIS. open your geopolitics materials.",
            "CLOSE THIS. geopolitical analysis demands your full attention.",
            "CLOSE THIS. your geopolitical risk report won't write itself."
        ]
        }
    }

    private func computationalbiologyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those biological models aren't going to build themselves.",
            "close this and get back to your computational biology work.",
            "systems biology won't model itself — close this.",
            "your population dynamics assignment won't finish itself — close this.",
        ]
        case 2: return [
            "no one masters computational biology by scrolling.",
            "close this and open your biological modeling code.",
            "mathematical biology won't solve itself — focus."
        ]
        default: return [
            "CLOSE THIS. open your computational biology tools.",
            "CLOSE THIS. biological network analysis demands your full attention.",
            "CLOSE THIS. your systems biology model won't run itself."
        ]
        }
    }

    private func philosophyofmindCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "consciousness won't study itself — close this.",
            "close this and get back to your philosophy of mind coursework.",
            "the hard problem of consciousness is hard — scrolling makes it harder.",
            "your qualia paper won't write itself — close this.",
        ]
        case 2: return [
            "no one solves the mind-body problem by scrolling.",
            "close this and open your philosophy of mind notes.",
            "phenomenal consciousness demands your full attention — focus."
        ]
        default: return [
            "CLOSE THIS. open your philosophy of mind materials.",
            "CLOSE THIS. consciousness studies require you to be conscious of your focus.",
            "CLOSE THIS. your mind-body problem paper won't write itself."
        ]
        }
    }

    private func digitalhumanitiesCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those texts aren't going to mine themselves.",
            "close this and get back to your digital humanities project.",
            "distant reading requires actual reading — close this.",
            "your cultural analytics project won't finish itself — close this.",
        ]
        case 2: return [
            "no one masters digital humanities by scrolling.",
            "close this and open your DH tools.",
            "that corpus won't analyze itself — focus."
        ]
        default: return [
            "CLOSE THIS. open your digital humanities project.",
            "CLOSE THIS. text mining requires you to open the texts.",
            "CLOSE THIS. your humanities computing assignment won't do itself."
        ]
        }
    }

    private func environmentalpolicyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that environmental policy paper isn't going to write itself.",
            "close this and get back to your climate policy work.",
            "carbon policy won't analyze itself — close this.",
            "your environmental governance assignment won't finish itself — close this.",
        ]
        case 2: return [
            "no one shapes climate policy by scrolling.",
            "close this and open your environmental policy notes.",
            "climate legislation won't analyze itself — focus."
        ]
        default: return [
            "CLOSE THIS. open your environmental policy materials.",
            "CLOSE THIS. climate policy analysis demands your full attention.",
            "CLOSE THIS. your carbon policy paper won't write itself."
        ]
        }
    }

    private func cognitivelinguisticsCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that cognitive grammar analysis isn't going to write itself.",
            "close this and get back to your cognitive linguistics work.",
            "conceptual metaphors won't map themselves — close this.",
            "frame semantics won't analyze itself — close this.",
        ]
        case 2: return [
            "no one masters cognitive linguistics by scrolling.",
            "close this and open your cognitive linguistics notes.",
            "construction grammar won't study itself — focus."
        ]
        default: return [
            "CLOSE THIS. open your cognitive linguistics materials.",
            "CLOSE THIS. Lakoff and Langacker demand your full attention.",
            "CLOSE THIS. conceptual blending theory won't explain itself."
        ]
        }
    }

    private func environmentaljusticeCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that environmental justice analysis isn't going to write itself.",
            "close this and get back to your EJ coursework.",
            "cumulative environmental burdens won't document themselves — close this.",
            "environmental racism won't address itself by scrolling — close this.",
        ]
        case 2: return [
            "no one advances environmental justice by scrolling.",
            "close this and open your EJ materials.",
            "your sacrifice zone analysis won't finish itself — focus."
        ]
        default: return [
            "CLOSE THIS. open your environmental justice materials.",
            "CLOSE THIS. environmental health disparities demand your full attention.",
            "CLOSE THIS. your EJ paper won't write itself."
        ]
        }
    }

    private func schoolcounselingCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those counseling case notes aren't going to write themselves.",
            "close this and get back to your school counseling work.",
            "your students need you focused — close this.",
            "your CACREP practicum notes won't write themselves — close this.",
        ]
        case 2: return [
            "no one becomes a school counselor by scrolling.",
            "close this and open your counseling materials.",
            "career development theory won't study itself — focus."
        ]
        default: return [
            "CLOSE THIS. open your school counseling notes.",
            "CLOSE THIS. your counseling licensure exam won't pass itself.",
            "CLOSE THIS. student affairs theory demands your full attention."
        ]
        }
    }

    private func cognitivepsychologyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that working memory research isn't going to write itself.",
            "close this and get back to your cognitive psychology work.",
            "cognitive load is real — and so is your assignment.",
            "selective attention won't study itself — close this.",
        ]
        case 2: return [
            "no one masters cognitive psych by scrolling.",
            "close this and open your cognitive psychology notes.",
            "information processing won't happen on its own — focus."
        ]
        default: return [
            "CLOSE THIS. open your cognitive psychology materials.",
            "CLOSE THIS. working memory has limits — use them wisely.",
            "CLOSE THIS. Baddeley's model won't review itself."
        ]
        }
    }

    private func developmentalpsychologyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those developmental milestones aren't going to memorize themselves.",
            "close this and get back to your developmental psychology work.",
            "Vygotsky didn't discover the ZPD by scrolling.",
            "your child development assignment won't finish itself — close this.",
        ]
        case 2: return [
            "no one masters lifespan development by scrolling.",
            "close this and open your developmental psych notes.",
            "Erikson's stages won't study themselves — focus."
        ]
        default: return [
            "CLOSE THIS. open your developmental psychology materials.",
            "CLOSE THIS. child development theory demands your full attention.",
            "CLOSE THIS. Kohlberg's moral stages won't memorize themselves."
        ]
        }
    }

    private func paleontologyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those fossils aren't going to analyze themselves.",
            "close this and get back to your paleontology work.",
            "taphonomy won't study itself — close this.",
            "the fossil record doesn't care about your feed — close this.",
        ]
        case 2: return [
            "no one masters paleontology by scrolling.",
            "close this and open your paleontology notes.",
            "prehistoric life deserves your full attention — focus."
        ]
        default: return [
            "CLOSE THIS. open your paleontology materials.",
            "CLOSE THIS. fossil analysis demands your full attention.",
            "CLOSE THIS. the cambrian explosion happened faster than you're working."
        ]
        }
    }

    private func experimentalphysicsCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that physics lab report isn't going to write itself.",
            "close this and get back to your physics experiment.",
            "your optics data won't analyze itself — close this.",
            "experimental results don't interpret themselves — close this.",
        ]
        case 2: return [
            "no one passes experimental physics by scrolling.",
            "close this and open your physics lab report.",
            "your quantum mechanics problem set won't finish itself — focus."
        ]
        default: return [
            "CLOSE THIS. open your physics lab report.",
            "CLOSE THIS. your experimental data demands analysis.",
            "CLOSE THIS. Feynman didn't scroll through his physics."
        ]
        }
    }

    private func informationscienceCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that information retrieval assignment isn't going to complete itself.",
            "close this and get back to your information science work.",
            "knowledge management won't organize itself — close this.",
            "your information science coursework demands your attention — close this.",
        ]
        case 2: return [
            "no one masters information science by scrolling.",
            "close this and open your information science notes.",
            "your digital curation assignment won't finish itself — focus."
        ]
        default: return [
            "CLOSE THIS. open your information science materials.",
            "CLOSE THIS. information retrieval theory demands your full attention.",
            "CLOSE THIS. knowledge management starts with managing your own focus."
        ]
        }
    }

    private func socialepidemiologyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those health disparities won't research themselves.",
            "close this and get back to your social epidemiology work.",
            "social determinants of health don't study themselves — close this.",
            "your health disparities paper won't write itself — close this.",
        ]
        case 2: return [
            "no one advances health equity by scrolling.",
            "close this and open your social epi materials.",
            "your SDoH analysis won't finish itself — focus."
        ]
        default: return [
            "CLOSE THIS. open your social epidemiology notes.",
            "CLOSE THIS. health disparities research demands your full attention.",
            "CLOSE THIS. social determinants of health deserve serious study."
        ]
        }
    }

    private func cognitiveneuroscienceCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that fMRI analysis isn't going to run itself.",
            "close this and get back to your cognitive neuroscience work.",
            "BOLD signal won't interpret itself — close this.",
            "your neuroimaging data demands attention — close this.",
        ]
        case 2: return [
            "no one masters cognitive neuroscience by scrolling.",
            "close this and open your cognitive neuroscience notes.",
            "your EEG analysis won't finish itself — focus."
        ]
        default: return [
            "CLOSE THIS. open your cognitive neuroscience materials.",
            "CLOSE THIS. fMRI data analysis demands your full attention.",
            "CLOSE THIS. the brain you're studying is the one letting you scroll — use it."
        ]
        }
    }

    private func nanotechnologyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those nanoparticles aren't going to characterize themselves.",
            "close this and get back to your nanotechnology work.",
            "nanoscale precision demands full attention — close this.",
            "your nanofabrication assignment won't complete itself — close this.",
        ]
        case 2: return [
            "no one advances nanotechnology by scrolling.",
            "close this and open your nanotechnology notes.",
            "your quantum dot synthesis report won't write itself — focus."
        ]
        default: return [
            "CLOSE THIS. open your nanotechnology materials.",
            "CLOSE THIS. nanoscale work demands nanoscale focus.",
            "CLOSE THIS. Feynman said there's plenty of room at the bottom — go find it."
        ]
        }
    }

    private func appliedlinguisticsCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that second language acquisition analysis isn't going to write itself.",
            "close this and get back to your applied linguistics work.",
            "language pedagogy won't design itself — close this.",
            "your SLA research paper demands your attention — close this.",
        ]
        case 2: return [
            "no one masters applied linguistics by scrolling.",
            "close this and open your applied linguistics notes.",
            "your language assessment assignment won't finish itself — focus."
        ]
        default: return [
            "CLOSE THIS. open your applied linguistics materials.",
            "CLOSE THIS. SLA theory demands active engagement.",
            "CLOSE THIS. language doesn't acquire itself — neither does your degree."
        ]
        }
    }

    private func radiobiologyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that DNA damage analysis isn't going to write itself.",
            "close this and get back to your radiobiology work.",
            "radiation cell biology won't study itself — close this.",
            "your radiobiology assignment demands your attention — close this.",
        ]
        case 2: return [
            "no one masters radiobiology by scrolling.",
            "close this and open your radiobiology notes.",
            "your survival curve analysis won't finish itself — focus."
        ]
        default: return [
            "CLOSE THIS. open your radiobiology materials.",
            "CLOSE THIS. ionizing radiation doesn't wait — neither should your studying.",
            "CLOSE THIS. radiation biology demands your full attention."
        ]
        }
    }

    private func translationstudiesCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that literary translation isn't going to translate itself.",
            "close this and get back to your translation work.",
            "CAT tools won't use themselves — close this.",
            "your translation assignment demands your full attention — close this.",
        ]
        case 2: return [
            "no one masters translation studies by scrolling.",
            "close this and open your translation project.",
            "your localization work won't finish itself — focus."
        ]
        default: return [
            "CLOSE THIS. open your translation files.",
            "CLOSE THIS. words don't translate themselves.",
            "CLOSE THIS. great translators translate — close this and be one."
        ]
        }
    }

    private func ecologyconservationCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those species aren't going to save themselves.",
            "close this and get back to your conservation biology work.",
            "habitat restoration won't plan itself — close this.",
            "your wildlife ecology assignment demands your attention — close this.",
        ]
        case 2: return [
            "no one saves ecosystems by scrolling.",
            "close this and open your conservation biology notes.",
            "your species management plan won't write itself — focus."
        ]
        default: return [
            "CLOSE THIS. open your conservation biology materials.",
            "CLOSE THIS. biodiversity loss doesn't pause while you scroll.",
            "CLOSE THIS. the species you're studying need you focused."
        ]
        }
    }

    private func astrobiologyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "extremophiles aren't going to study themselves.",
            "close this and get back to your astrobiology work.",
            "planetary habitability won't analyze itself — close this.",
            "your astrobiology assignment demands your full attention — close this.",
        ]
        case 2: return [
            "no one finds life in the universe by scrolling.",
            "close this and open your astrobiology notes.",
            "your prebiotic chemistry work won't finish itself — focus."
        ]
        default: return [
            "CLOSE THIS. open your astrobiology materials.",
            "CLOSE THIS. the universe isn't going to search itself.",
            "CLOSE THIS. biosignatures don't detect themselves — neither does your degree."
        ]
        }
    }

    private func materialscharacterizationCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those XRD patterns aren't going to analyze themselves.",
            "close this and get back to your materials characterization work.",
            "the SEM images won't interpret themselves — close this.",
            "your materials characterization lab report demands your attention — close this.",
        ]
        case 2: return [
            "no one characterizes materials by scrolling.",
            "close this and open your characterization data.",
            "your Raman spectra won't assign themselves — focus."
        ]
        default: return [
            "CLOSE THIS. open your characterization data.",
            "CLOSE THIS. XRD peaks don't index themselves.",
            "CLOSE THIS. your SEM data is waiting — so is your degree."
        ]
        }
    }

    private func toxicogenomicsCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those gene expression profiles aren't going to analyze themselves.",
            "close this and get back to your toxicogenomics work.",
            "the AhR pathway won't map itself — close this.",
            "your toxicogenomics assignment demands your full attention — close this.",
        ]
        case 2: return [
            "no one masters toxicogenomics by scrolling.",
            "close this and open your toxicogenomics data.",
            "your TOXCAST analysis won't complete itself — focus."
        ]
        default: return [
            "CLOSE THIS. open your toxicogenomics dataset.",
            "CLOSE THIS. gene expression under toxic exposure doesn't analyze itself.",
            "CLOSE THIS. your omics data is waiting — and so is your deadline."
        ]
        }
    }

    private func developmentalbiology_Callouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those morphogen gradients aren't going to analyze themselves.",
            "close this and get back to your developmental biology work.",
            "Hox genes won't study themselves — close this.",
            "your developmental biology assignment demands your full attention — close this.",
        ]
        case 2: return [
            "no one masters developmental biology by scrolling.",
            "close this and open your developmental biology notes.",
            "your fate mapping analysis won't write itself — focus."
        ]
        default: return [
            "CLOSE THIS. open your developmental biology materials.",
            "CLOSE THIS. embryos don't study themselves — neither do you while scrolling.",
            "CLOSE THIS. organogenesis doesn't wait — neither should your studying."
        ]
        }
    }

    private func drugdiscoveryCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that lead compound isn't going to optimize itself.",
            "close this and get back to your drug discovery work.",
            "your ADMET analysis won't complete itself — close this.",
            "your drug discovery assignment demands your full attention — close this.",
        ]
        case 2: return [
            "no one discovers drugs by scrolling.",
            "close this and open your medicinal chemistry notes.",
            "your SAR analysis won't write itself — focus."
        ]
        default: return [
            "CLOSE THIS. open your drug discovery data.",
            "CLOSE THIS. lead optimization doesn't happen by scrolling.",
            "CLOSE THIS. high-throughput screening needs you at the bench, not the feed."
        ]
        }
    }

    private func organicchemistryCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "your reaction mechanism isn't going to draw itself.",
            "close this and get back to your orgo problem set.",
            "your synthesis route won't plan itself — close this.",
            "organic chemistry demands your full focus — close this.",
        ]
        case 2: return [
            "no one passes orgo by scrolling.",
            "close this and open your orgo notes.",
            "your retrosynthesis won't write itself — focus."
        ]
        default: return [
            "CLOSE THIS. open your orgo textbook.",
            "CLOSE THIS. SN2 doesn't happen by itself — neither does your studying.",
            "CLOSE THIS. your mechanisms aren't going to appear while you scroll."
        ]
        }
    }

    private func botanyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those plants aren't going to study themselves.",
            "close this and get back to your botany work.",
            "your plant taxonomy won't classify itself — close this.",
            "botany demands your full focus — close this.",
        ]
        case 2: return [
            "no one masters plant biology by scrolling.",
            "close this and open your botany notes.",
            "your plant physiology lab won't write itself — focus."
        ]
        default: return [
            "CLOSE THIS. open your plant biology textbook.",
            "CLOSE THIS. the herbarium isn't going to identify itself.",
            "CLOSE THIS. plant taxonomy waits for no one."
        ]
        }
    }

    private func operationsresearchCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that linear program won't solve itself.",
            "close this and get back to your operations research work.",
            "your OR model isn't going to optimize itself — close this.",
            "operations research demands your full attention — close this.",
        ]
        case 2: return [
            "no one solves OR problems by scrolling.",
            "close this and open your OR notes.",
            "your queueing model won't analyze itself — focus."
        ]
        default: return [
            "CLOSE THIS. open your operations research textbook.",
            "CLOSE THIS. the simplex method doesn't run itself.",
            "CLOSE THIS. stochastic optimization needs you focused."
        ]
        }
    }

    private func internalauditCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that audit report isn't going to write itself.",
            "close this and get back to your internal audit work.",
            "your control testing won't complete itself — close this.",
            "audit prep demands your full focus — close this.",
        ]
        case 2: return [
            "no one passes the CIA exam by scrolling.",
            "close this and open your audit notes.",
            "your audit planning won't do itself — focus."
        ]
        default: return [
            "CLOSE THIS. open your internal audit materials.",
            "CLOSE THIS. controls don't test themselves.",
            "CLOSE THIS. the CIA exam won't prep itself while you scroll."
        ]
        }
    }

    private func healthcarequalityCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that quality improvement project isn't going to plan itself.",
            "close this and get back to your healthcare quality work.",
            "your CPHQ prep won't complete itself — close this.",
            "patient safety demands your full focus — close this.",
        ]
        case 2: return [
            "no one passes the CPHQ by scrolling.",
            "close this and open your quality improvement notes.",
            "your root cause analysis won't write itself — focus."
        ]
        default: return [
            "CLOSE THIS. open your healthcare quality materials.",
            "CLOSE THIS. quality indicators won't review themselves.",
            "CLOSE THIS. patient safety is too important for scrolling."
        ]
        }
    }

    private func nursinganesthesiaCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that CRNA exam isn't going to study itself.",
            "close this and get back to your nurse anesthesia work.",
            "your anesthesia pharmacology won't review itself — close this.",
            "the NBCRNA won't wait while you scroll — close this.",
        ]
        case 2: return [
            "no one passes the NBCRNA by scrolling.",
            "close this and open your nurse anesthesia notes.",
            "your CRNA clinical prep won't do itself — focus."
        ]
        default: return [
            "CLOSE THIS. open your nurse anesthesia materials.",
            "CLOSE THIS. anesthesia pharmacology doesn't memorize itself.",
            "CLOSE THIS. the NBCRNA exam demands your full attention."
        ]
        }
    }

    private func physicalchemistryCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that pchem problem set isn't going to solve itself.",
            "close this and get back to your physical chemistry work.",
            "Gibbs energy won't calculate itself — close this.",
            "physical chemistry demands your full focus — close this.",
        ]
        case 2: return [
            "no one masters pchem by scrolling.",
            "close this and open your physical chemistry notes.",
            "your partition function won't work out itself — focus."
        ]
        default: return [
            "CLOSE THIS. open your pchem textbook.",
            "CLOSE THIS. chemical kinetics doesn't derive itself.",
            "CLOSE THIS. the Schrödinger equation won't solve itself while you scroll."
        ]
        }
    }

    private func inorganicchemistryCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those coordination complexes aren't going to study themselves.",
            "close this and get back to your inorganic chemistry work.",
            "crystal field theory won't review itself — close this.",
            "inorganic chemistry demands your full focus — close this.",
        ]
        case 2: return [
            "no one masters coordination chemistry by scrolling.",
            "close this and open your inorganic notes.",
            "your ligand field analysis won't write itself — focus."
        ]
        default: return [
            "CLOSE THIS. open your inorganic chemistry textbook.",
            "CLOSE THIS. d-block elements don't study themselves.",
            "CLOSE THIS. crystal field splitting won't appear while you scroll."
        ]
        }
    }

    private func analyticalchemistryCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that HPLC method isn't going to validate itself.",
            "close this and get back to your analytical chemistry work.",
            "your titration won't calculate itself — close this.",
            "analytical chemistry demands your full focus — close this.",
        ]
        case 2: return [
            "no one masters analytical chemistry by scrolling.",
            "close this and open your analytical chemistry notes.",
            "your GC-MS data won't interpret itself — focus."
        ]
        default: return [
            "CLOSE THIS. open your analytical chemistry notes.",
            "CLOSE THIS. chromatograms don't read themselves.",
            "CLOSE THIS. your titration calculations won't appear while you scroll."
        ]
        }
    }

    private func nuclearchemistryCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those radioactive decay equations aren't going to solve themselves.",
            "close this and get back to your nuclear chemistry work.",
            "half-life calculations won't do themselves — close this.",
            "nuclear chemistry demands your full focus — close this.",
        ]
        case 2: return [
            "no one masters nuclear chemistry by scrolling.",
            "close this and open your nuclear chemistry notes.",
            "your nuclear equations won't balance themselves — focus."
        ]
        default: return [
            "CLOSE THIS. open your nuclear chemistry textbook.",
            "CLOSE THIS. radioactive isotopes don't study themselves.",
            "CLOSE THIS. decay series don't resolve while you scroll."
        ]
        }
    }

    private func electrochemistryCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that electrochemistry problem set isn't going to solve itself.",
            "close this and get back to your electrochemistry work.",
            "the Nernst equation won't balance itself — close this.",
            "electrochemical cells don't build themselves — focus.",
        ]
        case 2: return [
            "no one masters electrochemistry by scrolling.",
            "close this and open your electrochemistry notes.",
            "your electrode potentials won't calculate themselves — focus."
        ]
        default: return [
            "CLOSE THIS. open your electrochemistry textbook.",
            "CLOSE THIS. galvanic cells don't study themselves.",
            "CLOSE THIS. cyclic voltammetry won't run while you scroll."
        ]
        }
    }

    private func polymerchemistryCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that polymer chemistry problem set isn't going to solve itself.",
            "close this and get back to your polymer chemistry work.",
            "polymerization reactions won't diagram themselves — close this.",
            "polymer science demands your full focus — close this.",
        ]
        case 2: return [
            "no one masters polymer chemistry by scrolling.",
            "close this and open your polymer science notes.",
            "your molecular weight distributions won't calculate themselves — focus."
        ]
        default: return [
            "CLOSE THIS. open your polymer chemistry textbook.",
            "CLOSE THIS. polymerization mechanisms don't study themselves.",
            "CLOSE THIS. polymer characterization won't happen while you scroll."
        ]
        }
    }

    private func maternalhealthCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that maternal health assignment isn't going to write itself.",
            "close this and get back to your OB nursing work.",
            "maternal-fetal medicine won't study itself — close this.",
            "your obstetrics coursework needs your full attention — close this.",
        ]
        case 2: return [
            "no one masters maternal health by scrolling.",
            "close this and open your OB nursing notes.",
            "your prenatal care materials won't review themselves — focus."
        ]
        default: return [
            "CLOSE THIS. open your maternal health textbook.",
            "CLOSE THIS. obstetric nursing doesn't study itself.",
            "CLOSE THIS. maternal health notes won't read while you scroll."
        ]
        }
    }

    private func globalhealthpolicyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that global health policy paper isn't going to write itself.",
            "close this and get back to your global health policy work.",
            "health systems strengthening won't study itself — close this.",
            "global health governance demands your full focus — close this.",
        ]
        case 2: return [
            "no one masters global health policy by scrolling.",
            "close this and open your global health policy notes.",
            "your UHC policy framework won't analyze itself — focus."
        ]
        default: return [
            "CLOSE THIS. open your global health policy materials.",
            "CLOSE THIS. health systems don't strengthen while you scroll.",
            "CLOSE THIS. global health governance won't study itself."
        ]
        }
    }

    private func processengineeringCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that unit operations problem set isn't going to solve itself.",
            "close this and get back to your process engineering work.",
            "reactor design won't happen while you scroll — close this.",
            "your mass and energy balances need your full focus — close this.",
        ]
        case 2: return [
            "no one masters process engineering by scrolling.",
            "close this and open your unit operations notes.",
            "Aspen Plus won't simulate itself — focus."
        ]
        default: return [
            "CLOSE THIS. open your unit operations textbook.",
            "CLOSE THIS. reactor design doesn't happen while you scroll.",
            "CLOSE THIS. transport phenomena won't solve itself."
        ]
        }
    }
}
