//
//  GoogleDrive.swift
//  TodoAndNote
//
//  Created by Yuumi Yoshida on 2019/06/14.
//  Copyright © 2019 Yuumi Yoshida. All rights reserved.
//

import Foundation
import GoogleSignIn
import GTMSessionFetcher
import GoogleAPIClientForREST
import GTMSessionFetcher

class GoogleDrive {

    struct FileInfo {
        let id: String
        let name: String
        let isFolder: Bool
        let parentId: String
    }

    static let shared = GoogleDrive()

    private let service = GTLRDriveService()
    private var window: UIWindow?
    public  var notesFolderId: String?


    public func setWindow(_ window: UIWindow?) {
        self.window = window
    }

    public func isAuthorized() -> Bool {
        return service.authorizer != nil
    }

    public func setAuthorizer(_ authorizer: GTMFetcherAuthorizationProtocol?) {
        service.authorizer =  authorizer
    }

    public func logout() {
        service.authorizer =  nil
        GIDSignIn.sharedInstance().signOut()
    }


    public func listRoots(_ parentIds: [String] = ["root"], completion: @escaping ([FileInfo]) -> Void) {
        let query = GTLRDriveQuery_FilesList.query()
        query.pageSize = 200
        query.fields = "files(id,name,mimeType,trashed,parents)"
        let condition = parentIds.map{"('\($0)' in parents)"}.joined(separator: " or ")
        query.q = condition + " and trashed = false"
        query.orderBy = "name"
        
        service.executeQuery(query) { (ticket, result, error) in
            print("--- list \(query.q ?? "")")
            self.checkAndErrorAlert(error)
            if let files = (result as? GTLRDrive_FileList)?.files {
                let list = files.map { e  in
                    return FileInfo(id: e.identifier!, name: e.name ?? "",
                                    isFolder: e.mimeType == "application/vnd.google-apps.folder", parentId: e.parents?.joined(separator: ",") ?? "")
                }
                completion(list)
            }
        }
    }
    
    public func listNots(completion: @escaping ([FileInfo]) -> Void) {
        listRoots() { rootList in
            let notesInfo = rootList.filter{ $0.name == "Notes"}
            if notesInfo.count == 1 {
                self.notesFolderId = notesInfo[0].id
                self.listRoots([notesInfo[0].id]) { topList in
                    let folders = topList.filter{ $0.isFolder }.map{$0.id}
                    self.listRoots(folders) {list in
                        completion([notesInfo[0]] + topList + list)
                    }
                }
            } else {
                self.errorAlert("Notes director not found")
                completion([])
            }
        }
    }

    public func createFile(_ name: String, parent: String? = nil, completion: ((String) -> Void)?) {
        let file = GTLRDrive_File()
        file.name = name
        file.mimeType = "text/plain"
        file.parents = [parent ?? "root"]

        let query = GTLRDriveQuery_FilesCreate.query(withObject: file, uploadParameters: nil)
        query.fields = "id"

        service.executeQuery(query) { (ticket, folder, error) in
            print("--- create")
            self.checkAndErrorAlert(error)
            if let id = (folder as? GTLRDrive_File)?.identifier {
                completion?(id)
                print(id)
            }
        }
    }

    public func download(_ fileID: String, completion: @escaping (String) -> Void) {
        let query = GTLRDriveQuery_FilesGet.queryForMedia(withFileId: fileID)
        service.executeQuery(query) { (ticket, file, error) in
            print("--- download")
            self.checkAndErrorAlert(error)
            if let data = (file as? GTLRDataObject)?.data {
                //print(String(data: data, encoding: .utf8)!)
                completion(String(data: data, encoding: .utf8)!)
            } else {
                completion("")
            }
        }
    }

    public func upload(_ fileID: String, content: String) {
        let file = GTLRDrive_File()

        let uploadParams = GTLRUploadParameters.init(data: content.data(using: .utf8) ?? Data(), mimeType:
            "text/plain")
        uploadParams.shouldUploadWithSingleRequest = true

        let query = GTLRDriveQuery_FilesUpdate.query(withObject: file, fileId: fileID, uploadParameters: uploadParams)
        service.executeQuery(query) { (ticket, folder, error) in
            print("--- upload")
            self.checkAndErrorAlert(error)
        }
    }

    public func delete(_ fileID: String) {
        let query = GTLRDriveQuery_FilesDelete.query(withFileId: fileID)
        service.executeQuery(query) { (ticket, nilFile, error) in
            print("--- delete")
            self.checkAndErrorAlert(error)
        }
    }


    //  -------------------------------------------------------------

    private func checkAndErrorAlert(_ error: Error?) {
        if let err = error {
            errorAlert("Error: \(err.localizedDescription)")
        }
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
