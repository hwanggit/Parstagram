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

class FeedViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    
    var posts = [PFObject]()
    
    var queryLimit: Int!
    
    let myRefreshControl = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        // Do any additional setup after loading the view.
        
        myRefreshControl.addTarget(self, action: #selector(fetchPosts), for: .valueChanged)
        tableView.refreshControl = myRefreshControl
        fetchPosts()
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
        query.includeKey("author")
        query.limit = queryLimit
        
        query.findObjectsInBackground{
            (posts, error) in
            if posts != nil {
                self.posts = posts!
                self.tableView.reloadData()
            }
        }
    }
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row + 1 == posts.count {
            fetchMorePosts()
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell") as! PostCell
        
        let post = posts[indexPath.row]
        let user = post["author"] as! PFUser
        
        cell.usernameLabel.text = user.username
        cell.contentLabel.text = post["caption"] as? String
        
        let image = post["image"] as! PFFileObject
        let urlString = image.url!
        let url = URL(string: urlString)!
        
        cell.photoView.af_setImage(withURL: url)
        
        return cell
    }
    
}
