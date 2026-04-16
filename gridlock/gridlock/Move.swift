import Foundation

struct Move: Codable, Hashable, Equatable {
    let boardIndex: Int       // which of the 9 sub-boards
    let posType: PosType
    let posIndex: Int         // index within posType array (0-8 cells, 0-11 edges, 0-3 intersections)
    var routingTarget: Int    // for sender-chooses variants; -1 otherwise
    var chosenBoard: Int      // for edge/intersection moves where opponent picks destination; -1 if N/A

    init(boardIndex: Int, posType: PosType, posIndex: Int, routingTarget: Int = -1, chosenBoard: Int = -1) {
        self.boardIndex = boardIndex
        self.posType = posType
        self.posIndex = posIndex
        self.routingTarget = routingTarget
        self.chosenBoard = chosenBoard
    }
}
