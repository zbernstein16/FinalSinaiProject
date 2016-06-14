////  Copyright © 2016 Zachary Bernstein. All rights reserved.


import CareKit
import Foundation
class CarePlanStoreManager: NSObject {
    // MARK: Static Properties
    
    static var sharedCarePlanStoreManager = CarePlanStoreManager()
    
    // MARK: Properties
    let appDelegate:AppDelegate = UIApplication.sharedApplication().delegate! as! AppDelegate
    
    weak var delegate: CarePlanStoreManagerDelegate?
    
    let store: OCKCarePlanStore

    private let insightsBuilder: InsightsBuilder
    
    var insights: [OCKInsightItem] {
        return insightsBuilder.insights
    }
    
    
    
    var activities:[Activity]?
    
    // MARK: Initialization
    
    private override init() {
        
        
       
        //Whenever app starts up, we add all the activity objects to this class' array.
        // Start to build the initial array of insights.
        
        if let _ = NSKeyedUnarchiver.unarchiveObjectWithFile(Constants.archivePath) as? [Activity]
        {
            activities = NSKeyedUnarchiver.unarchiveObjectWithFile(Constants.archivePath) as? [Activity]
        }
        else
        {
            activities = [Activity]()
        }
        
        // Determine the file URL for the store.
        let searchPaths = NSSearchPathForDirectoriesInDomains(.ApplicationSupportDirectory, .UserDomainMask, true)
        let applicationSupportPath = searchPaths[0]
        let persistenceDirectoryURL = NSURL(fileURLWithPath: applicationSupportPath)
        
        if !NSFileManager.defaultManager().fileExistsAtPath(persistenceDirectoryURL.absoluteString, isDirectory: nil) {
            try! NSFileManager.defaultManager().createDirectoryAtURL(persistenceDirectoryURL, withIntermediateDirectories: true, attributes: nil)
        }
        
        // Create the store.
        store = OCKCarePlanStore(persistenceDirectoryURL: persistenceDirectoryURL)
        
        /*
         Create an `InsightsBuilder` to build insights based on the data in
         the store.
         */
        insightsBuilder = InsightsBuilder(carePlanStore: store)
        
        super.init()
        
        // Register this object as the store's delegate to be notified of changes.
        store.delegate = self
        
       
        
        updateInsights()
    }
    
    
    func updateInsights() {
        
       
        
        insightsBuilder.updateInsights { [weak self] completed, newInsights in
            // If new insights have been created, notifiy the delegate, which is main view controller
            guard let storeManager = self, newInsights = newInsights where completed else { return }
            //TODO: Change method call here so that eventually it can add ResearchKIt Chart
            storeManager.delegate?.carePlanStoreManager(storeManager, didUpdateInsights: newInsights)
            
        }
    }
    func refreshStore() {
        
        
        
        
        //0: For every object, query through Pat-Med-Freq table to see if it still exists. If it does not, remove it from device.
        //1: Query Patient-Med-Freq Table for all medications this person is taking
        //2: For each medication, construct the identifier by creating string Med_id/Freq e.g ibuprofen id =1, Freq 3 -> Identifier: 1/3
        //3: Check if medication already exists  in storewith that identifier
        //4: If it does not, query through Medication table, tell storeManager to run method with given type of medication and pass argument to add new activity
        
        
        let userId = NSUserDefaults.standardUserDefaults().integerForKey(Constants.userIdKey)
        
        //0
        let idPredicate = NSPredicate(format:"Patient_id == \(userId)", argumentArray: nil)
        self.store.activitiesWithCompletion()
            {
                success, ockactivities, errorOrNil in
                if let error = errorOrNil
                {
                    print(error.localizedDescription)
                }
                else
                {
                    for ockactivity in ockactivities
                    {
                        let activity = self.activityWithMedId(Int(ockactivity.groupIdentifier!)!)
                        //Query for each events Med_id
                        let medIdPredicate = NSPredicate(format:"Med_id == \(activity!.id)", argumentArray: nil)
                        let compoundPredicate = NSCompoundPredicate.init(andPredicateWithSubpredicates: [idPredicate,medIdPredicate])
                        self.appDelegate.PatientMedFreqTable!.readWithPredicate(compoundPredicate)
                        {
                            results, errorOrNil in
                            if let _ = errorOrNil{
                                self.delegate!.failedToConnectToInternet()
                            }
                            //If no activity is found in the database, remove it from the device
                            else if results.items.count == 0 {
        
                                self.store.removeActivity(ockactivity, completion: {_,_ in })
                                self.activities?.removeAtIndex(self.activities!.indexOf(activity!)!)
                                NSKeyedArchiver.archiveRootObject((self.activities!), toFile:Constants.archivePath)
                                
                                //Remove Scheduled Notification from Device
                                for notification in UIApplication.sharedApplication().scheduledLocalNotifications!
                                {
                                    let notificationMedId = notification.userInfo!["Med_id"] as! String
                                    if notificationMedId == ockactivity.groupIdentifier
                                    {
                                        print("Deleted Notification")
                                        UIApplication.sharedApplication().cancelLocalNotification(notification)
                                    }
                                }
                                
                            }
                            
                        }
                        //self.store.removeActivity(activity, completion:{_,_ in })
                    }
                }
        }
        
        //1
        self.appDelegate.PatientMedFreqTable!.readWithPredicate(idPredicate)
        {
            results, errorOrNil in
            if let error = errorOrNil{
                
                if error.domain == NSURLErrorDomain && error.code == NSURLErrorNotConnectedToInternet {
                    self.delegate?.failedToConnectToInternet()
                }
                
            }
            else if let results = results
            {
                for item in results.items
                {
                    let PatMedFreqDict = item as! Dictionary<String,AnyObject>
                    //2
                    let identifier = String("\(PatMedFreqDict["Med_id"]!)/\(PatMedFreqDict["Freq"]!)")
                    
                    
                    //3
                    self.store.activityForIdentifier(identifier) {
                        success, activity, errorOrNil in
                        if let error = errorOrNil {
                            fatalError(error.localizedDescription)
                        }
                        if let _ = activity
                        {
                            //Activity already exists, do nothing
                        }
                        else
                        {
                            //Tell Storemanager to handle new activity
                            self.handleNewMedication(PatMedFreqDict)
                            
                        }
                        
                    }
                }
            }
            
        }
        
        let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
        dispatch_async(dispatch_get_global_queue(priority, 0)) {
            
            self.appDelegate.uploadInformation()
            
            dispatch_async(dispatch_get_main_queue()) {
                // update some UI
            }
        }
        
        
    }
    func handleNewMedication(PatMedFreqDictionary:Dictionary<String,AnyObject>)
    {
        

        let medId:Int = PatMedFreqDictionary["Med_id"] as! Int
        let freq:Int = PatMedFreqDictionary["Freq"] as! Int
        let startDate:NSDate = PatMedFreqDictionary["Start_Date"] as! NSDate
        //TODO: Make sure this has right column name
        let scheduleFreqString:String? = PatMedFreqDictionary["Schedule_Freq"] as! String?
        
        
        //4: Query through Med table with MedId to get all events with that Id
        
        let predicate = NSPredicate(format:"id == \(medId)", argumentArray: nil)
        self.appDelegate.medicationTable!.readWithPredicate(predicate)
        {
            results, errorOrNil in
            if let error = errorOrNil
            {
                fatalError(error.localizedDescription)
            }
            else if let results = results
            {
                for activity in results.items
                {
                    let name:String = activity["Name"] as! String
                    let type:String = activity["Type"] as! String
                    //TODO: Add more types here 
                    switch type {
                        case "Drug":
                           let drug = Drug(withName: name, start: startDate, occurences: freq, medId:medId, scheduleFreqString: scheduleFreqString)
                           self.store.addActivity(drug.carePlanActivity()) {
                                                success, errorOrNil in
                                                if let error = errorOrNil
                                                {
                                                    fatalError(error.localizedDescription)
                                                }
                                                else
                                                {
                                                    
                                                    self.activities!.append(drug)
                                                    NSKeyedArchiver.archiveRootObject(self.activities!, toFile:Constants.archivePath)
                                                    self.createNotification(activityDictionary: PatMedFreqDictionary , activity: drug)
                                                }
                            }
                        case "PainScale":
                            let painScale = PainScale(withTypeOfPain: name, start: startDate, occurences: freq, medId: medId)
                            self.store.addActivity(painScale.carePlanActivity()) {
                                            success, errorOrNil in
                                            if let error = errorOrNil
                                            {
                                                fatalError(error.localizedDescription)
                                            }
                                            else
                                            {
                                                self.activities!.append(painScale)
                                                NSKeyedArchiver.archiveRootObject(self.activities!, toFile:Constants.archivePath)
                                                self.createNotification(activityDictionary:PatMedFreqDictionary, activity: painScale)
                                                
                                            }
                            }
                        case "Allergy":
                            let allergy = Allergy(withStart: startDate, occurences: freq, medId: medId)
                            self.store.addActivity(allergy.carePlanActivity())
                            {
                                success, error in
                                if let error = errorOrNil
                                {
                                    fatalError(error.localizedDescription)
                                }
                                else
                                {
                                    self.activities!.append(allergy)
                                    NSKeyedArchiver.archiveRootObject(self.activities!, toFile:Constants.archivePath)
                                    self.createNotification(activityDictionary:PatMedFreqDictionary, activity: allergy)
                                }
                        }
                        default:
                            break
                    }
                    }
                
            }
        }
        
    }
    
