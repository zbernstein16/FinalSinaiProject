//import CareKit
//import ResearchKit
//
///**
// Struct that conforms to the `Assessment` protocol to define a back pain
// assessment.
// */
//struct BackPain: Assessment {
//    // MARK: Activity
//    
//    let activityType: ActivityType = .BackPain
//    
//    func carePlanActivity() -> OCKCarePlanActivity {
//        // Create a weekly schedule.
//        let startDate = NSDateComponents(year: 2016, month: 01, day: 01)
//        let schedule = OCKCareSchedule.weeklyScheduleWithStartDate(startDate, occurrencesOnEachDay: [1, 1, 1, 1, 1, 1, 1])
//        
//        // Get the localized strings to use for the assessment.
//        let title = NSLocalizedString("Pain", comment: "")
//        let summary = NSLocalizedString("Lower Back", comment: "")
//        
//        let activity = OCKCarePlanActivity.assessmentWithIdentifier(
//            activityType.rawValue,
//            groupIdentifier: nil,
//            title: title,
//            text: summary,
//            tintColor: UIColor.blueColor(),
//            resultResettable: true,
//            schedule: schedule,
//            userInfo: nil
//        )
//        
//        return activity
//    }
//    
//    // MARK: Assessment
//    
//    func task() -> ORKTask {
//        // Get the localized strings to use for the task.
//        let question = NSLocalizedString("How was your pain today?", comment: "")
//        let maximumValueDescription = NSLocalizedString("Very much", comment: "")
//        let minimumValueDescription = NSLocalizedString("Not at all", comment: "")
//        
//        // Create a question and answer format.
//        let answerFormat = ORKScaleAnswerFormat(
//            maximumValue: 10,
//            minimumValue: 1,
//            defaultValue: -1,
//            step: 1,
//            vertical: false,
//            maximumValueDescription: maximumValueDescription,
//            minimumValueDescription: minimumValueDescription
//        )
//        
//        let questionStep = ORKQuestionStep(identifier: activityType.rawValue, title: question, answer: answerFormat)
//        questionStep.optional = false
//        
//       
//        
//        // Create an ordered task with a single question.
//        let task = ORKOrderedTask(identifier: activityType.rawValue, steps: [questionStep])
//        
//        return task
//    }
//}
