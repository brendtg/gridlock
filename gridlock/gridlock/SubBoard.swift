import Foundation

struct SubBoard: Codable, Equatable, Hashable {
    // 9 cells (3x3 inner grid, row-major)
    var cells: [Player]           // count: 9
    // 12 edge positions (4 sides × 3 positions each: top0,top1,top2, right0,right1,right2, bottom0,bottom1,bottom2, left0,left1,left2)
    var edges: [Player]           // count: 12
    // 4 intersection positions (corners: topLeft, topRight, bottomRight, bottomLeft)
    var intersections: [Player]   // count: 4
    var status: BoardStatus
    // Indices of long-win lines that have been blocked by meta-blocking
    var blockedLongWinLines: Set<Int>

    init() {
        cells = Array(repeating: .empty, count: 9)
        edges = Array(repeating: .empty, count: 12)
        intersections = Array(repeating: .empty, count: 4)
        status = .active
        blockedLongWinLines = []
    }

    // Classic 3-in-a-row lines (indices into cells array)
    static let cellWinLines: [[Int]] = [
        [0,1,2],[3,4,5],[6,7,8],  // rows
        [0,3,6],[1,4,7],[2,5,8],  // cols
        [0,4,8],[2,4,6]           // diagonals
    ]

    // Win lines that include at least one edge or intersection (short wins)
    // These are lines crossing the board boundary - cannot be blocked
    // Represented as (posType, index) tuples conceptually, but for win checking
    // we check all possible 3-in-a-row combinations across the full 25-position board.
    // Position encoding for extended board (0-24):
    //   0-8: cells (row-major)
    //   9-20: edges (top0-2, right0-2, bottom0-2, left0-2)
    //   21-24: intersections (TL, TR, BR, BL)
    //
    // Extended win lines (subset involving edges/intersections):
    static let extendedWinLines: [[Int]] = [
        // Top edge row: TL-top0-TR, TL-top1-?, TR etc. — actual short wins
        [21,9,22],   // TL - top0 - TR (top edge)... wait, top has 3 positions
        // Let's define properly:
        // Top border: TL(21), top0(9), top1(10), top2(11), TR(22)
        // Right border: TR(22), right0(12), right1(13), right2(14), BR(23)
        // Bottom border: BL(24), bottom0(15), bottom1(16), bottom2(17), BR(23)
        // Left border: TL(21), left0(18), left1(19), left2(20), BL(24)
        // Short win lines - 3-in-a-row involving border positions:
        // Rows including edges:
        [21,9,10],   // not valid - need same row
        // Actually let's do this properly with a flat 5x5 grid:
        // Row 0: 21, 9, 22, ... no
        // 5x5 grid positions:
        // (0,0)=TL=21  (0,1)=top0=9   (0,2)=top1=10  (0,3)=top2=11  (0,4)=TR=22
        // (1,0)=left0=18 (1,1)=cell0=0 (1,2)=cell1=1  (1,3)=cell2=2  (1,4)=right0=12
        // (2,0)=left1=19 (2,1)=cell3=3 (2,2)=cell4=4  (2,3)=cell5=5  (2,4)=right1=13
        // (3,0)=left2=20 (3,1)=cell6=6 (3,2)=cell7=7  (3,3)=cell8=8  (3,4)=right2=14
        // (4,0)=BL=24  (4,1)=bot0=15  (4,2)=bot1=16  (4,3)=bot2=17  (4,4)=BR=23
        // 5x5 rows (y=0..4):
        [21,9,10],[9,10,11],[10,11,22],   // top row triples
        [18,0,1],[0,1,2],[1,2,12],         // row 1 triples
        [19,3,4],[3,4,5],[4,5,13],         // row 2 triples
        [20,6,7],[6,7,8],[7,8,14],         // row 3 triples
        [24,15,16],[15,16,17],[16,17,23],  // bottom row triples
        // 5x5 cols (x=0..4):
        [21,18,19],[18,19,20],[19,20,24],  // left col triples
        [9,0,3],[0,3,6],[3,6,15],          // col 1 triples
        [10,1,4],[1,4,7],[4,7,16],         // col 2 triples
        [11,2,5],[2,5,8],[5,8,17],         // col 3 triples
        [22,12,13],[12,13,14],[13,14,23],  // right col triples
        // 5x5 diagonals (TL->BR):
        [21,0,4],[0,4,23],[21,4,14],[9,1,13],[10,4,14],  // various diag triples TL->BR direction
        [18,3,7],[3,7,17],[19,7,23],[0,4,8],[1,5,23],
        // 5x5 diagonals (TR->BL):
        [22,1,3],[1,3,24],[22,2,19],[11,2,18],[10,3,20],
        [12,4,7],[4,7,20],[13,5,19],[2,4,6],[1,3,15],
    ]

    // Long win lines = pure cell lines (all 3 positions are cells)
    static var longWinLines: [[Int]] { cellWinLines }

    func occupant(posType: PosType, posIndex: Int) -> Player {
        switch posType {
        case .cell: return cells[posIndex]
        case .edge: return edges[posIndex]
        case .intersection: return intersections[posIndex]
        }
    }

    mutating func setOccupant(_ player: Player, posType: PosType, posIndex: Int) {
        switch posType {
        case .cell: cells[posIndex] = player
        case .edge: edges[posIndex] = player
        case .intersection: intersections[posIndex] = player
        }
    }

    // Flat index in 0-24 range
    static func flatIndex(posType: PosType, posIndex: Int) -> Int {
        switch posType {
        case .cell: return posIndex
        case .edge: return 9 + posIndex
        case .intersection: return 21 + posIndex
        }
    }

    func flatOccupant(flatIdx: Int) -> Player {
        if flatIdx < 9 { return cells[flatIdx] }
        else if flatIdx < 21 { return edges[flatIdx - 9] }
        else { return intersections[flatIdx - 21] }
    }

    // Check if this sub-board is won, checking both classic cell lines and extended lines
    func computeStatus(variant: GameVariant) -> BoardStatus {
        if status == .wonP1 || status == .wonP2 { return status }
        // Check long win lines (cells only)
        for (lineIdx, line) in SubBoard.cellWinLines.enumerated() {
            if blockedLongWinLines.contains(lineIdx) { continue }
            let vals = line.map { cells[$0] }
            if vals.allSatisfy({ $0 == .p1 }) { return .wonP1 }
            if vals.allSatisfy({ $0 == .p2 }) { return .wonP2 }
        }
        if variant.isExtended {
            // Check extended win lines
            for line in SubBoard.extendedWinLines {
                let vals = line.map { flatOccupant(flatIdx: $0) }
                if vals.allSatisfy({ $0 == .p1 }) { return .wonP1 }
                if vals.allSatisfy({ $0 == .p2 }) { return .wonP2 }
            }
        }
        // Check for draw: all positions filled
        let allFilled: Bool
        if variant.isExtended {
            allFilled = cells.allSatisfy({ $0 != .empty }) &&
                        edges.allSatisfy({ $0 != .empty }) &&
                        intersections.allSatisfy({ $0 != .empty })
        } else {
            allFilled = cells.allSatisfy({ $0 != .empty })
        }
        return allFilled ? .drawn : .active
    }

    var isEmpty: Bool {
        cells.allSatisfy { $0 == .empty } &&
        edges.allSatisfy { $0 == .empty } &&
        intersections.allSatisfy { $0 == .empty }
    }
}
