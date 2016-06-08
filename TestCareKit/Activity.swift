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