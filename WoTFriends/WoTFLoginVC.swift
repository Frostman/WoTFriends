//
//  WoTFLoginVC.swift
//  WoTFriends
//
//  Created by Sergey Lukjanov on 26/01/15.
//  Copyright (c) 2015 Sergey Lukjanov. All rights reserved.
//

import UIKit

import WoTFriendsKit


class WoTFLoginVC: UIViewController, UIWebViewDelegate {

    @IBOutlet weak var web: UIWebView!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.web?.delegate = self
    }

    override func viewDidAppear(animated: Bool) {
        let req = NSURLRequest(URL: NSURL(string: wgApi.authUrl)!)
        self.web?.loadRequest(req)
    }

    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if request.URL.host == wgApi.authRedirectHost {
            var paramsDict = [String: String]()
            let params = split(request.URL.query!, {$0 == "&"}, allowEmptySlices: false)
            for param in params {
                let keyVal = split(param, {$0 == "="})
                paramsDict[keyVal[0]] = keyVal[1]
            }
            // [expires_at: 1422913985, access_token: blabla, status: ok, nickname: Frostman, account_id: 31675]

            self.web?.stopLoading()
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            self.navigationController?.popToRootViewControllerAnimated(true)
            return false
        }
        return true
    }

    func webViewDidStartLoad(webView: UIWebView) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
    }

    func webViewDidFinishLoad(webView: UIWebView) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
    }
}

