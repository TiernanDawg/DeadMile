import Foundation
import Observation

struct VehicleSpec: Identifiable, Codable {
    let id: Int
    let name: String
    let mass: Double
    let power: Double
    let armor: Double
    let fuel: Double
    let price: Int
    let width: Double
    let color: String
    static let roster: [VehicleSpec] = [
        .init(id:0,name:"RUSTBUCKET",mass:1,power:1,armor:1,fuel:100,price:0,width:1,color:"#A65F3D"),
        .init(id:1,name:"DUST DEVIL",mass:1.3,power:1.2,armor:1.25,fuel:115,price:900,width:1.15,color:"#B87A42"),
        .init(id:2,name:"RESCUE RIG",mass:1.8,power:1.35,armor:1.8,fuel:125,price:2400,width:1.35,color:"#C84B3D"),
        .init(id:3,name:"NIGHTFALL",mass:1.25,power:1.8,armor:1.15,fuel:110,price:4300,width:1.2,color:"#4D5368"),
        .init(id:4,name:"IRON SCHOOLER",mass:2.1,power:1.5,armor:2.1,fuel:150,price:6900,width:1.55,color:"#C89D3C"),
        .init(id:5,name:"WRECKER",mass:2.3,power:1.8,armor:2.4,fuel:160,price:9800,width:1.5,color:"#68704D"),
        .init(id:6,name:"BULWARK",mass:2.7,power:2.05,armor:3.1,fuel:170,price:14000,width:1.65,color:"#566C78"),
        .init(id:7,name:"LONGHAUL",mass:3.2,power:2.25,armor:3.4,fuel:190,price:19000,width:1.8,color:"#7C6755"),
        .init(id:8,name:"GRAVITY",mass:3.6,power:2.7,armor:3.8,fuel:205,price:26000,width:1.8,color:"#59634C"),
        .init(id:9,name:"LAST WORD",mass:4.2,power:3.1,armor:4.5,fuel:230,price:36000,width:2,color:"#777A83")
    ]
}

struct RunRecord: Codable {
    var distance: Int
    var kills: Int
    var earned: Int
    var level: Int
    var area: Int
}

@Observable
@MainActor
final class PlayerProgress {
    var cash = 450
    var bestDistance = 0
    var unlockedLevel = 0
    var unlockedVehicles: Set<Int> = [0]
    var selectedVehicle = 0
    var upgrades: [String: Int] = [:]
    var areaProgress: [String: Int] = [:]
    var totalKills = 0
    var runs = 0
    var missionsUnlocked = false
    var explorationUnlocked = false
    var lastDailyClaim = ""
    var audioEnabled = true
    var hapticsEnabled = true
    var largeHUD = false
    var controlScale = 1.0

    func tier(_ category: String, vehicle: Int? = nil) -> Int {
        upgrades["\(vehicle ?? selectedVehicle)-\(category)", default: 0]
    }
    func upgradeCost(_ category: String, vehicle: Int? = nil) -> Int {
        let t = tier(category, vehicle: vehicle)
        return Int(Double(Tune.upgradeBaseCost) * pow(Tune.upgradeCostGrowth, Double(t)) * (1 + Double(vehicle ?? selectedVehicle) * 0.16))
    }
    func buyUpgrade(_ category: String) -> Bool {
        let key = "\(selectedVehicle)-\(category)"
        let current = upgrades[key, default: 0]
        guard current < 5 else { return false }
        let cost = upgradeCost(category)
        guard cash >= cost else { return false }
        cash -= cost
        upgrades[key] = current + 1
        save()
        return true
    }
    func buyVehicle(_ id: Int) -> Bool {
        guard let spec = VehicleSpec.roster.first(where: { $0.id == id }), !unlockedVehicles.contains(id), cash >= spec.price else { return false }
        cash -= spec.price
        unlockedVehicles.insert(id)
        selectedVehicle = id
        save()
        return true
    }
    func finish(_ record: RunRecord) {
        runs += 1
        totalKills += record.kills
        bestDistance = max(bestDistance, record.distance)
        cash += record.earned
        let key = "\(record.level)-\(record.area)"
        let old = areaProgress[key, default: 0]
        if record.distance >= Int(Biome.all[min(max(record.level,0),9)].areaLengths[min(max(record.area,0),2)]) {
            areaProgress[key] = max(old, 1)
            unlockedLevel = max(unlockedLevel, min(9, record.level + 1))
            if record.level >= 9 { missionsUnlocked = true; explorationUnlocked = true }
            cash += Tune.areaBonus * (record.level + 1)
        }
        save()
    }
    func claimDaily() -> Int {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withFullDate]
        let today = f.string(from: Date())
        guard today != lastDailyClaim else { return 0 }
        lastDailyClaim = today
        let reward = 250 + min(runs, 20) * 10
        cash += reward
        save()
        return reward
    }
    func save() {
        do {
            let data = try JSONEncoder().encode(SavePayload(progress: self))
            try data.write(to: Self.saveURL, options: .atomic)
        } catch { print("Save failed: \(error.localizedDescription)") }
    }
    static func load() -> PlayerProgress {
        let value = PlayerProgress()
        guard let data = try? Data(contentsOf: saveURL),
              let payload = try? JSONDecoder().decode(SavePayload.self, from: data) else { return value }
        payload.apply(to: value)
        return value
    }
    private static var saveURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("deadmile-save-v1.json")
    }
}

private struct SavePayload: Codable {
    var version = 1
    var cash: Int; var bestDistance: Int; var unlockedLevel: Int; var unlockedVehicles: [Int]
    var selectedVehicle: Int; var upgrades: [String:Int]; var areaProgress: [String:Int]
    var totalKills: Int; var runs: Int; var missionsUnlocked: Bool; var explorationUnlocked: Bool
    var lastDailyClaim: String; var audioEnabled: Bool; var hapticsEnabled: Bool; var largeHUD: Bool; var controlScale: Double
    init(progress p: PlayerProgress) {
        cash=p.cash; bestDistance=p.bestDistance; unlockedLevel=p.unlockedLevel; unlockedVehicles=Array(p.unlockedVehicles)
        selectedVehicle=p.selectedVehicle; upgrades=p.upgrades; areaProgress=p.areaProgress; totalKills=p.totalKills; runs=p.runs
        missionsUnlocked=p.missionsUnlocked; explorationUnlocked=p.explorationUnlocked; lastDailyClaim=p.lastDailyClaim
        audioEnabled=p.audioEnabled; hapticsEnabled=p.hapticsEnabled; largeHUD=p.largeHUD; controlScale=p.controlScale
    }
    func apply(to p: PlayerProgress) {
        guard version == 1 else { return }
        p.cash=cash; p.bestDistance=bestDistance; p.unlockedLevel=unlockedLevel; p.unlockedVehicles=Set(unlockedVehicles)
        p.selectedVehicle=selectedVehicle; p.upgrades=upgrades; p.areaProgress=areaProgress; p.totalKills=totalKills; p.runs=runs
        p.missionsUnlocked=missionsUnlocked; p.explorationUnlocked=explorationUnlocked; p.lastDailyClaim=lastDailyClaim
        p.audioEnabled=audioEnabled; p.hapticsEnabled=hapticsEnabled; p.largeHUD=largeHUD; p.controlScale=controlScale
    }
}
