//
//  StoreItemListInterfaceController.swift
//  Matlistan
//
//  Created by on 21/07/16.
//  Copyright © 2016 Consumiq AB. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity


class StoreItemListInterfaceController: WKInterfaceController, StoreItemListCellDelegate {

    @IBOutlet var removedItemListTbl: WKInterfaceTable!
    @IBOutlet var itemListTbl: WKInterfaceTable!
    @IBOutlet var shortedByLbl: WKInterfaceLabel!

    @IBOutlet var shortedListTitleLbl: WKInterfaceLabel!
    @IBOutlet var shortedListTitleGroup: WKInterfaceGroup!
    @IBOutlet var shortedListTbl: WKInterfaceTable!
    var sortedItemsArr : NSMutableArray! = NSMutableArray()


    @IBOutlet var groupRemovedItemTitle: WKInterfaceGroup!

    var shoppingListID : String?
    var storeID : String?

    let greenColor = UIColor.init(red: 114.0/255.0, green: 183.0/255.0, blue: 91.0/255.0, alpha: 1.0)

    let grayColor = UIColor.grayColor()
    let redColor = UIColor.redColor()
    let whiteColor = UIColor.whiteColor()




    var itemsList : NSMutableArray = NSMutableArray()
    var removedItems : NSMutableArray = NSMutableArray()
    var selectedItemDic : NSMutableDictionary = NSMutableDictionary()
    var selectedIndex : NSInteger = 0
    var selectedTableType : NSInteger = 0


    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)

        var dic : NSDictionary = context as! NSDictionary

        self.setTitle(dic.valueForKey("store_name") as? String)
        let sortType = dic.valueForKey("sort_type") as! String
        shortedByLbl.setText(sortType)
