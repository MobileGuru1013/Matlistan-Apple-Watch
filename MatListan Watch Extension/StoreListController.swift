//
//  StoreListController.swift
//  Matlistan
//
//  Created by on 7/20/16.
//  Copyright © 2016 Consumiq AB. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity


class StoreListController: WKInterfaceController {
    
    @IBOutlet var tblStoreList : WKInterfaceTable!
    
    @IBOutlet var noStoreGroup: WKInterfaceGroup!
    
    var storeList : NSMutableArray = NSMutableArray();

    var sortByStore : Bool = false

    var interfaceVC : InterfaceController?

    var shoppingListID : String?

    var itemListDict : NSMutableDictionary?

    var interactionEnable : Bool = true

    var isFromBack : Bool = false

    @IBOutlet var skipGroup: WKInterfaceGroup!
    @IBOutlet var sortOptionGroup: WKInterfaceGroup!
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)

        interfaceVC = context as? InterfaceController
        // Configure interface objects here.
        self.getStoreList()
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()

        if isFromBack {
            self.popController()
        }

        shoppingListID = interfaceVC?.itemID
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    
    func getStoreList()
    {
        
        let message : [String : AnyObject]
        message = ["REQUEST_TYPE":"GET_STORE_LIST"]
        
        WCSession.defaultSession().sendMessageData(NSKeyedArchiver.archivedDataWithRootObject(message), replyHandler:{ data in
            
            let dataDict:NSDictionary? = NSKeyedUnarchiver.unarchiveObjectWithData(data)! as? NSDictionary
            let sortEnable : NSString = dataDict?.valueForKey("SORT_BY_STORE") as! NSString
            if (sortEnable.isEqualToString("1")){
                self.sortByStore = true
            }

            self.storeList  = (dataDict?.valueForKey("STORE_LIST"))! as! NSMutableArray
            
            if self.storeList.count > 0
            {
                self.loadStoreListTable();
            }

            self.hideSortEnableGroup(true)
            
            },errorHandler: {
                error in
                self.hideSortEnableGroup(true)
                
        })
    }

    func openItemListForStore(storeID : String , forStrore storeName : String)  {
        let message : [String : AnyObject]
        message = ["REQUEST_TYPE":"GET_ITEM_LIST_OF_STORE",
                   "STORE_ID": storeID,
                    "SHOPPING_LIST_ID": shoppingListID!,
                    "STORE_NAME" : storeName
        ]

        WCSession.defaultSession().sendMessageData(NSKeyedArchiver.archivedDataWithRootObject(message), replyHandler:{ data in

            let dataDict:NSDictionary? = NSKeyedUnarchiver.unarchiveObjectWithData(data)! as? NSDictionary

            if dataDict != nil{
                let dict : NSMutableDictionary = NSMutableDictionary()

                var sortType = "Latest"
                if ((dataDict?.valueForKey("SORTING_TYPE")) != nil){
                    sortType = dataDict?.valueForKey("SORTING_TYPE") as! String
                }

                var store : String = storeName

                if store == ""{
                    store = NSLocalizedString("Store List", comment: "")
                }

                dict.setValue(store, forKey: "store_name")
                dict.setValue(storeID, forKey: "store_id")
                dict.setValue(sortType, forKey: "sort_type")
                dict.setValue(dataDict, forKey: "item_list")
                dict.setValue(self.shoppingListID, forKey: "shoppinListID")

                let sortingAvalable : NSString = dataDict?.valueForKey("SHORTING_AVAILABLE") as! NSString

                if(sortingAvalable.isEqualToString("1")){
                    self.itemListDict = NSMutableDictionary.init(dictionary: dict)
                    self.hideSortEnableGroup(false)
                }else{
                    self.pushControllerWithName("StoreItemListInterfaceController", context: dict)
                    self.isFromBack = true
                }
                self.enableAllOption(true)
            }

            },errorHandler: {
                error in
                self.enableAllOption(true)
        })
    }
    
    func loadStoreListTable()
    {
        self.tblStoreList.setNumberOfRows(storeList.count, withRowType: "StoreListCell")
        for (index, name) in storeList.enumerate() {
            
            let row = tblStoreList.rowControllerAtIndex(index) as! ItemListCell
            
            row.itemNameLbl.setText(name.valueForKey("name") as? String)
            //row.itemNameLbl.setText(name.valueForKey("name") as? String)
        }
    }

    override func table(table: WKInterfaceTable, didSelectRowAtIndex rowIndex: Int) {

        if self.interactionEnable == false{
            return;
        }
        self.enableAllOption(false)
        let dic : NSMutableDictionary = storeList.objectAtIndex(rowIndex) as! NSMutableDictionary

        let tempNumber = dic.valueForKey("id") as! Int
        let storeID = String(tempNumber)
        self.openItemListForStore(storeID, forStrore: dic.valueForKey("name") as! String)
    }

    func enableAllOption(enable:Bool) {
        self.interactionEnable = enable;
    }

    func hideSortEnableGroup(hide : Bool)  {
        self.sortOptionGroup.setHidden(hide)
        self.skipGroup.setHidden(!hide)
        if storeList.count<1 {
            self.noStoreGroup.setHidden(!hide)
            self.tblStoreList.setHidden(true)
        }else{
            self.noStoreGroup.setHidden(true)
            self.tblStoreList.setHidden(!hide)
        }

    }

    @IBAction func skipSortingOption() {
        if self.interactionEnable == false {
            return;
        }
        self.enableAllOption(false)
        openItemListForStore("", forStrore: "")
    }
    @IBAction func enableStoreSortOption() {
        hideSortEnableGroup(true)
        self.pushControllerWithName("StoreItemListInterfaceController", context: itemListDict)
        isFromBack = true
    }

    @IBAction func disableSortOption() {
        hideSortEnableGroup(true)
        var dic : NSDictionary = itemListDict?.valueForKey("item_list") as! NSDictionary
        let tempDic = NSMutableDictionary(dictionary: dic)
        let appSortArr = tempDic.objectForKey("APP_STORE_SORT_ARR")
        tempDic.removeObjectForKey("SORTED_ITEMS")
        tempDic.setObject(appSortArr!, forKey: "SORTED_ITEMS")
        dic = NSDictionary(dictionary: tempDic)
        itemListDict?.setObject(dic, forKey: "item_list")
        self.pushControllerWithName("StoreItemListInterfaceController", context: itemListDict)
        isFromBack = true
    }

}