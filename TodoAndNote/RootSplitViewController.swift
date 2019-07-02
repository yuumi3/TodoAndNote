//
//  RootSplitViewController.swift
//  TodoAndNote
//
//  Created by Yuumi Yoshida on 2018/10/24.
//  Copyright © 2018年 Yuumi Yoshida. All rights reserved.
//

import UIKit

class RootSplitViewController: UISplitViewController {
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let drive = GoogleDrive.shared
        if !drive.isAuthorized() {
            let loginViewController = self.storyboard?.instantiateViewController(withIdentifier: "loginStoryboardID")
            if let loginViewController = loginViewController {
                self.present(loginViewController, animated: true, completion: nil)
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        preferredDisplayMode = .allVisible
    }
}
