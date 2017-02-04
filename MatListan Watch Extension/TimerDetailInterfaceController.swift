//
//  TimerDetailInterfaceController.swift
//  Matlistan
//
//  Created by on 01/08/16.
//  Copyright © 2016 Consumiq AB. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity


class TimerDetailInterfaceController: WKInterfaceController,WatchRecipeTimerDelegate, TimerListDelegate {
    
    @IBOutlet var recipeNameLbl: WKInterfaceLabel!
    @IBOutlet var timerLbl: WKInterfaceLabel!

    var recipeObj : WatchRecipeTimer?
    var homeInterfaceVC : InterfaceController?

    var interactionEnable : Bool = true

    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)

        let dic : NSMutableDictionary = (context as? NSMutableDictionary)!
        recipeObj = dic.objectForKey("recipeObj") as? WatchRecipeTimer
        homeInterfaceVC = dic.objectForKey("homeVC") as? InterfaceController

        homeInterfaceVC!.timerListDelegate = self

        recipeNameLbl.setText(recipeObj!.recipeDesc as String)
        timerLbl.setText(recipeObj!.countTimer as String)

        recipeObj?.timerUpdateDelegate = self;
        // Configure interface objects here.
    }



    func timerUpdate(time: NSString, forIndex index: NSInteger) {
         timerLbl.setText(recipeObj!.countTimer as String)
    }

    func timerStop(recipeID: NSString, index: NSInteger) {
        self.homeInterfaceVC!.timerDic.removeObjectForKey(recipeID)
        self.popController()
    }

    @IBAction func stopTimerFromWatch() {

        if interactionEnable == false {
            return
        }

        interactionEnable = false

        let message : [String : AnyObject]

        let recipeBoxID : String = String((recipeObj?.recipeboxId)! as NSInteger)


        message = [
            "REQUEST_TYPE":"STOP_TIMER_ID",
            "TIMER_ID":recipeBoxID,
        ]

        WCSession.defaultSession().sendMessageData(NSKeyedArchiver.archivedDataWithRootObject(message), replyHandler:{ data in
            let dataDict:NSDictionary? = NSKeyedUnarchiver.unarchiveObjectWithData(data)! as? NSDictionary

            if dataDict != nil{
                self.recipeObj?.stopTimer()
            }
            self.interactionEnable = true

            }, errorHandler: {error in
            self.interactionEnable = true
        })

    }

    @IBAction func addOneMinInTimer() {

        if interactionEnable == false {
            return
        }

        interactionEnable = false

//        recipeObj?.tempSecondsLeft = (recipeObj?.secondsLeft)!
//        recipeObj?.secondsLeft = (recipeObj?.tempSecondsLeft)! + 60.0

        let message : [String : AnyObject]

        let recipeBoxID : String = String((recipeObj?.recipeboxId)! as NSInteger)


        message = [
            "REQUEST_TYPE":"ADD_MIN_IN_TIMER",
            "TIMER_ID":recipeBoxID,
        ]

        WCSession.defaultSession().sendMessageData(NSKeyedArchiver.archivedDataWithRootObject(message), replyHandler:{ data in
            let dataDict:NSDictionary? = NSKeyedUnarchiver.unarchiveObjectWithData(data)! as? NSDictionary

            if dataDict != nil{
//                self.recipeObj?.stopTimer()
            }
            self.interactionEnable = true

            }, errorHandler: {error in
                    self.interactionEnable = true
        })

    }
    

    func reloadTimerListScreen() {
//        recipeObj?.updateTime()
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()

        let message : [String : AnyObject]
        message = [
            "REQUEST_TYPE":"GET_TIMER_DATA",
        ]

        WCSession.defaultSession().sendMessageData(NSKeyedArchiver.archivedDataWithRootObject(message), replyHandler:{ data in

            }, errorHandler: {error in
                print("error: \(error)")
                
        })
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}
