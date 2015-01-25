//
//  WoTFriendsKitTests.swift
//  WoTFriendsKitTests
//
//  Created by Sergey Lukjanov on 22/01/15.
//  Copyright (c) 2015 Sergey Lukjanov. All rights reserved.
//

import UIKit
import XCTest

import WoTFriendsKit


class WoTFriendsKitTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // noop
    }
    
    override func tearDown() {
        // noop
        super.tearDown()
    }
    
    func testWgApiSearchPlayers() {
        let expectation = expectationWithDescription("WoTFriendsKit.WargamingApi.searchPlayers")

        wgApi.searchPlayers("Frostman") {
            results in
            XCTAssertTrue(results.count >= 1)
            XCTAssertEqual(results[0].wgId, 31675)
            XCTAssertEqual(results[0].nickname, "Frostman")
            
            expectation.fulfill()
        }

        waitForExpectationsWithTimeout(10) { (error) in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testFriendsManagerRefreshInfo() {
        let expectation = expectationWithDescription("WoTFriendsKit.FriendsManager.refreshFriendsInfo")

        friendsManager.addFriend(31675, nickname: "Hotman")
        friendsManager.refreshFriendsInfo(force: true) {
            error in
            XCTAssertFalse(error)
            expectation.fulfill()
        }

        waitForExpectationsWithTimeout(10) { (error) in
            let friend = friendsManager.listAll()[0]
            XCTAssertEqual(friend.nickname, "Frostman")
            XCTAssertTrue(friend.lastBattleTime != never)
            XCTAssertNil(error, "\(error)")
        }
    }
}
