//
//  IndexTranslation.swift
//  SudokuCheat
//
//  Created by Isaac Benham on 5/11/15.
//  Copyright (c) 2015 Isaac Benham. All rights reserved.
//

import Foundation

let iPhone4 =  UIScreen.mainScreen().bounds.size.height < 568


// row/column -> TileIndex ((Box: 0-8, Tile: 0-8))
func getBox(column: Int, row: Int) -> Int {
    switch column {
    case 1, 2, 3:
        switch row {
        case 1,2,3:
            return 1
        case 4,5,6:
            return 4
        default:
            return 7
        }
    case 4,5,6:
        switch row {
        case 1,2,3:
            return 2
        case 4,5,6:
            return 5
        default:
            return 8
        }
    default:
        switch row {
        case 1,2,3:
            return 3
        case 4,5,6:
            return 6
        default:
            return 9
        }
    }
}

func getTileIndex(board:Int=0, row: Int, column: Int) -> TileIndex {
    let box = getBox(column, row: row)
    switch row {
    case 1,4,7:
        switch column {
        case 1,4,7:
            return (board, box, 0)
        case 2,5,8:
            return (board, box, 1)
        default:
            return (board, box, 2)
        }
    case 2,5,8:
        switch column {
        case 1,4,7:
            return (board, box, 3)
        case 2,5,8:
            return (board, box, 4)
        default:
            return (board, box, 5)
        }
    default:
        switch column {
        case 1,4,7:
            return (board, box, 6)
        case 2,5,8:
            return (board, box, 7)
        default:
            return (board, box, 8)
        }
    }
}


// TileIndex -> row/column
func getColumnIndexFromTileIndex(tileIndex: TileIndex) -> Int {
    switch tileIndex.Box{
    case 1,4,7:
        switch tileIndex.Tile{
        case 1,4,7:
            return 1
        case 2,5,8:
            return 2
        default:
            return 3
        }
    case 2,5,8:
        switch tileIndex.Tile{
        case 1,4,7:
            return 4
        case 2,5,8:
            return 5
        default:
            return 6
        }
    default:
        switch tileIndex.Tile {
        case 1,4,7:
            return 7
        case 2,5,8:
            return 8
        default:
            return 9
        }
    }
}


func getRowIndexFromTileIndex(tileIndex: TileIndex) -> Int {
    switch tileIndex.Box{
    case 1,2,3:
        switch tileIndex.Tile{
        case 1,2,3:
            return 1
        case 4,5,6:
            return 2
        default:
            return 3
        }
    case 4,5,6:
        switch tileIndex.Tile{
        case 1,2,3:
            return 4
        case 4,5,6:
            return 5
        default:
            return 6
        }
    default:
        switch tileIndex.Tile {
        case 1,2,3:
            return 7
        case 4,5,6:
            return 8
        default:
            return 9
        }
    }
}

// Nodes <-> Cells

func cellsFromConstraints(constraints: [LinkedNode<PuzzleKey>]) -> [PuzzleCell] {
    var puzzleNodes: [PuzzleKey] = []
    for node in constraints {
        if node.key != nil {
            puzzleNodes.append(node.key!)
        }
    }
    var cells: [PuzzleCell] = []
    for node in puzzleNodes {
        let cell = node.cell!
        cells.append(cell)
    }
    return cells
}

func cellNodeDictFromNodes(nodes: [LinkedNode<PuzzleKey>]) -> [PuzzleCell: LinkedNode<PuzzleKey>]{
    var dict: [PuzzleCell: LinkedNode<PuzzleKey>] = [:]
    for node in nodes {
        let cell = node.key!.cell!
        dict[cell] = node
    }
    return dict
}

func tileForConstraint(node: PuzzleKey, tiles:[Tile]) -> Tile? {
    if let cRow = node.cell?.row {
        if let cCol = node.cell?.column {
            for t in tiles {
                if t.getColumnIndex() == cCol && t.getRowIndex() == cRow {
                    return t
                }
            }
        }
    }
    return nil
}


func translateCellsToConstraintList(cells:[PuzzleCell])->[PuzzleKey] {
    var matrixRowArray = [PuzzleKey]()
    for cell in cells {
        let mRow:PuzzleKey = PuzzleKey(cell: cell)
        matrixRowArray.append(mRow)
    }
    return matrixRowArray
}

