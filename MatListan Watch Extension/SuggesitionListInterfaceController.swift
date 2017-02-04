//
//  SuggesitionListInterfaceController.swift
//  Matlistan
//
//  Created by on 19/07/16.
//  Copyright © 2016 Consumiq AB. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity


class SuggesitionListInterfaceController: WKInterfaceController {

    @IBOutlet var groupNoMatchFound: WKInterfaceGroup!
    @IBOutlet var groupItemListSuggestion: WKInterfaceGroup!
    @IBOutlet var tblItemList:WKInterfaceTable!
    @IBOutlet var groupForAddItemSuccussfully: WKInterfaceGroup!
    @IBOutlet var backToHomeScreenLbl: WKInterfaceLabel!
    
    var interfaceVC :InterfaceController?

    var addedItemID : String?
    var addedItemListID : String?
    
    var names : NSMutableArray = NSMutableArray();

    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)

        interfaceVC = (context as? InterfaceController)!

        self.presentTextInputControllerWithSuggestions(nil, allowedInputMode: .Plain) { (data) in

            if data != nil{
                let inputArr : NSArray = data! as NSArray
                if inputArr.count>0{
                    let inputStr : String = inputArr.objectAtIndex(0) as! String
                    if (inputStr ?? "").isEmpty != true {
                        self.getSuggestions(inputStr)
                    }
                }
            }else{
                self.dismissController()
            }
        }

//        self.getSuggestions("Hey")

    }

    override func table(table: WKInterfaceTable, didSelectRowAtIndex rowIndex: Int) {
        self.addItemToList(names.objectAtIndex(rowIndex) as! String)
    }

    func addItemToList(itemName : String) {

        let message : [String : AnyObject]
        message = [
            "REQUEST_TYPE":"ADD_SUGGESTED_ITEM",
            "ITEM_NAME":itemName,
            "LIST_ID": (self.interfaceVC?.itemID)!
        ]

        WCSession.defaultSession().sendMessageData(NSKeyedArchiver.archivedDataWithRootObject(message), replyHandler:{ data in
                let dataDict:NSDictionary? = NSKeyedUnarchiver.unarchiveObjectWithData(data)! as? NSDictionary

                if dataDict != nil{
                    let itemName :String = (dataDict?.valueForKey("ITEM_NAME"))! as! String
                    let listName :String = (dataDict?.valueForKey("LIST_NAME"))! as! String
                    self.backToHomeScreenLbl.setText("\(NSLocalizedString("Added", comment: "")) \"\(itemName)\" \(NSLocalizedString("to", comment: "")) \"\(listName)\"")

                    self.addedItemID = dataDict?.valueForKey("ITEM_ID") as? String
                    self.addedItemListID = dataDict?.valueForKey("LIST_ID") as? String
                    self.showSuccessFullyAddItemGroup(false)
                }

            }, errorHandler: {error in

                
        })
        
    }

    override func dismissTextInputController() {
        self.popController()
    }

    func getSuggestions(inputStr : String) {

        let message : [String : AnyObject]
        message = [
            "REQUEST_TYPE":"GET_SUGGESTED_ITEM",
            "SUGESSION_STR":inputStr
        ]

        WCSession.defaultSession().sendMessageData(NSKeyedArchiver.archivedDataWithRootObject(message), replyHandler:{ data in
            let dataDict:NSDictionary? = NSKeyedUnarchiver.unarchiveObjectWithData(data)! as? NSDictionary
            self.names  = (dataDict?.valueForKey("SUGGESTED_ITEM"))! as! NSMutableArray


            let firstStr : String = self.names.objectAtIndex(0) as! String

            let temp1 : String = NSLocalizedString("Found no matching items. Please try again.", comment: "")
            let temp2 : String = NSLocalizedString("server_problem", comment: "")

            if (firstStr == temp1 || firstStr == temp2){
                self.hideNoMatchGroup(false)
            }else{
                self.showSuccessFullyAddItemGroup(true)
                self.loadSuggestedItemListTable()
            }

            print(dataDict)

            }, errorHandler: {error in
                self.hideNoMatchGroup(false)
                
        })
    }

    func hideNoMatchGroup(hide : Bool)  {
        groupNoMatchFound.setHidden(hide)
        groupItemListSuggestion.setHidden(!hide)
        groupForAddItemSuccussfully.setHidden(!hide)
    }

    func showSuccessFullyAddItemGroup(show : Bool) {
        groupNoMatchFound.setHidden(true)
        groupItemListSuggestion.setHidden(!show)
        groupForAddItemSuccussfully.setHidden(show)
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    func loadSuggestedItemListTable()
    {
        self.tblItemList.setNumberOfRows(names.count, withRowType: "SuggestedItemListCell")
        for (index, name) in names.enumerate() {
            let row = tblItemList.rowControllerAtIndex(index) as! ItemListCell

            row.itemNameLbl.setText(name as? String)
            //row.itemNameLbl.setText(name.valueForKey("name") as? String)
        }
    }
    
    @IBAction func backToHomeScreen()
    {
        self.dismissController();
    }
   
    @IBAction func undoAddedItem() {

        let message : [String : AnyObject]
        message = [
            "REQUEST_TYPE":"REMOVE_ADDED_ITEM",
            "ITEM_ID":self.addedItemID!,
            "LIST_ID": self.addedItemListID!
        ]

        WCSession.defaultSession().sendMessageData(NSKeyedArchiver.archivedDataWithRootObject(message), replyHandler:{ data in
            let dataDict:NSDictionary? = NSKeyedUnarchiver.unarchiveObjectWithData(data)! as? NSDictionary

            if dataDict != nil{
                self.dismissController()
            }

            }, errorHandler: {error in

        })
    }
    
    

}
