//
//  ViewController.swift
//  SudokuCheat
//
//  Created by Isaac Benham on 4/14/15.
//  Copyright (c) 2015 Isaac Benham. All rights reserved.
//

import UIKit
import iAd

extension UINavigationController {
    public override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        if let presented = self.topViewController {
            return presented.supportedInterfaceOrientations()
        } else {
            return .AllButUpsideDown
        }
    }
}


class SudokuController: UIViewController, NumPadDelegate, ADBannerViewDelegate {
    
    var startingNils: [Tile] = []
    var givens: [Tile] = []
    var board: SudokuBoard
    var numPad: SudokuNumberPad
    
    var inactivateInterface: (()->())!
    var activateInterface: (()->())!
    var bannerView = ADBannerView(adType: .Banner)
    var bannerPin: NSLayoutConstraint?
    private var bannerLayoutComplete = false
    var longFetchLabel = UILabel()
    let containerView = UIView(tag: 4)
   
   
   
    
    private var _puzzle: Puzzle?
    var puzzle: Puzzle? {
        var puzzCopy: Puzzle!
        dispatch_sync(concurrentPuzzleQueue){
            puzzCopy = self._puzzle
        }
        return puzzCopy
    }
    
    var tiles: [Tile] {
        get {
            var mutableTiles = [Tile]()
            let boxList = self.board.boxes as! [Box]
            for box in boxList {
                let containedTiles = box.boxes as! [Tile]
                mutableTiles.extend(containedTiles)
            }
            return mutableTiles
        }
    }
    
    var nilTiles: [Tile] {
        get {
            var nilTiles = [Tile]()
            for tile in tiles {
                if tile.value == .Nil {
                    nilTiles.append(tile)
                }
            }
            return nilTiles
        }
    }
    
    var nonNilTiles: [Tile] {
        get {
            var nilTiles = [Tile]()
            for tile in tiles {
                if tile.value != .Nil {
                    nilTiles.append(tile)
                }
            }
            return nilTiles
        }
    }
    
    var difficulty: PuzzleDifficulty = .Easy
    
    var numPadHeight: CGFloat {
        get {
            return self.board.frame.size.width * 1/9
        }
    }
    
