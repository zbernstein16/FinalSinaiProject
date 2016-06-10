//
//  ViewController.swift
//  TestCareKit
//
//  Created by Zachary Bernstein on 5/2/16.
//  Copyright © 2016 Zachary Bernstein. All rights reserved.

import UIKit
import CareKit
import ResearchKit
class MainViewController: UITabBarController, OCKCarePlanStoreDelegate {

    
    //MARK: Properties
    let storeManager = CarePlanStoreManager.sharedCarePlanStoreManager

    var careCardViewController: OCKCareCardViewController!
    var symptomTrackerViewController: OCKSymptomTrackerViewController!
    var insightsViewController: OCKInsightsViewController!
    var docViewController: DocViewController!
    var chartViewController:ChartViewController!
    var surveyVC: ORKTaskViewController!
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    var client:MSClient?
    var adherenceTable:MSTable?
    
    
//    let serialQueue = dispatch_queue_create("com.zachbern", DISPATCH_QUEUE_SERIAL)
//    let bigQue = dispatch_queue_create("com.zachbern2", DISPATCH_QUEUE_SERIAL)
    
    //MARK: Initialize
    
    required init?(coder aDecoder:NSCoder)
    {
        
        
        //SETUP CAREKIT AND RESEARCHKIT


        
        super.init(coder: aDecoder)
        
        
        self.setViewControllers()
        
        storeManager.delegate = self
    }
    //MARK: Default View Methods
    
