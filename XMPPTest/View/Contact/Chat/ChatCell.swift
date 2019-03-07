//
//  ChatCell.swift
//  XMPPTest
//
//  Created by Qi Wang on 2019/3/6.
//  Copyright © 2019 Qi Wang. All rights reserved.
//

import UIKit

class ChatCell: UITableViewCell {

    @IBOutlet weak var namelb: UILabel!
    @IBOutlet weak var chatMsgLb: UILabel!
    
    @IBOutlet weak var meLb: UILabel!
    @IBOutlet weak var rightChatMsgLb: UILabel!
    func setupView(friendModel: FriendModel, chatmsgModel: ChatMessageModel) {
        if chatmsgModel.isSelf == true {
            meLb.isHidden = false
            rightChatMsgLb.text = chatmsgModel.text
            
            namelb.isHidden = true
            chatMsgLb.isHidden = true
        } else {
            namelb.text = friendModel.name
            chatMsgLb.text = chatmsgModel.text
            
            meLb.isHidden = true
            rightChatMsgLb.isHidden = true
        }
        
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
