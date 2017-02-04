//
//  InterfaceController.swift
//  MatListan Watch Extension
//
//  Created by Moon Technolabs on 07/07/16.
//  Copyright © 2016 Consumiq AB. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity


protocol TimerListDelegate {
    func reloadTimerListScreen()
}

class InterfaceController: WKInterfaceController, WCSessionDelegate, LowestTimerDelegate {

    @IBOutlet var mainGroup: WKInterfaceGroup!
    @IBOutlet var noLoginGroup: WKInterfaceGroup!
    @IBOutlet var optionGroup: WKInterfaceGroup!
    @IBOutlet var itemNameGroup: WKInterfaceGroup!

    @IBOutlet var timerBtn: WKInterfaceButton!
    @IBOutlet var selectedItemBtn: WKInterfaceButton!

    var timerListDelegate : TimerListDelegate?

    var timerDic : NSMutableDictionary = NSMutableDictionary()


    var fetchedAppDetails : Bool = false

    var authorisedInApp : Bool = true

    var timerOptionIsHidden = true


    var itemNameStr : String?
    var itemID : String?



    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        if WCSession.isSupported()
        {
            let session:WCSession = WCSession.defaultSession()
            session.delegate = self;
            session.activateSession()
        }

            self.hideLoginGroup(true)

        self.hideTimerOption(true)
        self.setupScreen()

