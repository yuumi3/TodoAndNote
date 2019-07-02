//
//  Entries.swift
//  TodoAndNote
//
//  Created by Yuumi Yoshida on 2018/10/12.
//  Copyright © 2018年 Yuumi Yoshida. All rights reserved.
//

import Foundation


class Entries {
    private init() {}
    static let shared = Entries()
    

    static let ATTRIBUTES_FILE = ".attributes.json"
    static let BACKUP_DIR = "zBackup"
    static let MARKDOWN_EXT = ".md"

    private let drive = GoogleDrive.shared
    private(set) var folders: [String] = []
    private(set) var files: [[String]] = []
    private(set) var attributes: [[[String:String]]] = []
    private(set) var firstOpenFileId: String?
    private(set) var foldersId: [String] = []
    private(set) var filesId: [[String]] = []
    private(set) var backupFolderId:String?

    private var containerUrl: URL = URL(fileURLWithPath: "/")


    func reload(completion: @escaping () -> Void) {
        drive.listNots { list in
            self.folders = []
            self.files = []
            self.foldersId = []
            self.filesId = []

            var attrbuteFileId: String?

            list.forEach { entry in
                if entry.isFolder {
                    self.folders.append(entry.id == self.drive.notesFolderId  ? "" : entry.name)
                    self.foldersId.append(entry.id)
                    self.files.append([])
                    self.filesId.append([])
                    self.attributes.append([])
                    if entry.name == Entries.BACKUP_DIR {
                        self.backupFolderId = entry.id
                    }
                } else {
                    if entry.name == Entries.ATTRIBUTES_FILE {
                        attrbuteFileId = entry.id
                    } else {
                        let folderIx = self.foldersId.firstIndex(of: entry.parentId)!
                        self.files[folderIx].append(entry.name)
                        self.filesId[folderIx].append(entry.id)
                        self.attributes[folderIx].append([:])
                        if folderIx == 0 && entry.name == "TODO.md" {
                            self.firstOpenFileId = entry.id
                        }
                    }
                }
            }
            // print("+++ list \(self.dump)")
            if let attrId = attrbuteFileId {
                self.drive.download(attrId) {jsonString in
                    // print("+++ \(jsonString)")
                    self.decodeAttributesJson(jsonString)
                    completion()
                }
            }
        }
    }
    
    func read(fileId: String, completion: @escaping (String) -> Void) {
        drive.download(fileId) { completion($0) }
    }

    func write(fileId: String, content: String) {
        drive.upload(fileId, content: content)
    }
    
    func create(_ fileName: String, folderId: String,  completion: ((String) -> Void)? = nil) {
        drive.createFile(fileName, parent: folderId, completion: completion)
    }
    
    func createBackup(_ fileName: String,  completion: @escaping (String) -> Void) {
        guard backupFolderId != nil else { return }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        let today = dateFormatter.string(from: Date())

        drive.createFile(today + "_" + fileName, parent: backupFolderId, completion: completion)
    }
    
    func writeAttributes() {
    }

    func delete(fileId: String) {
        drive.delete(fileId)
    }

    func getTitle(fileId: String) -> String {
        for folderIx in 0...foldersId.count {
            if let fileIx = filesId[folderIx].firstIndex(of: fileId) {
                return files[folderIx][fileIx]
            }
        }
        return "???"
    }
    
    func index(folderId: String, fileId: String) -> (folderNo:Int, fileNo:Int)? {
        if let folderNo = self.foldersId.firstIndex(of: folderId) {
            if let fileNo = self.filesId[folderNo].firstIndex(of: fileId) {
                return (folderNo, fileNo)
            } else {
                return nil
            }
        } else {
            return nil
        }
    }

    func logout() {
        drive.logout()
        folders = []
        files = [[]]
        attributes = [[]]
    }
    
    func filenameWithoutExt(byIndexPath: IndexPath) -> String {
        let finename = self.files[byIndexPath.section][byIndexPath.row]
        return Entries.removeExtension(finename)
    }

    func fileColorName(byIndexPath: IndexPath) -> String? {
        let attr = self.attributes[byIndexPath.section][byIndexPath.row]
        return attr["color"]
    }
    
    func setFileColorName(atIndexPath: IndexPath, colorName: String) {
        var attr = attributes[atIndexPath.section][atIndexPath.row]
        attr["color"] = (colorName == "white") ? nil : colorName
        attributes[atIndexPath.section][atIndexPath.row] = attr
    }

    static func removeExtension(_ name: String) -> String {
        if name.hasSuffix(Entries.MARKDOWN_EXT) {
            return String(name.prefix(name.count - 3))
        } else {
            return name
        }
    }

    static func addExtension(_ name: String) -> String {
        if name.hasSuffix(Entries.MARKDOWN_EXT) {
            return name
        } else {
            return name + Entries.MARKDOWN_EXT
        }
    }
    
    var dump :  String {
        return "folder: \(folders)\nfiles: \(files)"
    }
    
    // --------------------------------
    
    
    private func findFolder(_ path: String) -> Int {
        for i in (1..<folders.count) {
            if path.hasPrefix(containerUrl.path + "/" + folders[i]) {
                return i
            }
        }
        return 0
    }
    
    // ---------------------------

    struct FileAttribute: Codable {
        let folder: String
        let file: String
        let color: String
    }

    private func decodeAttributesJson(_ jsonString: String) {
        let data = jsonString.data(using: .utf8) ?? Data()
        let fileAttributes = try? JSONDecoder().decode([FileAttribute].self, from: data)

        fileAttributes?.forEach { attr in
            let folderNo = self.folders.firstIndex(of: attr.folder)
            let fileNo = self.files[folderNo!].firstIndex(of: attr.file)

            self.attributes[folderNo!][fileNo!] = ["color": attr.color]
        }
    }
    
    func encodeAttributesJson() -> String {
        var attrs: [FileAttribute] = []
        for folderNo in 0..<folders.count {
            for fileNo in 0..<files[folderNo].count {
                if let color = self.attributes[folderNo][fileNo]["color"] {
                    attrs.append(FileAttribute(folder: folders[folderNo], file: files[folderNo][fileNo], color: color))
                }
            }
        }

        let data = try! JSONEncoder().encode(attrs)
        return String(data: data, encoding: .utf8) ?? ""
    }
    
}
