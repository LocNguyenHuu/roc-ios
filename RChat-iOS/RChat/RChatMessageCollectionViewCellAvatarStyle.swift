//
//  RChatMessageCollectionViewCellAvatarStyle.swift
//  RChat
//
//  Created by Max Alexander on 1/10/17.
//  Copyright © 2017 Max Alexander. All rights reserved.
//

import Foundation
import ChattoAdditions

class RChatMessageCollectionViewCellAvatarStyle: BaseMessageCollectionViewCellDefaultStyle {

    init(){
        let dateStyle = BaseMessageCollectionViewCellDefaultStyle.DateTextStyle(font: RChatConstants.Fonts.dateFont, color: UIColor.darkGray)
        super.init(dateTextStyle: dateStyle)
        baseColorOutgoing = RChatConstants.Colors.primaryColor
    }

    override func avatarSize(viewModel: MessageViewModelProtocol) -> CGSize {
        // Display avatar for both incoming and outgoing messages for demo purpose
        return viewModel.isIncoming ? CGSize(width: 35, height: 35) : CGSize.zero
    }


    
}