        // Configure interface objects here.
    }

    func hideLoginGroup(hide:Bool) {
        noLoginGroup.setHidden(hide)
        optionGroup.setHidden(!hide)
        itemNameGroup.setHidden(!hide)
    }

    @IBAction func setupScreen(){

        selectedItemBtn.setTitle(NSLocalizedString("Fetching Data...", comment: ""))
        let message : [String : AnyObject]
        message = [
            "REQUEST_TYPE":"GET_SELECTED_ITEM",
        ]

        WCSession.defaultSession().sendMessageData(NSKeyedArchiver.archivedDataWithRootObject(message), replyHandler:{ data in
                let dataDict:NSDictionary? = NSKeyedUnarchiver.unarchiveObjectWithData(data)! as? NSDictionary

                let authorised : NSString? = dataDict!["AUTHORIZED"] as? NSString

                if ((authorised?.isEqualToString("1")) != false){
                    self.authorisedInApp = true
                    self.showLoginMsg(true)
                    let title :NSString? = dataDict!["SELECTED_ITEM"] as? NSString
                    if (title != nil){
                        self.itemID = dataDict?.valueForKey("SELECTED_ITEM_ID") as? String
                        self.selectedItemBtn.setTitle(dataDict?.valueForKey("SELECTED_ITEM") as? String)
                        self.fetchedAppDetails = true
                    }
                }
                else{
                    self.authorisedInApp = false
                    self.showLoginMsg(false)
                }



            }, errorHandler: {error in
                        print("error: \(error)")

        })

        getTimerData()
    }

    func getTimerData() {
        let message : [String : AnyObject]
        message = [
            "REQUEST_TYPE":"GET_TIMER_DATA",
        ]

        WCSession.defaultSession().sendMessageData(NSKeyedArchiver.archivedDataWithRootObject(message), replyHandler:{ data in

            }, errorHandler: {error in
                print("error: \(error)")

        })

    }

    override func willActivate() {

        super.willActivate()

        if itemNameStr != nil {
            self.selectedItemBtn.setTitle(itemNameStr)
        }

        getTimerData()

        if self.timerDic.allKeys.count < 1 {
            self.hideTimerOption(true)
        }else{
            let tempArr : NSArray = self.timerDic.allKeys
            for recipe in tempArr {
                let recipeObj : WatchRecipeTimer = self.timerDic.objectForKey(recipe) as! WatchRecipeTimer
                recipeObj.timerUpdateDelegate = nil
                recipeObj.rowIndex = -1
            }
        }

        self.timerListDelegate = nil

        // This method is called when watch view controller is about to be visible to user

    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

    /*
    func playSound(){
                let  assetURL : NSURL = NSBundle.mainBundle().URLForResource("notification_sound", withExtension: "mp3")!
                let asset : WKAudioFileAsset = WKAudioFileAsset.init(URL: assetURL)
                let playerItm : WKAudioFilePlayerItem = WKAudioFilePlayerItem.init(asset: asset)
                let audioFilePlayer : WKAudioFilePlayer = WKAudioFilePlayer.init(playerItem: playerItm)
        
        
        
                if (audioFilePlayer.status == .ReadyToPlay) {
                    audioFilePlayer.play()
                }

                        let myBundle = NSBundle.mainBundle()
                        if let movieURL = myBundle.URLForResource("notification_sound", withExtension: "mp3") {
        
                            self.presentMediaPlayerControllerWithURL(movieURL,
                                                                     options: [WKMediaPlayerControllerOptionsAutoplayKey: true],
                                                                     completion: { (didPlayToEnd : Bool,
                                                                        endTime : NSTimeInterval,
                                                                        error : NSError?) -> Void in
        
                                                                        self.dismissMediaPlayerController()
        
                                                                        if let anErrorOccurred = error {
                                                                            // Handle the error.
                                                                        }
                                                                        // Perform other tasks
                            })
                            
                        }
    }

    */

    @IBAction func addNewItem() {



        if self.fetchedAppDetails && self.authorisedInApp  {
            self.presentControllerWithName("SuggesitionListInterfaceController", context: self)

        }else if !self.authorisedInApp {
            self.showLoginMsg(false)
            self.setupScreen()
        }else{
            let h0 = { self.setupScreen()}

            let action1 = WKAlertAction(title: "OK", style: .Default, handler:h0)

            presentAlertControllerWithTitle(NSLocalizedString("Error", comment: ""), message: NSLocalizedString("Please wait, getting data from app", comment: ""), preferredStyle: .ActionSheet, actions: [action1])
        }
    }



    @IBAction func showCartList() {

        if self.fetchedAppDetails && self.authorisedInApp  {
            self.pushControllerWithName("StoreListController", context: self)

        }else if !self.authorisedInApp {
            self.showLoginMsg(false)
            self.setupScreen()
        }else{
            let h0 = { self.setupScreen()}

            let action1 = WKAlertAction(title: "OK", style: .Default, handler:h0)

            presentAlertControllerWithTitle(NSLocalizedString("Alert", comment: ""), message: NSLocalizedString("Please wait, getting data from app", comment: ""), preferredStyle: .ActionSheet, actions: [action1])
        }


    }

    func showLoginMsg(showLoginMsg: Bool) {
        if showLoginMsg {
            noLoginGroup.setHidden(true)
            optionGroup.setHidden(false)
            itemNameGroup.setHidden(false)
        }else{
            noLoginGroup.setHidden(false)
            optionGroup.setHidden(true)
            itemNameGroup.setHidden(true)
        }
    }


    @IBAction func getItemList() {

        if self.fetchedAppDetails && self.authorisedInApp  {
            self.pushControllerWithName("ItemListInterfaceController", context: self)

        }else if !self.authorisedInApp {
            self.showLoginMsg(false)
            self.setupScreen()
        }else{
            let h0 = { self.setupScreen()}

            let action1 = WKAlertAction(title: "OK", style: .Default, handler:h0)

            presentAlertControllerWithTitle(NSLocalizedString("Alert", comment: ""), message: NSLocalizedString("Please wait, getting data from app", comment: ""), preferredStyle: .ActionSheet, actions: [action1])
        }
    }

    @IBAction func openTimerList() {
        if self.timerDic.allKeys.count>0 {
            if self.timerDic.allKeys.count == 1 {
                for key in self.timerDic.allKeys {
                    let dic : NSMutableDictionary = NSMutableDictionary()
                    let recipeObj : WatchRecipeTimer = self.timerDic.valueForKey(key as! String) as! WatchRecipeTimer
                    dic.setObject(recipeObj, forKey: "recipeObj")
                    dic.setObject(self, forKey: "homeVC")
                    self.pushControllerWithName("TimerDetailInterfaceController", context: dic)
                    break
                }
            }
            else{
                self.pushControllerWithName("TimerListInterfaceController", context: self)
            }
        }else{
            self.hideTimerOption(true)
        }
    }

    func updateLowestTimerValue(time: NSString) {
        self.timerBtn.setTitle(time as String)
    }

    func changeDelegate(recipeID: NSString) {

        self.timerDic.removeObjectForKey(recipeID)

        if self.timerDic.allKeys.count < 1 {
            self.hideTimerOption(true)
        }else{
            self.updateDelegateForLowestTimer()
        }
    }

    func updateDelegateForLowestTimer() {

        let tempArr : NSArray = self.timerDic.allKeys
        let recipeArr : NSMutableArray = NSMutableArray()

        for key in tempArr {
            recipeArr.addObject(self.timerDic.objectForKey(key)!)
        }

        let sortArr =  recipeArr.sort { ( obj1 , obj2 ) in
            let recipeObj1 = obj1 as! WatchRecipeTimer
            let recipeObj2 = obj2 as! WatchRecipeTimer
            return recipeObj1.secondsLeft < recipeObj2.secondsLeft
        }

        for (index,recipe) in sortArr.enumerate() {
            let recipeObj : WatchRecipeTimer = recipe as! WatchRecipeTimer
            if index == 0 {
                recipeObj.lowestTimerDelegare = self
            }else{
                recipeObj.lowestTimerDelegare = nil
            }

        }

    }

    func enableUserInteracton(enable: Bool)  {
        self.enableUserInteracton(enable)
    }

    func hideTimerOption(hide:Bool) {
        timerBtn.setHidden(hide)
        timerOptionIsHidden = hide

        if hide {
            let tempArr:NSArray = self.timerDic.allKeys

            for key in tempArr {
                let recipeObj : WatchRecipeTimer = self.timerDic.objectForKey(key) as! WatchRecipeTimer
                recipeObj.stopTimer()
            }

            self.timerDic.removeAllObjects()
            itemNameGroup.setHeight(60)
            mainGroup.setContentInset(UIEdgeInsetsMake(15, 10, 10, 10))
            optionGroup.setHeight(50)
            self.timerBtn.setTitle("")
        }else{

            itemNameGroup.setHeight(50)
            optionGroup.setHeight(42)
            mainGroup.setContentInset(UIEdgeInsetsMake(0, 10, 10, 10))

        }
    }

    func session(session: WCSession, didReceiveApplicationContext applicationContext: [String : AnyObject]) {

        if applicationContext["SELECTED_ITEM"] != nil {
            self.authorisedInApp = true
            self.hideLoginGroup(true)
            let title :NSString? = applicationContext["SELECTED_ITEM"] as? NSString
            if (title != nil && self.itemID == nil){
                self.itemID = applicationContext["SELECTED_ITEM_ID"] as? String
                self.selectedItemBtn.setTitle(applicationContext["SELECTED_ITEM"] as? String)
                self.fetchedAppDetails = true
            }
        }else if applicationContext["SHOW_TIMER"] != nil {
            let showTimer :NSString? = applicationContext["SHOW_TIMER"] as? NSString
            if showTimer?.isEqualToString("1") == true{
                let tempArr : NSMutableArray = (applicationContext["TIMER_ARR"] as? NSMutableArray)!
                if tempArr.count>0 {
                    var isAddedNew : Bool = false

                    for dic in tempArr {
                        let recipeBoxID : NSString = dic.valueForKey("recipeboxId") as! NSString
                        if self.timerDic.objectForKey(recipeBoxID) != nil {
                            let recipeTimer : WatchRecipeTimer = self.timerDic.objectForKey(recipeBoxID) as! WatchRecipeTimer
                            recipeTimer.initWithRecipieDic(recipeDic: dic as! NSMutableDictionary)
                            //                recipeTimer.updateTime()
                            recipeTimer.startTimer()

                        }else{
                            let recipeTimer : WatchRecipeTimer = WatchRecipeTimer.init()
                            recipeTimer.initWithRecipieDic(recipeDic: dic as! NSMutableDictionary)
                            recipeTimer.startTimer()
                            self.timerDic.setObject(recipeTimer, forKey: recipeBoxID)

                            isAddedNew = true
                        }
                    }

                    if isAddedNew && timerListDelegate != nil {

                        timerListDelegate?.reloadTimerListScreen()

                    }

                    self.updateDelegateForLowestTimer()

                    if tempArr.count == 1 && timerOptionIsHidden {
                        let dic : NSMutableDictionary = tempArr.objectAtIndex(0) as! NSMutableDictionary
                        let secondsLeft = ((dic.valueForKey("secondsLeft") as! NSString).integerValue)
                        var temp : NSInteger = (NSInteger)(secondsLeft)
                        let hours = temp / 3600;

                        temp = (NSInteger)(secondsLeft % 3600)
                        let minutes = temp / 60;

                        let seconds = temp % 60;
                        
                        let tempStr = String(format: "%02d:%02d:%02d",hours, minutes, seconds)

                        self.timerBtn.setTitle(tempStr)

                    }

                    self.hideTimerOption(false)

                }else{
                    self.hideTimerOption(true)
                }

            }else{
                self.hideTimerOption(true)
            }


        }else if applicationContext["STOP_TIMER_ID"] != nil{

            let recipeBoxID : NSString = applicationContext["STOP_TIMER_ID"] as! NSString

            if self.timerDic.objectForKey(recipeBoxID) != nil {
                let recipeTimer : WatchRecipeTimer = self.timerDic.objectForKey(recipeBoxID) as! WatchRecipeTimer
                recipeTimer.stopTimer()
                self.timerDic.removeObjectForKey(recipeBoxID)
                print("test2\(recipeBoxID)")
            }

            if self.timerDic.allKeys.count < 1 {
                self.hideTimerOption(true)
            }else{
                self.updateDelegateForLowestTimer()
            }
        }else if applicationContext["UPDATE_TIMER"] != nil{

            let dic : NSMutableDictionary = applicationContext["UPDATE_TIMER"] as! NSMutableDictionary
            let recipeBoxID : NSString = dic.valueForKey("recipeboxId") as! NSString

            if self.timerDic.objectForKey(recipeBoxID) != nil {
                let recipeTimer : WatchRecipeTimer = self.timerDic.objectForKey(recipeBoxID) as! WatchRecipeTimer
                recipeTimer.initWithRecipieDic(recipeDic: dic)
//                recipeTimer.updateTime()
                recipeTimer.startTimer()
            }else{
                let recipeTimer : WatchRecipeTimer = WatchRecipeTimer.init()
                recipeTimer.initWithRecipieDic(recipeDic: dic)
                recipeTimer.startTimer()
                self.timerDic.setObject(recipeTimer, forKey: recipeBoxID)
            }

            if timerListDelegate != nil {

                timerListDelegate?.reloadTimerListScreen()

            }
            self.updateDelegateForLowestTimer()
        }
            /*
        else if applicationContext["START_TIMER"] != nil{

            let recipeDic : NSMutableDictionary = applicationContext["START_TIMER"] as! NSMutableDictionary
            let recipeBoxID : NSString = recipeDic.valueForKey("recipeboxId") as! NSString

            if self.timerDic.objectForKey(recipeBoxID) != nil {
                let recipeTimer : WatchRecipeTimer = self.timerDic.objectForKey(recipeBoxID) as! WatchRecipeTimer
                recipeTimer.initWithRecipieDic(recipeDic: recipeDic)
                recipeTimer.updateTime()
            }else{
                let recipeTimer : WatchRecipeTimer = WatchRecipeTimer.init()
                recipeTimer.initWithRecipieDic(recipeDic: recipeDic)
                recipeTimer.startTimer()
                recipeTimer.relodView()
                self.timerDic.setObject(recipeTimer, forKey: recipeBoxID)
            }
            if timerListDelegate != nil {
                timerListDelegate?.reloadTimerListScreen()
            }
            
        }
        */

    }

}