//        shortedByLbl.setText(NSLocalizedString("Unsorted items", comment: ""))

        shoppingListID = dic.valueForKey("shoppinListID") as? String
        storeID = dic.valueForKey("store_id") as? String

        dic = (dic.valueForKey("item_list") as? NSDictionary)!


        if (dic.objectForKey("BUY_ITEMS") != nil) {
            itemsList = dic.objectForKey("BUY_ITEMS") as! NSMutableArray
        }

        if (dic.objectForKey("CHECKED_ITEMS") != nil) {
            removedItems = dic.objectForKey("CHECKED_ITEMS") as! NSMutableArray
        }

        if (dic.objectForKey("SORTED_ITEMS") != nil) {
            sortedItemsArr = dic.objectForKey("SORTED_ITEMS") as! NSMutableArray
        }

        if sortedItemsArr.count>0 {
            let sortBy = dic.valueForKey("SORTING_BY") as! String
            shortedListTitleLbl.setText("\(NSLocalizedString("Sorted by:", comment: "")) \(sortBy)")
        }

        if sortedItemsArr.count<1 && removedItems.count<1 && itemsList.count<1 {
            let h0 = { self.popController() }
            let action1 = WKAlertAction(title: "OK", style: .Default, handler:h0)

            self.presentAlertControllerWithTitle(NSLocalizedString("Alert", comment: ""), message: NSLocalizedString("Your grocery list is empty.", comment: ""), preferredStyle: .ActionSheet, actions: [action1])
        }

        // Configure interface objects here.
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()

        if sortedItemsArr.count<1 {
            hideSortedItemOption(true)
        }else{
            reloadSortedItemListTable()
            hideSortedItemOption(false)
        }

        if itemsList.count<1 {
            hideUnsortedItemOption(true)
        }else{
            hideUnsortedItemOption(false)
            self.reloadItemListTable()
        }

        if removedItems.count<1 {
            removedItemListTbl.setHidden(true)
            groupRemovedItemTitle.setHidden(true)
        }else{
            removedItemListTbl.setHidden(false)
            groupRemovedItemTitle.setHidden(false)
            reloadRemoveItemListTable()
        }
    }

    func reloadSortedItemListTable() {

        var tempArr : NSArray = itemsList.valueForKey("id") as! NSArray


        shortedListTbl.setNumberOfRows(sortedItemsArr.count, withRowType: "StoreItemListCell")

        for (index, name) in sortedItemsArr.enumerate() {
            let itemID = name.valueForKey("id") as? String
            if tempArr.containsObject(itemID!) {
                let index : NSInteger = tempArr.indexOfObject(itemID!)
                itemsList.removeObjectAtIndex(index)
                tempArr = itemsList.valueForKey("id") as! NSArray
            }
            let row = shortedListTbl.rowControllerAtIndex(index) as! StoreItemListCell
            row.delegate = self
            row.index = index
            row.listType = 0

            let attributeString: NSMutableAttributedString =  NSMutableAttributedString(string: (name.valueForKey("text") as? String)!)

            let isCheck : NSString = name.valueForKey("isChecked") as! NSString

            if isCheck.isEqualToString("0") {
                row.itemNameLbl.setTextColor(greenColor)
                row.moreBtn.setHidden(false)
            }else{
                row.itemNameLbl.setTextColor(grayColor)
                row.moreBtn.setHidden(true)
                attributeString.addAttribute(NSStrikethroughStyleAttributeName, value: 2, range: NSMakeRange(0, attributeString.length))

            }
            row.itemNameLbl.setAttributedText(attributeString)
        }
    }

    func reloadItemListTable() {

        itemListTbl.setNumberOfRows(itemsList.count, withRowType: "StoreItemListCell")

        for (index, name) in itemsList.enumerate() {

            let row = itemListTbl.rowControllerAtIndex(index) as! StoreItemListCell
            row.delegate = self
            row.index = index
            row.listType = 1

            let attributeString: NSMutableAttributedString =  NSMutableAttributedString(string: (name.valueForKey("text") as? String)!)

            let isCheck : NSString = name.valueForKey("isChecked") as! NSString

            if isCheck.isEqualToString("0") {
                row.itemNameLbl.setTextColor(redColor)
                row.moreBtn.setHidden(false)
            }else{
                row.itemNameLbl.setTextColor(grayColor)
                row.moreBtn.setHidden(true)
                attributeString.addAttribute(NSStrikethroughStyleAttributeName, value: 2, range: NSMakeRange(0, attributeString.length))

            }
            row.itemNameLbl.setAttributedText(attributeString)
        }
    }


    func reloadRemoveItemListTable() {

        removedItemListTbl.setNumberOfRows(removedItems.count, withRowType: "StoreItemListCell")

        for (index, name) in removedItems.enumerate() {

            let row = removedItemListTbl.rowControllerAtIndex(index) as! StoreItemListCell

            let attributeString: NSMutableAttributedString =  NSMutableAttributedString(string: (name.valueForKey("text") as? String)!)

            let isCheck : NSString = name.valueForKey("isChecked") as! NSString

            if isCheck.isEqualToString("0") {
                row.itemNameLbl.setTextColor(whiteColor)
                row.moreBtn.setHidden(false)
            }else{
                row.itemNameLbl.setTextColor(grayColor)
                row.moreBtn.setHidden(true)
                attributeString.addAttribute(NSStrikethroughStyleAttributeName, value: 2, range: NSMakeRange(0, attributeString.length))
            }

            row.delegate = self
            row.index = index
            row.listType = 2
            row.itemNameLbl.setAttributedText(attributeString)

        }
    }

    override func table(table: WKInterfaceTable, didSelectRowAtIndex rowIndex: Int) {

        let  dic : NSMutableDictionary = updateRowForTable(table, forRowIndex: rowIndex)

        self.pickUnpickItem(dic)
    }

    func updateRowForTable(table:WKInterfaceTable, forRowIndex rowIndex: Int) -> NSMutableDictionary  {

        var  dic : NSMutableDictionary = NSMutableDictionary()

        let row : StoreItemListCell = table.rowControllerAtIndex(rowIndex) as! StoreItemListCell

        var attributeString: NSMutableAttributedString;

        var pick : Bool

        if row.listType == 0 {
            dic = sortedItemsArr.objectAtIndex(rowIndex) as! NSMutableDictionary
            attributeString =  NSMutableAttributedString(string: (dic.valueForKey("text") as? String)!)

            let isCheck : NSString = dic.valueForKey("isChecked") as! NSString
            if isCheck.isEqualToString("0") {
                pick = true
                dic.setValue("1", forKey: "isChecked")
            }else{
                pick = false
                dic.setValue("0", forKey: "isChecked")
            }
            sortedItemsArr.replaceObjectAtIndex(rowIndex, withObject: dic)
            row.itemNameLbl.setTextColor(greenColor)
        }else if row.listType == 1{
            dic = itemsList.objectAtIndex(rowIndex) as! NSMutableDictionary
            attributeString =  NSMutableAttributedString(string: (dic.valueForKey("text") as? String)!)

            let isCheck : NSString = dic.valueForKey("isChecked") as! NSString
            if isCheck.isEqualToString("0") {
                pick = true
                dic.setValue("1", forKey: "isChecked")
            }else{
                pick = false
                dic.setValue("0", forKey: "isChecked")
            }
            row.itemNameLbl.setTextColor(redColor)
            itemsList.replaceObjectAtIndex(rowIndex, withObject: dic)
        }else{
            dic = removedItems.objectAtIndex(rowIndex) as! NSMutableDictionary
            attributeString =  NSMutableAttributedString(string: (dic.valueForKey("text") as? String)!)

            let isCheck : NSString = dic.valueForKey("isChecked") as! NSString
            if isCheck.isEqualToString("0") {
                pick = true
                dic.setValue("1", forKey: "isChecked")
            }else{
                pick = false
                dic.setValue("0", forKey: "isChecked")
            }
            row.itemNameLbl.setTextColor(whiteColor)
            removedItems.replaceObjectAtIndex(rowIndex, withObject: dic)
        }

        if pick {
            attributeString.addAttribute(NSStrikethroughStyleAttributeName, value: 2, range: NSMakeRange(0, attributeString.length))
            row.moreBtn.setHidden(true)
            row.itemNameLbl.setTextColor(grayColor)
        }else{
            row.moreBtn.setHidden(false)
        }

        row.itemNameLbl.setAttributedText(attributeString)

        return dic
    }

    func pickUnpickItem(dic : NSMutableDictionary) {
        let message : [String : AnyObject]
        let isChecked = dic.valueForKey("isChecked") as! String
        let itemID = dic.valueForKey("id") as! String
        let shoppingListID = dic.valueForKey("listId") as! String
        let storeID = dic.valueForKey("listId") as! String
        let isTaken = dic.valueForKey("isTaken") as! String

        var rowIndex = "0"


        if isChecked != "0" {
            rowIndex = "5"
        }

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

            }

            },errorHandler: {
                error in

        })
    }

    func didSelectMoreBtn(index: NSInteger, forListType type: NSInteger) {

        self.selectedIndex = index
        self.selectedTableType = type
        
        self.pushControllerWithName("ItemActionInterfaceController", context:self)
        
    }
    
    
    func hideSortedItemOption(hide : Bool) {
        shortedListTitleLbl.setHidden(hide)
        shortedListTitleGroup.setHidden(hide)
        shortedListTbl.setHidden(hide)
    }
    
    func hideUnsortedItemOption(hide : Bool) {
        itemListTbl.setHidden(hide)
        shortedByLbl.setHidden(hide)
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

    
}
