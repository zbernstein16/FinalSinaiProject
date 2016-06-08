//
//  File.swift
//  TestCareKit
//
//  Created by Zachary Bernstein on 5/13/16.
//  Copyright © 2016 Zachary Bernstein. All rights reserved.

import ResearchKit
import UIKit

/*
 This file creates a public Consent Document (ORKConsentDocument) which whill be added to an ORKTask to present the survey to the user.
*/

public var ConsentDocument: ORKConsentDocument {

    let consentDocument = ORKConsentDocument()
    consentDocument.title = "Consent Form"
    
    //Consent Sections
    let consentSectionTypes: [ORKConsentSectionType] = [
        .Overview,
        .DataGathering,
        .Privacy,
        .DataUse,
        .TimeCommitment,
        .StudySurvey,
        .StudyTasks,
        .Withdrawing
    ]
    
    
    //Turns Wanted types into actual ORKConsentSections
    //TODO: Split these up into individual cases
    /*
 
     let privacySection = ORKConsentSection(type: .Privacy)
     privacySection.summary = "In this study, none of your data will be shared with any third party."
     privacySection.content = "
 
 
    */
    let consentSections: [ORKConsentSection] = consentSectionTypes.map { contentSectionType in
        let consentSection = ORKConsentSection(type: contentSectionType)
        consentSection.summary = "If you wish to complete this study..."
        consentSection.content = "In this study you will be asked to submit data"
        return consentSection
    }
    
    consentDocument.sections = consentSections
    //Signature
    consentDocument.addSignature(ORKConsentSignature(forPersonWithTitle: "Patient", dateFormatString: nil, identifier: "ConsentDocumentParticipantSignature"))
   
    
    return consentDocument



}