    override func viewDidLoad() {
        //Set survey completed to true
        NSUserDefaults.standardUserDefaults().setBool(true, forKey: "surveyCompleted")
    
        self.setViewControllers()
        
        self.scheduleNotification()
        super.viewDidLoad()

    }
    func setViewControllers() {
        
        careCardViewController = createCareCardViewController()
        symptomTrackerViewController = createSymptomTrackerViewController()
        insightsViewController = createInsightsViewController()
        
        //docViewController = DocViewController()
        //docViewController.title = "HTML"
        
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        chartViewController = storyboard.instantiateViewControllerWithIdentifier("test") as! ChartViewController
     
   
        chartViewController.title = "CHART"
        //Add contact
        //connectViewController = createConnectViewController()
        
        
        
        
        self.viewControllers = [
            UINavigationController(rootViewController: careCardViewController),
            UINavigationController(rootViewController: symptomTrackerViewController),
            UINavigationController(rootViewController: insightsViewController),UINavigationController(rootViewController: chartViewController)]
        


    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
//MARK: Initialize Tab Controllers
    
    func createCareCardViewController() -> OCKCareCardViewController {
       
        //Creates new care card linked to the devices store.
        let viewController = OCKCareCardViewController(carePlanStore:storeManager.store)
        viewController.delegate = self
        
        //This button will refresh the user's medications
        viewController.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Refresh", style: .Plain, target: self, action: #selector(refresh))
        
        // Setup the controller's title and tab bar item
        viewController.title = NSLocalizedString("Care Card", comment: "")
        viewController.tabBarItem = UITabBarItem(title: viewController.title, image: UIImage(named:"carecard"), selectedImage: UIImage(named: "carecard-filled"))
        
        return viewController
    }
    
   func createSymptomTrackerViewController() -> OCKSymptomTrackerViewController {
        let viewController = OCKSymptomTrackerViewController(carePlanStore:storeManager.store)
        viewController.delegate = self
        viewController.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Refresh", style: .Plain, target: self, action: #selector(refresh))
    
    
        // Setup the controller's title and tab bar item
        viewController.title = NSLocalizedString("Symptom Tracker", comment: "")
        viewController.tabBarItem = UITabBarItem(title: viewController.title, image: UIImage(named:"symptoms"), selectedImage: UIImage(named: "symptoms-filled"))
        
        return viewController
    }

    
    func createInsightsViewController () -> OCKInsightsViewController {
        let headerTitle = NSLocalizedString("Weekly Charts", comment: "")
        let viewController = OCKInsightsViewController(insightItems: storeManager.insights, headerTitle: headerTitle, headerSubtitle: "")
         //viewController.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Insert", style: .Plain, target: self, action: #selector(insertActivity))
        // Setup the controller's title and tab bar item
        viewController.title = NSLocalizedString("Insights", comment: "")
        viewController.tabBarItem = UITabBarItem(title: viewController.title, image: UIImage(named:"insights"), selectedImage: UIImage(named: "insights-filled"))
        
        return viewController
    }
//MARK: Azure methods
    func failedToConnectToInternet() {
        let alert = UIAlertController(title: "Error", message:"Not Connected To Internet", preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Okay", style: .Default) { _ in })
        self.presentViewController(alert, animated: true){}

    }
    func refresh()
    {
        self.storeManager.refreshStore()
        self.setViewControllers();
    }
    /*
 
        This is only a testing method. It should be removed in the final version. It inserts a new object into medication table for this specific user. Remove the Insert Button in func setViewControllers
    */
    func insertActivity() {
     
         let newMed = ["Name":"Ibuprofen","Type":"Drug"]
        var medId:Int!
        appDelegate.medicationTable!.insert(newMed)
        {
            (result, error) in
            if let err = error {
                print("Error", err)
            }
            else if let item = result {
                let med = item as! Dictionary<String,AnyObject>
                print("Inserted new Med")
                medId = med["id"]! as! Int
                
                
                let newPatMedFreq:[String:AnyObject] = ["Patient_id":NSUserDefaults.standardUserDefaults().integerForKey(Constants.userIdKey),"Med_id":medId,"Freq":2,"Start_Date":"2000-01-01"]
                self.appDelegate.PatientMedFreqTable!.insert(newPatMedFreq) { (result, error) in
                    if let err = error {
                        print("ERROR ", err)
                    } else if let _ = result {
                        print("Inserted new PatMedFreq")
                        
                    }
                }
                
                
            }
            
            
        }
        
       
        
        
        
        
        
    }
    
}



//MARK: Extensions

//MARK: Care Plan Sotre Manager Delegate
extension MainViewController: CarePlanStoreManagerDelegate {
    
    /// Called when the `CarePlanStoreManager`'s insights are updated.
    
    
    //Must Eventually add ability to incorporate Research Kit charts here
    func carePlanStoreManager(manager: CarePlanStoreManager, didUpdateInsights insights: [OCKInsightItem]) {
        // Update the insights view controller with the new insights.
        insightsViewController.items = insights
    }
}

//MARK: Care Card Extension.
/*
 
    As of now not used. Could theoretically be used to live insert data into table, but this leads to a lot of synchronization issues
 
*/
extension MainViewController:OCKCareCardViewControllerDelegate
{
    func careCardViewController(viewController: OCKCareCardViewController, didSelectButtonWithInterventionEvent interventionEvent: OCKCarePlanEvent) {

        
        //HERE IS WHERE LIVE SYNC COULD OCCUR
    }
}
//MARK: Symptom Tracker Extension
/*
 
    Finds selected assessment in store and presents task to user
 
*/
extension MainViewController: OCKSymptomTrackerViewControllerDelegate
{
    func symptomTrackerViewController(viewController: OCKSymptomTrackerViewController, didSelectRowWithAssessmentEvent assessmentEvent: OCKCarePlanEvent) {
        
        // Lookup the assessment the row represents.
        print("Location 1")
        //guard let activityType = ActivityType(rawValue: assessmentEvent.activity.groupIdentifier!) else { return }
        guard let sampleAssessment = storeManager.activityWithMedId(Int(assessmentEvent.activity.groupIdentifier!)!)! as? Assessment else { return }
        /*
         Check if we should show a task for the selected assessment event
         based on its state.
         */
        print("location 3")
        guard assessmentEvent.state == .Initial ||
            assessmentEvent.state == .NotCompleted ||
            (assessmentEvent.state == .Completed && assessmentEvent.activity.resultResettable) else { return }
        
        // Show an `ORKTaskViewController` for the assessment's task.
        let taskViewController = ORKTaskViewController(task: sampleAssessment.task(), taskRunUUID: nil)
        taskViewController.delegate = self
        
        presentViewController(taskViewController, animated: true, completion: nil)
    }
}
//MARK: Task View Controller Extension
/*
 
    Upon completing the task will create result and call self.completeEvent() to store the result
 
*/
extension MainViewController: ORKTaskViewControllerDelegate
{
    /// Called with then user completes a presented `ORKTaskViewController`.
    func taskViewController(taskViewController: ORKTaskViewController, didFinishWithReason reason: ORKTaskViewControllerFinishReason, error: NSError?) {
        defer {
            dismissViewControllerAnimated(true, completion: nil)
        }
        
        // Make sure the reason the task controller finished is that it was completed.
        guard reason == .Completed else { return }
        
        // Determine the event that was completed and the `SampleAssessment` it represents.
        guard let event = symptomTrackerViewController.lastSelectedAssessmentEvent,
            let assessment = storeManager.activityWithMedId(Int(event.activity.groupIdentifier!)!) as? Assessment
        else { return }
        
        // Build an `OCKCarePlanEventResult` that can be saved into the `OCKCarePlanStore`.
        let carePlanResult = assessment.buildResultForCarePlanEvent(event, taskResult: taskViewController.result)
        //let carePlanResult = sampleAssessment.buildResultForCarePlanEvent(event, taskResult: taskViewController.result)
        self.completeEvent(event, inStore: self.storeManager.store, withResult: carePlanResult)
        
        
        
        
        
    }
    
// MARK: Convenience
    /*

        Called whenever user completes task. Stores it to device. Healthkit storage should eventually be implemented here
     
    */
    private func completeEvent(event: OCKCarePlanEvent, inStore store: OCKCarePlanStore, withResult result: OCKCarePlanEventResult) {
        
        //TODO:Healthkit integration
        //Eventual Healthkit storage
 
       
//        if ([identifier isEqualToString:TemperatureAssessment]) {
//            //1. Present a survey to ask for temperature
//            // ...
//            
//            //2. Save the collected temperature into health kit
//            HKHealthStore *hkstore = [HKHealthStore new];
//            HKQuantityType *type = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyTemperature];
//            
//            [hkstore requestAuthorizationToShareTypes:[NSSet setWithObject:type] readTypes:[NSSet setWithObject:type] completion:^(BOOL success, NSError * _Nullable error) {
//                HKQuantitySample *sample = [HKQuantitySample quantitySampleWithType:type quantity:[HKQuantity quantityWithUnit:[HKUnit degreeFahrenheitUnit] doubleValue:99.1] startDate:[NSDate date] endDate:[NSDate date]];
//                
//                [hkstore saveObject:sample withCompletion:^(BOOL success, NSError * _Nullable error) {
//                // 3. When the collected temperature has been saved into health kit
//                // Use the saved HKSample object to create a result object and save it to CarePlanStore.
//                // Then each time, CarePlanStore will load the temperature data from HealthKit.
//                OCKCarePlanEventResult *result = [[OCKCarePlanEventResult alloc] initWithQuantitySample:sample quantityStringFormatter:nil unitStringKeys:@{[HKUnit degreeFahrenheitUnit]: @"\u00B0F", [HKUnit degreeCelsiusUnit]: @"\u00B0C",} userInfo:nil];
//        
//        [_store updateEvent:assessmentEvent withResult:result state:OCKCarePlanEventStateCompleted completion:^(BOOL success, OCKCarePlanEvent * _Nonnull event, NSError * _Nonnull error) {
//        NSAssert(success, error.localizedDescription);
//        }];
//    }];                                        
//}];
//}
        
        
        
        //Update Store with new event
        store.updateEvent(event, withResult: result, state: .Completed) { success, _, error in
            
        }
        
    }
    
//MARK: Background Notification executes every minute while app is open
    func scheduleNotification() {
//        UIApplication.sharedApplication().cancelAllLocalNotifications()
//        
//        //SET UP JSON UPDATE NOTIFICATIONS
//        let notif:UILocalNotification! = UILocalNotification()
//
//        //Set up Daily Fire Schedule
//        let calendar = NSCalendar.currentCalendar()
//        let components = calendar.components([NSCalendarUnit.Day, NSCalendarUnit.Month,NSCalendarUnit.Year], fromDate: NSDate())
//        components.hour = 0
//        components.minute = 0
//        components.second = 0
//        calendar.timeZone = NSTimeZone.systemTimeZone()
//        let dateToFire = calendar.dateFromComponents(components)!
//        notif.fireDate = dateToFire
//        notif.timeZone = NSTimeZone.systemTimeZone()
//        notif.repeatInterval = NSCalendarUnit.Minute
//        notif.category = "update"
//        UIApplication.sharedApplication().scheduleLocalNotification(notif)
//        
//        
//        //Set up Reminders Three times a day
//        for i in 1..<4
//        {
//            let notif2:UILocalNotification! = UILocalNotification()
//            let calendar = NSCalendar.currentCalendar()
//            let components = calendar.components([NSCalendarUnit.Day, NSCalendarUnit.Month,NSCalendarUnit.Year], fromDate: NSDate())
//            
//            switch i {
//            case 1:
//                components.hour = 8
//            case 2:
//                components.hour = 12
//            case 3:
//                components.hour = 20
//            default:
//                break
//            }
//            components.minute = 0
//            components.second = 0
//            calendar.timeZone = NSTimeZone.systemTimeZone()
//            let dateToFire = calendar.dateFromComponents(components)!
//            notif2.fireDate = dateToFire
//            notif2.timeZone = NSTimeZone.systemTimeZone()
//            notif2.repeatInterval = NSCalendarUnit.Day
//            notif2.alertTitle = "Medication alert:"
//            notif2.alertBody = "Don't forget to report!"
//            
//            UIApplication.sharedApplication().scheduleLocalNotification(notif2)
//        }
        
    }
   

}