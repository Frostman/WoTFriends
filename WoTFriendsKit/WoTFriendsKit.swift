//
//  WoTFriendsKit.swift
//  WoTFriends
//
//  Created by Sergey Lukjanov on 22/01/15.
//  Copyright (c) 2015 Sergey Lukjanov. All rights reserved.
//

import Foundation

import Alamofire
import SwiftyJSON


/**
Copy-pasted from https://github.com/SwiftyJSON/Alamofire-SwiftyJSON
Created by Pinglin Tang with MIT License
*/
extension Request {

    /**
    Adds a handler to be called once the request has finished.

    :param: completionHandler A closure to be executed once the request has finished. The closure takes 4 arguments: the URL request, the URL response, if one was received, the SwiftyJSON enum, if one could be created from the URL response and data, and any error produced while creating the SwiftyJSON enum.

    :returns: The request.
    */
    public func responseSwiftyJSON(completionHandler: (NSURLRequest, NSHTTPURLResponse?, SwiftyJSON.JSON, NSError?) -> Void) -> Self {
        return responseSwiftyJSON(queue:nil, options:NSJSONReadingOptions.AllowFragments, completionHandler:completionHandler)
    }

    /**
    Adds a handler to be called once the request has finished.

    :param: queue The queue on which the completion handler is dispatched.
    :param: options The JSON serialization reading options. `.AllowFragments` by default.
    :param: completionHandler A closure to be executed once the request has finished. The closure takes 4 arguments: the URL request, the URL response, if one was received, the SwiftyJSON enum, if one could be created from the URL response and data, and any error produced while creating the SwiftyJSON enum.

    :returns: The request.
    */
    public func responseSwiftyJSON(queue: dispatch_queue_t? = nil, options: NSJSONReadingOptions = .AllowFragments, completionHandler: (NSURLRequest, NSHTTPURLResponse?, JSON, NSError?) -> Void) -> Self {

        return response(queue: queue, serializer: Request.JSONResponseSerializer(options: options), completionHandler: { (request, response, object, error) -> Void in

            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {

                var responseJSON: JSON
                if error != nil || object == nil{
                    responseJSON = JSON.nullJSON
                } else {
                    responseJSON = SwiftyJSON.JSON(object!)
                }

                dispatch_async(queue ?? dispatch_get_main_queue(), {
                    completionHandler(self.request, self.response, responseJSON, error)
                })
            })
        })
    }
}


public let never: NSTimeInterval = 0


public typealias FriendInfoUpdate = (nickname: String?, isFriend: Bool?, lastBattleTime: NSTimeInterval?)
public typealias SearchResult = (nickname: String, wgId: Int)


public class WargamingApi {
    private let apiUrl = "https://api.worldoftanks.ru/wot/"
    private let applicationId = "095b11d9609060b4951bdcf0c9add401"

    private let authEndpoint = "auth/login"
    private let accountListEndpoint = "account/list"
    private let accountInfoEndpoint = "account/info"

    public let authRedirectHost = "localhost"
    public var authUrl: String {
        get { return "\(apiUrl)\(authEndpoint)/?application_id=\(applicationId)"
            + "&redirect_uri=https://\(authRedirectHost)/" }
    }

    private func requestApi(endpoint: String, parameters: [String: String]? = nil,
        retries: Int = 0, handler: (json: SwiftyJSON.JSON?) -> Void) {
            if retries >= 0 {
                let url = "\(apiUrl)\(endpoint)/"
                Alamofire.request(.GET, url, parameters: parameters)
                    .validate(statusCode: 200..<300)
                    .validate(contentType: ["application/json"])
                    .responseSwiftyJSON {
                        (request, response, json, error) in
                        if error == nil && json != SwiftyJSON.JSON.nullJSON {
                            handler(json: json)
                            return
                        }
                        if response?.statusCode == 407 {
                            // REQUEST_LIMIT_EXCEEDED
                            // TODO schedule retry in a second
                        }
                        self.requestApi(endpoint, parameters: parameters, retries: retries - 1,
                            handler: handler)
                }
            } else {
                handler(json: nil)
            }
    }

    public func getFriendInfoUpdates(wgIds: [Int], handler: ([Int: FriendInfoUpdate]?) -> Void) {
        requestApi(accountInfoEndpoint, parameters: ["application_id": applicationId,
            "account_id": ",".join(wgIds.map { String($0) })], retries: 3) {
                json in
                if let json = json {
                    if json["status"].string == "ok" {
                        var updates = [Int: FriendInfoUpdate]()
                        for (wgId, account) in json["data"].dictionaryValue {
                            let nickname = account["nickname"].stringValue
                            let lastBattleTime = account["last_battle_time"].doubleValue

                            updates[wgId.toInt()!] = FriendInfoUpdate(nickname: nickname, isFriend: nil, lastBattleTime: lastBattleTime)
                        }
                        handler(updates)
                        return
                    }
                }
                handler(nil)
        }
    }

    public func searchPlayers(search: String, handler: (results: [SearchResult]) -> Void) {
        requestApi(accountListEndpoint, parameters: ["application_id": applicationId,
            "type": "startswith", "search": search, "limit": "25", "fields": "account_id,nickname"], retries: 3) {
                json in
                var results = [SearchResult]()
                if let json = json {
                    if json["status"].string == "ok" {
                        for result in json["data"].arrayValue {
                            let wgId = result["account_id"].intValue
                            let nickname = result["nickname"].stringValue
                            results.append(SearchResult(nickname: nickname, wgId: wgId))
                        }
                    }
                }
                handler(results: results)
        }
    }
}


public let wgApi = WargamingApi()


