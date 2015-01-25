//
//  WoTFAddFriendVC.swift
//  WoTFriends
//
//  Created by Sergey Lukjanov on 24/01/15.
//  Copyright (c) 2015 Sergey Lukjanov. All rights reserved.
//

import UIKit

import WoTFriendsKit


class WoTFAddFriendVC: UITableViewController, UISearchBarDelegate {

    @IBOutlet weak var searchBar: UISearchBar!
    
    private var searchResults: [SearchResult] = [SearchResult]()
    private var selectedResult: SearchResult? = nil

    func refresh(search: String? = nil) {
        self.searchResults = [SearchResult]()
        if countElements(search ?? "") >= 3 {
            wgApi.searchPlayers(search!) {
                results in
                self.searchResults = results
                self.tableView.reloadData()
            }
        }
        self.tableView.reloadData()
    }

    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        let search = searchBar.text
        self.refresh(search: search)
    }

    override func viewDidLoad() {
        self.searchBar.delegate = self
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.refresh()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.searchResults.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as UITableViewCell

        let result = self.searchResults[indexPath.row]
        cell.textLabel?.text = result.nickname
        cell.detailTextLabel?.text = "1h ago"

        return cell
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        let result = self.searchResults[indexPath.row]

        let subscribeMenu = UIAlertController(title: nil, message: "Subscribe to \(result.nickname)?", preferredStyle: .ActionSheet)

        subscribeMenu.addAction(UIAlertAction(title: "Subscribe", style: UIAlertActionStyle.Default, handler: {
            action in
            if friendsManager.addFriend(result.wgId, nickname: result.nickname) {
                self.navigationController?.popToRootViewControllerAnimated(true)
            }
        }))
        subscribeMenu.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
        self.presentViewController(subscribeMenu, animated: true, completion: nil)
    }
}
