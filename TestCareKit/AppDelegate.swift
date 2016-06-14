//  Sinai App
//
//  Created by Zachary Bernstein on 5/23/16.
//  Copyright © 2016 Zachary Bernstein. All rights reserved.


import UIKit
import CareKit
import MobileCoreServices
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
 
    
    /*

        These variables are needed to upload to Azure. They will be initialized within ConsentViewController.swift, if they are not initialized by then they will be initialized in ApplicationDidFinishLaunching
     
     
    */
    
    var client:MSClient?
    var adherenceTable:MSTable?
    var patientTable:MSTable?
    var PatientMedFreqTable:MSTable?
    var medicationTable:MSTable?
    var backgroundTask: UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
    
    
    
    var window: UIWindow?
  
    
   
    

//MARK: Azure Methods
    
  
    /**
 
        Every time user opens app for first time, or app enters background, or whenever background fetch occurs, this will query through all the health data for the day and upload to Azure through MSClient API
    */
    func uploadInformation() {
        
        
        //UPDATE WILL ONLY FIRE IF USER HAS COMPLETED SURVEY. I.E HAS NAVIGATED TO MAIN VIEW CONTROLLER AND REGISTERD FOR UPDATE NOTIFICATION
            if NSUserDefaults.standardUserDefaults().boolForKey("surveyCompleted") == true
                {
                    self.uploadAssessmentData()
                    self.uploadInterventionData()
                }
        }
    /**
 
     Uploads specifically intervention Data (i.e Care Card events)
 
    */
    func uploadInterventionData()
    {
        //Runs Task for short period of time in background if user closes app.
        registerBackgroundTask()
        let storeManager = CarePlanStoreManager.sharedCarePlanStoreManager
        
        //Queries through Care Card events
        storeManager.store.eventsOnDate(NSDate().dateComponents(), type: .Intervention) { activities, errorOrNil in
            for activity in activities
            {
            
            let identifier = activity.first!.activity.identifier
            let components = identifier.componentsSeparatedByString("/")
            let medId:Int = Int(components.first!)!
            let date:String = NSDate.dateFromComponents(activity.first!.date).monthDayYearString()
            
            
               
            
            //Query to see if post already exists for that day
            let medIdPredicate = NSPredicate(format:"Med_id == \(medId)")
            let datePredicate = NSPredicate(format:"Date == '\(date)'")
            let patPredicate = NSPredicate(format:"Patient_id == \(NSUserDefaults.standardUserDefaults().integerForKey(Constants.userIdKey))")
            let compoundPredicate:NSCompoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates:[medIdPredicate,patPredicate,datePredicate])
            let query = self.adherenceTable!.queryWithPredicate(compoundPredicate)
            
            query.readWithCompletion() {
                (result, errorOrNil) in
                if let error = errorOrNil
                {
                    print("ERROR:",error)
                    
                }
                else
                {
                    //Create new post
                    var newAdherencePost:[String:AnyObject] = ["Patient_id":NSUserDefaults.standardUserDefaults().integerForKey(Constants.userIdKey),
                        "Med_id":medId,
                        "Date":date
                    ]
                    var i:Int! = 1
                    
                    //Add time and status for each dosage of the day
                    for event in activity
                    {
                        print("Creation Date")
                        //TODO: Need to get Time they took dosage

                        
                        var result:String!
                        switch event.state.rawValue
                        {
                        case 2:
                            result = "Completed"
                        default:
                            result = "Not-Completed"
                        }
                        
                        let statusString = "Status_" + String(i)
                        let timeString = "Time_" + String(i)
                        newAdherencePost[statusString] = result
                        newAdherencePost[timeString] = event.timeDate.hourMinutesString()
                        
                        i = i+1
                        
                    }
                    
                    //If object already existed, update it
                    if let item = result.items.first
                    {
                        //If more than one adherence posts for this med id are found, they should be deleted
                        if result.items.count > 1
                        {
                            for d in 1...result.items.count-1
                            {
                                //Deletes Excess items in case they are found
                                let deleteItem = result.items[d]
                                self.adherenceTable!.delete(deleteItem as! [NSObject : AnyObject], completion: nil)
                                print("Delete Excess");
                            }
                        }
                        var newItem = item.mutableCopy() as! Dictionary<String,AnyObject>
                        //Update Object
                        newItem["Status_1"] = newAdherencePost["Status_1"]
                        newItem["Status_2"] = newAdherencePost["Status_2"]
                        newItem["Status_3"] = newAdherencePost["Status_3"]
                        
                        newItem["Time_1"] = newAdherencePost["Time_1"]
                        newItem["Time_2"] = newAdherencePost["Time_2"]
                        newItem["Time_3"] = newAdherencePost["Time_3"]
                        
                        self.adherenceTable!.update(newItem)
                        {
                            (results, error) in
                            if let err = error {
                                print("ERROR",err)
                            }
                            else
                            {
                                self.endBackgroundTask()
                            }
                        }
                        
                        
                        
                    }
                    else
                    {
                        //Insert new object
                        self.adherenceTable!.insert(newAdherencePost)
                        {
                            (results, err2) in
                            if let error = err2
                            {
                                print("ERROR",error)
                            }
                            else
                            {
                                self.endBackgroundTask()
                                
                            }
                        }
                        
                        
                    }
                }
            }
            
            
            
            //End For Loop
        }
            
        }
    }
    /**
     
     Uploads specifically assessment Data (i.e Symptom Tracker events, e.g Pain Scale). See above for comments.
     
     */
    func uploadAssessmentData()
    {
        
        //Runs Task for short period of time in background if user closes app.
        registerBackgroundTask()
        let storeManager = CarePlanStoreManager.sharedCarePlanStoreManager
        
        //Queries through Symptom tracker events
        storeManager.store.eventsOnDate(NSDate().dateComponents(), type:.Assessment) { activities, errorOrNil in
            for activity in activities
            {
                
                let identifier = activity.first!.activity.identifier
                let components = identifier.componentsSeparatedByString("/")
                let medId:Int = Int(components.first!)!
                let date:String = NSDate.dateFromComponents(activity.first!.date).monthDayYearString()
                
                
                
                
                //Query to see if post already exists for that day
                let medIdPredicate = NSPredicate(format:"Med_id == \(medId)")
                let datePredicate = NSPredicate(format:"Date == '\(date)'")
                let patPredicate = NSPredicate(format:"Patient_id == \(NSUserDefaults.standardUserDefaults().integerForKey(Constants.userIdKey))")
                let compoundPredicate:NSCompoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates:[medIdPredicate,patPredicate,datePredicate])
                let query = self.adherenceTable!.queryWithPredicate(compoundPredicate)
                
                query.readWithCompletion() {
                    (result, errorOrNil) in
                    if let error = errorOrNil
                    {
                        print("LOCATION 1")
                        print("ERROR:",error)
                        
                    }
                    else
                    {
                        var newAdherencePost:[String:AnyObject] = ["Patient_id":NSUserDefaults.standardUserDefaults().integerForKey(Constants.userIdKey),
                            "Med_id":medId,
                            "Date":date
                        ]
                        var i:Int! = 1
                        for event in activity
                        {
                            
                            var result:String?
                            if let eventResult = event.result {
                                result = eventResult.valueString
                            }
                            else
                            {
                                result = "Not-Completed"
                            }
                            
                            
                            
                            let statusString = "Status_" + String(i)
                            let timeString = "Time_" + String(i)
                            newAdherencePost[statusString] = result
                            newAdherencePost[timeString] = event.timeDate.hourMinutesString()
                            
                            i = i+1
                            
                        }
                        
                        
                        if let item = result.items.first
                        {
                            //If more than one adherence posts for this med id are found, they should be deleted
                            if result.items.count > 1
                            {
                                for d in 1...result.items.count-1
                                {
                                    //Deletes Excess items in case they are found
                                    let deleteItem = result.items[d]
                                    self.adherenceTable!.delete(deleteItem as! [NSObject : AnyObject], completion: nil)
                                    print("Delete Excess");
                                }
                            }
                            var newItem = item.mutableCopy() as! Dictionary<String,AnyObject>
                            //Update Object
                            newItem["Status_1"] = newAdherencePost["Status_1"]
                            newItem["Status_2"] = newAdherencePost["Status_2"]
                            newItem["Status_3"] = newAdherencePost["Status_3"]
                            
                            newItem["Time_1"] = newAdherencePost["Time_1"]
                            newItem["Time_2"] = newAdherencePost["Time_2"]
                            newItem["Time_3"] = newAdherencePost["Time_3"]
                            
                            self.adherenceTable!.update(newItem)
                            {
                                (results, error) in
                                if let err = error {
                                    print("LOCATION 2")
                                    print("ERROR",err)
                                }
                                else
                                {
                                    self.endBackgroundTask()
                                }
                            }
                            
                            
                            
                        }
                        else
                        {
                            //Insert new object
                            self.adherenceTable!.insert(newAdherencePost)
                            {
                                (results, err2) in
                                if let error = err2
                                {
                                    print("LOCATION 3")
                                    print("ERROR",error)
                                }
                                else
                                {
                                    self.endBackgroundTask()
                                    
                                }
                            }
                            
                            
                        }
                    }
                }
                
                
                
                //End For Loop
            }
            
        }
    }
