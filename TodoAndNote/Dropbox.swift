//
//  Dropbox.swift
//  TodoAndNote
//
//  Created by Yuumi Yoshida on 2018/10/12.
//  Copyright © 2018年 Yuumi Yoshida. All rights reserved.
//

import Foundation
import SwiftyDropbox

class Dropbox {
    static let shared = Dropbox()

    private init() {}
    private var window: UIWindow?
    private var loginedCallback: (() -> Void)?

    func  setup(_ window: UIWindow?) {
        self.window = window
        let dbAppKey = ((((Bundle.main.object(forInfoDictionaryKey: "CFBundleURLTypes") as! NSArray)[0] as! NSDictionary)["CFBundleURLSchemes"]) as! NSArray)[0] as! String
        let appKey = String(dbAppKey.suffix(dbAppKey.count - 3))
        DropboxClientsManager.setupWithAppKey(appKey)
    }

    func handleRedirectURL(_ url: URL) {
        if let authResult = DropboxClientsManager.handleRedirectURL(url) {
            networkActivity(false)
            switch authResult {
            case .success:
                self.loginedCallback?()
                print("Success! User is logged into Dropbox.")
            case .cancel:
                errorAlert("Authorization flow was manually canceled by user!")
            case .error(_, let description):
                errorAlert("Error: \(description)")
            }
        }
    }

    func isAuthorized() -> Bool {
        return DropboxClientsManager.authorizedClient != nil
    }

    func authorize(controller: UIViewController, logined: (() -> Void)?) {
        if DropboxClientsManager.authorizedClient != nil  { return }

        networkActivity(true)
        self.loginedCallback = logined
        DropboxClientsManager.authorizeFromController(
            UIApplication.shared,
            controller: controller,
            openURL: { (url: URL) -> Void in
                UIApplication.shared.open(url, options: [ : ], completionHandler: nil)
            }
        )
    }

    func logout() {
        DropboxClientsManager.unlinkClients()
    }

    func getAccount(complete: @escaping ((Users.FullAccount) -> Void)) {
        guard let client = DropboxClientsManager.authorizedClient else {
            errorAlert("UnAuthorized");
            return
        }
        networkActivity(true)
        client.users.getCurrentAccount().response { response, error in
            self.networkActivity(false)
            if let account = response {
                complete(account)
            } else {
                self.errorAlert(error: error?.description)
            }
        }
    }

    func getEnties(complete: @escaping (([Files.Metadata]) -> Void)) {
        guard let client = DropboxClientsManager.authorizedClient else {
            errorAlert("UnAuthorized");
            return
        }
        networkActivity(true)
        client.files.listFolder(path: Entries.PREFIX, recursive: true).response { response, error in
            self.networkActivity(false)
            if let metadata = response {
                complete(metadata.entries)
             } else {
                self.errorAlert(error: error?.description)
            }
        }
    }

    func downloadContent(pathname: String, complete: @escaping ((String) -> Void)) {
        guard let client = DropboxClientsManager.authorizedClient else {
            errorAlert("UnAuthorized");
            return
        }
        networkActivity(true)
        client.files.download(path: pathname).response { response, error in
            self.networkActivity(false)
            if let response = response {
                let fileContent = String(bytes: response.1, encoding: .utf8)  ?? ""
                complete(fileContent)
            } else {
                self.errorAlert(error: error?.description)
            }
       }
    }

    func uploadContent(pathname: String, content: String, complete: @escaping (() -> Void)) {
        guard let client = DropboxClientsManager.authorizedClient else {
            errorAlert("UnAuthorized");
            return
        }
        networkActivity(true)
        let data = content.data(using: String.Encoding.utf8, allowLossyConversion: false)!
        client.files.upload(path: pathname, mode: .overwrite, input: data).response { response, error in
            self.networkActivity(false)
            if response != nil {
               complete()
            } else {
                self.errorAlert(error: error?.description)
            }
        }
    }

    func deleteFile(pathname: String, complete: @escaping (() -> Void)) {
        guard let client = DropboxClientsManager.authorizedClient else {
            errorAlert("UnAuthorized");
            return
        }
        networkActivity(true)
        client.files.deleteV2(path: pathname).response { response, error in
            self.networkActivity(false)
            if response != nil {
                complete()
            } else {
                self.errorAlert(error: error?.description)
            }
        }
    }

    //  -------------------------------------------------------------

    private func errorAlert(error: String?) {
        errorAlert("Error: \(error?.description ?? "????" )")
    }

    private func errorAlert(_ message: String) {
        print("** Error: \(message)")
        let alert = UIAlertController(title: "エラー", message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.window?.rootViewController?.present(alert, animated: true, completion: nil)
    }

    private func networkActivity(_ active: Bool) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = active
    }

}
