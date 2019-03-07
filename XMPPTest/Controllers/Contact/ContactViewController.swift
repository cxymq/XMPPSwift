//
//  ContactViewController.swift
//  XMPPTest
//
//  Created by Qi Wang on 2019/3/5.
//  Copyright © 2019 Qi Wang. All rights reserved.
//

import UIKit
import XMPPFramework

class ContactViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var tableView: UITableView!
    var xmppManager: XmppManager?
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        view.backgroundColor = UIColor.yellow
        
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
        
        //收到刷新好友列表的通知
        NotificationCenter.default.removeObserver(self, name: Notification.Name("Get_Roster"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(getRoster), name: Notification.Name("Get_Roster"), object: nil)
    }
    
    //MARK: ------ Notification
    @objc func getRoster() {
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
        return (xmppManager?.roster?.count)!
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "Cell")
        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: "Cell")
        }
        
        let friendModel: FriendModel? = xmppManager?.roster?[indexPath.row] as? FriendModel
        cell?.textLabel?.text = friendModel?.name
        cell?.detailTextLabel?.text = friendModel?.status
        return cell!
    }
    
    //MARK: ------ UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        
        let vc = ChatViewController()
        vc.friendModel = xmppManager?.roster?[indexPath.row] as? FriendModel
        navigationController!.pushViewController(vc, animated: true)
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
