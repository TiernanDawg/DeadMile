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
    var fuelPickups: Int = 0
    var cashPickups: Int = 0
    var boostPickups: Int = 0
    var hiddenKits: Int = 0
    var isExploration: Bool = false
}

struct DailyChallengeSpec {
    enum Metric { case distance, kills, fuelPickups, cashPickups }
    let date: String
    let title: String
    let detail: String
    let metric: Metric
    let target: Int
    let reward: Int

    static func current() -> DailyChallengeSpec {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        let now = Date()
        let date = formatter.string(from: now)
        let day = Calendar.current.ordinality(of: .day, in: .year, for: now) ?? 1
        let options: [(String, String, Metric, Int)] = [
            ("LONG HAUL", "Drive 2,500 meters", .distance, 2500),
            ("CLEAR THE ROAD", "Eliminate 15 infected", .kills, 15),
            ("FUEL SCAVENGER", "Collect 3 fuel cans", .fuelPickups, 3),
            ("CASH RUN", "Collect 5 cash drops", .cashPickups, 5)
        ]
        let option = options[(day - 1) % options.count]
        return DailyChallengeSpec(date: date, title: option.0, detail: option.1, metric: option.2, target: option.3, reward: 450)
    }
}

struct MissionSpec: Identifiable {
    enum Metric {
        case kills, distance, fuelPickups, cashPickups, boostPickups, hiddenKits, runs, cashEarned, areasCleared
    }
    let id: Int
    let title: String
    let detail: String
    let metric: Metric
    let target: Int
    let reward: Int

    static let all: [MissionSpec] = (0..<50).map { index in
        let tier = index / 8 + 1
        let templates: [(String, String, Metric, Int, String)] = [
            ("THIN THE HORDE", "Eliminate", .kills, 8, "infected"),
            ("KEEP ROLLING", "Reach a best distance of", .distance, 1200, "meters"),
            ("FUEL RUNNER", "Collect", .fuelPickups, 2, "fuel cans"),
            ("SCAVENGER", "Collect", .cashPickups, 3, "cash drops"),
            ("FULL THROTTLE", "Collect", .boostPickups, 2, "boost cells"),
            ("ROAD VETERAN", "Complete", .runs, 5, "runs"),
            ("WASTELAND ECONOMY", "Earn", .cashEarned, 1500, "dollars"),
            ("ROUTE CLEARER", "Clear", .areasCleared, 1, "story areas"),
            ("HIDDEN CACHE", "Find", .hiddenKits, 1, "survival kits")
        ]
        let template = templates[index % templates.count]
        let target = template.3 * tier
        return MissionSpec(
            id: index,
            title: "\(template.0) · \(String(format: "%02d", index + 1))",
            detail: "\(template.1) \(target) \(template.4)",
            metric: template.2,
            target: target,
            reward: 100 + index * 30
        )
    }
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
    var totalFuelPickups = 0
    var totalCashPickups = 0
    var totalBoostPickups = 0
    var totalHiddenKits = 0
    var lifetimeCashEarned = 0
    var areasCleared = 0
    var claimedMissions: Set<Int> = []
    var missionStars: [Int: Int] = [:]
    var dailyChallengeDate = ""
    var dailyChallengeProgress = 0
    var dailyChallengeClaimed = false

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

    func missionProgress(_ mission: MissionSpec) -> Int {
        switch mission.metric {
        case .kills: return totalKills
        case .distance: return bestDistance
        case .fuelPickups: return totalFuelPickups
        case .cashPickups: return totalCashPickups
        case .boostPickups: return totalBoostPickups
        case .hiddenKits: return totalHiddenKits
        case .runs: return runs
        case .cashEarned: return lifetimeCashEarned
        case .areasCleared: return areasCleared
        }
    }

