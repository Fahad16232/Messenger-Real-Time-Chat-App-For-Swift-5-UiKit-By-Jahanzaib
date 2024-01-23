//
//  LoginViewController.swift
//  Messenger
//
//  Created by Fahad on 26/12/2023.
//

import UIKit
import FirebaseAuth
import FBSDKLoginKit
import GoogleSignIn
import FirebaseDatabase
import JGProgressHUD

final class LoginViewController: UIViewController {
    
    private let spinner = JGProgressHUD(style: .dark)
    //Crash Button
    private let crashButton: UIButton = {
        let button = UIButton()
        button.setTitle("Test Action", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        return button
    }()
//
    
    private let scrollView : UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        return scrollView
    }()
    
    private let imageView : UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "logo")
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let emailField : UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .continue
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Email Address"
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .secondarySystemBackground
        return field
    }()
    private let passwordField : UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .done
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Password"
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .secondarySystemBackground
        field.isSecureTextEntry = true
        return field
    }()
    
    private let loginButton : UIButton = {
        let button = UIButton()
        button.setTitle("Log In", for: .normal)
        button.backgroundColor = .link
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        return button
    }()
    private let facbookLoginButton: FBLoginButton = {
        let button = FBLoginButton()
        button.permissions = ["email", "public_profile"]
        button.layer.cornerRadius = 12
        button.backgroundColor = .link
        button.layer.masksToBounds = true
        return button
    }()
    private let googleLoginButton: GIDSignInButton = {
        let button = GIDSignInButton()
        button.style = .wide
        button.colorScheme = .dark
        button.layer.cornerRadius = 12
        button.backgroundColor = .link
        button.layer.masksToBounds = true
        
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Log In"
        view.backgroundColor = .systemBackground
        //Crash button
        crashButton.addTarget(self, action: #selector(crashButtonTapped), for: .touchUpInside)
            scrollView.addSubview(crashButton)
        //
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Register", style: .done, target: self, action: #selector(didTapRegister))
        
        loginButton.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(googleLoginButtonTapped))
        
        emailField.delegate = self
        passwordField.delegate = self
        
        facbookLoginButton.delegate = self
        
        // Add SubViews
        
        
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        scrollView.addSubview(emailField)
        scrollView.addSubview(passwordField)
        scrollView.addSubview(loginButton)
        scrollView.addSubview(googleLoginButton)
        scrollView.addGestureRecognizer(tapGesture)
        scrollView.addSubview(facbookLoginButton)
        
        
        
    }
    override func viewDidLayoutSubviews() {
        
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds
        
        let size = scrollView.width/3
        imageView.frame = CGRect(x: (scrollView.width-size)/2, y: 100, width: size, height: size)
        emailField.frame = CGRect(x: 30, y: imageView.bottom+10, width: scrollView.width-60, height: 42)
        passwordField.frame = CGRect(x: 30, y: emailField.bottom+10, width: scrollView.width-60, height: 42)
        loginButton.frame = CGRect(x: 30, y: passwordField.bottom+10, width: scrollView.width-60, height: 42)
        facbookLoginButton.frame = CGRect(x: 30, y: loginButton.bottom+10, width: scrollView.width-60, height: 42)
        googleLoginButton.frame = CGRect(x: 30, y: facbookLoginButton.bottom+10, width: scrollView.width-60, height: 40)
      
        //Crash button
        crashButton.frame = CGRect(x: 30, y: googleLoginButton.bottom + 20, width: scrollView.width - 60, height: 42)
        //
        
        facbookLoginButton.center = scrollView.center
        facbookLoginButton.frame.origin.y = loginButton.bottom+20
        
        googleLoginButton.center = scrollView.center
        googleLoginButton.frame.origin.y = facbookLoginButton.bottom+20
    }
    //Crash Button
    @objc private func crashButtonTapped() {
        let numbers = [0]
        let _ = numbers[1]
        print("Crash button tapped!")
    }
  //
    @objc private func loginButtonTapped(){
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
        
        UIView.animate(withDuration: 0.2, animations: {
            self.loginButton.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }) { _ in
            UIView.animate(withDuration: 0.2) {
                self.loginButton.transform = .identity
                // Perform additional actions if needed
            }
        }
        guard let email = emailField.text , let password = passwordField.text, !email.isEmpty , !password.isEmpty , password.count >= 6 else {
            alertUserLoginError()
            return
        }
        
        spinner.show(in: view)
        
        //MARK: //FireBase Login
        
        FirebaseAuth.Auth.auth().signIn(withEmail: email, password: password , completion: {[weak self] AuthDataResult , error in
            
            guard let strongSelf = self else {
                return
            }
            
            DispatchQueue.main.async {
                strongSelf.spinner.dismiss()
            }
            
            guard let result = AuthDataResult , error == nil else {
                print("Failed to log in with email:\(email)")
                return
            }
            let user = result.user
            
            let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
            DatabaseManager.shared.getDataFor(path:safeEmail, completion: { result in
                switch result {
                case.success(let data):
                    guard let userData = data as? [String:Any],
                    let firstName = userData["first_name"],
                    let lastName = userData["last_name"] else {
                        return
                    }
                    UserDefaults.standard.set("\(firstName) \(lastName)", forKey: "name")
                    
                case.failure(let error):
                    print("Failed to get the data with error: \(error)")
                }
            })
            
            
            UserDefaults.standard.set(email, forKey: "email")
            
            print("Logged in User:\(user)")
            strongSelf.navigationController?.dismiss(animated: true)
        })
        
    }
    
    func alertUserLoginError(){
        let alert = UIAlertController(title: "Oopss", message: "Checke Information Correctly", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dissmiss", style: .cancel))
        present(alert, animated: true)
    }
    
    @objc private func didTapRegister(){
        let vc = RegisterViewController()
        vc.title = "Create Account"
        navigationController?.pushViewController(vc, animated: true)
    }
    
}

