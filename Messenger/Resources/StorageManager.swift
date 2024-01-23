//
//  StorageManager.swift
//  Messenger
//
//  Created by Fahad on 10/01/2024.
//

import Foundation
import FirebaseStorage

/// Alow you to get, fetch and upload files to firebase storage
final class storageManager {
    
    static let shared = storageManager()
    private init() {}
    private let storage = Storage.storage().reference()
    
    public typealias UploadPictureCompletion = (Result<String, Error>) -> Void
    ///Upload pictures to firebase storage and return completion with url string to download
    
    public func uploadProfilePicture(with data : Data , fileName: String,completion:@escaping UploadPictureCompletion) {
        storage.child("images/\(fileName)").putData(data, metadata: nil, completion: { [weak self] metadata, error in
            guard let strongSelf = self else {
                return
            }
            guard error == nil else {
                //failed
                print("Failed to upload data to firebase for picture")
                completion(.failure(StorageError.failedToUpload))
                return
            }
            strongSelf.storage.child("images/\(fileName)").downloadURL(completion:{ url , error in
                guard let url = url else {
                    print("Failed to get download url")
                    completion(.failure(StorageError.failedToGetDownloadUrl))
                    return
                }
                let urlString = url.absoluteString
                print("Download url returned: \(urlString)")
                completion(.success(urlString))
            })
        })
    }
    
    ///Upload image that will be sent in a conversation message
    
    public func uploadMessagePhoto(with data : Data , fileName: String,completion:@escaping UploadPictureCompletion) {
        storage.child("message_images/\(fileName)").putData(data, metadata: nil, completion: {[weak self] metadata, error in
            guard error == nil else {
                //failed
                print("Failed to upload data to firebase for picture")
                completion(.failure(StorageError.failedToUpload))
                return
            }
            self?.storage.child("message_images/\(fileName)").downloadURL(completion:{ url , error in
                guard let url = url else {
                    print("Failed to get download url")
                    completion(.failure(StorageError.failedToGetDownloadUrl))
                    return
                }
                let urlString = url.absoluteString
                print("Download url returned: \(urlString)")
                completion(.success(urlString))
            })
        })
    }
    
    ///Upload video that will be sent in a conversation message
    
    public func uploadMessageVideo(with fileUrl : URL , fileName: String,completion:@escaping UploadPictureCompletion) {
        let metadata = StorageMetadata()
        //specify MIME type
        metadata.contentType = "video/quicktime"

        //convert video url to data
        if let videoData = NSData(contentsOf: fileUrl) as Data? {
            //use 'putData' instead
            // Move the storage.child call here
            storage.child("message_videos/\(fileName)").putData(videoData, metadata : metadata, completion: {[weak self] metadata, error in
                guard error == nil else {
                    //failed
                    print("Failed to upload data to firebase for video")
                    completion(.failure(StorageError.failedToUpload))
                    return
                }
                self?.storage.child("message_videos/\(fileName)").downloadURL(completion:{ url , error in
                    guard let url = url else {
                        print("Failed to get download url")
                        completion(.failure(StorageError.failedToGetDownloadUrl))
                        return
                    }
                    let urlString = url.absoluteString
                    print("Download url returned: \(urlString)")
                    completion(.success(urlString))
                })
            })
        }
        
    }
    public enum StorageError : Error{
        case failedToUpload
        case failedToGetDownloadUrl
    }
    public func downloadUrl(for path : String, completion : @escaping (Result<URL, Error>)-> Void){
        let refrence = storage.child(path)
        refrence.downloadURL(completion: {url , error in
            guard let url = url , error == nil else{
                completion(.failure(StorageError.failedToGetDownloadUrl))
                return
            }
            completion(.success(url))
        })
    }
}