    var  wrongTiles: [Tile] {
        var wrong: [Tile] = []
        for tile in nonNilTiles {
            if let correct = tile.solutionValue {
                if correct != tile.value.rawValue {
                    wrong.append(tile)
                }
            }
        }
        return wrong
    }
    
    
    private let spinner: UIActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.WhiteLarge)
    
    
    required init(coder aDecoder: NSCoder) {
        numPad = SudokuNumberPad(frame: CGRectZero)
        board = SudokuBoard(frame: CGRectZero)
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        board.controller = self
        numPad.delegate = self
        view.addSubview(board)
        view.addSubview(numPad)
        board.addSubview(spinner)
        longFetchLabel.hidden = true
        bannerView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        longFetchLabel.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        board.addSubview(longFetchLabel)
        
        setUpBoard()
        setUpButtons()
        longFetchLabel.layer.backgroundColor = UIColor.blackColor().CGColor
        longFetchLabel.textColor = UIColor.whiteColor()
        longFetchLabel.layer.cornerRadius = 10.0
        longFetchLabel.textAlignment = .Center
        longFetchLabel.numberOfLines = 2
        longFetchLabel.font = UIFont.systemFontOfSize(UIFont.labelFontSize())
        longFetchLabel.adjustsFontSizeToFitWidth = true
        
        longFetchLabel.text = "SudokuBot is cooking up a custom puzzle just for you!  It will be ready in a sec."
        
        // register to receive notifications when user defaults change
        NSUserDefaults.standardUserDefaults().addObserver(self, forKeyPath: symbolSetKey, options: .New, context: nil)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        layoutAnimated(true)
        activateInterface()
        
      
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if self.puzzle != nil && !canDisplayBannerAds {
            bannerLayoutComplete = false
            bannerView.delegate = self
            canDisplayBannerAds = true
            view.addSubview(bannerView)
        }
       
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        if canDisplayBannerAds {
            bannerView.removeFromSuperview()
            bannerView.delegate = nil
            canDisplayBannerAds = false
        }
    }
    
    func wakeFromBackground() {
        activateInterface()
        
        //layoutAnimated(true)
        
        if self.puzzle != nil && !canDisplayBannerAds {
            bannerView.delegate = self
            bannerLayoutComplete = false
            canDisplayBannerAds = true
            view.addSubview(bannerView)
            
        }
        
        layoutAnimated(true)
        
    }
    
    func goToBackground() {
        inactivateInterface()
        
        if canDisplayBannerAds {
            bannerView.removeFromSuperview()
            bannerView.delegate = nil
            canDisplayBannerAds = false
            layoutAnimated(false)
        }
    }
    
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return .Portrait
    }
    
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [NSObject : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if let path = keyPath {
            if path == symbolSetKey {
                numPad.refreshButtonText()
                for tile in tiles {
                    tile.refreshLabel()
                }

            }
        }
    }
    
   deinit {

        NSUserDefaults.standardUserDefaults().removeObserver(self, forKeyPath: symbolSetKey)
    
    }
    
    func setUpBoard() {
        
        
        board.translatesAutoresizingMaskIntoConstraints = false
        numPad.translatesAutoresizingMaskIntoConstraints = false
        spinner.translatesAutoresizingMaskIntoConstraints = false
        longFetchLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let topPin = NSLayoutConstraint(item: board, attribute: .Top, relatedBy: .Equal, toItem: self.topLayoutGuide, attribute: .Bottom, multiplier: 1, constant: 10)
        let centerPin = NSLayoutConstraint(item: board, attribute: .CenterX, relatedBy: .Equal, toItem: originalContentView, attribute: .CenterX, multiplier: 1, constant: 0)
        let boardWidth = NSLayoutConstraint(item: board, attribute: .Width, relatedBy: .Equal, toItem: originalContentView, attribute: .Width, multiplier: 0.95, constant: 0)
        let boardHeight = NSLayoutConstraint(item: board, attribute: .Height, relatedBy: .Equal, toItem: board, attribute: .Width, multiplier: 1, constant: 0)
        
        let constraints = [topPin, centerPin, boardWidth, boardHeight]
        originalContentView.addConstraints(constraints)
       
        
        let numPadWidth = NSLayoutConstraint(item: numPad, attribute: .Width, relatedBy: .Equal, toItem: board, attribute: .Width, multiplier: 1, constant: 0)
        let numPadHeight = NSLayoutConstraint(item: numPad, attribute: .Height, relatedBy: .Equal, toItem: board, attribute: .Width, multiplier: 1/9, constant: 0)
        let numPadCenterX = NSLayoutConstraint(item: numPad, attribute: .CenterX, relatedBy: .Equal, toItem: board, attribute: .CenterX, multiplier: 1, constant: 0)
        let numPadTopSpace = NSLayoutConstraint(item: numPad, attribute: .Top, relatedBy: .Equal, toItem: board, attribute: .Bottom, multiplier: 1, constant: 8)
        let spinnerHor = NSLayoutConstraint(item: spinner, attribute: .CenterX, relatedBy: .Equal, toItem: board, attribute: .CenterX, multiplier: 1, constant: 0)
        let spinnerVert = NSLayoutConstraint(item: spinner, attribute: .CenterY, relatedBy: .Equal, toItem: board, attribute: .CenterY, multiplier: 1, constant: 0)
        
        originalContentView.addConstraints([numPadWidth, numPadHeight, numPadCenterX, numPadTopSpace, spinnerHor, spinnerVert])


        
        board.backgroundColor = UIColor(red: 0.5, green: 0.5, blue: 1, alpha: 1)
        
        
    }
    
    func setUpButtons() {
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
       
        
    }
    
    override func viewWillLayoutSubviews() {
        if self.canDisplayBannerAds  && !bannerLayoutComplete {
            if bannerView.superview == nil {
                view.addSubview(bannerView)

            }
            bannerView.delegate = self
            
            bannerView.translatesAutoresizingMaskIntoConstraints = false
            
            originalContentView.removeConstraints()
            originalContentView.translatesAutoresizingMaskIntoConstraints = false
            
            
            bannerPin = NSLayoutConstraint(item: bannerView, attribute: .Top, relatedBy: .Equal, toItem: view, attribute: .Bottom, multiplier: 1, constant: 0)
            bannerPin?.priority = 1000
            let bannerLeft = NSLayoutConstraint(item: bannerView, attribute: .Leading, relatedBy: .Equal, toItem:view, attribute: .Leading, multiplier: 1, constant: 0)
            let bannerRight = NSLayoutConstraint(item: bannerView, attribute: .Trailing, relatedBy: .Equal, toItem: view, attribute: .Trailing, multiplier: 1, constant: 0)
            
            
            let contentBottom = NSLayoutConstraint(item: originalContentView, attribute: .Bottom, relatedBy: .Equal, toItem: bannerView, attribute: .Top, multiplier: 1, constant: 0)
            contentBottom.priority = 1000
            let contentLeft = NSLayoutConstraint(item: originalContentView, attribute: .Leading, relatedBy: .Equal, toItem: view, attribute: .Leading, multiplier: 1, constant: 0)
            let contentRight = NSLayoutConstraint(item: originalContentView, attribute: .Trailing, relatedBy: .Equal, toItem: view, attribute: .Trailing, multiplier: 1, constant: 0)
            let contentTop = NSLayoutConstraint(item: originalContentView, attribute: .Top, relatedBy: .Equal, toItem: view, attribute: .Top, multiplier: 1, constant: 0)
            view.addConstraints([contentBottom, contentLeft, contentRight, contentTop, bannerPin!, bannerLeft, bannerRight])
            
            bannerLayoutComplete = true
            
            board.removeConstraints()
            setUpBoard()
            containerView.removeConstraints()
            setUpButtons()
            
        }
       
    }
    
    func tileAtIndex(_index: TileIndex) -> Tile {
        return board.getBoxAtIndex(_index.0).getTileAtIndex(_index.1)
    }
    
    
    // puzzle fetching
    func fetchPuzzle() {
        
        bannerView.userInteractionEnabled = false
       
        UIView.animateWithDuration(0.25) {
            self.navigationController?.navigationBarHidden = true
            self.inactivateInterface()
        }
        let middleTile = board.tileAtIndex((5,4))
        let placeHolderColor = middleTile.selectedColor
        middleTile.selectedColor = UIColor.blackColor()
        board.selectedTile = middleTile
        
        board.userInteractionEnabled = false
        
        spinner.startAnimating()
        let handler: (Puzzle -> ()) = {
            puzz -> () in
            dispatch_sync(GlobalMainQueue){
                self.spinner.stopAnimating()
                middleTile.selectedColor = placeHolderColor
                self._puzzle = puzz
                self.startingNils = []
                self.givens = []
                for cell in puzz.solution {
                    let tIndex = getTileIndexForRow(cell.row, andColumn: cell.column)
                    let tile = self.board.tileAtIndex(tIndex)
                    tile.backingCell = cell
                    tile.solutionValue = cell.value
                    self.startingNils.append(tile)
                }
                for cell in puzz.initialValues {
                    let tIndex = getTileIndexForRow(cell.row, andColumn: cell.column)
                    let tile = self.board.tileAtIndex(tIndex)
                    tile.backingCell = cell
                    tile.value = TileValue(rawValue: cell.value)!
                    self.givens.append(tile)
                    
                }
                self.board.userInteractionEnabled = true
                UIView.animateWithDuration(0.25) {
                    self.navigationController?.navigationBarHidden = false
                    self.longFetchLabel.hidden = true
                }
                self.puzzleReady()
                dispatch_async(GlobalBackgroundQueue) {
                    Matrix.sharedInstance.fillCaches()
                }
            }
        }
            
        dispatch_barrier_async(concurrentPuzzleQueue) {
            let matrix = Matrix.sharedInstance
            
            if !self.difficulty.isCachable {
                dispatch_sync(GlobalMainQueue) {
                    UIView.animateWithDuration(0.25) {
                        self.longFetchLabel.hidden = false
                        self.longFetchLabel.frame = CGRectMake(0,0, self.board.frame.width, self.board.frame.height * 0.2)
                    }
                }
                matrix.generatePuzzleOfDifficulty(self.difficulty) { puzz -> () in
                    handler(puzz)
                }
            } else {
                if let puzz = matrix.getCachedPuzzleOfDifficulty(self.difficulty) {
                    handler(puzz)
                    
                } else {
                    let defaults = NSUserDefaults.standardUserDefaults()
                    let key = self.difficulty.cacheString()
                    if let dict = defaults.objectForKey(key), puzz = Puzzle.fromData((dict as! NSData)) {
                        handler(puzz)
                        defaults.removeObjectForKey(key)
                    } else {
                        dispatch_sync(GlobalMainQueue) {
                            UIView.animateWithDuration(0.25) {
                                self.longFetchLabel.hidden = false
                                self.longFetchLabel.frame = CGRectMake(0,0, self.board.frame.width, self.board.frame.height * 0.2)
                            }
                        }
                        matrix.generatePuzzleOfDifficulty(self.difficulty) { puzz -> () in
                            handler(puzz)
                        }
                    }
                }
            }
            
        }
    }
    
    func replayCurrent() {
        if _puzzle == nil {
            return
        }
        
        UIView.animateWithDuration(0.5) {
            for tile in self.startingNils {
                tile.value = TileValue.Nil
                if tile.solutionValue == nil {
                    tile.solutionValue = tile.backingCell.value
                    tile.userInteractionEnabled = true
                }
            }
        }
        
        for tile in self.givens {
            tile.userInteractionEnabled = false
        }
    }
    
    // Board tile selected handler
    func boardSelectedTileChanged() {
        numPad.refresh()
    }
    
    func boardReady() {
        
    }
    
    func puzzleReady() {
        activateInterface()
        if !canDisplayBannerAds {
            bannerLayoutComplete = false
            canDisplayBannerAds = true
        }
        bannerView.userInteractionEnabled = true
        if nilTiles.count > 0 {
            board.selectedTile = nilTiles[0]
        }
    }
    
    
    // NumPadDelegate methods
    func valueSelected(value: Int) {
        if let selected = board.selectedTile {
            if selected.value.rawValue == value {
                selected.value = TileValue(rawValue: 0)!
            } else {
                if let newTV = TileValue(rawValue: value) {
                    selected.value = newTV
                }
            }
        }
        numPad.refresh()
    }
    
    func currentValue() -> Int? {
        if let sel = self.board.selectedTile {
           let val = sel.value.rawValue
            if val == 0 {
                return nil
            }
            return val
        }
        return nil
    }
    
    // banner view delegate
    
    func bannerViewDidLoadAd(banner: ADBannerView!) {
        print("test!")
        layoutAnimated(true)
    }
    
    func bannerView(banner: ADBannerView!, didFailToReceiveAdWithError error: NSError!) {
        
        print(error)
        layoutAnimated(true)
    }
    
    
    func layoutAnimated(animated: Bool) {
        
        if !canDisplayBannerAds {
            if bannerPin?.constant != 0 {
                view.layoutIfNeeded()
                UIView.animateWithDuration(0.25) {
                    self.bannerPin?.constant = 0
                    self.view.layoutIfNeeded()
                }
            }
            return
        }
        
        if bannerView.bannerLoaded  {
            if bannerPin?.constant == 0 {
                view.layoutIfNeeded()
                UIView.animateWithDuration(0.25) {
                    self.bannerPin?.constant = -self.bannerView.frame.size.height
                    self.view.layoutIfNeeded()
                }
            }
        } else {
            if bannerPin?.constant != 0 {
                view.layoutIfNeeded()
                UIView.animateWithDuration(0.25) {
                    self.bannerPin?.constant = 0
                    self.view.layoutIfNeeded()
                }
            }
        }
    }
    
    func bannerViewActionShouldBegin(banner: ADBannerView!, willLeaveApplication willLeave: Bool) -> Bool {
        return true
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        super.prepareForSegue(segue, sender: sender)
        print("segue!")
    }
    
}

class PuzzleOptionsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    let tableView = UITableView(frame: CGRectZero, style: .Grouped)
    let baseView = UIView(frame: CGRectZero)
    let saveButton = UIButton()
    var selectedIndex:NSIndexPath = NSIndexPath(forRow: 0, inSection: 0)  {
        willSet {
            if selectedIndex != newValue {
                let cell = tableView.cellForRowAtIndexPath(selectedIndex)
                cell?.accessoryType = .None
            }
        }
        didSet {
            if selectedIndex != oldValue {
                let cell = tableView.cellForRowAtIndexPath(selectedIndex)
                cell?.accessoryType = .Checkmark
            }
        }
    }
    
    var timedStatus = true {
        didSet {
            let indexPath = NSIndexPath(forRow: 0, inSection: 1)
            let cell = tableView.cellForRowAtIndexPath(indexPath)
            cell?.textLabel!.text = timedStatusString
        }
    }
    var timedStatusString: String {
        get {
            return timedStatus ? "On" : "Off"
        }
    }
    
    required init(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
        
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "cell")
        view.addSubview(tableView)
        view.addSubview(baseView)
        baseView.addSubview(saveButton)
        saveButton.addTarget(self, action: Selector("saveAndDismiss"), forControlEvents: .TouchUpInside)
        saveButton.setTitle("Save", forState: .Normal)
        saveButton.layer.borderColor = UIColor.darkGrayColor().CGColor
        saveButton.layer.borderWidth = 2.0
        saveButton.setTitleColor(UIColor.blackColor(), forState: .Normal)
        saveButton.layer.cornerRadius = 5.0
        saveButton.backgroundColor = UIColor.whiteColor()
        saveButton.showsTouchWhenHighlighted = true
        baseView.backgroundColor = UIColor.lightGrayColor()
       
        
        self.layoutTableView()
        tableView.delegate = self
        tableView.dataSource = self
        
        let defaults = NSUserDefaults.standardUserDefaults()
        let selected = defaults.integerForKey(symbolSetKey)
        
        let index = NSIndexPath(forRow: selected, inSection: 0)
        selectedIndex = index
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    func layoutTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        baseView.translatesAutoresizingMaskIntoConstraints = false
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        
        let basePin = NSLayoutConstraint(item: baseView, attribute: .Bottom, relatedBy: .Equal, toItem: view, attribute: .Bottom, multiplier: 1, constant: 0)
        let baseWidth = NSLayoutConstraint(item: baseView, attribute: .Width, relatedBy: .Equal, toItem: view, attribute: .Width, multiplier: 1, constant: 0)
        let baseHeight = NSLayoutConstraint(item: baseView, attribute: .Height, relatedBy: .Equal, toItem: view, attribute: .Height, multiplier: 1/12, constant: 0)
        
        let tvWidth = NSLayoutConstraint(item: tableView, attribute: .Width, relatedBy: .Equal, toItem: view, attribute: .Width, multiplier: 1, constant: 0)
        let topPin = NSLayoutConstraint(item: tableView, attribute: .Top, relatedBy: .Equal, toItem: self.topLayoutGuide, attribute: .Bottom, multiplier: 1, constant: 0)
        let bottomPin = NSLayoutConstraint(item: tableView, attribute: .Bottom, relatedBy: .Equal, toItem: baseView, attribute: .Top, multiplier: 1, constant: 0)
        
        let buttonHeight = NSLayoutConstraint(item: saveButton, attribute: .Height, relatedBy: .Equal, toItem: baseView, attribute: .Height, multiplier: 4/5, constant: 0)
        let buttonWidth = NSLayoutConstraint(item: saveButton, attribute: .Width, relatedBy: .Equal, toItem: baseView, attribute: .Width, multiplier: 1/6, constant: 0)
        let buttonVertCenter = NSLayoutConstraint(item: saveButton, attribute: .CenterY, relatedBy: .Equal, toItem: baseView, attribute: .CenterY, multiplier: 1, constant: 0)
        let buttonPin = NSLayoutConstraint(item: saveButton, attribute: .Trailing, relatedBy: .Equal, toItem: baseView, attribute: .Trailing, multiplier: 1, constant: -8)
        
        let constraints = [basePin, baseWidth, baseHeight, tvWidth, topPin, bottomPin, buttonHeight, buttonWidth, buttonVertCenter, buttonPin]
        
        self.view.addConstraints(constraints)
        
    }

    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Change Symbol Set"
         default:
            return "Timer"
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section{
        case 0:
            return 3
        default:
            return 1
            
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) as UITableViewCell
       
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = "Standard: 1-9"
            case 1:
                cell.textLabel?.text = "Critters:🐥-🐌"
            default:
                cell.textLabel?.text = "Flags:🇨🇭-🇲🇽"
            }
        default:
            cell.textLabel?.text = timedStatusString
        }
        
        if indexPath == selectedIndex {
            cell.accessoryType = .Checkmark
        }
        return cell
        
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        if indexPath.section == 0 {
            selectedIndex = indexPath
        } else {
            timedStatus = !timedStatus
        }
        
    }
    
    // saving changes
    
    func saveAndDismiss() {
        
        let selected = selectedIndex.row
        let defaults = NSUserDefaults.standardUserDefaults()
        
        defaults.setInteger(selected, forKey: "symbolSet")
        defaults.setBool(timedStatus, forKey: "timed")
        
        defaults.synchronize()
        
        presentingViewController!.dismissViewControllerAnimated(true) {
          
        }

    }
    
    
    
}

