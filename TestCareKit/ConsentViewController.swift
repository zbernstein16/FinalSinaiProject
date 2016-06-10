//
//  ConsentViewController.swift
//  TestCareKit
//
//  Created by Zachary Bernstein on 5/13/16.
//  Copyright © 2016 Zachary Bernstein. All rights reserved.

import UIKit
import ResearchKit
/*
 If the user opens the app for the first time, this ViewController will present the survey to signup. However, if the user has already completed the survey, it will navigate right to the main app.
*/
class ConsentViewController: UIViewController {
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    override func viewDidLoad() {
        appDelegate.client = MSClient(applicationURLString:"https://zachservice.azure-mobile.net/")
        appDelegate.adherenceTable = appDelegate.client!.tableWithName("Adherence")
        appDelegate.patientTable = appDelegate.client!.tableWithName("Patient")
        appDelegate.PatientMedFreqTable = appDelegate.client!.tableWithName("Patient_Med_Freq")
        appDelegate.medicationTable = appDelegate.client!.tableWithName("Medication")
        
        
            //Check if user has completed survey
            if NSUserDefaults.standardUserDefaults().boolForKey("surveyCompleted") == true
            {
                self.appDelegate.uploadInformation()
                self.performSegueWithIdentifier("toMain", sender: nil)
            }
            else
            {
                UIApplication.sharedApplication().scheduledLocalNotifications?.removeAll()
                let taskViewController = ORKTaskViewController(task: ConsentTask, taskRunUUID: nil)
                taskViewController.delegate = self
                self.navigationController!.pushViewController(taskViewController, animated: true)

            }

        
        

        
        
    }
    
}
extension ConsentViewController : ORKTaskViewControllerDelegate {
    
    func taskViewController(taskViewController: ORKTaskViewController, didFinishWithReason reason: ORKTaskViewControllerFinishReason, error: NSError?) {
        
        if reason == ORKTaskViewControllerFinishReason.Completed{
            //IF SURVEY WAS COMPLETED
            //Save document to PDF
            

            let dob = taskViewController.result.stepResultForStepIdentifier("dateOfBirthPage")!.firstResult! as! ORKDateQuestionResult
            let dateString = dob.dateAnswer!.monthDayYearString()
            
            
                    let copy = ConsentDocument.copy() as! ORKConsentDocument
                    let signature:ORKConsentSignatureResult! = taskViewController.result.stepResultForStepIdentifier("ConsentReviewStep")!.firstResult! as! ORKConsentSignatureResult
         
                    let firstName = signature.signature!.givenName!
                    let lastName = signature.signature!.familyName!
            
            //Make PDF of Contract
            signature.applyToDocument(copy)
            copy.makePDFWithCompletionHandler() {
                PDFData, errorOrNil in
                if let error = errorOrNil {
                    print(error.localizedDescription)
                }
                else
                {
                    
                  
                    
                    
                    let file = "consent.pdf" //this is the file. we will write to and read from it
                    if let dir = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.AllDomainsMask, true).first {
                        let path = NSURL(fileURLWithPath: dir).URLByAppendingPathComponent(file)
                        
                        
                        //writing
                        do {
                            try PDFData!.writeToURL(path, options: NSDataWritingOptions.DataWritingAtomic)
                        }
                        catch { print("Falied to write signature") }
                    }
                    
                }
            }

            
            //Add new patient to Patient Table
            let alert = UIAlertController(title: nil, message: "Please wait...", preferredStyle: .Alert)
            
            
            //Create Loading
            alert.view.tintColor = UIColor.blackColor()
            let loadingIndicator: UIActivityIndicatorView = UIActivityIndicatorView(frame: CGRectMake(10, 5, 50, 50)) as UIActivityIndicatorView
            loadingIndicator.hidesWhenStopped = true
            loadingIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.Gray
            loadingIndicator.startAnimating();
            alert.view.addSubview(loadingIndicator)
            presentViewController(alert, animated: true, completion: nil)
            self.view.userInteractionEnabled = false
            
            //let newPatient:Dictionary<String,AnyObject> = ["First_Name":firstName,"Last_Name":lastName,"Date_Of_Birth":dateString]
            
            

            let firstNamePredicate = NSPredicate(format: "First_Name == \(firstName)")
            let lastNamePredicate = NSPredicate(format: "Last_Name == \(lastName)")
            let dateOfBirthPredicate = NSPredicate(format: "Date_Of_Birth == '\(dateString)'")
            let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [firstNamePredicate,lastNamePredicate,dateOfBirthPredicate])
            
