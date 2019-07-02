//
//  LoginViewController.swift
//  TodoAndNote
//
//  Created by Yuumi Yoshida on 2019/06/15.
//  Copyright © 2019 Yuumi Yoshida. All rights reserved.
//

import UIKit
import GoogleSignIn
import GoogleAPIClientForREST

class LoginViewController: UIViewController, GIDSignInDelegate, GIDSignInUIDelegate {
    let signInButton = GIDSignInButton()
    let drive = GoogleDrive.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupGoogleSignIn()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    private func setupGoogleSignIn() {
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().scopes = [kGTLRAuthScopeDrive]
        GIDSignIn.sharedInstance().signInSilently()
        
        signInButton.frame.origin = CGPoint(
            x: (self.view.frame.size.width - signInButton.frame.size.width) / 2.0,
            y: self.view.frame.size.height * 0.8)
        self.view.addSubview(signInButton)
    }
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if let _ = error {
            print("** auth error \(error.localizedDescription)")
            drive.setAuthorizer(nil)
            signInButton.isHidden = false
        } else {
            print("** auth success")
            drive.setAuthorizer(user.authentication.fetcherAuthorizer())
            self.dismiss(animated: true, completion: nil)
            NotificationCenter.default.post(name: .reloadEntries, object: nil)
        }
    }
}
