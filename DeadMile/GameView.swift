import SwiftUI
import SpriteKit

struct GameView: View {
    let progress: PlayerProgress
    let level: Int
    let area: Int
    let explorationMode: Bool
    let onExit: ()->Void
    @State private var distance=0
    @State private var speed=0
    @State private var fuel:CGFloat=100
    @State private var health:CGFloat=100
    @State private var boost:CGFloat=0
    @State private var cash=0
    @State private var routeProgress:CGFloat=0
    @State private var result: DeadMileScene.Result?
    @State private var paused=false
    @State private var scene: DeadMileScene
    @Environment(\.scenePhase) private var scenePhase

    init(progress:PlayerProgress,level:Int,area:Int,explorationMode:Bool = false,onExit:@escaping ()->Void) {
        self.progress=progress; self.level=level; self.area=area; self.explorationMode=explorationMode; self.onExit=onExit
        let s=DeadMileScene(size:CGSize(width:896,height:414))
        s.scaleMode = .resizeFill
        s.level=level; s.area=area; s.explorationMode=explorationMode
        s.audioEnabled=progress.audioEnabled; s.hapticsEnabled=progress.hapticsEnabled
        s.vehicle=VehicleSpec.roster.first(where:{$0.id==progress.selectedVehicle}) ?? VehicleSpec.roster[0]
        s.upgradeTiers=["engine":progress.tier("engine"),"tires":progress.tier("tires"),"fuel":progress.tier("fuel"),"armor":progress.tier("armor"),"boost":progress.tier("boost"),"weapon":progress.tier("weapon")]
        _scene=State(initialValue:s)
    }

