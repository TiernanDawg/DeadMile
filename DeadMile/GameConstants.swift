import Foundation
import CoreGraphics

// Central tuning sheet. Keep gameplay and economy adjustments here.
enum Tune {
    static let gravity: CGFloat = -9.8
    static let maxForwardSpeed: CGFloat = 780
    static let engineForce: CGFloat = 1450
    static let reverseForce: CGFloat = 820
    static let airTorque: CGFloat = 5.8
    static let fuelBurnPerSecond: CGFloat = 0.48
    static let baseFuel: CGFloat = 100
    static let baseHealth: CGFloat = 100
    static let zombieSpawnDistance: CGFloat = 510
    static let zombieContactDamage: CGFloat = 5
    static let hitCash: Int = 8
    static let distanceCashPer100: Int = 12
    static let areaBonus: Int = 180
    static let upgradeBaseCost: Int = 110
    static let upgradeCostGrowth: Double = 1.48
    static let cameraLookAhead: CGFloat = 230
    static let maxActiveZombies = 18
    static let maxParticles = 90
    static let lowSpeedEndThreshold: CGFloat = 18
    static let lowSpeedEndDelay: TimeInterval = 2.5
}

struct Biome: Identifiable {
    let id: Int
    let name: String
    let sky: (CGFloat, CGFloat, CGFloat)
    let ground: (CGFloat, CGFloat, CGFloat)
    let accent: (CGFloat, CGFloat, CGFloat)
    let zombieScale: CGFloat
    let areaLengths: [CGFloat]
    static let all: [Biome] = [
        .init(id: 0, name: "DESERT HIGHWAY", sky: (0.22,0.13,0.12), ground: (0.42,0.25,0.15), accent: (0.95,0.55,0.24), zombieScale: 1, areaLengths: [5200,7600,10400]),
        .init(id: 1, name: "GHOST TOWN", sky: (0.13,0.16,0.22), ground: (0.24,0.25,0.28), accent: (0.45,0.66,0.72), zombieScale: 1.05, areaLengths: [6000,8500,11200]),
        .init(id: 2, name: "FOREST ROAD", sky: (0.08,0.17,0.13), ground: (0.19,0.25,0.17), accent: (0.48,0.69,0.34), zombieScale: 1.1, areaLengths: [6500,9000,12000]),
        .init(id: 3, name: "INDUSTRIAL YARD", sky: (0.18,0.18,0.2), ground: (0.29,0.29,0.3), accent: (0.86,0.48,0.22), zombieScale: 1.15, areaLengths: [7000,9800,13000]),
        .init(id: 4, name: "CITY STREETS", sky: (0.12,0.13,0.19), ground: (0.23,0.23,0.27), accent: (0.42,0.62,0.91), zombieScale: 1.2, areaLengths: [7600,10500,13800]),
        .init(id: 5, name: "SUBURBS", sky: (0.22,0.19,0.17), ground: (0.3,0.28,0.22), accent: (0.76,0.65,0.42), zombieScale: 1.22, areaLengths: [8200,11200,14600]),
        .init(id: 6, name: "SNOW PASS", sky: (0.17,0.22,0.29), ground: (0.55,0.59,0.62), accent: (0.7,0.86,0.96), zombieScale: 1.25, areaLengths: [9000,12200,15800]),
        .init(id: 7, name: "HARBOR", sky: (0.08,0.2,0.25), ground: (0.22,0.29,0.31), accent: (0.27,0.72,0.78), zombieScale: 1.3, areaLengths: [9800,13200,17000]),
        .init(id: 8, name: "MILITARY BASE", sky: (0.17,0.2,0.16), ground: (0.25,0.28,0.21), accent: (0.68,0.72,0.35), zombieScale: 1.35, areaLengths: [10800,14500,18500]),
        .init(id: 9, name: "EVACUATION PORT", sky: (0.2,0.13,0.14), ground: (0.29,0.23,0.22), accent: (0.92,0.43,0.32), zombieScale: 1.45, areaLengths: [12000,16000,20500])
    ]
}
