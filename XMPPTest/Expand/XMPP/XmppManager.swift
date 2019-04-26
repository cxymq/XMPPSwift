//
//  XmppManager.swift
//  XMPPTest
//
//  Created by Qi Wang on 2019/3/5.
//  Copyright © 2019 Qi Wang. All rights reserved.
//

import UIKit

import XMPPFramework

struct Constants {
    static let XMPP_DOMAIN = "192.168.11.31"
    static let XMPP_LOCALHOST = "localhost"
    static let XMPP_SUBDOMAIN = "cintel"
    
//    static let XMPP_DOMAIN_WEB = "http://wx.cintelcloud.com:9090/"
//    static let XMPP_PWD = "123456"
}


//加class，表示只能由class遵守该协议，否则如果被struct遵守，使用weak修饰delegate会有问题，struct无引用计数概念
@objc protocol XmppManagerDelegate: class {
    //收到消息
    @objc optional func xmppReceiveMessage(xmppStream: XMPPStream, message: XMPPMessage)
    //消息发送失败
    @objc optional func xmppDidFailSendMessage(xmppStream: XMPPStream, message: XMPPMessage, error: Error)
    //消息发送成功
    @objc optional func xmppDidSendMessage(xmppStream: XMPPStream, message: XMPPMessage)
    
    //获取好友状态改变
    @objc optional func xmppDidReceivePresence(xmppStream: XMPPStream, presence: XMPPPresence)
    //收到添加好友请求
    @objc optional func xmppDidReceivePresenceSubscriptionRequest(xmppRoster: XMPPRoster, presence: XMPPPresence)
}

class XmppManager: NSObject, XMPPStreamDelegate, XMPPRosterDelegate, NSFetchedResultsControllerDelegate, XMPPRoomDelegate {
    
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
    
