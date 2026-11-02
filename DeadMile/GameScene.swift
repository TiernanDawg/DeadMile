@preconcurrency import SpriteKit
import UIKit

@MainActor
final class DeadMileScene: SKScene, SKPhysicsContactDelegate {
    struct Input { var gas=false; var brake=false; var tiltLeft=false; var tiltRight=false; var boost=false }
    struct Result { let distance:Int; let kills:Int; let earned:Int; let fuel:CGFloat; let destroyed:Bool; let fuelPickups:Int; let cashPickups:Int; let boostPickups:Int }
    var input = Input()
    var onFinish: ((Result)->Void)?
    var onHUD: ((Int, Int, CGFloat, CGFloat, CGFloat, Int)->Void)?
    var level = 0
    var area = 0
    var audioEnabled = true
    var hapticsEnabled = true
    var vehicle = VehicleSpec.roster[0]
    var upgradeTiers: [String:Int] = [:]
    private var chassis: SKSpriteNode?
    private var wheels: [SKSpriteNode] = []
    private var cameraNode = SKCameraNode()
    private var fuel: CGFloat = Tune.baseFuel
    private var health: CGFloat = Tune.baseHealth
    private var maxHealth: CGFloat = Tune.baseHealth
    private var fuelPickups = 0
    private var cashPickups = 0
    private var boostPickups = 0
    private var boost: CGFloat = 0
    private var distance: CGFloat = 0
    private var kills = 0
    private var cash = 0
    private var elapsed: TimeInterval = 0
    private var lowSpeedTime: TimeInterval = 0
    private var ended = false
    private var lastSpawn: CGFloat = 0
    private var lastPickup: CGFloat = 2300
    private var pickupIndex = 3
    private var zombies: [SKSpriteNode] = []
    private var pickups: [SKSpriteNode] = []
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
        for layer in 0..<3 {
            let group=SKNode(); group.zPosition = CGFloat(-30+layer*5)
            for i in 0..<14 {
                let w=CGFloat(90+(i*37+layer*19)%150), h=CGFloat(100+(i*71+layer*31)%260)
                let shape=SKShapeNode(rectOf:CGSize(width:w,height:h),cornerRadius:CGFloat(layer*3+2))
                shape.fillColor=UIColor(red:biome.ground.0,green:biome.ground.1,blue:biome.ground.2,alpha:0.20+CGFloat(layer)*0.08)
                shape.strokeColor = .clear
                shape.position=CGPoint(x:CGFloat(i)*190+CGFloat(layer)*60,y:CGFloat(layer*55)+h/2+80)
                group.addChild(shape)
            }
            group.name="parallax-\(layer)"
            addChild(group)
        }
    }

    private func buildTerrain() {
        let biome=Biome.all[min(max(level,0),9)]
        let length=biome.areaLengths[min(max(area,0),2)] * 10 + 900
        var points=[CGPoint(x:-500,y:65)]
        var x:CGFloat = -500
        var y:CGFloat = 65
        while x < length {
            randomSeed = randomSeed &* 6364136223846793005 &+ 1
            let r=CGFloat((randomSeed >> 33) % 1000)/1000
            let nextY=65 + sin(x/420)*32 + cos(x/910)*22 + (r-0.5)*18
            let nextX=x+CGFloat(110+Int(r*90))
            points.append(CGPoint(x:nextX,y:nextY))
            x=nextX; y=nextY
        }
        let ground=SKShapeNode()
        let path=CGMutablePath()
        path.move(to:points[0])
        for p in points.dropFirst() { path.addLine(to:p) }
        ground.path=path
        ground.strokeColor=UIColor(red:biome.accent.0,green:biome.accent.1,blue:biome.accent.2,alpha:1)
        ground.lineWidth=8
        ground.zPosition=1
        ground.physicsBody=SKPhysicsBody(edgeChainFrom:path)
        ground.physicsBody?.friction=1.15
        ground.physicsBody?.restitution=0.05
        addChild(ground)
        terrainBodies.append(ground)
        let fill=SKShapeNode()
        let fillPath=CGMutablePath()
        fillPath.move(to:CGPoint(x:-500,y:-500)); fillPath.addLine(to:points[0])
        for p in points.dropFirst() { fillPath.addLine(to:p) }
        fillPath.addLine(to:CGPoint(x:length+1000,y:-500)); fillPath.closeSubpath()
        fill.path=fillPath; fill.fillColor=UIColor(red:biome.ground.0,green:biome.ground.1,blue:biome.ground.2,alpha:1)
        fill.strokeColor = .clear; fill.zPosition=0; addChild(fill)
    }

    private func buildVehicle() {
        let width=CGFloat(150*vehicle.width)
        fuel = CGFloat(vehicle.fuel) + CGFloat(upgradeTiers["fuel",default:0]) * 15
        maxHealth = Tune.baseHealth * CGFloat(vehicle.armor) * (1 + CGFloat(upgradeTiers["armor",default:0]) * 0.2)
        health = maxHealth
        let car=SKSpriteNode(texture:ArtFactory.vehicle(colorHex:vehicle.color),size:CGSize(width:width,height:65))
        car.position=CGPoint(x:150,y:155); car.zPosition=10
        car.physicsBody=SKPhysicsBody(rectangleOf:CGSize(width:width*0.82,height:35))
        car.physicsBody?.mass=CGFloat(vehicle.mass*4.2)
        car.physicsBody?.allowsRotation=true
        car.physicsBody?.linearDamping=0.08
        car.physicsBody?.angularDamping=0.42
        car.physicsBody?.friction=0.9
        car.physicsBody?.categoryBitMask=1
        car.physicsBody?.contactTestBitMask=2 | 4
        car.physicsBody?.collisionBitMask=UInt32.max
        addChild(car); chassis=car
        for x in [-width*0.28,width*0.28] {
            let wheel=SKSpriteNode(texture:wheelTexture(),size:CGSize(width:36,height:36))
            wheel.position=CGPoint(x:car.position.x+x,y:car.position.y-26); wheel.zPosition=11
            wheel.physicsBody=SKPhysicsBody(circleOfRadius:15)
            wheel.physicsBody?.mass=CGFloat(vehicle.mass*0.45)
            wheel.physicsBody?.friction=1.8
            wheel.physicsBody?.restitution=0.02
            wheel.physicsBody?.allowsRotation=true
            addChild(wheel); wheels.append(wheel)
            if let a=car.physicsBody, let b=wheel.physicsBody {
                let joint=SKPhysicsJointPin.joint(withBodyA:a,bodyB:b,anchor:wheel.position)
                joint.frictionTorque=8
                physicsWorld.add(joint)
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
        let engine=CGFloat(vehicle.power)*(1+CGFloat(upgradeTiers["engine",default:0])*0.18)
        if input.gas && fuel>0 {
            body.applyForce(CGVector(dx:Tune.engineForce*engine,dy:0))
            fuel=max(0,fuel-Tune.fuelBurnPerSecond*(1+engine*0.08)*dt)
        }
        if input.brake {
            if speed>35 { body.applyForce(CGVector(dx:-Tune.reverseForce*CGFloat(vehicle.mass),dy:0)) }
            else if fuel>0 { body.applyForce(CGVector(dx:-Tune.reverseForce*0.55,dy:0)); fuel=max(0,fuel-Tune.fuelBurnPerSecond*dt) }
        }
        if input.tiltLeft { body.applyTorque(Tune.airTorque*body.mass) }
        if input.tiltRight { body.applyTorque(-Tune.airTorque*body.mass) }
        if input.boost && boost>0 && fuel>0 {
            body.applyForce(CGVector(dx:2200*CGFloat(vehicle.power),dy:0))
            boost=max(0,boost-dt*24)
            fuel=max(0,fuel-dt*2)
            if Int(currentTime*12) % 3 == 0 { emitDust(at:car.position,color:.cyan) }
        }
        if body.velocity.dx > Tune.maxForwardSpeed { body.velocity.dx=Tune.maxForwardSpeed }
        if body.velocity.dx < -Tune.maxForwardSpeed*0.45 { body.velocity.dx = -Tune.maxForwardSpeed*0.45 }
        distance=max(distance,car.position.x-150)
        if car.position.x-lastPickup > 1900 {
            lastPickup = car.position.x
            spawnPickup(at: CGPoint(x:car.position.x+650,y:CGFloat.random(in:150...220)), kind:pickupIndex % 4)
            pickupIndex += 1
        }
        if car.position.x-lastSpawn > Tune.zombieSpawnDistance && zombies.count<Tune.maxActiveZombies {
            lastSpawn=car.position.x
            spawnZombie(at:CGPoint(x:car.position.x+CGFloat.random(in:360...650),y:CGFloat.random(in:140...235)))
        }
        for zombie in zombies where zombie.position.x < cameraNode.position.x-850 { zombie.removeFromParent() }
        zombies.removeAll { $0.parent == nil }
        cameraNode.position=CGPoint(x:max(400,car.position.x+Tune.cameraLookAhead),y:max(230,car.position.y+115))
        for node in children where node.name?.hasPrefix("parallax-") == true {
            let layer=CGFloat(Int(node.name.map { String($0.suffix(1)) } ?? "0") ?? 0)
            node.position.x = cameraNode.position.x * layer * -0.12
        }
        if speed < Tune.lowSpeedEndThreshold && fuel <= 0 { lowSpeedTime += dt } else { lowSpeedTime=0 }
        if health <= 0 || (fuel <= 0 && lowSpeedTime > Tune.lowSpeedEndDelay) { finish(destroyed:health<=0) }
        if currentTime-lastHUD > 0.12 {
            lastHUD=currentTime
            onHUD?(Int(distance/10),Int(speed*0.22),fuel,health,boost,cash)
        }
        if car.position.y < -240 { health=0 }
    }

    private func spawnZombie(at point:CGPoint) {
        let variant=Int.random(in:0..<3)
        let zombie=SKSpriteNode(texture:ArtFactory.zombie(variant:variant),size:CGSize(width:44,height:65))
        zombie.position=point; zombie.zPosition=8; zombie.name="zombie"
        zombie.physicsBody=SKPhysicsBody(rectangleOf:CGSize(width:28,height:48))
        zombie.physicsBody?.mass=variant == 2 ? 2.8 : 0.9
        zombie.physicsBody?.isDynamic=true
        zombie.physicsBody?.allowsRotation=true
        zombie.physicsBody?.categoryBitMask=2
        zombie.physicsBody?.contactTestBitMask=1
        zombie.physicsBody?.collisionBitMask=1
        addChild(zombie); zombies.append(zombie)
        let walk=SKAction.sequence([.moveBy(x:-18,y:0,duration:0.5),.moveBy(x:18,y:0,duration:0.5)])
        zombie.run(.repeatForever(walk))
    }

    private func spawnPickup(at point:CGPoint,kind:Int) {
        let colors:[UIColor]=[.systemGreen,.systemYellow,.systemCyan,.systemRed]
        let node=SKShapeNode(circleOfRadius:15)
        node.fillColor=colors[kind%colors.count]; node.strokeColor=.white; node.lineWidth=3
        node.position=point; node.zPosition=12; node.name="pickup-\(kind)"
        node.physicsBody=SKPhysicsBody(circleOfRadius:15); node.physicsBody?.isDynamic=false
        node.physicsBody?.categoryBitMask=4; node.physicsBody?.contactTestBitMask=1
        addChild(node); pickups.append(node)
    }

    func didBegin(_ contact:SKPhysicsContact) {
        let a=contact.bodyA.node, b=contact.bodyB.node
        if let zombie=(a?.name=="zombie" ? a : b?.name=="zombie" ? b : nil) {
            let impact=abs(contact.collisionImpulse)
            kills += 1
            FeedbackService.shared.hit(audio:audioEnabled,haptics:hapticsEnabled)
            let reward=Tune.hitCash + Int(min(impact/80,20))
            cash += reward
            emitDust(at:zombie.position,color:UIColor(red:0.56,green:0.72,blue:0.48,alpha:1))
            zombie.removeFromParent()
            zombies.removeAll { $0 === zombie }
            if impact < 18 { health=max(0,health-Tune.zombieContactDamage) }
        }
        if let pickup=(a?.name?.hasPrefix("pickup-")==true ? a : b?.name?.hasPrefix("pickup-")==true ? b : nil) {
            let kind=Int(pickup.name?.replacingOccurrences(of:"pickup-",with:"") ?? "0") ?? 0
            if kind==0 { fuel=min(CGFloat(vehicle.fuel)+CGFloat(upgradeTiers["fuel",default:0])*15,fuel+28); fuelPickups += 1 }
            if kind==1 { cash += 75; cashPickups += 1 }
            if kind==2 { boost=min(100,boost+55); boostPickups += 1 }
            if kind==3 { health=min(maxHealth,health+35) }
            FeedbackService.shared.pickup(audio:audioEnabled,haptics:hapticsEnabled)
            emitDust(at:pickup.position,color:.yellow); pickup.removeFromParent()
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
        removeAllChildren()
        zombies.removeAll(); pickups.removeAll(); wheels.removeAll(); terrainBodies.removeAll()
        chassis = nil
        fuel = CGFloat(vehicle.fuel) + CGFloat(upgradeTiers["fuel",default:0]) * 15
        maxHealth = Tune.baseHealth * CGFloat(vehicle.armor) * (1 + CGFloat(upgradeTiers["armor",default:0]) * 0.2)
        health = maxHealth
        boost = 0; distance = 0
        kills = 0; cash = 0; fuelPickups = 0; cashPickups = 0; boostPickups = 0; elapsed = 0; lowSpeedTime = 0; lastSpawn = 0; lastPickup = 2300; pickupIndex = 3; lastHUD = 0; ended = false
        didMove(to: view ?? SKView())
    }

    private func finish(destroyed:Bool) {
        guard !ended else { return }
        ended=true
        let result=Result(distance:Int(distance/10),kills:kills,earned:cash+Int(distance/1000)*Tune.distanceCashPer100,fuel:fuel,destroyed:destroyed,fuelPickups:fuelPickups,cashPickups:cashPickups,boostPickups:boostPickups)
        onFinish?(result)
        isPaused=true
    }
}
