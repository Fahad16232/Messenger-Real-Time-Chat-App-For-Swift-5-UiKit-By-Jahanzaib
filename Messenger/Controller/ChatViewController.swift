//
//  ChatViewController.swift
//  Messenger
//
//  Created by Fahad on 09/01/2024.
//

import UIKit
import MessageKit
import InputBarAccessoryView
import SDWebImage
import AVKit
import AVFoundation
import CoreLocation


final class ChatViewController: MessagesViewController, MessageCellDelegate{
    
    private var senderPhotoUrl : URL?
    private var otherUserPhotoUrl : URL?
    
    
    public static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .long
        formatter.locale = .current
        return formatter
    }()
    
    public let otherUserEmail : String
    private var conversationId : String?
    public var isNewConversation = false

    private var messages = [Message]()
    private var selfSender : Sender? {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
       return Sender(photoURL: "", senderId: safeEmail, displayName: "Me")}

    
    init(with email :String, id : String?){
        self.otherUserEmail = email
        self.conversationId = id
        super.init(nibName: nil, bundle: nil)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .red
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messageCellDelegate = self
        messageInputBar.delegate = self
        setUpInputButton()
    }
    
    private func setUpInputButton(){
        let button = InputBarButtonItem()
        button.setSize(CGSize(width: 35, height: 35), animated: false)
        button.setImage(UIImage(systemName: "paperclip"), for: .normal)
        button.onTouchUpInside { [weak self]_ in
            self?.presentInputActionSheet()
        }
        messageInputBar.setLeftStackViewWidthConstant(to: 36, animated: true)
        messageInputBar.setStackViewItems([button], forStack: .left, animated: false)
    }
    private func presentInputActionSheet(){
        let actionSheet = UIAlertController.init(title: "Attach Media", message: "What would you like to attach", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Photo", style: .default , handler: {[weak self] _ in
            self?.presentPhotoInputActionSheet()
        }))
        actionSheet.addAction(UIAlertAction(title: "Video", style: .default , handler: {[weak self] _ in
            self?.presentVideoInputActionSheet()
        }))
        actionSheet.addAction(UIAlertAction(title: "Audio", style: .default , handler: { _ in
            
        }))
        actionSheet.addAction(UIAlertAction(title: "Location", style: .default , handler: {[weak self] _ in
            self?.presentLocationPicker()
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel , handler: nil))
     present(actionSheet, animated: true)
    }
    
    // Location Function
    
    private func presentLocationPicker(){
        let vc = LocationPickerViewController(coordinates: nil)
        vc.title  = "Pick Location "
        vc.navigationItem.largeTitleDisplayMode = .never
        vc.completion = { [weak self] selectedCoordinates in
            guard let strongSelf = self else {
                return
            }
            guard  let messageId = strongSelf.createMessageID(), let conversationId = strongSelf.conversationId , let name = strongSelf.title , let selfSender = strongSelf.selfSender else {
                
                return
            }
            
            let longitude: Double = selectedCoordinates.longitude
            let latitude: Double = selectedCoordinates.latitude
            print("Long:\(longitude)/ Lati:\(latitude)")
            
            let location = Location(location: CLLocation(latitude: latitude, longitude: longitude), size: .zero)
            
            let message = Message(sender: selfSender, messageId: messageId, sentDate: Date(), kind: .location(location))
            
            DatabaseManager.shared.sendMessage(to: conversationId, name: name, otherUserEmail: strongSelf.otherUserEmail, newMessage: message, completion: {success in
                if success {
                   print("Sent location message")
                }
                else{
                    print("Failed to sent location  Message")
                }
            })

        }
        
        navigationController?.pushViewController(vc, animated: true)
    }
    
    // Photo Action Sheet
    private func presentPhotoInputActionSheet(){
        let actionSheet = UIAlertController.init(title: "Attach Photo", message: "Choose a photo to attach", preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default , handler: {[weak self] _ in
      
            let picker =  UIImagePickerController()
            picker.sourceType = .camera
            picker.allowsEditing = true
            picker.delegate = self
            self?.present(picker, animated: true)
            
        }))
        actionSheet.addAction(UIAlertAction(title: "Photo Library", style: .default , handler: {[weak self] _ in
            let picker =  UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.allowsEditing = true
            picker.delegate = self
            self?.present(picker, animated: true)
            
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel , handler: nil ))
     present(actionSheet, animated: true)
    }
    // Video Action Sheet
    
    private func presentVideoInputActionSheet(){
        let actionSheet = UIAlertController.init(title: "Attach Video", message: "Choose a video to attach", preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default , handler: {[weak self] _ in
      
            let picker =  UIImagePickerController()
            picker.sourceType = .camera
            picker.allowsEditing = true
            picker.mediaTypes = ["public.movies"]
            picker.videoQuality = .typeMedium
            picker.delegate = self
            self?.present(picker, animated: true)
            
        }))
       
        actionSheet.addAction(UIAlertAction(title: "Library", style: .default, handler: { [weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.allowsEditing = true
            picker.mediaTypes = ["public.movie"] // Specify the media type for videos
            picker.videoQuality = .typeMedium
            picker.delegate = self
            self?.present(picker, animated: true)
        }))

        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel , handler: nil ))
     present(actionSheet, animated: true)
    }
    
    //
    //scrollToItem with section: strongSelf.messages.count - 1
    private func listenForMessages(id: String, scrollToItem: Bool) {
        DatabaseManager.shared.getAllMessagesForConversation(with: id, completion: { [weak self] result in
            switch result {
            case .success(let messages):
                print("success in getting messages \(messages)")
                guard !messages.isEmpty else {
                    print("Messages are empty")
                    return
                }

                self?.messages = messages
                DispatchQueue.main.async {
                    self?.messagesCollectionView.reloadDataAndKeepOffset()

                    if scrollToItem, let lastSection = self?.messages.count, lastSection > 0 {
                        self?.messagesCollectionView.scrollToItem(
                            at: IndexPath(item: 0, section: lastSection - 1),
                            at: .bottom,
                            animated: true
                        )
                    }
                }
            case .failure(let error):
                print("Failed to get messages: \(error)")
            }
        })
    }

    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        messageInputBar.inputTextView.becomeFirstResponder()
        if let convoID = conversationId {
            listenForMessages(id: convoID,scrollToItem: true)
        }
    }
}