    /**
 
        For every new activity added to the device, this will create a notification at the given times in the Patient-Med-Frequency table. (Columns "Time_1", "Time_2", and "Time_3")
 
    */
    func createNotification(activityDictionary activityDict:Dictionary<String,AnyObject>, activity:Activity)
    {
        
        loop: for i in 1...activity.freq
        {
            let notification = UILocalNotification()
            
            inner: switch activity
            {
            case is Drug:
                let drug = activity as! Drug
                notification.alertBody = "Time to take your \(drug.drugName)"
            case is PainScale:
                let scale = activity as! PainScale
                notification.alertBody = "Time to measure your \(scale.typeOfPain)"
            default:
                break inner
            }

            notification.alertTitle = "Medication alert"

            let dateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = "HH:mm"
            let timeColumnString = "Time_" + String(i)
            guard let time = activityDict[timeColumnString] else { continue loop }
            guard let timeString = time as? String else { continue loop }
            guard let fireDate = dateFormatter.dateFromString(timeString) else { continue loop }
            notification.fireDate = fireDate
            notification.repeatInterval = NSCalendarUnit.Day
            notification.soundName = UILocalNotificationDefaultSoundName // play default sound
            notification.timeZone = NSTimeZone.systemTimeZone()
            notification.category = "alert"
            notification.userInfo = ["Med_id":activityDict["Med_id"]!]
            UIApplication.sharedApplication().scheduleLocalNotification(notification)
            
        }
      
    }
    
//MARK: Convenience
    
    func activityWithMedId(id:Int) -> Activity?
    {
        let activity = self.activities!.filter({ $0.id == id })
        return activity.first
    }
    func activityWithType(type: ActivityType) -> Activity? {
        for activity in activities! where activity.activityType == type {
            return activity
        }
        
        return nil
    }

    
}



extension CarePlanStoreManager: OCKCarePlanStoreDelegate {
    func carePlanStoreActivityListDidChange(store: OCKCarePlanStore) {
        updateInsights()
    }
    
    func carePlanStore(store: OCKCarePlanStore, didReceiveUpdateOfEvent event: OCKCarePlanEvent) {
        updateInsights()
    }
}



protocol CarePlanStoreManagerDelegate: class {
    
    func carePlanStoreManager(manager: CarePlanStoreManager, didUpdateInsights insights: [OCKInsightItem])
    func failedToConnectToInternet()
    
}