    weak var delegate: XmppManagerDelegate?
    
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
            
        }
        if xmppReconnect == nil {
            xmppReconnect = XMPPReconnect.init()
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
    
    //
    
    
    //MARK: ------ xmppStream
    //连接服务器,用户名为jid，JID一般由三部分构成：用户名，域名和资源名，格式为user@domain/resource，例如： test@example.com /Anthony。对应于XMPPJID类中的三个属性user、domain、resource。
    func connectXMPP(userName: String, pwd: String) {
        self.pwd = pwd
        
        //设置代理
        xmppStream.addDelegate(self, delegateQueue: DispatchQueue.main)
        
        if !xmppStream.isConnected() {
            //用户名
            let jid = XMPPJID(user: userName, domain: Constants.XMPP_DOMAIN, resource: nil)
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
//        let jid = XMPPJID(user: userName, domain: Constants.XMPP_DOMAIN, resource: nil)
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
//        xmppRoster?.addUser(jid, withNickname: nickName, groups: nil, subscribeToPresence: true)
    }
    //删除好友
    func deleteFriend(jid: XMPPJID) {
        xmppRoster?.removeUser(jid)
    }
    
    //添加群组
    func addGroup(name: String, roomName: String?) {
        var currentName = roomName
        if roomName == nil {
            //创建群组JID，以时间戳当作name
            let formatter = DateFormatter.init()
            formatter.dateFormat = "yyyyMMddHHmmss"
            let currentTime = formatter.string(from: Date.init())
            currentName = currentTime
        }
        let roomJID = NSString.init(format: "%@@%@.%@", currentName!, Constants.XMPP_SUBDOMAIN, Constants.XMPP_LOCALHOST)
        let jid = XMPPJID.init(string: roomJID as String)
        
        //使用XMPP提供的示例类存储， 也可以自定义继承自XMPPCoreDataStorage的类
        let xmppRoomHybridStorage = XMPPRoomHybridStorage.sharedInstance()
        let xmppRoom = XMPPRoom.init(roomStorage: xmppRoomHybridStorage, jid: jid, dispatchQueue: DispatchQueue.main)
        xmppRoom?.activate(xmppStream)
        xmppRoom?.addDelegate(self, delegateQueue: DispatchQueue.main)
        xmppRoom?.join(usingNickname: name, history: nil, password: nil)
    }
    
    //加载rooms
    func loadRooms() {
        let queryElement = XMLElement.element(withName: "query", uri: "http://jabber.org/protocol/disco#items")
        let iqElement = XMLElement.element(withName: "iq") as! XMLElement
        iqElement.addAttribute(withName: "type", stringValue: "get")
        iqElement.addAttribute(withName: "from", stringValue: xmppStream.myJID.bare())
        let service = NSString.init(format: "%@.%@", Constants.XMPP_SUBDOMAIN, Constants.XMPP_LOCALHOST)
        iqElement.addAttribute(withName: "to", stringValue: service as String)
        iqElement.addAttribute(withName: "id", stringValue: "getMyRooms")
        iqElement.addChild(queryElement as! DDXMLNode)
        xmppStream.send(iqElement)
    }
    
    //配置房间
    func configNewRoom(xmppRoom: XMPPRoom) {
        let x = XMLElement.init(name: "x", uri: "jabber:x:data")
        var p = XMLElement.init(name: "field")
        p.addAttribute(withName: "var", stringValue: "muc#roomconfig_persistentroom") //永久房间
        p.addChild(XMLElement.element(withName: "value", stringValue: "1") as! DDXMLNode)
        x.addChild(p)
        
        p = XMLElement.element(withName: "field") as! XMLElement
        p.addAttribute(withName: "var", stringValue: "muc#roomconfig_maxusers") //最大用户数
        p.addChild(XMLElement.element(withName: "value", stringValue: "100") as! DDXMLNode)
        x.addChild(p)
        
        p = XMLElement.element(withName: "field") as! XMLElement
        p.addAttribute(withName: "var", stringValue: "muc#roomconfig_publicroom") //公共房间
        p.addChild(XMLElement.element(withName: "value", stringValue: "0") as! DDXMLNode)
        x.addChild(p)
        
        p = XMLElement.element(withName: "field") as! XMLElement
        p.addAttribute(withName: "var", stringValue: "muc#roomconfig_allowinvites") //允许邀请
        p.addChild(XMLElement.element(withName: "value", stringValue: "1") as! DDXMLNode)
        x.addChild(p)
        
        xmppRoom.configureRoom(usingOptions: x)
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
        
        //定时发送ping,要求对方返回pong,因此这个时间我们需要设置
        xmppAutoPing?.pingInterval = 1000
        //如果是普通的用户来得ping，一样会响应
        xmppAutoPing?.respondsToQueries = true
        //这个过程是C---->S  ;观察 S--->C(需要在服务器设置）
        
        xmppReconnect?.autoReconnect = true
        
        _setActive()
        
        //允许后台模式(注意ios模拟器上是不支持后台socket的)
        xmppStream.enableBackgroundingOnSocket = true
        
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
        if delegate != nil {
            delegate?.xmppReceiveMessage!(xmppStream: sender, message: message)
        }
        
        if UIApplication.shared.applicationState == .background {
            let localNoti = UILocalNotification.init()
            localNoti.alertAction = "OK"
            localNoti.alertTitle = "消息"
            localNoti.alertBody = text
            localNoti.applicationIconBadgeNumber = UIApplication.shared.applicationIconBadgeNumber+1
            UIApplication.shared.presentLocalNotificationNow(localNoti)
        }
        
    }
    
    func xmppStream(_ sender: XMPPStream!, didReceive iq: XMPPIQ!) -> Bool {
        let elementID = iq.elementID()
        if elementID != "getMyRooms" {
            return true
        }
        
        let results = iq.elements(forXmlns: "http://jabber.org/protocol/disco#items")
        if (results?.count)! < 1 {
            return true
        }
        
        let rooms = NSMutableArray.init()
        for element in (iq?.children)! {
            if element.name == "query" {
                for item in element.children! {
                    if item.name == "item" {
                        rooms.add(item)
                    }
                }
            }
        }
        NotificationCenter.default.post(name: NSNotification.Name.init(rawValue: "XMPP_GET_GROUPS"), object: rooms)
        
        return true
    }
    
    //获取好友状态改变的回调
    func xmppStream(_ sender: XMPPStream!, didReceive presence: XMPPPresence!) {
        let presenceType = presence.type()
        let presenceFrom = presence.from()?.user
        print("\(String(describing: presenceFrom))状态：\(String(describing: presenceType))")
        if delegate != nil {
            delegate?.xmppDidReceivePresence!(xmppStream: xmppStream, presence: presence)
        }
    }
    
    //监听消息发送成功
    func xmppStream(_ sender: XMPPStream!, didSend message: XMPPMessage!) {
        print("消息发送成功、\(String(describing: message.body()))")
        if delegate != nil {
            delegate?.xmppDidSendMessage!(xmppStream: xmppStream, message: message)
        }
    }
    func xmppStream(_ sender: XMPPStream!, didFailToSend message: XMPPMessage!, error: Error!) {
        print("消息发送失败、\(String(describing: error))")
        if delegate != nil {
            delegate?.xmppDidFailSendMessage!(xmppStream: xmppStream, message: message, error: error)
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
//            NotificationCenter.default.post(Notification(name: Notification.Name(rawValue: "Get_Roster")))
            NotificationCenter.default.post(name: NSNotification.Name.init(rawValue: "Get_Roster"), object: roster)
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
        let type = item.attribute(forName: "type")?.stringValue
        //转换XMPPJid类型
//        let xmppJid = XMPPJID.init(string: jid)
        print("来自>>>>>>>>\(String(describing: jid))>>>>>>好友的操作\(String(describing: type))")
    }
    
    //收到好友请求,添加好友一定会订阅他，接受他的订阅不一定要添加对方为好友
    func xmppRoster(_ sender: XMPPRoster!, didReceivePresenceSubscriptionRequest presence: XMPPPresence!) {
        print("收到好友请求")
        let show = presence.show()
        let status = presence.status()
        let type = presence.type() as String
        print("\(String(describing: show))<<<<<<\(String(describing: status))<<<<<<<<\(type)")
        if delegate != nil {
            delegate?.xmppDidReceivePresenceSubscriptionRequest!(xmppRoster: sender, presence: presence)
        }
    }
    
    //MARK: ------ NSFetchedResultsControllerDelegate
    
    
    
    //MARK: ------ XMPPRoomDelegate
    func xmppRoomDidCreate(_ sender: XMPPRoom!) {
        print("房间创建成功")
        configNewRoom(xmppRoom: sender)
    }
    
    func xmppRoomDidJoin(_ sender: XMPPRoom!) {
        print("加入房间成功")
        
    }
    
    func xmppRoom(_ sender: XMPPRoom!, didFetchConfigurationForm configForm: DDXMLElement!) {
        print("获取房间配置 %@", configForm)
    }
    
    func xmppRoom(_ sender: XMPPRoom!, didFetchBanList items: [Any]!) {
        print("黑名单列表")
    }
    
    func xmppRoom(_ sender: XMPPRoom!, didFetchMembersList items: [Any]!) {
        print("成员列表")
    }
    
    func xmppRoom(_ sender: XMPPRoom!, didFetchModeratorsList items: [Any]!) {
        print("主持人列表")
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
