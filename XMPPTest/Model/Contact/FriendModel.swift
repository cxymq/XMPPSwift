//
//  FriendModel.swift
//  XMPPTest
//
//  Created by Qi Wang on 2019/3/6.
//  Copyright © 2019 Qi Wang. All rights reserved.
//

import UIKit
import XMPPFramework

class FriendModel: NSObject {
    public var name: String?
    public var pwd: String?
    public var status: String?
    
    public var jid: XMPPJID?
    public var xmppUserCoreDataStorageObject: XMPPUserCoreDataStorageObject?
    
    init(xmppUserCoreDataStorageObject: XMPPUserCoreDataStorageObject) {
        self.xmppUserCoreDataStorageObject = xmppUserCoreDataStorageObject
        jid = xmppUserCoreDataStorageObject.jid
        name = jid?.user
        status = xmppUserCoreDataStorageObject.isOnline() ? "在线" : "离线"
    }
    
    init(jid: XMPPJID) {
        self.jid = jid
        name = jid.user
    }
    
    

}
