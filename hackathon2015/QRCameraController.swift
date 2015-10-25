//
//  ViewController.swift
//  hackathon2015
//
//  Created by Mac on 10/24/15.
//  Copyright © 2015 Mac. All rights reserved.
//

import UIKit
import AVFoundation
import WebKit

let ScreenWH = UIScreen.mainScreen().bounds

class QRCameraController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    var captureSession:AVCaptureSession? = nil
    var videoPreviewLayer:AVCaptureVideoPreviewLayer? = nil
    var qrCodeFrameView:UIView? = nil
    var messageLabel:UILabel? = nil
    let defaultCodeFrame:CGRect = CGRectMake(
                                        (ScreenWH.width - ScreenWH.width * 0.8) / 2,
                                        (ScreenWH.height - ScreenWH.width * 0.8) / 2,
                                        ScreenWH.width * 0.8,
                                        ScreenWH.width * 0.8)
    let defaultBoxFrame:CGRect = CGRectMake(128.0/ScreenWH.height, (ScreenWH.width - 280.0)/ScreenWH.width * 2.0, 280.0/ScreenWH.height, 280.0/ScreenWH.width)
    var completionHandler:((String)->Void)?
    var backButton:UIButton?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        view.backgroundColor = UIColor.blackColor()
        
        // Initialize QR Code Frame to highlight the QR code
        qrCodeFrameView = UIView()
        qrCodeFrameView?.layer.borderColor = UIColor.greenColor().CGColor
        qrCodeFrameView?.layer.borderWidth = 2
        qrCodeFrameView?.frame = defaultCodeFrame
        view.addSubview(qrCodeFrameView!)
        view.bringSubviewToFront(qrCodeFrameView!)
        
        messageLabel = UILabel()
        messageLabel?.frame = defaultCodeFrame
        messageLabel?.text = "请将扫描框对准二维码"
        messageLabel?.textColor = UIColor.greenColor()
        messageLabel?.textAlignment = NSTextAlignment.Center //UITextAlignment.Center;
        view.addSubview(messageLabel!)
        view.bringSubviewToFront(messageLabel!)

        backButton = UIButton()
        backButton?.frame = CGRectMake((ScreenWH.width - ScreenWH.width * 0.4) / 2, defaultCodeFrame.maxY + 25, ScreenWH.width * 0.4, 32)
        backButton?.setTitle("返回", forState: UIControlState.Normal)
        backButton?.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
        backButton?.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        backButton?.addTarget(self, action: "goBack", forControlEvents: UIControlEvents.TouchDown)
        view.addSubview(backButton!)
        view.bringSubviewToFront(backButton!)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        captureSession?.stopRunning()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func goBack() {
        self.dismissViewControllerAnimated(true, completion: nil)
//        self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // 初始化视频捕获
    func initCapture() {
        do {
            let captureDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
            
            let captureInput = try AVCaptureDeviceInput(device: captureDevice)
            
            // input和output的桥梁,它协调着intput到output的数据传输.(见字意,session-会话)
            captureSession = AVCaptureSession()
            captureSession!.addInput(captureInput)
            
            // 输出流
            let captureMetadataOutput = AVCaptureMetadataOutput()
            // 限制扫描区域
            captureMetadataOutput.rectOfInterest = defaultBoxFrame
            captureSession!.addOutput(captureMetadataOutput)
            // 添加的队列按规定必须是串行
            captureMetadataOutput.setMetadataObjectsDelegate(self, queue: dispatch_get_main_queue())
            // 指定信息类型,QRCode
            captureMetadataOutput.metadataObjectTypes = [AVMetadataObjectTypeQRCode]
            
            // 用这个预览图层和图像信息捕获会话(session)来显示视频
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
            videoPreviewLayer!.backgroundColor = UIColor.blackColor().CGColor
            videoPreviewLayer!.videoGravity = AVLayerVideoGravityResizeAspectFill
            videoPreviewLayer!.frame = view.bounds
            view.layer.addSublayer(videoPreviewLayer!)
            view.bringSubviewToFront(messageLabel!)
            view.bringSubviewToFront(qrCodeFrameView!)
            view.bringSubviewToFront(backButton!)

            captureSession!.startRunning()
            
        } catch {
            let errorAlert = UIAlertController(title: "提醒", message: "请在iPhone的\"设置-隐私-相机\"选项中,允许XXX访问您的相机", preferredStyle: .Alert)
            errorAlert.addAction(UIAlertAction(title: "确定", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(errorAlert, animated: true, completion: nil)
        }
    }
    

    func captureOutput(captureOutput: AVCaptureOutput!,
        didOutputMetadataObjects metadataObjects: [AnyObject]!, fromConnection
        connection: AVCaptureConnection!) {
            
            // Check if the metadataObjects array is not nil and it contains at least one object.
            if metadataObjects == nil || metadataObjects.count == 0 {
                qrCodeFrameView?.frame = defaultCodeFrame
                print("No QR code")
                return
            }
            
            // Get the metadata object.
            let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
            
            if metadataObj.type == AVMetadataObjectTypeQRCode {
                // If the found metadata is equal to the QR code metadata then update the status label's text and set the bounds
                let barCodeObject =
                videoPreviewLayer?.transformedMetadataObjectForMetadataObject(metadataObj
                    as AVMetadataMachineReadableCodeObject) as! AVMetadataMachineReadableCodeObject
                qrCodeFrameView?.frame = barCodeObject.bounds;
                
                if metadataObj.stringValue != nil {
//                    messageLabel!.text = metadataObj.stringValue
//                    print(metadataObj.stringValue)
                    completionHandler!(metadataObj.stringValue)
                    captureSession?.stopRunning()
                }
            }
    }
    

}

