//
//  ChatMessageModel.swift
//  XMPPTest
//
//  Created by Qi Wang on 2019/3/6.
//  Copyright © 2019 Qi Wang. All rights reserved.
//

import UIKit

class ChatMessageModel: NSObject {
    var isSelf: Bool?
    var text: String?
    
    init(isSelf: Bool, text: String) {
        self.isSelf = isSelf
        self.text = text
    }
}
