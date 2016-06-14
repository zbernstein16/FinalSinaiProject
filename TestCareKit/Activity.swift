//
//  Activity.swift
//  TestCareKit
//
//  Created by Zachary Bernstein on 5/4/16.
//  Copyright © 2016 Zachary Bernstein. All rights reserved.
//  Copyright (c) 2016, Apple Inc. All rights reserved.

import CareKit
class Activity:NSObject, ActivityProtocol
{
    var freq:Int!
    var id:Int!
    //Schedule String will come in as "_/_/_/_/_/_/_"
    var scheduleFreqString:String?
    var startDate:NSDateComponents!
    
    //Computer property will return array of NSNumbers only if in right format
    var scheduleFreqArray:[NSNumber]? {
        guard let scheduleFreqString = scheduleFreqString,
        let array = scheduleFreqString.toScheduleArray()
        else { return nil }
        
        return array;
    }
    override init()
    {
        self.activityType = .Blank
        super.init()
    }
    var activityType:ActivityType
    
    
    func carePlanActivity() -> OCKCarePlanActivity
    {
        fatalError("This method must be overridden")
    }
}
//Protocol Defines what is necesssary for activities to have
protocol ActivityProtocol {
    
    var activityType:ActivityType { get set }
    func carePlanActivity() -> OCKCarePlanActivity
    
}



enum ActivityType:String {
    
    case Drug
    case PainScale
    case Blank
    
    
    case HamstringStretch
    case TakeMedication
    case NameSurvey
    case ChoiceSurvey
    case BackPain
    case Mood
    case BloodGlucose
    case Tower
    
}