@preconcurrency import SpriteKit
@preconcurrency import GameController
import UIKit

private enum CollisionLayer {
    static let vehicle: UInt32 = 1
    static let infected: UInt32 = 2
    static let pickup: UInt32 = 4
    static let hazard: UInt32 = 8
    static let projectile: UInt32 = 16
    static let terrain: UInt32 = 32
    static let wheel: UInt32 = 64
}

@MainActor
final class DeadMileScene: SKScene, @preconcurrency SKPhysicsContactDelegate {
    struct Input { var gas=false; var brake=false; var tiltLeft=false; var tiltRight=false; var boost=false; var fire=false }
    struct Result { let distance:Int; let kills:Int; let earned:Int; let fuel:CGFloat; let destroyed:Bool; let fuelPickups:Int; let cashPickups:Int; let boostPickups:Int; let hiddenKits:Int }
    var input = Input()
    var onFinish: ((Result)->Void)?
    var onHUD: ((Int, Int, CGFloat, CGFloat, CGFloat, Int)->Void)?
    var level = 0
    var area = 0
    var explorationMode = false
    var audioEnabled = true
    var hapticsEnabled = true
    var vehicle = VehicleSpec.roster[0]
    var upgradeTiers: [String:Int] = [:]
    private var chassis: SKSpriteNode?
    private var wheels: [SKSpriteNode] = []
    private var wheelJoints: [SKPhysicsJointPin] = []
    private var damageOverlay: SKShapeNode?
    private var hoodPanel: SKShapeNode?
    private var debris: [SKNode] = []
    private var panelDetached = false
    private var detachedWheel = false
    private var cameraNode = SKCameraNode()
    private var fuel: CGFloat = Tune.baseFuel
    private var maxFuel: CGFloat = Tune.baseFuel
    private var health: CGFloat = Tune.baseHealth
    private var maxHealth: CGFloat = Tune.baseHealth
    private var fuelPickups = 0
    private var cashPickups = 0
    private var boostPickups = 0
    private var hiddenKits = 0
    private var lastKit: CGFloat = 0
    private var boost: CGFloat = 0
    private var distance: CGFloat = 0
    private var kills = 0
    private var cash = 0
    private var elapsed: TimeInterval = 0
    private var lowSpeedTime: TimeInterval = 0
    private var ended = false
    private var lastSpawn: CGFloat = 0
    private var lastHazard: CGFloat = 0
    private var lastPickup: CGFloat = 2300
    private var pickupIndex = 3
    private var zombies: [SKSpriteNode] = []
    private var projectiles: [SKNode] = []
    private var lastShotTime: TimeInterval = 0
    private var pickups: [SKNode] = []
    private var hazards: [SKNode] = []
    private var lastHUD: TimeInterval = 0
    private var terrainBodies: [SKNode] = []
    private var randomSeed: UInt64 = 0xDEAD_BEEF

    override func didMove(to view: SKView) {
        backgroundColor = UIColor(red:0.12,green:0.10,blue:0.12,alpha:1)
        physicsWorld.gravity = CGVector(dx:0,dy:Tune.gravity)
        physicsWorld.contactDelegate = self
        camera = cameraNode
        addChild(cameraNode)
        buildBackdrop()
        buildTerrain()
        buildVehicle()
        spawnPickup(at: CGPoint(x:700,y:160), kind: 0)
        spawnPickup(at: CGPoint(x:1450,y:210), kind: 1)
        spawnPickup(at: CGPoint(x:2300,y:170), kind: 2)
    }

