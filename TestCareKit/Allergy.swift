import CareKit
import ResearchKit


class Allergy:Assessment, NSCoding {
    // MARK: Activity
    
    
   
   
    
    
    
    init(withStart start:NSDate,occurences:Int, medId:Int)
    {
        super.init()
        self.activityType = .PainScale
        self.startDate = start.dateComponents()
        self.freq = occurences
        self.id = medId
    }
    override func carePlanActivity() -> OCKCarePlanActivity {
        // Create a weekly schedule.
        let startDate = self.startDate
        let schedule = OCKCareSchedule.dailyScheduleWithStartDate(startDate, occurrencesPerDay:UInt(freq))
        
        // Get the localized strings to use for the assessment.
        let title = NSLocalizedString("Allergy Survey", comment: "")
      
        let identifier = String("\(id)/\(freq)")
        let activity = OCKCarePlanActivity.assessmentWithIdentifier(
            identifier,
            groupIdentifier:String(self.id),
            title: title,
            text: "",
            tintColor: UIColor.blueColor(),
            resultResettable: true,
            schedule: schedule,
            userInfo: nil
        )
        
        return activity
    }
    
    // MARK: Assessment
    
    override func task() -> ORKTask {
        
        return AllergySurveyTask()
    
    }
    
    // MARK: NSCoding
    
    required convenience init?(coder decoder: NSCoder) {
        
        guard let freq = decoder.decodeObjectForKey("freq") as? Int,
            let startDate = decoder.decodeObjectForKey("startDate") as? NSDateComponents,
            let id = decoder.decodeObjectForKey("id") as? Int else { return nil }

        self.init(withStart:NSDate.dateFromComponents(startDate),occurences:freq, medId:id)
        
    }
    
    func encodeWithCoder(coder: NSCoder) {
        coder.encodeObject(self.freq, forKey: "freq")
        coder.encodeObject(self.startDate, forKey: "startDate")
        coder.encodeObject(self.id, forKey: "id")
    }
    
    
    
    
    
}