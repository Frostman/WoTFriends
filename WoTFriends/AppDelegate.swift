//
//  AppDelegate.swift
//  WoTFriends
//
//  Created by Sergey Lukjanov on 21/01/15.
//  Copyright (c) 2015 Sergey Lukjanov. All rights reserved.
//

import UIKit

import Parse
import ParseCrashReporting

import WoTFriendsKit


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) -> Bool {
        ParseCrashReporting.enable();
        Parse.setApplicationId("UGtmgRM7Tprrh7kMKBN6QnWjrlJYIWo3JILkGaBe",
            clientKey:"AYgx0iMgbMEFqLr1o1UF1eZDZw16pd6b8PWDJsJs")

        let types:UIUserNotificationType = (.Alert | .Badge | .Sound)
        let settings = UIUserNotificationSettings(forTypes: types, categories: nil)

        application.registerUserNotificationSettings(settings)
        application.registerForRemoteNotifications()

        return true
    }

    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        let installation = PFInstallation.currentInstallation()
        installation.setDeviceTokenFromData(deviceToken)
        installation.channels = friendsManager.listAll().filter { $0.isSubscribed }.map { "wg\($0.wgId)" }
        installation.saveInBackgroundWithBlock {
            (succeeded, error) in
            NSLog("installation saved: \(succeeded); channels: \(installation.channels)")
        }
    }

    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        NSLog("Failed to register for remote notifications:  \(error)")
    }

    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        PFPush.handlePush(userInfo)
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

