//
//  ItemListInterfaceController.swift
//  Matlistan
//
//  Created by Moon Technolabs on 09/07/16.
//  Copyright © 2016 Consumiq AB. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity

class ItemListInterfaceController: WKInterfaceController, WCSessionDelegate {

    @IBOutlet var itemListTbl: WKInterfaceTable!

    var itemListArr : NSMutableArray? = []
    
    var selectedItem : NSMutableDictionary?

    var selectedIndex:Int = 2

    var interfaceVC :InterfaceController?

    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)

        interfaceVC = (context as? InterfaceController)!

        self.getItemList()

        // Configure interface objects here.
    }

    func getItemList() {

        let message : [String : AnyObject]
        message = [
            "REQUEST_TYPE":"GET_ITEM_LIST",
        ]

        WCSession.defaultSession().sendMessageData(NSKeyedArchiver.archivedDataWithRootObject(message), replyHandler:{ data in
            let dataDict:NSDictionary? = NSKeyedUnarchiver.unarchiveObjectWithData(data)! as? NSDictionary

            self.updateDataOfTableForDic(dataDict!)

            }, errorHandler: {error in
                print("error: \(error)")
        })
    }

    func updateDataOfTableForDic(dataDict : NSDictionary) {
        self.itemListArr  = (dataDict.valueForKey("ITEM_LIST"))! as? NSMutableArray

        self.selectedItem = (dataDict.valueForKey("SELECTED_ITEM"))! as? NSMutableDictionary

        if self.selectedItem!.objectForKey("item_listID") == nil{
            self.selectedItem = (self.itemListArr?.firstObject) as? NSMutableDictionary
        }
        self.itemListTbl.setNumberOfRows(self.itemListArr!.count, withRowType: "ItemListCell")

        self.loadITemListTABLE()
    }

    func loadITemListTABLE()
    {
        let selectedItem :NSString = self.interfaceVC!.itemID!

        for (index, name) in itemListArr!.enumerate() {
            let row = itemListTbl.rowControllerAtIndex(index) as! ItemListCell

            row.itemNameLbl.setText(name.valueForKey("name") as? String)

            let rowID : NSString = name.objectForKey("item_listID") as! NSString


            if (selectedItem.isEqualToString(rowID as String))
            {
                row.greenBackground.setBackgroundColor(UIColor(red: 114/255.0, green: 183/255.0, blue: 91/255.0, alpha: 1.0))
                selectedIndex = index
            }
            else
            {
                row.greenBackground.setBackgroundColor(UIColor(red: 27/255.0, green: 27/255.0, blue: 27/255.0, alpha: 1.0))
            }
        }
    }
    
    
    override func table(table: WKInterfaceTable, didSelectRowAtIndex rowIndex: Int) {

        if selectedIndex != rowIndex {
            selectedIndex = rowIndex
            self.selectedItem = (self.itemListArr?.objectAtIndex(rowIndex)) as? NSMutableDictionary
//            self.changeItemInApp()
//            self.interfaceVC?.updateSelectedItem((self.selectedItem!.valueForKey("name") as? String)!)
            self.interfaceVC!.itemNameStr = self.selectedItem!.valueForKey("name") as? String
            self.interfaceVC!.itemID = self.selectedItem!.valueForKey("item_listID") as? String

        }
        else{
//            self.popController()
        }

        self.popController()

//        self.loadITemListTABLE()
//        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(3 * Double(NSEC_PER_SEC)))
//        dispatch_after(delayTime, dispatch_get_main_queue()) {
//           self.popController()
//        }


    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

    func changeItemInApp()  {

        let message : [String : AnyObject]
        message = [
            "REQUEST_TYPE":"CHANGE_SELECTED_ITEM",
            "SELECTED_ITEM_ID":self.selectedItem!.objectForKey("item_listID")as! NSString
        ]

        WCSession.defaultSession().sendMessageData(NSKeyedArchiver.archivedDataWithRootObject(message), replyHandler:{ data in
                dispatch_async(dispatch_get_main_queue(), { 
                    self.popController()
                })

            }, errorHandler: {error in
                print("error: \(error)")
            })
    }

    func session(session: WCSession, didReceiveApplicationContext applicationContext: [String : AnyObject]) {


        
    }

}
