import CareKit
import ResearchKit

/**
 Struct that conforms to the `Assessment` protocol to define a back pain
 assessment.
 */
class PainScale:Assessment, NSCoding {
    // MARK: Activity
    

    var typeOfPain:String!
    var startDate:NSDateComponents!
    
    
    
    init(withTypeOfPain pain:String,start:NSDate,occurences:Int, medId:Int)
    {
        super.init()
        self.activityType = .PainScale
        self.typeOfPain = pain
        self.startDate = start.dateComponents()
        self.freq = occurences
        self.id = medId
    }
    override func carePlanActivity() -> OCKCarePlanActivity {
        // Create a weekly schedule.
        let startDate = self.startDate
        let schedule = OCKCareSchedule.dailyScheduleWithStartDate(startDate, occurrencesPerDay:UInt(freq))
        
        // Get the localized strings to use for the assessment.
        let title = NSLocalizedString("Pain", comment: "")
        let summary = NSLocalizedString(typeOfPain, comment: "")
        
         let identifier = String("\(id)/\(freq)")
        let activity = OCKCarePlanActivity.assessmentWithIdentifier(
            identifier,
            groupIdentifier:activityType.rawValue,
            title: title,
            text: summary,
            tintColor: UIColor.blueColor(),
            resultResettable: true,
            schedule: schedule,
            userInfo: nil
        )
        
        return activity
    }
    
    // MARK: Assessment
    
    override func task() -> ORKTask {
        
        // Get the localized strings to use for the task.
        let question = NSLocalizedString("How was your pain today?", comment: "")
        let maximumValueDescription = NSLocalizedString("Very much", comment: "")
        let minimumValueDescription = NSLocalizedString("Not at all", comment: "")
        
        // Create a question and answer format.
        let answerFormat = ORKScaleAnswerFormat(
            maximumValue: 10,
            minimumValue: 1,
            defaultValue: -1,
            step: 1,
            vertical: false,
            maximumValueDescription: maximumValueDescription,
            minimumValueDescription: minimumValueDescription
        )
        
        let questionStep = ORKQuestionStep(identifier: activityType.rawValue, title: question, answer: answerFormat)
        questionStep.optional = false
        
        
        
        // Create an ordered task with a single question.
        let task = ORKOrderedTask(identifier: activityType.rawValue, steps: [questionStep])
        
        return task
    }
    
    // MARK: NSCoding
    
    required convenience init?(coder decoder: NSCoder) {
        
        guard let typeOfPain = decoder.decodeObjectForKey("typeOfPain") as? String,
            let freq = decoder.decodeObjectForKey("freq") as? Int,
            let startDate = decoder.decodeObjectForKey("startDate") as? NSDateComponents,
            let id = decoder.decodeObjectForKey("id") as? Int else { return nil }
        
        
        self.init(withTypeOfPain:typeOfPain,start:NSDate.dateFromComponents(startDate),occurences:freq, medId:id)
        
    }
    
    func encodeWithCoder(coder: NSCoder) {
        coder.encodeObject(self.typeOfPain, forKey: "typeOfPain")
        coder.encodeObject(self.freq, forKey: "freq")
        coder.encodeObject(self.startDate, forKey: "startDate")
        coder.encodeObject(self.id, forKey: "id")
    }
    

    
    
    
}