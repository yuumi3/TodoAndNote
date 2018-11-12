//
//  DetailViewController.swift
//  TodoAndNote
//
//  Created by Yuumi Yoshida on 2018/10/12.
//  Copyright © 2018年 Yuumi Yoshida. All rights reserved.
//

import UIKit
import WebKit

class DetailViewController: UIViewController, WKNavigationDelegate, WKScriptMessageHandler {
    @IBOutlet weak var sourceTextView: UITextView!
    @IBOutlet weak var markdownWebView: WKWebView!
    @IBOutlet weak var switchViewButton: UIBarButtonItem!
    @IBOutlet weak var clearButton: UIBarButtonItem!
    
    private let MarkdownKeys : [(title: String, text: String)] = [
        ("-[]", "- [ ] "),
        ("TAB", "   "),
        ("- list", "- \n- \n- "),
        ("1.list", "1. \n2. \n3. "),
        ("code", "```\n"),
        ("##", "## ")]

    private var originalSource: String?
    private let dropbox = Dropbox.shared
    private var keyboardHeight: CGFloat?
    
    var filePathname: String? {
        didSet { reloadDocument() }
    }

    @IBAction func pushSwitchViewButton(_ sender: Any) {
        if markdownWebView.isHidden {
            sourceTextView.endEditing(true)
            markdownWebView.isHidden = false
            sourceTextView.isHidden = true
            switchViewButton.image = UIImage(named: "edit-icon")
            updateSourceFile()
            refreshMarkedown()
        } else {
            markdownWebView.isHidden = true
            sourceTextView.isHidden = false
            switchViewButton.image = UIImage(named: "markdown-icon")
        }
    }
    
    @IBAction func pushClearButton(_ sender: Any) {
        updateSourceFile()
        sourceTextView?.text = nil
        originalSource = nil
        refreshMarkedown()
        switchViewButton.isEnabled = false
        clearButton.isEnabled = false
        self.navigationItem.title = "TodoAndNote"
     }

    override func viewDidLoad() {
        super.viewDidLoad()

        addKeyboradToolbar()
        
        sourceTextView.isHidden = true
        switchViewButton.isEnabled = false
        switchViewButton.title = "Edit"
        clearButton.isEnabled = false
        self.navigationItem.title = "TodoAndNote"

        let url = Bundle.main.url(forResource: "index", withExtension: ".html")!
        let urlRequest = URLRequest(url: url)
        markdownWebView.load(urlRequest)
        markdownWebView.configuration.userContentController.add(self, name: "changeCheckbox")

        NotificationCenter.default.addObserver(forName: .reloadDocument, object: nil, queue: OperationQueue.main, using: { notification in
            self.reloadDocument()
        })
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: OperationQueue.main, using: { notification in
            if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
                self.keyboardHeight = keyboardFrame.cgRectValue.height
                self.changeSourceTextViewHeght(-keyboardFrame.cgRectValue.height)
            }
        })
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardDidHideNotification, object: nil, queue: OperationQueue.main, using: { notification in
            if let height = self.keyboardHeight {
                self.changeSourceTextViewHeght(height)
            }
        })

    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        let param = message.body as! String
        let to_check = param.prefix(1) == "1"
        var text = NSRegularExpression.escapedPattern(for: String(param.suffix(param.count - 1)))
        if let ixNL = text.firstIndex(of: "\n") {
            text = String(text.prefix(upTo: ixNL))
        }
        let pattern = "- \\[\(to_check ? " " : "x")\\]\\s*\(text)"
        let replace = to_check ? "- [x]\(text)" : "- [ ]\(text)"
        // print(pattern, replace)
        
        let regex = try! NSRegularExpression(pattern: pattern)
        let source = sourceTextView.text ?? ""
        sourceTextView.text = regex.stringByReplacingMatches(in: source, options: [],
                                                             range: NSMakeRange(0, source.count), withTemplate: replace)
        updateSourceFile()
        refreshMarkedown()
    }

    // ------------------------------------------------------------------
    
    private func addKeyboradToolbar() {
        let keyboardToolbar = UIToolbar(frame:CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 40))
        keyboardToolbar.barStyle = .default
        keyboardToolbar.items = []
        MarkdownKeys.forEach({key in
            keyboardToolbar.items?.append(UIBarButtonItem(title: key.title, style: .plain, target: self, action: #selector(pushMarkdownKey)))
        })
        keyboardToolbar.sizeToFit()
        sourceTextView.inputAccessoryView = keyboardToolbar
    }

    @objc func pushMarkdownKey(_ button: UIBarButtonItem) {
        if let title = button.title {
            let text = MarkdownKeys.first(where: {$0.title == title})?.text ?? ""
            self.sourceTextView.insertText(text)
        }
    }

    private func reloadDocument() {
        if let path = filePathname {
            dropbox.downloadContent(pathname: path, complete: { content in
                self.sourceTextView.text = content
                self.originalSource = content
                self.refreshMarkedown()
                self.switchViewButton.isEnabled = true
                self.clearButton.isEnabled = true
                self.navigationItem.title = Entries.filenameFromPath(path)
            })
        }
    }


    private func refreshMarkedown() {
        let text = (sourceTextView.text ?? "").replacingOccurrences(of: "\n", with: "\\n").replacingOccurrences(of: "'", with: "\\'")
        let js = "var md = '" + text + "'; document.getElementById('content').innerHTML = marked(md); checkbox_callback();"
        self.markdownWebView.evaluateJavaScript(js, completionHandler: { (object, error) in
            //print(error ?? "OK")
        })
    }

    private func updateSourceFile() {
        if sourceTextView.text != originalSource && self.filePathname != nil {
            dropbox.uploadContent(pathname: self.filePathname!, content: sourceTextView.text,
                                  complete: {
                                    self.originalSource = self.sourceTextView.text
            })
        }
    }
    
    private func changeSourceTextViewHeght(_ height: CGFloat) {
        var frame = self.sourceTextView.frame
        frame.size.height += height
        self.sourceTextView.frame = frame
    }
}

