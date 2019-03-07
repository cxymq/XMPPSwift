//
//  ChatTableViewController.swift
//  XMPPTest
//
//  Created by Qi Wang on 2019/3/5.
//  Copyright © 2019 Qi Wang. All rights reserved.
//

import UIKit
import XMPPFramework

class ChatTableViewController: UITableViewController, XMPPStreamDelegate {
    
    var messages: NSMutableArray?
    
    public var friendModel: FriendModel?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        let xmppManager = XmppManager.sharedInstance()
        xmppManager.xmppStream.addDelegate(self, delegateQueue: DispatchQueue.main)
        
        messages = NSMutableArray.init()
        
        tableView.register(UINib(nibName: "ChatCell", bundle: nil), forCellReuseIdentifier: "ChatCell")
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return (messages?.count)!
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: ChatCell = tableView.dequeueReusableCell(withIdentifier: "ChatCell") as! ChatCell
        cell.setupView(friendModel: friendModel!, chatmsgModel: messages![indexPath.row] as! ChatMessageModel)
        return cell
    }
    
    
    
    //MARK: ------XMPPStreamDelegate
    //接收消息
    func xmppStream(_ sender: XMPPStream!, didReceive message: XMPPMessage!) {
        let text = message.body()
        if let msg = text {
            print("ChatTableViewController收到消息\n")
            print(msg)
            let chatmsgModel = ChatMessageModel.init(isSelf: false, text: msg)
            messages?.add(chatmsgModel)
            tableView.reloadData()
        }
        
    }
    
    //监听消息发送成功
    func xmppStream(_ sender: XMPPStream!, didSend message: XMPPMessage!) {
        let text = message.body()
        if let msg = text {
            let chatmsgModel = ChatMessageModel.init(isSelf: true, text: msg)
            messages?.add(chatmsgModel)
            tableView.reloadData()
        }
    }
    
    func xmppStream(_ sender: XMPPStream!, didFailToSend message: XMPPMessage!, error: Error!) {
        print("消息发送失败、\(String(describing: error))")
    }

    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
