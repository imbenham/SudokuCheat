//
//  AppDelegate.swift
//  SudokuCheat
//
//  Created by Isaac Benham on 4/14/15.
//  Copyright (c) 2015 Isaac Benham. All rights reserved.
//

import UIKit
import iAd


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, ADBannerViewDelegate {

    var window: UIWindow?
    
    var banner: ADBannerView?
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        window?.frame = UIScreen.mainScreen().bounds
        
       
        
        
        let defaults = NSUserDefaults.standardUserDefaults()
        let number:Int = 0
        
        if defaults.objectForKey(symbolSetKey) == nil {
            defaults.setInteger(number, forKey: symbolSetKey)
        }
        if defaults.objectForKey(timedKey) == nil {
            defaults.setBool(false, forKey: timedKey)
        }
        dispatch_async(concurrentPuzzleQueue) {
            let operationQueue = PuzzleStore.sharedInstance.operationQueue
            let store = PuzzleStore.sharedInstance
            
            let storeInitialization = NSBlockOperation() {
                
                let keys = cachableDifficulties
                for key in keys {
                    let cacheFilePath = key.cachePath()
                    if let data = NSKeyedUnarchiver.unarchiveObjectWithFile(cacheFilePath.path!) as? [Puzzle] {
                        for puzz in data {
                            store.cachePuzzle(puzz, ofDifficulty: key)
                        }
                    }
                }
                
                let empties = store.getEmptyCaches
                for empty in empties {
                    let puzz = self.defaultPuzzleForDifficulty(empty)
                    store.cachePuzzle(puzz, ofDifficulty: empty)
                }

            }
            
            storeInitialization.completionBlock = {
                Matrix.sharedInstance
            }
            
            storeInitialization.qualityOfService = .Utility
            storeInitialization.queuePriority = .High
            
            operationQueue.addOperations([storeInitialization], waitUntilFinished: false)
        }

        return true
        
    }
    
    
    func defaultPuzzleForDifficulty(difficulty: PuzzleDifficulty) -> Puzzle {
        let puzzDict:[String:[(Int,Int,Int)]] = {
            switch difficulty {
            case .Easy:
                return ["givens":[(3,4,9), (5,4,2), (2,1,8), (8,6,4), (6,3,8), (8,9,8), (6,9,6), (1,7,3), (2,9,5), (7,2,7), (9,9,2), (8,3,9), (8,7,5), (2,3,3), (3,5,8), (4,1,1), (2,5,6), (4,5,5), (6,8,2), (7,7,9), (6,1,5), (8,8,6), (1,3,6), (2,4,1), (9,4,6), (5,1,9), (3,6,3), (5,3,7), (5,8,5), (9,3,5), (4,8,7), (5,9,3), (3,9,7), (6,5,7), (7,5,3)], "solution":[(3,1,2), (5,7,4), (1,4,5), (1,6,2), (9,7,7), (3,2,5), (5,2,6), (8,5,2), (3,8,4), (4,7,8), (8,1,3), (9,2,8), (5,6,8), (2,2,4), (1,2,9), (2,7,2), (9,5,9), (7,6,5), (7,4,8), (4,2,2), (7,1,6), (6,7,1), (6,4,4), (7,9,4), (3,7,6), (9,6,1), (1,9,1), (7,3,2), (1,1,7), (6,6,9), (4,9,9), (2,8,9), (5,5,1), (9,8,3), (4,3,4), (8,2,1), (9,1,4), (1,8,8), (1,5,4), (6,2,3), (2,6,7), (7,8,1), (3,3,1), (4,6,6), (8,4,7), (4,4,3)]]
            case .Medium:
                return ["givens":[(5,2,2), (7,6,7), (5,9,5), (1,4,1), (1,2,7), (2,9,1), (4,1,3), (3,6,4), (9,5,8), (8,3,4), (2,6,9), (7,3,9), (3,3,5), (4,7,2), (8,4,6), (7,9,6), (4,4,8), (9,2,5), (4,5,4), (5,8,6), (6,7,8), (9,9,3), (6,5,2), (5,5,3), (6,3,1), (6,6,6), (1,6,8), (8,9,7), (9,7,1)], "solution":[(5,1,4), (4,2,6), (5,3,8), (7,8,8), (3,7,3), (2,1,8), (1,1,6), (6,8,3), (7,5,1), (1,7,9), (2,7,6), (2,3,2), (2,8,5), (2,2,4), (3,1,9), (2,5,7), (8,6,3), (9,1,7), (9,8,9), (7,4,5), (3,4,2), (8,5,9), (4,9,9), (9,6,2), (5,6,1), (6,2,9), (4,3,7), (8,7,5), (6,1,5), (1,3,3), (1,5,5), (5,4,9), (1,9,2), (9,4,4), (4,6,5), (7,1,2), (7,2,3), (8,1,1), (8,2,8), (5,7,7), (6,4,7), (7,7,4), (2,4,3), (3,9,8), (6,9,4), (1,8,4), (3,2,1), (8,8,2), (9,3,6), (3,5,6), (3,8,7), (4,8,1)]]
            case .Hard:
                return ["givens":[(4,9,3), (3,7,9), (8,7,6), (6,3,2), (9,6,2), (2,6,4), (4,8,1), (5,1,4), (8,2,7), (7,8,3), (5,2,1), (7,4,6), (5,7,8), (7,3,9), (8,9,4), (3,4,5), (2,5,1), (2,2,5), (2,4,8), (2,9,7), (5,8,5), (1,9,6), (7,5,4), (1,8,4), (4,2,9), (9,1,3), (1,6,3)], "solution":[(1,1,8), (9,4,9), (3,5,2), (9,9,8), (4,6,5), (4,4,2), (9,7,1), (5,4,3), (7,6,7), (3,9,1), (9,2,6), (8,1,2), (3,2,4), (6,8,6), (3,3,3), (5,6,9), (6,6,1), (6,2,3), (1,4,7), (5,5,6), (4,3,8), (3,8,8), (7,7,2), (5,9,2), (7,2,8), (2,3,6), (8,4,1), (6,4,4), (9,8,7), (1,3,1), (8,8,9), (9,3,4), (4,5,7), (3,1,7), (7,1,1), (8,5,3), (6,5,8), (4,1,6), (2,7,3), (3,6,6), (1,7,5), (8,6,8), (1,2,2), (6,9,9), (7,9,5), (6,7,7), (8,3,5), (6,1,5), (9,5,5), (5,3,7), (4,7,4), (2,1,9), (2,8,2), (1,5,9)]]
            default:
                return ["givens":[(7,3,1), (8,4,8), (6,8,7), (4,6,3), (3,5,3), (5,1,7), (8,2,9), (2,6,7), (5,8,3), (3,9,7), (8,7,5), (4,7,9), (4,1,8), (1,7,2), (1,5,5), (5,5,2), (6,5,6), (4,3,2), (7,8,6), (5,4,9), (7,9,4), (2,2,1), (8,1,6), (9,2,8), (9,8,9)], "solution":[(3,1,9), (2,5,8), (7,4,3), (6,2,3), (3,7,1), (4,5,4), (4,2,6), (6,9,2), (9,1,4), (3,4,4), (7,6,5), (2,1,5), (9,3,5), (5,7,6), (1,4,1), (9,9,3), (9,5,1), (5,3,4), (2,8,4), (9,7,7), (4,9,5), (6,1,1), (4,8,1), (3,3,8), (8,8,2), (7,2,7), (1,1,3), (2,4,2), (8,9,1), (1,8,8), (4,4,7), (5,9,8), (3,8,5), (5,2,5), (1,9,6), (1,2,4), (9,6,2), (3,2,2), (8,5,7), (6,3,9), (6,4,5), (7,5,9), (1,3,7), (7,7,8), (8,3,3), (7,1,2), (2,7,3), (2,3,6), (6,6,8), (1,6,9), (5,6,1), (2,9,9), (3,6,6), (6,7,4), (9,4,6), (8,6,4)]]
            }
            
            }()
        var puzzGivens: [PuzzleCell] = []
        for tup in puzzDict["givens"]! {
            puzzGivens.append(PuzzleCell(row: tup.0, column: tup.1, value: tup.2))
        }
        var puzzSolution: [PuzzleCell] = []
        for tup in puzzDict["solution"]! {
            puzzSolution.append(PuzzleCell(row: tup.0, column: tup.1, value: tup.2))
        }
        
        let puzz = Puzzle(nonNilValues: puzzGivens)
        puzz.solution = puzzSolution
        
        return puzz
    }
    
    
    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        
        let rootView = window?.rootViewController as? UINavigationController
        
        if let puzzleController = rootView?.topViewController as? SudokuController {
            puzzleController.goToBackground()
            
        }
        
        banner = nil
        
        PuzzleStore.sharedInstance.operationQueue.cancelAllOperations()
        
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.

        let app = UIApplication.sharedApplication()
        app.beginBackgroundTaskWithExpirationHandler {
            let store = PuzzleStore.sharedInstance
            let keys = store.cachesToRefresh
            
            for key in keys {
                
                let puzzList = store.cacheForDifficulty(key)
                let cPath = key.cachePath()
                let path = cPath.path!
                
                if !NSFileManager.defaultManager().fileExistsAtPath(path) {
                    
                    do {
                        try NSFileManager.defaultManager().createDirectoryAtURL(cPath.URLByDeletingLastPathComponent!, withIntermediateDirectories: true, attributes: nil)
                    } catch {
                        return
                    }
                }
                
                NSKeyedArchiver.archiveRootObject(puzzList, toFile: path)
                
            }
            
            store.clearCaches()
        }
            
        
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
       dispatch_barrier_async(concurrentPuzzleQueue) {
            let store = PuzzleStore.sharedInstance
            let keys = cachableDifficulties
            for key in keys {
                let cacheFilePath = key.cachePath()
                if let data = NSKeyedUnarchiver.unarchiveObjectWithFile(cacheFilePath.path!) as? [Puzzle] {
                    for puzz in data {
                       store.cachePuzzle(puzz, ofDifficulty: key)
                    }
                }
            }
        
            store.cachesToRefresh.removeAll()
        }
        
        
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
        dispatch_async(concurrentPuzzleQueue) {
            let store = PuzzleStore.sharedInstance
            if let empty = store.getEmptyCaches.first {
                PuzzleStore.sharedInstance.populatePuzzleCache(empty)
            }
        }
        
        let rootView = self.window?.rootViewController as? UINavigationController
        if let puzzleController = rootView?.topViewController as? SudokuController {
            puzzleController.wakeFromBackground()
        }
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
       
        
        let rootView = window?.rootViewController as? UINavigationController
        
        if let puzzleController = rootView?.topViewController as? PlayPuzzleViewController {
            saveCurrentPuzzleForController(puzzleController)
        }
        


    }
    
    func applicationDidReceiveMemoryWarning(application: UIApplication) {
        
        if UIApplication.sharedApplication().applicationState == UIApplicationState.Background {
            let rootView = window?.rootViewController as? UINavigationController
            
            if let puzzleController = rootView?.topViewController as? PlayPuzzleViewController {
                
                saveCurrentPuzzleForController(puzzleController)
                rootView?.popViewControllerAnimated(false)
            }

        }

    }
    
    func saveCurrentPuzzleForController(controller: PlayPuzzleViewController) {
        let defaults = NSUserDefaults.standardUserDefaults()
        
        let dictionaryToSave = dictionaryToSaveForController(controller)
        
        defaults.setObject(dictionaryToSave, forKey: currentPuzzleKey)

    }
    
    
    // banner view delegate
    
    func bannerViewDidLoadAd(banner: ADBannerView!) {
        let rootView = window!.rootViewController as! UINavigationController
        if let puzzleController = rootView.topViewController as? SudokuController {
            puzzleController.bannerViewDidLoadAd(banner)
        }

    }
    
    func bannerView(banner: ADBannerView!, didFailToReceiveAdWithError error: NSError!) {
        let rootView = window!.rootViewController as! UINavigationController
        if let puzzleController = rootView.topViewController as? SudokuController {
            puzzleController.bannerView(banner, didFailToReceiveAdWithError: error)
        } else {
            self.banner = nil
            return
        }
    }
    
    
   func bannerViewActionShouldBegin(banner: ADBannerView!, willLeaveApplication willLeave: Bool) -> Bool {
        let rootView = window!.rootViewController as! UINavigationController
        if let puzzleController = rootView.topViewController as? PlayPuzzleViewController {
            return puzzleController.bannerViewActionShouldBegin(banner, willLeaveApplication: willLeave)
        } else {
            if let sudokuContrl = rootView.topViewController as? SudokuController {
                return sudokuContrl.bannerViewActionShouldBegin(banner, willLeaveApplication: willLeave)
            }
    }
        return false
    }
    
    
    
    func bannerViewActionDidFinish(banner: ADBannerView!) {
        let rootView = window!.rootViewController as! UINavigationController
        if let puzzleController = rootView.topViewController as? PlayPuzzleViewController {
            puzzleController.bannerViewActionDidFinish(banner)
        }
        
    }


}

