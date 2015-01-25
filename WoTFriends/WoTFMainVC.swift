//
//  WoTFMainVC.swift
//  WoTFriends
//
//  Created by Sergey Lukjanov on 24/01/15.
//  Copyright (c) 2015 Sergey Lukjanov. All rights reserved.
//

import UIKit

import Parse

import WoTFriendsKit


class WoTFMainVC: UITableViewController {
    private var friends: [Friend] = [Friend]()

    func reloadData(force: Bool = false) {
        friendsManager.refreshFriendsInfo(force: force) {
            error in
            if !error {
                self.friends = friendsManager.listAll()
                self.tableView.reloadData()
                self.refreshControl?.endRefreshing()
            }
        }
    }

    func doRefresh() {
        self.reloadData(force: true)
    }

    func getFriend(indexPath: NSIndexPath) -> Friend {
        return self.friends[indexPath.row]
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.refreshControl?.addTarget(self, action: "doRefresh", forControlEvents: UIControlEvents.ValueChanged)
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.reloadData()
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.friends.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as UITableViewCell
        let friend = self.friends[indexPath.row]

        cell.textLabel?.text = friend.nickname
        cell.detailTextLabel?.text = friend.lastSeenAgo()

        if friend.isSubscribed {
            cell.accessoryType = .Checkmark
        } else {
            cell.accessoryType = .None
        }

        return cell
    }

    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
    }

    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [AnyObject]?  {
        let friend = getFriend(indexPath)

        let inviteAction = UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: "Invite") {
            action, indexPath in
            let inviteMenu = UIAlertController(title: nil, message: "Invite \(friend.nickname) to play?", preferredStyle: .ActionSheet)
        
            inviteMenu.addAction(UIAlertAction(title: "Invite", style: UIAlertActionStyle.Default) {
                action in
                let push = PFPush()
                push.setChannel("invite\(friend.wgId)")
                push.setData(["alert": "Someplayer invites you to play WoT!"])
                push.sendPushInBackgroundWithBlock {
                    (succeeded, error) in
                    NSLog("Push notification send, success: \(succeeded), error: \(error)")
                }
                })
            inviteMenu.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
            self.presentViewController(inviteMenu, animated: true, completion: nil)
        }
        inviteAction.backgroundColor = UIColor.greenColor()

        let deleteAction = UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: "Delete") {
            (action:UITableViewRowAction!, indexPath:NSIndexPath!) -> Void in

            let deleteMenu = UIAlertController(title: nil, message: "Delete \(friend.nickname) from list?", preferredStyle: .ActionSheet)

            deleteMenu.addAction(UIAlertAction(title: "Delete", style: UIAlertActionStyle.Default) {
                action in
                self.friends = friendsManager.removeFriendAndReturnAll(self.friends[indexPath.row].wgId)
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)

            })
            deleteMenu.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))

            self.presentViewController(deleteMenu, animated: true, completion: nil)
        }

        if friend.isFriend {
            return [deleteAction]
        } else {
            return [deleteAction, inviteAction]
        }
    }


    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)

        let friend = getFriend(indexPath)
        let subscribeType = friend.isSubscribed ? "Unsubscribe" : "Subscribe"

        let subscribeMenu = UIAlertController(title: nil, message: "\(subscribeType) to \(friend.nickname)?", preferredStyle: .ActionSheet)

        subscribeMenu.addAction(UIAlertAction(title: subscribeType, style: UIAlertActionStyle.Default, handler: {
            action in
            let friend = self.getFriend(indexPath)
            let newIsSubscribed = !friend.isSubscribed

            self.friends = friendsManager.updateFriendAndReturnAll(friend.wgId, isSubscribed: newIsSubscribed)

            let installation = PFInstallation.currentInstallation()
            installation.channels = self.friends.filter { $0.isSubscribed }.map { "wg\($0.wgId)" }
            installation.saveInBackgroundWithBlock {
                (succeeded, error) in
                NSLog("PFInstallation saved: \(succeeded); channels: \(installation.channels)")
            }

            let cell = tableView.cellForRowAtIndexPath(indexPath)
            cell?.accessoryType = newIsSubscribed ? .Checkmark : .None
        }))
        subscribeMenu.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
        self.presentViewController(subscribeMenu, animated: true, completion: nil)
    }
}