extension LoginViewController : UITextFieldDelegate{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailField {
            passwordField.becomeFirstResponder()
        }
        else if textField == passwordField {
            loginButtonTapped()
        }
        
        return true
    }
}

extension LoginViewController : LoginButtonDelegate {
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginKit.FBLoginButton) {
        //no operations
    }
    
    
    func loginButton(_ loginButton: FBSDKLoginKit.FBLoginButton, didCompleteWith result: FBSDKLoginKit.LoginManagerLoginResult?, error: (Error)?) {
        guard let token = result?.token?.tokenString else {
            print("User failed to log in with facebook")
            return
        }
        
        let facebookRequest = FBSDKLoginKit.GraphRequest(graphPath: "me", parameters: ["fields":"email,first_name,last_name,picture.type(large)"], tokenString: token, version: nil, httpMethod: .get)
        facebookRequest.start(completion: { _ , result , error in
            guard let result = result as? [String: Any] ,
                  error == nil else {
                print("failed to make facebook graph request")
                return
            }
            print("\(result)")
          
            guard let firstName = result ["first_name"] as? String,
                  let lastName = result ["last_name"] as? String ,
                  let email = result ["email"] as? String ,
            let picture = result ["picture"] as? [String: Any] ,
                let data = picture ["data"] as? [String: Any] ,
                let pictureUrl = data["url"] as? String
            else {
                print("Failed to get email and name from FB result")
                return
            }
            UserDefaults.standard.set(email, forKey: "email")
            UserDefaults.standard.set("\(firstName) \(lastName)", forKey: "name")

            DatabaseManager.shared.userExists(with: email, completion: { exists in
                if !exists {
                    let chatUser = ChatAppUser(firstName: firstName, lastName: lastName, emailAddress: email)
                    DatabaseManager.shared.insertUser(with: chatUser , completion: { success in
                        if success{
                            guard let url = URL(string: pictureUrl) else {
                                return
                            }
                            print("Downloading data from facebook image")
                            URLSession.shared.dataTask(with: url, completionHandler: {data , _ ,_ in
                                guard let data = data else{
                                    print("failed to get data from FB")
                                    return
                                }
                                print("Got data from facebook uploading...")
                                //upload image
                                let fileName = chatUser.profilePictureFileName
                                storageManager.shared.uploadProfilePicture(with: data, fileName: fileName, completion: { result in
                                    switch result{
                                    case .success(let downloadUrl):
                                        UserDefaults.standard.set(downloadUrl, forKey: "profile_picture_url")
                                        print(downloadUrl)
                                    case .failure(let error):
                                        print("Storage Manager Error:\(error)")
                                    }

                                })
                            }).resume()
                        }
                    })
                    return
                }
                
            })
            
            let credential = FacebookAuthProvider.credential(withAccessToken: token)
            
            FirebaseAuth.Auth.auth().signIn(with: credential , completion: { [weak self] AuthDataResult , error in
                guard let strongSelf = self else {
                    return
                }
                
                guard AuthDataResult != nil , error == nil else {
                    if let error = error{
                        print("Facebook credential login failed, MFA may be needed - \(error)")
                    }
                    return
                }
                print("Successfuly logged user in")
                strongSelf.navigationController?.dismiss(animated: true)
            })
            
        })
        
    }
    
    
}
extension LoginViewController {
    @objc private func googleLoginButtonTapped() {
        GIDSignIn.sharedInstance.signIn(withPresenting: self) { userGD, error in
            guard error == nil else {
                print("Error signing in with Google: \(error!)")
                return
            }
            
            // If sign-in succeeded, you can access user information here.
            guard let userGD = userGD else {
                print("Sign-in result is nil")
                return
            }
            
            let user = userGD.user
            let emailAddress = user.profile?.email
            let fullName = user.profile?.name
            let givenName = user.profile?.givenName
            let familyName = user.profile?.familyName
            let profilePicUrl = user.profile?.imageURL(withDimension: 320)
            
            // Now, you can perform further actions with the user's information.
            print("Google Sign-In succeeded!")
            print("Email: \(emailAddress ?? "N/A")")
            print("Full Name: \(fullName ?? "N/A")")
            print("Given Name: \(givenName ?? "N/A")")
            print("Family Name: \(familyName ?? "N/A")")
            print("Profile Picture URL: \(profilePicUrl?.absoluteString ?? "N/A")")
            
            UserDefaults.standard.set(emailAddress, forKey: "email")
            UserDefaults.standard.set("\(givenName) \(familyName)", forKey: "name")

            
            // TODO: Perform additional actions, e.g., Firebase authentication, database operations, etc.
            DatabaseManager.shared.userExists(with: emailAddress!, completion: { exists in
                if !exists {
                    let chatUser = ChatAppUser(firstName: givenName!, lastName: familyName!, emailAddress: emailAddress!)
                    DatabaseManager.shared.insertUser(with: chatUser , completion: {success in
                        if success {
                            //upload image
                            if ((user.profile?.hasImage) != nil){
                                guard let url = user.profile?.imageURL(withDimension: 200) else {
                                    return
                                }
                                URLSession.shared.dataTask(with: url, completionHandler: {data,_,_ in
                                    guard let data = data else{
                                        return
                                    }
                                    let fileName = chatUser.profilePictureFileName
                                    storageManager.shared.uploadProfilePicture(with: data, fileName: fileName, completion: { result in
                                        switch result{
                                        case .success(let downloadUrl):
                                            UserDefaults.standard.set(downloadUrl, forKey: "profile_picture_url")
                                            print(downloadUrl)
                                        case .failure(let error):
                                            print("Storage Manager Error:\(error)")
                                        }

                                    })
                                }).resume()
                                
                            }
                            
                        }
                    })
                    return
                }
                
            })
            
            let credential = GoogleAuthProvider.credential(withIDToken: user.idToken!.tokenString, accessToken: user.accessToken.tokenString)
            
            FirebaseAuth.Auth.auth().signIn(with: credential) { [weak self] userGD , error in
                guard let strongSelf = self else {
                    return
                }
                guard userGD != nil, error == nil else {
                    if let error = error {
                        print("Firebase authentication error: \(error.localizedDescription)")
                    }
                    return
                }
                
                // User is now signed in with Firebase
                print("Firebase Sign-In succeeded!")
                strongSelf.navigationController?.dismiss(animated: true)
                
                let chatUser = ChatAppUser(firstName: givenName!, lastName: familyName!, emailAddress: emailAddress!)
                DatabaseManager.shared.insertUser(with: chatUser , completion: { success in
                    if success {
                        //upload image
//
                    }
                })
            }
        }
    }
}

