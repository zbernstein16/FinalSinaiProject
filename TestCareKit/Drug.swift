//
//  TakeMedication.swift
//  TestCareKit
//
//  Created by Zachary Bernstein on 5/4/16.
//  Copyright © 2016 Zachary Bernstein. All rights reserved.
//

import CareKit
import ResearchKit
class Drug:Activity, NSCoding {
    

    var drugName: String!
    var startDate:NSDateComponents!
    init(withName name:String,start:NSDate,occurences:Int, medId:Int)
    {
        super.init()
        self.activityType = ActivityType.Drug
        self.drugName = name
        self.startDate = start.dateComponents()
        self.freq = occurences
        self.id = medId
    }
    override func carePlanActivity() -> OCKCarePlanActivity {
        print("Frequency")
        print(freq)
        
        
        let schedule = OCKCareSchedule.dailyScheduleWithStartDate(startDate, occurrencesPerDay:UInt(freq))
        let identifier = String("\(id)/\(freq)")
        return OCKCarePlanActivity.interventionWithIdentifier(identifier, groupIdentifier:String(self.id), title: drugName, text: nil, tintColor: UIColor.redColor(), instructions: "Take \(freq) time(s) a day", imageURL: nil, schedule: schedule, userInfo: nil)
    }
    
    
    // MARK: NSCoding
    
    required convenience init?(coder decoder: NSCoder) {
        guard let drugName = decoder.decodeObjectForKey("drugName") as? String,
            let freq = decoder.decodeObjectForKey("freq") as? Int,
            let startDate = decoder.decodeObjectForKey("startDate") as? NSDateComponents,
            let id = decoder.decodeObjectForKey("id") as? Int else { return nil }
        
        self.init(withName: drugName, start: NSDate.dateFromComponents(startDate), occurences: freq, medId: id)
        
    }
    
    
    func encodeWithCoder(coder: NSCoder) {
        coder.encodeObject(self.drugName, forKey: "drugName")
        coder.encodeObject(self.freq, forKey: "freq")
        coder.encodeObject(self.startDate, forKey: "startDate")
        coder.encodeObject(self.id, forKey: "id")
    }


}