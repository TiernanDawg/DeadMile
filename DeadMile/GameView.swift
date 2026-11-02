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
        s.upgradeTiers=["engine":progress.tier("engine"),"fuel":progress.tier("fuel"),"armor":progress.tier("armor"),"weapon":progress.tier("weapon")]
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
                    Button { paused=true; scene.isPaused=true } label: { Image(systemName:"pause.fill").font(.title2).padding(12).background(.ultraThinMaterial,in:Circle()) }
                }
                HStack(spacing:7) {
                    meter("FUEL",fuel,.orange); meter("HULL",health,.red); meter("BOOST",boost,.cyan)
                }
                Spacer()
            }.padding(.horizontal,22).padding(.top,10)
            VStack {
                Spacer()
                HStack(alignment:.bottom) {
                    HStack(spacing:10) {
                        holdButton("BACK",icon:"arrow.uturn.backward",color:.orange) { scene.input.brake=$0 }
                        VStack(spacing:8) {
                            holdButton("TILT",icon:"rotate.left",color:.white) { scene.input.tiltLeft=$0 }
                            holdButton("TILT",icon:"rotate.right",color:.white) { scene.input.tiltRight=$0 }
                        }
                    }
                    Spacer()
                    HStack(spacing:10) {
                        if progress.tier("weapon") > 0 {
                            holdButton("FIRE",icon:"scope",color:.red) { scene.input.fire=$0 }
                        }
                        holdButton("BOOST",icon:"bolt.fill",color:.cyan) { scene.input.boost=$0 }
                        holdButton("GAS",icon:"arrowtriangle.right.fill",color:.green) { scene.input.gas=$0 }
                    }
                }
            }.padding(.horizontal,24).padding(.bottom,18)
            if paused {
                overlay(title:"PAUSED",subtitle:"The wasteland can wait.",primary:"RESUME",secondary:"QUIT RUN",primaryAction:{paused=false;scene.isPaused=false},secondaryAction:onExit)
            }
            if let result {
                overlay(title:result.destroyed ? "WRECKED" : "OUT OF FUEL",subtitle:"\(result.distance)m  •  \(result.kills) infected eliminated  •  \(result.hiddenKits) caches  •  +$\(result.earned)",primary:"UPGRADE",secondary:"RETRY",primaryAction:onExit,secondaryAction:{self.result=nil;scene.resetRun()})
            }
        }
        .onAppear {
            scene.onHUD={ d,s,f,h,b,c in distance=d;speed=s;fuel=f;health=h;boost=b;cash=c }
            scene.onFinish={ r in
                result=r
                progress.finish(RunRecord(distance:r.distance,kills:r.kills,earned:r.earned,level:level,area:area,fuelPickups:r.fuelPickups,cashPickups:r.cashPickups,boostPickups:r.boostPickups,hiddenKits:r.hiddenKits,isExploration:explorationMode))
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active && result == nil {
                paused = true
                scene.isPaused = true
            }
        }
        .onDisappear { FeedbackService.shared.stopEngine(); progress.save() }
    }

    private func stat(_ title:String,_ value:String,_ color:Color)->some View {
        VStack(alignment:.leading,spacing:2) { Text(title).font(.system(size:10,weight:.black,design:.rounded)).foregroundStyle(.white.opacity(0.6)); Text(value).font(.system(size:17,weight:.heavy,design:.rounded)).foregroundStyle(color) }
            .padding(.horizontal,12).padding(.vertical,7).background(.black.opacity(0.42),in:RoundedRectangle(cornerRadius:10))
    }
    private func meter(_ title:String,_ value:CGFloat,_ color:Color)->some View {
        VStack(alignment:.leading,spacing:3) { Text(title).font(.system(size:9,weight:.black)); GeometryReader { geo in ZStack(alignment:.leading) { Capsule().fill(.white.opacity(0.18)); Capsule().fill(color).frame(width:geo.size.width*max(0,min(1,value/100))) } }.frame(height:7) }
            .frame(maxWidth:150).foregroundStyle(.white).padding(8).background(.black.opacity(0.35),in:RoundedRectangle(cornerRadius:8))
            .accessibilityElement(children:.ignore).accessibilityLabel(title).accessibilityValue("\(Int(value)) percent")
    }
    private func holdButton(_ title:String,icon:String,color:Color,action:@escaping(Bool)->Void)->some View {
        Image(systemName:icon).font(.system(size:23,weight:.black)).foregroundStyle(color)
            .frame(width:68 * CGFloat(progress.controlScale) * (progress.largeHUD ? 1.18 : 1),height:62 * CGFloat(progress.controlScale) * (progress.largeHUD ? 1.18 : 1)).background(.ultraThinMaterial,in:RoundedRectangle(cornerRadius:17))
            .overlay(RoundedRectangle(cornerRadius:17).stroke(color.opacity(0.5),lineWidth:1))
            .contentShape(RoundedRectangle(cornerRadius:17))
            .accessibilityLabel(title)
            .accessibilityHint("Press and hold to activate")
            .accessibilityAddTraits(.isButton)
            .gesture(DragGesture(minimumDistance:0).onChanged{_ in action(true)}.onEnded{_ in action(false)})
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