    private func buildBackdrop() {
        let biome = Biome.all[min(max(level,0),9)]
        backgroundColor = UIColor(red:biome.sky.0,green:biome.sky.1,blue:biome.sky.2,alpha:1)
        let tileWidth: CGFloat = 2200
        let glowColor = UIColor(red:min(1,biome.accent.0*1.12),green:min(1,biome.accent.1*0.88),blue:min(1,biome.accent.2*0.72),alpha:0.14)

        for tile in -1...5 {
            let glow = SKShapeNode(circleOfRadius:245)
            glow.fillColor = glowColor
            glow.strokeColor = .clear
            glow.position = CGPoint(x:CGFloat(tile)*tileWidth+1650,y:350)
            glow.zPosition = -38
            addChild(glow)
        }

        let distant = UIColor(red:biome.ground.0*0.48,green:biome.ground.1*0.50,blue:biome.ground.2*0.56,alpha:1)
        let mid = UIColor(red:biome.ground.0*0.34,green:biome.ground.1*0.36,blue:biome.ground.2*0.42,alpha:1)
        let near = UIColor(red:biome.ground.0*0.19,green:biome.ground.1*0.22,blue:biome.ground.2*0.26,alpha:1)

        for layer in 0..<3 {
            let group = SKNode()
            group.zPosition = CGFloat(-32 + layer*5)
            for tile in -1...5 {
                let origin = CGFloat(tile)*tileWidth
                if layer == 0 {
                    let ridge = CGMutablePath()
                    ridge.move(to:CGPoint(x:origin,y:-80))
                    ridge.addLine(to:CGPoint(x:origin,y:195))
                    for index in 0...22 {
                        let x = origin + CGFloat(index)*100
                        let peak = 265 + sin(CGFloat(index)*1.37 + CGFloat(level))*72 + cos(CGFloat(index)*0.61)*34
                        ridge.addLine(to:CGPoint(x:x,y:peak))
                    }
                    ridge.addLine(to:CGPoint(x:origin+tileWidth,y:165))
                    ridge.addLine(to:CGPoint(x:origin+tileWidth,y:-80))
                    ridge.closeSubpath()
                    let mountains = SKShapeNode(path:ridge)
                    mountains.fillColor = distant
                    mountains.strokeColor = .clear
                    group.addChild(mountains)
                    for index in 0..<4 {
                        let mesa = SKShapeNode(rectOf:CGSize(width:CGFloat(110+index*23),height:CGFloat(100+index*16)),cornerRadius:12)
                        mesa.fillColor = distant.withAlphaComponent(0.8)
                        mesa.strokeColor = .clear
                        mesa.position = CGPoint(x:origin+CGFloat(index)*545+280,y:130+CGFloat(index%2)*35)
                        group.addChild(mesa)
                    }
                } else if layer == 1 {
                    for index in 0..<13 {
                        let x = origin + CGFloat(index)*174 + CGFloat((index*37+level*19)%54)
                        let width = CGFloat(62+(index*29+level*13)%76)
                        let height = CGFloat(130+(index*53+level*31)%175)
                        let building = SKShapeNode(rectOf:CGSize(width:width,height:height),cornerRadius:4)
                        building.fillColor = mid
                        building.strokeColor = UIColor(white:0.07,alpha:0.28)
                        building.lineWidth = 3
                        building.position = CGPoint(x:x,y:90+height/2)
                        group.addChild(building)
                        let roof = SKShapeNode(rectOf:CGSize(width:width*0.68,height:8),cornerRadius:2)
                        roof.fillColor = near.withAlphaComponent(0.95)
                        roof.strokeColor = .clear
                        roof.position = CGPoint(x:x,y:90+height+5)
                        group.addChild(roof)
                        for row in 0..<max(2,Int(height/42)) {
                            for column in 0..<2 {
                                let window = SKShapeNode(rectOf:CGSize(width:8,height:13),cornerRadius:2)
                                window.fillColor = UIColor(red:biome.accent.0,green:biome.accent.1,blue:biome.accent.2,alpha:0.48)
                                window.strokeColor = .clear
                                window.position = CGPoint(x:x+(column == 0 ? -width*0.22 : width*0.22),y:110+CGFloat(row)*37)
                                group.addChild(window)
                            }
                        }
                    }
                } else {
                    for index in 0..<5 {
                        let x = origin + CGFloat(index)*480 + CGFloat((index*71+level*43)%110)
                        let trunk = SKShapeNode(rectOf:CGSize(width:10,height:120),cornerRadius:3)
                        trunk.fillColor = near
                        trunk.strokeColor = .clear
                        trunk.position = CGPoint(x:x,y:130)
                        group.addChild(trunk)
                        let branches = SKShapeNode()
                        let path = CGMutablePath()
                        path.move(to:CGPoint(x:x,y:165))
                        path.addLine(to:CGPoint(x:x-42,y:230))
                        path.move(to:CGPoint(x:x,y:185))
                        path.addLine(to:CGPoint(x:x+53,y:252))
                        path.move(to:CGPoint(x:x-20,y:207))
                        path.addLine(to:CGPoint(x:x-65,y:218))
                        branches.path = path
                        branches.strokeColor = near
                        branches.lineWidth = 8
                        branches.lineCap = .round
                        group.addChild(branches)
                        let poleX = x+170
                        let pole = SKShapeNode(rectOf:CGSize(width:7,height:205),cornerRadius:2)
                        pole.fillColor = near
                        pole.strokeColor = .clear
                        pole.position = CGPoint(x:poleX,y:170)
                        group.addChild(pole)
                        let arm = SKShapeNode(rectOf:CGSize(width:100,height:7),cornerRadius:2)
                        arm.fillColor = near
                        arm.strokeColor = .clear
                        arm.position = CGPoint(x:poleX,y:250)
                        group.addChild(arm)
                    }
                }
            }
            group.name = "parallax-\(layer)"
            addChild(group)
        }
    }

    private func roadBaseY(at x: CGFloat) -> CGFloat {
        65 + sin(x/420)*32 + cos(x/910)*22 + sin(x/137)*4
    }

    private func roadSurfaceY(at x: CGFloat) -> CGFloat {
        roadBaseY(at:x) + 18
    }

