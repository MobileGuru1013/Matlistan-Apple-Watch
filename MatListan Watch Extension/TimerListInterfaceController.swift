//
//  TimerListInterfaceController.swift
//  Matlistan
//
//  Created by on 29/07/16.
//  Copyright © 2016 Consumiq AB. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity


class TimerListInterfaceController: WKInterfaceController,WatchRecipeTimerDelegate, TimerListDelegate {

    @IBOutlet var timerListTable: WKInterfaceTable!

    var recipeArr : NSMutableArray = NSMutableArray()
    var homeInterfaceVC : InterfaceController!


    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)

        homeInterfaceVC = context as! InterfaceController

        // Configure interface objects here.
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()

        homeInterfaceVC.timerListDelegate = self;

        relodTimerTable()

        let message : [String : AnyObject]
        message = [
            "REQUEST_TYPE":"GET_TIMER_DATA",
        ]

        WCSession.defaultSession().sendMessageData(NSKeyedArchiver.archivedDataWithRootObject(message), replyHandler:{ data in

            }, errorHandler: {error in
                print("error: \(error)")

        })

    }

    func relodTimerTable(){

        recipeArr.removeAllObjects()

        let tempArr : NSArray = homeInterfaceVC.timerDic.allKeys

        for key in tempArr {
            recipeArr.addObject(homeInterfaceVC.timerDic.objectForKey(key)!)
        }

        let sortArr =  recipeArr.sort { ( obj1 , obj2 ) in
            let recipeObj1 = obj1 as! WatchRecipeTimer
            let recipeObj2 = obj2 as! WatchRecipeTimer
            return recipeObj1.secondsLeft < recipeObj2.secondsLeft
        }

        recipeArr = NSMutableArray (array: sortArr)

        timerListTable.setNumberOfRows(recipeArr.count, withRowType: "TimerCell")

        for (index, name) in recipeArr.enumerate() {
            let row = timerListTable.rowControllerAtIndex(index) as! TimerCell
            let recipeObj : WatchRecipeTimer = name as! WatchRecipeTimer
            recipeObj.timerUpdateDelegate = self

            if index == 0 {
                recipeObj.lowestTimerDelegare = homeInterfaceVC
            }else{
                recipeObj.lowestTimerDelegare = nil
            }

            recipeObj.rowIndex = index
            //row.itemNameLbl.setText(name.valueForKey("name") as? String)
            let timerText = recipeObj.countTimer as String
            row.timerCount.setText( timerText)

            let recipeName = recipeObj.recipeDesc as String
            row.recipeName.setText(recipeName)
        }
    }

    override func table(table: WKInterfaceTable, didSelectRowAtIndex rowIndex: Int) {

        let recipeObj : WatchRecipeTimer = self.recipeArr.objectAtIndex(rowIndex) as! WatchRecipeTimer

        let dic : NSMutableDictionary = NSMutableDictionary()

        dic.setObject(recipeObj, forKey: "recipeObj")
        dic.setObject(homeInterfaceVC, forKey: "homeVC")
        self.pushControllerWithName("TimerDetailInterfaceController", context: dic)
    }

    func timerUpdate(time: NSString, forIndex index: NSInteger) {

        if (index >= 0 && index < self.recipeArr.count) {
            let row = timerListTable.rowControllerAtIndex(index) as! TimerCell
            row.timerCount.setText(time as String)
        }
    }

    func timerStop(recipeID: NSString, index: NSInteger) {

        let recipeObj : WatchRecipeTimer = self.recipeArr.objectAtIndex(index) as! WatchRecipeTimer

        if recipeObj.recipeboxId == recipeID.integerValue {
            self.recipeArr.removeObjectAtIndex(index)
            self.homeInterfaceVC.timerDic.removeObjectForKey(recipeID)

            if self.recipeArr.count < 1 {
                self.popController()
                return
            }

            for (index,recipe) in self.recipeArr.enumerate() {
                let recipeObj : WatchRecipeTimer = recipe as! WatchRecipeTimer
                recipeObj.rowIndex = index
            }

            let indexSet = NSIndexSet.init(index: index)
            timerListTable.removeRowsAtIndexes(indexSet)
        }
    }

    func reloadTimerListScreen() {
         self.relodTimerTable()
    }

    override func willDisappear() {

    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()

    }
}
