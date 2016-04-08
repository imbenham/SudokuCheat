//
//  CheatViewController.swift
//  SudokuCheat
//
//  Created by Isaac Benham on 5/25/15.
//  Copyright (c) 2015 Isaac Benham. All rights reserved.
//

import Foundation
import iAd

class CheatViewController: SudokuController {
    
    var solveButton: UIButton?
    var clearButton: UIButton?
    var solved = false
    
    struct Token {
        static var onceToken: dispatch_once_t = 0
    }
    
    class var token:dispatch_once_t {
        get {
        return Token.onceToken
        }
        set {
            Token.onceToken = newValue
        }
    }


    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        originalContentView.backgroundColor = UIColor.orangeColor()
        if !iPhone4 {
            solveButton = UIButton()
            clearButton = UIButton()
            originalContentView.addSubview(solveButton!)
            solveButton!.backgroundColor = UIColor.whiteColor()
            solveButton!.setTitleColor(UIColor.blackColor(), forState: .Normal)
            solveButton!.setTitle("Solve", forState: .Normal)
            solveButton!.layer.cornerRadius = 5.0
            solveButton!.addTarget(self, action: #selector(CheatViewController.solvePuzzle), forControlEvents: .TouchUpInside)
            solveButton!.layer.borderColor = UIColor.blackColor().CGColor
            solveButton!.layer.borderWidth = 2.0
            originalContentView.addSubview(clearButton!)
            clearButton!.backgroundColor = UIColor.whiteColor()
            clearButton!.setTitleColor(UIColor.blackColor(), forState: .Normal)
            clearButton!.setTitle("Clear", forState: .Normal)
            clearButton!.layer.cornerRadius = 5.0
            clearButton!.addTarget(self, action: #selector(CheatViewController.clearAll), forControlEvents: .TouchUpInside)
            clearButton!.layer.borderColor = UIColor.blackColor().CGColor
            clearButton!.layer.borderWidth = 2.0
            
            solveButton!.translatesAutoresizingMaskIntoConstraints = false
            clearButton!.translatesAutoresizingMaskIntoConstraints = false
            
            let solveRightEdge = NSLayoutConstraint(item: solveButton!, attribute: .Trailing, relatedBy: .Equal, toItem: board, attribute: .Trailing, multiplier: 1, constant: 0)
            let solveBottomPin = NSLayoutConstraint(item: solveButton!, attribute: .Bottom, relatedBy: .Equal, toItem: bottomLayoutGuide, attribute: .Top, multiplier: 1, constant: -8)
            let buttonWidth = NSLayoutConstraint(item: solveButton!, attribute: .Width, relatedBy: .Equal, toItem: board, attribute: .Width, multiplier: 1/3, constant: 0)
            let buttonHeight = NSLayoutConstraint(item: solveButton!, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: 40)
            
            let clearWidth = NSLayoutConstraint(item: clearButton!, attribute: .Width, relatedBy: .Equal, toItem: self.board, attribute: .Width, multiplier: 1/3, constant: 0)
            let clearHeight = NSLayoutConstraint(item: clearButton!, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: 40)
            let clearBottomPin = NSLayoutConstraint(item: clearButton!, attribute: .Bottom, relatedBy: .Equal, toItem: self.bottomLayoutGuide, attribute: .Top, multiplier: 1, constant: -8)
            let clearLeftEdge = NSLayoutConstraint(item: clearButton!, attribute: .Leading, relatedBy: .Equal, toItem: self.board, attribute: .Leading, multiplier: 1, constant: 0)
            
            let constraints = [solveRightEdge, solveBottomPin, buttonWidth, buttonHeight, clearWidth, clearHeight, clearBottomPin, clearLeftEdge]
            view.addConstraints(constraints)

        } else {
            let swipe = UISwipeGestureRecognizer(target: self, action: #selector(CheatViewController.solvePuzzle))
            board.addGestureRecognizer(swipe)
        }
        
        
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setInteger(0, forKey: "symbolSet")
        
    }
    
    override func motionEnded(motion: UIEventSubtype, withEvent event: UIEvent?) {
        if motion == UIEventSubtype.MotionShake {
            clearAll()
        }
    }
    
    

    
    override func viewDidAppear(animated: Bool) {
        
        dispatch_once(&CheatViewController.token) {
            let message = iPhone4 ? "Enter any valid puzzle and SudokuBot will magically solve it for you. With magic. Shake to clear. Swipe right to solve." : "Enter any valid puzzle and SudokuBot will magically solve it for you. With magic."
            let instructionAlert = UIAlertController(title: "Welcome to the dark side.", message: message, preferredStyle: .Alert)
            let dismiss = UIAlertAction(title: "OK", style: .Cancel, handler: nil)
            instructionAlert.addAction(dismiss)
            self.presentViewController(instructionAlert, animated: true) { () in
                self.bannerLayoutComplete = false
                self.canDisplayBannerAds = true
            }
            
            
        }

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    func clearAll() {
        solved = false
        let tiles = self.tiles
        for tile in tiles {
            tile.labelColor = UIColor.blackColor()
            tile.setValue(0)
            tile.refreshLabel()
        }
        selectedTile = nilTiles[0]
        activateInterface()
    }
    
    func solvePuzzle() {
        deactivateInterface()
        let valuatedTiles = nonNilTiles
        let cells: [PuzzleCell] = cellsFromTiles(valuatedTiles)
        if let solution = Matrix.sharedInstance.solutionForValidPuzzle(cells) {
            for cell in solution {
                let tIndex = getTileIndex(row: cell.row, column: cell.column)
                let tile = board.tileAtIndex(tIndex)
                tile.labelColor = UIColor.redColor()
                tile.setValue(cell.value)
            }
            selectedTile = nil
            solved = true
            activateInterface()

        } else {
            let alertController = UIAlertController(title: "Invalid Puzzle", message: "SudokuBot can't help you because the puzzle you've tried to solve has more or less than one solution. It's not THAT magical.", preferredStyle: .Alert)
            
            let OKAction = UIAlertAction(title: "OK", style: .Default) { (_) in
                self.dismissViewControllerAnimated(true) {
                    ()->() in
                   
                }
                 self.activateInterface()
            }
            alertController.addAction(OKAction)
            
            self.presentViewController(alertController, animated: true) {
                
            }
        }

    }
    
    override func bannerViewActionShouldBegin(banner: ADBannerView!, willLeaveApplication willLeave: Bool) -> Bool {
        return super.bannerViewActionShouldBegin(banner, willLeaveApplication: willLeave)
    }
    
    
    
    func bannerViewActionDidFinish(banner: ADBannerView!) {
        activateInterface()
        
    }
    
    override func deactivateInterface() {
        if !iPhone4 {
            self.solveButton!.userInteractionEnabled = false
            self.solveButton!.alpha = 0.5
            self.clearButton!.userInteractionEnabled = false
            
        }
        self.numPad.userInteractionEnabled  = false
        for tile in self.tiles {
            tile.userInteractionEnabled = false
        }
        self.board.userInteractionEnabled = false
    }
    
    override func activateInterface() {
        if !iPhone4 {
            if !self.solved {
                self.solveButton!.userInteractionEnabled = true
                self.solveButton!.alpha = 1.0
            }
        }
        
        
        for tile in self.tiles {
            tile.userInteractionEnabled = true
        }
        
        if !iPhone4 {
            self.clearButton!.userInteractionEnabled = true
        }
        self.numPad.userInteractionEnabled = true
        self.board.userInteractionEnabled = true
        self.numPad.refresh()
    }

}
