import SwiftUI

struct RootView: View {
    @Bindable var progress: PlayerProgress
    @State private var screen = "home"
    @State private var selectedLevel = 0
    @State private var selectedArea = 0
    @State private var showDebug = false
    @State private var showReset = false

    var body: some View {
        ZStack {
            LinearGradient(colors:[Color(red:0.07,green:0.08,blue:0.1),Color(red:0.19,green:0.12,blue:0.1)],startPoint:.topLeading,endPoint:.bottomTrailing).ignoresSafeArea()
            if screen == "run" {
                GameView(progress:progress,level:selectedLevel,area:selectedArea,onExit:{screen="garage"})
            } else {
                VStack(spacing:0) {
                    HStack {
                        Text("DEAD MILE").font(.system(size:15,weight:.black,design:.rounded)).tracking(3)
                        Spacer()
                        Label("$\(progress.cash)",systemImage:"dollarsign.circle.fill").font(.system(size:17,weight:.heavy,design:.rounded)).foregroundStyle(.yellow)
                    }.padding(.horizontal,28).padding(.top,20)
                    Spacer()
                    switch screen {
                    case "home": home
                    case "levels": levels
                    case "garage": garage
                    case "missions": missions
                    case "settings": settings
                    case "howto": howto
                    case "achievements": achievements
                    default: home
                    }
                    Spacer()
                    HStack {
                        footerButton("GARAGE","wrench.and.screwdriver.fill","garage")
                        footerButton("STORY","map.fill","levels")
                        footerButton("MISSIONS","target", "missions")
                        footerButton("SETTINGS","gearshape.fill","settings")
                    }.padding(.bottom,12)
                    Text("v1.0.0").font(.system(size:9,weight:.bold,design:.monospaced)).foregroundStyle(.white.opacity(0.3))
                        .onLongPressGesture(minimumDuration:1.5){showDebug.toggle()}
                }.padding(.horizontal,24)
            }
            if showDebug { debugPanel }
        }
        .alert("Reset all progress?",isPresented:$showReset) {
            Button("Cancel",role:.cancel){}
            Button("Reset",role:.destructive){ progress.cash=450;progress.bestDistance=0;progress.unlockedLevel=0;progress.unlockedVehicles=[0];progress.selectedVehicle=0;progress.upgrades=[:];progress.areaProgress=[:];progress.totalKills=0;progress.runs=0;progress.save() }
        } message:{Text("This permanently clears local game progress.")}
    }

