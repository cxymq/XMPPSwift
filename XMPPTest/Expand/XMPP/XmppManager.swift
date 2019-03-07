//
//  XmppManager.swift
//  XMPPTest
//
//  Created by Qi Wang on 2019/3/5.
//  Copyright © 2019 Qi Wang. All rights reserved.
//

import UIKit

import XMPPFramework

class XmppManager: NSObject, XMPPStreamDelegate, XMPPRosterDelegate, NSFetchedResultsControllerDelegate {
    
    //单例
    //简便实现
//    static let `default` = XmppManager()
    
    //dispatch_once 实现 , swift3.0废弃
    /*class func shareSingle() -> XmppManager {
        struct Singleton {
            static var onceToken: dispatch_once_t = 0
            static var single: XmppManager?
        }
        dispatch_once(&Singleton.onceToken,{
            Singleton.single=XmppManager()
        }
        )
        return Singleton.single!
    }*/
    
    //在方法体 可执行设置 实例前 工作
    static let instance: XmppManager = XmppManager()
    class func sharedInstance() -> XmppManager {
        return instance
    }
    
    override init() {
        if xmppStream == nil {
            xmppStream = XMPPStream()
        }
        
        if xmppRosterCoreDataStorage == nil {
            xmppRosterCoreDataStorage = XMPPRosterCoreDataStorage.sharedInstance()
        }
        if xmppRoster == nil {
            xmppRoster = XMPPRoster.init(rosterStorage: xmppRosterCoreDataStorage, dispatchQueue: DispatchQueue.main)
            xmppRoster?.autoFetchRoster = false
        }
        if xmppAutoPing == nil {
            xmppAutoPing = XMPPAutoPing.init()
            //定时发送ping,要求对方返回ping,因此这个时间我们需要设置
            xmppAutoPing?.pingInterval = 1000
            //如果是普通的用户来得ping，一样会响应
            xmppAutoPing?.respondsToQueries = true
            //这个过程是C---->S  ;观察 S--->C(需要在服务器设置）
        }
        if xmppReconnect == nil {
            xmppReconnect = XMPPReconnect.init()
            xmppReconnect?.autoReconnect = true
        }
        if roster == nil {
            roster = NSMutableArray.init()
        }
    }
    
    //存储好友列表
    public var roster: NSMutableArray?
    
    //通过该类与服务器连接，由socket实现（CocoaAsyncSocket）
    var xmppStream: XMPPStream!
    var pwd: String!
    
    //处理和好友相关：获取好友列表，添加好友，接收好友请求，同意添加好友，拒绝添加好友
    var xmppRoster: XMPPRoster?
    //用于存储好友
    var xmppRosterCoreDataStorage: XMPPRosterCoreDataStorage?
    
    //自动重连
    var xmppAutoPing: XMPPAutoPing?
    var xmppReconnect: XMPPReconnect?
    
    
    
    //MARK: ------ xmppStream
    //连接服务器,用户名为jid，JID一般由三部分构成：用户名，域名和资源名，格式为user@domain/resource，例如： test@example.com /Anthony。对应于XMPPJID类中的三个属性user、domain、resource。
    func connectXMPP(userName: String, pwd: String) {
        self.pwd = pwd
        
        //设置代理
        xmppStream.addDelegate(self, delegateQueue: DispatchQueue.main)
        
        if !xmppStream.isConnected() {
            //用户名
            let jid = XMPPJID(user: userName, domain: "192.168.11.31", resource: "Contacts")
//            let jid = XMPPJID(string: userName)
            xmppStream.myJID = jid
            //连接服务器
            do {
                try xmppStream.connect(withTimeout: 5)
            } catch let error {
                print(error)
            }
        }
    }
    
    //退出登录
    func disConnect() {
        let presence = XMPPPresence(type: "unavailable")
        xmppStream.send(presence)
        
        //断开连接
        xmppStream.disconnect()
        
        _setInactive()
    }
    
    //发送消息
    func sendMessage(userName: String, text: String) {
        print("发送消息\n")
        let jid = XMPPJID(string: userName)
//        let jid = XMPPJID(user: "wang", domain: "192.168.11.31", resource: "Contacts")
        let message = XMPPMessage(type: "chat", to: jid)
        message?.addBody(text)
        if let msg = message {
            print(msg.type())
            print(msg.body())
            xmppStream.send(msg)
        } else {
            print("消息为空")
        }
    }
    
    //添加好友
    func addFriend(jid: XMPPJID, nickName: String) {
        xmppRoster?.addUser(jid, withNickname: nickName)
    }
    //删除好友
    func deleteFriend(jid: XMPPJID) {
        xmppRoster?.removeUser(jid)
    }
    
    //MARK: ------ XMPPStreamDelegate
    //连接成功的回调
    func xmppStream(_ sender: XMPPStream!, socketDidConnect socket: GCDAsyncSocket!) {
        print("连接成功")
    }
    
    //连接成功后 输入密码登录
    func xmppStreamDidConnect(_ sender: XMPPStream!) {
        do {
            try sender.authenticate(withPassword: self.pwd)
        } catch let error {
            print(error)
        }
    }
    
