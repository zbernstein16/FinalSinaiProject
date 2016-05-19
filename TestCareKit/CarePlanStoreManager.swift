/*
 Copyright (c) 2016, Apple Inc. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 
 1.  Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 2.  Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation and/or
 other materials provided with the distribution.
 
 3.  Neither the name of the copyright holder(s) nor the names of any contributors
 may be used to endorse or promote products derived from this software without
 specific prior written permission. No license is granted to the trademarks of
 the copyright holders even if such marks are included in this software.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

import CareKit

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
    
    // MARK: Initialization
    
    private override init() {
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
        
        // Start to build the initial array of insights.
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
    func handleNewMedication(PatMedFreqDictionary:Dictionary<String,AnyObject>)
    {
        let medId:Int = PatMedFreqDictionary["Med_id"] as! Int
        let freq:Int = PatMedFreqDictionary["Freq"] as! Int
        let startDate:NSDate = PatMedFreqDictionary["Start_Date"] as! NSDate
        
        
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
                for medication in results.items
                {
                    let name:String = medication["Name"] as! String
                    let type:String = medication["Type"] as! String
                    //TODO: Add more types here 
                    switch type {
                        case "Drug":
                           let drug = Drug(withName: name, start: startDate, occurences: freq, medId:medId)
                           self.store.addActivity(drug.carePlanActivity()) {
                            success, error in
                            if !success {
                                
                            }
                            else
                            {
                                
                            }
                        }
                        case "Paint":
                            print("Found Pain")
                        default:
                            break
                    }
                }
            }
        }
        
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
    
}