    func finish(_ record: RunRecord) {
        runs += 1
        totalKills += record.kills
        totalFuelPickups += record.fuelPickups
        totalCashPickups += record.cashPickups
        totalBoostPickups += record.boostPickups
        totalHiddenKits += record.hiddenKits
        lifetimeCashEarned += record.earned
        bestDistance = max(bestDistance, record.distance)
        cash += record.earned
        let challenge = DailyChallengeSpec.current()
        if dailyChallengeDate != challenge.date {
            dailyChallengeDate = challenge.date
            dailyChallengeProgress = 0
            dailyChallengeClaimed = false
        }
        let challengeGain: Int
        switch challenge.metric {
        case .distance: challengeGain = record.distance
        case .kills: challengeGain = record.kills
        case .fuelPickups: challengeGain = record.fuelPickups
        case .cashPickups: challengeGain = record.cashPickups
        }
        dailyChallengeProgress += max(0, challengeGain)
        if !dailyChallengeClaimed && dailyChallengeProgress >= challenge.target {
            dailyChallengeClaimed = true
            cash += challenge.reward
        }

        if !record.isExploration {
            let key = "\(record.level)-\(record.area)"
            let old = areaProgress[key, default: 0]
            let biome = Biome.all[min(max(record.level, 0), 9)]
            let requiredDistance = Int(biome.areaLengths[min(max(record.area, 0), 2)])
            if record.distance >= requiredDistance {
                if old == 0 {
                    areasCleared += 1
                    cash += Tune.areaBonus * (record.level + 1)
                }
                areaProgress[key] = 1
                if record.area >= 2 { unlockedLevel = max(unlockedLevel, min(9, record.level + 1)) }
            }

            if record.level == 0 && record.area >= 2 && areaProgress[key, default: 0] > 0 {
                missionsUnlocked = true
            }
            if record.level >= 9 && record.area >= 2 && areaProgress[key, default: 0] > 0 {
                explorationUnlocked = true
            }
        }
        if missionsUnlocked {
            for mission in MissionSpec.all {
                let value = missionProgress(mission)
                let stars = min(3, value / max(1, mission.target))
                if stars > missionStars[mission.id, default: 0] { missionStars[mission.id] = stars }
                if !claimedMissions.contains(mission.id) && value >= mission.target {
                    claimedMissions.insert(mission.id)
                    cash += mission.reward
                }
            }
        }
        save()
    }

    func claimDaily() -> Int {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())
        guard today != lastDailyClaim else { return 0 }
        lastDailyClaim = today
        let reward = 250 + min(runs, 20) * 10
        cash += reward
        save()
        return reward
    }

    func reset() {
        cash = 450
        bestDistance = 0
        unlockedLevel = 0
        unlockedVehicles = [0]
        selectedVehicle = 0
        upgrades = [:]
        areaProgress = [:]
        totalKills = 0
        runs = 0
        missionsUnlocked = false
        explorationUnlocked = false
        lastDailyClaim = ""
        totalFuelPickups = 0
        totalCashPickups = 0
        totalBoostPickups = 0
        totalHiddenKits = 0
        lifetimeCashEarned = 0
        areasCleared = 0
        claimedMissions = []
        missionStars = [:]
        dailyChallengeDate = ""
        dailyChallengeProgress = 0
        dailyChallengeClaimed = false
        save()
    }

    func importSave(data: Data) -> Bool {
        guard let payload = try? JSONDecoder().decode(SavePayload.self, from: data),
              payload.version == 1,
              payload.cash >= 0,
              payload.bestDistance >= 0,
              (0...9).contains(payload.unlockedLevel),
              payload.totalKills >= 0,
              payload.runs >= 0,
              payload.unlockedVehicles.count <= VehicleSpec.roster.count,
              payload.unlockedVehicles.contains(payload.selectedVehicle),
              Set(payload.unlockedVehicles).isSubset(of: Set(VehicleSpec.roster.map { $0.id })),
              payload.upgrades.count <= VehicleSpec.roster.count * 4,
              payload.upgrades.values.allSatisfy({ (0...5).contains($0) }),
              payload.areaProgress.values.allSatisfy({ (0...1).contains($0) }),
              (payload.totalFuelPickups ?? 0) >= 0,
              (payload.totalCashPickups ?? 0) >= 0,
              (payload.totalBoostPickups ?? 0) >= 0,
              (payload.totalHiddenKits ?? 0) >= 0,
              (payload.lifetimeCashEarned ?? 0) >= 0,
              (payload.areasCleared ?? 0) >= 0,
              (payload.dailyChallengeProgress ?? 0) >= 0,
              (payload.claimedMissions ?? []).allSatisfy({ (0..<50).contains($0) }),
              (payload.missionStars ?? [:]).allSatisfy({ (0..<50).contains($0.key) && (0...3).contains($0.value) }),
              (0.8...1.3).contains(payload.controlScale) else { return false }
        payload.apply(to: self)
        save()
        return true
    }

    func save() {        do {
            let directory = Self.saveURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(SavePayload(progress: self))
            try data.write(to: Self.saveURL, options: .atomic)
        } catch {
            print("Save failed: \(error.localizedDescription)")
        }
    }

    static func load() -> PlayerProgress {
        let value = PlayerProgress()
        guard let data = try? Data(contentsOf: saveURL),
              let payload = try? JSONDecoder().decode(SavePayload.self, from: data) else { return value }
        payload.apply(to: value)
        return value
    }

    private static var saveURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("deadmile-save-v1.json")
    }
}