extension ChatViewController : InputBarAccessoryViewDelegate{
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty,
        let selfSender = self.selfSender,
        let messageID = createMessageID() else {
            return
        }
        print("Sending:\(text)")
        
        let message = Message(sender: selfSender, messageId: messageID, sentDate: Date(), kind: .text(text))
        
          //Send Message
        if isNewConversation {
            // Create convo in database
            DatabaseManager.shared.createNewConversation(with: otherUserEmail,name: self.title ?? "User" ,firstMessage: message, completion: { [weak self ] success in
                if success {
                    print("Message sent")
                    self?.isNewConversation = false
                    let newConversationID = "conversation_\(message.messageId)"
                    self?.conversationId = newConversationID
                    self?.listenForMessages(id: newConversationID, scrollToItem: true)
                    self?.messageInputBar.inputTextView.text = nil
                }
                else{
                 print("Failed to sent")
                }
            })
        }
        else{
            guard let conversationId =  conversationId , let name = self.title else {
                return
            }
                
            // Append to existing convo Data
            DatabaseManager.shared.sendMessage(to: conversationId,  name: name, otherUserEmail : otherUserEmail,newMessage: message, completion: {[weak self] success in
                if success {
                    self?.messageInputBar.inputTextView.text = nil

                    print("Message sent")
                }
                    else{
                        print("Failed to send")
                    }
                
            })
        }
    }
    private func createMessageID() -> String? {
        //date , otherUserEmail , senderEmail, randomInt
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        
        let safeCurrentUserEmail = DatabaseManager.safeEmail(emailAddress: currentUserEmail)
        let dateString = Self.dateFormatter.string(from: Date())
        
        let newIdentifier = "\(otherUserEmail)_\(safeCurrentUserEmail)_\(dateString)"
        print("Created Message ID: \(newIdentifier)")
        return newIdentifier
    }
}

extension ChatViewController : UIImagePickerControllerDelegate , UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        guard  let messageId = createMessageID(), let conversationId = conversationId , let name = self.title , let selfSender = selfSender else {
            
