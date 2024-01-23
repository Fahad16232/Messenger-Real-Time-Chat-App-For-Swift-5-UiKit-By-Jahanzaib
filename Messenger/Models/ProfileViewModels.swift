//
//  ProfileViewModels.swift
//  Messenger
//
//  Created by Fahad on 23/01/2024.
//

import Foundation

enum ProfileViewModelType {
case info, logout
}

struct ProfileViewModel{
    let viewModelType : ProfileViewModelType
    let title : String
    let handler : (() -> Void)?
    
}
