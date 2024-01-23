//
//  ConversationsModels.swift
//  Messenger
//
//  Created by Fahad on 23/01/2024.
//

import Foundation

struct Conversation {
    let id : String
    let name : String
    let otherUseremail : String
    let latestMessage: LatestMessage
    
}

struct LatestMessage {
    let date : String
    let text : String
    let isRead : Bool
}