    var body: some View {
        ZStack {
            SpriteView(scene:scene,options:[.ignoresSiblingOrder]).ignoresSafeArea()
            VStack(spacing:8) {
                HStack {
                    stat("DIST",String(format:"%05d m",distance),.white)
                    stat("SPEED","\(speed) km/h",.white)
                    Spacer()
                    stat("CASH","$\(cash)",.yellow)
                    Button { paused=true; scene.input=DeadMileScene.Input(); FeedbackService.shared.stopEngine(); scene.isPaused=true } label: { Image(systemName:"pause.fill").font(.title2).padding(12).background(.ultraThinMaterial,in:Circle()) }
                        .accessibilityLabel("Pause game")
                }
                HStack(spacing:7) {
                    meter("FUEL",fuel,.orange); meter("HULL",health,.red); meter("BOOST",boost,.cyan)
                }
                if !explorationMode {
                    HStack(spacing:8) {
                        Text("REGION \(level+1)  /  LEG \(area+1)")
                            .font(.system(size:9,weight:.black,design:.rounded))
                            .foregroundStyle(.white.opacity(0.76))
                        GeometryReader { geometry in
                            ZStack(alignment:.leading) {
                                Capsule().fill(.white.opacity(0.16))
                                Capsule().fill(LinearGradient(colors:[.orange,.yellow],startPoint:.leading,endPoint:.trailing))
                                    .frame(width:geometry.size.width*max(0,min(1,routeProgress)))
                            }
                        }.frame(height:5)
                        Text("\(Int(routeProgress*100))%")
                            .font(.system(size:9,weight:.black,design:.monospaced))
                            .foregroundStyle(.orange)
                    }
                    .padding(.horizontal,10)
                    .padding(.vertical,6)
                    .background(.black.opacity(0.38),in:Capsule())
                }
                Spacer()
            }.padding(.horizontal,18).padding(.top,8)
            VStack {
                Spacer()
                HStack(alignment:.bottom) {
                    if progress.leftHandedControls {
                        rightControlCluster
                        Spacer()
                        leftControlCluster
                    } else {
                        leftControlCluster
                        Spacer()
                        rightControlCluster
                    }
                }
            }.padding(.horizontal,24).padding(.bottom,18)
            if paused {
                overlay(title:"PAUSED",subtitle:"The wasteland can wait.",primary:"RESUME",secondary:"QUIT RUN",primaryAction:{paused=false;scene.isPaused=false},secondaryAction:onExit)
            }
            if let result {
                overlay(title:result.cleared ? "LEG CLEARED" : (result.destroyed ? "VEHICLE WRECKED" : "OUT OF FUEL"),subtitle:"\(result.distance)m  •  \(result.kills) infected  •  \(result.checkpointReached ? "FUEL STOP REACHED" : "NO CHECKPOINT")  •  +$\(result.earned)",primary:"GARAGE",secondary:"RETRY",primaryAction:onExit,secondaryAction:{self.result=nil;scene.resetRun()})
            }
        }
        .onAppear {
            scene.onHUD={ d,s,f,h,b,c,p in distance=d;speed=s;fuel=f;health=h;boost=b;cash=c;routeProgress=p }
            scene.onFinish={ r in
                result=r
                progress.finish(RunRecord(distance:r.distance,kills:r.kills,earned:r.earned,level:level,area:area,fuelPickups:r.fuelPickups,cashPickups:r.cashPickups,boostPickups:r.boostPickups,hiddenKits:r.hiddenKits,isExploration:explorationMode))
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active && result == nil {
                paused = true
                scene.input = DeadMileScene.Input()
                FeedbackService.shared.stopEngine()
                scene.isPaused = true
            }
        }
        .onDisappear { scene.input = DeadMileScene.Input(); FeedbackService.shared.stopEngine(); progress.save() }
    }

    private var leftControlCluster: some View {
        HStack(spacing:8) {
            holdButton("BRAKE",icon:"arrow.uturn.backward",color:.orange) { scene.input.brake=$0 }
            VStack(spacing:6) {
                holdButton("TILT L",icon:"rotate.left",color:.white) { scene.input.tiltLeft=$0 }
                holdButton("TILT R",icon:"rotate.right",color:.white) { scene.input.tiltRight=$0 }
            }
        }
    }

    private var rightControlCluster: some View {
        HStack(spacing:10) {
            if progress.tier("weapon") > 0 {
                holdButton("FIRE",icon:"scope",color:.red) { scene.input.fire=$0 }
            }
            holdButton("BOOST",icon:"bolt.fill",color:.cyan) { scene.input.boost=$0 }
            holdButton("GAS",icon:"arrowtriangle.right.fill",color:.green) { scene.input.gas=$0 }
        }
    }

    private func stat(_ title:String,_ value:String,_ color:Color)->some View {
        VStack(alignment:.leading,spacing:1) {
            Text(title)
                .font(.system(size:8,weight:.black,design:.rounded))
                .foregroundStyle(.white.opacity(0.55))
            Text(value)
                .font(.system(size:14,weight:.heavy,design:.rounded))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.horizontal,10)
        .padding(.vertical,6)
        .background(LinearGradient(colors:[Color.black.opacity(0.62),Color.black.opacity(0.34)],startPoint:.topLeading,endPoint:.bottomTrailing),in:RoundedRectangle(cornerRadius:9))
        .overlay(RoundedRectangle(cornerRadius:9).stroke(.white.opacity(0.09),lineWidth:1))
    }

    private func meter(_ title:String,_ value:CGFloat,_ color:Color)->some View {
        VStack(alignment:.leading,spacing:4) {
            HStack {
                Text(title).font(.system(size:8,weight:.black,design:.rounded))
                Spacer(minLength:2)
                Text("\(Int(max(0,min(100,value))))%")
                    .font(.system(size:8,weight:.bold,design:.monospaced))
                    .foregroundStyle(.white.opacity(0.68))
            }
            GeometryReader { geo in
                ZStack(alignment:.leading) {
                    Capsule().fill(.white.opacity(0.14))
                    Capsule().fill(LinearGradient(colors:[color,color.opacity(0.68)],startPoint:.leading,endPoint:.trailing))
                        .frame(width:geo.size.width*max(0,min(1,value/100)))
                }
            }.frame(height:6)
        }
        .frame(maxWidth:118)
        .foregroundStyle(.white)
        .padding(.horizontal,8)
        .padding(.vertical,7)
        .background(.black.opacity(0.42),in:RoundedRectangle(cornerRadius:9))
        .overlay(RoundedRectangle(cornerRadius:9).stroke(.white.opacity(0.08),lineWidth:1))
        .accessibilityElement(children:.ignore)
        .accessibilityLabel(title)
        .accessibilityValue("\(Int(value)) percent")
    }

    private func holdButton(_ title:String,icon:String,color:Color,action:@escaping(Bool)->Void)->some View {
        VStack(spacing:3) {
            Image(systemName:icon)
                .font(.system(size:21,weight:.black))
            Text(title)
                .font(.system(size:7,weight:.black,design:.rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .foregroundStyle(color)
        .frame(width:58 * CGFloat(progress.controlScale) * (progress.largeHUD ? 1.18 : 1),
               height:55 * CGFloat(progress.controlScale) * (progress.largeHUD ? 1.18 : 1))
        .background(
            LinearGradient(colors:[Color(red:0.17,green:0.19,blue:0.21).opacity(0.94),Color(red:0.07,green:0.08,blue:0.10).opacity(0.96)],startPoint:.topLeading,endPoint:.bottomTrailing),
            in:RoundedRectangle(cornerRadius:15)
        )
        .overlay(RoundedRectangle(cornerRadius:15).stroke(color.opacity(0.62),lineWidth:1.5))
        .contentShape(RoundedRectangle(cornerRadius:15))
        .accessibilityLabel(title)
        .accessibilityHint("Press and hold to activate")
        .accessibilityAddTraits(.isButton)
        .onLongPressGesture(minimumDuration:0,maximumDistance:70,pressing:{ isPressing in
            action(isPressing)
        },perform:{})
    }

    private func overlay(title:String,subtitle:String,primary:String,secondary:String,primaryAction:@escaping()->Void,secondaryAction:@escaping()->Void)->some View {
        VStack(spacing:16) {
            Text(title).font(.system(size:38,weight:.black,design:.rounded))
            Text(subtitle).font(.headline).foregroundStyle(.white.opacity(0.7))
            HStack {
                Button(primary,action:primaryAction).buttonStyle(NeonButton(color:.green))
                Button(secondary,action:secondaryAction).buttonStyle(NeonButton(color:.orange))
            }
        }.padding(34).background(.ultraThinMaterial,in:RoundedRectangle(cornerRadius:24)).overlay(RoundedRectangle(cornerRadius:24).stroke(.white.opacity(0.2)))
    }
}

private struct NeonButton:ButtonStyle {
    let color:Color
    func makeBody(configuration:Configuration)->some View {
        configuration.label.font(.system(size:14,weight:.black,design:.rounded)).padding(.horizontal,24).padding(.vertical,14)
            .background(color.opacity(configuration.isPressed ? 0.5 : 0.85),in:Capsule()).foregroundStyle(.black)
    }
}
