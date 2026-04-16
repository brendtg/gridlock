import SwiftUI
import Observation

@Observable
final class SettingsStore {
    var soundEffectsEnabled: Bool = true {
        didSet { UserDefaults.standard.set(soundEffectsEnabled, forKey: "soundEffectsEnabled") }
    }
    var hapticsEnabled: Bool = true {
        didSet { UserDefaults.standard.set(hapticsEnabled, forKey: "hapticsEnabled") }
    }
    var showRoutingAnimation: Bool = true {
        didSet { UserDefaults.standard.set(showRoutingAnimation, forKey: "showRoutingAnimation") }
    }
    var showConfirmButton: Bool = true {
        didSet { UserDefaults.standard.set(showConfirmButton, forKey: "showConfirmButton") }
    }
    var autoZoom: Bool = true {
        didSet { UserDefaults.standard.set(autoZoom, forKey: "autoZoom") }
    }
    var pieRuleDefault: Bool = false {
        didSet { UserDefaults.standard.set(pieRuleDefault, forKey: "pieRuleDefault") }
    }
    var player1Name: String = "Player 1" {
        didSet { UserDefaults.standard.set(player1Name, forKey: "player1Name") }
    }
    var player2Name: String = "Player 2" {
        didSet { UserDefaults.standard.set(player2Name, forKey: "player2Name") }
    }

    init() {
        let ud = UserDefaults.standard
        if let v = ud.object(forKey: "soundEffectsEnabled") as? Bool { soundEffectsEnabled = v }
        if let v = ud.object(forKey: "hapticsEnabled") as? Bool { hapticsEnabled = v }
        if let v = ud.object(forKey: "showRoutingAnimation") as? Bool { showRoutingAnimation = v }
        if let v = ud.object(forKey: "showConfirmButton") as? Bool { showConfirmButton = v }
        if let v = ud.object(forKey: "autoZoom") as? Bool { autoZoom = v }
        if let v = ud.object(forKey: "pieRuleDefault") as? Bool { pieRuleDefault = v }
        if let v = ud.string(forKey: "player1Name") { player1Name = v }
        if let v = ud.string(forKey: "player2Name") { player2Name = v }
    }

    func playerName(for player: Player) -> String {
        player == .p1 ? player1Name : player2Name
    }
}
