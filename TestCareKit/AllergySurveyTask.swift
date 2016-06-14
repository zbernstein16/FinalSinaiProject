//
//  AllergySurveyTask.swift
//  CustomModuleTestProject
//
//  Created by Zachary Bernstein on 6/13/16.
//  Copyright © 2016 Zachary Bernstein. All rights reserved.
//

import Foundation
import ResearchKit
class AllergySurveyTask: NSObject, ORKTask {
    let storeManager = CarePlanStoreManager.sharedCarePlanStoreManager
    let introStepID = "intro_step"
    let causeStepID = "cause_step"
    let nameStepID = "name_step"
    let questStepID = "quest_step"
    let colorStepID = "color_step"
    let summaryStepID = "summary_step"
    var steps:[ORKStep] = [];
    var identifier: String {
        get { return "survey"}
    }
    override init()
    {
        super.init()
        let instructionStep = ORKInstructionStep(identifier: introStepID)
        instructionStep.title = "The Questions Three"
        instructionStep.text = "Who would cross the Bridge of Death must answer me these questions three, ere the other side they see."
        self.steps.append(instructionStep);
        
        let textChoices = [ORKTextChoice(text: "Infectious illness", detailText: "(such as cold, stomach flu, virus, fever, etc.)", value: 0, exclusive: false),ORKTextChoice(text: "Exercise/physical activity", value: 1),ORKTextChoice(text: "Menses", value: 3)]
        let causeStep = ORKQuestionStep(identifier: causeStepID, title: "Did any of the following occur around the time of the reaction? Check if applicable.", answer: ORKAnswerFormat.choiceAnswerFormatWithStyle(ORKChoiceAnswerStyle.MultipleChoice, textChoices:textChoices));
        
        self.steps.append(causeStep);
        
        let nameAnswerFormat = ORKTextAnswerFormat(maximumLength: 20)
        nameAnswerFormat.multipleLines = false
        let nameQuestionStepTitle = "What is your name?"
        self.steps.append(ORKQuestionStep(identifier: nameStepID, title: nameQuestionStepTitle, answer: nameAnswerFormat))
    }
    func stepWithIdentifier(identifier: String) -> ORKStep? {
        switch identifier {
            
        case introStepID:
            return steps[0];
        case causeStepID:
            return steps[1];
        case nameStepID:
            return steps[2];
            
        case questStepID:
            return questStep("")
            
        case colorStepID:
            let colorQuestionStepTitle = "What is your favorite color?"
            let colorTuples = [
                (UIImage(named: "red")!, "Red"),
                (UIImage(named: "orange")!, "Orange"),
                (UIImage(named: "yellow")!, "Yellow"),
                (UIImage(named: "green")!, "Green"),
                (UIImage(named: "blue")!, "Blue"),
                (UIImage(named: "purple")!, "Purple")
            ]
            var imageChoices:[ORKImageChoice] = []
            for (image, name) in colorTuples {
                imageChoices.append(ORKImageChoice(normalImage: image, selectedImage: nil, text: name, value: name))
            }
            let colorAnswerFormat: ORKImageChoiceAnswerFormat = ORKAnswerFormat.choiceAnswerFormatWithImageChoices(imageChoices)
            return ORKQuestionStep(identifier: colorStepID, title: colorQuestionStepTitle, answer: colorAnswerFormat)
            
        case summaryStepID:
            let summaryStep = ORKCompletionStep(identifier: "SummaryStep")
            summaryStep.title = "Right. Off you go!"
            summaryStep.text = "That was easy!"
            return summaryStep
            
        default:
            return nil
        }
    }
    func stepBeforeStep(step: ORKStep?, withResult result: ORKTaskResult) -> ORKStep? {
        
        
        return nil
    }
    
    func stepAfterStep(step: ORKStep?, withResult result: ORKTaskResult) -> ORKStep? {
        
        switch step?.identifier {
        case .None:
            return stepWithIdentifier(introStepID)
            
        case .Some(introStepID):
            return stepWithIdentifier(causeStepID)
            
        case .Some(nameStepID):
            //If result is something
            return questStep(findName(result))
            
        case .Some(questStepID):
            return stepWithIdentifier(colorStepID)
            
        case .Some(colorStepID):
            return stepWithIdentifier(summaryStepID)
            
        default:
            return nil
        }
        
        return nil
    }
    func findName(result: ORKTaskResult) -> String? {
        
        if let stepResult = result.resultForIdentifier(nameStepID) as? ORKStepResult, let subResults = stepResult.results, let textQuestionResult = subResults[0] as? ORKTextQuestionResult {
            
            return textQuestionResult.textAnswer
        }
        return nil
    }
    
    func questStep(name: String?) -> ORKStep {
        var questQuestionStepTitle = "What is your quest?"
        if let name = name {
            questQuestionStepTitle = "What is your quest, \(name)?"
        }
        let textChoices = [ORKTextChoice(text: "Create a ResearchKit App", value: 0), ORKTextChoice(text: "Seek the Holy Grail", value: 1),ORKTextChoice(text: "Find a shrubbery", value: 2)]
        let questAnswerFormat: ORKTextChoiceAnswerFormat = ORKAnswerFormat.choiceAnswerFormatWithStyle(.SingleChoice, textChoices: textChoices)
        return ORKQuestionStep(identifier: questStepID, title: questQuestionStepTitle, answer: questAnswerFormat)
    }
    
}