    private func buildTerrain() {
        let biome = Biome.all[min(max(level,0),9)]
        let startX: CGFloat = -1400
        let endX: CGFloat = explorationMode ? 1_000_000 : biome.areaLengths[min(max(area,0),2)] * 10 + 900
        let step: CGFloat = 80
        let centerPath = CGMutablePath()
        let surfacePath = CGMutablePath()
        let fillPath = CGMutablePath()
        var first = true

        for x in stride(from:startX,through:endX+step,by:step) {
            let base = roadBaseY(at:x)
            let center = CGPoint(x:x,y:base)
            let surface = CGPoint(x:x,y:base+18)
            if first {
                centerPath.move(to:center)
                surfacePath.move(to:surface)
                fillPath.move(to:CGPoint(x:startX,y:-700))
                fillPath.addLine(to:surface)
                first = false
            } else {
                centerPath.addLine(to:center)
                surfacePath.addLine(to:surface)
                fillPath.addLine(to:surface)
            }
        }
        fillPath.addLine(to:CGPoint(x:endX+step,y:-700))
        fillPath.closeSubpath()

        let earth = SKShapeNode(path:fillPath)
        earth.fillColor = UIColor(red:biome.ground.0*0.70,green:biome.ground.1*0.72,blue:biome.ground.2*0.76,alpha:1)
        earth.strokeColor = .clear
        earth.zPosition = 0
        addChild(earth)

        let asphalt = SKShapeNode(path:centerPath)
        asphalt.strokeColor = UIColor(red:0.105,green:0.12,blue:0.13,alpha:1)
        asphalt.lineWidth = 42
        asphalt.lineCap = .round
        asphalt.lineJoin = .round
        asphalt.zPosition = 2
        addChild(asphalt)

        let edge = SKShapeNode(path:surfacePath)
        edge.strokeColor = UIColor(red:biome.accent.0,green:biome.accent.1,blue:biome.accent.2,alpha:0.95)
        edge.lineWidth = 4
        edge.zPosition = 3
        addChild(edge)

        let decorationEnd = min(endX,CGFloat(48000))
        for x in stride(from:CGFloat(0),through:decorationEnd,by:280) {
            let marker = SKShapeNode(rectOf:CGSize(width:48,height:4),cornerRadius:2)
            marker.fillColor = UIColor(red:0.92,green:0.78,blue:0.47,alpha:0.85)
            marker.strokeColor = .clear
            marker.position = CGPoint(x:x,y:roadBaseY(at:x)+5)
            marker.zRotation = atan2(roadBaseY(at:x+20)-roadBaseY(at:x-20),40)
            marker.zPosition = 3
            addChild(marker)
        }

        for x in stride(from:CGFloat(-300),through:decorationEnd,by:205) {
            let size = CGFloat(8 + (Int(abs(x/205)) % 4)*4)
            let pebble = SKShapeNode(ellipseOf:CGSize(width:size,height:5))
            pebble.fillColor = UIColor(white:0.11,alpha:0.52)
            pebble.strokeColor = .clear
            pebble.position = CGPoint(x:x,y:roadBaseY(at:x)-39)
            pebble.zPosition = 1
            addChild(pebble)
        }

        let physicsGround = SKNode()
        physicsGround.physicsBody = SKPhysicsBody(edgeChainFrom:surfacePath)
        physicsGround.physicsBody?.categoryBitMask = CollisionLayer.terrain
        physicsGround.physicsBody?.collisionBitMask = CollisionLayer.vehicle | CollisionLayer.wheel
        physicsGround.physicsBody?.friction = 1.7
        physicsGround.physicsBody?.restitution = 0.015
        addChild(physicsGround)
        terrainBodies.append(physicsGround)
    }

