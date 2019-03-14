//
//  ChatViewController.swift
//  XMPPTest
//
//  Created by Qi Wang on 2019/3/5.
//  Copyright © 2019 Qi Wang. All rights reserved.
//

import UIKit
import SnapKit

class ChatViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var chatHistoryView: UIView!
    @IBOutlet weak var messageView: UIView!
    @IBOutlet weak var tableViewBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet var chatTableView: ChatTableViewController!
    
    @IBOutlet weak var messageTf: UITextField!
    
    var xmppManager: XmppManager!
    
    var friendModel: FriendModel?
    
    @IBAction func sendMessage(_ sender: Any) {
        if messageTf!.text?.isEmpty == false {
            xmppManager.sendMessage(userName: (friendModel?.jid?.full())!, text: messageTf.text!)
            messageTf.text = ""
            //放弃第一响应者
            messageTf.resignFirstResponder()
            //界面上所有输入框停止编辑
//            self.view.endEditing(true)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.

        //添加键盘通知
        addNotification()
        
        xmppManager = XmppManager.sharedInstance()
        
        chatTableView.friendModel = friendModel
        chatHistoryView.addSubview(chatTableView.view)
        chatTableView.view.snp.makeConstraints { (make) in
            make.top.left.right.bottom.equalTo(0)
        }
    }
    
    func addNotification() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(noti:)), name:UIResponder.keyboardWillShowNotification, object: nil)
        
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(noti:)), name:UIResponder.keyboardWillHideNotification, object: nil)
    }

    //MARK: ------ notification
    @objc func keyboardWillShow(noti: NSNotification) {
        let userInfo = noti.userInfo!
        let keyboardBounds = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        
        print(keyboardBounds)
        
        tableViewBottomConstraint.constant = keyboardBounds.size.height+80
        
    }
    
    @objc func keyboardWillHide(noti: NSNotification) {
        tableViewBottomConstraint.constant = 80
        
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
