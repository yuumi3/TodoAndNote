//
//  AddPopoverViewController.swift
//  TodoAndNote
//
//  Created by Yuumi Yoshida on 2018/10/23.
//  Copyright © 2018年 Yuumi Yoshida. All rights reserved.
//


import UIKit

class AddPopoverViewController: UITableViewController {
    var entries = Entries()
    var filePathname: String?
    private var folderIndex: Int?
    private var filename: String?

    @IBOutlet weak var doneButtonItem: UIBarButtonItem!
    
    @IBAction func pushCancelButton(_ sender: Any) {
        self.dismiss(animated: true)
    }

    @objc func changeFilenameText(_ textField: UITextField) {
        filename = textField.text
        checkInputDone()
     }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let ix = folderIndex, let name = filename {
            filePathname = entries.pathname(folderNo: ix, filename: name, addExtention: ".md")
        }
   }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? " " : "Folders"
    }

    override  func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 0 ? 10 : 40
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? 1 : entries.folders.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "FileNameCell", for: indexPath) as! TextFieldTableCell
            cell.textField.addTarget(self, action: #selector(changeFilenameText(_:)), for: .editingChanged)
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "FolderSelectCell", for: indexPath)
            cell.textLabel!.text = indexPath.row == 0 ? "ROOT" : entries.folders[indexPath.row]

            if let ix = self.folderIndex {
                cell.accessoryType =  ix == indexPath.row ? .checkmark : .none
            } else {
                cell.accessoryType = .none
            }
            return cell
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            self.folderIndex = indexPath.row
            self.tableView.reloadData()
            checkInputDone()
         }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        doneButtonItem.isEnabled = false
    }
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func checkInputDone() {
        if let ix = folderIndex, let name = filename {
            doneButtonItem.isEnabled = (ix >= 0 && name.count > 0)
        }
    }
}