    private func buildVehicle() {
        let width=CGFloat(150*vehicle.width)
        maxFuel = CGFloat(vehicle.fuel) + CGFloat(upgradeTiers["fuel",default:0]) * 15
        fuel = maxFuel
        maxHealth = Tune.baseHealth * CGFloat(vehicle.armor) * (1 + CGFloat(upgradeTiers["armor",default:0]) * 0.2)
        health = maxHealth
        let car=SKSpriteNode(texture:ArtFactory.vehicle(colorHex:vehicle.color,style:vehicle.id),size:CGSize(width:width,height:65))
        car.position=CGPoint(x:150,y:roadSurfaceY(at:150)+42); car.zPosition=10
        car.physicsBody=SKPhysicsBody(rectangleOf:CGSize(width:width*0.82,height:35))
        car.physicsBody?.mass=CGFloat(vehicle.mass*4.2)
        car.physicsBody?.allowsRotation=true
        car.physicsBody?.linearDamping=0.12
        car.physicsBody?.angularDamping=0.42
        car.physicsBody?.friction=0.9
        car.physicsBody?.categoryBitMask=CollisionLayer.vehicle
        car.physicsBody?.contactTestBitMask=CollisionLayer.infected | CollisionLayer.pickup | CollisionLayer.hazard
        car.physicsBody?.collisionBitMask=CollisionLayer.terrain | CollisionLayer.infected | CollisionLayer.hazard
        addChild(car); chassis=car
        let damagePath = CGMutablePath()
        damagePath.move(to:CGPoint(x:-42,y:12))
        damagePath.addLine(to:CGPoint(x:-18,y:-2))
        damagePath.addLine(to:CGPoint(x:2,y:10))
        damagePath.addLine(to:CGPoint(x:22,y:-8))
        damagePath.addLine(to:CGPoint(x:43,y:8))
        let damage = SKShapeNode(path:damagePath)
        damage.strokeColor = UIColor(red:0.75,green:0.12,blue:0.08,alpha:1)
        damage.lineWidth = 3
        damage.alpha = 0
        damage.zPosition = 8
        car.addChild(damage)
        damageOverlay = damage
        let hood = SKShapeNode(rectOf:CGSize(width:38,height:8),cornerRadius:2)
        hood.fillColor = UIColor(white:0.42,alpha:1)
        hood.strokeColor = UIColor(white:0.8,alpha:1)
        hood.lineWidth = 1.5
        hood.position = CGPoint(x:-42,y:27)
        hood.zPosition = 5
        car.addChild(hood)
        hoodPanel = hood
        if upgradeTiers["weapon",default:0] > 0 {
            let mount = SKShapeNode(rectOf:CGSize(width:34,height:10),cornerRadius:3)
            mount.fillColor = UIColor(white:0.22,alpha:1)
            mount.strokeColor = UIColor(white:0.7,alpha:1)
            mount.lineWidth = 2
            mount.position = CGPoint(x:48,y:35)
            mount.zPosition = 3
            car.addChild(mount)
            let barrel = SKShapeNode(rectOf:CGSize(width:35,height:5),cornerRadius:2)
            barrel.fillColor = UIColor(white:0.12,alpha:1)
            barrel.strokeColor = .white
            barrel.position = CGPoint(x:76,y:41)
            barrel.zPosition = 4
            car.addChild(barrel)
        }
        for x in [-width*0.28,width*0.28] {
            let wheel=SKSpriteNode(texture:wheelTexture(),size:CGSize(width:36,height:36))
            wheel.position=CGPoint(x:car.position.x+x,y:car.position.y-26); wheel.zPosition=11
            wheel.physicsBody=SKPhysicsBody(circleOfRadius:15)
            wheel.physicsBody?.mass=CGFloat(vehicle.mass*0.45)
            wheel.physicsBody?.friction=2.4
            wheel.physicsBody?.linearDamping=0.18
            wheel.physicsBody?.restitution=0.02
            wheel.physicsBody?.allowsRotation=true
            wheel.physicsBody?.categoryBitMask=CollisionLayer.wheel
            wheel.physicsBody?.collisionBitMask=CollisionLayer.terrain
            wheel.physicsBody?.contactTestBitMask=0
            addChild(wheel); wheels.append(wheel)
            if let a=car.physicsBody, let b=wheel.physicsBody {
                let joint=SKPhysicsJointPin.joint(withBodyA:a,bodyB:b,anchor:wheel.position)
                joint.rotationSpeed = 0
                joint.frictionTorque = 42
                physicsWorld.add(joint)
                wheelJoints.append(joint)
            }
        }
    }

    private func wheelTexture() -> SKTexture {
        let node=SKShapeNode(circleOfRadius:16); node.fillColor=UIColor(white:0.07,alpha:1); node.strokeColor=UIColor(white:0.55,alpha:1); node.lineWidth=4
        let renderer=UIGraphicsImageRenderer(size:CGSize(width:40,height:40))
        let image=renderer.image { _ in
            UIColor(white:0.08,alpha:1).setFill(); UIBezierPath(ovalIn:CGRect(x:2,y:2,width:36,height:36)).fill()
            UIColor(white:0.55,alpha:1).setStroke(); let p=UIBezierPath(ovalIn:CGRect(x:9,y:9,width:22,height:22)); p.lineWidth=4; p.stroke()
            UIColor(white:0.75,alpha:1).setFill(); UIBezierPath(ovalIn:CGRect(x:17,y:17,width:6,height:6)).fill()
        }
        _ = node
        return SKTexture(image:image)
    }

