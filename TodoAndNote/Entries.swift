//
//  Entries.swift
//  TodoAndNote
//
//  Created by Yuumi Yoshida on 2018/10/12.
//  Copyright © 2018年 Yuumi Yoshida. All rights reserved.
//

import Foundation
import SwiftyDropbox


class Entries {
    private static let PREFIX_ITEM = "Notes"
    static let PREFIX = "/" + PREFIX_ITEM
    static let PREFIX_DIR = PREFIX.lowercased() + "/"
    static let ATTRIBUTES_FILE = PREFIX_DIR + ".attributes.json"
    static let BACKUP_DIR = PREFIX_DIR + "zBackup"

    private var entries: [Files.Metadata] = []
    private(set) var folders: [String] = [""]
    private(set) var files: [[String]] = [[]]
    private(set) var attributes: [[[String:String]]] = [[]]

    init(entries: [Files.Metadata], attributeJson: String) {
        self.entries = entries
        for entry in entries {
            if let folder = (entry as? Files.FolderMetadata) {
                let path = folder.pathLower!
                if path.hasPrefix(Entries.PREFIX_DIR) {
                    folders.append(folder.name)
                    files.append([])
                    attributes.append([])
                 }
            }
        }
        folders.sort()

        for entry in entries {
            if let file = (entry as? Files.FileMetadata){
                let path = file.pathLower!
                if Entries.isMarkdown(file.name) {
                    files[findFolder(path)].append(file.name)
                    attributes[findFolder(path)].append([:])
                }
            }
        }
        for i in 0..<folders.count { files[i].sort() }
        
        decodeAttributesJson(attributeJson)
        //print(encodeAttributesJson())
    }
    
    init() {
    }
    
    func pathname(folderNo: Int, filename: String, addExtention: String? = nil) -> String {
        let secondFolder = folderNo == 0 ? "" :  folders[folderNo] + "/"
        let ext = addExtention == nil ? "" : (filename.contains(".") ? "" : addExtention!)
        return Entries.PREFIX + "/" + secondFolder + filename + ext
    }

    func pathname(folderNo: Int, fileNo: Int) -> String {
        return pathname(folderNo: folderNo, filename: files[folderNo][fileNo])
    }

    func backupPathname(folderNo: Int, fileNo: Int) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        let today = dateFormatter.string(from: Date())

        return Entries.BACKUP_DIR + "/" + today + "_" + files[folderNo][fileNo]
    }

    func index(byPathname: String) -> (folderNo:Int, fileNo:Int)? {
        var items = byPathname.split(separator: "/")
        if items.count > 0 && items[0] == Entries.PREFIX_ITEM { items.remove(at: 0) }

        if items.count == 1 {
            if let fileNo = files[0].firstIndex(of: String(items[0])) {
                return (0, fileNo)
            }
        } else if items.count == 2 {
            if let folderNo = folders.firstIndex(of: String(items[0])) {
                if let fileNo = files[folderNo].firstIndex(of: String(items[1])) {
                    return (folderNo, fileNo)
                }
            }
        }
       return nil
     }

    func clear() {
        folders = []
        files = [[]]
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

    static func filenameFromPath(_ path: String) -> String {
        let items = path.split(separator: "/")
        return removeExtension(String(items.last ?? ""))
    }

    static func isMarkdown(_ path: String) -> Bool {
        return path.hasSuffix(".md")
    }
    
    static func removeExtension(_ path: String) -> String {
        return isMarkdown(path) ? String(path.prefix(path.count - 3)) : path
   }

    var dump :  String {
        return "folder: \(folders)\nfiles: \(files)"
    }
    
    // --------------------------------
    
    
    private func findFolder(_ path: String) -> Int {
        for i in (1..<folders.count) {
            if path.hasPrefix(Entries.PREFIX_DIR + folders[i].lowercased()) {
                return i
            }
        }
        return 0
    }
    
    // ---------------------------
    struct FileAttribute: Codable {
        let path: String
        let color: String
    }

    private func decodeAttributesJson(_ jsonString: String) {
        let data = jsonString.data(using: .utf8) ?? Data()
        let fileAttributes = try! JSONDecoder().decode([FileAttribute].self, from: data)

        fileAttributes.forEach { attr in
            if let indices = index(byPathname: attr.path) {
                self.attributes[indices.folderNo][indices.fileNo] = ["color": attr.color]
            }
        }
    }
    
    func encodeAttributesJson() -> String {
        var attrs: [FileAttribute] = []
        for folderNo in 0..<folders.count {
            for fileNo in 0..<files[folderNo].count {
                if let color = self.attributes[folderNo][fileNo]["color"] {
                   attrs.append(FileAttribute(path: self.pathname(folderNo: folderNo, fileNo: fileNo), color: color))
                }
            }
        }
        
        let data = try! JSONEncoder().encode(attrs)
        return String(data: data, encoding: .utf8) ?? ""
    }
}
