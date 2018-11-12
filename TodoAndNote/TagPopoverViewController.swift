//
//  TagPopoverViewController.swift
//  TodoAndNote
//
//  Created by Yuumi Yoshida on 2018/11/01.
//  Copyright © 2018年 Yuumi Yoshida. All rights reserved.
//

import UIKit

class TagPopoverViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    private let tagColors = ["red", "orange", "yellow", "green", "blue", "purple", "gray", "white"]

    @IBOutlet var navigationBar: UINavigationBar!
    @IBOutlet var tagColorCollection: UICollectionView!
    
    private var orginalTagColor: String?
    var fileListCell: FileListTableCell? {
        didSet {
            if fileListCell?.tagColor == nil { fileListCell?.tagColor = "tag-white" }
            orginalTagColor = fileListCell?.tagColor
        }
    }
    
    @IBAction func pushCancelButton(_ sender: Any) {
        self.fileListCell?.tagColor = orginalTagColor
        self.dismiss(animated: true)
    }

    @IBAction func pushDoneButton(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        tagColorCollection.reloadData()
    }

    override func viewDidLoad() {
        if UIDevice.current.userInterfaceIdiom == .pad {
            self.navigationBar.frame.origin.y = 0
        }
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return tagColors.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = tagColorCollection.dequeueReusableCell(withReuseIdentifier: "tagColorCell",
                                               for: indexPath) as UICollectionViewCell
        cell.backgroundColor = UIColor(named: "tag-\(tagColors[indexPath.row])")
        if self.fileListCell?.tagColor == tagColors[indexPath.row] {
            cell.contentView.layer.borderWidth = 3
            cell.contentView.layer.borderColor = UIColor.black.cgColor
        } else {
            cell.contentView.layer.borderWidth = 0
        }
        return cell;
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.fileListCell?.tagColor = tagColors[indexPath.row]
        self.tagColorCollection.reloadData()
    }
    
}