    override func update(_ currentTime: TimeInterval) {
        guard !ended, let car=chassis, let body=car.physicsBody else { return }
        let dt=min(max(currentTime-(elapsed == 0 ? currentTime : elapsed),0),1.0/20.0)
        elapsed=currentTime
        let speed=abs(body.velocity.dx)
        let pad = GCController.controllers().first?.extendedGamepad
        let gasPressed = input.gas || (pad?.rightTrigger.value ?? 0) > 0.15
        let brakePressed = input.brake || (pad?.leftTrigger.value ?? 0) > 0.15
        let stickX = pad?.leftThumbstick.xAxis.value ?? 0
        let tiltLeftPressed = input.tiltLeft || stickX < -0.25
        let tiltRightPressed = input.tiltRight || stickX > 0.25
        let boostPressed = input.boost || (pad?.buttonB.isPressed ?? false)
        let firePressed = input.fire || (pad?.buttonA.isPressed ?? false)
        FeedbackService.shared.updateEngine(speed:speed,audio:audioEnabled,biome:level)
        let engine=CGFloat(vehicle.power)*(1+CGFloat(upgradeTiers["engine",default:0])*0.18)
        let reverseDrive = brakePressed && speed < 35 && fuel > 0
        for joint in wheelJoints {
            if gasPressed && fuel > 0 {
                joint.rotationSpeed = -min(46,(speed+135)/15)
                joint.frictionTorque = 58 * engine
            } else if reverseDrive {
                joint.rotationSpeed = 8.5
                joint.frictionTorque = 46
            } else {
                joint.rotationSpeed = 0
                joint.frictionTorque = 72
            }
        }
        if gasPressed && fuel>0 {
            body.applyForce(CGVector(dx:Tune.engineForce*engine,dy:0))
            fuel=max(0,fuel-Tune.fuelBurnPerSecond*(1+engine*0.08)*dt)
        }
        if brakePressed {
            if speed>35 { body.applyForce(CGVector(dx:-Tune.reverseForce*CGFloat(vehicle.mass),dy:0)) }
            else if fuel>0 { body.applyForce(CGVector(dx:-Tune.reverseForce*0.55,dy:0)); fuel=max(0,fuel-Tune.fuelBurnPerSecond*dt) }
        }
        if tiltLeftPressed { body.applyTorque(Tune.airTorque*body.mass) }
        if tiltRightPressed { body.applyTorque(-Tune.airTorque*body.mass) }
        if firePressed && upgradeTiers["weapon",default:0] > 0 {
            let tier = upgradeTiers["weapon",default:0]
            let cooldown = max(0.16,0.48-Double(tier)*0.055)
            if currentTime-lastShotTime >= cooldown {
                lastShotTime = currentTime
                fireWeapon(from:car.position,tier:tier)
            }
        }
        if boostPressed && boost>0 && fuel>0 {
            body.applyForce(CGVector(dx:2200*CGFloat(vehicle.power),dy:0))
            boost=max(0,boost-dt*24)
            fuel=max(0,fuel-dt*2)
            if Int(currentTime*12) % 3 == 0 { emitDust(at:car.position,color:.cyan) }
        }
        if body.velocity.dx > Tune.maxForwardSpeed { body.velocity.dx=Tune.maxForwardSpeed }
        if body.velocity.dx < -Tune.maxForwardSpeed*0.45 { body.velocity.dx = -Tune.maxForwardSpeed*0.45 }
        distance=max(distance,car.position.x-150)
        if explorationMode && car.position.x-lastKit > 6500 {
            lastKit = car.position.x
            let kitX = car.position.x+CGFloat.random(in:700...1100)
            spawnPickup(at: CGPoint(x:kitX,y:roadSurfaceY(at:kitX)+34), kind:4)
        }
        if car.position.x-lastPickup > 1900 {
            lastPickup = car.position.x
            let pickupX = car.position.x+650
            spawnPickup(at: CGPoint(x:pickupX,y:roadSurfaceY(at:pickupX)+34), kind:pickupIndex % 4)
            pickupIndex += 1
        }
        if car.position.x-lastSpawn > Tune.zombieSpawnDistance && zombies.count<Tune.maxActiveZombies {
            lastSpawn=car.position.x
            let zombieX = car.position.x+CGFloat.random(in:360...650)
            spawnZombie(at:CGPoint(x:zombieX,y:roadSurfaceY(at:zombieX)+28))
        }
        if car.position.x-lastHazard > 1450 && hazards.count < 8 {
            lastHazard = car.position.x
            let hazardX = car.position.x + CGFloat.random(in:520...820)
            spawnHazard(at:CGPoint(x:hazardX,y:roadSurfaceY(at:hazardX)+22))
        }
        for zombie in zombies {
            let delta = car.position.x - zombie.position.x
            let direction: CGFloat = delta < 0 ? -1 : 1
            let variant = zombie.userData?["variant"] as? Int ?? 0
            let speeds:[CGFloat] = [24,52,17,22,20,65,13,26,19,40]
            let chaseSpeed = speeds[min(max(variant,0),speeds.count-1)] + CGFloat(min(level, 9) * 3)
            var separation: CGFloat = 0
            for other in zombies where other !== zombie {
                let gap = zombie.position.x - other.position.x
                if abs(gap) < 64 { separation += gap >= 0 ? 13 : -13 }
            }
            zombie.physicsBody?.velocity.dx = max(-92, min(92, direction * chaseSpeed + separation))
        }
        for zombie in zombies where zombie.position.x < cameraNode.position.x-850 { zombie.removeFromParent() }
        for projectile in projectiles where projectile.position.x > cameraNode.position.x+1000 || projectile.position.x < cameraNode.position.x-1000 { projectile.removeFromParent() }
        projectiles.removeAll { $0.parent == nil }
        zombies.removeAll { $0.parent == nil }
        for hazard in hazards where hazard.position.x < cameraNode.position.x-850 { hazard.removeFromParent() }
        for item in debris where item.position.x < cameraNode.position.x-850 { item.removeFromParent() }
        debris.removeAll { $0.parent == nil }
        hazards.removeAll { $0.parent == nil }
        cameraNode.position=CGPoint(x:max(0,car.position.x+Tune.cameraLookAhead),y:max(80,car.position.y+42))
        for node in children where node.name?.hasPrefix("parallax-") == true {
            let layer=CGFloat(Int(node.name.map { String($0.suffix(1)) } ?? "0") ?? 0)
            let parallax=0.08 + layer * 0.10
            let tileWidth:CGFloat=2200
            let wraps=floor(cameraNode.position.x * parallax / tileWidth)
            node.position.x = cameraNode.position.x * (1 - parallax) + wraps * tileWidth
        }
        if speed < Tune.lowSpeedEndThreshold && fuel <= 0 { lowSpeedTime += dt } else { lowSpeedTime=0 }
        damageOverlay?.alpha = max(0,min(0.9,1 - health / max(1,maxHealth)))
        if !panelDetached && health <= maxHealth * 0.58, let panel = hoodPanel, let car = chassis {
            panel.position = car.convert(panel.position, to:self)
            panel.removeFromParent()
            panel.zPosition = 14
            panel.physicsBody = SKPhysicsBody(rectangleOf:CGSize(width:38,height:8))
            panel.physicsBody?.mass = 0.35
            panel.physicsBody?.isDynamic = true
            panel.physicsBody?.allowsRotation = true
            panel.physicsBody?.velocity = car.physicsBody?.velocity ?? .zero
            addChild(panel)
            debris.append(panel)
            hoodPanel = nil
            panelDetached = true
        }
        if !detachedWheel && health <= maxHealth * 0.28, let joint = wheelJoints.popLast() {
            physicsWorld.remove(joint)
            detachedWheel = true
            wheels.last?.name = "detached-wheel"
            emitDust(at:car.position,color:.orange)
        }
        if health <= 0 || (fuel <= 0 && lowSpeedTime > Tune.lowSpeedEndDelay) { finish(destroyed:health<=0) }
        if currentTime-lastHUD > 0.12 {
            lastHUD=currentTime
            onHUD?(Int(distance/10),Int(speed*0.22),maxFuel > 0 ? fuel / maxFuel * 100 : 0,maxHealth > 0 ? health / maxHealth * 100 : 0,boost,cash)
        }
        if car.position.y < -240 { health=0 }
    }

