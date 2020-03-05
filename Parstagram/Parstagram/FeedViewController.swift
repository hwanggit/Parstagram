//
//  FeedViewController.swift
//  Parstagram
//
//  Created by Luhao Wang on 2/25/20.
//  Copyright © 2020 Luhao Wang. All rights reserved.
//

import UIKit
import Parse
import AlamofireImage
import MessageInputBar

class FeedViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, MessageInputBarDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    let commentBar = MessageInputBar()
    var showsCommentsBar = false
    
    var posts = [PFObject]()
    var selectedPost: PFObject!
    
    var queryLimit: Int!
    
    let myRefreshControl = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        commentBar.inputTextView.placeholder = "Add a comment..."
        commentBar.sendButton.title = "Post"
        commentBar.delegate = self
        
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.keyboardDismissMode = .interactive
        
        let center = NotificationCenter.default
        
        center.addObserver(self, selector: #selector(keyboardWillBeHidden(note:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        // Do any additional setup after loading the view.
        
        myRefreshControl.addTarget(self, action: #selector(fetchPosts), for: .valueChanged)
        tableView.refreshControl = myRefreshControl
        fetchPosts()
    }
    
    @objc func keyboardWillBeHidden(note: Notification) {
        commentBar.inputTextView.text = nil
        showsCommentsBar = false
        becomeFirstResponder()
    }
    
    override var inputAccessoryView: UIView? {
        return commentBar
    }
    
    override var canBecomeFirstResponder: Bool {
        return showsCommentsBar
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.tableView.reloadData()
    }
    
    @objc func fetchPosts() {
        queryLimit = 20
        
        let query = PFQuery(className: "Posts")
        query.includeKey("author")
        query.limit = queryLimit
        
        query.findObjectsInBackground{
            (posts, error) in
            if posts != nil {
                self.posts = posts!
                self.tableView.reloadData()
            }
        }
        
        self.myRefreshControl.endRefreshing()
    }
    
    func fetchMorePosts() {
        queryLimit += 20
        
        let query = PFQuery(className: "Posts")
        query.includeKeys(["author", "comments", "comments.author"])
        query.limit = queryLimit
        
        query.findObjectsInBackground{
            (posts, error) in
            if posts != nil {
                self.posts = posts!
                self.tableView.reloadData()
            }
        }
    }
    
    func messageInputBar(_ inputBar: MessageInputBar, didPressSendButtonWith text: String) {
        let comment = PFObject(className: "Comments")
        comment["text"] = text
        comment["post"] = selectedPost
        comment["author"] = PFUser.current()!
        
        selectedPost.add(comment, forKey: "comments")
        
        selectedPost.saveInBackground {
            (success, error) in
            if success {
                print("Comment saved")
            } else {
                print("Error saving comment")
            }
        }
        
        tableView.reloadData()
        
        commentBar.inputTextView.text = nil
        showsCommentsBar = false
        becomeFirstResponder()
        commentBar.inputTextView.resignFirstResponder()
    }

    
    @IBAction func onLogout(_ sender: Any) {
        PFUser.logOut()
        
        let main = UIStoryboard(name: "Main", bundle: nil)
        
        let loginViewController = main.instantiateViewController(withIdentifier: "LoginViewController")
        
        let sceneDelegate = self.view.window?.windowScene?.delegate as! SceneDelegate
        
        sceneDelegate.window?.rootViewController = loginViewController
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let post = posts[indexPath.section]
        
        let comments = (post["comments"] as? [PFObject]) ?? []
        
        if indexPath.row == comments.count + 1 {
            showsCommentsBar = true
            becomeFirstResponder()
            
            commentBar.inputTextView.becomeFirstResponder()
            
            selectedPost = post
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.section + 1 == posts.count {
            fetchMorePosts()
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let post = posts[section]
        let comments = (post["comments"] as? [PFObject]) ?? []
        
        return comments.count + 2
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let post = posts[indexPath.section]
        let comments = (post["comments"] as? [PFObject]) ?? []
        
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell") as! PostCell
            
            let user = post["author"] as! PFUser
            
            cell.usernameLabel.text = user.username
            cell.contentLabel.text = post["caption"] as? String
            
            let image = post["image"] as! PFFileObject
            let urlString = image.url!
            let url = URL(string: urlString)!
            
            cell.photoView.af_setImage(withURL: url)
            
            return cell
        } else if indexPath.row <= comments.count {
            let cell = tableView.dequeueReusableCell(withIdentifier: "CommentCell") as! CommentCell
            
            let comment = comments[indexPath.row - 1]
            
            cell.comment.text = comment["text"] as? String
            
            let user = comment["author"] as! PFUser
            cell.nameLabel.text = user.username
            
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "AddCommentCell")!
            
            return cell
        }
    }
}