@MainActor
private struct SavePayload: Codable {
    var version = 1
    var cash: Int
    var bestDistance: Int
    var unlockedLevel: Int
    var unlockedVehicles: [Int]
    var selectedVehicle: Int
    var upgrades: [String: Int]
    var areaProgress: [String: Int]
    var totalKills: Int
    var runs: Int
    var missionsUnlocked: Bool
    var explorationUnlocked: Bool
    var lastDailyClaim: String
    var audioEnabled: Bool
    var hapticsEnabled: Bool
    var largeHUD: Bool
    var controlScale: Double
    var totalFuelPickups: Int?
    var totalCashPickups: Int?
    var totalBoostPickups: Int?
    var totalHiddenKits: Int?
    var lifetimeCashEarned: Int?
    var areasCleared: Int?
    var claimedMissions: [Int]?
    var missionStars: [Int: Int]?
    var dailyChallengeDate: String?
    var dailyChallengeProgress: Int?
    var dailyChallengeClaimed: Bool?

    init(progress p: PlayerProgress) {
        cash = p.cash
        bestDistance = p.bestDistance
        unlockedLevel = p.unlockedLevel
        unlockedVehicles = Array(p.unlockedVehicles)
        selectedVehicle = p.selectedVehicle
        upgrades = p.upgrades
        areaProgress = p.areaProgress
        totalKills = p.totalKills
        runs = p.runs
        missionsUnlocked = p.missionsUnlocked
        explorationUnlocked = p.explorationUnlocked
        lastDailyClaim = p.lastDailyClaim
        audioEnabled = p.audioEnabled
        hapticsEnabled = p.hapticsEnabled
        largeHUD = p.largeHUD
        controlScale = p.controlScale
        totalFuelPickups = p.totalFuelPickups
        totalCashPickups = p.totalCashPickups
        totalBoostPickups = p.totalBoostPickups
        totalHiddenKits = p.totalHiddenKits
        lifetimeCashEarned = p.lifetimeCashEarned
        areasCleared = p.areasCleared
        claimedMissions = Array(p.claimedMissions)
        missionStars = p.missionStars
        dailyChallengeDate = p.dailyChallengeDate
        dailyChallengeProgress = p.dailyChallengeProgress
        dailyChallengeClaimed = p.dailyChallengeClaimed
    }

    func apply(to p: PlayerProgress) {
        guard version == 1 else { return }
        p.cash = cash
        p.bestDistance = bestDistance
        p.unlockedLevel = unlockedLevel
        p.unlockedVehicles = Set(unlockedVehicles)
        p.selectedVehicle = selectedVehicle
        p.upgrades = upgrades
        p.areaProgress = areaProgress
        p.totalKills = totalKills
        p.runs = runs
        p.missionsUnlocked = missionsUnlocked
        p.explorationUnlocked = explorationUnlocked
        p.lastDailyClaim = lastDailyClaim
        p.audioEnabled = audioEnabled
        p.hapticsEnabled = hapticsEnabled
        p.largeHUD = largeHUD
        p.controlScale = controlScale
        p.totalFuelPickups = totalFuelPickups ?? 0
        p.totalCashPickups = totalCashPickups ?? 0
        p.totalBoostPickups = totalBoostPickups ?? 0
        p.totalHiddenKits = totalHiddenKits ?? 0
        p.lifetimeCashEarned = lifetimeCashEarned ?? 0
        p.areasCleared = areasCleared ?? 0
        p.claimedMissions = Set(claimedMissions ?? [])
        p.missionStars = missionStars ?? [:]
        p.dailyChallengeDate = dailyChallengeDate ?? ""
        p.dailyChallengeProgress = dailyChallengeProgress ?? 0
        p.dailyChallengeClaimed = dailyChallengeClaimed ?? false
    }
}