    private func fireWeapon(from point: CGPoint, tier: Int) {
        let bullet = SKShapeNode(circleOfRadius: tier >= 4 ? 6 : 4)
        bullet.fillColor = tier >= 3 ? .systemCyan : .systemYellow
        bullet.strokeColor = .white
        bullet.lineWidth = 1
        bullet.position = CGPoint(x:point.x+88,y:point.y+13)
        bullet.zPosition = 20
        bullet.name = "bullet"
        let body = SKPhysicsBody(circleOfRadius:tier >= 4 ? 6 : 4)
        body.isDynamic = true
        body.affectedByGravity = false
        body.allowsRotation = false
        body.categoryBitMask = CollisionLayer.projectile
        body.contactTestBitMask = CollisionLayer.infected
        body.collisionBitMask = 0
        bullet.physicsBody = body
        addChild(bullet)
        projectiles.append(bullet)
        body.velocity = CGVector(dx:900+CGFloat(tier)*180,dy:0)
    }

    private func spawnZombie(at point:CGPoint) {
        let variant=Int.random(in:0..<10)
        let scale=Biome.all[min(max(level,0),9)].zombieScale
        let widths:[CGFloat] = [44,39,54,44,44,36,58,44,50,50]
        let heights:[CGFloat] = [65,62,72,65,65,66,75,68,70,42]
        let baseWidth = widths[variant]
        let baseHeight = heights[variant]
        let zombie=SKSpriteNode(texture:ArtFactory.zombie(variant:variant),size:CGSize(width:baseWidth*scale,height:baseHeight*scale))
        zombie.position=point; zombie.zPosition=8; zombie.name="zombie"
        let bodyWidths:[CGFloat] = [28,24,38,28,30,22,44,28,36,38]
        let bodyHeights:[CGFloat] = [48,42,56,48,50,44,62,52,58,24]
        zombie.physicsBody=SKPhysicsBody(rectangleOf:CGSize(width:bodyWidths[variant]*scale,height:bodyHeights[variant]*scale))
        let masses:[CGFloat] = [0.9,0.65,2.8,1.4,1.8,0.55,3.5,1.2,2.6,0.8]
        zombie.physicsBody?.mass=masses[variant] * scale
        let metadata=NSMutableDictionary()
        metadata["variant"] = variant
        metadata["hp"] = variant == 8 ? 3 : (variant == 6 ? 2 : 1)
        zombie.userData=metadata
        zombie.physicsBody?.linearDamping=0.7
        zombie.physicsBody?.angularDamping=0.8
        zombie.physicsBody?.isDynamic=true
        zombie.physicsBody?.allowsRotation=true
        zombie.physicsBody?.categoryBitMask=CollisionLayer.infected
        zombie.physicsBody?.contactTestBitMask=CollisionLayer.vehicle
        zombie.physicsBody?.collisionBitMask=CollisionLayer.vehicle | CollisionLayer.terrain
        addChild(zombie); zombies.append(zombie)
    }

