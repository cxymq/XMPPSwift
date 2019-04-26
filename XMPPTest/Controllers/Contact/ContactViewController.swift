//
//  ContactViewController.swift
//  XMPPTest
//
//  Created by Qi Wang on 2019/3/5.
//  Copyright © 2019 Qi Wang. All rights reserved.
//

import UIKit
import XMPPFramework

class ContactViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, XmppManagerDelegate {
    
    var tableView: UITableView!
    var xmppManager: XmppManager?
    //存储好友列表
    var roster: NSMutableArray?
    
    
    init() {
        super.init(nibName: nil, bundle: nil)
        roster = NSMutableArray.init()
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        view.backgroundColor = UIColor.yellow
        
        self.title = "好友列表"
        //添加好友按钮
        let btnItem = UIBarButtonItem.init(title: "add", style: .done, target: self, action: #selector(addFriend))
        let groupItem = UIBarButtonItem.init(title: "group", style: .done, target: self, action: #selector(showGroup))
//        self.navigationItem.rightBarButtonItem = btnItem
        self.navigationItem.rightBarButtonItems = [btnItem, groupItem]
        
        tableView = UITableView(frame: self.view.bounds, style: UITableView.Style.plain)
        tableView.delegate = self
        tableView.dataSource = self
        view.addSubview(self.tableView)
        tableView.backgroundColor = UIColor.white
        //两种写法皆可
//        self.tableView.register(UITableViewCell.classForCoder(), forCellReuseIdentifier: "Cell")
//         self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        
        //拉取好友列表
        xmppManager = XmppManager.sharedInstance()
//        xmppManager?.xmppRoster?.addDelegate(self, delegateQueue: DispatchQueue.main)
        xmppManager?.xmppRoster?.fetch()
        xmppManager!.delegate = self
        
        //收到刷新好友列表的通知
        NotificationCenter.default.removeObserver(self, name: Notification.Name("Get_Roster"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(getRoster(notification:)), name: Notification.Name("Get_Roster"), object: nil)
    }
    
    //MARK: ------ RightBarButtonItem
    @objc func addFriend() {
        let alert = UIAlertController.init(title: "输入对方名称", message: nil, preferredStyle: .alert)
        alert.addTextField { (tf) in
            tf.placeholder = "输入对方名称"
        }
        alert.addAction(UIAlertAction.init(title: "确定", style: .default, handler: { (aa) in
            let nick = alert.textFields?.first?.text
            if nick != nil {
                //本地测试，将domain改成localhost
                let jid = XMPPJID.init(user: nick, domain: "localhost", resource: nil)
                self.xmppManager?.addFriend(jid: jid!, nickName: nick!)
            }
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    @objc func showGroup() {
        self.navigationController?.pushViewController(RoomsViewController.init(), animated: true)
    }
    
    //MARK: ------ Notification
    @objc func getRoster(notification: Notification) {
        roster = notification.object as? NSMutableArray
        tableView.reloadData()
    }
    
    //MARK: ------ UITableViewDataSource
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (roster?.count)!
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "Cell")
        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: "Cell")
        }
        
        let friendModel: FriendModel? = roster?[indexPath.row] as? FriendModel
        cell?.textLabel?.text = friendModel?.name
        cell?.detailTextLabel?.text = friendModel?.status
        return cell!
    }
    
    //MARK: ------ UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        
        let vc = ChatViewController()
        vc.friendModel = roster?[indexPath.row] as? FriendModel
        navigationController!.pushViewController(vc, animated: true)
    }
    
    //MARK: ------ XmppManagerDelegate
    func xmppReceiveMessage(xmppStream: XMPPStream, message: XMPPMessage) {
        let text = message.body()
        if let msg = text {
            print("ContactViewController收到消息\n")
            print(msg)
        }
    }
    
    func xmppDidReceivePresence(xmppStream: XMPPStream, presence: XMPPPresence) {
        let presenceType = presence.type()
        let presenceFrom = presence.from()?.user

        var status = "离线"
        if presenceType == "available" {
            status = "在线"
        }
        
        for fm in roster! {
            if (fm as! FriendModel).jid?.user == presenceFrom {
                (fm as! FriendModel).status = status
            }
        }

        //好友列表
        if presenceFrom != xmppStream.myJID.user && presenceType == "subscribed" {
            let fm = FriendModel.init(jid: presence.from())
            self.roster?.add(fm)
        }
        if presenceType == "unsubscribe" {
            
            self.xmppManager?.xmppRoster?.removeUser(presence.from())
        }
        
        tableView.reloadData()
    }
    
    func xmppDidReceivePresenceSubscriptionRequest(xmppRoster: XMPPRoster, presence: XMPPPresence) {
        let fromJID = presence.from()
        let nick = fromJID?.full()
        
        let alert = UIAlertController.init(title: "\(String(describing: nick))的好友请求", message: "同意并添加对方", preferredStyle: .alert)
        alert.addAction(UIAlertAction.init(title: "确定", style: .default, handler: { (aa) in
            //同意并添加对方为好友
            self.xmppManager?.xmppRoster?.acceptPresenceSubscriptionRequest(from: fromJID, andAddToRoster: true)
//            self.xmppManager?.addFriend(jid: fromJID!, nickName: nick!)
//            let fm = FriendModel.init(jid: fromJID!)
//            fm.status = "在线"
//
//            if !(self.roster?.contains(fm))! {
//                self.roster?.add(fm)
//                self.tableView.reloadData()
//            }
            
        }))
        alert.addAction(UIAlertAction.init(title: "拒绝", style: .default, handler: { (aa) in
            self.xmppManager?.xmppRoster?.rejectPresenceSubscriptionRequest(from: fromJID)
        }))
        self.present(alert, animated: true, completion: nil)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
