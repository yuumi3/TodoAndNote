//
//  FilesTableCell.swift
//  TodoAndNote
//
//  Created by Yuumi Yoshida on 2018/10/26.
//  Copyright © 2018年 Yuumi Yoshida. All rights reserved.
//

import UIKit

class FileListTableCell: UITableViewCell {
    @IBOutlet weak var labelText: UILabel!
    @IBOutlet weak var tagView: UIView!
    var tagColor: String! {
        didSet {
            if let color = tagColor {
                self.tagView.backgroundColor = UIColor(named: "tag-\(color)")
            } else {
                self.tagView.backgroundColor = UIColor.white
            }
        }
    }
}