    private func spawnHazard(at point:CGPoint) {
        let kind = Int.random(in:0..<3)
        let node: SKShapeNode
        switch kind {
        case 0:
            node = SKShapeNode(rectOf:CGSize(width:54,height:38),cornerRadius:5)
            node.fillColor = UIColor(red:0.38,green:0.22,blue:0.13,alpha:1)
            node.strokeColor = UIColor(red:0.76,green:0.52,blue:0.29,alpha:1)
            node.lineWidth = 4
        case 1:
            node = SKShapeNode(circleOfRadius:25)
            node.fillColor = UIColor(white:0.16,alpha:1)
            node.strokeColor = UIColor(white:0.48,alpha:1)
            node.lineWidth = 6
        default:
            let path = CGMutablePath()
            path.move(to:CGPoint(x:-34,y:-16))
            path.addLine(to:CGPoint(x:-18,y:22))
            path.addLine(to:CGPoint(x:-3,y:-16))
            path.addLine(to:CGPoint(x:14,y:22))
            path.addLine(to:CGPoint(x:31,y:-16))
            path.closeSubpath()
            node = SKShapeNode(path:path)
            node.fillColor = UIColor(red:0.58,green:0.55,blue:0.48,alpha:1)
            node.strokeColor = .white
            node.lineWidth = 2
        }
        node.position = point
        node.zPosition = 7
        node.name = "hazard"
        node.physicsBody = kind == 1
            ? SKPhysicsBody(circleOfRadius:25)
            : SKPhysicsBody(rectangleOf:CGSize(width:kind == 2 ? 64 : 54,height:kind == 2 ? 38 : 38))
        node.physicsBody?.isDynamic = false
        node.physicsBody?.categoryBitMask = CollisionLayer.hazard
        node.physicsBody?.contactTestBitMask = CollisionLayer.vehicle
        node.physicsBody?.collisionBitMask = CollisionLayer.vehicle
        addChild(node)
        hazards.append(node)
    }

    private func spawnPickup(at point:CGPoint,kind:Int) {
        let colors:[UIColor]=[.systemGreen,.systemYellow,.systemCyan,.systemRed,.systemOrange]
        let node: SKShapeNode = kind == 4 ? SKShapeNode(rectOf:CGSize(width:34,height:28),cornerRadius:4) : SKShapeNode(circleOfRadius:15)
        node.fillColor = colors[kind % colors.count]
        node.strokeColor = .white
        node.lineWidth = 3
        node.position=point; node.zPosition=12; node.name="pickup-\(kind)"
        node.physicsBody=SKPhysicsBody(circleOfRadius:15); node.physicsBody?.isDynamic=false
        node.physicsBody?.categoryBitMask=CollisionLayer.pickup; node.physicsBody?.contactTestBitMask=CollisionLayer.vehicle; node.physicsBody?.collisionBitMask=0
        addChild(node); pickups.append(node)
    }

