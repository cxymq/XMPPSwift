//
//  LoginViewController.swift
//  XMPPTest
//
//  Created by Qi Wang on 2019/3/5.
//  Copyright © 2019 Qi Wang. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {
    
    var xmppManager: XmppManager?
    
    @IBOutlet weak var userNameTf: UITextField!
    
    @IBOutlet weak var pwdTf: UITextField!
    
    @IBAction func loginXMPP(_ sender: Any) {
        if self.userNameTf.text == nil || self.pwdTf.text == nil {
            print("用户名或密码不能为空")
        } else {
            self.xmppManager?.connectXMPP(userName: self.userNameTf!.text!, pwd: self.pwdTf!.text!)
        }
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.xmppManager = XmppManager.sharedInstance()
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
