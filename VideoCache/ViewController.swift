//
//  ViewController.swift
//  VideoCache
//
//  Created by Chris on 2019/2/24.
//  Copyright © 2019 putao. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {

    @IBOutlet weak var playerView: UIView!
    @IBOutlet weak var progressSlider: UISlider!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var timeLabel: UILabel!
    
    var playerItem:AVPlayerItem!
    var avplayer:AVPlayer!
    var playerLayer:AVPlayerLayer!
    
    var link:CADisplayLink!
    var dragging = false
    
    let kScheme = "PUTAO://"

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        guard let url = URL(string: "\(kScheme)http://gedftnj8mkvfefuaefm.exp.bcevod.com/mda-hc2s2difdjz6c5y9/hd/mda-hc2s2difdjz6c5y9.mp4?playlist%3D%5B%22hd%22%5D&auth_key=1500559192-0-0-dcb501bf19beb0bd4e0f7ad30c380763&bcevod_channel=searchbox_feed&srchid=3ed366b1b0bf70e0&channel_id=2&d_t=2&b_v=9.1.0.0") else { fatalError("连接错误") }
        
        let avAsset = AVURLAsset(url: url)
        avAsset.resourceLoader.setDelegate(self, queue: DispatchQueue.main)
        playerItem = AVPlayerItem(asset: avAsset)
        
        // 监听缓冲进度改变
        playerItem.addObserver(self, forKeyPath: "loadedTimeRanges", options: NSKeyValueObservingOptions.new, context: nil)
        // 监听状态改变
        playerItem.addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions.new, context: nil)
        
        avplayer = AVPlayer(playerItem: playerItem)
        avplayer.automaticallyWaitsToMinimizeStalling = false
        
        playerLayer = AVPlayerLayer(player: avplayer)
        playerLayer.frame = playerView.bounds
        playerLayer.videoGravity = AVLayerVideoGravity.resizeAspect
        playerLayer.contentsScale = UIScreen.main.scale
        
        playerView.layer.insertSublayer(playerLayer, at: 0)
        
        self.link = CADisplayLink(target: self, selector: #selector(update))
        self.link.add(to: RunLoop.main, forMode: RunLoop.Mode.default)
    }
    
    deinit {
        playerItem.removeObserver(self, forKeyPath: "loadedTimeRanges")
        playerItem.removeObserver(self, forKeyPath: "status")
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let playerItem = object as? AVPlayerItem else { return }
        if keyPath == "loadedTimeRanges"{
            // 通过监听AVPlayerItem的"loadedTimeRanges"，可以实时知道当前视频的进度缓冲
            let loadedTime = avalableDurationWithplayerItem()
            let totalTime = CMTimeGetSeconds(playerItem.duration)
            let percent = loadedTime/totalTime
            print("percent: \(percent)")
        }else if keyPath == "status"{
//            print("status: \(playerItem.status.rawValue)")
            if playerItem.status == AVPlayerItem.Status.readyToPlay{
                // 只有在这个状态下才能播放
                //                self.avplayer.play()
            }else{
//                print("加载异常")
            }
        }
    }
    
    @IBAction func play(_ sender: Any) {
        if avplayer.rate == 0 { // 暂停
            avplayer.play()
            playButton.setTitle("pause", for: .normal)
        }else {
            avplayer.pause()
            playButton.setTitle("play", for: .normal)
        }
    }

    @IBAction func sliderTouchDown(_ sender: Any) {
        dragging = true
    }
    
    @IBAction func sliderTouchUp(_ sender: Any) {
        dragging = false
        //当视频状态为AVPlayerStatusReadyToPlay时才处理
        if self.avplayer.status == AVPlayer.Status.readyToPlay{
            let duration = (sender as AnyObject).value * Float(CMTimeGetSeconds(self.avplayer.currentItem!.duration))
            let seekTime = CMTimeMake(value: Int64(duration), timescale: 1)
            self.avplayer.seek(to: seekTime, completionHandler: {[weak self] (b) in
                self?.dragging = false
            })
        }
    }
    
    @objc func update(){
        //暂停的时候
        if avplayer.rate == 0 {
            return
        }
        
        let currentTime = CMTimeGetSeconds(self.avplayer.currentTime())
        let totalTime   = TimeInterval(playerItem.duration.value) / TimeInterval(playerItem.duration.timescale)
        
        
        let timeStr = "\(formatPlayTime(secounds: currentTime))/\(formatPlayTime(secounds: totalTime))"
        timeLabel.text = timeStr

        if !dragging {
            self.progressSlider.value = Float(currentTime/totalTime)
        }
    }
    
    func avalableDurationWithplayerItem()->TimeInterval{
        guard let loadedTimeRanges = avplayer?.currentItem?.loadedTimeRanges,let first = loadedTimeRanges.first else {fatalError()}
        let timeRange = first.timeRangeValue
        let startSeconds = CMTimeGetSeconds(timeRange.start)
        let durationSecound = CMTimeGetSeconds(timeRange.duration)
        let result = startSeconds + durationSecound
        return result
    }
    
    func formatPlayTime(secounds:TimeInterval)->String{
        if secounds.isNaN{
            return "00:00"
        }
        let Min = Int(secounds / 60)
        let Sec = Int(secounds.truncatingRemainder(dividingBy: 60))
        return String(format: "%02d:%02d", Min, Sec)
    }
}


extension ViewController : AVAssetResourceLoaderDelegate {
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        if let url = loadingRequest.request.url, url.absoluteString.contains(kScheme) {
            MediaDownloader.shared.requestHeaderInfo(url: url, loadingRequest: loadingRequest)
            return true
        }
        return false
    }
    
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, didCancel loadingRequest: AVAssetResourceLoadingRequest) {
        
    }
    
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForRenewalOfRequestedResource renewalRequest: AVAssetResourceRenewalRequest) -> Bool {
        return true
    }
}