    func didBegin(_ contact:SKPhysicsContact) {
        let a=contact.bodyA.node, b=contact.bodyB.node
        if let zombie=(a?.name=="zombie" ? a : b?.name=="zombie" ? b : nil) {
            let bullet = a?.name == "bullet" ? a : (b?.name == "bullet" ? b : nil)
            let variant = zombie.userData?["variant"] as? Int ?? 0
            let hp = zombie.userData?["hp"] as? Int ?? 1
            if bullet != nil && hp > 1 {
                zombie.userData?["hp"] = hp - 1
                if let sprite = zombie as? SKSpriteNode {
                    sprite.color = .red
                    sprite.colorBlendFactor = 0.65
                }
                bullet?.removeFromParent()
                projectiles.removeAll { $0 === bullet }
                emitDust(at:zombie.position,color:.orange)
            } else {
                let impact=abs(contact.collisionImpulse)
                kills += 1
                FeedbackService.shared.hit(audio:audioEnabled,haptics:hapticsEnabled)
                cash += Tune.hitCash + Int(min(impact/80,20))
                emitDust(at:zombie.position,color:UIColor(red:0.56,green:0.72,blue:0.48,alpha:1))
                zombie.removeFromParent()
                zombies.removeAll { $0 === zombie }
                if let bullet {
                    bullet.removeFromParent()
                    projectiles.removeAll { $0 === bullet }
                } else if impact < 18 {
                    let multiplier: CGFloat = variant == 6 ? 2.0 : (variant == 7 ? 1.5 : 1.0)
                    health=max(0,health-Tune.zombieContactDamage*multiplier)
                }
            }
        }
        if let hazard = (a?.name == "hazard" ? a : b?.name == "hazard" ? b : nil) {
            hazard.name = "hazard-spent"
            let damage = min(32, 12 + Int(contact.collisionImpulse / 180))
            health = max(0, health - CGFloat(damage))
            FeedbackService.shared.hit(audio:audioEnabled,haptics:hapticsEnabled)
            emitDust(at:hazard.position,color:UIColor(red:0.72,green:0.42,blue:0.24,alpha:1))
            hazard.removeFromParent()
            hazards.removeAll { $0 === hazard }
        }
        if let pickup=(a?.name?.hasPrefix("pickup-")==true ? a : b?.name?.hasPrefix("pickup-")==true ? b : nil) {
            let kind=Int(pickup.name?.replacingOccurrences(of:"pickup-",with:"") ?? "0") ?? 0
            if kind==0 { fuel=min(maxFuel,fuel+28); fuelPickups += 1 }
            if kind==1 { cash += 75; cashPickups += 1 }
            if kind==2 { boost=min(100,boost+55); boostPickups += 1 }
            if kind==3 { health=min(maxHealth,health+35) }
            if kind==4 { hiddenKits += 1; cash += 250; fuel=min(maxFuel,fuel+18); health=min(maxHealth,health+15); boost=min(100,boost+25) }
            FeedbackService.shared.pickup(audio:audioEnabled,haptics:hapticsEnabled)
            emitDust(at:pickup.position,color:.yellow); pickup.removeFromParent(); pickups.removeAll { $0 === pickup }
        }
    }

    private func emitDust(at point:CGPoint,color:UIColor) {
        for _ in 0..<7 {
            let p=SKShapeNode(circleOfRadius:CGFloat.random(in:2...5))
            p.fillColor=color.withAlphaComponent(0.75); p.strokeColor = .clear
            p.position=point; p.zPosition=30; addChild(p)
            let move=SKAction.moveBy(x:CGFloat.random(in:-38...38),y:CGFloat.random(in:8...42),duration:0.35)
            p.run(.sequence([move,.fadeOut(withDuration:0.18),.removeFromParent()]))
        }
    }

    func resetRun() {
        isPaused = false
        input = Input()
        cameraNode.position = .zero
        for joint in wheelJoints { physicsWorld.remove(joint) }
        removeAllChildren()
        zombies.removeAll(); projectiles.removeAll(); pickups.removeAll(); hazards.removeAll(); debris.removeAll(); wheels.removeAll(); wheelJoints.removeAll(); terrainBodies.removeAll()
        chassis = nil
        damageOverlay = nil
        hoodPanel = nil
        panelDetached = false
        detachedWheel = false
        maxFuel = CGFloat(vehicle.fuel) + CGFloat(upgradeTiers["fuel",default:0]) * 15
        fuel = maxFuel
        maxHealth = Tune.baseHealth * CGFloat(vehicle.armor) * (1 + CGFloat(upgradeTiers["armor",default:0]) * 0.2)
        health = maxHealth
        boost = 0; distance = 0
        kills = 0; cash = 0; fuelPickups = 0; cashPickups = 0; boostPickups = 0; hiddenKits = 0; lastKit = 0; elapsed = 0; lowSpeedTime = 0; lastSpawn = 0; lastHazard = 0; lastPickup = 2300; pickupIndex = 3; lastHUD = 0; lastShotTime = 0; ended = false
        didMove(to: view ?? SKView())
    }

    private func finish(destroyed:Bool) {
        guard !ended else { return }
        ended=true
        FeedbackService.shared.stopEngine()
        let result=Result(distance:Int(distance/10),kills:kills,earned:cash+Int(distance/1000)*Tune.distanceCashPer100,fuel:fuel,destroyed:destroyed,fuelPickups:fuelPickups,cashPickups:cashPickups,boostPickups:boostPickups,hiddenKits:hiddenKits)
        onFinish?(result)
        isPaused=true
    }
}