//tiles -> cells
func cellsFromTiles(tiles:[Tile]) -> [PuzzleCell] {
    var cells: [PuzzleCell] = []
    for tile in tiles {
        let val = tile.displayValue.rawValue
        let row = tile.getRowIndex()
        let column = tile.getColumnIndex()
        let pCell = PuzzleCell(row: row, column: column, value: val)
        cells.append(pCell)
    }
    
    return cells
}

// other utils

var GlobalMainQueue: dispatch_queue_t {
    return dispatch_get_main_queue()
}

/*var GlobalUserInteractiveQueue: dispatch_queue_t {
    return dispatch_get_global_queue(Int(QOS_CLASS_USER_INTERACTIVE.rawValue), 0)
}

var GlobalUserInitiatedQueue: dispatch_queue_t {
    return dispatch_get_global_queue(Int(QOS_CLASS_USER_INITIATED.rawValue), 0)
}

var GlobalUtilityQueue: dispatch_queue_t {
    return dispatch_get_global_queue(Int(QOS_CLASS_UTILITY.rawValue), 0)
}*/

var GlobalBackgroundQueue: dispatch_queue_t {
    return dispatch_get_global_queue(Int(QOS_CLASS_BACKGROUND.rawValue), 0)
}

let concurrentPuzzleQueue = dispatch_queue_create(
    "com.isaacbenham.SudokuCheat.puzzleQueue", DISPATCH_QUEUE_CONCURRENT)

//let concurrentBackupQueue = dispatch_queue_create("com.isaacbenham.SudokuCheat.backupQueue", DISPATCH_QUEUE_CONCURRENT)

extension UIButton {
    convenience init(tag: Int) {
        self.init()
        self.tag = tag
    }
}

extension UIView {
    convenience init(tag: Int) {
        self.init()
        self.tag = tag
    }
}

// user default constants
let symbolSetKey = "symbolSet"
let timedKey = "timed"
let easyPuzzleKey = "Easy"
let mediumPuzzleKey = "Medium"
let hardPuzzleKey = "Hard"
let insanePuzzleKey = "Insane"

let easyPuzzleReady = "easyPuzzleReady"
let mediumPuzzleReady = "mediumPuzzleReady"
let hardPuzzleReady = "hardPuzzleReady"
let insanePuzzleReady = "insanePuzzleReady"
let customPuzzleReady = "customPuzzleReady"

let currentHardPuzzleKey = "currentHardPuzzle"
let currentEasyPuzzleKey = "currentEasyPuzzle"
let currentMediumPuzzleKey = "currentMediumPuzzle"
let currentInsanePuzzleKey = "currentInsanePuzzle"
let currentPuzzleKey = "currentPuzzle"

let cachedNotification = "puzzleCached"

let easyCacheFilePath = (NSFileManager.defaultManager().URLsForDirectory(.LibraryDirectory, inDomains: .UserDomainMask)[0] as NSURL).URLByAppendingPathComponent("easy/puzzle_cache.plist")

let mediumCacheFilePath = (NSFileManager.defaultManager().URLsForDirectory(.LibraryDirectory, inDomains: .UserDomainMask)[0] as NSURL).URLByAppendingPathComponent("medium/puzzle_cache.plist")

let hardCacheFilePath = (NSFileManager.defaultManager().URLsForDirectory(.LibraryDirectory, inDomains: .UserDomainMask)[0] as NSURL).URLByAppendingPathComponent("hard/puzzle_cache.plist")

let insaneCacheFilePath = (NSFileManager.defaultManager().URLsForDirectory(.LibraryDirectory, inDomains: .UserDomainMask)[0] as NSURL).URLByAppendingPathComponent("insane/puzzle_cache.plist")

enum SymbolSet {
    case Standard, Critters, Flags
    
    
    func getSymbolForTyleValue(value: TileValue) -> String {
        switch self {
        case Standard:
            return String(value.rawValue)
        case Critters:
            let dict:[Int:String] = [1:"🐥", 2:"🙈", 3:"🐼", 4:"🐰", 5:"🐷", 6:"🐘", 7:"🐢", 8:"🐙", 9:"🐌"]
            return dict[value.rawValue]!
        case Flags:
            let dict = [1:"🇨🇭", 2:"🇿🇦", 3:"🇨🇱", 4:"🇨🇦", 5:"🇯🇵", 6:"🇹🇷", 7:"🇫🇮", 8:"🇰🇷", 9:"🇲🇽"]
            return dict[value.rawValue]!
        }
    }
    
