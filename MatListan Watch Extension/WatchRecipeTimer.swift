//
//  WatchRecipeTimer.swift
//  Matlistan
//
//  Created by on 29/07/16.
//  Copyright © 2016 Consumiq AB. All rights reserved.
//

import WatchKit

protocol WatchRecipeTimerDelegate {
    func timerUpdate(time : NSString, forIndex index: NSInteger)
    func timerStop(recipeID : NSString ,index: NSInteger)
}

protocol LowestTimerDelegate {
    func updateLowestTimerValue(time : NSString)
    func changeDelegate(recipeID: NSString)
}

class WatchRecipeTimer: NSObject {
    var recipeTimer : NSTimer!
    var recipeboxId : NSInteger = 0
    var recipeTimerId : NSInteger = 0
    var recipeName : NSString = ""
    var recipeDesc : NSString = ""
    var countTimer : NSString = ""
    var secondsLeft : NSTimeInterval = 0.0
    var interval : NSTimeInterval = 0.0
    var tempSecondsLeft : NSTimeInterval = 0.0
    var hours : NSInteger = 0
    var minutes : NSInteger = 0
    var seconds : NSInteger = 0
    var recipeDic : NSMutableDictionary! = NSMutableDictionary()

    var rowIndex : NSInteger = -1


    var timerUpdateDelegate : WatchRecipeTimerDelegate?

    var lowestTimerDelegare : LowestTimerDelegate?




    func initWithRecipieDic(recipeDic dic:NSMutableDictionary){

        if self.recipeTimer != nil {
            self.recipeTimer.invalidate()
        }

        recipeDic = dic;
        self.recipeboxId = (dic.valueForKey("recipeboxId")?.integerValue)! //recipeId.integerValue;
        self.recipeName =  dic.valueForKey("recipeName") as! NSString
        self.recipeTimerId = 0; //it is zero by default
        self.recipeDesc = dic.valueForKey("recipeDesc") as! NSString;
        self.secondsLeft = ((dic.valueForKey("secondsLeft") as? NSString)?.doubleValue)!

        var appDate : NSDate = dic.valueForKey("date") as! NSDate
        let interVal : NSTimeInterval = NSDate().timeIntervalSinceDate(appDate)

        appDate = dic.valueForKey("start_date") as! NSDate

        let startInterval : NSTimeInterval = NSDate().timeIntervalSinceDate(appDate)


        print("interval \(interVal) Before: \(self.secondsLeft)")
        if interVal>0 {
            self.secondsLeft = (self.secondsLeft - interVal )
            print("interval \(interVal) After: \(self.secondsLeft)")
        }

        if startInterval > 0 {
            let dt : Double = floor(startInterval)
            if startInterval - dt > 0 {
                self.secondsLeft = self.secondsLeft + (startInterval - dt)
            }

            print("dt \(dt) After: \(self.secondsLeft)")

        }

        self.updateCounterTimeLable()
    }

    func startNewTimer() {
        startTimer()
    }

    func startTimer() {
        dispatch_async(dispatch_get_main_queue()) { 
            self.recipeTimer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: #selector(self.updateTime), userInfo: nil, repeats: true)
            NSRunLoop.currentRunLoop().addTimer(self.recipeTimer, forMode: NSRunLoopCommonModes)

        }
    }

    func stopTimer() {

        print("Stop : \(self.recipeboxId)")

        if (self.recipeTimer != nil) {
            self.recipeTimer.invalidate()
        }
        self.recipeTimer = nil

        if self.secondsLeft < 1 {
            WKInterfaceDevice().playHaptic(.Notification)
        }

        if self.timerUpdateDelegate != nil {

            let recipeID = "\(self.recipeboxId)"
            self.timerUpdateDelegate?.timerStop(recipeID, index: self.rowIndex)
            self.timerUpdateDelegate = nil
        }

        if self.lowestTimerDelegare != nil {
            let timerID : NSString = NSString(string: String((self.recipeboxId) as NSInteger))
            self.lowestTimerDelegare?.changeDelegate(timerID)
        }
    }

    func updateTime() {
        self.secondsLeft = self.secondsLeft - 1
        if(self.secondsLeft > 0 )
        {

            self.updateCounterTimeLable()

            if timerUpdateDelegate != nil {
                timerUpdateDelegate?.timerUpdate(countTimer, forIndex: self.rowIndex)
            }

            if lowestTimerDelegare != nil {
                lowestTimerDelegare?.updateLowestTimerValue(countTimer)
            }

        }
        else
        {
            hours = 0
            minutes = 0
            seconds = 0

            let tempStr = String(format: "%02d:%02d:%02d",self.hours, self.minutes, self.seconds)

            countTimer = NSString(string: tempStr)

            self.stopTimer()
        }
    }
  

    func updateCounterTimeLable() {
        var temp : NSInteger = (NSInteger)(self.secondsLeft)
        hours = temp / 3600;

        temp = (NSInteger)(self.secondsLeft % 3600)
        minutes = temp / 60;

        seconds = temp % 60;

        let tempStr = String(format: "%02d:%02d:%02d",self.hours, self.minutes, self.seconds)

        countTimer = NSString(string: tempStr)
//         print(countTimer)
    }

}