    func xmppStream(_ sender: XMPPStream!, didNotAuthenticate error: DDXMLElement!) {
        print("未认证")
        print(error)
    }
    
    //登录成功后 设置登录状态
    func xmppStreamDidAuthenticate(_ sender: XMPPStream!) {
        print("认证成功")
        
        _setActive()
        
        let presence = XMPPPresence(type: "available")
        xmppStream.send(presence)
        
        //跳转通讯录界面
        let delegate = UIApplication.shared.delegate as! AppDelegate
        if delegate.window != nil {
            delegate.window?.rootViewController = UINavigationController.init(rootViewController: ContactViewController())
        }
    }
    
    //退出登录的回调
    func xmppStreamDidDisconnect(_ sender: XMPPStream!, withError error: Error!) {
        print("退出成功")
    }
    
    //接收消息
    func xmppStream(_ sender: XMPPStream!, didReceive message: XMPPMessage!) {
        let text = message.body()
        if let msg = text {
            print("收到消息\n")
            print(msg)
        }
        
    }
    
    //MARK: ------ roster
    /**
     *  好友列表加载
     NSFetchedResultsController，官方解释是可以有效地管理从Core Data读取到的提供给UITableView对象的数据。
     
     使用方法分为3步：
     1. 配置一个request，指定要查询的数据库表
     2. 至少为获取到的数据设置一个排序方法
     3. 可以为数据设置过滤条件
     
     除此之外，它还提供以下两个功能：
     1. 监听和它关联的上下文（NSManagedObjectContext）的改变，并报告这些改变
     2. 缓存结果，重新显示相同的数据的时候不需要再获取一遍
     */
    func loadFriends() {
        //显示好友数据（保存在XMPPRoster.sqlite）
        //1.上下文，关联XMPPRoster.sqlite
        let rosterContext = xmppRosterCoreDataStorage?.mainThreadManagedObjectContext
        
        //2.请求查询哪张表
        let request: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest.init(entityName: "XMPPUserCoreDataStorageObject")
        
        //设置排序
        let sort = NSSortDescriptor.init(key: "displayName", ascending: true)
        request.sortDescriptors = [sort]
        
        //过滤没有添加成功的好友
        //语法和sql一样
        let predicate = NSPredicate.init(format: "subscription != %@", "none")
        request.predicate = predicate
        
        //3.执行请求
        //3.1创建结果控制器
        let resultControler = NSFetchedResultsController.init(fetchRequest: request, managedObjectContext: rosterContext!, sectionNameKeyPath: nil, cacheName: nil)
        resultControler.delegate = self
        //3.2执行
        do {
            try resultControler.performFetch()
        } catch let error {
            print("执行错误",error)
        }
        
        for user in resultControler.fetchedObjects! {
            
            let friendModel = FriendModel.init(xmppUserCoreDataStorageObject: user as! XMPPUserCoreDataStorageObject)
            print(friendModel)
            roster?.add(friendModel)
            //通知ContactViewController已经获取到联系人
            NotificationCenter.default.post(Notification(name: Notification.Name(rawValue: "Get_Roster")))
        }
    }
    
    //MARK: ------XMPPRosterDelegate
    
    func xmppRosterDidBeginPopulating(_ sender: XMPPRoster!, withVersion version: String!) {
        print("开始同步")
    }
    /**
     * 同步结束
     **/
    //收到好友列表，并且已经存入存储器的回调
    func xmppRosterDidEndPopulating(_ sender: XMPPRoster!) {
        print("已获取好友列表")
        loadFriends()
    }
    
    //收到每一个好友
    func xmppRoster(_ sender: XMPPRoster!, didReceiveRosterItem item: DDXMLElement!) {
        //得到jid
        let jid = item.attribute(forName: "jid")?.stringValue
        let alias = item.attribute(forName: "alias")?.stringValue
        //转换XMPPJid类型
//        let xmppJid = XMPPJID.init(string: jid)
        print("来自>>>>>>>>\(String(describing: jid))>>>>>>好友的操作\(String(describing: alias))")
    }
    
    //收到好友请求,添加好友一定会订阅他，接受他的订阅不一定要添加对方为好友
    func xmppRoster(_ sender: XMPPRoster!, didReceivePresenceSubscriptionRequest presence: XMPPPresence!) {
        print("收到好友请求")
        let show = presence.show()
        let status = presence.status()
        let type = presence.type() as String
        print("\(String(describing: show))<<<<<<\(String(describing: status))<<<<<<<<\(type)")
    }
    
    //MARK: ------ private method
    private func _setActive() {
        xmppRoster?.addDelegate(self, delegateQueue: DispatchQueue.main)

        xmppRoster?.activate(xmppStream)
        xmppAutoPing?.activate(xmppStream)
        xmppReconnect?.activate(xmppStream)
    }
    
    private func _setInactive() {
        
        xmppAutoPing?.deactivate()
        xmppReconnect?.autoReconnect = false
        xmppReconnect?.deactivate()
        
        xmppRoster?.deactivate()
        xmppRoster?.removeDelegate(self)
        
        xmppStream.removeDelegate(self)
    }

}
