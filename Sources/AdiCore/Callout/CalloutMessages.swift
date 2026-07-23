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
        case "forensicchemistry":      return forensicchemistryCallouts(tier: tier)
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
        case "optogenetics":           return optogeneticsCallouts(tier: tier)
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
        case "gametheory":            return gametheoryCallouts(tier: tier)
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
        case "globalenvironmentalgovernance": return globalenvironmentalgovernanceCallouts(tier: tier)
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
        case "civilengineering":           return civilengineeringCallouts(tier: tier)
        case "syntheticbiology":           return syntheticbiologyCallouts(tier: tier)
        case "proteomics":                 return proteomicsCallouts(tier: tier)
        case "metabolomics":               return metabolomicsCallouts(tier: tier)
        case "electrophysiology":          return electrophysiologyCallouts(tier: tier)
        case "aerospacengineering":        return aerospacengineeringCallouts(tier: tier)
        case "aerostructures":             return aerostructuresCallouts(tier: tier)
        case "controlengineering":         return controlengineeringCallouts(tier: tier)
        case "electricalengineering":      return electricalengineeringCallouts(tier: tier)
        case "signalprocessing":           return signalprocessingCallouts(tier: tier)
        case "genetics":                   return geneticsCallouts(tier: tier)
        case "microbiology":               return microbiologyCallouts(tier: tier)
        case "immunology":                 return immunologyCallouts(tier: tier)
        case "parasitology":               return parasitologyCallouts(tier: tier)
        case "embryology":                 return embryologyCallouts(tier: tier)
        case "histology":                  return histologyCallouts(tier: tier)
        case "surgicalpathology":          return surgicalpathologyCallouts(tier: tier)
        case "pathology":                  return pathologyCallouts(tier: tier)
        case "neuroanatomy":               return neuroanatomyCallouts(tier: tier)
        case "chemicalkinetics":           return chemicalkineticsCallouts(tier: tier)
        case "computationalchemistry":     return computationalchemistryCallouts(tier: tier)
        case "ecology":                    return ecologyCallouts(tier: tier)
        case "neuropharmacology":          return neuropharmacologyCallouts(tier: tier)
        case "pharmacology":               return pharmacologyCallouts(tier: tier)
        case "physiology":                 return physiologyCallouts(tier: tier)
        case "mechanicalengineering":      return mechanicalengineeringCallouts(tier: tier)
        case "nuclearengineering":         return nuclearengineeringCallouts(tier: tier)
        case "materialstesting":           return materialstestingCallouts(tier: tier)
        case "compositematerials":         return compositematerialsCallouts(tier: tier)
        case "powerelectronics":           return powerelectronicsCallouts(tier: tier)
        case "geotechnicalengineering":    return geotechnicalengineeringCallouts(tier: tier)
        case "structuralanalysis":         return structuralanalysisCallouts(tier: tier)
        case "miningengineering":          return miningengineeringCallouts(tier: tier)
        case "wastewatertreatment":        return wastewatertreatmentCallouts(tier: tier)
        case "airpollutioncontrol":        return airpollutioncontrolCallouts(tier: tier)
        case "renewableenergy":            return renewableenergyCallouts(tier: tier)
        case "navalarchitecture":          return navalarchitectureCallouts(tier: tier)
        case "mechatronics":               return mechatronicsCallouts(tier: tier)
        case "structuraldynamics":         return structuraldynamicsCallouts(tier: tier)
        case "bioprocessengineering":      return bioprocessengineeringCallouts(tier: tier)
        case "systemsengineering":         return systemsengineeringCallouts(tier: tier)
        case "transportationplanning":     return transportationplanningCallouts(tier: tier)
        case "architecturalengineering":   return architecturalengineeringCallouts(tier: tier)
        case "environmentalhydrology":        return environmentalhydrologyCallouts(tier: tier)
        case "geoenvironmentalengineering":   return geoenvironmentalengineeringCallouts(tier: tier)
        case "earthquakeengineering":         return earthquakeengineeringCallouts(tier: tier)
        case "computationalstructuralmechanics": return computationalstructuralmechanicsCallouts(tier: tier)
        case "coastalengineeringocean":       return coastalengineeringoceanCallouts(tier: tier)
        case "biomedicalengineering":      return biomedicalengineeringCallouts(tier: tier)
        case "chemicalengineering":        return chemicalengineeringCallouts(tier: tier)
        case "oceanography":               return oceanographyCallouts(tier: tier)
        case "geochemistry":               return geochemistryCallouts(tier: tier)
        case "thermodynamics":             return thermodynamicsCallouts(tier: tier)
        case "radiologyrotation":          return radiologyrotationCallouts(tier: tier)
        case "anesthesiology":             return anesthesiologyCallouts(tier: tier)
        case "structuralbiology":          return structuralbiologyCallouts(tier: tier)
        case "biochemistrylab":            return biochemistrylabCallouts(tier: tier)
        case "clinicalneurology":          return clinicalneurologyCallouts(tier: tier)
        case "dermatologyrotation":        return dermatologyrotationCallouts(tier: tier)
        case "psychiatryrotation":         return psychiatryrotationCallouts(tier: tier)
        case "surgeryrotation":            return surgeryrotationCallouts(tier: tier)
        case "orthopedicsrotation":        return orthopedicsrotationCallouts(tier: tier)
        case "pediatricsrotation":         return pediatricsrotationCallouts(tier: tier)
        case "internalmedicine":           return internalMedicineCallouts(tier: tier)
        case "cardiologyrotation":         return cardiologyrotationCallouts(tier: tier)
        case "nephrologyrotation":         return nephrologyrotationCallouts(tier: tier)
        case "endocrinologyrotation":      return endocrinologyrotationCallouts(tier: tier)
        case "hematologyoncology":         return hematologyoncologyCallouts(tier: tier)
        case "neurologyrotation":          return neurologyrotationCallouts(tier: tier)
        case "obgynrotation":              return obgynrotationCallouts(tier: tier)
        case "familymedicine":             return familymedicineCallouts(tier: tier)
        case "emergencymedicinerotation":  return emergencymedicinerotationCallouts(tier: tier)
        case "clinicaltoxicology":         return clinicaltoxicologyCallouts(tier: tier)
        case "virology":                   return virologyCallouts(tier: tier)
        case "clinicalmicrobiology":       return clinicalmicrobiologyCallouts(tier: tier)
        case "medicinalchemistry":         return medicinalchemistryCallouts(tier: tier)
        case "cellandmolecularbiology":    return cellandmolecularbiologyCallouts(tier: tier)
        case "biochemistry2":              return biochemistry2Callouts(tier: tier)
        case "physicalchemistrylab":       return physicalchemistryLabCallouts(tier: tier)
        case "organicchemistrylab":        return organicchemistrylabCallouts(tier: tier)
        case "immunologycourse":           return immunologycourseCallouts(tier: tier)
        case "neurobiologylab":            return neurobiologylabCallouts(tier: tier)
        case "astronomylab":               return astronomylabCallouts(tier: tier)
        case "geologylab":                 return geologylabCallouts(tier: tier)
        case "environmentalscience":       return environmentalscienceCallouts(tier: tier)
        case "anthropology":               return anthropologyCallouts(tier: tier)
        case "demography":                 return demographyCallouts(tier: tier)
        case "sociology":                  return sociologyCallouts(tier: tier)
        case "biostatistics":              return biostatisticsCallouts(tier: tier)
        case "marinebiology2":             return marinebiology2Callouts(tier: tier)
        case "moleculargeneticslab":       return moleculargeneticslabCallouts(tier: tier)
        case "evolutionarybiology":        return evolutionarybiologyCallouts(tier: tier)
        case "biochemistry3":              return biochemistry3Callouts(tier: tier)
        case "atmosphericscience":         return atmosphericscienceCallouts(tier: tier)
        case "ecologicalfieldwork":        return ecologicalfieldworkCallouts(tier: tier)
        case "quantummechanics":           return quantummechanicsCallouts(tier: tier)
        case "solidstatephysics":          return solidstatephysicsCallouts(tier: tier)
        case "classicalmechanics":         return classicalmechanicsCallouts(tier: tier)
        case "astrophysics":               return astrophysicsCallouts(tier: tier)
        case "atmosphericchemistry":       return atmosphericchemistryCallouts(tier: tier)
        case "optics":                     return opticsCallouts(tier: tier)
        case "electromagnetism":           return electromagnetismCallouts(tier: tier)
        case "neuroimaging":               return neuroimagingCallouts(tier: tier)
        case "geophysics":                 return geophysicsCallouts(tier: tier)
        case "mineralogy":                 return mineralogyCallouts(tier: tier)
        case "petrology":                  return petrologyCallouts(tier: tier)
        case "hydrogeology":               return hydrogeologyCallouts(tier: tier)
        case "stratigraphy":               return stratigraphyCallouts(tier: tier)
        case "systemsbiology":             return systemsbiologyCallouts(tier: tier)
        case "microbiologylab":            return microbiologylabCallouts(tier: tier)
        case "ecophysiology":              return ecophysiologyCallouts(tier: tier)
        case "plantphysiology":            return plantphysiologyCallouts(tier: tier)
        case "animalphysiology":           return animalphysiologyCallouts(tier: tier)
        case "cellsignaling":              return cellsignalingCallouts(tier: tier)
        case "humangeneticsclass":         return humangeneticsclassCallouts(tier: tier)
        case "immunogenetics":             return immunogeneticsCallouts(tier: tier)
        case "neurologylab":               return neurologylabCallouts(tier: tier)
        case "socialpsychology":           return socialpsychologyCallouts(tier: tier)
        case "geriatricrotation":          return geriatricrotationCallouts(tier: tier)
        case "neurochemistry":             return neurochemistryCallouts(tier: tier)
        case "psychobiologyclass":         return psychobiologyclassCallouts(tier: tier)
        case "abnormalpsychology":         return abnormalpsychologyCallouts(tier: tier)
        case "healthpsychology":           return healthpsychologyCallouts(tier: tier)
        case "advancedlinearalgebra":      return advancedlinearalgebraCallouts(tier: tier)
        case "linearalgebra":              return linearalgebraCallouts(tier: tier)
        case "differentialequations":      return differentialequationsCallouts(tier: tier)
        case "neuropsychology":            return neuropsychologyCallouts(tier: tier)
        case "developmentalpsych":         return developmentalpsychCallouts(tier: tier)
        case "militarymedicine":           return militarymedicineCallouts(tier: tier)
        case "complexanalysis":            return complexanalysisCallouts(tier: tier)
        case "measuretheory":              return measuretheoryCallouts(tier: tier)
        case "realanalysis":               return realanalysisCallouts(tier: tier)
        case "discretemath":               return discretemathCallouts(tier: tier)
        case "probabilitytheory":          return probabilitytheoryCallouts(tier: tier)
        case "numericalanalysis":          return numericalanalysisCallouts(tier: tier)
        case "statisticalmethods":         return statisticalmethodsCallouts(tier: tier)
        case "algebraictopology":          return algebraictopologyCallouts(tier: tier)
        case "topology":                   return topologyCallouts(tier: tier)
        case "numbertheory":               return numbertheoryCallouts(tier: tier)
        case "abstractalgebra":            return abstractalgebraCallouts(tier: tier)
        case "seismology":                 return seismologyCallouts(tier: tier)
        case "volcanology":                return volcanologyCallouts(tier: tier)
        case "geomorphology":              return geomorphologyCallouts(tier: tier)
        case "sedimentology":              return sedimentologyCallouts(tier: tier)
        case "structuralgeology":          return structuralgeologyCallouts(tier: tier)
        case "functionalanalysis":         return functionalanalysisCallouts(tier: tier)
        case "riemanniangeometry":         return riemanniangeometryCallouts(tier: tier)
        case "differentialgeometry":       return differentialgeometryCallouts(tier: tier)
        case "cosmology":                  return cosmologyCallouts(tier: tier)
        case "planetaryscience":           return planetaryscienceCallouts(tier: tier)
        case "particlephysics":            return particlephysicsCallouts(tier: tier)
        case "statisticalmechanics":       return statisticalmechanicsCallouts(tier: tier)
        case "environmentalchemistry":     return environmentalchemistryCallouts(tier: tier)
        case "radioastronomy":             return radioastronomyCallouts(tier: tier)
        case "astrochemistry":             return astrochemistryCallouts(tier: tier)
        case "nuclearphysics":             return nuclearphysicsCallouts(tier: tier)
        case "plasmaphysics":              return plasmaphysicsCallouts(tier: tier)
        case "quantumoptics":              return quantumopticsCallouts(tier: tier)
        case "marinechemistry":            return marinechemistryCallouts(tier: tier)
        case "bioinorganicchemistry":      return bioinorganicchemistryCallouts(tier: tier)
        case "informationtheory":          return informationtheoryCallouts(tier: tier)
        case "mathematicalstatistics":     return mathematicalstatisticsCallouts(tier: tier)
        case "computationalfluidynamics":  return computationalfluidynamicsCallouts(tier: tier)
        case "hydrology":                  return hydrologyCallouts(tier: tier)
        case "glaciology":                 return glaciologyCallouts(tier: tier)
        case "climatology":                return climatologyCallouts(tier: tier)
        case "photochemistry":             return photochemistryCallouts(tier: tier)
        case "electromagnetictheory":      return electromagnetictheoryCallouts(tier: tier)
        case "operatingsystems":           return operatingsystemsCallouts(tier: tier)
        case "algorithms":                 return algorithmsCallouts(tier: tier)
        case "databasesystems":            return databasesystemsCallouts(tier: tier)
        case "computernetworks":           return computernetworksCallouts(tier: tier)
        case "computervision":             return computervisionCallouts(tier: tier)
        case "softwareengineering":        return softwareengineeringCallouts(tier: tier)
        case "humancomputerinteraction":   return humancomputerinteractionCallouts(tier: tier)
        case "machinelearning":            return machinelearningCallouts(tier: tier)
        case "distributedsystems":         return distributedsystemsCallouts(tier: tier)
        case "computersecurity":           return computersecurityCallouts(tier: tier)
        case "corrosionengineering":       return corrosionengineeringCallouts(tier: tier)
        case "additivemfg":                return additivemfgCallouts(tier: tier)
        case "batterytechnology":          return batterytechnologyCallouts(tier: tier)
        case "semiconductordevices":       return semiconductordevicesCallouts(tier: tier)
        case "vlsidesign":                 return vlsidesignCallouts(tier: tier)
        case "acousticalengineering":      return acousticalengineeringCallouts(tier: tier)
        case "microfluidics":              return microfluidicsCallouts(tier: tier)
        case "marinehydrodynamics":        return marinehydrodynamicsCallouts(tier: tier)
        case "thermofluidscombustion":     return thermofluidscombustionCallouts(tier: tier)
        case "spaceweather":               return spaceweatherCallouts(tier: tier)
        case "nanophotonics":              return nanophotonicsCallouts(tier: tier)
        case "microelectromechanicalsystems": return microelectromechanicalsystemsCallouts(tier: tier)
        case "photovoltaicsenergy":        return photovoltaicsenergyCallouts(tier: tier)
        case "biomechatronics":            return biomechatronicsCallouts(tier: tier)
        case "nucleardynamics":            return nucleardynamicsCallouts(tier: tier)
        case "nuclearreactorphysics":      return nuclearreactorphysicsCallouts(tier: tier)
        case "optoelectronics":            return optoelectronicsCallouts(tier: tier)
        case "magneticresonance":          return magneticresonanceCallouts(tier: tier)
        case "computationalelectromagnetics": return computationalelectromagneticsCallouts(tier: tier)
        case "thermoelectrics":            return thermoelectricsCallouts(tier: tier)
        case "quantumfieldtheory":         return quantumfieldtheoryCallouts(tier: tier)
        case "rfengineering":              return rfengineeringCallouts(tier: tier)
        case "fluidmechanics":             return fluidmechanicsCallouts(tier: tier)
        case "heattransfer":               return heattransferCallouts(tier: tier)
        case "powersystems":               return powersystemsCallouts(tier: tier)
        case "programminglanguages":       return programminglanguagesCallouts(tier: tier)
        case "compilerdesign":             return compilerdesignCallouts(tier: tier)
        case "computergraphics":           return computergraphicsCallouts(tier: tier)
        case "embeddedsystems":            return embeddedsystemsCallouts(tier: tier)
        case "formalverification":         return formalverificationCallouts(tier: tier)
        case "computationtheory":          return computationtheoryCallouts(tier: tier)
        case "softwarearchitecture":       return softwarearchitectureCallouts(tier: tier)
        case "informationretrieval":       return informationretrievalCallouts(tier: tier)
        case "naturallanguageprocessing":  return naturallanguageprocessingCallouts(tier: tier)
        case "computerarchitecture":       return computerarchitectureCallouts(tier: tier)
        case "photonics":                  return photonicsCallouts(tier: tier)
        case "acousticsengineering":       return acousticsengineeringCallouts(tier: tier)
        case "petroleumengineering":       return petroleumengineeringCallouts(tier: tier)
        case "sportspsychology":           return sportspsychologyCallouts(tier: tier)
        case "limnology":                  return limnologyCallouts(tier: tier)
        case "astrodynamics":              return astrodynamicsCallouts(tier: tier)
        case "biomaterials":               return biomaterialsCallouts(tier: tier)
        case "crystallography":            return crystallographyCallouts(tier: tier)
        case "spectroscopy":               return spectroscopyCallouts(tier: tier)
        case "industrialengineering":      return industrialengineeringCallouts(tier: tier)
        case "psycholinguistics":          return psycholinguisticsCallouts(tier: tier)
        case "photogrammetry":             return photogrammetryCallouts(tier: tier)
        case "tectonics":                  return tectonicsCallouts(tier: tier)
        case "tribology":                  return tribologyCallouts(tier: tier)
        case "radiochemistry":             return radiochemistryCallouts(tier: tier)
        case "condensedmatterphysics":     return condensedmatterphysicsCallouts(tier: tier)
        case "energymaterials":            return energymaterialsCallouts(tier: tier)
        case "computationalneuroscience":  return computationalneuroscienceCallouts(tier: tier)
        case "biophysicslab":              return biophysicslabCallouts(tier: tier)
        case "stochasticprocesses":        return stochasticprocessesCallouts(tier: tier)
        case "solidmechanics":             return solidmechanicsCallouts(tier: tier)
        case "opticalengineering":         return opticalengineeringCallouts(tier: tier)
        case "quantumchemistry":           return quantumchemistryCallouts(tier: tier)
        case "surfacechemistry":           return surfacechemistryCallouts(tier: tier)
        case "historicalgeology":          return historicalgeologyCallouts(tier: tier)
        case "agriculturalchemistry":      return agriculturalchemistryCallouts(tier: tier)
        case "digitalcommunications":      return digitalcommunicationsCallouts(tier: tier)
        case "contractlaw":                return contractlawCallouts(tier: tier)
        case "propertylaw":                return propertylawCallouts(tier: tier)
        case "corporatelaw":               return corporatelawCallouts(tier: tier)
        case "taxlaw":                     return taxlawCallouts(tier: tier)
        case "administrativelaw":          return administrativelawCallouts(tier: tier)
        case "physicaltherapy":            return physicaltherapyCallouts(tier: tier)
        case "medicalspanish":             return medicalspanishCallouts(tier: tier)
        case "musicology":                 return musicologyCallouts(tier: tier)
        case "patientadvocacy":            return patientadvocacyCallouts(tier: tier)
        case "animallaw":                  return animallawCallouts(tier: tier)
        case "computationallinguistics":   return computationallinguisticsCallouts(tier: tier)
        case "sociolinguistics":           return sociolinguisticsCallouts(tier: tier)
        case "agroecology":                return agroecologyCallouts(tier: tier)
        case "forensicengineering":        return forensicengineeringCallouts(tier: tier)
        case "healthlaw":                  return healthlawCallouts(tier: tier)
        case "metamaterials":              return metamaterialsCallouts(tier: tier)
        case "nondestructivetesting":      return nondestructivetestingCallouts(tier: tier)
        case "optimalcontrol":             return optimalcontrolCallouts(tier: tier)
        case "rocketpropulsion":           return rocketpropulsionCallouts(tier: tier)
        case "reliabilityengineering":     return reliabilityengineeringCallouts(tier: tier)
        case "deepseabiology":             return deepseabiologyCallouts(tier: tier)
        case "constructionestimating":     return constructionestimatingCallouts(tier: tier)
        case "internationallaw":           return internationallawCallouts(tier: tier)
        case "urbansociology":             return urbansociologyCallouts(tier: tier)
        case "politicalsociology":         return politicalsociologyCallouts(tier: tier)
        case "environmentaleconomics":     return environmentaleconomicsCallouts(tier: tier)
        case "socialepigenetics":          return socialepigeneticsCallouts(tier: tier)
        case "behavioralneuroscience":     return behavioralneuroscienceCallouts(tier: tier)
        case "medicalethics":              return medicalethicsCallouts(tier: tier)
        case "lawandeconomics":            return lawandeconomicsCallouts(tier: tier)
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

    private func civilengineeringCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that structural analysis isn't going to solve itself.",
            "close this and get back to your civil engineering work.",
            "reinforced concrete doesn't design itself — close this.",
            "your geotechnical problem set needs your full focus — close this.",
        ]
        case 2: return [
            "no one passes the PE exam by scrolling.",
            "close this and open your civil engineering notes.",
            "beams don't analyze themselves — focus."
        ]
        default: return [
            "CLOSE THIS. open your structural engineering textbook.",
            "CLOSE THIS. geotechnical design doesn't happen while you scroll.",
            "CLOSE THIS. your concrete design won't finish itself."
        ]
        }
    }

    private func syntheticbiologyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that genetic circuit isn't going to design itself.",
            "close this and get back to your synthetic biology work.",
            "your iGEM project won't build itself — close this.",
            "metabolic engineering doesn't happen while you scroll — close this.",
        ]
        case 2: return [
            "no one builds genetic circuits by scrolling.",
            "close this and open your synthetic biology notes.",
            "BioBrick parts won't assemble themselves — focus."
        ]
        default: return [
            "CLOSE THIS. open your synthetic biology design tool.",
            "CLOSE THIS. genetic circuits don't wire themselves.",
            "CLOSE THIS. your metabolic pathway won't engineer itself."
        ]
        }
    }

    private func proteomicsCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those protein spectra aren't going to analyze themselves.",
            "close this and get back to your proteomics work.",
            "your mass spec data won't interpret itself — close this.",
            "LC-MS/MS results don't analyze themselves — close this.",
        ]
        case 2: return [
            "no one identifies proteins by scrolling.",
            "close this and open your proteomics data analysis.",
            "your peptide identification won't finish itself — focus."
        ]
        default: return [
            "CLOSE THIS. open your mass spectrometry data.",
            "CLOSE THIS. proteomics data won't analyze while you scroll.",
            "CLOSE THIS. those spectra won't interpret themselves."
        ]
        }
    }

    private func metabolomicsCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those metabolite profiles aren't going to analyze themselves.",
            "close this and get back to your metabolomics work.",
            "your NMR data won't interpret itself — close this.",
            "LC-MS metabolomics doesn't happen while you scroll — close this.",
        ]
        case 2: return [
            "no one profiles metabolites by scrolling.",
            "close this and open your metabolomics dataset.",
            "your metabolic flux analysis won't finish itself — focus."
        ]
        default: return [
            "CLOSE THIS. open your metabolomics data.",
            "CLOSE THIS. metabolite profiles won't analyze while you scroll.",
            "CLOSE THIS. your metabolome won't map itself."
        ]
        }
    }

    private func electrophysiologyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that patch clamp data isn't going to analyze itself.",
            "close this and get back to your electrophysiology work.",
            "neurons fire — you should too. close this.",
            "your action potential recording won't interpret itself — close this.",
        ]
        case 2: return [
            "no one masters patch clamp by scrolling.",
            "close this and open your electrophysiology data.",
            "spike sorting won't finish itself — focus."
        ]
        default: return [
            "CLOSE THIS. open your electrophysiology recording.",
            "CLOSE THIS. patch clamp data doesn't analyze while you scroll.",
            "CLOSE THIS. your MEA data won't sort itself."
        ]
        }
    }

    private func aerospacengineeringCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that aerodynamics problem set isn't going to solve itself.",
            "close this and get back to your aerospace engineering work.",
            "your orbital mechanics homework won't finish itself — close this.",
            "spacecraft don't design themselves while you scroll — close this.",
        ]
        case 2: return [
            "no one gets to orbit by scrolling.",
            "close this and open your aerospace engineering notes.",
            "your propulsion problem set won't finish itself — focus."
        ]
        default: return [
            "CLOSE THIS. open your aerospace engineering textbook.",
            "CLOSE THIS. aerodynamics doesn't happen while you scroll.",
            "CLOSE THIS. your orbital mechanics won't solve itself."
        ]
        }
    }

    private func electricalengineeringCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that circuits problem set isn't going to solve itself.",
            "close this and get back to your electrical engineering work.",
            "your EE lab report won't write itself — close this.",
            "those circuit analysis problems won't solve themselves — close this.",
        ]
        case 2: return [
            "no one masters circuits by scrolling.",
            "close this and open your electrical engineering notes.",
            "your Kirchhoff's law problems won't finish themselves — focus."
        ]
        default: return [
            "CLOSE THIS. open your electrical engineering textbook.",
            "CLOSE THIS. circuits don't analyze while you scroll.",
            "CLOSE THIS. your signal processing problems won't solve themselves."
        ]
        }
    }

    private func geneticsCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those genetics problems aren't going to solve themselves.",
            "close this and get back to your genetics work.",
            "your Hardy-Weinberg problems won't finish themselves — close this.",
            "Mendel didn't discover inheritance by scrolling — close this.",
        ]
        case 2: return [
            "no one masters Mendelian genetics by scrolling.",
            "close this and open your genetics textbook.",
            "those Punnett squares won't fill themselves — focus."
        ]
        default: return [
            "CLOSE THIS. open your genetics notes.",
            "CLOSE THIS. population genetics doesn't happen while you scroll.",
            "CLOSE THIS. your genetics problem set won't solve itself."
        ]
        }
    }

    private func microbiologyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those bacteria aren't going to identify themselves.",
            "close this and get back to your microbiology work.",
            "your microbiology lab report won't write itself — close this.",
            "gram stains don't read themselves while you scroll — close this.",
        ]
        case 2: return [
            "no one masters microbiology by scrolling.",
            "close this and open your microbiology textbook.",
            "those culture plates won't analyze themselves — focus."
        ]
        default: return [
            "CLOSE THIS. open your microbiology notes.",
            "CLOSE THIS. bacterial identification doesn't happen while you scroll.",
            "CLOSE THIS. your microbiology lab won't complete itself."
        ]
        }
    }

    private func immunologyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "your immune system isn't going to study itself.",
            "close this and get back to your immunology work.",
            "those T cell activation pathways won't memorize themselves — close this.",
            "antigen presentation doesn't study itself while you scroll — close this.",
        ]
        case 2: return [
            "no one masters the immune system by scrolling.",
            "close this and open your immunology textbook.",
            "those antibody structure diagrams won't learn themselves — focus."
        ]
        default: return [
            "CLOSE THIS. open your immunology notes.",
            "CLOSE THIS. innate and adaptive immunity won't review themselves.",
            "CLOSE THIS. your immunology exam won't pass itself."
        ]
        }
    }

    private func parasitologyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those parasites aren't going to identify themselves.",
            "close this and get back to your parasitology work.",
            "helminth identification doesn't happen while you scroll — close this.",
            "your parasitology lab report won't write itself — close this.",
        ]
        case 2: return [
            "no one identifies parasites by scrolling.",
            "close this and open your parasitology notes.",
            "those protozoa won't classify themselves — focus."
        ]
        default: return [
            "CLOSE THIS. open your parasitology textbook.",
            "CLOSE THIS. parasite life cycles won't memorize themselves.",
            "CLOSE THIS. your parasitology exam won't pass itself."
        ]
        }
    }

    private func embryologyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those embryology diagrams aren't going to study themselves.",
            "close this and get back to your embryology work.",
            "germ layers and organogenesis won't review themselves — close this.",
            "your embryology exam is coming and you're here — close this.",
        ]
        case 2: return [
            "no one masters embryology by scrolling.",
            "close this and open your embryology notes.",
            "those developmental stages won't memorize themselves — focus."
        ]
        default: return [
            "CLOSE THIS. open your embryology textbook.",
            "CLOSE THIS. organogenesis doesn't review itself.",
            "CLOSE THIS. your embryology exam won't pass itself."
        ]
        }
    }

    private func histologyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those tissue slides aren't going to identify themselves.",
            "close this and get back to your histology work.",
            "H&E staining patterns won't memorize themselves — close this.",
            "your histology practical is coming and you're here — close this.",
        ]
        case 2: return [
            "no one identifies tissues by scrolling.",
            "close this and open your histology slides.",
            "those epithelial types won't classify themselves — focus."
        ]
        default: return [
            "CLOSE THIS. open your histology notes.",
            "CLOSE THIS. tissue identification doesn't happen while you scroll.",
            "CLOSE THIS. your histology practical won't pass itself."
        ]
        }
    }

    private func pathologyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those pathology slides aren't going to analyze themselves.",
            "close this and get back to your pathology work.",
            "disease mechanisms won't review themselves — close this.",
            "gross and microscopic pathology won't study themselves while you scroll — close this.",
        ]
        case 2: return [
            "no one masters pathology by scrolling.",
            "close this and open your pathology notes.",
            "those disease processes won't learn themselves — focus."
        ]
        default: return [
            "CLOSE THIS. open your pathology textbook.",
            "CLOSE THIS. pathogenesis doesn't review itself.",
            "CLOSE THIS. your pathology exam won't pass itself."
        ]
        }
    }

    private func neuroanatomyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those cranial nerves aren't going to memorize themselves.",
            "close this and get back to your neuroanatomy work.",
            "brain regions and neural pathways won't review themselves — close this.",
            "your neuroanatomy exam is coming and you're scrolling — close this.",
        ]
        case 2: return [
            "no one maps the brain by scrolling.",
            "close this and open your neuroanatomy notes.",
            "those neural tracts won't trace themselves — focus."
        ]
        default: return [
            "CLOSE THIS. open your neuroanatomy textbook.",
            "CLOSE THIS. cranial nerve functions won't memorize themselves.",
            "CLOSE THIS. your neuroanatomy exam won't pass itself."
        ]
        }
    }

    private func chemicalkineticsCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those rate laws aren't going to derive themselves.",
            "close this and get back to your chemical kinetics work.",
            "your Arrhenius problem set won't finish itself — close this.",
            "reaction order doesn't determine itself while you scroll — close this.",
        ]
        case 2: return [
            "no one masters kinetics by scrolling.",
            "close this and open your chemical kinetics notes.",
            "those integrated rate laws won't solve themselves — focus."
        ]
        default: return [
            "CLOSE THIS. open your chemical kinetics textbook.",
            "CLOSE THIS. activation energy problems won't solve themselves.",
            "CLOSE THIS. your kinetics exam won't pass itself."
        ]
        }
    }

    private func computationalchemistryCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those DFT calculations aren't going to run themselves.",
            "close this and get back to your computational chemistry work.",
            "your molecular dynamics simulation won't set up itself — close this.",
            "ab initio methods don't compute while you scroll — close this.",
        ]
        case 2: return [
            "no one masters quantum chemistry by scrolling.",
            "close this and open your computational chemistry assignment.",
            "those GAUSSIAN outputs won't analyze themselves — focus."
        ]
        default: return [
            "CLOSE THIS. open your computational chemistry software.",
            "CLOSE THIS. DFT calculations don't run while you scroll.",
            "CLOSE THIS. your computational chemistry problem set won't finish itself."
        ]
        }
    }

    private func ecologyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those food webs aren't going to diagram themselves.",
            "close this and get back to your ecology work.",
            "trophic levels and community dynamics won't review themselves — close this.",
            "your ecology exam is coming and you're scrolling — close this.",
        ]
        case 2: return [
            "no one masters ecosystems by scrolling.",
            "close this and open your ecology textbook.",
            "those predator-prey models won't analyze themselves — focus."
        ]
        default: return [
            "CLOSE THIS. open your ecology notes.",
            "CLOSE THIS. ecosystem dynamics don't review themselves.",
            "CLOSE THIS. your ecology exam won't pass itself."
        ]
        }
    }

    private func pharmacologyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those drug mechanisms aren't going to memorize themselves.",
            "close this and get back to your pharmacology work.",
            "pharmacokinetics and dose-response curves won't review themselves — close this.",
            "your pharmacology exam is coming and you're here — close this.",
        ]
        case 2: return [
            "no one masters receptor pharmacology by scrolling.",
            "close this and open your pharmacology textbook.",
            "those agonist and antagonist mechanisms won't learn themselves — focus."
        ]
        default: return [
            "CLOSE THIS. open your pharmacology notes.",
            "CLOSE THIS. drug mechanisms don't review themselves.",
            "CLOSE THIS. your pharmacology exam won't pass itself."
        ]
        }
    }

    private func physiologyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those organ systems aren't going to review themselves.",
            "close this and get back to your physiology work.",
            "action potentials and homeostasis won't study themselves — close this.",
            "your physiology exam is coming and you're scrolling — close this.",
        ]
        case 2: return [
            "no one masters organ physiology by scrolling.",
            "close this and open your physiology textbook.",
            "those cardiovascular and renal systems won't review themselves — focus."
        ]
        default: return [
            "CLOSE THIS. open your physiology notes.",
            "CLOSE THIS. organ system functions don't review themselves.",
            "CLOSE THIS. your physiology exam won't pass itself."
        ]
        }
    }

    private func mechanicalengineeringCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "your machine design problems aren't going to solve themselves.",
            "close this and get back to your ME problem set.",
            "dynamics and kinematics won't work themselves out — close this.",
            "your mechanical engineering exam is coming. close this and study."
        ]
        case 2: return [
            "no one passes dynamics by scrolling.",
            "close this and open your ME textbook.",
            "those machine design calculations won't do themselves — focus."
        ]
        default: return [
            "CLOSE THIS. open your mechanics textbook.",
            "CLOSE THIS. dynamics and statics won't study themselves.",
            "CLOSE THIS. your ME exam won't solve itself."
        ]
        }
    }

    private func nuclearengineeringCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those reactor physics equations aren't going to solve themselves.",
            "close this and get back to your nuclear engineering work.",
            "neutron transport and criticality won't study themselves — close this.",
            "your nuclear engineering exam is coming. close this."
        ]
        case 2: return [
            "no one masters reactor physics by scrolling.",
            "close this and open your nuclear engineering textbook.",
            "those criticality calculations won't do themselves — focus."
        ]
        default: return [
            "CLOSE THIS. open your nuclear engineering notes.",
            "CLOSE THIS. reactor physics won't study itself.",
            "CLOSE THIS. your nuclear exam won't pass itself."
        ]
        }
    }

    private func materialstestingCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those test specimens aren't going to analyze themselves.",
            "close this and get back to your materials testing lab.",
            "stress-strain curves won't plot themselves — close this.",
            "your Charpy impact data won't interpret itself. close this."
        ]
        case 2: return [
            "no one passes materials testing by scrolling.",
            "close this and open your lab report.",
            "those tensile test results won't write themselves — focus."
        ]
        default: return [
            "CLOSE THIS. open your materials testing lab report.",
            "CLOSE THIS. your stress-strain curve won't plot itself.",
            "CLOSE THIS. those specimens need your analysis, not your scrolling."
        ]
        }
    }

    private func biomedicalengineeringCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "your biomechanics problem set isn't going to solve itself.",
            "close this and get back to your BME work.",
            "medical device design won't happen while you're scrolling — close this.",
            "your biomedical engineering exam is coming. close this and study."
        ]
        case 2: return [
            "no one passes biomechanics by scrolling.",
            "close this and open your BME textbook.",
            "those bioinstrumentation problems won't solve themselves — focus."
        ]
        default: return [
            "CLOSE THIS. open your biomedical engineering notes.",
            "CLOSE THIS. biomaterials and biomechanics won't study themselves.",
            "CLOSE THIS. your BME exam won't pass itself."
        ]
        }
    }

    private func chemicalengineeringCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those transport phenomena problems aren't going to solve themselves.",
            "close this and get back to your ChE problem set.",
            "unit operations and mass transfer won't work themselves out — close this.",
            "your chemical engineering exam is coming. close this and study."
        ]
        case 2: return [
            "no one masters transport phenomena by scrolling.",
            "close this and open your ChE textbook.",
            "those heat and mass transfer calculations won't do themselves — focus."
        ]
        default: return [
            "CLOSE THIS. open your chemical engineering textbook.",
            "CLOSE THIS. transport phenomena won't study itself.",
            "CLOSE THIS. your ChE exam won't pass itself."
        ]
        }
    }

    private func oceanographyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those ocean circulation problems aren't going to solve themselves.",
            "close this and get back to your oceanography work.",
            "thermohaline circulation won't study itself — close this.",
            "your oceanography exam is coming. close this and study."
        ]
        case 2: return [
            "no one masters ocean dynamics by scrolling.",
            "close this and open your oceanography textbook.",
            "those ocean current equations won't work themselves out — focus."
        ]
        default: return [
            "CLOSE THIS. open your oceanography notes.",
            "CLOSE THIS. physical oceanography won't study itself.",
            "CLOSE THIS. your oceanography exam won't pass itself."
        ]
        }
    }

    private func geochemistryCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those trace-element analyses aren't going to run themselves.",
            "close this and get back to your geochemistry work.",
            "isotope geochemistry won't study itself — close this.",
            "your geochemistry exam is coming. close this."
        ]
        case 2: return [
            "no one masters isotope ratios by scrolling.",
            "close this and open your geochemistry textbook.",
            "those geochemical calculations won't do themselves — focus."
        ]
        default: return [
            "CLOSE THIS. open your geochemistry lab notes.",
            "CLOSE THIS. isotope geochemistry won't study itself.",
            "CLOSE THIS. your geochemistry exam won't pass itself."
        ]
        }
    }

    private func thermodynamicsCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those Rankine cycle problems aren't going to solve themselves.",
            "close this and get back to your thermodynamics work.",
            "entropy and enthalpy won't review themselves — close this.",
            "your thermodynamics exam is coming. close this and study."
        ]
        case 2: return [
            "no one passes thermodynamics by scrolling.",
            "close this and open your thermo textbook.",
            "those steam-table calculations won't do themselves — focus."
        ]
        default: return [
            "CLOSE THIS. open your thermodynamics notes.",
            "CLOSE THIS. Carnot and Rankine cycles won't study themselves.",
            "CLOSE THIS. your thermo exam won't pass itself."
        ]
        }
    }

    private func radiologyrotationCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those radiology cases aren't going to read themselves.",
            "close this and get back to your radiology reading.",
            "those images need your interpretation — close this.",
            "your attending is waiting. close this and get back to radiology."
        ]
        case 2: return [
            "no one learns image interpretation by scrolling.",
            "close this and open your PACS cases.",
            "those radiographs won't read themselves — focus."
        ]
        default: return [
            "CLOSE THIS. open your radiology cases.",
            "CLOSE THIS. those images need your interpretation.",
            "CLOSE THIS. your radiology reading isn't going to do itself."
        ]
        }
    }

    private func anesthesiologyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those anesthesia concepts aren't going to study themselves.",
            "close this and get back to your anesthesiology work.",
            "volatile anesthetics and MAC won't review themselves — close this.",
            "your anesthesiology exam is coming. close this and study."
        ]
        case 2: return [
            "no one masters anesthetic pharmacology by scrolling.",
            "close this and open your anesthesiology notes.",
            "those airway management concepts won't review themselves — focus."
        ]
        default: return [
            "CLOSE THIS. open your anesthesiology textbook.",
            "CLOSE THIS. anesthetic pharmacology won't study itself.",
            "CLOSE THIS. your anesthesiology exam won't pass itself."
        ]
        }
    }

    private func structuralbiologyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those protein structures aren't going to determine themselves.",
            "close this and get back to your structural biology work.",
            "cryo-EM data won't analyze itself — close this.",
            "your protein structure project is waiting. close this."
        ]
        case 2: return [
            "no one resolves protein structures by scrolling.",
            "close this and open your structural biology data.",
            "those PDB models won't build themselves — focus."
        ]
        default: return [
            "CLOSE THIS. open your structural biology tools.",
            "CLOSE THIS. cryo-EM and X-ray data won't analyze themselves.",
            "CLOSE THIS. protein structure determination won't do itself."
        ]
        }
    }

    private func biochemistrylabCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those biochemistry lab results aren't going to write themselves.",
            "close this and get back to your biochemistry lab.",
            "your SDS-PAGE gel isn't going to interpret itself — close this.",
            "your biochemistry lab report is waiting. close this."
        ]
        case 2: return [
            "no one passes biochemistry lab by scrolling.",
            "close this and open your lab notebook.",
            "those enzyme kinetics results won't analyze themselves — focus."
        ]
        default: return [
            "CLOSE THIS. open your biochemistry lab notebook.",
            "CLOSE THIS. your lab data won't analyze itself.",
            "CLOSE THIS. your biochemistry lab report won't write itself."
        ]
        }
    }

    private func clinicalneurologyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those neurology cases aren't going to read themselves.",
            "close this and get back to your neuro rotation work.",
            "your attending is waiting — close this and get back to rounds.",
            "your neurology cases need your focus. close this."
        ]
        case 2: return [
            "no one becomes a neurologist by scrolling.",
            "close this and get back to your neurology notes.",
            "those neuro cases won't review themselves — focus."
        ]
        default: return [
            "CLOSE THIS. open your neurology case notes.",
            "CLOSE THIS. those neuro cases need your full attention.",
            "CLOSE THIS. your neurology rotation won't study itself."
        ]
        }
    }

    private func dermatologyrotationCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those skin lesions aren't going to classify themselves.",
            "close this and get back to your derm rotation.",
            "your derm attending is waiting — close this.",
            "those dermatology cases need your focus. close this."
        ]
        case 2: return [
            "no one learns dermoscopy by scrolling.",
            "close this and open your derm case notes.",
            "those biopsy results won't interpret themselves — focus."
        ]
        default: return [
            "CLOSE THIS. open your dermatology case notes.",
            "CLOSE THIS. those skin lesions need your interpretation.",
            "CLOSE THIS. your derm rotation won't study itself."
        ]
        }
    }

    private func psychiatryrotationCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those psychiatric cases aren't going to formulate themselves.",
            "close this and get back to your psychiatry rotation.",
            "your psych attending is waiting — close this.",
            "those psychiatry notes need your focus. close this."
        ]
        case 2: return [
            "no one masters the DSM-5 by scrolling.",
            "close this and open your psychiatry case notes.",
            "that psychiatric formulation won't write itself — focus."
        ]
        default: return [
            "CLOSE THIS. open your psychiatry case notes.",
            "CLOSE THIS. those psychiatric formulations need your attention.",
            "CLOSE THIS. your psychiatry rotation won't study itself."
        ]
        }
    }

    private func surgeryrotationCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those operative notes aren't going to write themselves.",
            "close this and get back to your surgery rotation.",
            "your surgery attending is watching — close this.",
            "those surgical cases need your full attention. close this."
        ]
        case 2: return [
            "no one becomes a surgeon by scrolling.",
            "close this and open your surgical notes.",
            "that operative report won't write itself — focus."
        ]
        default: return [
            "CLOSE THIS. open your surgical notes.",
            "CLOSE THIS. those operative reports need your attention.",
            "CLOSE THIS. your surgery rotation won't study itself."
        ]
        }
    }

    private func pediatricsrotationCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those pediatric cases aren't going to write themselves.",
            "close this and get back to your peds rotation.",
            "your peds attending is waiting — close this.",
            "those pediatric notes need your focus. close this."
        ]
        case 2: return [
            "no one masters developmental milestones by scrolling.",
            "close this and open your pediatrics case notes.",
            "that peds case won't present itself — focus."
        ]
        default: return [
            "CLOSE THIS. open your pediatrics case notes.",
            "CLOSE THIS. those peds cases need your attention.",
            "CLOSE THIS. your pediatrics rotation won't study itself."
        ]
        }
    }

    private func internalMedicineCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that H&P isn't going to write itself.",
            "close this and get back to your medicine rotation.",
            "your medicine attending is waiting — close this.",
            "those SOAP notes need your focus. close this."
        ]
        case 2: return [
            "no one passes the medicine shelf by scrolling.",
            "close this and open your internal medicine notes.",
            "that H&P won't write itself — focus."
        ]
        default: return [
            "CLOSE THIS. open your internal medicine notes.",
            "CLOSE THIS. that H&P needs to be written.",
            "CLOSE THIS. your medicine rotation won't study itself."
        ]
        }
    }

    private func obgynrotationCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those OB/GYN notes aren't going to write themselves.",
            "close this and get back to your OB/GYN rotation.",
            "your attending is waiting on those L&D notes — close this.",
            "those gynecology cases need your focus. close this."
        ]
        case 2: return [
            "no one masters labor and delivery by scrolling.",
            "close this and open your OB/GYN case notes.",
            "those obstetrics notes won't write themselves — focus."
        ]
        default: return [
            "CLOSE THIS. open your OB/GYN rotation notes.",
            "CLOSE THIS. those L&D cases need your attention.",
            "CLOSE THIS. your OB/GYN rotation won't study itself."
        ]
        }
    }

    private func familymedicineCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those family medicine notes aren't going to write themselves.",
            "close this and get back to your FM rotation.",
            "your family medicine attending is waiting — close this.",
            "those continuity clinic notes need your focus. close this."
        ]
        case 2: return [
            "no one passes the FM shelf by scrolling.",
            "close this and open your family medicine notes.",
            "that clinic note won't write itself — focus."
        ]
        default: return [
            "CLOSE THIS. open your family medicine rotation notes.",
            "CLOSE THIS. those clinic notes need to be written.",
            "CLOSE THIS. your FM rotation won't study itself."
        ]
        }
    }

    private func emergencymedicinerotationCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those shift notes aren't going to write themselves.",
            "close this and get back to your EM rotation.",
            "your EM attending is waiting — close this.",
            "those emergency medicine cases need your focus. close this."
        ]
        case 2: return [
            "no one becomes an EM physician by scrolling.",
            "close this and open your EM shift notes.",
            "that emergency case won't present itself — focus."
        ]
        default: return [
            "CLOSE THIS. open your emergency medicine notes.",
            "CLOSE THIS. those shift notes need to be written.",
            "CLOSE THIS. your EM rotation won't study itself."
        ]
        }
    }

    private func virologyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those viral replication cycles aren't going to memorize themselves.",
            "close this and get back to your virology.",
            "those viral pathogens won't learn themselves. close this.",
            "your virology exam is waiting. close this."
        ]
        case 2: return [
            "no one masters virology by scrolling.",
            "close this and open your virology notes.",
            "those viral pathogenesis mechanisms won't memorize themselves — focus."
        ]
        default: return [
            "CLOSE THIS. open your virology textbook.",
            "CLOSE THIS. those viral life cycles need your attention.",
            "CLOSE THIS. your virology exam won't study itself."
        ]
        }
    }

    private func clinicalmicrobiologyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those culture results aren't going to interpret themselves.",
            "close this and get back to your microbiology lab.",
            "that antibiogram won't read itself. close this.",
            "those cultures need your attention. close this."
        ]
        case 2: return [
            "no one masters clinical microbiology by scrolling.",
            "close this and open your culture results.",
            "that antibiogram interpretation won't do itself — focus."
        ]
        default: return [
            "CLOSE THIS. open your clinical microbiology lab.",
            "CLOSE THIS. those culture results need interpretation.",
            "CLOSE THIS. your clinical microbiology work won't do itself."
        ]
        }
    }

    private func medicinalchemistryCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those SAR analyses aren't going to write themselves.",
            "close this and get back to your medicinal chemistry.",
            "your drug design problem isn't going to solve itself. close this.",
            "those lead compounds won't optimize themselves. close this."
        ]
        case 2: return [
            "no one designs drugs by scrolling.",
            "close this and open your medicinal chemistry notes.",
            "that lead optimization won't do itself — focus."
        ]
        default: return [
            "CLOSE THIS. open your medicinal chemistry textbook.",
            "CLOSE THIS. those SAR analyses need your attention.",
            "CLOSE THIS. your drug design work won't do itself."
        ]
        }
    }

    private func cellandmolecularbiologyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those cell biology problems aren't going to solve themselves.",
            "close this and get back to your cell biology.",
            "those organelles won't study themselves. close this.",
            "your cell biology exam is waiting. close this."
        ]
        case 2: return [
            "no one masters cell biology by scrolling.",
            "close this and open your cell biology notes.",
            "that cell cycle diagram won't learn itself — focus."
        ]
        default: return [
            "CLOSE THIS. open your cell biology textbook.",
            "CLOSE THIS. those cell division mechanisms need your attention.",
            "CLOSE THIS. your cell biology exam won't study itself."
        ]
        }
    }

    private func biochemistry2Callouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those signal transduction pathways aren't going to study themselves.",
            "close this and get back to your advanced biochemistry.",
            "your lipid metabolism problem isn't going to solve itself. close this.",
            "those nucleotide pathways won't memorize themselves. close this."
        ]
        case 2: return [
            "no one masters signal transduction by scrolling.",
            "close this and open your biochemistry notes.",
            "that phosphorylation cascade won't learn itself — focus."
        ]
        default: return [
            "CLOSE THIS. open your advanced biochemistry textbook.",
            "CLOSE THIS. those lipid metabolism pathways need your attention.",
            "CLOSE THIS. your advanced biochemistry exam won't study itself."
        ]
        }
    }

    private func physicalchemistryLabCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that pchem lab report isn't going to write itself.",
            "close this and get back to your physical chemistry lab.",
            "your spectroscopy data won't analyze itself. close this.",
            "that calorimetry lab won't finish itself. close this."
        ]
        case 2: return [
            "no one masters pchem lab work by scrolling.",
            "close this and open your physical chemistry lab notebook.",
            "that spectroscopy experiment won't document itself — focus."
        ]
        default: return [
            "CLOSE THIS. open your pchem lab notebook.",
            "CLOSE THIS. that calorimetry data needs analysis.",
            "CLOSE THIS. your physical chemistry lab work won't do itself."
        ]
        }
    }

    private func organicchemistrylabCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that orgo lab report isn't going to write itself.",
            "close this and get back to your organic chemistry lab.",
            "your recrystallization data won't analyze itself. close this.",
            "that TLC plate won't document itself. close this."
        ]
        case 2: return [
            "no one passes orgo lab by scrolling.",
            "close this and open your organic chemistry lab notebook.",
            "that distillation report won't write itself — focus."
        ]
        default: return [
            "CLOSE THIS. open your orgo lab notebook.",
            "CLOSE THIS. that IR spectrum needs interpretation.",
            "CLOSE THIS. your organic chemistry lab work won't do itself."
        ]
        }
    }

    private func immunologycourseCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those immunotherapy mechanisms aren't going to study themselves.",
            "close this and get back to your immunology.",
            "that complement cascade won't memorize itself. close this.",
            "those T-reg cell pathways won't study themselves. close this."
        ]
        case 2: return [
            "no one masters advanced immunology by scrolling.",
            "close this and open your immunology notes.",
            "that checkpoint inhibitor mechanism won't study itself — focus."
        ]
        default: return [
            "CLOSE THIS. open your advanced immunology textbook.",
            "CLOSE THIS. those complement pathways need your attention.",
            "CLOSE THIS. your immunology exam won't study itself."
        ]
        }
    }

    private func neurobiologylabCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that neurobiology lab report isn't going to write itself.",
            "close this and get back to your neurobiology lab.",
            "your patch clamp data won't analyze itself. close this.",
            "that neural tracing experiment won't document itself. close this."
        ]
        case 2: return [
            "no one masters neurobiology lab work by scrolling.",
            "close this and open your neurobiology lab notebook.",
            "that patch clamp recording won't write itself — focus."
        ]
        default: return [
            "CLOSE THIS. open your neurobiology lab notebook.",
            "CLOSE THIS. that patch clamp data needs analysis.",
            "CLOSE THIS. your neurobiology lab work won't do itself."
        ]
        }
    }

    private func astronomylabCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those star charts aren't going to plot themselves.",
            "close this and get back to your observational astronomy lab.",
            "your telescope data won't analyze itself. close this.",
            "those astronomical calculations won't do themselves. close this."
        ]
        case 2: return [
            "no one learns observational astronomy by scrolling.",
            "close this and open your astronomy lab notebook.",
            "that stellar spectrum won't analyze itself — focus."
        ]
        default: return [
            "CLOSE THIS. open your astronomy lab notebook.",
            "CLOSE THIS. those light curves need analysis.",
            "CLOSE THIS. your observational astronomy lab won't do itself."
        ]
        }
    }

    private func geologylabCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that geology lab report isn't going to write itself.",
            "close this and get back to your geology lab.",
            "those rock samples won't identify themselves. close this.",
            "that thin section won't analyze itself. close this."
        ]
        case 2: return [
            "no one passes geology lab by scrolling.",
            "close this and open your geology lab notebook.",
            "those rock specimens need your attention — focus."
        ]
        default: return [
            "CLOSE THIS. open your geology lab notebook.",
            "CLOSE THIS. those thin sections need analysis.",
            "CLOSE THIS. your geology field report won't write itself."
        ]
        }
    }

    private func environmentalscienceCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those earth systems problems aren't going to solve themselves.",
            "close this and get back to your environmental science.",
            "your biogeochemical cycle notes won't write themselves. close this.",
            "that environmental data won't analyze itself. close this."
        ]
        case 2: return [
            "no one masters environmental science by scrolling.",
            "close this and open your environmental science notes.",
            "that carbon cycle diagram won't study itself — focus."
        ]
        default: return [
            "CLOSE THIS. open your environmental science textbook.",
            "CLOSE THIS. those earth systems concepts need your attention.",
            "CLOSE THIS. your environmental science exam won't study itself."
        ]
        }
    }

    private func anthropologyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that ethnography isn't going to write itself.",
            "close this and get back to your anthropology.",
            "those kinship systems won't memorize themselves. close this.",
            "that field observation report won't write itself. close this."
        ]
        case 2: return [
            "no one masters anthropology by scrolling.",
            "close this and open your anthropology notes.",
            "that cultural analysis won't write itself — focus."
        ]
        default: return [
            "CLOSE THIS. open your anthropology textbook.",
            "CLOSE THIS. those ethnographic field notes need your attention.",
            "CLOSE THIS. your anthropology exam won't study itself."
        ]
        }
    }

    private func sociologyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that sociological analysis isn't going to write itself.",
            "close this and get back to your sociology.",
            "those social theory frameworks won't memorize themselves. close this.",
            "that sociology paper won't write itself. close this."
        ]
        case 2: return [
            "no one masters sociology by scrolling.",
            "close this and open your sociology notes.",
            "that structural functionalism essay won't write itself — focus."
        ]
        default: return [
            "CLOSE THIS. open your sociology textbook.",
            "CLOSE THIS. those social theory concepts need your attention.",
            "CLOSE THIS. your sociology exam won't study itself."
        ]
        }
    }

    private func biostatisticsCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those survival curves aren't going to analyze themselves.",
            "close this and get back to your biostatistics.",
            "that Kaplan-Meier plot won't interpret itself. close this.",
            "your biostatistics problem set won't do itself. close this."
        ]
        case 2: return [
            "no one masters biostatistics by scrolling.",
            "close this and open your biostatistics textbook.",
            "that Cox regression won't run itself — focus."
        ]
        default: return [
            "CLOSE THIS. open your biostatistics notes.",
            "CLOSE THIS. those survival curves need your analysis.",
            "CLOSE THIS. your biostatistics exam won't study itself."
        ]
        }
    }

    private func marinebiology2Callouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those plankton samples aren't going to identify themselves.",
            "close this and get back to your marine biology lab.",
            "your tidepool field data won't write itself. close this.",
            "that marine organism won't dissect itself. close this."
        ]
        case 2: return [
            "no one learns marine biology lab work by scrolling.",
            "close this and open your marine biology lab notebook.",
            "those ocean samples need analysis — focus."
        ]
        default: return [
            "CLOSE THIS. open your marine biology lab notebook.",
            "CLOSE THIS. those plankton samples need identification.",
            "CLOSE THIS. your tidepool field report won't write itself."
        ]
        }
    }

    private func moleculargeneticslabCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those restriction fragments aren't going to map themselves.",
            "close this and get back to your molecular genetics lab.",
            "that karyotype won't analyze itself. close this.",
            "your DNA fingerprint results won't interpret themselves. close this."
        ]
        case 2: return [
            "no one masters molecular genetics lab by scrolling.",
            "close this and open your molecular genetics lab notebook.",
            "that restriction map won't draw itself — focus."
        ]
        default: return [
            "CLOSE THIS. open your molecular genetics lab report.",
            "CLOSE THIS. those restriction fragments need mapping.",
            "CLOSE THIS. your karyotype analysis won't do itself."
        ]
        }
    }

    private func evolutionarybiologyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that phylogenetic tree isn't going to build itself.",
            "close this and get back to your evolutionary biology.",
            "those speciation mechanisms won't memorize themselves. close this.",
            "your evolutionary biology exam won't study itself. close this."
        ]
        case 2: return [
            "no one masters evolutionary biology by scrolling.",
            "close this and open your evolutionary biology textbook.",
            "that phylogeny won't reconstruct itself — focus."
        ]
        default: return [
            "CLOSE THIS. open your evolutionary biology notes.",
            "CLOSE THIS. those phylogenetic trees need your analysis.",
            "CLOSE THIS. your evolution exam won't study itself."
        ]
        }
    }

    private func biochemistry3Callouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those cofactor pathways aren't going to memorize themselves.",
            "close this and get back to your biochemistry.",
            "that heme biosynthesis pathway won't study itself. close this.",
            "those vitamin coenzyme mechanisms won't review themselves. close this."
        ]
        case 2: return [
            "no one masters cofactor biochemistry by scrolling.",
            "close this and open your advanced biochemistry textbook.",
            "that porphyrin pathway won't memorize itself — focus."
        ]
        default: return [
            "CLOSE THIS. open your biochemistry notes.",
            "CLOSE THIS. those cofactor mechanisms need your attention.",
            "CLOSE THIS. your biochemistry exam won't study itself."
        ]
        }
    }

    private func atmosphericscienceCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those synoptic maps aren't going to analyze themselves.",
            "close this and get back to your atmospheric science.",
            "your weather model won't run itself. close this.",
            "that atmospheric dynamics problem set won't do itself. close this."
        ]
        case 2: return [
            "no one masters atmospheric science by scrolling.",
            "close this and open your meteorology textbook.",
            "those NWP models won't study themselves — focus."
        ]
        default: return [
            "CLOSE THIS. open your atmospheric science notes.",
            "CLOSE THIS. those synoptic charts need your analysis.",
            "CLOSE THIS. your meteorology exam won't study itself."
        ]
        }
    }

    private func ecologicalfieldworkCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those transect data aren't going to analyze themselves.",
            "close this and get back to your field ecology work.",
            "your species richness survey won't write itself. close this.",
            "that mark-recapture analysis won't do itself. close this."
        ]
        case 2: return [
            "no one learns field ecology by scrolling.",
            "close this and open your field ecology lab notebook.",
            "those quadrat samples need analysis — focus."
        ]
        default: return [
            "CLOSE THIS. open your field ecology lab notebook.",
            "CLOSE THIS. those transect data need your analysis.",
            "CLOSE THIS. your biodiversity survey won't write itself."
        ]
        }
    }

    private func quantummechanicsCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that wave function won't solve itself.",
            "close this and get back to your quantum mechanics.",
            "those Schrödinger equations won't work themselves out. close this.",
            "your quantum mechanics problem set won't do itself. close this."
        ]
        case 2: return [
            "no one masters quantum mechanics by scrolling.",
            "close this and open your quantum mechanics textbook.",
            "those wave functions need solving — focus."
        ]
        default: return [
            "CLOSE THIS. open your quantum mechanics notes.",
            "CLOSE THIS. those Hamiltonians won't solve themselves.",
            "CLOSE THIS. your quantum mechanics exam won't study itself."
        ]
        }
    }

    private func solidstatephysicsCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that band structure diagram won't draw itself.",
            "close this and get back to your solid state physics.",
            "those Brillouin zone problems won't solve themselves. close this.",
            "your condensed matter problem set won't do itself. close this."
        ]
        case 2: return [
            "no one masters solid state physics by scrolling.",
            "close this and open your condensed matter textbook.",
            "those crystal lattice problems need solving — focus."
        ]
        default: return [
            "CLOSE THIS. open your solid state physics notes.",
            "CLOSE THIS. those phonon dispersion curves won't plot themselves.",
            "CLOSE THIS. your condensed matter exam won't study itself."
        ]
        }
    }

    private func classicalmechanicsCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that Lagrangian won't set up itself.",
            "close this and get back to your classical mechanics.",
            "those Euler-Lagrange equations won't solve themselves. close this.",
            "your analytical mechanics problem set won't do itself. close this."
        ]
        case 2: return [
            "no one masters classical mechanics by scrolling.",
            "close this and open your mechanics textbook.",
            "those generalized coordinates won't solve themselves — focus."
        ]
        default: return [
            "CLOSE THIS. open your classical mechanics notes.",
            "CLOSE THIS. those rigid body dynamics problems won't solve themselves.",
            "CLOSE THIS. your mechanics exam won't study itself."
        ]
        }
    }

    private func astrophysicsCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those gravitational waves won't analyze themselves.",
            "close this and get back to your astrophysics.",
            "that stellar evolution model won't run itself. close this.",
            "your astrophysics problem set won't do itself. close this."
        ]
        case 2: return [
            "no one masters astrophysics by scrolling.",
            "close this and open your astrophysics textbook.",
            "those cosmological simulations won't run themselves — focus."
        ]
        default: return [
            "CLOSE THIS. open your astrophysics notes.",
            "CLOSE THIS. those N-body simulations won't run themselves.",
            "CLOSE THIS. your astrophysics exam won't study itself."
        ]
        }
    }

    private func atmosphericchemistryCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that ozone depletion mechanism won't write itself.",
            "close this and get back to your atmospheric chemistry.",
            "those aerosol reactions won't analyze themselves. close this.",
            "your atmospheric chemistry research won't do itself. close this."
        ]
        case 2: return [
            "no one masters atmospheric chemistry by scrolling.",
            "close this and open your atmospheric chemistry notes.",
            "those tropospheric reactions need your analysis — focus."
        ]
        default: return [
            "CLOSE THIS. open your atmospheric chemistry research.",
            "CLOSE THIS. those OH radical reactions won't model themselves.",
            "CLOSE THIS. your atmospheric chemistry analysis won't write itself."
        ]
        }
    }

    private func opticsCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those wave equations won't solve themselves.",
            "close this and get back to your optics.",
            "that diffraction problem won't do itself. close this.",
            "your optics problem set won't solve itself. close this."
        ]
        case 2: return [
            "no one masters optics by scrolling.",
            "close this and open your optics textbook.",
            "those interference patterns won't calculate themselves — focus."
        ]
        default: return [
            "CLOSE THIS. open your optics notes.",
            "CLOSE THIS. those lens equations won't solve themselves.",
            "CLOSE THIS. your optics exam won't study itself."
        ]
        }
    }

    private func electromagnetismCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those Maxwell's equations won't solve themselves.",
            "close this and get back to your E&M.",
            "that Gauss's law problem won't do itself. close this.",
            "your electromagnetism problem set won't solve itself. close this."
        ]
        case 2: return [
            "no one masters electromagnetism by scrolling.",
            "close this and open your E&M textbook.",
            "those field equations need solving — focus."
        ]
        default: return [
            "CLOSE THIS. open your electromagnetism notes.",
            "CLOSE THIS. those Maxwell's equations won't solve themselves.",
            "CLOSE THIS. your E&M exam won't study itself."
        ]
        }
    }

    private func neuroimagingCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that fMRI pipeline won't run itself.",
            "close this and get back to your neuroimaging.",
            "those brain scans won't analyze themselves. close this.",
            "your neuroimaging analysis won't do itself. close this."
        ]
        case 2: return [
            "no one masters neuroimaging by scrolling.",
            "close this and open your neuroimaging pipeline.",
            "that connectome won't map itself — focus."
        ]
        default: return [
            "CLOSE THIS. open your neuroimaging analysis.",
            "CLOSE THIS. those fMRI images won't preprocess themselves.",
            "CLOSE THIS. your brain imaging project won't finish itself."
        ]
        }
    }

    private func geophysicsCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that seismic section won't interpret itself.",
            "close this and get back to your geophysics.",
            "those gravity anomalies won't model themselves. close this.",
            "your geophysics problem set won't do itself. close this."
        ]
        case 2: return [
            "no one masters geophysics by scrolling.",
            "close this and open your geophysics textbook.",
            "those seismic profiles need your analysis — focus."
        ]
        default: return [
            "CLOSE THIS. open your geophysics notes.",
            "CLOSE THIS. those seismic waves won't model themselves.",
            "CLOSE THIS. your geophysics exam won't study itself."
        ]
        }
    }

    private func mineralogyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those minerals won't identify themselves.",
            "close this and get back to your mineralogy.",
            "that crystal system chart won't study itself. close this.",
            "your mineralogy exam won't pass itself. close this."
        ]
        case 2: return [
            "no one masters mineralogy by scrolling.",
            "close this and open your mineralogy textbook.",
            "those crystal properties need memorizing — focus."
        ]
        default: return [
            "CLOSE THIS. open your mineralogy notes.",
            "CLOSE THIS. those mineral properties won't learn themselves.",
            "CLOSE THIS. your mineralogy exam won't study itself."
        ]
        }
    }

    private func petrologyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that rock classification won't do itself.",
            "close this and get back to your petrology.",
            "those thin sections won't describe themselves. close this.",
            "your petrology problem set won't do itself. close this."
        ]
        case 2: return [
            "no one masters petrology by scrolling.",
            "close this and open your petrology textbook.",
            "those igneous and metamorphic rocks need your analysis — focus."
        ]
        default: return [
            "CLOSE THIS. open your petrology notes.",
            "CLOSE THIS. those petrographic descriptions won't write themselves.",
            "CLOSE THIS. your petrology exam won't study itself."
        ]
        }
    }

    private func hydrogeologyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that groundwater model won't run itself.",
            "close this and get back to your hydrogeology.",
            "those aquifer tests won't analyze themselves. close this.",
            "your hydrogeology problem set won't do itself. close this."
        ]
        case 2: return [
            "no one masters hydrogeology by scrolling.",
            "close this and open your hydrogeology textbook.",
            "those pumping tests need analysis — focus."
        ]
        default: return [
            "CLOSE THIS. open your hydrogeology notes.",
            "CLOSE THIS. those Darcy flow equations won't solve themselves.",
            "CLOSE THIS. your hydrogeology exam won't study itself."
        ]
        }
    }

    private func stratigraphyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that stratigraphic column won't draw itself.",
            "close this and get back to your stratigraphy.",
            "those unconformities won't map themselves. close this.",
            "your stratigraphy problem set won't do itself. close this."
        ]
        case 2: return [
            "no one masters stratigraphy by scrolling.",
            "close this and open your stratigraphy textbook.",
            "that sequence stratigraphy won't interpret itself — focus."
        ]
        default: return [
            "CLOSE THIS. open your stratigraphy notes.",
            "CLOSE THIS. those stratigraphic sections won't correlate themselves.",
            "CLOSE THIS. your stratigraphy exam won't study itself."
        ]
        }
    }

    private func systemsbiologyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that metabolic network model won't build itself.",
            "close this and get back to your systems biology.",
            "those flux balance calculations won't run themselves. close this.",
            "your systems biology assignment won't do itself. close this."
        ]
        case 2: return [
            "no one masters systems biology by scrolling.",
            "close this and open your systems biology notes.",
            "that gene regulatory network won't model itself — focus."
        ]
        default: return [
            "CLOSE THIS. open your systems biology textbook.",
            "CLOSE THIS. those genome-scale models won't run themselves.",
            "CLOSE THIS. your systems biology exam won't study itself."
        ]
        }
    }

    private func microbiologylabCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those plates won't count themselves.",
            "close this and get back to your microbiology lab.",
            "that unknown bacteria won't identify itself. close this.",
            "your microbiology lab report won't write itself. close this."
        ]
        case 2: return [
            "no one aces microbiology lab by scrolling.",
            "close this and open your microbiology lab notebook.",
            "those CFU counts need your attention — focus."
        ]
        default: return [
            "CLOSE THIS. open your microbiology lab manual.",
            "CLOSE THIS. that disk diffusion result won't interpret itself.",
            "CLOSE THIS. your microbiology lab practical won't study itself."
        ]
        }
    }

    private func ecophysiologyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those thermal performance curves won't analyze themselves.",
            "close this and get back to your ecophysiology.",
            "that metabolic rate data won't write up itself. close this.",
            "your ecophysiology assignment won't do itself. close this."
        ]
        case 2: return [
            "no one masters ecophysiology by scrolling.",
            "close this and open your ecophysiology notes.",
            "those osmoregulation mechanisms need reviewing — focus."
        ]
        default: return [
            "CLOSE THIS. open your ecophysiology textbook.",
            "CLOSE THIS. those physiological ecology problems won't solve themselves.",
            "CLOSE THIS. your ecophysiology exam won't study itself."
        ]
        }
    }

    private func plantphysiologyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those phytohormone pathways won't memorize themselves.",
            "close this and get back to your plant physiology.",
            "that stomatal conductance problem won't do itself. close this.",
            "your plant physiology exam won't study itself. close this."
        ]
        case 2: return [
            "no one masters plant physiology by scrolling.",
            "close this and open your plant physiology textbook.",
            "that xylem transport problem needs your focus — now."
        ]
        default: return [
            "CLOSE THIS. open your plant physiology notes.",
            "CLOSE THIS. those phloem loading mechanisms won't explain themselves.",
            "CLOSE THIS. your plant physiology exam won't study itself."
        ]
        }
    }

    private func cellsignalingCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those signaling cascades won't map themselves.",
            "close this and get back to your cell signaling work.",
            "that MAPK pathway problem won't solve itself. close this.",
            "your cell signaling exam won't study itself. close this."
        ]
        case 2: return [
            "no one masters cell signaling by scrolling.",
            "close this and open your cell signaling textbook.",
            "those receptor tyrosine kinase pathways need reviewing — focus."
        ]
        default: return [
            "CLOSE THIS. open your cell signaling notes.",
            "CLOSE THIS. those kinase cascades won't diagram themselves.",
            "CLOSE THIS. your cell signaling exam won't study itself."
        ]
        }
    }

    private func humangeneticsclassCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those pedigree charts won't draw themselves.",
            "close this and get back to your human genetics work.",
            "that chromosomal disorder problem won't do itself. close this.",
            "your human genetics exam won't study itself. close this."
        ]
        case 2: return [
            "no one masters human genetics by scrolling.",
            "close this and open your human genetics textbook.",
            "those pedigree analysis problems need your focus — now."
        ]
        default: return [
            "CLOSE THIS. open your human genetics notes.",
            "CLOSE THIS. those chromosomal disorder cases won't analyze themselves.",
            "CLOSE THIS. your human genetics exam won't study itself."
        ]
        }
    }

    private func immunogeneticsCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those HLA haplotypes won't memorize themselves.",
            "close this and get back to your immunogenetics work.",
            "that transplant immunology problem won't do itself. close this.",
            "your immunogenetics exam won't study itself. close this."
        ]
        case 2: return [
            "no one masters immunogenetics by scrolling.",
            "close this and open your immunogenetics textbook.",
            "those MHC class I and II pathways need reviewing — focus."
        ]
        default: return [
            "CLOSE THIS. open your immunogenetics notes.",
            "CLOSE THIS. those HLA typing concepts won't review themselves.",
            "CLOSE THIS. your immunogenetics exam won't study itself."
        ]
        }
    }

    private func neurologylabCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that nerve conduction study won't write itself.",
            "close this and get back to your neurology lab work.",
            "those EEG lab results won't analyze themselves. close this.",
            "your neurology lab report won't write itself. close this."
        ]
        case 2: return [
            "no one aces neurology lab by scrolling.",
            "close this and open your neurology lab notebook.",
            "that cranial nerve examination needs your practice — focus."
        ]
        default: return [
            "CLOSE THIS. open your neurology lab manual.",
            "CLOSE THIS. those nerve conduction results won't interpret themselves.",
            "CLOSE THIS. your neurology lab practical won't study itself."
        ]
        }
    }

    private func socialpsychologyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those social cognition theories won't study themselves.",
            "close this and get back to your social psychology work.",
            "that attribution theory problem won't do itself. close this.",
            "your social psychology exam won't study itself. close this."
        ]
        case 2: return [
            "no one masters social psychology by scrolling.",
            "close this and open your social psychology textbook.",
            "those attitude change and persuasion concepts need reviewing — focus."
        ]
        default: return [
            "CLOSE THIS. open your social psychology notes.",
            "CLOSE THIS. those group dynamics theories won't memorize themselves.",
            "CLOSE THIS. your social psychology exam won't study itself."
        ]
        }
    }

    private func animalphysiologyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those osmoregulation mechanisms won't write themselves.",
            "close this and get back to your animal physiology.",
            "that countercurrent exchange problem won't do itself. close this.",
            "your animal physiology exam won't study itself. close this."
        ]
        case 2: return [
            "no one masters animal physiology by scrolling.",
            "close this and open your animal physiology textbook.",
            "those thermoregulation pathways need reviewing — focus."
        ]
        default: return [
            "CLOSE THIS. open your animal physiology notes.",
            "CLOSE THIS. those comparative physiology problems won't solve themselves.",
            "CLOSE THIS. your animal physiology exam won't study itself."
        ]
        }
    }

    private func geriatricrotationCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that geriatric assessment won't write itself.",
            "close this and get back to your geriatric rotation work.",
            "that CGA write-up won't finish itself. close this.",
            "your geriatric patients need your notes, not this."
        ]
        case 2: return [
            "no one aces geriatrics by scrolling.",
            "close this and open your geriatric rotation notes.",
            "that polypharmacy review needs your attention — focus."
        ]
        default: return [
            "CLOSE THIS. open your geriatric rotation notes.",
            "CLOSE THIS. that frailty assessment won't document itself.",
            "CLOSE THIS. your geriatric rotation write-up won't finish itself."
        ]
        }
    }

    private func neurochemistryCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those neurotransmitter pathways won't map themselves.",
            "close this and get back to your neurochemistry.",
            "that monoamine synthesis pathway won't trace itself. close this.",
            "your neurochemistry exam won't study itself. close this."
        ]
        case 2: return [
            "no one masters neurochemistry by scrolling.",
            "close this and open your neurochemistry notes.",
            "those synaptic vesicle cycling steps need reviewing — focus."
        ]
        default: return [
            "CLOSE THIS. open your neurochemistry notes.",
            "CLOSE THIS. those catecholamine pathways won't map themselves.",
            "CLOSE THIS. your neurochemistry exam won't study itself."
        ]
        }
    }

    private func psychobiologyclassCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those brain-behavior mechanisms won't map themselves.",
            "close this and get back to your biopsychology work.",
            "that hemispheric lateralization chart won't draw itself. close this.",
            "your biopsychology exam won't study itself. close this."
        ]
        case 2: return [
            "no one masters biopsychology by scrolling.",
            "close this and open your biopsychology notes.",
            "those hormones-and-behavior pathways need reviewing — focus."
        ]
        default: return [
            "CLOSE THIS. open your biopsychology notes.",
            "CLOSE THIS. those brain-behavior links won't memorize themselves.",
            "CLOSE THIS. your biological psychology exam won't study itself."
        ]
        }
    }

    private func abnormalpsychologyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those DSM criteria won't memorize themselves.",
            "close this and get back to your abnormal psychology work.",
            "that case conceptualization won't write itself. close this.",
            "your abnormal psychology exam won't study itself. close this."
        ]
        case 2: return [
            "no one masters abnormal psychology by scrolling.",
            "close this and open your abnormal psychology textbook.",
            "those disorder criteria and differential diagnoses need reviewing — focus."
        ]
        default: return [
            "CLOSE THIS. open your abnormal psychology notes.",
            "CLOSE THIS. those DSM criteria won't memorize themselves.",
            "CLOSE THIS. your abnormal psychology exam won't study itself."
        ]
        }
    }

    private func healthpsychologyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that biopsychosocial case study won't write itself.",
            "close this and get back to your health psychology work.",
            "those stress-and-health frameworks won't review themselves. close this.",
            "your health psychology exam won't study itself. close this."
        ]
        case 2: return [
            "no one masters health psychology by scrolling.",
            "close this and open your health psychology textbook.",
            "those illness behavior and coping models need reviewing — focus."
        ]
        default: return [
            "CLOSE THIS. open your health psychology notes.",
            "CLOSE THIS. those biopsychosocial case studies won't write themselves.",
            "CLOSE THIS. your health psychology exam won't study itself."
        ]
        }
    }

    private func linearalgebraCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those eigenvectors won't find themselves.",
            "close this and get back to your linear algebra.",
            "that matrix decomposition problem won't solve itself. close this.",
            "your linear algebra exam won't study itself. close this."
        ]
        case 2: return [
            "no one masters linear algebra by scrolling.",
            "close this and open your linear algebra textbook.",
            "those vector space proofs need working through — focus."
        ]
        default: return [
            "CLOSE THIS. open your linear algebra notes.",
            "CLOSE THIS. those eigenvectors won't find themselves.",
            "CLOSE THIS. your linear algebra exam won't study itself."
        ]
        }
    }

    private func differentialequationsCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those ODEs won't solve themselves.",
            "close this and get back to your differential equations.",
            "that Laplace transform problem won't do itself. close this.",
            "your diff eq exam won't study itself. close this."
        ]
        case 2: return [
            "no one masters differential equations by scrolling.",
            "close this and open your diff eq textbook.",
            "those separation of variables problems need working through — focus."
        ]
        default: return [
            "CLOSE THIS. open your differential equations notes.",
            "CLOSE THIS. those ODEs won't solve themselves.",
            "CLOSE THIS. your differential equations exam won't study itself."
        ]
        }
    }

    private func neuropsychologyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those neuropsychological assessment methods won't learn themselves.",
            "close this and get back to your neuropsychology work.",
            "that executive function assessment won't study itself. close this.",
            "your neuropsychology exam won't study itself. close this."
        ]
        case 2: return [
            "no one masters neuropsychology by scrolling.",
            "close this and open your neuropsychology textbook.",
            "those cortical function and assessment battery concepts need reviewing — focus."
        ]
        default: return [
            "CLOSE THIS. open your neuropsychology notes.",
            "CLOSE THIS. those neuropsychological batteries won't memorize themselves.",
            "CLOSE THIS. your neuropsychology exam won't study itself."
        ]
        }
    }

    private func developmentalpsychCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those Piaget stages won't memorize themselves.",
            "close this and get back to your developmental psychology work.",
            "that attachment theory paper won't write itself. close this.",
            "your developmental psych exam won't study itself. close this."
        ]
        case 2: return [
            "no one masters developmental psychology by scrolling.",
            "close this and open your developmental psych textbook.",
            "those Piaget stages and attachment frameworks need reviewing — focus."
        ]
        default: return [
            "CLOSE THIS. open your developmental psychology notes.",
            "CLOSE THIS. those Piaget stages won't memorize themselves.",
            "CLOSE THIS. your developmental psych exam won't study itself."
        ]
        }
    }

    private func militarymedicineCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that TCCC protocol won't memorize itself.",
            "close this and get back to your combat medicine training.",
            "that MARCH algorithm won't study itself. close this.",
            "your tactical medicine exam won't study itself. close this."
        ]
        case 2: return [
            "no one aces combat medicine by scrolling.",
            "close this and open your TCCC training materials.",
            "those hemorrhage control and field care protocols need reviewing — focus."
        ]
        default: return [
            "CLOSE THIS. open your tactical medicine notes.",
            "CLOSE THIS. that MARCH algorithm won't memorize itself.",
            "CLOSE THIS. your combat casualty care exam won't study itself."
        ]
        }
    }

    private func complexanalysisCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those Cauchy-Riemann equations won't solve themselves.",
            "close this and get back to your complex analysis work.",
            "that contour integral won't compute itself. close this.",
            "your complex analysis exam won't study itself. close this."
        ]
        case 2: return [
            "no one masters complex analysis by scrolling.",
            "close this and open your complex analysis notes.",
            "those residue theorem problems need your attention — focus."
        ]
        default: return [
            "CLOSE THIS. open your complex analysis textbook.",
            "CLOSE THIS. those Cauchy-Riemann equations won't solve themselves.",
            "CLOSE THIS. your complex analysis exam won't study itself."
        ]
        }
    }

    private func realanalysisCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those epsilon-delta proofs won't write themselves.",
            "close this and get back to your real analysis work.",
            "that metric space problem won't solve itself. close this.",
            "your real analysis exam won't study itself. close this."
        ]
        case 2: return [
            "no one masters real analysis by scrolling.",
            "close this and open your real analysis notes.",
            "those Lebesgue integration problems need your full attention — focus."
        ]
        default: return [
            "CLOSE THIS. open your real analysis textbook.",
            "CLOSE THIS. those epsilon-delta proofs won't write themselves.",
            "CLOSE THIS. your real analysis exam won't study itself."
        ]
        }
    }

    private func discretemathCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those combinatorics problems won't solve themselves.",
            "close this and get back to your discrete math work.",
            "that graph theory proof won't write itself. close this.",
            "your discrete math exam won't study itself. close this."
        ]
        case 2: return [
            "no one masters discrete math by scrolling.",
            "close this and open your discrete math notes.",
            "those proof-by-induction problems need your attention — focus."
        ]
        default: return [
            "CLOSE THIS. open your discrete math textbook.",
            "CLOSE THIS. those combinatorics problems won't solve themselves.",
            "CLOSE THIS. your discrete math exam won't study itself."
        ]
        }
    }

    private func probabilitytheoryCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those probability theory proofs won't write themselves.",
            "close this and get back to your probability theory work.",
            "that sigma-algebra problem won't solve itself. close this.",
            "your probability theory exam won't study itself. close this."
        ]
        case 2: return [
            "no one masters probability theory by scrolling.",
            "close this and open your probability theory notes.",
            "those central limit theorem derivations need your attention — focus."
        ]
        default: return [
            "CLOSE THIS. open your probability theory textbook.",
            "CLOSE THIS. those sigma-algebra problems won't solve themselves.",
            "CLOSE THIS. your probability theory exam won't study itself."
        ]
        }
    }

    private func numericalanalysisCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those numerical methods won't implement themselves.",
            "close this and get back to your numerical analysis work.",
            "that finite difference problem won't solve itself. close this.",
            "your numerical analysis exam won't study itself. close this."
        ]
        case 2: return [
            "no one masters numerical analysis by scrolling.",
            "close this and open your numerical analysis notes.",
            "those floating-point and interpolation problems need your attention — focus."
        ]
        default: return [
            "CLOSE THIS. open your numerical analysis textbook.",
            "CLOSE THIS. those numerical methods won't implement themselves.",
            "CLOSE THIS. your numerical analysis exam won't study itself."
        ]
        }
    }

    private func statisticalmethodsCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that ANOVA won't run itself.",
            "those statistical methods won't apply themselves.",
            "your applied statistics assignment is waiting.",
            "you can't derive a Bayesian posterior by watching this."
        ]
        case 2: return [
            "no one masters statistical methods by scrolling.",
            "close this and open your statistics textbook.",
            "those experimental design problems need your attention — focus."
        ]
        default: return [
            "CLOSE THIS. open your applied statistics notes.",
            "CLOSE THIS. those statistical methods won't apply themselves.",
            "CLOSE THIS. your statistics exam won't study itself."
        ]
        }
    }

    private func topologyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those open and closed sets won't classify themselves.",
            "compactness proofs don't write themselves.",
            "your topology assignment is waiting.",
            "you can't prove homeomorphism by watching this."
        ]
        case 2: return [
            "no one masters topology by scrolling.",
            "close this and open your topology textbook.",
            "those compactness and connectedness proofs need your attention — focus."
        ]
        default: return [
            "CLOSE THIS. open your topology notes.",
            "CLOSE THIS. those topology proofs won't write themselves.",
            "CLOSE THIS. your topology exam won't study itself."
        ]
        }
    }

    private func abstractalgebraCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those group theory proofs won't write themselves.",
            "the isomorphism theorems aren't going to study themselves.",
            "your abstract algebra assignment is waiting.",
            "you can't prove Sylow's theorem by watching this."
        ]
        case 2: return [
            "no one masters abstract algebra by scrolling.",
            "close this and open your algebra textbook.",
            "those group and ring theory problems need your attention — focus."
        ]
        default: return [
            "CLOSE THIS. open your abstract algebra notes.",
            "CLOSE THIS. those algebra proofs won't write themselves.",
            "CLOSE THIS. your abstract algebra exam won't study itself."
        ]
        }
    }

    private func seismologyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that seismogram won't interpret itself.",
            "those earthquake location problems won't solve themselves.",
            "your seismology assignment is waiting.",
            "you can't analyze focal mechanisms by watching this."
        ]
        case 2: return [
            "no one masters seismology by scrolling.",
            "close this and open your seismology notes.",
            "those seismic wave and focal mechanism problems need your attention — focus."
        ]
        default: return [
            "CLOSE THIS. open your seismology textbook.",
            "CLOSE THIS. those seismograms won't analyze themselves.",
            "CLOSE THIS. your seismology exam won't study itself."
        ]
        }
    }

    private func volcanologyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that volcanic hazard assessment won't do itself.",
            "those pyroclastic flow problems won't solve themselves.",
            "your volcanology assignment is waiting.",
            "you can't model eruption dynamics by watching this."
        ]
        case 2: return [
            "no one masters volcanology by scrolling.",
            "close this and open your volcanology notes.",
            "those eruption dynamics and volcanic hazard problems need your attention — focus."
        ]
        default: return [
            "CLOSE THIS. open your volcanology textbook.",
            "CLOSE THIS. those volcanic processes won't analyze themselves.",
            "CLOSE THIS. your volcanology exam won't study itself."
        ]
        }
    }

    private func geomorphologyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those landforms won't analyze themselves.",
            "your geomorphology assignment is sitting there waiting.",
            "fluvial processes don't study themselves — get back to it.",
            "you can't map hillslope processes by scrolling through this."
        ]
        case 2: return [
            "no one masters geomorphology by scrolling.",
            "close this and open your geomorphology notes.",
            "those drainage basin and landform problems need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your geomorphology textbook.",
            "CLOSE THIS. those landform processes won't analyze themselves.",
            "CLOSE THIS. your geomorphology exam won't study itself."
        ]
        }
    }

    private func sedimentologyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those sedimentary structures won't describe themselves.",
            "your sedimentology assignment is waiting.",
            "grain size analysis doesn't do itself — get back to it.",
            "you can't interpret facies by scrolling through this."
        ]
        case 2: return [
            "no one masters sedimentology by scrolling.",
            "close this and open your sedimentology notes.",
            "those facies and sediment transport problems need your attention — focus."
        ]
        default: return [
            "CLOSE THIS. open your sedimentology textbook.",
            "CLOSE THIS. those sedimentary structures won't interpret themselves.",
            "CLOSE THIS. your sedimentology exam won't study itself."
        ]
        }
    }

    private func structuralgeologyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those fault geometries won't work themselves out.",
            "your structural geology assignment is waiting.",
            "stereonet analysis doesn't do itself — get back to it.",
            "you can't interpret fold geometry by scrolling through this."
        ]
        case 2: return [
            "no one masters structural geology by scrolling.",
            "close this and open your structural geology notes.",
            "those fault analysis and strain problems need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your structural geology textbook.",
            "CLOSE THIS. those deformation mechanisms won't analyze themselves.",
            "CLOSE THIS. your structural geology exam won't study itself."
        ]
        }
    }

    private func functionalanalysisCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those Banach space proofs won't write themselves.",
            "your functional analysis assignment is waiting.",
            "operator theory doesn't study itself — get back to it.",
            "you can't prove the spectral theorem by scrolling through this."
        ]
        case 2: return [
            "no one masters functional analysis by scrolling.",
            "close this and open your functional analysis notes.",
            "those Hilbert space and operator theory problems need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your functional analysis textbook.",
            "CLOSE THIS. those Banach space theorems won't prove themselves.",
            "CLOSE THIS. your functional analysis exam won't study itself."
        ]
        }
    }

    private func differentialgeometryCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those Riemannian manifold problems won't solve themselves.",
            "your differential geometry assignment is waiting.",
            "geodesics don't compute themselves — get back to it.",
            "you can't derive Christoffel symbols by scrolling through this."
        ]
        case 2: return [
            "no one masters differential geometry by scrolling.",
            "close this and open your differential geometry notes.",
            "those curvature and manifold problems need your attention — focus."
        ]
        default: return [
            "CLOSE THIS. open your differential geometry textbook.",
            "CLOSE THIS. those Riemannian manifolds won't analyze themselves.",
            "CLOSE THIS. your differential geometry exam won't study itself."
        ]
        }
    }

    private func cosmologyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those Friedmann equations won't solve themselves.",
            "your cosmology assignment is waiting.",
            "the universe isn't going to explain itself — get back to it.",
            "you can't understand dark energy by scrolling through this."
        ]
        case 2: return [
            "no one masters cosmology by scrolling.",
            "close this and open your cosmology notes.",
            "those large-scale structure and CMB problems need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your cosmology textbook.",
            "CLOSE THIS. those Friedmann equations won't derive themselves.",
            "CLOSE THIS. your cosmology exam won't study itself."
        ]
        }
    }

    private func planetaryscienceCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those planetary formation problems won't solve themselves.",
            "your planetary science assignment is waiting.",
            "exoplanets don't characterize themselves — get back to it.",
            "you can't model planetary atmospheres by scrolling through this."
        ]
        case 2: return [
            "no one masters planetary science by scrolling.",
            "close this and open your planetary science notes.",
            "those solar system formation and exoplanet problems need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your planetary science textbook.",
            "CLOSE THIS. those planetary geology problems won't solve themselves.",
            "CLOSE THIS. your planetary science exam won't study itself."
        ]
        }
    }

    private func particlephysicsCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those Feynman diagrams won't draw themselves.",
            "your particle physics assignment is waiting.",
            "the Standard Model won't explain itself — get back to it.",
            "you can't derive QFT by scrolling through this."
        ]
        case 2: return [
            "no one masters particle physics by scrolling.",
            "close this and open your particle physics notes.",
            "those gauge theory and QFT problems need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your particle physics textbook.",
            "CLOSE THIS. those Feynman diagrams won't compute themselves.",
            "CLOSE THIS. your particle physics exam won't study itself."
        ]
        }
    }

    private func statisticalmechanicsCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those partition functions won't evaluate themselves.",
            "your statistical mechanics assignment is waiting.",
            "entropy doesn't maximize itself — get back to it.",
            "you can't solve ensemble theory by scrolling through this."
        ]
        case 2: return [
            "no one masters statistical mechanics by scrolling.",
            "close this and open your stat mech notes.",
            "those Boltzmann distribution and ensemble problems need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your statistical mechanics textbook.",
            "CLOSE THIS. those partition functions won't evaluate themselves.",
            "CLOSE THIS. your stat mech exam won't study itself."
        ]
        }
    }

    private func environmentalchemistryCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those contaminant fate problems won't work themselves out.",
            "your environmental chemistry assignment is waiting.",
            "pollutant transport doesn't model itself — get back to it.",
            "you can't master aquatic chemistry by scrolling through this."
        ]
        case 2: return [
            "no one masters environmental chemistry by scrolling.",
            "close this and open your environmental chemistry notes.",
            "those water quality and contaminant fate problems need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your environmental chemistry textbook.",
            "CLOSE THIS. those contaminant transport problems won't solve themselves.",
            "CLOSE THIS. your environmental chemistry exam won't study itself."
        ]
        }
    }

    private func radioastronomyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those radio telescope observations won't analyze themselves.",
            "your radio astronomy assignment is waiting.",
            "VLBI data doesn't reduce itself — get back to it.",
            "you can't master pulsar timing by scrolling through this."
        ]
        case 2: return [
            "no one masters radio astronomy by scrolling.",
            "close this and open your radio astronomy notes.",
            "those aperture synthesis and interferometry problems need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your radio astronomy textbook.",
            "CLOSE THIS. those VLBI data won't reduce themselves.",
            "CLOSE THIS. your radio astronomy exam won't study itself."
        ]
        }
    }

    private func astrochemistryCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those interstellar medium chemistry problems won't solve themselves.",
            "your astrochemistry assignment is waiting.",
            "molecular cloud chemistry doesn't unravel itself — get back to it.",
            "you can't master astrochemistry by scrolling through this."
        ]
        case 2: return [
            "no one masters astrochemistry by scrolling.",
            "close this and open your astrochemistry notes.",
            "those interstellar molecule and chemical evolution problems need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your astrochemistry textbook.",
            "CLOSE THIS. those interstellar chemistry problems won't solve themselves.",
            "CLOSE THIS. your astrochemistry exam won't study itself."
        ]
        }
    }

    private func nuclearphysicsCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those nuclear reactions won't balance themselves.",
            "your nuclear physics assignment is waiting.",
            "radioactive decay doesn't calculate itself — get back to it.",
            "you can't master nuclear physics by scrolling through this."
        ]
        case 2: return [
            "no one masters nuclear physics by scrolling.",
            "close this and open your nuclear physics notes.",
            "those decay chains and fission problems need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your nuclear physics textbook.",
            "CLOSE THIS. those nuclear reaction calculations won't do themselves.",
            "CLOSE THIS. your nuclear physics exam won't study itself."
        ]
        }
    }

    private func plasmaphysicsCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those MHD equations won't solve themselves.",
            "your plasma physics assignment is waiting.",
            "Debye shielding doesn't derive itself — get back to it.",
            "you can't master plasma physics by scrolling through this."
        ]
        case 2: return [
            "no one masters plasma physics by scrolling.",
            "close this and open your plasma physics notes.",
            "those MHD and tokamak confinement problems need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your plasma physics textbook.",
            "CLOSE THIS. those MHD equations won't solve themselves.",
            "CLOSE THIS. your plasma physics exam won't study itself."
        ]
        }
    }

    private func computationalfluidynamicsCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that CFD simulation won't converge itself.",
            "your computational fluid dynamics assignment is waiting.",
            "Navier-Stokes doesn't discretize itself — get back to it.",
            "you can't master CFD by scrolling through this."
        ]
        case 2: return [
            "no one masters CFD by scrolling.",
            "close this and open your CFD notes.",
            "those Navier-Stokes and turbulence modeling problems need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your computational fluid dynamics textbook.",
            "CLOSE THIS. that CFD simulation won't set itself up.",
            "CLOSE THIS. your CFD exam won't study itself."
        ]
        }
    }

    private func glaciologyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those ice sheet calculations won't do themselves.",
            "your glaciology assignment is waiting.",
            "glacier mass balance doesn't compute itself — get back to it.",
            "you can't master glaciology by scrolling through this."
        ]
        case 2: return [
            "no one masters glaciology by scrolling.",
            "close this and open your glaciology notes.",
            "those ice core and glacier dynamics problems need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your glaciology textbook.",
            "CLOSE THIS. those ice sheet dynamics won't analyze themselves.",
            "CLOSE THIS. your glaciology exam won't study itself."
        ]
        }
    }

    private func hydrologyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those streamflow calculations won't do themselves.",
            "your hydrology assignment is waiting.",
            "hydrological cycles don't analyze themselves — get back to it.",
            "you can't master hydrology by scrolling through this."
        ]
        case 2: return [
            "no one masters hydrology by scrolling.",
            "close this and open your hydrology notes.",
            "those watershed and flood frequency problems need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your hydrology textbook.",
            "CLOSE THIS. those hydrograph calculations won't do themselves.",
            "CLOSE THIS. your hydrology exam won't study itself."
        ]
        }
    }

    private func climatologyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those climate model equations won't run themselves.",
            "your climatology assignment is waiting.",
            "radiative forcing doesn't calculate itself — get back to it.",
            "you can't master climatology by scrolling through this."
        ]
        case 2: return [
            "no one masters climatology by scrolling.",
            "close this and open your climatology notes.",
            "those climate feedback and ENSO problems need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your climatology textbook.",
            "CLOSE THIS. those climate model calculations won't do themselves.",
            "CLOSE THIS. your climatology exam won't study itself."
        ]
        }
    }

    private func photochemistryCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those excited state transitions won't derive themselves.",
            "your photochemistry assignment is waiting.",
            "Jablonski diagrams don't draw themselves — get back to it.",
            "you can't master photochemistry by scrolling through this."
        ]
        case 2: return [
            "no one masters photochemistry by scrolling.",
            "close this and open your photochemistry notes.",
            "those quantum yield and energy transfer problems need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your photochemistry textbook.",
            "CLOSE THIS. those photochemical reaction mechanisms won't write themselves.",
            "CLOSE THIS. your photochemistry exam won't study itself."
        ]
        }
    }

    private func electromagnetictheoryCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those electrodynamics problems won't solve themselves.",
            "your electromagnetic theory assignment is waiting.",
            "retarded potentials don't derive themselves — get back to it.",
            "you can't master electrodynamics by scrolling through this."
        ]
        case 2: return [
            "no one masters electromagnetic theory by scrolling.",
            "close this and open your Griffiths.",
            "those gauge invariance and radiation problems need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your electrodynamics textbook.",
            "CLOSE THIS. those multipole expansion problems won't solve themselves.",
            "CLOSE THIS. your electromagnetic theory exam won't study itself."
        ]
        }
    }

    private func operatingsystemsCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those process scheduling algorithms won't learn themselves.",
            "your OS exam doesn't care that you're scrolling.",
            "get back to your operating systems work.",
            "close this and open your OS textbook.",
        ]
        case 2: return [
            "no one masters operating systems by scrolling.",
            "close this and work on your OS assignment.",
            "those virtual memory and scheduling problems need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your operating systems textbook.",
            "CLOSE THIS. those deadlock and synchronization problems won't solve themselves.",
            "CLOSE THIS. your OS exam won't study itself."
        ]
        }
    }

    private func algorithmsCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those algorithm proofs won't write themselves.",
            "your algorithms exam doesn't care that you're scrolling.",
            "get back to your algorithms work.",
            "close this and open your algorithms textbook.",
        ]
        case 2: return [
            "no one masters algorithms by scrolling.",
            "close this and work on your algorithms problem set.",
            "those dynamic programming and complexity proofs need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your algorithms textbook.",
            "CLOSE THIS. those NP-completeness and graph algorithm problems won't solve themselves.",
            "CLOSE THIS. your algorithms exam won't study itself."
        ]
        }
    }

    private func databasesystemsCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those database design problems won't solve themselves.",
            "your database exam doesn't care that you're scrolling.",
            "get back to your database systems work.",
            "close this and open your database textbook.",
        ]
        case 2: return [
            "no one masters database systems by scrolling.",
            "close this and work on your database assignment.",
            "those normalization and query optimization problems need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your database systems textbook.",
            "CLOSE THIS. those ER diagrams and SQL queries won't write themselves.",
            "CLOSE THIS. your database exam won't study itself."
        ]
        }
    }

    private func computernetworksCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those network protocol problems won't solve themselves.",
            "your networks exam doesn't care that you're scrolling.",
            "get back to your computer networks work.",
            "close this and open your networking textbook.",
        ]
        case 2: return [
            "no one masters computer networks by scrolling.",
            "close this and work on your networking assignment.",
            "those TCP/IP and routing protocol problems need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your computer networks textbook.",
            "CLOSE THIS. those subnetting and OSI model problems won't solve themselves.",
            "CLOSE THIS. your networks exam won't study itself."
        ]
        }
    }

    private func computervisionCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those image processing algorithms won't implement themselves.",
            "your computer vision exam doesn't care that you're scrolling.",
            "get back to your computer vision work.",
            "close this and open your computer vision textbook.",
        ]
        case 2: return [
            "no one masters computer vision by scrolling.",
            "close this and work on your CV assignment.",
            "those object detection and segmentation problems need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your computer vision textbook.",
            "CLOSE THIS. those convolutional network and feature extraction problems won't solve themselves.",
            "CLOSE THIS. your computer vision exam won't study itself."
        ]
        }
    }

    private func softwareengineeringCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those UML diagrams won't draw themselves.",
            "your software engineering exam doesn't care that you're scrolling.",
            "get back to your SE work.",
            "close this and open your software engineering textbook.",
        ]
        case 2: return [
            "no one passes software engineering by scrolling.",
            "close this and work on your SE assignment.",
            "those design patterns and requirements won't study themselves."
        ]
        default: return [
            "CLOSE THIS. open your software engineering textbook.",
            "CLOSE THIS. those SOLID principles and design patterns won't learn themselves.",
            "CLOSE THIS. your software engineering exam won't study itself."
        ]
        }
    }

    private func humancomputerinteractionCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that usability study won't run itself.",
            "your HCI exam doesn't care that you're scrolling.",
            "get back to your HCI work.",
            "close this and open your HCI textbook.",
        ]
        case 2: return [
            "no one masters human-computer interaction by scrolling.",
            "close this and work on your HCI assignment.",
            "those cognitive walkthroughs and heuristic evaluations need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your HCI textbook.",
            "CLOSE THIS. those usability studies and interaction design problems won't solve themselves.",
            "CLOSE THIS. your HCI exam won't study itself."
        ]
        }
    }

    private func machinelearningCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those gradient descent derivations won't work themselves out.",
            "your machine learning exam doesn't care that you're scrolling.",
            "get back to your ML work.",
            "close this and open your machine learning textbook.",
        ]
        case 2: return [
            "no one masters machine learning by scrolling.",
            "close this and work on your ML assignment.",
            "those SVM and cross-validation problems need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your machine learning textbook.",
            "CLOSE THIS. those bias-variance tradeoffs and regularization problems won't solve themselves.",
            "CLOSE THIS. your machine learning exam won't study itself."
        ]
        }
    }

    private func distributedsystemsCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those consensus protocol proofs won't write themselves.",
            "your distributed systems exam doesn't care that you're scrolling.",
            "get back to your distributed systems work.",
            "close this and open your distributed systems textbook.",
        ]
        case 2: return [
            "no one masters distributed systems by scrolling.",
            "close this and work on your distributed systems assignment.",
            "those CAP theorem and fault tolerance problems need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your distributed systems textbook.",
            "CLOSE THIS. those Paxos and Raft consensus problems won't solve themselves.",
            "CLOSE THIS. your distributed systems exam won't study itself."
        ]
        }
    }

    private func computersecurityCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those buffer overflow exploits won't analyze themselves.",
            "your computer security exam doesn't care that you're scrolling.",
            "get back to your computer security work.",
            "close this and open your computer security textbook.",
        ]
        case 2: return [
            "no one masters computer security by scrolling.",
            "close this and work on your security assignment.",
            "those memory safety and software vulnerability problems need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your computer security textbook.",
            "CLOSE THIS. those secure coding and vulnerability analysis problems won't solve themselves.",
            "CLOSE THIS. your computer security exam won't study itself."
        ]
        }
    }

    private func corrosionengineeringCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those galvanic corrosion diagrams won't draw themselves.",
            "your corrosion engineering exam doesn't care that you're scrolling.",
            "get back to your corrosion engineering work.",
            "close this and open your corrosion engineering textbook.",
        ]
        case 2: return [
            "no one masters corrosion engineering by scrolling.",
            "close this and work on your corrosion assignment.",
            "those cathodic protection and SCC problems need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your corrosion engineering textbook.",
            "CLOSE THIS. those electrochemical corrosion and Pourbaix diagram problems won't solve themselves.",
            "CLOSE THIS. your corrosion engineering exam won't study itself."
        ]
        }
    }

    private func acousticalengineeringCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those RT60 calculations and STC ratings won't work themselves out.",
            "your architectural acoustics exam doesn't care that you're scrolling.",
            "get back to your building acoustics work.",
            "close this and open your acoustical engineering textbook.",
        ]
        case 2: return [
            "no one masters acoustical engineering by scrolling.",
            "close this and work on your acoustics assignment.",
            "those absorption coefficients and flanking transmission problems need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your acoustical engineering textbook.",
            "CLOSE THIS. those Sabine formula and speech intelligibility calculations won't solve themselves.",
            "CLOSE THIS. your architectural acoustics exam won't study itself."
        ]
        }
    }

    private func microfluidicsCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that lab-on-chip design won't build itself.",
            "your microfluidics exam doesn't care that you're scrolling.",
            "get back to your microfluidics work.",
            "close this and open your microfluidics textbook.",
        ]
        case 2: return [
            "no one masters microfluidics by scrolling.",
            "close this and work on your microfluidics assignment.",
            "those Dean flow and electroosmosis problems need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your microfluidics textbook.",
            "CLOSE THIS. those PDMS device fabrication and microchannel flow problems won't solve themselves.",
            "CLOSE THIS. your microfluidics exam won't study itself."
        ]
        }
    }

    private func marinehydrodynamicsCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those added mass and wave-body interaction problems won't solve themselves.",
            "your marine hydrodynamics exam doesn't care that you're scrolling.",
            "get back to your marine hydrodynamics work.",
            "close this and open your marine hydrodynamics textbook.",
        ]
        case 2: return [
            "no one masters marine hydrodynamics by scrolling.",
            "close this and work on your marine hydrodynamics assignment.",
            "those seakeeping and radiation/diffraction problems need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your marine hydrodynamics textbook.",
            "CLOSE THIS. those panel method and strip theory hydrodynamics problems won't solve themselves.",
            "CLOSE THIS. your marine hydrodynamics exam won't study itself."
        ]
        }
    }

    private func thermofluidscombustionCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those premixed flame and equivalence ratio problems won't solve themselves.",
            "your combustion engineering exam doesn't care that you're scrolling.",
            "get back to your combustion engineering work.",
            "close this and open your combustion engineering textbook.",
        ]
        case 2: return [
            "no one masters combustion engineering by scrolling.",
            "close this and work on your combustion assignment.",
            "those adiabatic flame temperature and NOx formation problems need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your combustion engineering textbook.",
            "CLOSE THIS. those laminar burning velocity and diffusion flame problems won't solve themselves.",
            "CLOSE THIS. your combustion engineering exam won't study itself."
        ]
        }
    }

    private func nuclearreactorphysicsCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those neutron transport and criticality problems won't solve themselves.",
            "your reactor physics exam doesn't care that you're scrolling.",
            "get back to your reactor physics work.",
            "close this and open your reactor physics textbook.",
        ]
        case 2: return [
            "no one masters reactor physics by scrolling.",
            "close this and work on your reactor physics assignment.",
            "those four-factor formula and xenon poisoning problems need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your reactor physics textbook.",
            "CLOSE THIS. those criticality analysis and reactor kinetics problems won't solve themselves.",
            "CLOSE THIS. your reactor physics exam won't study itself."
        ]
        }
    }

    private func optoelectronicsCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those LED physics and photodetector problems won't solve themselves.",
            "your optoelectronics exam doesn't care that you're scrolling.",
            "get back to your optoelectronics work.",
            "close this and open your optoelectronics textbook.",
        ]
        case 2: return [
            "no one masters optoelectronics by scrolling.",
            "close this and work on your optoelectronics assignment.",
            "those laser diode and semiconductor band gap problems need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your optoelectronics textbook.",
            "CLOSE THIS. those photoluminescence and electroluminescence optoelectronics problems won't solve themselves.",
            "CLOSE THIS. your optoelectronics exam won't study itself."
        ]
        }
    }

    private func magneticresonanceCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those Bloch equations and pulse sequences won't work themselves out.",
            "your MRI physics exam doesn't care that you're scrolling.",
            "get back to your magnetic resonance work.",
            "close this and open your MRI textbook.",
        ]
        case 2: return [
            "no one masters magnetic resonance by scrolling.",
            "close this and work on your MRI/NMR assignment.",
            "those k-space and T1/T2 relaxation problems need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your magnetic resonance textbook.",
            "CLOSE THIS. those spin-echo sequences and k-space reconstruction problems won't solve themselves.",
            "CLOSE THIS. your MRI physics exam won't study itself."
        ]
        }
    }

    private func computationalelectromagneticsCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that FDTD simulation won't run itself.",
            "your computational electromagnetics exam doesn't care that you're scrolling.",
            "get back to your CEM work.",
            "close this and open your computational EM textbook.",
        ]
        case 2: return [
            "no one masters computational electromagnetics by scrolling.",
            "close this and work on your CEM assignment.",
            "those FDTD grid setup and method-of-moments problems need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your computational electromagnetics textbook.",
            "CLOSE THIS. those HFSS simulation and FDTD boundary condition problems won't solve themselves.",
            "CLOSE THIS. your computational electromagnetics exam won't study itself."
        ]
        }
    }

    private func thermoelectricsCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those Seebeck coefficient and ZT figure-of-merit problems won't solve themselves.",
            "your thermoelectrics exam doesn't care that you're scrolling.",
            "get back to your thermoelectrics work.",
            "close this and open your thermoelectrics textbook.",
        ]
        case 2: return [
            "no one masters thermoelectrics by scrolling.",
            "close this and work on your thermoelectrics assignment.",
            "those Peltier effect and thermoelectric generator efficiency problems need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your thermoelectrics textbook.",
            "CLOSE THIS. those ZT figure of merit and Seebeck/Peltier coefficient problems won't solve themselves.",
            "CLOSE THIS. your thermoelectrics exam won't study itself."
        ]
        }
    }

    private func programminglanguagesCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those type inference proofs won't write themselves.",
            "your programming languages exam doesn't care that you're scrolling.",
            "get back to your PL theory work.",
            "close this and open your programming languages textbook.",
        ]
        case 2: return [
            "no one masters programming languages theory by scrolling.",
            "close this and work on your PL assignment.",
            "those lambda calculus reductions and type system rules need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your programming languages textbook.",
            "CLOSE THIS. those operational semantics and type inference derivations won't solve themselves.",
            "CLOSE THIS. your PL exam won't study itself."
        ]
        }
    }

    private func compilerdesignCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that parser won't write itself.",
            "your compilers exam doesn't care that you're scrolling.",
            "get back to your compiler design work.",
            "close this and open your compilers textbook.",
        ]
        case 2: return [
            "no one masters compiler design by scrolling.",
            "close this and work on your compilers assignment.",
            "those lexer rules and code generation passes need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your compilers textbook.",
            "CLOSE THIS. those parsing algorithms and register allocation problems won't solve themselves.",
            "CLOSE THIS. your compilers exam won't study itself."
        ]
        }
    }

    private func computergraphicsCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those ray tracing equations won't derive themselves.",
            "your computer graphics exam doesn't care that you're scrolling.",
            "get back to your graphics work.",
            "close this and open your computer graphics textbook.",
        ]
        case 2: return [
            "no one masters computer graphics by scrolling.",
            "close this and work on your graphics assignment.",
            "those rasterization and shader problems need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your computer graphics textbook.",
            "CLOSE THIS. those rendering pipeline and 3D transform problems won't solve themselves.",
            "CLOSE THIS. your computer graphics exam won't study itself."
        ]
        }
    }

    private func embeddedsystemsCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that interrupt handler won't write itself.",
            "your embedded systems exam doesn't care that you're scrolling.",
            "get back to your embedded systems work.",
            "close this and open your embedded systems textbook.",
        ]
        case 2: return [
            "no one masters embedded systems by scrolling.",
            "close this and work on your embedded assignment.",
            "those RTOS scheduling and microcontroller problems need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your embedded systems textbook.",
            "CLOSE THIS. those interrupt service routines and device driver problems won't solve themselves.",
            "CLOSE THIS. your embedded systems exam won't study itself."
        ]
        }
    }

    private func formalverificationCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those Hoare triples won't verify themselves.",
            "your formal verification exam doesn't care that you're scrolling.",
            "get back to your formal methods work.",
            "close this and open your formal verification textbook.",
        ]
        case 2: return [
            "no one masters formal verification by scrolling.",
            "close this and work on your formal methods assignment.",
            "those model checking and theorem proving problems need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your formal verification textbook.",
            "CLOSE THIS. those temporal logic formulas and Hoare logic proofs won't verify themselves.",
            "CLOSE THIS. your formal verification exam won't study itself."
        ]
        }
    }

    private func computationtheoryCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that Turing machine won't design itself.",
            "your theory of computation exam doesn't care that you're scrolling.",
            "get back to your automata and complexity work.",
            "close this and open your theory of computation textbook.",
        ]
        case 2: return [
            "no one masters theory of computation by scrolling.",
            "close this and work on your automata assignment.",
            "those decidability and NP-completeness proofs need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your theory of computation textbook.",
            "CLOSE THIS. those DFA constructions and NP-completeness reductions won't prove themselves.",
            "CLOSE THIS. your theory of computation exam won't study itself."
        ]
        }
    }

    private func softwarearchitectureCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that system design won't architect itself.",
            "your software architecture exam doesn't care that you're scrolling.",
            "get back to your architecture patterns work.",
            "close this and open your software architecture textbook.",
        ]
        case 2: return [
            "no one masters software architecture by scrolling.",
            "close this and work on your architecture assignment.",
            "those microservices and domain-driven design problems need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your software architecture textbook.",
            "CLOSE THIS. those architectural patterns and system design problems won't solve themselves.",
            "CLOSE THIS. your software architecture exam won't study itself."
        ]
        }
    }

    private func informationretrievalCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that inverted index won't build itself.",
            "your information retrieval exam doesn't care that you're scrolling.",
            "get back to your IR work.",
            "close this and open your information retrieval textbook.",
        ]
        case 2: return [
            "no one masters information retrieval by scrolling.",
            "close this and work on your IR assignment.",
            "those TF-IDF and BM25 ranking problems need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your information retrieval textbook.",
            "CLOSE THIS. those document ranking and query expansion problems won't solve themselves.",
            "CLOSE THIS. your information retrieval exam won't study itself."
        ]
        }
    }

    private func naturallanguageprocessingCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those NLP models won't train themselves.",
            "your NLP exam doesn't care that you're scrolling.",
            "get back to your natural language processing work.",
            "close this and open your NLP textbook.",
        ]
        case 2: return [
            "no one masters NLP by scrolling.",
            "close this and work on your NLP assignment.",
            "those transformer and sequence labeling problems need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your NLP textbook.",
            "CLOSE THIS. those named entity recognition and dependency parsing problems won't solve themselves.",
            "CLOSE THIS. your NLP exam won't study itself."
        ]
        }
    }

    private func computerarchitectureCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that pipeline won't design itself.",
            "your computer architecture exam doesn't care that you're scrolling.",
            "get back to your architecture work.",
            "close this and open your computer architecture textbook.",
        ]
        case 2: return [
            "no one masters computer architecture by scrolling.",
            "close this and work on your architecture assignment.",
            "those cache hierarchy and branch prediction problems need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your computer architecture textbook.",
            "CLOSE THIS. those pipeline stages and cache coherence problems won't solve themselves.",
            "CLOSE THIS. your computer architecture exam won't study itself."
        ]
        }
    }

    private func photonicsCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those photonic circuits won't design themselves.",
            "your photonics exam doesn't care that you're scrolling.",
            "get back to your photonics work.",
            "close this and open your photonics textbook.",
        ]
        case 2: return [
            "no one masters photonics by scrolling.",
            "close this and work on your photonics assignment.",
            "those waveguide and fiber optics problems need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your photonics textbook.",
            "CLOSE THIS. those nonlinear optics and integrated photonics problems won't solve themselves.",
            "CLOSE THIS. your photonics exam won't study itself."
        ]
        }
    }

    private func acousticsengineeringCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those acoustic measurements won't take themselves.",
            "your acoustics exam doesn't care that you're scrolling.",
            "get back to your acoustics work.",
            "close this and open your acoustics textbook.",
        ]
        case 2: return [
            "no one masters acoustics by scrolling.",
            "close this and work on your acoustics assignment.",
            "those room acoustics and noise control problems need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your acoustics textbook.",
            "CLOSE THIS. those acoustic wave and vibration analysis problems won't solve themselves.",
            "CLOSE THIS. your acoustics exam won't study itself."
        ]
        }
    }

    private func petroleumengineeringCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that reservoir won't model itself.",
            "your petroleum engineering exam doesn't care that you're scrolling.",
            "get back to your petroleum engineering work.",
            "close this and open your petroleum engineering textbook.",
        ]
        case 2: return [
            "no one masters reservoir engineering by scrolling.",
            "close this and work on your petroleum engineering assignment.",
            "those well logging and petrophysics problems need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your petroleum engineering textbook.",
            "CLOSE THIS. those reservoir simulation and drilling engineering problems won't solve themselves.",
            "CLOSE THIS. your petroleum engineering exam won't study itself."
        ]
        }
    }

    private func sportspsychologyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that athlete's mindset won't build itself.",
            "your sports psychology exam doesn't care that you're scrolling.",
            "get back to your sports psychology work.",
            "close this and open your sports psychology textbook.",
        ]
        case 2: return [
            "no one masters mental performance by scrolling.",
            "close this and work on your sports psychology assignment.",
            "those flow state and pre-competition anxiety concepts need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your sports psychology textbook.",
            "CLOSE THIS. those visualization and mental skills training concepts won't internalize themselves.",
            "CLOSE THIS. your sports psychology exam won't study itself."
        ]
        }
    }

    private func limnologyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those freshwater ecosystems won't study themselves.",
            "your limnology exam doesn't care that you're scrolling.",
            "get back to your limnology work.",
            "close this and open your limnology textbook.",
        ]
        case 2: return [
            "no one masters limnology by scrolling.",
            "close this and work on your limnology assignment.",
            "those eutrophication and benthic community problems need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your limnology textbook.",
            "CLOSE THIS. those freshwater ecology and lake stratification problems won't solve themselves.",
            "CLOSE THIS. your limnology exam won't study itself."
        ]
        }
    }

    private func astrodynamicsCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those orbital mechanics problems won't solve themselves.",
            "your astrodynamics exam doesn't care that you're scrolling.",
            "get back to your orbital mechanics work.",
            "close this and open your astrodynamics textbook.",
        ]
        case 2: return [
            "no one masters orbital mechanics by scrolling.",
            "close this and work on your astrodynamics problem set.",
            "those Hohmann transfers and orbit determination problems need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your astrodynamics textbook.",
            "CLOSE THIS. those Keplerian orbits and delta-v calculations won't solve themselves.",
            "CLOSE THIS. your orbital mechanics exam won't study itself."
        ]
        }
    }

    private func biomaterialsCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those biocompatibility and scaffold design problems won't solve themselves.",
            "your biomaterials exam doesn't care that you're scrolling.",
            "get back to your biomaterials work.",
            "close this and open your biomaterials textbook.",
        ]
        case 2: return [
            "no one masters biomaterials by scrolling.",
            "close this and work on your biomaterials assignment.",
            "those implant materials and biocompatibility problems need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your biomaterials textbook.",
            "CLOSE THIS. those scaffold design and surface functionalization problems won't solve themselves.",
            "CLOSE THIS. your biomaterials exam won't study itself."
        ]
        }
    }

    private func crystallographyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those crystal structure problems won't solve themselves.",
            "your crystallography exam doesn't care that you're scrolling.",
            "get back to your crystallography work.",
            "close this and open your crystallography textbook.",
        ]
        case 2: return [
            "no one masters crystallography by scrolling.",
            "close this and work on your crystallography assignment.",
            "those Bragg's law and space group problems need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your crystallography textbook.",
            "CLOSE THIS. those X-ray diffraction and crystal symmetry problems won't solve themselves.",
            "CLOSE THIS. your crystallography exam won't study itself."
        ]
        }
    }

    private func spectroscopyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those NMR and IR spectra won't interpret themselves.",
            "your spectroscopy exam doesn't care that you're scrolling.",
            "get back to your spectroscopy work.",
            "close this and open your spectroscopy textbook.",
        ]
        case 2: return [
            "no one masters spectroscopy by scrolling.",
            "close this and work on your spectroscopy assignment.",
            "those NMR chemical shifts and mass spec fragmentation problems need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your spectroscopy textbook.",
            "CLOSE THIS. those NMR splitting patterns and IR absorptions won't interpret themselves.",
            "CLOSE THIS. your spectroscopy exam won't study itself."
        ]
        }
    }

    private func industrialengineeringCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those operations research problems won't solve themselves.",
            "your industrial engineering exam doesn't care that you're scrolling.",
            "get back to your IE work.",
            "close this and open your industrial engineering textbook.",
        ]
        case 2: return [
            "no one masters industrial engineering by scrolling.",
            "close this and work on your IE assignment.",
            "those queueing theory and facilities layout problems need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your industrial engineering textbook.",
            "CLOSE THIS. those operations research and lean manufacturing problems won't solve themselves.",
            "CLOSE THIS. your IE exam won't study itself."
        ]
        }
    }

    private func psycholinguisticsCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those sentence processing problems won't think themselves through.",
            "your psycholinguistics exam doesn't care that you're scrolling.",
            "get back to your psycholinguistics work.",
            "close this and open your psycholinguistics textbook.",
        ]
        case 2: return [
            "no one masters psycholinguistics by scrolling.",
            "close this and work on your psycholinguistics assignment.",
            "those garden-path sentences and mental lexicon problems need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your psycholinguistics textbook.",
            "CLOSE THIS. those sentence processing and lexical access problems won't solve themselves.",
            "CLOSE THIS. your psycholinguistics exam won't study itself."
        ]
        }
    }

    private func photogrammetryCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that 3D reconstruction won't happen while you're scrolling.",
            "your photogrammetry exam doesn't care that you're here.",
            "get back to your photogrammetry work.",
            "close this and open your photogrammetry textbook.",
        ]
        case 2: return [
            "no one masters photogrammetry by scrolling.",
            "close this and work on your photogrammetry assignment.",
            "those structure-from-motion and bundle adjustment problems need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your photogrammetry textbook.",
            "CLOSE THIS. those point cloud processing and drone mapping problems won't solve themselves.",
            "CLOSE THIS. your photogrammetry exam won't study itself."
        ]
        }
    }

    private func tectonicsCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those tectonic plate problems won't solve themselves.",
            "your tectonics exam doesn't care that you're scrolling.",
            "get back to your tectonics work.",
            "close this and open your tectonics textbook.",
        ]
        case 2: return [
            "no one masters plate tectonics by scrolling.",
            "close this and work on your tectonics assignment.",
            "those subduction and fault mechanics problems need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your tectonics textbook.",
            "CLOSE THIS. those plate motion and geodynamics problems won't solve themselves.",
            "CLOSE THIS. your tectonics exam won't study itself."
        ]
        }
    }

    private func tribologyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that friction won't analyze itself.",
            "your tribology exam doesn't care that you're scrolling.",
            "get back to your tribology work.",
            "close this and open your tribology textbook.",
        ]
        case 2: return [
            "no one masters tribology by scrolling.",
            "close this and work on your tribology assignment.",
            "those wear rate and contact mechanics problems need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your tribology textbook.",
            "CLOSE THIS. those friction, wear, and lubrication problems won't solve themselves.",
            "CLOSE THIS. your tribology exam won't study itself."
        ]
        }
    }

    private func radiochemistryCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those radioactive tracers won't track themselves.",
            "your radiochemistry exam doesn't care that you're scrolling.",
            "get back to your radiochemistry work.",
            "close this and open your radiochemistry textbook.",
        ]
        case 2: return [
            "no one masters radiochemistry by scrolling.",
            "close this and work on your radiochemistry assignment.",
            "those isotope dating and radiolabeling problems need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your radiochemistry textbook.",
            "CLOSE THIS. those radiocarbon dating and radioactive tracer problems won't solve themselves.",
            "CLOSE THIS. your radiochemistry exam won't study itself."
        ]
        }
    }

    private func signalprocessingCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those fourier transforms won't solve themselves.",
            "no one learns dsp by scrolling.",
            "those filters aren't going to design themselves.",
            "you're supposed to be doing signal processing."
        ]
        case 2: return [
            "you know you have a dsp problem set due.",
            "those z-transforms are still waiting for you.",
            "go work on your signal processing."
        ]
        default: return [
            "CLOSE THIS. those fourier transforms and filter designs won't solve themselves.",
            "CLOSE THIS. your dsp problem set is not going to work itself out.",
            "CLOSE THIS. you have signal processing to do. do it."
        ]
        }
    }

    private func controlengineeringCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those pid tuning problems won't solve themselves.",
            "no one masters control systems by scrolling.",
            "that root locus isn't going to plot itself.",
            "you're supposed to be working on control engineering."
        ]
        case 2: return [
            "you know you have a control systems assignment due.",
            "those bode plots are still waiting for you.",
            "go work on your control engineering."
        ]
        default: return [
            "CLOSE THIS. those transfer functions and stability analyses won't solve themselves.",
            "CLOSE THIS. your control systems problem set is not going to work itself out.",
            "CLOSE THIS. you have control engineering to do. do it."
        ]
        }
    }

    private func aerostructuresCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that airframe structural analysis won't do itself.",
            "no one masters aerostructures by scrolling.",
            "those composite airframe problems are still sitting there.",
            "you're supposed to be working on aircraft structures."
        ]
        case 2: return [
            "you know you have an aerostructures assignment due.",
            "that shear flow analysis isn't going to solve itself.",
            "go work on your aircraft structures."
        ]
        default: return [
            "CLOSE THIS. those airframe and aeroelasticity problems won't solve themselves.",
            "CLOSE THIS. your aerostructures assignment is not going to do itself.",
            "CLOSE THIS. you have aircraft structures to work on. do it."
        ]
        }
    }

    private func optogeneticsCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those channelrhodopsin protocols won't write themselves.",
            "no one masters optogenetics by scrolling.",
            "that viral vector experiment isn't going to plan itself.",
            "you're supposed to be working on your optogenetics lab."
        ]
        case 2: return [
            "you know you have an optogenetics lab report due.",
            "those opsin expression protocols are still waiting.",
            "go work on your optogenetics."
        ]
        default: return [
            "CLOSE THIS. those viral vector and fiberoptic stimulation protocols won't write themselves.",
            "CLOSE THIS. your optogenetics lab report is not going to write itself.",
            "CLOSE THIS. you have optogenetics work to do. do it."
        ]
        }
    }

    private func demographyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those demographic tables won't analyze themselves.",
            "no one masters demography by scrolling.",
            "that population pyramid isn't going to build itself.",
            "you're supposed to be working on your demography assignment."
        ]
        case 2: return [
            "you know you have a demography problem set due.",
            "those life tables are still waiting for you.",
            "go work on your demography."
        ]
        default: return [
            "CLOSE THIS. those fertility rate and mortality table analyses won't do themselves.",
            "CLOSE THIS. your demography assignment is not going to work itself out.",
            "CLOSE THIS. you have demography work to do. do it."
        ]
        }
    }

    private func compositematerialsCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those composite laminate analyses won't solve themselves.",
            "no one masters composite materials by scrolling.",
            "that CLT problem set isn't going to finish itself.",
            "you're supposed to be working on your composite materials assignment."
        ]
        case 2: return [
            "you know you have a composite materials problem set due.",
            "those failure criteria problems are still waiting for you.",
            "go work on your composite materials."
        ]
        default: return [
            "CLOSE THIS. those CLT and failure criteria analyses won't do themselves.",
            "CLOSE THIS. your composite materials assignment is not going to work itself out.",
            "CLOSE THIS. you have composite materials work to do. do it."
        ]
        }
    }

    private func powerelectronicsCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those converter design problems won't solve themselves.",
            "no one masters power electronics by scrolling.",
            "that PWM analysis isn't going to finish itself.",
            "you're supposed to be working on your power electronics assignment."
        ]
        case 2: return [
            "you know you have a power electronics problem set due.",
            "those switching circuit analyses are still waiting for you.",
            "go work on your power electronics."
        ]
        default: return [
            "CLOSE THIS. those buck-boost converter and PWM analyses won't do themselves.",
            "CLOSE THIS. your power electronics assignment is not going to work itself out.",
            "CLOSE THIS. you have power electronics work to do. do it."
        ]
        }
    }

    private func geotechnicalengineeringCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those soil mechanics problems won't solve themselves.",
            "no one masters geotechnical engineering by scrolling.",
            "that foundation design analysis isn't going to finish itself.",
            "you're supposed to be working on your geotechnical engineering assignment."
        ]
        case 2: return [
            "you know you have a geotechnical engineering problem set due.",
            "those slope stability analyses are still waiting for you.",
            "go work on your geotechnical engineering."
        ]
        default: return [
            "CLOSE THIS. those foundation design and slope stability analyses won't do themselves.",
            "CLOSE THIS. your geotechnical engineering assignment is not going to work itself out.",
            "CLOSE THIS. you have geotechnical engineering work to do. do it."
        ]
        }
    }

    private func structuralanalysisCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those beam diagrams won't draw themselves.",
            "no one masters structural analysis by scrolling.",
            "that shear-moment diagram isn't going to finish itself.",
            "you're supposed to be working on your structural analysis problem set."
        ]
        case 2: return [
            "you know you have a structural analysis problem set due.",
            "those matrix stiffness problems are still waiting for you.",
            "go work on your structural analysis."
        ]
        default: return [
            "CLOSE THIS. those shear-moment diagrams and matrix stiffness problems won't solve themselves.",
            "CLOSE THIS. your structural analysis assignment is not going to work itself out.",
            "CLOSE THIS. you have structural analysis work to do. do it."
        ]
        }
    }

    private func miningengineeringCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those ore processing problems won't solve themselves.",
            "no one masters mining engineering by scrolling.",
            "that mine planning analysis isn't going to finish itself.",
            "you're supposed to be working on your mining engineering assignment."
        ]
        case 2: return [
            "you know you have a mining engineering problem set due.",
            "those rock mechanics analyses are still waiting for you.",
            "go work on your mining engineering."
        ]
        default: return [
            "CLOSE THIS. those mine planning and rock mechanics analyses won't do themselves.",
            "CLOSE THIS. your mining engineering assignment is not going to work itself out.",
            "CLOSE THIS. you have mining engineering work to do. do it."
        ]
        }
    }

    private func wastewatertreatmentCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those activated sludge calculations won't solve themselves.",
            "no one masters wastewater treatment by scrolling.",
            "that WWTP design problem is still sitting there waiting.",
            "you're supposed to be working on your wastewater treatment assignment."
        ]
        case 2: return [
            "you know you have a wastewater treatment problem set due.",
            "those biological nutrient removal analyses are still waiting for you.",
            "go work on your wastewater treatment."
        ]
        default: return [
            "CLOSE THIS. those activated sludge and membrane bioreactor problems won't do themselves.",
            "CLOSE THIS. your wastewater treatment assignment is not going to finish itself.",
            "CLOSE THIS. you have WWTP design work to do. do it."
        ]
        }
    }

    private func airpollutioncontrolCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those ESP and scrubber design problems won't solve themselves.",
            "no one masters air pollution control by scrolling.",
            "that NOx control analysis isn't going to finish itself.",
            "you're supposed to be working on your air pollution control assignment."
        ]
        case 2: return [
            "you know you have an air pollution control problem set due.",
            "those particulate matter control calculations are still waiting for you.",
            "go work on your air pollution control."
        ]
        default: return [
            "CLOSE THIS. those electrostatic precipitator and SCR design problems won't do themselves.",
            "CLOSE THIS. your air pollution control assignment is not going to work itself out.",
            "CLOSE THIS. you have air quality control work to do. do it."
        ]
        }
    }

    private func renewableenergyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those solar PV and wind turbine calculations won't solve themselves.",
            "no one masters renewable energy by scrolling.",
            "that grid integration analysis isn't going to finish itself.",
            "you're supposed to be working on your renewable energy assignment."
        ]
        case 2: return [
            "you know you have a renewable energy problem set due.",
            "those LCOE and energy storage analyses are still waiting for you.",
            "go work on your renewable energy."
        ]
        default: return [
            "CLOSE THIS. those solar PV and wind energy design problems won't do themselves.",
            "CLOSE THIS. your renewable energy assignment is not going to work itself out.",
            "CLOSE THIS. you have sustainable energy work to do. do it."
        ]
        }
    }

    private func navalarchitectureCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those ship stability and hull resistance problems won't solve themselves.",
            "no one masters naval architecture by scrolling.",
            "that ship design analysis isn't going to finish itself.",
            "you're supposed to be working on your naval architecture assignment."
        ]
        case 2: return [
            "you know you have a naval architecture problem set due.",
            "those metacentric height and resistance calculations are still waiting for you.",
            "go work on your naval architecture."
        ]
        default: return [
            "CLOSE THIS. those ship stability and hull design problems won't do themselves.",
            "CLOSE THIS. your naval architecture assignment is not going to work itself out.",
            "CLOSE THIS. you have ship design work to do. do it."
        ]
        }
    }

    private func mechatronicsCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those PLC programming and servo control problems won't solve themselves.",
            "no one masters mechatronics by scrolling.",
            "that motion control design isn't going to finish itself.",
            "you're supposed to be working on your mechatronics assignment."
        ]
        case 2: return [
            "you know you have a mechatronics problem set due.",
            "those sensors and actuators analyses are still waiting for you.",
            "go work on your mechatronics."
        ]
        default: return [
            "CLOSE THIS. those PLC programming and motion control problems won't do themselves.",
            "CLOSE THIS. your mechatronics assignment is not going to work itself out.",
            "CLOSE THIS. you have mechatronics design work to do. do it."
        ]
        }
    }

    private func structuraldynamicsCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those free vibration and mode shape problems won't solve themselves.",
            "your structural dynamics exam doesn't care that you're scrolling.",
            "get back to your structural dynamics work.",
            "close this and open your structural dynamics textbook.",
        ]
        case 2: return [
            "no one masters structural dynamics by scrolling.",
            "close this and work on your structural dynamics assignment.",
            "those natural frequency and response spectrum problems need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your structural dynamics textbook.",
            "CLOSE THIS. those MDOF systems and earthquake response spectra won't solve themselves.",
            "CLOSE THIS. your structural dynamics exam won't study itself."
        ]
        }
    }

    private func bioprocessengineeringCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those bioreactor design and fermentation kinetics won't work themselves out.",
            "your bioprocess engineering exam doesn't care that you're scrolling.",
            "get back to your bioprocess engineering work.",
            "close this and open your bioprocess engineering textbook.",
        ]
        case 2: return [
            "no one masters bioprocess engineering by scrolling.",
            "close this and work on your bioprocess assignment.",
            "those Monod kinetics and downstream processing problems need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your bioprocess engineering textbook.",
            "CLOSE THIS. those bioreactor scale-up and cell culture design problems won't solve themselves.",
            "CLOSE THIS. your bioprocess engineering exam won't study itself."
        ]
        }
    }

    private func systemsengineeringCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those MBSE models and requirements documents won't write themselves.",
            "your systems engineering exam doesn't care that you're scrolling.",
            "get back to your systems engineering work.",
            "close this and open your systems engineering textbook.",
        ]
        case 2: return [
            "no one masters systems engineering by scrolling.",
            "close this and work on your systems engineering assignment.",
            "those SysML diagrams and tradespace analyses need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your systems engineering textbook.",
            "CLOSE THIS. those V-model and requirements management problems won't solve themselves.",
            "CLOSE THIS. your systems engineering exam won't study itself."
        ]
        }
    }

    private func transportationplanningCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those travel demand models won't build themselves.",
            "your transportation planning exam doesn't care that you're scrolling.",
            "get back to your transportation planning work.",
            "close this and open your transportation planning textbook.",
        ]
        case 2: return [
            "no one masters transportation planning by scrolling.",
            "close this and work on your transportation planning assignment.",
            "those four-step models and traffic assignment problems need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your transportation planning textbook.",
            "CLOSE THIS. those trip generation and mode split problems won't solve themselves.",
            "CLOSE THIS. your transportation planning exam won't study itself."
        ]
        }
    }

    private func architecturalengineeringCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those building systems and HVAC design problems won't solve themselves.",
            "your architectural engineering exam doesn't care that you're scrolling.",
            "get back to your architectural engineering work.",
            "close this and open your architectural engineering textbook.",
        ]
        case 2: return [
            "no one masters architectural engineering by scrolling.",
            "close this and work on your architectural engineering assignment.",
            "those building envelope and MEP design problems need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your architectural engineering textbook.",
            "CLOSE THIS. those building energy analysis and structural systems problems won't solve themselves.",
            "CLOSE THIS. your architectural engineering exam won't study itself."
        ]
        }
    }

    private func environmentalhydrologyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those stormwater models and HEC-HMS runs won't set up themselves.",
            "your environmental hydrology exam doesn't care that you're scrolling.",
            "get back to your environmental hydrology work.",
            "close this and open your environmental hydrology textbook.",
        ]
        case 2: return [
            "no one masters environmental hydrology by scrolling.",
            "close this and work on your stormwater design assignment.",
            "those SCS curve number and detention pond calculations need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your environmental hydrology textbook.",
            "CLOSE THIS. those HEC-HMS and SWMM stormwater models won't run themselves.",
            "CLOSE THIS. your environmental hydrology exam won't study itself."
        ]
        }
    }

    private func geoenvironmentalengineeringCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those contaminant transport and remediation design problems won't solve themselves.",
            "your geoenvironmental engineering exam doesn't care that you're scrolling.",
            "get back to your geoenvironmental engineering work.",
            "close this and open your geoenvironmental engineering textbook.",
        ]
        case 2: return [
            "no one masters geoenvironmental engineering by scrolling.",
            "close this and work on your geoenvironmental engineering assignment.",
            "those groundwater contamination and landfill design problems need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your geoenvironmental engineering textbook.",
            "CLOSE THIS. those contaminant plume and soil vapor extraction problems won't solve themselves.",
            "CLOSE THIS. your geoenvironmental engineering exam won't study itself."
        ]
        }
    }

    private func earthquakeengineeringCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those seismic hazard and liquefaction problems won't solve themselves.",
            "your earthquake engineering exam doesn't care that you're scrolling.",
            "get back to your earthquake engineering work.",
            "close this and open your earthquake engineering textbook.",
        ]
        case 2: return [
            "no one masters earthquake engineering by scrolling.",
            "close this and work on your earthquake engineering assignment.",
            "those PSHA and ground motion prediction problems need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your earthquake engineering textbook.",
            "CLOSE THIS. those liquefaction potential and seismic hazard analyses won't solve themselves.",
            "CLOSE THIS. your earthquake engineering exam won't study itself."
        ]
        }
    }

    private func computationalstructuralmechanicsCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those FEA models and element stiffness matrices won't build themselves.",
            "your computational structural mechanics exam doesn't care that you're scrolling.",
            "get back to your finite element analysis work.",
            "close this and open your FEA textbook.",
        ]
        case 2: return [
            "no one masters finite element analysis by scrolling.",
            "close this and work on your FEA assignment.",
            "those ABAQUS models and nonlinear FEA problems need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your finite element analysis textbook.",
            "CLOSE THIS. those mesh generation and contact mechanics FEA problems won't solve themselves.",
            "CLOSE THIS. your computational structural mechanics exam won't study itself."
        ]
        }
    }

    private func coastalengineeringoceanCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those wave mechanics and coastal sediment transport problems won't solve themselves.",
            "your coastal engineering exam doesn't care that you're scrolling.",
            "get back to your coastal engineering work.",
            "close this and open your coastal engineering textbook.",
        ]
        case 2: return [
            "no one masters coastal engineering by scrolling.",
            "close this and work on your coastal engineering assignment.",
            "those breakwater design and beach nourishment calculations need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your coastal engineering textbook.",
            "CLOSE THIS. those wave runup and longshore transport calculations won't solve themselves.",
            "CLOSE THIS. your coastal engineering exam won't study itself."
        ]
        }
    }

    private func quantumfieldtheoryCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those Feynman diagrams and renormalization integrals won't do themselves.",
            "your QFT exam doesn't care that you're scrolling.",
            "get back to your quantum field theory work.",
            "close this and open your QFT textbook.",
        ]
        case 2: return [
            "no one masters quantum field theory by scrolling.",
            "close this and work on your QFT problem set.",
            "those path integrals and gauge invariance derivations need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your quantum field theory textbook.",
            "CLOSE THIS. those Feynman diagrams and renormalization group equations won't solve themselves.",
            "CLOSE THIS. your QFT exam won't study itself."
        ]
        }
    }

    private func rfengineeringCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those S-parameters and Smith chart problems won't solve themselves.",
            "your RF engineering exam doesn't care that you're scrolling.",
            "get back to your microwave engineering work.",
            "close this and open your RF engineering textbook.",
        ]
        case 2: return [
            "no one masters RF engineering by scrolling.",
            "close this and work on your microwave engineering assignment.",
            "those transmission line and impedance matching problems need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your RF engineering textbook.",
            "CLOSE THIS. those Smith chart and antenna design problems won't solve themselves.",
            "CLOSE THIS. your microwave engineering exam won't study itself."
        ]
        }
    }

    private func fluidmechanicsCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those pipe flow and boundary layer problems won't solve themselves.",
            "your fluid mechanics exam doesn't care that you're scrolling.",
            "get back to your fluid mechanics work.",
            "close this and open your fluid mechanics textbook.",
        ]
        case 2: return [
            "no one masters fluid mechanics by scrolling.",
            "close this and work on your fluid mechanics assignment.",
            "those Navier-Stokes and Moody chart problems need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your fluid mechanics textbook.",
            "CLOSE THIS. those Reynolds number and Bernoulli equation problems won't solve themselves.",
            "CLOSE THIS. your fluid mechanics exam won't study itself."
        ]
        }
    }

    private func heattransferCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those fin analysis and heat exchanger problems won't solve themselves.",
            "your heat transfer exam doesn't care that you're scrolling.",
            "get back to your heat transfer work.",
            "close this and open your heat transfer textbook.",
        ]
        case 2: return [
            "no one masters heat transfer by scrolling.",
            "close this and work on your heat transfer assignment.",
            "those LMTD and NTU-effectiveness problems need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your heat transfer textbook.",
            "CLOSE THIS. those Biot number and convection coefficient problems won't solve themselves.",
            "CLOSE THIS. your heat transfer exam won't study itself."
        ]
        }
    }

    private func powersystemsCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those load flow and fault analysis problems won't solve themselves.",
            "your power systems exam doesn't care that you're scrolling.",
            "get back to your power systems engineering work.",
            "close this and open your power systems textbook.",
        ]
        case 2: return [
            "no one masters power systems by scrolling.",
            "close this and work on your power systems assignment.",
            "those per-unit calculations and bus admittance problems need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your power systems textbook.",
            "CLOSE THIS. those load flow Newton-Raphson and symmetrical component problems won't solve themselves.",
            "CLOSE THIS. your power systems engineering exam won't study itself."
        ]
        }
    }

    private func nucleardynamicsCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those point kinetics and reactor transient problems won't solve themselves.",
            "your reactor dynamics exam doesn't care that you're scrolling.",
            "get back to your reactor dynamics work.",
            "close this and open your reactor dynamics textbook.",
        ]
        case 2: return [
            "no one masters reactor dynamics by scrolling.",
            "close this and work on your reactor dynamics assignment.",
            "those xenon oscillation and temperature feedback problems need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your reactor dynamics textbook.",
            "CLOSE THIS. those point kinetics and RELAP transient problems won't solve themselves.",
            "CLOSE THIS. your reactor dynamics exam won't study itself."
        ]
        }
    }

    private func additivemfgCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those FDM and powder bed fusion problems won't design themselves.",
            "your additive manufacturing exam doesn't care that you're scrolling.",
            "get back to your 3D printing and DFAM work.",
            "close this and open your additive manufacturing textbook.",
        ]
        case 2: return [
            "no one masters additive manufacturing by scrolling.",
            "close this and work on your additive manufacturing assignment.",
            "those SLA and selective laser sintering design problems need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your additive manufacturing textbook.",
            "CLOSE THIS. those FDM process parameters and DFAM problems won't solve themselves.",
            "CLOSE THIS. your additive manufacturing exam won't study itself."
        ]
        }
    }

    private func batterytechnologyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those Li-ion chemistry and SEI layer problems won't solve themselves.",
            "your battery technology exam doesn't care that you're scrolling.",
            "get back to your battery electrochemistry work.",
            "close this and open your battery technology textbook.",
        ]
        case 2: return [
            "no one masters battery technology by scrolling.",
            "close this and work on your battery technology assignment.",
            "those cathode material and EIS problems need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your battery technology textbook.",
            "CLOSE THIS. those Li-ion chemistry and cycle life problems won't solve themselves.",
            "CLOSE THIS. your battery technology exam won't study itself."
        ]
        }
    }

    private func semiconductordevicesCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those p-n junction and MOSFET device physics problems won't solve themselves.",
            "your semiconductor devices exam doesn't care that you're scrolling.",
            "get back to your semiconductor device physics work.",
            "close this and open your semiconductor devices textbook.",
        ]
        case 2: return [
            "no one masters semiconductor devices by scrolling.",
            "close this and work on your semiconductor devices assignment.",
            "those depletion approximation and BJT problems need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your semiconductor devices textbook.",
            "CLOSE THIS. those p-n junction I-V and MOSFET threshold voltage problems won't solve themselves.",
            "CLOSE THIS. your semiconductor devices exam won't study itself."
        ]
        }
    }

    private func vlsidesignCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those standard cell and place-and-route problems won't design themselves.",
            "your VLSI design exam doesn't care that you're scrolling.",
            "get back to your VLSI and CMOS design work.",
            "close this and open your VLSI design textbook.",
        ]
        case 2: return [
            "no one masters VLSI design by scrolling.",
            "close this and work on your VLSI design assignment.",
            "those static timing analysis and transistor sizing problems need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your VLSI design textbook.",
            "CLOSE THIS. those place-and-route and static timing analysis problems won't solve themselves.",
            "CLOSE THIS. your VLSI design exam won't study itself."
        ]
        }
    }

    private func spaceweatherCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those solar wind and geomagnetic storm problems won't solve themselves.",
            "your space weather exam doesn't care that you're scrolling.",
            "get back to your space weather assignment.",
            "close this and open your space weather textbook.",
        ]
        case 2: return [
            "no one masters space weather by scrolling.",
            "close this and work on your space weather problem set.",
            "those Kp index and CME impact models need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your space weather textbook.",
            "CLOSE THIS. those solar wind and magnetosphere coupling problems won't solve themselves.",
            "CLOSE THIS. your space weather exam won't study itself."
        ]
        }
    }

    private func nanophotonicsCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those plasmonics and near-field optics problems won't solve themselves.",
            "your nanophotonics exam doesn't care that you're scrolling.",
            "get back to your nanophotonics assignment.",
            "close this and open your nanophotonics textbook.",
        ]
        case 2: return [
            "no one masters nanophotonics by scrolling.",
            "close this and work on your nanophotonics problem set.",
            "those Mie scattering and photonic crystal problems need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your nanophotonics textbook.",
            "CLOSE THIS. those plasmonics and near-field optics problems won't solve themselves.",
            "CLOSE THIS. your nanophotonics exam won't study itself."
        ]
        }
    }

    private func microelectromechanicalsystemsCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those capacitive sensing and electrostatic actuation problems won't design themselves.",
            "your MEMS exam doesn't care that you're scrolling.",
            "get back to your MEMS fabrication assignment.",
            "close this and open your MEMS textbook.",
        ]
        case 2: return [
            "no one masters MEMS by scrolling.",
            "close this and work on your MEMS design problem.",
            "those microfabrication process flow and DRIE problems need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your MEMS textbook.",
            "CLOSE THIS. those capacitive sensing and piezoelectric transduction problems won't solve themselves.",
            "CLOSE THIS. your MEMS exam won't study itself."
        ]
        }
    }

    private func photovoltaicsenergyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those fill factor and short-circuit current problems won't solve themselves.",
            "your photovoltaics exam doesn't care that you're scrolling.",
            "get back to your solar cell design assignment.",
            "close this and open your photovoltaics textbook.",
        ]
        case 2: return [
            "no one masters photovoltaics by scrolling.",
            "close this and work on your solar cell problem set.",
            "those heterojunction and perovskite cell problems need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your photovoltaics textbook.",
            "CLOSE THIS. those fill factor and bandgap engineering problems won't solve themselves.",
            "CLOSE THIS. your photovoltaics exam won't study itself."
        ]
        }
    }

    private func biomechatronicsCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those EMG control and prosthetic design problems won't solve themselves.",
            "your biomechatronics exam doesn't care that you're scrolling.",
            "get back to your rehabilitation robotics assignment.",
            "close this and open your biomechatronics textbook.",
        ]
        case 2: return [
            "no one masters biomechatronics by scrolling.",
            "close this and work on your biomechatronics problem set.",
            "those neural interface and exoskeleton design problems need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your biomechatronics textbook.",
            "CLOSE THIS. those EMG control and prosthetic design problems won't solve themselves.",
            "CLOSE THIS. your biomechatronics exam won't study itself."
        ]
        }
    }

    private func condensedmatterphysicsCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those topological insulator and quantum Hall problems won't solve themselves.",
            "your condensed matter physics exam doesn't care that you're scrolling.",
            "get back to your Fermi liquid theory assignment.",
            "close this and open your condensed matter physics textbook.",
        ]
        case 2: return [
            "no one masters condensed matter by scrolling.",
            "close this and work on your condensed matter problem set.",
            "those Berry phase and Landau level problems need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your condensed matter physics textbook.",
            "CLOSE THIS. those topological insulator and Fermi liquid problems won't solve themselves.",
            "CLOSE THIS. your condensed matter physics exam won't study itself."
        ]
        }
    }

    private func energymaterialsCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those thermoelectric and electrocatalysis problems won't solve themselves.",
            "your energy materials exam doesn't care that you're scrolling.",
            "get back to your solid oxide fuel cell assignment.",
            "close this and open your energy materials textbook.",
        ]
        case 2: return [
            "no one masters energy materials by scrolling.",
            "close this and work on your energy materials problem set.",
            "those hydrogen storage and electrocatalysis problems need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your energy materials textbook.",
            "CLOSE THIS. those thermoelectric and fuel cell problems won't solve themselves.",
            "CLOSE THIS. your energy materials exam won't study itself."
        ]
        }
    }

    private func computationalneuroscienceCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those Hodgkin-Huxley and neural population model problems won't solve themselves.",
            "your computational neuroscience exam doesn't care that you're scrolling.",
            "get back to your spike train analysis assignment.",
            "close this and open your computational neuroscience textbook.",
        ]
        case 2: return [
            "no one masters computational neuroscience by scrolling.",
            "close this and work on your computational neuroscience problem set.",
            "those integrate-and-fire and connectome analysis problems need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your computational neuroscience textbook.",
            "CLOSE THIS. those Hodgkin-Huxley and reservoir computing problems won't solve themselves.",
            "CLOSE THIS. your computational neuroscience exam won't study itself."
        ]
        }
    }

    private func biophysicslabCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those patch clamp and FRET experiment problems won't solve themselves.",
            "your biophysics lab report doesn't care that you're scrolling.",
            "get back to your single-molecule fluorescence assignment.",
            "close this and open your experimental biophysics lab notebook.",
        ]
        case 2: return [
            "no one masters experimental biophysics by scrolling.",
            "close this and work on your biophysics lab report.",
            "those magnetic tweezers and super-resolution microscopy problems need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your biophysics lab notebook.",
            "CLOSE THIS. those patch clamp and FRET experiment problems won't solve themselves.",
            "CLOSE THIS. your biophysics lab report won't write itself."
        ]
        }
    }

    private func stochasticprocessesCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those Markov chain and Poisson process problems won't solve themselves.",
            "your stochastic processes exam doesn't care that you're scrolling.",
            "get back to your stochastic processes assignment.",
            "close this and open your stochastic processes textbook.",
        ]
        case 2: return [
            "no one masters stochastic processes by scrolling.",
            "close this and work on your stochastic processes problem set.",
            "those martingale and Brownian motion problems need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your stochastic processes textbook.",
            "CLOSE THIS. those Markov chain and Itô calculus problems won't solve themselves.",
            "CLOSE THIS. your stochastic processes exam won't study itself."
        ]
        }
    }

    private func solidmechanicsCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those stress-strain and Mohr's circle problems won't solve themselves.",
            "your solid mechanics exam doesn't care that you're scrolling.",
            "get back to your mechanics of materials assignment.",
            "close this and open your solid mechanics textbook.",
        ]
        case 2: return [
            "no one masters solid mechanics by scrolling.",
            "close this and work on your solid mechanics problem set.",
            "those fracture mechanics and yield criterion problems need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your solid mechanics textbook.",
            "CLOSE THIS. those Mohr's circle and von Mises stress problems won't solve themselves.",
            "CLOSE THIS. your solid mechanics exam won't study itself."
        ]
        }
    }

    private func opticalengineeringCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that lens design and aberration analysis won't do itself.",
            "your optical engineering exam doesn't care that you're scrolling.",
            "get back to your optical system design assignment.",
            "close this and open your optical engineering textbook.",
        ]
        case 2: return [
            "no one masters optical engineering by scrolling.",
            "close this and work on your optical design problem set.",
            "those Zemax layout and Zernike aberration problems need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your optical engineering textbook.",
            "CLOSE THIS. those wavefront sensing and interferometry problems won't solve themselves.",
            "CLOSE THIS. your optical engineering exam won't study itself."
        ]
        }
    }

    private func quantumchemistryCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those molecular orbital theory and Hartree-Fock problems won't solve themselves.",
            "your quantum chemistry exam doesn't care that you're scrolling.",
            "get back to your quantum chemistry assignment.",
            "close this and open your quantum chemistry textbook.",
        ]
        case 2: return [
            "no one masters quantum chemistry by scrolling.",
            "close this and work on your quantum chemistry problem set.",
            "those DFT and coupled cluster problems need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your quantum chemistry textbook.",
            "CLOSE THIS. those Hartree-Fock and basis set problems won't solve themselves.",
            "CLOSE THIS. your quantum chemistry exam won't study itself."
        ]
        }
    }

    private func surfacechemistryCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those adsorption isotherms and BET surface area problems won't solve themselves.",
            "your surface chemistry exam doesn't care that you're scrolling.",
            "get back to your surface science assignment.",
            "close this and open your surface chemistry textbook.",
        ]
        case 2: return [
            "no one masters surface chemistry by scrolling.",
            "close this and work on your surface chemistry problem set.",
            "those Langmuir-Hinshelwood and TPD desorption problems need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your surface chemistry textbook.",
            "CLOSE THIS. those adsorption isotherm and surface reconstruction problems won't solve themselves.",
            "CLOSE THIS. your surface chemistry exam won't study itself."
        ]
        }
    }

    private func quantumopticsCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those cavity QED and photon statistics problems won't solve themselves.",
            "your quantum optics exam doesn't care that you're scrolling.",
            "get back to your Jaynes-Cummings model and Wigner function derivations.",
            "close this and open your quantum optics textbook.",
        ]
        case 2: return [
            "no one masters quantum optics by scrolling.",
            "close this and work on your quantum optics problem set.",
            "those squeezed states and Hong-Ou-Mandel problems need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your quantum optics textbook.",
            "CLOSE THIS. those cavity QED and photon entanglement problems won't solve themselves.",
            "CLOSE THIS. your quantum optics exam won't study itself."
        ]
        }
    }

    private func marinechemistryCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those carbonate system and seawater composition problems won't solve themselves.",
            "your marine chemistry exam doesn't care that you're scrolling.",
            "get back to your ocean alkalinity and trace metal speciation work.",
            "close this and open your chemical oceanography textbook.",
        ]
        case 2: return [
            "no one masters marine chemistry by scrolling.",
            "close this and work on your marine chemistry problem set.",
            "those dissolved inorganic carbon and ocean acidification problems need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your marine chemistry textbook.",
            "CLOSE THIS. those carbonate system and trace metal problems won't solve themselves.",
            "CLOSE THIS. your marine chemistry exam won't study itself."
        ]
        }
    }

    private func bioinorganicchemistryCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those metalloenzyme and iron-sulfur cluster problems won't solve themselves.",
            "your bioinorganic chemistry exam doesn't care that you're scrolling.",
            "get back to your heme protein and oxygen transport mechanisms.",
            "close this and open your bioinorganic chemistry textbook.",
        ]
        case 2: return [
            "no one masters bioinorganic chemistry by scrolling.",
            "close this and work on your bioinorganic chemistry problem set.",
            "those nitrogenase and carbonic anhydrase problems need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your bioinorganic chemistry textbook.",
            "CLOSE THIS. those metalloenzyme and cisplatin problems won't solve themselves.",
            "CLOSE THIS. your bioinorganic chemistry exam won't study itself."
        ]
        }
    }

    private func informationtheoryCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those Shannon entropy and channel capacity problems won't solve themselves.",
            "your information theory exam doesn't care that you're scrolling.",
            "get back to your Huffman coding and mutual information derivations.",
            "close this and open your information theory textbook.",
        ]
        case 2: return [
            "no one masters information theory by scrolling.",
            "close this and work on your information theory problem set.",
            "those channel coding and rate-distortion problems need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your information theory textbook.",
            "CLOSE THIS. those channel capacity and source coding problems won't solve themselves.",
            "CLOSE THIS. your information theory exam won't study itself."
        ]
        }
    }

    private func mathematicalstatisticsCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those sufficiency and Cramér-Rao bound problems won't solve themselves.",
            "your mathematical statistics exam doesn't care that you're scrolling.",
            "get back to your Neyman-Pearson lemma and UMVUE derivations.",
            "close this and open your mathematical statistics textbook.",
        ]
        case 2: return [
            "no one masters mathematical statistics by scrolling.",
            "close this and work on your mathematical statistics problem set.",
            "those Fisher information and exponential family problems need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your mathematical statistics textbook.",
            "CLOSE THIS. those sufficiency and Rao-Blackwell problems won't solve themselves.",
            "CLOSE THIS. your mathematical statistics exam won't study itself."
        ]
        }
    }

    private func historicalgeologyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those geochronology and geologic time scale problems won't study themselves.",
            "your historical geology exam doesn't care that you're scrolling.",
            "get back to your Precambrian and Paleozoic era study notes.",
            "close this and open your historical geology textbook.",
        ]
        case 2: return [
            "no one masters historical geology by scrolling.",
            "close this and work on your historical geology problem set.",
            "those mass extinctions and paleogeography problems need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your historical geology textbook.",
            "CLOSE THIS. those geochronology and geologic time scale problems won't solve themselves.",
            "CLOSE THIS. your historical geology exam won't study itself."
        ]
        }
    }

    private func agriculturalchemistryCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those fertilizer chemistry and nutrient cycling problems won't solve themselves.",
            "your agricultural chemistry exam doesn't care that you're scrolling.",
            "get back to your pesticide chemistry and soil nutrient study notes.",
            "close this and open your agricultural chemistry textbook.",
        ]
        case 2: return [
            "no one masters agricultural chemistry by scrolling.",
            "close this and work on your agricultural chemistry problem set.",
            "those agrochemical and nitrogen fixation problems need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your agricultural chemistry textbook.",
            "CLOSE THIS. those fertilizer chemistry and soil nutrient problems won't solve themselves.",
            "CLOSE THIS. your agricultural chemistry exam won't study itself."
        ]
        }
    }

    private func digitalcommunicationsCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those BER analysis and OFDM modulation problems won't solve themselves.",
            "your digital communications exam doesn't care that you're scrolling.",
            "get back to your BPSK/QPSK and matched filter derivations.",
            "close this and open your digital communications textbook.",
        ]
        case 2: return [
            "no one masters digital communications by scrolling.",
            "close this and work on your digital communications problem set.",
            "those MIMO and channel coding problems need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your digital communications textbook.",
            "CLOSE THIS. those BER analysis and OFDM problems won't solve themselves.",
            "CLOSE THIS. your digital communications exam won't study itself."
        ]
        }
    }

    private func contractlawCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those offer-and-acceptance and promissory estoppel problems won't brief themselves.",
            "your contracts exam doesn't care that you're scrolling.",
            "get back to your UCC and breach of contract analysis.",
            "close this and open your contracts textbook.",
        ]
        case 2: return [
            "no one aces contracts by scrolling.",
            "close this and work on your contracts outline.",
            "those expectation damages and statute of frauds problems need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your contracts textbook.",
            "CLOSE THIS. those offer-and-acceptance and breach of contract problems won't brief themselves.",
            "CLOSE THIS. your contracts exam won't study itself."
        ]
        }
    }

    private func propertylawCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those future interests and rule against perpetuities problems won't brief themselves.",
            "your property exam doesn't care that you're scrolling.",
            "get back to your adverse possession and easement analysis.",
            "close this and open your property law textbook.",
        ]
        case 2: return [
            "no one aces property law by scrolling.",
            "close this and work on your property law outline.",
            "those fee simple and landlord-tenant problems need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your property law textbook.",
            "CLOSE THIS. those future interests and rule against perpetuities problems won't brief themselves.",
            "CLOSE THIS. your property exam won't study itself."
        ]
        }
    }

    private func metamaterialsCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those negative-index metamaterials and split-ring resonator problems won't solve themselves.",
            "your metamaterials exam doesn't care that you're scrolling.",
            "get back to your metasurface and transformation optics study notes.",
            "close this and open your metamaterials textbook.",
        ]
        case 2: return [
            "no one masters metamaterials by scrolling.",
            "close this and work on your metamaterials problem set.",
            "those effective medium theory and electromagnetic cloaking problems need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your metamaterials textbook.",
            "CLOSE THIS. those split-ring resonator and metasurface problems won't solve themselves.",
            "CLOSE THIS. your metamaterials exam won't study itself."
        ]
        }
    }

    private func nondestructivetestingCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those ultrasonic testing and eddy current problems won't solve themselves.",
            "your NDT exam doesn't care that you're scrolling.",
            "get back to your magnetic particle and dye penetrant study notes.",
            "close this and open your nondestructive testing textbook.",
        ]
        case 2: return [
            "no one masters NDT by scrolling.",
            "close this and work on your nondestructive testing problem set.",
            "those phased array ultrasound and radiographic testing problems need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your nondestructive testing textbook.",
            "CLOSE THIS. those ultrasonic testing and ASNT certification problems won't solve themselves.",
            "CLOSE THIS. your NDT exam won't study itself."
        ]
        }
    }

    private func optimalcontrolCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those Pontryagin maximum principle and LQR problems won't solve themselves.",
            "your optimal control exam doesn't care that you're scrolling.",
            "get back to your Hamilton-Jacobi-Bellman and Kalman filter study notes.",
            "close this and open your optimal control textbook.",
        ]
        case 2: return [
            "no one masters optimal control by scrolling.",
            "close this and work on your optimal control problem set.",
            "those Riccati equation and model predictive control problems need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your optimal control textbook.",
            "CLOSE THIS. those LQR and Hamilton-Jacobi-Bellman problems won't solve themselves.",
            "CLOSE THIS. your optimal control exam won't study itself."
        ]
        }
    }

    private func rocketpropulsionCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those specific impulse and Tsiolkovsky rocket equation problems won't solve themselves.",
            "your rocket propulsion exam doesn't care that you're scrolling.",
            "get back to your nozzle design and propellant chemistry study notes.",
            "close this and open your rocket propulsion textbook.",
        ]
        case 2: return [
            "no one masters rocket propulsion by scrolling.",
            "close this and work on your rocket propulsion problem set.",
            "those de Laval nozzle and thrust coefficient problems need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your rocket propulsion textbook.",
            "CLOSE THIS. those specific impulse and bipropellant combustion problems won't solve themselves.",
            "CLOSE THIS. your rocket propulsion exam won't study itself."
        ]
        }
    }

    private func reliabilityengineeringCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those MTBF and Weibull distribution problems won't solve themselves.",
            "your reliability engineering exam doesn't care that you're scrolling.",
            "get back to your FMEA and fault tree analysis study notes.",
            "close this and open your reliability engineering textbook.",
        ]
        case 2: return [
            "no one masters reliability engineering by scrolling.",
            "close this and work on your reliability engineering problem set.",
            "those bathtub curve and accelerated life testing problems need your focus now."
        ]
        default: return [
            "CLOSE THIS. open your reliability engineering textbook.",
            "CLOSE THIS. those Weibull analysis and FMEA problems won't solve themselves.",
            "CLOSE THIS. your reliability engineering exam won't study itself."
        ]
        }
    }

    private func measuretheoryCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "measure theory notes open? sigma-algebras and Lebesgue measure need your attention.",
            "those Radon-Nikodym and Fubini problems are waiting.",
            "your measure theory exam is coming — L^p spaces won't review themselves.",
            "hausdorff measure and outer measure problems: get back to them."
        ]
        case 2: return [
            "stop. your measure theory problem set is still open.",
            "sigma-algebras, measurable functions — your exam won't wait.",
            "measure theory class doesn't pause because you're distracted."
        ]
        default: return [
            "CLOSE THIS. open your measure theory textbook.",
            "CLOSE THIS. those Lebesgue integration and Carathéodory problems won't solve themselves.",
            "CLOSE THIS. your measure theory exam won't study itself."
        ]
        }
    }

    private func algebraictopologyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "algebraic topology notes open? fundamental groups and covering spaces need your focus.",
            "those homology group computations and Mayer-Vietoris problems are waiting.",
            "your algebraic topology exam is coming — CW complexes won't review themselves.",
            "seifert-van Kampen theorem and Betti numbers: get back to them."
        ]
        case 2: return [
            "stop. your algebraic topology problem set is still open.",
            "singular homology, cohomology — your exam won't wait.",
            "algebraic topology class doesn't pause because you're distracted."
        ]
        default: return [
            "CLOSE THIS. open your algebraic topology textbook.",
            "CLOSE THIS. those homology and homotopy problems won't solve themselves.",
            "CLOSE THIS. your algebraic topology exam won't study itself."
        ]
        }
    }

    private func numbertheoryCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "number theory notes open? Fermat's little theorem and quadratic residues need your focus.",
            "those Euler totient and Chinese remainder theorem problems are waiting.",
            "your number theory exam is coming — Legendre symbols won't review themselves.",
            "diophantine equations and quadratic reciprocity: get back to them."
        ]
        case 2: return [
            "stop. your number theory problem set is still open.",
            "primitive roots, multiplicative functions — your exam won't wait.",
            "number theory class doesn't pause because you're distracted."
        ]
        default: return [
            "CLOSE THIS. open your number theory textbook.",
            "CLOSE THIS. those prime factorization and modular arithmetic problems won't solve themselves.",
            "CLOSE THIS. your number theory exam won't study itself."
        ]
        }
    }

    private func orthopedicsrotationCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "ortho rotation notes still need writing — fracture management cases don't document themselves.",
            "your orthopedics shelf is approaching — MSK exam findings need review.",
            "those ortho case presentations won't write themselves — get back to them.",
            "joint replacement and sports medicine cases are waiting on your notes."
        ]
        case 2: return [
            "stop. your ortho rotation write-ups are still open.",
            "fracture cases, post-op notes — your attending is expecting them.",
            "orthopedics clerkship doesn't pause because you're distracted."
        ]
        default: return [
            "CLOSE THIS. open your orthopedics rotation notes.",
            "CLOSE THIS. those fracture management and MSK cases won't document themselves.",
            "CLOSE THIS. your orthopedics shelf won't study itself."
        ]
        }
    }

    private func cardiologyrotationCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "cardiology rotation notes still need writing — echo findings and cath results don't document themselves.",
            "your cardiology shelf is approaching — heart failure and arrhythmia management need review.",
            "those cardiology case presentations won't write themselves — get back to them.",
            "cath lab cases and EKG interpretation are waiting on your notes."
        ]
        case 2: return [
            "stop. your cardiology rotation write-ups are still open.",
            "echo reads, cath lab notes — your attending is expecting them.",
            "cardiology clerkship doesn't pause because you're distracted."
        ]
        default: return [
            "CLOSE THIS. open your cardiology rotation notes.",
            "CLOSE THIS. those echo and cath lab cases won't document themselves.",
            "CLOSE THIS. your cardiology shelf won't study itself."
        ]
        }
    }

    private func nephrologyrotationCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "nephrology rotation notes still need writing — AKI workup and CKD management plans don't document themselves.",
            "your nephrology shelf is approaching — dialysis indications and renal pathophysiology need review.",
            "those renal case presentations won't write themselves — get back to them.",
            "glomerulonephritis cases and electrolyte management are waiting on your notes."
        ]
        case 2: return [
            "stop. your nephrology rotation write-ups are still open.",
            "renal biopsy cases, dialysis notes — your attending is expecting them.",
            "nephrology clerkship doesn't pause because you're distracted."
        ]
        default: return [
            "CLOSE THIS. open your nephrology rotation notes.",
            "CLOSE THIS. those AKI and CKD management cases won't document themselves.",
            "CLOSE THIS. your nephrology shelf won't study itself."
        ]
        }
    }

    private func endocrinologyrotationCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "endocrinology rotation notes still need writing — thyroid and adrenal cases don't document themselves.",
            "your endocrinology shelf is approaching — diabetes management and hormone labs need review.",
            "those endocrine case presentations won't write themselves — get back to them.",
            "thyroid nodule workup and DM medication adjustment are waiting on your notes."
        ]
        case 2: return [
            "stop. your endocrinology rotation write-ups are still open.",
            "hormone lab results, endocrine tumor workup — your attending is expecting them.",
            "endocrinology clerkship doesn't pause because you're distracted."
        ]
        default: return [
            "CLOSE THIS. open your endocrinology rotation notes.",
            "CLOSE THIS. those thyroid and adrenal cases won't document themselves.",
            "CLOSE THIS. your endocrinology shelf won't study itself."
        ]
        }
    }

    private func hematologyoncologyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "heme/onc rotation notes still need writing — leukemia and lymphoma workups don't document themselves.",
            "your hematology oncology shelf is approaching — chemo regimens and bone marrow interpretation need review.",
            "those oncology case presentations won't write themselves — get back to them.",
            "bone marrow biopsy results and chemotherapy toxicity notes are waiting on your write-up."
        ]
        case 2: return [
            "stop. your heme/onc rotation notes are still open.",
            "leukemia staging, lymphoma regimens — your attending is expecting those notes.",
            "hematology oncology clerkship doesn't pause because you're distracted."
        ]
        default: return [
            "CLOSE THIS. open your heme/onc rotation notes.",
            "CLOSE THIS. those leukemia and lymphoma cases won't document themselves.",
            "CLOSE THIS. your hematology oncology shelf won't study itself."
        ]
        }
    }

    private func advancedlinearalgebraCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "advanced linear algebra isn't going to study itself — Jordan canonical form and spectral theorem are waiting.",
            "your advanced linear algebra exam is coming — dual spaces and bilinear forms need review.",
            "those tensor product and quadratic form problems are still open.",
            "Jordan normal form, matrix analysis — get back to your problem set."
        ]
        case 2: return [
            "stop. your advanced linear algebra assignment is still open.",
            "Jordan blocks, spectral theorem — your exam won't wait.",
            "advanced linear algebra class doesn't pause because you're distracted."
        ]
        default: return [
            "CLOSE THIS. open your advanced linear algebra textbook.",
            "CLOSE THIS. those Jordan canonical form and dual space problems won't solve themselves.",
            "CLOSE THIS. your advanced linear algebra exam won't study itself."
        ]
        }
    }

    private func riemanniangeometryCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "Riemannian geometry isn't going to study itself — geodesics and sectional curvature are waiting.",
            "your Riemannian geometry exam is coming — Levi-Civita connection and Gauss-Bonnet need review.",
            "those Ricci tensor and parallel transport problems are still open.",
            "Jacobi fields, Hopf-Rinow, comparison geometry — get back to your problem set."
        ]
        case 2: return [
            "stop. your Riemannian geometry assignment is still open.",
            "Riemannian metrics, geodesic completeness — your exam won't wait.",
            "Riemannian geometry class doesn't pause because you're distracted."
        ]
        default: return [
            "CLOSE THIS. open your Riemannian geometry textbook.",
            "CLOSE THIS. those geodesic and curvature tensor problems won't solve themselves.",
            "CLOSE THIS. your Riemannian geometry exam won't study itself."
        ]
        }
    }

    private func neurologyrotationCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "neurology rotation notes still need writing — stroke and seizure workups don't document themselves.",
            "your neurology shelf is approaching — neuroanatomy and neuro exam findings need review.",
            "those neurology case presentations won't write themselves — get back to them.",
            "EEG findings, lumbar puncture results, NIHSS documentation — waiting on your write-up."
        ]
        case 2: return [
            "stop. your neurology rotation notes are still open.",
            "stroke protocol, seizure workup, headache differential — your attending is expecting those notes.",
            "neurology clerkship doesn't pause because you're distracted."
        ]
        default: return [
            "CLOSE THIS. open your neurology rotation notes.",
            "CLOSE THIS. those stroke and seizure cases won't document themselves.",
            "CLOSE THIS. your neurology shelf won't study itself."
        ]
        }
    }

    private func surgicalpathologyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those gross specimens and histopathology slides aren't going to write themselves.",
            "your surgical path rotation — synoptic CAP reports, tumor grading, frozen section reads need documentation.",
            "sign-out is coming up and those surgical pathology notes are still open.",
            "grossing specimens, slide review, CAP protocol reports — get back to your write-ups."
        ]
        case 2: return [
            "stop. your surgical pathology rotation notes are still open.",
            "gross sections, histopath slides, tumor staging — your attending is expecting that sign-out.",
            "surgical pathology rotation doesn't pause because you're distracted."
        ]
        default: return [
            "CLOSE THIS. open your surgical pathology notes.",
            "CLOSE THIS. those gross specimens and frozen section reads won't document themselves.",
            "CLOSE THIS. your surgical pathology sign-out won't write itself."
        ]
        }
    }

    private func gametheoryCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "game theory isn't going to study itself — Nash equilibrium and dominant strategies are waiting.",
            "your game theory exam is approaching — mixed strategies, payoff matrices, Bayesian games need review.",
            "those prisoner's dilemma and mechanism design problems are still open.",
            "Nash equilibrium, auction theory, evolutionary games — get back to your problem set."
        ]
        case 2: return [
            "stop. your game theory assignment is still open.",
            "mixed strategy equilibria, extensive form games — your exam won't wait.",
            "game theory class doesn't pause because you're distracted."
        ]
        default: return [
            "CLOSE THIS. open your game theory textbook.",
            "CLOSE THIS. those Nash equilibrium and mechanism design problems won't solve themselves.",
            "CLOSE THIS. your game theory exam won't study itself."
        ]
        }
    }

    private func forensicchemistryCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "forensic chemistry isn't going to study itself — GC-MS drug analysis and trace evidence methods are waiting.",
            "your forensic chemistry exam is approaching — arson accelerant analysis and controlled substance identification need review.",
            "those forensic analytical chemistry problems and lab reports are still open.",
            "crime lab analytical methods, drug ID, trace evidence chemistry — get back to your assignment."
        ]
        case 2: return [
            "stop. your forensic chemistry assignment is still open.",
            "GC-MS analysis, arson chemistry, toxicological methods — your exam won't wait.",
            "forensic chemistry class doesn't pause because you're distracted."
        ]
        default: return [
            "CLOSE THIS. open your forensic chemistry textbook.",
            "CLOSE THIS. those crime lab analytical chemistry problems won't solve themselves.",
            "CLOSE THIS. your forensic chemistry exam won't study itself."
        ]
        }
    }

    private func neuropharmacologyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "neuropharmacology isn't going to study itself — CNS receptor mechanisms and drug targets are waiting.",
            "your neuropharmacology exam is approaching — dopamine, serotonin, GABA receptor pharmacology need review.",
            "those antidepressant, antipsychotic, and opioid mechanism problems are still open.",
            "SSRI/SNRI mechanisms, NMDA antagonists, anxiolytic pharmacology — get back to your problem set."
        ]
        case 2: return [
            "stop. your neuropharmacology assignment is still open.",
            "CNS drug mechanisms, receptor subtypes, neurotransmitter systems — your exam won't wait.",
            "neuropharmacology class doesn't pause because you're distracted."
        ]
        default: return [
            "CLOSE THIS. open your neuropharmacology textbook.",
            "CLOSE THIS. those CNS receptor mechanism and drug target problems won't solve themselves.",
            "CLOSE THIS. your neuropharmacology exam won't study itself."
        ]
        }
    }

    private func clinicaltoxicologyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "clinical toxicology rotation notes still need writing — toxidrome documentation and antidote protocols don't write themselves.",
            "your tox consult service notes are still open — overdose management and antidote decisions need documentation.",
            "those poison control center cases won't document themselves — get back to your clinical tox notes.",
            "toxidrome identification, antidote selection, decontamination protocols — your attending is expecting those consult notes."
        ]
        case 2: return [
            "stop. your clinical toxicology consult notes are still open.",
            "opioid/cholinergic/anticholinergic toxidrome, antidote protocols — your tox rotation notes won't write themselves.",
            "clinical toxicology rotation doesn't pause because you're distracted."
        ]
        default: return [
            "CLOSE THIS. open your clinical toxicology rotation notes.",
            "CLOSE THIS. those toxidrome and antidote consult notes won't document themselves.",
            "CLOSE THIS. your tox rotation notes won't write themselves."
        ]
        }
    }

    private func globalenvironmentalgovernanceCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "global environmental governance isn't going to study itself — CBD, CITES, UNCLOS, MEAs, and treaty compliance are waiting.",
            "your international environmental law exam is approaching — multilateral agreements, UNEP governance, and global commons need review.",
            "those international environmental treaty analysis papers are still open.",
            "Paris Agreement (climate), CBD (biodiversity), CITES (wildlife), Basel (hazardous waste) — get back to your MEA analysis."
        ]
        case 2: return [
            "stop. your international environmental governance assignment is still open.",
            "MEA compliance, UNEP governance, global commons — your exam won't wait.",
            "global environmental governance class doesn't pause because you're distracted."
        ]
        default: return [
            "CLOSE THIS. open your international environmental governance textbook.",
            "CLOSE THIS. those multilateral treaty analysis papers won't write themselves.",
            "CLOSE THIS. your global environmental governance exam won't study itself."
        ]
        }
    }

    private func corporatelawCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "corporate law isn't going to study itself — fiduciary duties, business judgment rule, and M&A structures are waiting.",
            "your corporate law exam is approaching — duty of care/loyalty, corporate governance, and securities regulation need review.",
            "those corporate law case briefs and business organizations problems are still open.",
            "Delaware corporate law, fiduciary duties, shareholder rights, M&A transactions — get back to your outline."
        ]
        case 2: return [
            "stop. your corporate law exam prep is still open.",
            "duty of loyalty, business judgment rule, corporate governance — your exam won't wait.",
            "corporate law class doesn't pause because you're distracted."
        ]
        default: return [
            "CLOSE THIS. open your corporate law textbook.",
            "CLOSE THIS. those fiduciary duty and M&A transaction problems won't solve themselves.",
            "CLOSE THIS. your corporate law exam won't study itself."
        ]
        }
    }

    private func taxlawCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "tax law isn't going to study itself — federal income tax, capital gains, deductions, and IRC sections are waiting.",
            "your tax law exam is approaching — gross income, exclusions, deductions, capital gains, and tax policy need review.",
            "those federal income tax analysis problems and IRC section questions are still open.",
            "IRC §61 gross income, §162 business deductions, capital gains characterization, progressive rates — get back to your outline."
        ]
        case 2: return [
            "stop. your tax law exam prep is still open.",
            "gross income inclusions, IRC deductions, capital gains rules — your exam won't wait.",
            "tax law class doesn't pause because you're distracted."
        ]
        default: return [
            "CLOSE THIS. open your tax law textbook.",
            "CLOSE THIS. those IRC code section analysis problems won't solve themselves.",
            "CLOSE THIS. your tax law exam won't study itself."
        ]
        }
    }

    private func administrativelawCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "administrative law isn't going to study itself — APA rulemaking, Chevron deference, and judicial review of agency action are waiting.",
            "your administrative law exam is approaching — notice-and-comment rulemaking, arbitrary-and-capricious review, and agency adjudication need review.",
            "those APA and agency judicial review case briefs are still open.",
            "Chevron deference, hard look review, informal rulemaking, nondelegation doctrine — get back to your admin law outline."
        ]
        case 2: return [
            "stop. your administrative law exam prep is still open.",
            "APA rulemaking, Chevron doctrine, arbitrary-and-capricious review — your exam won't wait.",
            "administrative law class doesn't pause because you're distracted."
        ]
        default: return [
            "CLOSE THIS. open your administrative law textbook.",
            "CLOSE THIS. those APA and agency adjudication analysis problems won't solve themselves.",
            "CLOSE THIS. your administrative law exam won't study itself."
        ]
        }
    }

    private func physicaltherapyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "your DPT program isn't going to complete itself — NPTE prep, clinical notes, and PT coursework are waiting.",
            "physical therapy clinical isn't paused — musculoskeletal, neuro, and cardiopulmonary practice still need your attention.",
            "those PT SOAP notes and clinical documentation won't write themselves.",
            "NPTE board exam, PT clinical rotation, DPT coursework — get back to your physical therapy studies."
        ]
        case 2: return [
            "stop. your PT clinical notes and DPT coursework are still open.",
            "NPTE prep, PT SOAP documentation, clinical decision-making — your exam and CI won't wait.",
            "DPT program doesn't pause because you're distracted."
        ]
        default: return [
            "CLOSE THIS. open your physical therapy textbook or clinical notes.",
            "CLOSE THIS. those PT SOAP notes and NPTE practice questions won't complete themselves.",
            "CLOSE THIS. your DPT coursework won't study itself."
        ]
        }
    }

    private func medicalspanishCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "your medical Spanish assignment isn't going to finish itself — clinical vocabulary, patient history phrases, and OSCE prep are waiting.",
            "medical Spanish class doesn't wait — clinical terms, symptom descriptions, and patient communication practice are still open.",
            "those medical interpreter certification materials and clinical Spanish exercises are still open.",
            "CCHI exam prep, clinical vocabulary, patient-history phrases in Spanish — get back to your medical Spanish coursework."
        ]
        case 2: return [
            "stop. your medical Spanish assignment and clinical vocabulary practice are still open.",
            "medical interpreter certification, clinical vocabulary, OSCE in Spanish — your exam won't wait.",
            "medical Spanish class doesn't pause because you're distracted."
        ]
        default: return [
            "CLOSE THIS. open your medical Spanish textbook or clinical vocabulary notes.",
            "CLOSE THIS. those clinical vocabulary flashcards and patient-history phrases won't review themselves.",
            "CLOSE THIS. your medical Spanish exam won't study itself."
        ]
        }
    }

    private func musicologyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "your musicology paper isn't going to write itself — analytical frameworks, primary sources, and music historiography are waiting.",
            "ethnomusicology fieldwork, music history dissertation, and AMS paper — your academic music research won't do itself.",
            "those musicology seminar readings and analytical essays are still open.",
            "music historiography, organology, popular music studies, ethnomusicology theory — get back to your musicology coursework."
        ]
        case 2: return [
            "stop. your musicology paper and seminar readings are still open.",
            "music history dissertation, ethnomusicology analysis, AMS conference deadline — your research won't wait.",
            "musicology program doesn't pause because you're distracted."
        ]
        default: return [
            "CLOSE THIS. open your musicology textbook or research notes.",
            "CLOSE THIS. those musicology analytical essays and primary sources won't review themselves.",
            "CLOSE THIS. your musicology dissertation chapter won't write itself."
        ]
        }
    }

    private func patientadvocacyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "your patient advocacy coursework isn't going to complete itself — care navigation, patient rights, and BCPA certification prep are waiting.",
            "patient advocacy class doesn't wait — healthcare navigation, discharge planning, and patient rights exercises are still open.",
            "those patient advocacy case studies and healthcare navigation scenarios are still open.",
            "BCPA exam prep, care coordination, patient rights advocacy — get back to your patient advocacy coursework."
        ]
        case 2: return [
            "stop. your patient advocacy assignment and BCPA prep materials are still open.",
            "BCPA certification, care navigation, patient rights — your exam won't wait.",
            "patient advocacy program doesn't pause because you're distracted."
        ]
        default: return [
            "CLOSE THIS. open your patient advocacy textbook or case study notes.",
            "CLOSE THIS. those patient advocacy case studies and BCPA practice questions won't complete themselves.",
            "CLOSE THIS. your patient advocacy certification exam won't study itself."
        ]
        }
    }

    private func animallawCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "animal law isn't going to study itself — AWA litigation, anti-cruelty statutes, and animal rights legal theory are waiting.",
            "your animal law exam is approaching — standing for animals, legal personhood, factory farming law, and wildlife trafficking need review.",
            "those animal law case briefs and AWA analysis problems are still open.",
            "anti-cruelty statutes, legal personhood for animals, AWA compliance, animal law clinic — get back to your animal law coursework."
        ]
        case 2: return [
            "stop. your animal law exam prep and clinic casefile are still open.",
            "AWA litigation, animal rights legal theory, anti-cruelty statutes — your exam won't wait.",
            "animal law class doesn't pause because you're distracted."
        ]
        default: return [
            "CLOSE THIS. open your animal law casebook.",
            "CLOSE THIS. those AWA analysis problems and animal law case briefs won't write themselves.",
            "CLOSE THIS. your animal law exam won't study itself."
        ]
        }
    }

    private func computationallinguisticsCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "computational linguistics isn't going to study itself — CKY parsing, PCFGs, formal grammar, and dependency parsing are waiting.",
            "your computational linguistics exam is approaching — context-free grammars, Earley algorithm, formal semantics, and parsing complexity need review.",
            "those computational linguistics problem sets and formal grammar proofs are still open.",
            "CKY/Earley parsing, probabilistic CFGs, lambda semantics, minimalist syntax — get back to your computational linguistics coursework."
        ]
        case 2: return [
            "stop. your computational linguistics exam and parsing assignment are still open.",
            "formal grammars, PCFGs, dependency parsing, computational semantics — your exam won't wait.",
            "computational linguistics class doesn't pause because you're distracted."
        ]
        default: return [
            "CLOSE THIS. open your computational linguistics textbook or problem set.",
            "CLOSE THIS. those parsing proofs and formal grammar exercises won't complete themselves.",
            "CLOSE THIS. your computational linguistics exam won't study itself."
        ]
        }
    }

    private func sociolinguisticsCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "sociolinguistics isn't going to study itself — language variation, dialectology, code-switching, and language policy are waiting.",
            "your sociolinguistics exam is approaching — variationist methods, Labovian fieldwork, pidgins, creoles, and linguistic landscape need review.",
            "those sociolinguistics analysis exercises and language variation assignments are still open.",
            "code-switching, speech communities, register variation, language contact — get back to your sociolinguistics coursework."
        ]
        case 2: return [
            "stop. your sociolinguistics exam and language variation analysis are still open.",
            "dialectology, language policy, sociolects, variationist linguistics — your exam won't wait.",
            "sociolinguistics class doesn't pause because you're distracted."
        ]
        default: return [
            "CLOSE THIS. open your sociolinguistics textbook or field data.",
            "CLOSE THIS. those language variation exercises and dialect analysis problems won't complete themselves.",
            "CLOSE THIS. your sociolinguistics exam won't study itself."
        ]
        }
    }

    private func agroecologyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "agroecology isn't going to study itself — agroforestry design, agroecosystem analysis, sustainable farming systems, and permaculture principles are waiting.",
            "your agroecology exam is approaching — food systems ecology, polyculture farming, integrated pest management, and soil ecology need review.",
            "those agroecology problem sets and agroforestry design assignments are still open.",
            "agroforestry, regenerative agriculture, crop ecology, soil biology — get back to your agroecology coursework."
        ]
        case 2: return [
            "stop. your agroecology exam and sustainable farming systems assignment are still open.",
            "agroforestry, permaculture design, food systems ecology, soil ecology — your exam won't wait.",
            "agroecology class doesn't pause because you're distracted."
        ]
        default: return [
            "CLOSE THIS. open your agroecology textbook or field assignment.",
            "CLOSE THIS. those agroforestry design problems and agroecosystem analyses won't complete themselves.",
            "CLOSE THIS. your agroecology exam won't study itself."
        ]
        }
    }

    private func forensicengineeringCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "forensic engineering isn't going to study itself — failure analysis, root cause investigation, product liability, and expert witness reports are waiting.",
            "your forensic engineering exam is approaching — structural failure modes, FMEA, fracture mechanics, and accident reconstruction need review.",
            "that forensic engineering failure analysis report and root cause documentation are still open.",
            "failure mode analysis, structural failure investigation, product liability engineering, expert witness report — get back to your forensic engineering work."
        ]
        case 2: return [
            "stop. your forensic engineering exam and failure analysis assignment are still open.",
            "FMEA, root cause analysis, structural failure, product liability engineering — your exam won't wait.",
            "forensic engineering class doesn't pause because you're distracted."
        ]
        default: return [
            "CLOSE THIS. open your forensic engineering textbook or failure analysis case.",
            "CLOSE THIS. that failure analysis investigation and expert witness report won't write themselves.",
            "CLOSE THIS. your forensic engineering exam won't study itself."
        ]
        }
    }

    private func healthlawCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "health law isn't going to study itself — HIPAA privacy rule, FDA regulatory law, ACA litigation, and healthcare compliance are waiting.",
            "your health law exam is approaching — Medicare/Medicaid law, informed consent doctrine, EMTALA, and healthcare antitrust need review.",
            "those health law case briefs and HIPAA compliance memos are still open.",
            "HIPAA law, FDA drug regulation, ACA structure, Medicare/Medicaid — get back to your health law coursework."
        ]
        case 2: return [
            "stop. your health law exam prep and healthcare compliance memo are still open.",
            "HIPAA privacy rule, FDA regulatory framework, ACA litigation, healthcare antitrust — your exam won't wait.",
            "health law class doesn't pause because you're distracted."
        ]
        default: return [
            "CLOSE THIS. open your health law casebook or HIPAA outline.",
            "CLOSE THIS. those health law case briefs and FDA regulatory memos won't write themselves.",
            "CLOSE THIS. your health law exam won't study itself."
        ]
        }
    }

    private func deepseabiologyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "deep-sea biology doesn't study itself — hydrothermal vent ecology, cold seep communities, chemosynthesis, and hadal zone adaptations are all waiting.",
            "your deep-sea biology exam needs you — chemosynthetic bacteria, tubeworm symbiosis, abyssal zone food webs, and bioluminescence mechanisms won't memorize themselves.",
            "those deep-sea biology notes and hadal trench ecology assignments are still open.",
            "hydrothermal vents, cold seeps, marine snow, mesopelagic zones — get back to your deep-sea biology coursework."
        ]
        case 2: return [
            "stop. your deep-sea biology exam prep and lab report are still open.",
            "chemosynthesis, tubeworms, hadal trenches, pressure adaptation — your exam won't wait.",
            "deep-sea biology class doesn't pause because you're distracted."
        ]
        default: return [
            "CLOSE THIS. open your deep-sea biology notes or vent ecology textbook.",
            "CLOSE THIS. those chemosynthesis and cold seep community analyses won't write themselves.",
            "CLOSE THIS. your hadal zone biology exam won't study itself."
        ]
        }
    }

    private func constructionestimatingCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "construction estimating doesn't complete itself — quantity takeoffs, RSMeans unit prices, CSI divisions, and bid preparation are all waiting.",
            "your estimating exam needs you — material takeoffs, MasterFormat divisions, overhead and profit, and subcontractor bid review won't memorize themselves.",
            "those cost estimate spreadsheets and quantity takeoff assignments are still open.",
            "RSMeans, quantity takeoff, bid writing, unit price estimating — get back to your construction estimating coursework."
        ]
        case 2: return [
            "stop. your construction estimating exam and takeoff assignment are still open.",
            "quantity takeoff, RSMeans pricing, CSI divisions, bid preparation — your exam won't wait.",
            "estimating class doesn't pause because you're distracted."
        ]
        default: return [
            "CLOSE THIS. open your estimating notes or RSMeans manual.",
            "CLOSE THIS. those quantity takeoffs and bid worksheets won't complete themselves.",
            "CLOSE THIS. your construction estimating exam won't study itself."
        ]
        }
    }

    private func internationallawCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "international law doesn't study itself — VCLT treaty interpretation, state responsibility, jus cogens, UNCLOS, and ICJ jurisprudence are all waiting.",
            "your public international law exam needs you — sovereign immunity, customary international law, UN Charter obligations, and IHL won't memorize themselves.",
            "those PIL case briefs and treaty analysis assignments are still open.",
            "ICJ, VCLT, UNCLOS, state responsibility — get back to your international law coursework."
        ]
        case 2: return [
            "stop. your international law exam and PIL case brief are still open.",
            "jus cogens, VCLT, sovereign immunity, customary international law — your exam won't wait.",
            "international law class doesn't pause because you're distracted."
        ]
        default: return [
            "CLOSE THIS. open your PIL casebook or VCLT treaty law outline.",
            "CLOSE THIS. those ICJ case briefs and state responsibility memos won't write themselves.",
            "CLOSE THIS. your international law exam won't study itself."
        ]
        }
    }

    private func urbansociologyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "urban sociology doesn't study itself — gentrification, neighborhood effects, residential segregation, collective efficacy, and urban inequality are all waiting.",
            "your urban sociology exam needs you — Chicago school theory, social disorganization, concentrated disadvantage, and urban ethnography won't memorize themselves.",
            "those urban sociology case studies and neighborhood effects papers are still open.",
            "gentrification, displacement, urban inequality, right to the city — get back to your urban sociology coursework."
        ]
        case 2: return [
            "stop. your urban sociology exam and ethnography assignment are still open.",
            "gentrification, residential segregation, collective efficacy, Chicago school — your exam won't wait.",
            "urban sociology class doesn't pause because you're distracted."
        ]
        default: return [
            "CLOSE THIS. open your urban sociology textbook or neighborhood effects readings.",
            "CLOSE THIS. those gentrification and urban inequality analyses won't write themselves.",
            "CLOSE THIS. your urban sociology exam won't study itself."
        ]
        }
    }

    private func politicalsociologyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "political sociology doesn't study itself — social movement theory, state power, hegemony, resource mobilization, and collective action are all waiting.",
            "your political sociology exam needs you — Gramsci, power elite theory, political opportunity structure, and class struggle won't memorize themselves.",
            "those political sociology papers and social movement analysis assignments are still open.",
            "state theory, hegemony, social movements, ruling class — get back to your political sociology coursework."
        ]
        case 2: return [
            "stop. your political sociology exam and social movement analysis are still open.",
            "resource mobilization, political opportunity structure, Gramsci, state theory — your exam won't wait.",
            "political sociology class doesn't pause because you're distracted."
        ]
        default: return [
            "CLOSE THIS. open your political sociology textbook or social movements readings.",
            "CLOSE THIS. those hegemony theory and collective action analyses won't write themselves.",
            "CLOSE THIS. your political sociology exam won't study itself."
        ]
        }
    }

    private func environmentaleconomicsCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "environmental economics doesn't study itself — Pigouvian taxes, Coase theorem, ecosystem services valuation, cap-and-trade, and benefit-cost analysis are all waiting.",
            "your environmental economics exam needs you — externalities, market failure, contingent valuation, willingness to pay, and tragedy of the commons won't memorize themselves.",
            "those environmental economics problem sets and natural resource economics assignments are still open.",
            "pigouvian tax, coase theorem, hedonic pricing, ecosystem services — get back to your environmental economics coursework."
        ]
        case 2: return [
            "stop. your environmental economics exam and valuation assignment are still open.",
            "externalities, pigouvian tax, coase theorem, cap-and-trade economics — your exam won't wait.",
            "environmental economics class doesn't pause because you're distracted."
        ]
        default: return [
            "CLOSE THIS. open your environmental economics textbook or valuation problem set.",
            "CLOSE THIS. those ecosystem services valuation and pollution externality analyses won't complete themselves.",
            "CLOSE THIS. your environmental economics exam won't study itself."
        ]
        }
    }

    private func socialepigeneticsCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "epigenetics doesn't study itself — DNA methylation, histone modifications, chromatin remodeling, stress-induced epigenetic changes, and intergenerational inheritance are all waiting.",
            "your epigenetics exam needs you — bisulfite sequencing, ChIP-seq, epigenetic clocks, early adversity and gene expression, and social genomics won't memorize themselves.",
            "those epigenetics lab reports and social epigenetics assignments are still open.",
            "methylation analysis, transgenerational epigenetics, gene-environment interactions, chromatin remodeling — get back to your epigenetics coursework."
        ]
        case 2: return [
            "stop. your epigenetics exam and methylation analysis assignment are still open.",
            "histone modifications, dna methylation, bisulfite sequencing, epigenetic inheritance — your exam won't wait.",
            "epigenetics class doesn't pause because you're distracted."
        ]
        default: return [
            "CLOSE THIS. open your epigenetics textbook or chromatin remodeling lab notes.",
            "CLOSE THIS. those methylation analysis and intergenerational epigenetics assignments won't complete themselves.",
            "CLOSE THIS. your epigenetics exam won't study itself."
        ]
        }
    }

    private func behavioralneuroscienceCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "behavioral neuroscience doesn't run itself — your fear conditioning lab, Morris water maze protocol, elevated plus maze analysis, and open field test data are all waiting.",
            "your behavioral neuroscience lab report needs you — conditioned place preference, stereotaxic coordinates, reward circuit data, and rodent behavior scoring won't write themselves.",
            "those behavioral neuroscience lab reports and animal model assignments are still open.",
            "fear conditioning, Morris water maze, elevated plus maze, stereotaxic surgery — get back to your behavioral neuroscience lab."
        ]
        case 2: return [
            "stop. your behavioral neuroscience lab report and open field test analysis are still open.",
            "conditioned place preference, forced swim test, Barnes maze, reward circuit data — your lab won't finish itself.",
            "behavioral neuroscience lab doesn't pause because you're distracted."
        ]
        default: return [
            "CLOSE THIS. open your behavioral neuroscience lab notebook or fear conditioning data.",
            "CLOSE THIS. those rodent behavior analysis and stereotaxic surgery reports won't write themselves.",
            "CLOSE THIS. your behavioral neuroscience lab report won't finish itself."
        ]
        }
    }

    private func medicalethicsCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "medical ethics doesn't study itself — Beauchamp and Childress, the four principles (autonomy, beneficence, nonmaleficence, justice), informed consent, and end-of-life decision-making are all waiting.",
            "your medical ethics exam needs you — principlism, the Hippocratic oath, medical futility, resource allocation, and the doctor-patient relationship won't memorize themselves.",
            "those medical ethics papers and clinical ethics case analyses are still open.",
            "four principles of biomedical ethics, Beauchamp and Childress, principlism, clinical ethics consultation — get back to your medical ethics coursework."
        ]
        case 2: return [
            "stop. your medical ethics exam and case analysis are still open.",
            "autonomy, beneficence, nonmaleficence, justice — your exam won't wait.",
            "medical ethics class doesn't pause because you're distracted."
        ]
        default: return [
            "CLOSE THIS. open your medical ethics textbook or Beauchamp and Childress notes.",
            "CLOSE THIS. those four-principles analyses and clinical ethics case studies won't write themselves.",
            "CLOSE THIS. your medical ethics exam won't study itself."
        ]
        }
    }

    private func lawandeconomicsCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "law and economics doesn't study itself — Coase theorem, efficient breach, Posner, Calabresi, Kaldor-Hicks efficiency, and optimal deterrence theory are all waiting.",
            "your law and economics exam needs you — transaction costs, pareto efficiency, economic analysis of tort law, and the Learned Hand formula won't memorize themselves.",
            "those law and economics papers and economic analysis of law assignments are still open.",
            "efficient breach, coase theorem, calabresi, posner — get back to your law and economics coursework."
        ]
        case 2: return [
            "stop. your law and economics exam and economic analysis paper are still open.",
            "coase theorem, efficient breach, kaldor-hicks, optimal deterrence — your exam won't wait.",
            "law and economics class doesn't pause because you're distracted."
        ]
        default: return [
            "CLOSE THIS. open your law and economics textbook or Posner casebook.",
            "CLOSE THIS. those economic analysis of tort and contract law assignments won't complete themselves.",
            "CLOSE THIS. your law and economics exam won't study itself."
        ]
        }
    }

}
