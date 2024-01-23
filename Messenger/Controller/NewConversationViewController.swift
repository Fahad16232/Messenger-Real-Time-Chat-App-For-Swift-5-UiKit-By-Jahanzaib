//
//  NewConversationViewController.swift
//  Messenger
//
//  Created by Fahad on 26/12/2023.
//

import UIKit
import JGProgressHUD

final class NewConversationViewController: UIViewController {
    
    public var completion : ((SearchResult) -> (Void))?

    private let spinner = JGProgressHUD(style: .dark)
    private var users = [[String: String]]()
    private var results = [SearchResult]()
    private var hasFetched = false
    
    private let serachBar : UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "Search for Users..."
        return searchBar
    }()
    
    private let tableView : UITableView = {
       let table = UITableView()
        table.isHidden = true
        table.register(NewConversationCell.self, forCellReuseIdentifier: NewConversationCell.identifier)
        return table
    }()
    
    private let noUserResult : UILabel = {
        let lable = UILabel()
        lable.isHidden = true
        lable.text = "No Results"
        lable.textAlignment = .center
        lable.textColor = .gray
        lable.font = .systemFont(ofSize: 21, weight: .medium)
        return lable
    }()
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(noUserResult)
        view.addSubview(tableView)
        
        tableView.delegate = self
        tableView.dataSource = self
        
        serachBar.delegate = self
        navigationController?.navigationBar.topItem?.titleView = serachBar
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Cancel", style: .done, target: self, action: #selector(dismissSelf))
        view.backgroundColor = .systemBackground
        serachBar.becomeFirstResponder()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
        noUserResult.frame = CGRect(x: view.width/4, y: (view.height-200)/2, width: view.width/2, height: 200)
    }
    @objc func dismissSelf(){
        dismiss(animated: true)
    }
    
}

extension NewConversationViewController : UITableViewDelegate , UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = results[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: NewConversationCell.identifier, for: indexPath) as! NewConversationCell
        cell.configure(with: model)
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        //start conversation
        let targetUserData = results[indexPath.row]
        dismiss(animated: true, completion: { [weak self] in
            self?.completion?(targetUserData)
        })
     
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90 
    }
}

extension NewConversationViewController : UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let text = searchBar.text, !text.replacingOccurrences(of: " ", with: "").isEmpty else {
            return
        }
        searchBar.resignFirstResponder()
        results.removeAll()
        spinner.show(in: view)
        searchUsers(query: text)
    }
    func searchUsers(query: String){
        // check is array has firebase results
        if hasFetched{
            // if it does: filter
            filterUsers(with: query)
        }
        else {
            // if not , fetch then filter
            DatabaseManager.shared.getAllusers(completion: {[weak self] result in
                switch result {
                case .success(let userCollection):
                    self?.hasFetched = true
                    self?.users = userCollection
                    self?.filterUsers(with: query)
                case.failure(let error):
                    print("Failed to get users: \(error )")
                    
                }
            })
        }
        
        

    }
    func filterUsers(with term: String){
            // update the UI: either show results or show no results lable
            
            guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String, hasFetched else {
                return
            }
            let safeEmail = DatabaseManager.safeEmail(emailAddress: currentUserEmail)
            
            self.spinner.dismiss()
            let results : [SearchResult] = users.filter({
                guard let email = $0["email"],email != safeEmail else {
                    return false
                }
               guard let name = $0["name"]?.lowercased() else{
                    return false
                }
                return name.hasPrefix(term.lowercased())
            }).compactMap({
                 
                guard let email = $0["email"] , let name = $0["name"] else{
                    return nil
                }
                return SearchResult(name: name, email: email)
            })
            self.results = results
            updateUI()
        }
    func updateUI(){
        if results.isEmpty {
            noUserResult.isHidden = false
            tableView.isHidden = true
        }else{
            noUserResult.isHidden = true
            tableView.isHidden = false
            tableView.reloadData()
        }
    }
}