    func getSymbolForValue(value: Int) -> String {
        switch self {
        case Standard:
            return String(value)
        case Critters:
            let dict:[Int:String] = [1:"🐥", 2:"🙈", 3:"🐼", 4:"🐰", 5:"🐷", 6:"🐘", 7:"🐢", 8:"🐙", 9:"🐌"]
            return dict[value]!
        case Flags:
            let dict = [1:"🇨🇭", 2:"🇸🇪", 3:"🇨🇱", 4:"🇨🇦", 5:"🇯🇵", 6:"🇹🇷", 7:"🇫🇮", 8:"🇰🇷", 9:"🇲🇽"]
            return dict[value]!
        }
    }
}

extension TileValue {
    func getSymbolForTyleValueforSet(symSet: SymbolSet) -> String {
        switch symSet {
        case .Standard:
            return String(self.rawValue)
        case .Critters:
            let dict:[Int:String] = [1:"🐥", 2:"🙈", 3:"🐼", 4:"🐰", 5:"🐷", 6:"🐘", 7:"🐢", 8:"🐙", 9:"🐌"]
            return dict[self.rawValue]!
        case .Flags:
            let dict = [1:"🇨🇭", 2:"🇿🇦", 3:"🇨🇱", 4:"🇨🇦", 5:"🇯🇵", 6:"🇹🇷", 7:"🇫🇮", 8:"🇰🇷", 9:"🇲🇽"]
            return dict[self.rawValue]!
        }
    }
    
}


extension UIView {
    
    func removeConstraints() {
        if let superView = self.superview {
            self.removeFromSuperview()
            superView.addSubview(self)
        }
    }
    
    
    
}

/*func dictionaryToSaveForController(controller: PlayPuzzleViewController) -> NSDictionary {
    
    let data = NSKeyedArchiver.archivedDataWithRootObject(controller.puzzle!)
    
    let assignedCells = controller.startingNils.filter({$0.value != .Nil}).map({$0.backingCell.asDict()})
    
    let annotatedCells = controller.annotatedTiles.map({NSDictionary(dictionary: ["cell": $0.backingCell.asDict(), "notes":$0.noteValues.map{$0.rawValue}], copyItems: true)})
    
    let time = controller.timeElapsed
    
    let discoveredCells = controller.discoveredTiles.map({$0.backingCell.asDict()})
    
    let difficulty = controller.difficulty.cacheString()
    
    return ["puzzle":data, "progress":assignedCells, "annotated":annotatedCells, "discovered":discoveredCells, "time":time, "difficulty":difficulty] as NSDictionary
    
}*/


class TableCell: UIView {
    var labelVertInset: CGFloat = 0 {
        didSet {
            label?.frame.origin.y = labelVertInset
            label?.frame.size.height = self.frame.size.height - (2*labelVertInset)
        }
    }
    var labelHorizontalInset: CGFloat = 0 {
        didSet {
            label?.frame.origin.x = labelHorizontalInset
        }
    }
    var label: UILabel? {
        didSet {
            if let old = oldValue {
                old.removeFromSuperview()
            }
            var rect = self.bounds
            rect.origin.x += labelHorizontalInset
            rect.origin.y += labelVertInset
            rect.size.height -= 2*labelVertInset
            label?.frame = rect
            label?.font = UIFont(name: "futura", size: UIFont.labelFontSize())
            label!.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
            self.addSubview(label!)
        }
    }
    
    override var frame:CGRect {
        
        didSet {
            var labelFrame = bounds
            labelFrame.insetInPlace(dx: labelHorizontalInset, dy: labelVertInset)
            label?.frame = labelFrame
        }
    }
    
    var section: Int?
}

extension UIViewController {
    func sections() -> Int {
        return 0
    }
    
    func rowsForSection(section: Int) -> Int {
        return 3
    }
}




