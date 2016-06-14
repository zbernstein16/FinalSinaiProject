//
//  Assessment.swift
//  TestCareKit
//
//  Created by Zachary Bernstein on 5/4/16.
//  Copyright © 2016 Zachary Bernstein. All rights reserved.


import CareKit
import ResearchKit
class Assessment:Activity, AssessmentProtocol
{
    func task() -> ORKTask
    {
        fatalError("This method must be overridden")
    }
}
protocol AssessmentProtocol: ActivityProtocol {
    func task() -> ORKTask
}


/**
 Extends instances of `Assessment` to add a method that returns a
 `OCKCarePlanEventResult` for a `OCKCarePlanEvent` and `ORKTaskResult`. The
 `OCKCarePlanEventResult` can then be written to a `OCKCarePlanStore`.
 */
extension Assessment {
    func buildResultForCarePlanEvent(event: OCKCarePlanEvent, taskResult: ORKTaskResult) -> [OCKCarePlanEventResult] {
        // Get the first result for the first step of the task result.
        var eventResultsArray:[OCKCarePlanEventResult] = []
        guard let results = taskResult.results else { return [] }
            for stepResult in results
            {
                guard let stepResult = stepResult as? ORKStepResult, individualResults = stepResult.results else { fatalError("Unexpected task results") }
                for individualResult in individualResults
                {
                    if let scaleResult = individualResult as? ORKScaleQuestionResult, answer = scaleResult.scaleAnswer {
                        eventResultsArray.append(OCKCarePlanEventResult(valueString: answer.stringValue, unitString: "out of 10", userInfo: nil))
                    }
                    else if let numericResult = individualResult as? ORKNumericQuestionResult, answer = numericResult.numericAnswer {
                        eventResultsArray.append(OCKCarePlanEventResult(valueString: answer.stringValue, unitString: numericResult.unit, userInfo: nil))
                    }
                    else if let choiceResult = individualResult as? ORKChoiceQuestionResult, answer = choiceResult.choiceAnswers?.first {
                        eventResultsArray.append(OCKCarePlanEventResult(valueString:String(answer), unitString: "", userInfo: nil))

                    }
                    else if let textResult = individualResult as? ORKTextQuestionResult, answer = textResult.textAnswer {
                        
                        eventResultsArray.append(OCKCarePlanEventResult(valueString: answer, unitString: "", userInfo: nil))
                    }

                }
            }
//        guard let firstResult = taskResult.firstResult as? ORKStepResult, stepResult = firstResult.results?.first else { fatalError("Unexepected task results") }
//        
//        // Determine what type of result should be saved.
//        if let scaleResult = stepResult as? ORKScaleQuestionResult, answer = scaleResult.scaleAnswer {
//            return OCKCarePlanEventResult(valueString: answer.stringValue, unitString: "out of 10", userInfo: nil)
//        }
//        else if let numericResult = stepResult as? ORKNumericQuestionResult, answer = numericResult.numericAnswer {
//            return OCKCarePlanEventResult(valueString: answer.stringValue, unitString: numericResult.unit, userInfo: nil)
//        }
//        else if let choiceResult = stepResult as? ORKChoiceQuestionResult, answer = choiceResult.choiceAnswers?.first {
//            
//            return OCKCarePlanEventResult(valueString:String(answer), unitString: "", userInfo: nil)
//        }
//        else if let textResult = stepResult as? ORKTextQuestionResult, answer = textResult.textAnswer {
//    
//            return OCKCarePlanEventResult(valueString: answer, unitString: "", userInfo: nil)
//        }
//        else if let hanoiResult = stepResult as? ORKTowerOfHanoiResult {
//            let answer = hanoiResult.puzzleWasSolved
//            switch answer {
//            case true:
//                //return OCKCarePlanEventResult(valueString: "Solved", unitString: "", userInfo: nil)
//                return OCKCarePlanEventResult(valueString: String(hanoiResult.moves!.count), unitString: "Moves", userInfo: nil)
//            case false:
//                return OCKCarePlanEventResult(valueString: "Failed", unitString: "", userInfo: nil)
//            }
//        }
//        fatalError("Unexpected task result type")
        return eventResultsArray
    }
}