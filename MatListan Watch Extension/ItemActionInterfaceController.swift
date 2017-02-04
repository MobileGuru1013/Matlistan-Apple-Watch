//
//  ItemActionInterfaceController.swift
//  Matlistan
//
//  Created by on 7/22/16.
//  Copyright © 2016 Consumiq AB. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity


class ItemActionInterfaceController: WKInterfaceController {

    @IBOutlet var tblItemAction: WKInterfaceTable!
    var itemActionArr : NSMutableArray = NSMutableArray()

    var itemDetailsDic : NSMutableDictionary = NSMutableDictionary()

    var storeItemListObj : StoreItemListInterfaceController?


    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)

        // Configure interface objects here.

        storeItemListObj = context as? StoreItemListInterfaceController

        let dict = getSelectedItemDic()

        let  title : String = dict.valueForKey("text") as! String

        setTitle(title)
        itemActionArr = [NSLocalizedString("Taken", comment: ""), NSLocalizedString("Caught at wrong place", comment: ""), NSLocalizedString("Taken, item has a new location", comment: ""), NSLocalizedString("Not in the collection", comment: ""), NSLocalizedString("Out", comment: ""), NSLocalizedString("Shop next time", comment: ""), NSLocalizedString("Remove", comment: ""),NSLocalizedString("Cancel", comment: "")]
        loadTableItemAction()
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

    func getSelectedItemDic() -> NSMutableDictionary {
        var dict : NSMutableDictionary = NSMutableDictionary()

        if storeItemListObj?.selectedTableType == 0 {
            dict = (storeItemListObj?.sortedItemsArr.objectAtIndex((storeItemListObj?.selectedIndex)!))! as! NSMutableDictionary
        }else if storeItemListObj?.selectedTableType == 1{
            dict = (storeItemListObj?.itemsList.objectAtIndex((storeItemListObj?.selectedIndex)!))! as! NSMutableDictionary
        }else{
            dict = (storeItemListObj?.removedItems.objectAtIndex((storeItemListObj?.selectedIndex)!))! as! NSMutableDictionary
        }
        return dict
    }

    func removeItemFromList() {
        if storeItemListObj?.selectedTableType == 0 {
            storeItemListObj?.sortedItemsArr.removeObjectAtIndex((storeItemListObj?.selectedIndex)!)
            storeItemListObj?.reloadSortedItemListTable()
        }else if storeItemListObj?.selectedTableType == 1{
            storeItemListObj?.itemsList.removeObjectAtIndex((storeItemListObj?.selectedIndex)!)
            storeItemListObj?.reloadItemListTable()
        }else{
        storeItemListObj?.removedItems.removeObjectAtIndex((storeItemListObj?.selectedIndex)!)
            storeItemListObj?.reloadRemoveItemListTable()
        }
    }

    func pickUnPickItem() {
        if storeItemListObj?.selectedTableType == 0 {
            storeItemListObj?.updateRowForTable((storeItemListObj?.shortedListTbl)!, forRowIndex: (storeItemListObj?.selectedIndex)!)
        }else if storeItemListObj?.selectedTableType == 1{
            storeItemListObj?.updateRowForTable((storeItemListObj?.itemListTbl)!, forRowIndex: (storeItemListObj?.selectedIndex)!)
        }else{
            storeItemListObj?.updateRowForTable((storeItemListObj?.removedItemListTbl)!, forRowIndex: (storeItemListObj?.selectedIndex)!)
        }
    }

    func loadTableItemAction()
    {
        tblItemAction.setNumberOfRows(itemActionArr.count, withRowType:"ItemListCell")
        for (index, name) in itemActionArr.enumerate() {
            let row = tblItemAction.rowControllerAtIndex(index) as! ItemListCell
            
            //row.itemNameLbl.setText(name.valueForKey("name") as? String)
            row.itemNameLbl.setText(name as? String)
        }
    }

    override func table(table: WKInterfaceTable, didSelectRowAtIndex rowIndex: Int) {
        if rowIndex == 7 {
            self.popController()
        }else {

            let message : [String : AnyObject]
            let dict = getSelectedItemDic()

            let isChecked = dict.valueForKey("isChecked") as! String
            let itemID = dict.valueForKey("id") as! String
            let shoppingListID = dict.valueForKey("listId") as! String
            let storeID = dict.valueForKey("listId") as! String
            let isTaken = dict.valueForKey("isTaken") as! String

            message = ["REQUEST_TYPE":"UPDATE_ITEM_IN_STORE",
                       "IS_TAKEN": isTaken,
                       "SHOPPING_LIST_ID": shoppingListID,
                       "ITEM_ID": itemID,
                       "STORE_ID": storeID,
                       "IS_CHECKED":isChecked,
                       "ACTION_ROW_INDEX":rowIndex
            ]

            WCSession.defaultSession().sendMessageData(NSKeyedArchiver.archivedDataWithRootObject(message), replyHandler:{ data in

                let dataDict:NSDictionary? = NSKeyedUnarchiver.unarchiveObjectWithData(data)! as? NSDictionary

                if dataDict != nil{
                    if rowIndex == 6 {
                        self.removeItemFromList()
                    }else{
                        self.pickUnPickItem()
                    }
                    self.popController()
                }

                },errorHandler: {
                    error in
                    
            })
        }
    }

}
