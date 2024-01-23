//
//  ConversationTableViewCell.swift
//  Messenger
//
//  Created by Fahad on 12/01/2024.
//

import UIKit
import SDWebImage



class ConversationTableViewCell: UITableViewCell {
    static let identifier = "ConversationTableViewCell"
    
    private let userImageView : UIImageView = {
       let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 50
        imageView.layer.masksToBounds = true
        return imageView
    }()
    
    private let userNameLable : UILabel = {
       let label = UILabel()
        label.font = .systemFont(ofSize: 21, weight: .semibold)
        return label
        
    }()
    
    private let userMessageLable : UILabel = {
       let label = UILabel()
        label.font = .systemFont(ofSize: 19, weight: .regular)
        label.numberOfLines = 0
        return label
        
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(userImageView)
        contentView.addSubview(userNameLable)
        contentView.addSubview(userMessageLable)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        userImageView.frame = CGRect(x: 10, y: 10, width: 100, height: 100)
        userNameLable.frame = CGRect(x:userImageView.right + 10, y: 10, width: contentView.width - 20 - userImageView.width, height: (contentView.height-20)/2)
        userMessageLable.frame = CGRect(x:userImageView.right + 10, y: userNameLable.bottom
                                        + 10, width: contentView.width - 20 - userImageView.width, height: (contentView.height-20)/2)    }
    public func configure(with model :Conversation){
        userMessageLable.text = model.latestMessage.text
        userNameLable.text = model.name
        let path = "images/\(model.otherUseremail)_profile_picture.png"
        storageManager.shared.downloadUrl(for: path, completion: {[weak self] result in
            switch result {
            case.success(let url):
                DispatchQueue.main.async {
                    self?.userImageView.sd_setImage(with: url, completed: nil)

                }
            case.failure(let error):
                print("Failed to get image url:\(error)")
            }
        })
    }
}
