//
//  MasterViewController.swift
//  TodoAndNote
//
//  Created by Yuumi Yoshida on 2018/10/12.
//  Copyright © 2018年 Yuumi Yoshida. All rights reserved.
//

import UIKit

class MasterViewController: UITableViewController {

    var activityIndicatorView = UIActivityIndicatorView()
    var detailViewController: DetailViewController? = nil
    var entries = Entries()
    private let dropbox = Dropbox.shared
    private var lastIndexPath: IndexPath?

    override func viewDidLoad() {
        super.viewDidLoad()
 
         if let split = splitViewController {
            let controllers = split.viewControllers
            detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
        }
        
        NotificationCenter.default.addObserver(forName: .reloadEntries, object: nil, queue: OperationQueue.main, using: { notification in
                self.reloadEntries()
        })
        activityIndicatorView.style = .whiteLarge
        activityIndicatorView.color = .black
        self.navigationController?.view.addSubview(activityIndicatorView)
        activityIndicatorView.startAnimating()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        clearsSelectionOnViewWillAppear = splitViewController!.isCollapsed
        super.viewWillAppear(animated)
        activityIndicatorView.center = view.center
   }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        reloadEntries(complete: { self.activityIndicatorView.stopAnimating() })
    }

    @IBAction func pushMenuButton(_ sender: Any) {
        let action = UIAlertController(title: "Menu", message: nil, preferredStyle:  .actionSheet)
        action.addAction(UIAlertAction(title: "Logout", style: .default, handler: { action in
            self.logout()
        }))
        action.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in
        }))
        action.popoverPresentationController?.sourceView = self.view
        action.popoverPresentationController?.barButtonItem = sender as? UIBarButtonItem
 
        self.present(action, animated: true)
    }
    
    @IBAction func pushAddButton(_ sender: Any) {
        self.addNewFile()
    }

    @IBAction func unwindToTop(segue: UIStoryboardSegue) {
        if let popover = segue.source as? AddPopoverViewController, let pathname = popover.filePathname {
            
            print("return  \(pathname)")
            dropbox.uploadContent(pathname: pathname, content: "", complete: {
                self.reloadEntries(complete: {
                    if let indices = self.entries.index(byPathname: pathname) {
                        print(indices)
                        self.tableView.selectRow(at: IndexPath(row: indices.fileNo, section: indices.folderNo), animated: false, scrollPosition: .none)
                        self.performSegue(withIdentifier: "showDetail", sender: nil)
                    }
                })
             })
        } else if let popover = segue.source as? TagPopoverViewController, let fileListCell = popover.fileListCell,
            let indexPath = self.lastIndexPath {
            entries.setFileColorName(atIndexPath: indexPath, colorName: fileListCell.tagColor)
            self.tableView.reloadData()
            dropbox.uploadContent(pathname: Entries.ATTRIBUTES_FILE, content: entries.encodeAttributesJson(), complete: { print("-- write attr")})
        }
    }
    
    // ---------------------
    
    private func logout() {
        let alert = UIAlertController(title: "Logout", message: "Are your sure?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
            Dropbox.shared.logout()
            self.entries.clear()
            self.tableView.reloadData()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

    private func addNewFile() {
        let popover = self.storyboard!.instantiateViewController(withIdentifier: "AddPropover") as! AddPopoverViewController
        popover.entries = self.entries
        popover.modalPresentationStyle = .formSheet
        self.present(popover, animated: true)
   }
    
    private func tagEditFile(_ indexPath: IndexPath) {
        let popover = self.storyboard!.instantiateViewController(withIdentifier: "TagPropover") as! TagPopoverViewController
        popover.fileListCell = self.tableView.cellForRow(at: indexPath) as? FileListTableCell
        popover.modalPresentationStyle = .formSheet
        self.lastIndexPath = indexPath
        self.present(popover, animated: true)
    }

    private func deleteFile(_ indexPath: IndexPath) {
        let alert = UIAlertController(title: "Delete", message: "Are your sure?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
            self.dropbox.deleteFile(pathname: self.entries.pathname(folderNo: indexPath.section, fileNo: indexPath.row),
                                    complete: { self.reloadEntries() })
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
     }
    
    private func backupFile(_ indexPath: IndexPath) {
        let path = self.entries.pathname(folderNo: indexPath.section, fileNo: indexPath.row)
        let backupPtah = self.entries.backupPathname(folderNo: indexPath.section, fileNo: indexPath.row)
        self.dropbox.downloadContent(pathname: path, complete: { (content) in
            self.dropbox.uploadContent(pathname: backupPtah, content: content, complete: {
                print("backupd")
            })
        })
    }

    // MARK: - Segues

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let controller = (segue.destination as! UINavigationController).topViewController as! DetailViewController
                controller.filePathname = entries.pathname(folderNo: indexPath.section, fileNo: indexPath.row)
                controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
                controller.navigationItem.leftItemsSupplementBackButton = true
                splitViewController?.preferredDisplayMode = UIDevice.current.orientation.isLandscape ? .allVisible : .primaryHidden
            }
        }
    }

    // MARK: - Table View

    override func numberOfSections(in tableView: UITableView) -> Int {
        return entries.folders.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return entries.folders[section]
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return entries.files[section].count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FileListCell", for: indexPath) as! FileListTableCell

        cell.textLabel!.text = entries.filenameWithoutExt(byIndexPath: indexPath)
        cell.tagColor = entries.fileColorName(byIndexPath: indexPath)
        
        let accessoryButton = UIButton(type: .custom)
        accessoryButton.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        accessoryButton.tag = indexPath.section * 1000 + indexPath.row
        accessoryButton.addTarget(self, action: #selector(accessoryButtonTapped), for: .touchUpInside)
        accessoryButton.setImage(UIImage(named: "dots-icon"), for: .normal)
        accessoryButton.contentMode = .scaleAspectFit
        
        cell.accessoryView = accessoryButton
        return cell
    }

    @objc private func accessoryButtonTapped(_ sender: UIButton){
        let indexPath = IndexPath(row: sender.tag % 1000, section: sender.tag / 1000)

        let action = UIAlertController(title: nil, message: "File Operation", preferredStyle:  .actionSheet)
        action.addAction(UIAlertAction(title: "Edit Tag", style: .default, handler: { action in
            self.tagEditFile(indexPath)
        }))
        action.addAction(UIAlertAction(title: "Backup", style: .default, handler: { action in
            self.backupFile(indexPath)
        }))
        action.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { action in
            self.deleteFile(indexPath)
        }))
        action.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in
        }))
        
        action.popoverPresentationController?.sourceView = sender
        action.popoverPresentationController?.sourceRect = CGRect(x: 8, y: 0, width: 30, height: 20)
        action.popoverPresentationController?.permittedArrowDirections = .left
        self.present(action, animated: true)
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44.0
    }

    private func reloadEntries(complete: (() -> Void)? = nil) {
        if dropbox.isAuthorized() {
            self.dropbox.getEnties(complete: { entries in
                self.dropbox.downloadContent(pathname: Entries.ATTRIBUTES_FILE, complete: { attributes in
                    self.entries = Entries(entries: entries, attributeJson: attributes)
                    self.tableView.reloadData()
                    complete?()
                })
            })
        }
    }
}