    private var home:some View {
        VStack(spacing:18) {
            Text("THE ROAD
DOESN'T END").font(.system(size:44,weight:.black,design:.rounded)).multilineTextAlignment(.center).tracking(-1)
            Text("10 REGIONS  •  30 RUNS  •  NO SAFE STOPS").font(.system(size:11,weight:.heavy,design:.rounded)).tracking(2).foregroundStyle(.orange)
            HStack(spacing:14) { metric("BEST DISTANCE","\(progress.bestDistance)m");metric("INFECTED","\(progress.totalKills)") }
            Button { selectedLevel=progress.unlockedLevel;selectedArea=0;screen="run" } label:{Label("START DRIVING",systemImage:"play.fill").frame(maxWidth:300)}
                .buttonStyle(PrimaryStyle())
            Button { screen="howto" } label:{Text("HOW TO SURVIVE").font(.system(size:12,weight:.bold)).foregroundStyle(.white.opacity(0.65))}
            Button { let reward=progress.claimDaily(); if reward>0 { dailyMessage="DAILY SUPPLY +$\(reward)" } else { dailyMessage="DAILY SUPPLY ALREADY CLAIMED" } } label:{Label(dailyMessage,systemImage:"gift.fill").font(.system(size:12,weight:.bold)).foregroundStyle(.yellow)}
        }
    }
    @State private var dailyMessage = "CLAIM DAILY SUPPLY"

    private var levels:some View {
        VStack(spacing:12) {
            Text("THE WASTELAND").font(.system(size:30,weight:.black,design:.rounded))
            Text("Choose your next route").foregroundStyle(.white.opacity(0.6))
            ScrollView(.horizontal) {
                HStack(spacing:12) {
                    ForEach(Biome.all) { biome in
                        Button { if biome.id<=progress.unlockedLevel { selectedLevel=biome.id;selectedArea=0;screen="run" } } label:{
                            VStack(alignment:.leading,spacing:10) {
                                Text(String(format:"%02d",biome.id+1)).font(.system(size:26,weight:.black,design:.rounded))
                                Text(biome.name).font(.system(size:12,weight:.heavy)).lineLimit(2)
                                Text(biome.id<=progress.unlockedLevel ? "AVAILABLE" : "LOCKED").font(.system(size:9,weight:.black)).foregroundStyle(biome.id<=progress.unlockedLevel ? .green : .gray)
                            }.frame(width:142,height:120,alignment:.leading).padding(12).background(Color(red:biome.sky.0,green:biome.sky.1,blue:biome.sky.2).opacity(0.8),in:RoundedRectangle(cornerRadius:16))
                        }.disabled(biome.id>progress.unlockedLevel)
                    }
                }.padding(.horizontal,6)
            }.frame(height:165)
            Text("Area lengths increase with each route. Clear an area to earn its supply bonus.").font(.system(size:12)).foregroundStyle(.white.opacity(0.6)).multilineTextAlignment(.center)
        }
    }

    private var garage:some View {
        VStack(spacing:12) {
            Text("MOTOR POOL").font(.system(size:30,weight:.black,design:.rounded))
            TabView(selection:$progress.selectedVehicle) {
                ForEach(VehicleSpec.roster) { spec in
                    VStack(spacing:8) {
                        Image(uiImage:UIImage(cgImage:ArtFactory.vehicle(colorHex:spec.color).cgImage()!))
                            .resizable().scaledToFit().frame(maxWidth:360,maxHeight:115)
                        Text(spec.name).font(.system(size:21,weight:.black,design:.rounded))
                        HStack { statBar("POWER",spec.power/3.1);statBar("ARMOR",spec.armor/4.5);statBar("FUEL",spec.fuel/230) }
                        if progress.unlockedVehicles.contains(spec.id) {
                            Text("OWNED").font(.system(size:10,weight:.black)).foregroundStyle(.green)
                        } else {
                            Button("UNLOCK  $\(spec.price)") { _=progress.buyVehicle(spec.id) }.buttonStyle(PrimaryStyle()).disabled(progress.cash<spec.price)
                        }
                    }.tag(spec.id)
                }
            }.tabViewStyle(.page(indexDisplayMode:.always)).frame(height:235)
            HStack(spacing:8) {
                upgradeButton("ENGINE","engine", "Power and acceleration")
                upgradeButton("FUEL","fuel", "Longer runs")
                upgradeButton("ARMOR","armor", "Survive heavy impacts")
            }
            Text("Recommended: \(progress.tier("engine") < 2 ? "ENGINE" : progress.tier("fuel") < 2 ? "FUEL TANK" : "ARMOR")").font(.system(size:11,weight:.bold)).foregroundStyle(.orange)
        }
    }

    private var missions:some View {
        VStack(spacing:14) {
            Text("SURVIVAL CONTRACTS").font(.system(size:28,weight:.black,design:.rounded))
            if progress.missionsUnlocked {
                ForEach(0..<50,id:\.self) { i in
                    HStack { Text(String(format:"CONTRACT %02d",i+1)).font(.system(size:12,weight:.black));Spacer();Text(["Crush 8 infected","Travel 1,200m","Collect 2 fuel cans","Finish with 25% hull"][i%4]).font(.system(size:11)).foregroundStyle(.white.opacity(0.65));Image(systemName:"star") }
                        .padding(10).background(.white.opacity(0.06),in:RoundedRectangle(cornerRadius:8))
                }.frame(maxHeight:250)
            } else {
                Image(systemName:"lock.fill").font(.largeTitle).foregroundStyle(.orange)
                Text("Clear the evacuation port to unlock contracts and exploration.").multilineTextAlignment(.center).foregroundStyle(.white.opacity(0.65))
            }
        }
    }

    private var settings:some View {
        VStack(spacing:18) {
            Text("SETTINGS").font(.system(size:30,weight:.black,design:.rounded))
            Toggle("Game audio",isOn:$progress.audioEnabled).tint(.orange)
            Toggle("Haptic feedback",isOn:$progress.hapticsEnabled).tint(.orange)
            Toggle("Large HUD",isOn:$progress.largeHUD).tint(.orange)
            VStack(alignment:.leading) { Text("Control size");Slider(value:$progress.controlScale,in:0.8...1.3) }
            Button("RESET PROGRESS",role:.destructive){showReset=true}
            Button("EXPORT SAVE") { exportSave() }.buttonStyle(SecondaryStyle())
        }.padding(.horizontal,40).frame(maxWidth:520)
    }

    private var howto:some View {
        VStack(spacing:15) {
            Text("SURVIVAL 101").font(.system(size:30,weight:.black,design:.rounded))
            instruction("GAS","Hold the right pedal to accelerate.")
            instruction("BRAKE / REVERSE","Use the left pedal to slow down or reverse.")
            instruction("TILT","Use the two center controls to rotate in mid-air.")
            instruction("BOOST","Boost charges are collected on the road. Spend them for a burst.")
            instruction("FUEL","Fuel cans refill your tank. When empty, keep rolling to stretch your run.")
        }.padding(.horizontal,40).frame(maxWidth:600)
    }

    private var achievements:some View {
        VStack(spacing:10) {
            Text("FIELD RECORDS").font(.system(size:28,weight:.black,design:.rounded))
            metric("FIRST BLOOD","\(progress.totalKills) / 1 infected")
            metric("ROAD WARRIOR","\(progress.bestDistance) / 5,000 m")
            metric("MILE EATER","\(progress.runs) runs completed")
            metric("FLEET COMMANDER","\(progress.unlockedVehicles.count) / 10 vehicles")
        }
    }

    private var debugPanel:some View {
        VStack(spacing:10) {
            Text("FIELD ENGINEERING").font(.system(size:18,weight:.black))
            Button("+ $10,000") { progress.cash+=10000;progress.save() }.buttonStyle(SecondaryStyle())
            Button("UNLOCK ALL VEHICLES") { progress.unlockedVehicles=Set(0..<10);progress.unlockedLevel=9;progress.save() }.buttonStyle(SecondaryStyle())
            Button("CLOSE") { showDebug=false }.buttonStyle(PrimaryStyle())
        }.padding(24).background(.regularMaterial,in:RoundedRectangle(cornerRadius:20))
    }

    private func metric(_ title:String,_ value:String)->some View {
        VStack(spacing:4) { Text(value).font(.system(size:20,weight:.black,design:.rounded));Text(title).font(.system(size:9,weight:.heavy)).foregroundStyle(.white.opacity(0.55)) }
            .frame(maxWidth:150).padding(12).background(.white.opacity(0.07),in:RoundedRectangle(cornerRadius:12))
    }
    private func footerButton(_ title:String,_ icon:String,_ target:String)->some View {
        Button { screen=target } label: { VStack(spacing:4){Image(systemName:icon).font(.system(size:17,weight:.bold));Text(title).font(.system(size:8,weight:.black))}.foregroundStyle(screen==target ? .orange : .white.opacity(0.55)).frame(maxWidth:.infinity) }
    }
    private func upgradeButton(_ title:String,_ key:String,_ detail:String)->some View {
        let tier=progress.tier(key), cost=progress.upgradeCost(key)
        return Button {
            if progress.unlockedVehicles.contains(progress.selectedVehicle) { _=progress.buyUpgrade(key) }
        } label:{
            VStack(spacing:4) { Text(title).font(.system(size:11,weight:.black));Text("LV \(tier)/5").font(.system(size:10,weight:.bold));Text(tier<5 ? "$\(cost)" : "MAX").font(.system(size:11,weight:.heavy)).foregroundStyle(.yellow);Text(detail).font(.system(size:8)).foregroundStyle(.white.opacity(0.55)).lineLimit(1) }
                .frame(maxWidth:.infinity).padding(9).background(.white.opacity(0.07),in:RoundedRectangle(cornerRadius:10))
        }.disabled(tier>=5 || progress.cash<cost || !progress.unlockedVehicles.contains(progress.selectedVehicle))
    }
    private func statBar(_ title:String,_ value:Double)->some View {
        VStack(spacing:3) { Text(title).font(.system(size:8,weight:.black));ProgressView(value:min(1,max(0,value))).tint(.orange).frame(width:75) }
    }
    private func instruction(_ title:String,_ text:String)->some View {
        HStack(alignment:.top) { Text(title).font(.system(size:12,weight:.black)).frame(width:130,alignment:.leading).foregroundStyle(.orange);Text(text).font(.system(size:12)).foregroundStyle(.white.opacity(0.75));Spacer(minLength:0) }
    }
    private func exportSave() {
        let url=FileManager.default.temporaryDirectory.appendingPathComponent("deadmile-save-v1.json")
        progress.save()
        if let data=try? Data(contentsOf:FileManager.default.urls(for:.applicationSupportDirectory,in:.userDomainMask)[0].appendingPathComponent("deadmile-save-v1.json")) {
            try? data.write(to:url)
            shareURL=url
        }
    }
    @State private var shareURL:URL?
}

private struct PrimaryStyle:ButtonStyle {
    func makeBody(configuration:Configuration)->some View {
        configuration.label.font(.system(size:14,weight:.black,design:.rounded)).padding(.horizontal,30).padding(.vertical,15)
            .background(Color.orange.opacity(configuration.isPressed ? 0.5 : 1),in:Capsule()).foregroundStyle(.black)
    }
}
private struct SecondaryStyle:ButtonStyle {
    func makeBody(configuration:Configuration)->some View {
        configuration.label.font(.system(size:12,weight:.black)).padding(12).background(.white.opacity(0.1),in:Capsule())
    }
}