            return
        }
        if let image = info[.editedImage] as? UIImage,let imageData = image.pngData() {
            let fileName = "photo_message_" + messageId.replacingOccurrences(of: " ", with: "-") + ".png"
            
            // Upload Image
            storageManager.shared.uploadMessagePhoto(with: imageData, fileName: fileName, completion: {[weak self] result in
                guard let strongSelf = self else {
                    return
                }
                switch result {
                case.success(let urlString):
                    
                   // Ready to send Message
                    print("Uploaded Message Photo: \(urlString)")
                    guard let url = URL(string: urlString) , let placeHolder = UIImage(systemName: "plus") else {
                        return
                    }
                    
                    let media = Media(url: url, image: nil, placeholderImage: placeHolder, size: .zero)
                    
                    let message = Message(sender: selfSender, messageId: messageId, sentDate: Date(), kind: .photo(media))
                    
                    DatabaseManager.shared.sendMessage(to: conversationId, name: name, otherUserEmail: strongSelf.otherUserEmail, newMessage: message, completion: {success in
                        if success {
                           print("Sent photo message")
                        }
                        else{
                            print("Failed to sent photo Message")
                        }
                    })
                case.failure(let error):
                    print("Message photo upload error:\(error)")
                }
            })
        }
        else if let videoUrl = info[.mediaURL] as? URL {
            
            let fileName = "photo_message_" + messageId.replacingOccurrences(of: " ", with: "-") + ".mov"
            // Upload Video
            
            storageManager.shared.uploadMessageVideo(with: videoUrl, fileName: fileName, completion: {[weak self] result in
                guard let strongSelf = self else {
                    return
                }
                switch result {
                case.success(let urlString):
                    
                   // Ready to send Message
                    print("Uploaded Message video: \(urlString)")
                    guard let url = URL(string: urlString) , let placeHolder = UIImage(systemName: "plus") else {
                        return
                    }
                    
                    let media = Media(url: url, image: nil, placeholderImage: placeHolder, size: .zero)
                    
                    let message = Message(sender: selfSender, messageId: messageId, sentDate: Date(), kind: .video(media))
                    
                    DatabaseManager.shared.sendMessage(to: conversationId, name: name, otherUserEmail: strongSelf.otherUserEmail, newMessage: message, completion: {success in
                        if success {
                           print("Sent video message")
                        }
                        else{
                            print("Failed to sent video Message")
                        }
                    })
                case.failure(let error):
                    print("Message video upload error:\(error)")
                }
            })
        }
        
        
        // Send Message
    }
}

extension ChatViewController : MessagesDataSource,MessagesLayoutDelegate, MessagesDisplayDelegate {
    func currentSender() -> MessageKit.SenderType {
        if let sender = selfSender{
            return sender
        }
        fatalError("Self sender is nil, email should be chached")
    
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessageKit.MessagesCollectionView) -> MessageKit.MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessageKit.MessagesCollectionView) -> Int {
        return messages.count
    }
    
    func configureMediaMessageImageView(_ imageView: UIImageView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        guard let message = message as? Message else {
            return
        }
        
        switch message.kind {
        case .photo(let media):
            guard let imageUrl = media.url else {
                return
            }
            imageView.sd_setImage(with: imageUrl)
        default:
            break
        }
    }
    
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        let sender = message.sender
        if sender.senderId == selfSender?.senderId {
            // This is our message that we sent
            return .link
        }
        return .secondarySystemBackground
    }
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        let sender = message.sender
        if sender.senderId == selfSender?.senderId {
            // Show our Image
            if let currentUserImageUrl = self.senderPhotoUrl {
                avatarView.sd_setImage(with: currentUserImageUrl, placeholderImage: nil)
            }
            else {
                
                guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
                    return
                }
                
                let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
                let path = "images/\(safeEmail)_profile_picture.png"
                // Fetch url
                storageManager.shared.downloadUrl(for: path, completion: { [weak self]result in
                    switch result {
                    case.success(let url):
                        self?.senderPhotoUrl = url
                        DispatchQueue.main.async {
                            avatarView.sd_setImage(with: url)
                        }
                    case.failure(let error):
                        print("\(error)")
                    }
                })
            }
        }else {
            // Other User image
        
               
                if let otherUserImageUrl = self.otherUserPhotoUrl {
                    avatarView.sd_setImage(with: otherUserImageUrl, placeholderImage: nil)
                }
                else {
                    // Fetch url
                    let email = self.otherUserEmail
                    
                    
                    let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
                    let path = "images/\(safeEmail)_profile_picture.png"
                    // Fetch url
                    storageManager.shared.downloadUrl(for: path, completion: { [weak self]result in
                        switch result {
                        case.success(let url):
                            self?.senderPhotoUrl = url
                            DispatchQueue.main.async {
                                avatarView.sd_setImage(with: url)
                            }
                        case.failure(let error):
                            print("\(error)")
                        }
                    })
                }
        
    }
}
    
 // Here is the functions of messages
    func didTapMessage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else {
            return
        }
        let message = messages[indexPath.section]
        switch message.kind {
            
        case .location(let locationData):
           
            let coordinates = locationData.location.coordinate
            let vc = LocationPickerViewController(coordinates: coordinates)
            vc.title = "Location"
            navigationController?.pushViewController(vc, animated: true)
        default:
            break
        }

    }
    
    func didTapImage(in cell: MessageCollectionViewCell) {
      
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else {
            return
        }
        let message = messages[indexPath.section]
        switch message.kind {
        case .photo(let media):
            guard let imageUrl = media.url else {
                return
            }
            let vc = PhotoViewerViewController(with: imageUrl)
            navigationController?.pushViewController(vc, animated: true)
            
        case .video(let media):
            guard let videoUrl = media.url else {
                return
            }
            let vc = AVPlayerViewController()
            vc.player = AVPlayer(url: videoUrl)
            present(vc, animated: true)
            
        default:
            break
        }
    }
}
