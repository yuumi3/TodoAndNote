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
    private var activityIndicatorView = UIActivityIndicatorView()

    private let MarkdownKeys : [(title: String, text: String)] = [
        ("-[]", "- [ ] "),
        ("TAB", "   "),
        ("- list", "- \n- \n- "),
        ("1.list", "1. \n2. \n3. "),
        ("code", "```\n"),
        ("##", "## ")]

    private var originalSource: String?
    private var entries = Entries.shared
    
    var fileId: String?

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
        if !markdownWebView.isHidden && markdownWebView.canGoBack {
             markdownWebView.goBack()
        } else {
            updateSourceFile()
            sourceTextView?.text = nil
            originalSource = nil
            refreshMarkedown()
            switchViewButton.isEnabled = false
            clearButton.isEnabled = false
            self.navigationItem.title = "TodoAndNote"
        }
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
        markdownWebView.configuration.userContentController.add(self, name: "printLog")

        activityIndicatorView.style = .whiteLarge
        activityIndicatorView.color = .black
        self.navigationController?.view.addSubview(activityIndicatorView)

        NotificationCenter.default.addObserver(forName: .reloadDocument, object: nil, queue: OperationQueue.main, using: { notification in
            if let path = notification.object {
                self.fileId = path as? String
                self.reloadDocument()
            }
        })
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        activityIndicatorView.center = view.center
        reloadDocument()
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError: Error) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        switch message.name {
        case "printLog":
            print("--JS: \(message.body as! String)")
        case "changeCheckbox":
            let param = message.body as! Int
            let postion = param / 10
            let checked = (param % 10) == 1
            // print("-- \(postion) : \(checked)")
            var source = sourceTextView.text ?? ""
            let regexp = try! NSRegularExpression(pattern: "- \\[.\\] ")
            let matches = regexp.matches(in: source, range: NSMakeRange(0, source.count))
            if matches.count >= postion {
                let range = matches[postion - 1].range
                let startIx = source.index(source.startIndex, offsetBy: range.lowerBound)
                let endIx   = source.index(source.startIndex, offsetBy: range.upperBound)
                source.replaceSubrange(startIx..<endIx, with: checked ? "- [x] " : "- [ ] ")

                sourceTextView.text = source
                updateSourceFile()
                refreshMarkedown()
            }
        default:
            print("Error message \(message.name) on userContentController")
        }
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
        if let fileId = self.fileId {
            self.activityIndicatorView.startAnimating()
            self.entries.read(fileId: fileId) { source in
                self.originalSource = source
                self.sourceTextView.text = source
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.refreshMarkedown()
                    self.activityIndicatorView.stopAnimating()
                }
                self.switchViewButton.isEnabled = true
                self.clearButton.isEnabled = true
                self.navigationItem.title = self.entries.getTitle(fileId: fileId)
            }
        }
    }


    private func refreshMarkedown() {
        let text = (self.originalSource ?? "").replacingOccurrences(of: "\n", with: "\\n").replacingOccurrences(of: "'", with: "\\'")
        let js = "var md = '" + text + "'; document.getElementById('content').innerHTML = marked(md, {renderer: rendererEx}); checkbox_callback();"
        self.markdownWebView.evaluateJavaScript(js, completionHandler: { (object, error) in
            print(error ?? "OK")
        })
    }

    private func updateSourceFile() {
        if sourceTextView.text != originalSource && self.fileId != nil {
            self.entries.write(fileId: self.fileId!, content: sourceTextView.text)
            self.originalSource = self.sourceTextView.text
        }
    }
}