//MARK: Background Methods
    /**
        Background fetch upload once in a while
    */
    func application(application: UIApplication, performFetchWithCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        uploadInformation()
    }
    /**
        Called whenever background task should occur
    */
    func registerBackgroundTask() {
        backgroundTask = UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler {
            [unowned self] in
            self.endBackgroundTask()
        }
        assert(backgroundTask != UIBackgroundTaskInvalid)
    }
    
    func endBackgroundTask() {
        UIApplication.sharedApplication().endBackgroundTask(backgroundTask)
        backgroundTask = UIBackgroundTaskInvalid
    }
    
//MARK: Normal Methods
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) -> Bool {

        
        //REQUIRED FOR NOTIFICATIONS TO SHOW UP
        application.registerUserNotificationSettings(UIUserNotificationSettings(forTypes:[.Alert, .Badge, .Sound], categories: nil))  // types are UIUserNotificationType members
        
 
        guard let _ = self.client, let _ = self.adherenceTable, let _ = self.patientTable, let _ = self.PatientMedFreqTable, let _ = self.medicationTable else {
            client = MSClient(applicationURLString:"https://zachservice.azure-mobile.net/")
            adherenceTable = client!.tableWithName("Adherence")
            patientTable = client!.tableWithName("Patient")
            PatientMedFreqTable = client!.tableWithName("Patient_Med_Freq")
            medicationTable = client!.tableWithName("Medication")
            return true
        }
        
        
        //Updates store in background every 12 hours
        let twelveHourInterval:NSTimeInterval! = 12 * 60 * 60
        UIApplication.sharedApplication().setMinimumBackgroundFetchInterval(twelveHourInterval)
        
        
        
        

       
        
        uploadInformation()
        
        
    
        return true
    }
    func application(application: UIApplication, didReceiveLocalNotification notification: UILocalNotification) {
       
        
        
        
    }
    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        uploadInformation()
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        endBackgroundTask()
    }
    
    // MARK: - Core Data stack
    
    lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file.
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1] 
    }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = NSBundle.mainBundle().URLForResource("QSTodoDataModel", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        var coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("qstodoitem.sqlite")
        var error: NSError? = nil
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator!.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil)
        } catch var error1 as NSError {
            error = error1
            coordinator = nil
            
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            dict[NSUnderlyingErrorKey] = error
            error = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(error), \(error!.userInfo)")
            abort()
        } catch {
            fatalError()
        }
        
        return coordinator
    }()
    
    lazy var managedObjectContext: NSManagedObjectContext? = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        if coordinator == nil {
            return nil
        }
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()
}


