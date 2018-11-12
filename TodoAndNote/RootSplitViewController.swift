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
        Dropbox.shared.authorize(controller: self, logined: {
            NotificationCenter.default.post(name: .reloadEntries, object: nil)
        })
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        preferredDisplayMode = .allVisible
    }
}
