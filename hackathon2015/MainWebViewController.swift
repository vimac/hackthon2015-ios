//
//  MainWebViewController.swift
//  hackathon2015
//
//  Created by Mac on 10/24/15.
//  Copyright © 2015 Mac. All rights reserved.
//

import UIKit
import WebKit

var context = 0

class MainWebViewController: UINavigationController, WKNavigationDelegate, WKScriptMessageHandler, BMKLocationServiceDelegate {

    var webView:WKWebView? = nil
    var webConfig:WKWebViewConfiguration {
        get {
            
            // Create WKWebViewConfiguration instance
            let webCfg:WKWebViewConfiguration = WKWebViewConfiguration()
            
            // Setup WKUserContentController instance for injecting user script
            let userController:WKUserContentController = WKUserContentController()
            
            // Add a script message handler for receiving  "buttonClicked" event notifications posted from the JS document using window.webkit.messageHandlers.buttonClicked.postMessage script message
            userController.addScriptMessageHandler(self, name: "bridge")
            
//            // Get script that's to be injected into the document
//            let js:String = "alert('hello,world')"
//            
//            // Specify when and where and what user script needs to be injected into the web document
//            let userScript:WKUserScript =  WKUserScript(source: js, injectionTime: WKUserScriptInjectionTime.AtDocumentEnd, forMainFrameOnly: false)
//            
//            // Add the user script to the WKUserContentController instance
//            userController.addUserScript(userScript)
            
            // Configure the WKWebViewConfiguration instance with the WKUserContentController
            webCfg.userContentController = userController;
            
            return webCfg;
        }
    }
    
    var locationService: BMKLocationService!
    var userLocation: BMKUserLocation!
    
    var rightButton:UIBarButtonItem?
    var backButton:UIBarButtonItem?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "活动工厂"

        // Do any additional setup after loading the view.
        let webViewFrame:CGRect  = CGRectMake(0, UIApplication.sharedApplication().statusBarFrame.size.height + self.navigationBar.frame.height,
            UIScreen.mainScreen().bounds.width, UIScreen.mainScreen().bounds.height)
        
        webView = WKWebView(frame: webViewFrame, configuration: webConfig)
        let url = NSURL(string: "http://10.0.20.55:8001/index/wel")
        let request = NSURLRequest(URL: url!)
        webView!.loadRequest(request)
        webView!.navigationDelegate = self
        //webView!.navigationDelegate = self
        view.addSubview(webView!)
        self.webView?.addObserver(self, forKeyPath: "title", options: NSKeyValueObservingOptions.New, context: &context)
        
        // 设置定位精确度，默认：kCLLocationAccuracyBest
        BMKLocationService.setLocationDesiredAccuracy(kCLLocationAccuracyBest)
        //指定最小距离更新(米)，默认：kCLDistanceFilterNone
        BMKLocationService.setLocationDistanceFilter(10)
        // 定位功能初始化
        locationService = BMKLocationService()
        locationService!.delegate = self
  
        //rightButton = UIBarButtonItem(title: "扫一扫", style: UIBarButtonItemStyle.Plain, target: self, action: "enableQRScanner")
        rightButton = UIBarButtonItem(image: UIImage(named: "QR"), style: UIBarButtonItemStyle.Plain, target: self, action: "enableQRScanner")
        rightButton?.tintColor = UIColor.blackColor()
        self.navigationItem.rightBarButtonItem = rightButton
        
        backButton = UIBarButtonItem(title: "返回", style: UIBarButtonItemStyle.Plain, target: self, action: "goBack")
        backButton?.tintColor = UIColor.blackColor()
        self.navigationItem.leftBarButtonItem = backButton

    }
    
    func goBack() {
        webView?.goBack()
        if ((webView?.title?.isEmpty) != true) {
            self.title = webView?.title
        } else {
            self.title = "活动工厂"
        }
    }
    
    override func observeValueForKeyPath(keyPath: String?,
        ofObject object: AnyObject?,
        change: [String : AnyObject]?,
        context: UnsafeMutablePointer<Void>) {
        switch keyPath {
            case "title"?:
                if ((webView?.title?.isEmpty) != true) {
                    self.title = webView?.title
                } else {
                    self.title = "活动工厂"
                }
                break
            default:
                break
        }
    }
    
    func enableQRScanner() {
        let qrCameraController = QRCameraController()
        qrCameraController.completionHandler = {(result: String) -> Void in
            self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
            if (result.hasPrefix("http")) {
                let url = NSURL(string: result)
                let request = NSURLRequest(URL: url!)
                self.webView!.loadRequest(request)
            }
            //self.webView?.evaluateJavaScript("window.callback('" + method + "', '" + result + "');" , completionHandler: nil)
        }
        self.navigationController?.presentViewController(qrCameraController, animated: true, completion:{() -> () in
            qrCameraController.initCapture()
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        let method:String = message.body.valueForKey("request") as! String
        
        switch (method) {
            case "QRScanner":
                let qrCameraController = QRCameraController()
                qrCameraController.completionHandler = {(result: String) -> Void in
                    self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
                    self.navigationController?.popToRootViewControllerAnimated(true)
                    if (result.hasPrefix("http")) {
                        let url = NSURL(string: result)
                        let request = NSURLRequest(URL: url!)
                        self.webView!.loadRequest(request)
                    }
//                    self.webView?.evaluateJavaScript("window.jsBridgeCallBack('" + method + "', '" + result + "');" , completionHandler: nil)
                }
                self.navigationController?.presentViewController(qrCameraController, animated: true, completion:{() -> () in
                    qrCameraController.initCapture()
                })
                break
            case "GPS":
                locationService!.startUserLocationService()
                break
            case "Title":
                self.title = message.body.valueForKey("title") as? String
                break
            default:
                break
        }
    }
    
    // 用户位置更新后，会调用此函数
    func didUpdateBMKUserLocation(userLocation: BMKUserLocation!) {
        self.userLocation = userLocation
        print("目前位置：\(userLocation.location.coordinate.longitude), \(userLocation.location.coordinate.latitude)")
        self.webView?.evaluateJavaScript("window.jsBridgeCallBack('GPS', '\(userLocation.location.coordinate.longitude), \(userLocation.location.coordinate.latitude)');" , completionHandler: nil)
        locationService.stopUserLocationService()
    }
    
    func webView(webView: WKWebView, didCommitNavigation navigation: WKNavigation!) {
        self.title = "加载中"
    }
    
    func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
        if ((webView.title?.isEmpty) != false) {
            self.title = webView.title
        } else {
            self.title = "活动工厂"
        }
    }

}