            let query = appDelegate.patientTable!.queryWithPredicate(compoundPredicate)
            query.readWithCompletion()
            {
              (result, errorOrNil) in
                if let error = errorOrNil
                {
                    if error.domain == NSURLErrorDomain && error.code == NSURLErrorNotConnectedToInternet {
                        let alert = UIAlertController(title: "Error", message:"Not Connected To Internet", preferredStyle: .Alert)
                        alert.addAction(UIAlertAction(title: "Okay", style: .Default) { _ in })
                        self.presentViewController(alert, animated: true){}
                    }
                    else {
                        let alert = UIAlertController(title: "Error", message:"Try again later", preferredStyle: .Alert)
                        alert.addAction(UIAlertAction(title: "Okay", style: .Default) { _ in })
                        self.presentViewController(alert, animated: true){}
                        
                    }
                }
                else
                {
                    
                    //Previous account already found
                    if let item = result.items.first
                    {
                        NSUserDefaults.standardUserDefaults().setInteger(item["id"] as! Int, forKey: Constants.userIdKey)
                        print("Patient ID: \(item["id"])")
                        self.view.userInteractionEnabled = true
                        self.dismissViewControllerAnimated(false, completion: nil)
                        
                        
                    }
                    else
                    {
                        //Create New patient
                        let newPatient:Dictionary<String,AnyObject> = ["First_Name":firstName,"Last_Name":lastName,"Date_Of_Birth":dateString]
                        self.appDelegate.patientTable!.insert(newPatient) {
                            (res, errOrNil) in
                            if let error = errOrNil {
                                
                                self.view.userInteractionEnabled = true
                                self.dismissViewControllerAnimated(false, completion: nil)
                                print("Error",error)
                                print("ERROR CODE: " + String(error.code))
                                
                                if error.domain == NSURLErrorDomain && error.code == NSURLErrorNotConnectedToInternet {
                                    let alert = UIAlertController(title: "Error", message:"Not Connected To Internet", preferredStyle: .Alert)
                                    alert.addAction(UIAlertAction(title: "Okay", style: .Default) { _ in })
                                    self.presentViewController(alert, animated: true){}
                                }
                                else {
                                    let alert = UIAlertController(title: "Error", message:"Try again later", preferredStyle: .Alert)
                                    alert.addAction(UIAlertAction(title: "Okay", style: .Default) { _ in })
                                    self.presentViewController(alert, animated: true){}
                                }
                                
                            }
                            else if let it = res
                            {
                                self.view.userInteractionEnabled = true
                                self.dismissViewControllerAnimated(false, completion: nil)
                                NSUserDefaults.standardUserDefaults().setInteger(it["id"] as! Int, forKey: Constants.userIdKey)
                                //ONCE SURVEY COMPLETED, AND USER CREATED, NAVIGATE TO MAIN APP
                                self.navigationController!.popViewControllerAnimated(false)
                                self.performSegueWithIdentifier("toMain", sender: nil)
                                print("Patient ID: \(it["id"])")

                            }
                            
                        }

                }
                
            }
                
//                appDelegate.patientTable!.insert(newPatient) { (result, errorOrNil) in
//                if let error = errorOrNil {
//                    
//                    self.view.userInteractionEnabled = true
//                    self.dismissViewControllerAnimated(false, completion: nil)
//                    print("Error",error)
//                    print("ERROR CODE: " + String(error.code))
//                    
//                        if error.domain == NSURLErrorDomain && error.code == NSURLErrorNotConnectedToInternet {
//                            let alert = UIAlertController(title: "Error", message:"Not Connected To Internet", preferredStyle: .Alert)
//                            alert.addAction(UIAlertAction(title: "Okay", style: .Default) { _ in })
//                            self.presentViewController(alert, animated: true){}
//                        }
//                        else {
//                            let alert = UIAlertController(title: "Error", message:"Try again later", preferredStyle: .Alert)
//                            alert.addAction(UIAlertAction(title: "Okay", style: .Default) { _ in })
//                            self.presentViewController(alert, animated: true){}
//                        }
//            
//                } else if let item = result {
//                    self.view.userInteractionEnabled = true
//                    self.dismissViewControllerAnimated(false, completion: nil)
//                    print("Patient It")
//                    print(item["id"] as! Int)
//                NSUserDefaults.standardUserDefaults().setInteger(item["id"] as! Int, forKey: Constants.userIdKey)
//                    //ONCE SURVEY COMPLETED, AND USER CREATED, NAVIGATE TO MAIN APP
//                    self.navigationController!.popViewControllerAnimated(false)
//                    self.performSegueWithIdentifier("toMain", sender: nil)
//                }
//                }
            
            
                    
            
           
            
            }
        }
        else {
            //IF SURVEY NOT COMPLETED, RESTART SURVEY
            self.navigationController!.popViewControllerAnimated(false)
            let taskViewController = ORKTaskViewController(task: ConsentTask, taskRunUUID: nil)
            taskViewController.delegate = self
            self.navigationController!.pushViewController(taskViewController, animated: true)
        }
        
    }
    
}