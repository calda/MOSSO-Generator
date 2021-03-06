//
//  ViewController.swift
//  MOSSO
//
//  Created by DFA Film 9: K-9 on 12/9/14.
//  Copyright (c) 2014 Dog Pound Productions. All rights reserved.
//

import Cocoa
import AVKit
import AVFoundation
import AppKit
import Quartz

class ViewController: NSViewController {

    struct Static {
        static var needsMultiplePasses = false
    }
    
    let fileManager = NSFileManager.defaultManager()
    let editor = AVMutableVideoComposition()
    @IBOutlet weak var outputText: NSTextField!
    @IBOutlet weak var progressBar: NSProgressIndicator!
    let backgroundQueue = dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)
    var exporter : AVAssetExportSession = AVAssetExportSession()
    @IBOutlet weak var icon: NSImageView!
    
    var showOpenOverride : AVAsset?
    var overrideSetting : OverrideSetting = .Random40Cuts
    
    enum OverrideSetting {
        case Random40Cuts, Random40Consecutive, First40, All, None
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    
    override func viewDidDisappear() {
        NSApplication.sharedApplication().terminate(self)
    }
    
    
    @IBAction func generateButtonClicked(sender: NSButton) {
        let dirs : [String]? = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .AllDomainsMask, true) as? [String]
        let path = dirs![0].stringByAppendingPathComponent("/MOSSO")
        if !fileManager.fileExistsAtPath(path, isDirectory: nil) {
            showMessage("Folder not found (Documents/MOSSO)")
            return
        }
        sender.enabled = false
        sender.stringValue = "Generating clip queue..."
        sender.animator().alphaValue = 0
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 1.0
            sender.animator().alphaValue = 0
        }, completionHandler: nil)
        dispatch_async(backgroundQueue, {
            self.generateVideo()
        })
    }
    
    
    func generateVideo() {
        //delete previous file
        let desktopPath = NSSearchPathForDirectoriesInDomains(.DesktopDirectory, .UserDomainMask, true)[0] as! String
        let fileURL = NSURL.fileURLWithPath(desktopPath.stringByAppendingPathComponent("/Generated MOSSO.mov"))
        var error:NSError?
        NSFileManager.defaultManager().removeItemAtPath(fileURL!.path!, error: &error)
        
        //generate new file
        let (titleClipOpt, titleStartTime, clipQueue) = generateClipQueue()
        let mixComposition = AVMutableComposition()
        var nextClipStart = kCMTimeZero
        var layerInstructions : [AVMutableVideoCompositionLayerInstruction] = []
        var mixLength : CMTime = kCMTimeZero
        
        if let titleClip = titleClipOpt {
            let titleTrack = mixComposition.addMutableTrackWithMediaType(AVMediaTypeVideo, preferredTrackID: 1)
            let instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: titleTrack)
            instruction.setOpacity(1.0, atTime: titleStartTime)
            layerInstructions.append(instruction)
            titleTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, titleClip.duration), ofTrack: titleClip.tracksWithMediaType(AVMediaTypeVideo)[0] as! AVAssetTrack, atTime: titleStartTime, error: nil)
        }
        
        for queuedAsset in clipQueue {
            let isFirstClip = (queuedAsset == clipQueue.first!)
            let isLastClip = (queuedAsset == clipQueue.last!)
            
            let queueClip = MSClip(asset: queuedAsset, startTime: nextClipStart, fadeIn: !isLastClip && !isFirstClip, includeSound: isFirstClip || isLastClip)
            nextClipStart = queueClip.nextClipStart
            
            if isLastClip {
                let timeRanges = getShowOpenTimeRanges(queueClip)
                let layerInstruction = queueClip.buildInstruction(composition: mixComposition, selectedTimeRange: timeRanges, hideClip: overrideSetting == .None)
                layerInstructions.append(layerInstruction)
            } else {
                let layerInstruction = queueClip.buildInstruction(mixComposition)
                layerInstructions.append(layerInstruction)
            }
            
            
            if isLastClip {
                mixLength = queueClip.fadeOutEnd
            }
        }
        
        
        var flavorTexts = [
            "Evaluating shot composition",
            "Color correcting footage",
            "Recording a new Show Open song",
            "Entering file into Media Festival",
            "Decrypting ancient SD video codecs",
            "Searching for clips",
            "Shushing students",
            "Finding nirvana",
            "Watching grass grow",
            "Watching paint dry",
            "Thanks for waiting",
            "You're in AV2 aren't you?",
            "Sending Toto back to Oz",
            "Generating amusing loading text",
            "Discovering the meaning of silence",
            "Evolving the most serene plant known to man",
            "Creating a better MOSSO than Hennessy ever could",
            "MOSSO escaping from Alcatraz",
            "Raising a child and naming it MOSSO",
            "Conforming to intergalactic broadcast standards",
            "Sending video drones to record last minute clips",
            "Dividing by zero",
            "Subtracting points from show grade",
            "Giving the gift of life (Roxanne)",
            "Toto does lunch AND credits",
            "Retreiving lunch menu from Mrs. Winstead",
            "This will only take a Moment",
            "Misspelling someting",
            "Your paitience is underappreciated probably",
            "Laughing at my own jokes",
            "Splicing Serenity gene into plant DNA",
            "Mowing the senior grass",
            "Trimming our hedges",
            "Making Mr. Cowins clean the courtyard",
            "Replacing Hennessy with a new teacher",
            "Making everyone watch the show",
            "Developing MOSSO Generator 2.0",
            "Making a show better than local news",
            "Broadcasting onto WJBF",
            "Hacking News Channel 6",
            "Electing Hennessy Supreme Commander of something",
            "Force quitting MOSSO Generator",
            "Initiating kernel panic",
            "Using all 200% of the processor",
            "Overclocking Camera 2",
            "Upgrading internal TV network to 4K",
            "10110001101001001001010010011011100",
            "Making up technical jargon",
            "Filing $150,000 purchase order",
            "Requesting that Apple make MOSSO Generator a bundled app on OS X",
            "Releasing OS XI: Hennessy",
            "Waiting in line to buy Windows 95",
            "Upgrading to Snow Leopard",
            "Installing Windows Vista in boot camp",
            "Renaming WDFA to HENN",
            "Building a new studio",
            "Doing everything except actually generating a MOSSO",
            "Reusing old jokes",
            "Replacing Show Open with Basketweave",
            "Dragging every application to Dock",
            "Launching Final Cut so you can generate it yourself",
            "Replacing iMacs with Microsoft Surface Pros",
            "Rerouting train tracks through studio",
            "Preparing intercom interruption",
            "Prerecording the show",
            "Broadcasting yesterday's show. Hopefully nobody will notice",
            "Generating the same thing as yesterday",
            "<flavor text 384.txt> not found",
            "Using effect 615",
            "Inverting colors",
            "You better be laughing at this",
            "Using a natural language generator to make more funny jokes",
            "Constructing loft in editing room",
            "Winning media festival",
            "I'm cooler than Producer Buddy",
            "There's profanity in here somewhere",
            "...",
            "MOSSO Generator is typing",
            "Telling another useless story",
            "MOSSO Generator: Funny jokes since 2015",
            "Generating a new Cohost",
            "Inventing world news",
            "Reading announcements",
            "Brainwashing the herd--erm.. students",
            "Take notes",
            "There will be a test",
            "Generating new dog names",
            "Building the next-gen iMac",
            "Reading announcements",
            "Writing fake announements",
            "Producing a 1-hour special",
            "Generating an 8 minute MOSSO",
            "Do you really trust me with your show grade?",
            "Setting show grade to -34",
            "Sabotaging something",
            "Your lucky numbers are 4 8 15 16 23 42",
            "github.com/calda/MOSSO-Generator",
            "Announcing Final Cut Pro 11",
            "Replacing Final Cut with Windows Movie Maker",
            "Deleting system32",
            "Creating the next hit meme",
            "Inverting colors",
            "Applying Sepia filter",
            "Applying gaussian blur",
            "Raising dB above -12",
            "Loading Hennessy Memes",
            "Greetings from March 2015",
            "Carl Stepens Here",
            "Ayy Lmao"
        ]
        
        for _ in 0...10 { //shuffle
            flavorTexts.sort { (_,_) in arc4random() < arc4random() }
        }
        
        for i in 0...(flavorTexts.count - 1) {
            delay(Double(i * 3)) {
                if self.exporter.progress == 1.0 { return }
                self.showMessage("\(flavorTexts[i])")
            }
            delay(Double(i * 3) + 0.3) {
                if self.exporter.progress == 1.0 { return }
                self.showMessage("\(flavorTexts[i]).")
            }
            delay(Double(i * 3) + 0.6) {
                if self.exporter.progress == 1.0 { return }
                self.showMessage("\(flavorTexts[i])..")
            }
            delay(Double(i * 3) + 0.9) {
                if self.exporter.progress == 1.0 { return }
                self.showMessage("\(flavorTexts[i])...")
            }
        }
        
        let mainInstruction = AVMutableVideoCompositionInstruction()
        mainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeAdd(mixLength, CMTimeMake(10,1)))
        mainInstruction.layerInstructions = layerInstructions
        
        let mainCompositionInst = AVMutableVideoComposition(propertiesOfAsset: mixComposition)
        mainCompositionInst.instructions = [mainInstruction]
        mainCompositionInst.frameDuration = CMTimeMake(1, 30)
        mainCompositionInst.renderSize = CGSizeMake(1280, 720)
        
        exporter = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPreset1280x720)
        exporter.outputURL = fileURL
        exporter.videoComposition = mainCompositionInst
        exporter.outputFileType = AVFileTypeQuickTimeMovie
        exporter.canPerformMultiplePassesOverSourceMediaData = ViewController.Static.needsMultiplePasses
        exporter.exportAsynchronouslyWithCompletionHandler({
            dispatch_async(dispatch_get_main_queue(), {
                self.showMessage("Export Complete. Opening MOSSO...")
                self.delay(2) {
                    while !self.fileManager.fileExistsAtPath(fileURL!.path!) { }
                    NSWorkspace.sharedWorkspace().openFile(fileURL!.path!)
                    NSApplication.sharedApplication().terminate(self)
                }
            })
        })
        updateProgress()
    }
    
    func updateProgress() {
        self.progressBar.doubleValue = Double(self.exporter.progress)
        self.progressBar.indeterminate = self.exporter.progress > 0.99
        self.progressBar.setNeedsDisplayInRect(self.progressBar.frame)
        self.icon.alphaValue = CGFloat(0.1 + (self.exporter.progress * 0.9))
        delay(0.1) {
            self.updateProgress()
        }
        
    }
    
    
    func generateClipQueue() -> (titleClip: AVAsset?, titleStart: CMTime, queue: [AVAsset]) {
        var clips : [String] = []
        
        //get all clips from folder
        let dirs : [String]? = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .AllDomainsMask, true) as? [String]
        let path = dirs![0].stringByAppendingPathComponent("/MOSSO")
        if let enumerator = fileManager.enumeratorAtPath(path) {
            while let file = enumerator.nextObject() as? String {
                if file.hasSuffix(".mov") && !(file as NSString).containsString("REQUIRED") && !(file as NSString).containsString("SHOW OPEN") {
                    clips.append(path + "/" + file)
                }
            }
        }
        
        if clips.count == 0 {
            let pathLength = path.pathComponents.count
            let pathDisplay = "\(path.pathComponents[pathLength - 2])/\(path.pathComponents[pathLength - 1])"
            showMessage("No clips in folder (\(pathDisplay))")
        }
        
        //create Clip Queue that adds up to 32s (<37s)
        var clipQueue : [AVAsset] = []
        var currentDuration : CMTime = kCMTimeZero
        
        while currentDuration < CMTimeMake(32,1) {
            let clipIndex = Int(random(min: 0, max: CGFloat(clips.count - 1)))
            let clipPath = clips[clipIndex]
            let clipAsset = AVAsset.assetWithURL(NSURL(fileURLWithPath: clipPath)) as! AVAsset
            let possibleNewDuration = CMTimeAdd(currentDuration, clipAsset.duration)
            if possibleNewDuration < CMTimeMake(37, 1) { //will not go over 37s
                clipQueue.append(clipAsset)
                currentDuration = possibleNewDuration
            }
            clips.removeAtIndex(clipIndex)
            if possibleNewDuration > CMTimeMake(32, 1) || clips.count == 0 { //video is 32s or out of clips
                break;
            }
        }
        
        let requiredPath = path.stringByAppendingPathComponent("/ REQUIRED")
        let countdownPath = requiredPath.stringByAppendingPathComponent("/COUNTDOWN.mov")
        var countdownLength = kCMTimeZero
        if let countdownAsset = AVAsset.assetWithURL(NSURL(fileURLWithPath: countdownPath)) as? AVAsset {
            clipQueue.insert(countdownAsset, atIndex: 0)
            countdownLength = countdownAsset.duration
        }
        
        if let showOpen = chooseShowOpen(path.stringByAppendingPathComponent("/ SHOW OPEN")) {
            clipQueue.append(showOpen)
        } else {
            error("SHOW OPEN NOT FOUND.")
        }
        
        let titlePath = requiredPath.stringByAppendingPathComponent("/TEXT WITH ALPHA.mov")
        let titleClip = AVAsset.assetWithURL(NSURL(fileURLWithPath: titlePath)) as? AVAsset
        
        return (titleClip, countdownLength, clipQueue)
    }
    
    
    func chooseShowOpen(showOpenFolder: String) -> AVAsset? {
        if let override = showOpenOverride {
            let duration = CGFloat(CMTimeGetSeconds(override.duration))
            return override
        }
        var showOpens : [(path: String, lots: Int)] = []
        if let enumerator = fileManager.enumeratorAtPath(showOpenFolder) {
            while let file = enumerator.nextObject() as? String {
                if file.hasSuffix(".mov") {
                    showOpens.append(path: file, lots: 1)
                }
            }
        }
        //load lots
        var totalLotCount = 0
        for i in 0...showOpens.count - 1 {
            let path : String = showOpens[i].path
            let nsPath = path as NSString
            let noEnding = nsPath.substringToIndex(nsPath.length - 4)
            let splits = split(noEnding){ $0 == " " }
            if let lotCount = splits[splits.count - 1].toInt() {
                showOpens[i].lots = lotCount
                totalLotCount += lotCount
            } else {
                totalLotCount += 1
            }
        }
        var lotRanges : [(low: Int, path: String)] = []
        var previousLow : Int = 0
        for (path, lots) in showOpens {
            lotRanges.append(low: previousLow + 0, path: path)
            previousLow += lots
        }
        let selectedLot = Int(random(min: 1, max: CGFloat(previousLow)))
        for i in 0...lotRanges.count - 1 {
            let low = lotRanges[i].low
            let high = (i == lotRanges.count - 1 ? previousLow : lotRanges[i + 1].low)
            if selectedLot > low && selectedLot <= high {
                //we have a winner
                let selectedPath = showOpenFolder.stringByAppendingPathComponent(lotRanges[i].path)
                return AVAsset.assetWithURL(NSURL(fileURLWithPath: selectedPath)) as? AVAsset
            }
        }
        return nil
    }
    
    
    func getShowOpenTimeRanges(clip: MSClip) -> [CMTimeRange] {
        if showOpenOverride != nil && showOpenOverride! == clip.asset {
            let duration = CGFloat(CMTimeGetSeconds(clip.asset.duration))
            if duration >= 40 {
                if overrideSetting == .First40 {
                    return [CMTimeRangeMake(kCMTimeZero, CMTimeMake(40, 1))]
                } else if overrideSetting == .Random40Consecutive {
                    return [createRandomRange(assetDuration: duration, rangeDuration: 40.0)]
                } else if overrideSetting == .Random40Cuts {
                    let cut1 = createRandomRange(assetDuration: duration, rangeDuration: 10.0)
                    let cut2 = createRandomRange(assetDuration: duration, rangeDuration: 10.0)
                    let cut3 = createRandomRange(assetDuration: duration, rangeDuration: 20.0)
                    return [cut1, cut2, cut3]
                }
                // overrideSetting == .All is the default (below)
            }
        }
        return [CMTimeRangeMake(kCMTimeZero, clip.asset.duration)]
    }
    
    
    func createRandomRange(#assetDuration: CGFloat, rangeDuration: CGFloat) -> CMTimeRange {
        let quartile1 = assetDuration * 0.25
        let quartile3 = assetDuration * 0.75
        let randomTime = random(min: quartile1, max: quartile3)
        let startTime = CMTimeMakeWithSeconds(Float64(randomTime), 9999)
        return CMTimeRangeMake(startTime, CMTimeMakeWithSeconds(Float64(rangeDuration), 9999))
    }
    
    
    func showMessage(message : String){
        dispatch_async(dispatch_get_main_queue(), {
            self.outputText.stringValue = message
        })
    }
    
    
    func error(error : String){
        showMessage("CRITIAL ERROR:::\(error)")
    }

    
    func random(#min: CGFloat, max: CGFloat) -> CGFloat {
        return CGFloat(Float(arc4random()) / 0xFFFFFFFF) * (max - min) + min
    }

    func delay(delay:Double, closure:()->()) {
        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC)))
        dispatch_after(time, dispatch_get_main_queue(), closure)
    }
    
    override func prepareForSegue(segue: NSStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showOverrides" {
            if let window = segue.destinationController as? NSWindowController {
                if let override = window.contentViewController as? OverrideVideoController {
                    override.mosso = self
                }
            }
        }
    }
    
}

