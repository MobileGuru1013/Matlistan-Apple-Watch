//
//  StoreItemListCell.swift
//  Matlistan
//
//  Created by on 21/07/16.
//  Copyright © 2016 Consumiq AB. All rights reserved.
//

import WatchKit

protocol StoreItemListCellDelegate {
    func didSelectMoreBtn(index : NSInteger, forListType type: NSInteger)
}

class StoreItemListCell: NSObject {

    @IBOutlet var moreBtn: WKInterfaceButton!
    @IBOutlet var itemNameLbl: WKInterfaceLabel!
    var index : NSInteger = 0
    var listType : NSInteger = 0


    var delegate: StoreItemListInterfaceController?


    @IBAction func moreBtnClick() {
        self.didSelectMoreBtn(self.index)
    }

    func didSelectMoreBtn(index : NSInteger) {
        delegate?.didSelectMoreBtn(index, forListType: self.listType)
    }
}