public class Friend : NSObject, NSCoding {
    public let wgId: Int
    public var nickname: String
    public var isSubscribed: Bool
    public var isFriend: Bool
    public var lastBattleTime: NSTimeInterval

    public init(wgId: Int, nickname: String, isSubscribed: Bool = false, isFriend: Bool = false,
        lastBattleTime: NSTimeInterval = never) {
            self.wgId = wgId
            self.nickname = nickname
            self.isSubscribed = isSubscribed
            self.isFriend = isFriend
            self.lastBattleTime = lastBattleTime
    }

    public func lastSeenAgo() -> String {
        let now = NSDate().timeIntervalSince1970
        let ago = NSString(format: "%.0f", (now - self.lastBattleTime) / 3600)
        return "\(ago)h ago"
    }

    required convenience public init(coder aDecoder: NSCoder) {
        let wgId = aDecoder.decodeObjectForKey("wgId") as? Int
        let nickname = aDecoder.decodeObjectForKey("nickname") as? String
        let isSubscribed = aDecoder.decodeObjectForKey("isSubscribed") as? Bool ?? false
        let isFriend = aDecoder.decodeObjectForKey("isFriend") as? Bool ?? false
        let lastBattleTime = aDecoder.decodeObjectForKey("lastBattleTime") as? NSTimeInterval ?? never

        self.init(wgId: wgId!, nickname: nickname!, isSubscribed: isSubscribed, isFriend: isFriend,
            lastBattleTime: lastBattleTime)
    }

    public func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(wgId, forKey: "wgId")
        aCoder.encodeObject(nickname, forKey: "nickname")
        if isSubscribed {
            aCoder.encodeObject(isSubscribed, forKey: "isSubscribed")
        }
        if isFriend {
            aCoder.encodeObject(isFriend, forKey: "isFriend")
        }
        if lastBattleTime != never {
            aCoder.encodeObject(lastBattleTime, forKey: "lastBattleTime")
        }
    }
}


func friendIsOrderedBefore(left: Friend, right: Friend) -> Bool {
    return left.nickname < right.nickname
}


public class FriendsManager {
    private let defaults = NSUserDefaults.standardUserDefaults()
    private let ioQueue = dispatch_queue_create("friendsStorageQueue", DISPATCH_QUEUE_CONCURRENT);
    private let friendsKey = "friends"
    private let infoUpdatedAt = never

    private func unsafeListAll() -> [Friend] {
        var friends: [Friend]?
        if let data = self.defaults.objectForKey(self.friendsKey) as? NSData {
            let unarc = NSKeyedUnarchiver(forReadingWithData: data)
            friends = unarc.decodeObjectForKey("root") as? [Friend]
        }
        return friends ?? [Friend]()
    }

    private func unsafeSetFriends(var friends: [Friend]) {
        friends.sort(friendIsOrderedBefore)
        let encodedFriends = NSKeyedArchiver.archivedDataWithRootObject(friends)
        self.defaults.setObject(encodedFriends, forKey: self.friendsKey)
    }

    private func updateFriendsInfo(updates: [Int: FriendInfoUpdate]) {
        dispatch_barrier_sync(self.ioQueue) {
            var friends = self.unsafeListAll()

            for friend in friends {
                if let friendUpdate = updates[friend.wgId] {
                    if let updatedNickname = friendUpdate.nickname {
                        friend.nickname = updatedNickname
                    }
                    if let updatedIsFriends = friendUpdate.isFriend {
                        friend.isFriend = updatedIsFriends
                    }
                    if let updatedIsLastBattleTime = friendUpdate.lastBattleTime {
                        friend.lastBattleTime = updatedIsLastBattleTime
                    }
                }
            }

            self.unsafeSetFriends(friends)
        }
    }

    public func listAll() -> [Friend] {
        var friends: [Friend]?
        dispatch_sync(self.ioQueue) {
            friends = self.unsafeListAll()
        }

        return friends ?? [Friend]()
    }

    public func addFriend(wgId: Int, nickname: String) -> Bool {
        var newFriendAdded = false
        dispatch_barrier_sync(self.ioQueue) {
            var friends = self.unsafeListAll()
            if (friends.filter { $0.wgId == wgId }).count == 0 {
                friends.append(Friend(wgId: wgId, nickname: nickname))
                newFriendAdded = true
            }
            self.unsafeSetFriends(friends)
        }
        self.refreshFriendsInfo(force: true) {
            _ in
            // noop
        }
        return newFriendAdded
    }

    public func removeFriendAndReturnAll(wgId: Int) -> [Friend] {
        var friends: [Friend]?
        dispatch_barrier_sync(self.ioQueue) {
            friends = self.unsafeListAll().filter {
                $0.wgId != wgId
            }
            self.unsafeSetFriends(friends!)
        }
        return friends ?? [Friend]()
    }

    public func updateFriendAndReturnAll(wgId: Int, isSubscribed: Bool? = nil) -> [Friend] {
        var friends: [Friend]?
        dispatch_barrier_sync(self.ioQueue) {
            friends = self.unsafeListAll()

            for friend in friends! {
                if friend.wgId == wgId {
                    if let isSubscribed = isSubscribed {
                        friend.isSubscribed = isSubscribed
                    }
                    break
                }
            }

            self.unsafeSetFriends(friends!)
        }
        return friends ?? [Friend]()
    }

    public func refreshFriendsInfo(force: Bool = false, handler: ((error: Bool) -> Void)) {
        // we should update friends info only if needed or if forced

        // fetch friends list if we have token

        wgApi.getFriendInfoUpdates(self.listAll().map{ $0.wgId }) {
            updates in
            if let updates = updates {
                self.updateFriendsInfo(updates)
                handler(error: false)
            } else {
                handler(error: true)
            }
        }
    }
}

public let friendsManager = FriendsManager()