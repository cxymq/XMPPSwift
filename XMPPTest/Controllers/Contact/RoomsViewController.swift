//
//  RoomsViewController.swift
//  XMPPTest
//
//  Created by Qi Wang on 2019/3/14.
//  Copyright © 2019 Qi Wang. All rights reserved.
//

import UIKit
import SnapKit
import XMPPFramework

class RoomsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var tableview: UITableView!
    var xmppManager: XmppManager?
    var rooms: NSMutableArray?
    
    
    init() {
        super.init(nibName: nil, bundle: nil)
        rooms = NSMutableArray.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        self.title = "群组"
        
        //添加群组按钮
        let btnItem = UIBarButtonItem.init(title: "add", style: .done, target: self, action: #selector(addFriend))
        self.navigationItem.rightBarButtonItem = btnItem
        
        tableview = UITableView.init(frame: .zero, style: .plain)
        tableview.delegate = self
        tableview.dataSource = self
        tableview.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        self.view.addSubview(tableview)
        tableview.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
        xmppManager = XmppManager.sharedInstance()
        xmppManager?.loadRooms()
        
        //收到群组列表的通知
        NotificationCenter.default.removeObserver(self, name: Notification.Name("XMPP_GET_GROUPS"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(getRooms(notification:)), name: Notification.Name("XMPP_GET_GROUPS"), object: nil)
    }
    
    //MARK: ------ notification
    @objc func getRooms(notification: Notification) {
        rooms = (notification.object as! NSMutableArray)
        tableview.reloadData()
    }
    
    //MARK: ------ RightBarButtonItem
    @objc func addFriend() {
        let alert = UIAlertController.init(title: "输入群组名称", message: nil, preferredStyle: .alert)
        alert.addTextField { (tf) in
            tf.placeholder = "输入群组名称"
        }
        alert.addTextField { (tf) in
            tf.placeholder = "输入在群组显示的昵称"
        }
        alert.addAction(UIAlertAction.init(title: "确定", style: .default, handler: { (aa) in
            let roomName = alert.textFields?.first?.text
            let nick = alert.textFields?.last?.text
            if (nick != nil) && (roomName != nil) {
                self.xmppManager?.addGroup(name: nick!, roomName: roomName!)
            }
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    //MARK: ------ UITableView
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (rooms?.count)!
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 66
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableview.dequeueReusableCell(withIdentifier: "Cell")
        let item = rooms![indexPath.row] as! XMLElement
        let name = item.attribute(forName: "name")?.stringValue
        cell?.textLabel?.text = name
        return cell!
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableview.deselectRow(at: indexPath, animated: false)
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
