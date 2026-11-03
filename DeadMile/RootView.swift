import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct RootView: View {
    @Bindable var progress: PlayerProgress
    @State private var screen = "home"
    @State private var selectedLevel = 0
    @State private var selectedArea = 0
    @State private var explorationMode = false
    @State private var garageVehicle = 0
    @State private var showShare = false
    @State private var showDebug = false
    @State private var showReset = false
    @State private var showImportConfirm = false
    @State private var showImportPicker = false
    @State private var showImportNotice = false
    @State private var importNotice = ""

    var body: some View {
        ZStack {
            MenuBackdrop().ignoresSafeArea()
            LinearGradient(colors:[.black.opacity(0.18),.black.opacity(0.48)],startPoint:.top,endPoint:.bottom).ignoresSafeArea()
            if screen == "run" {
                GameView(progress:progress,level:selectedLevel,area:selectedArea,explorationMode:explorationMode,onExit:{screen="garage"})
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
        .onChange(of: progress.audioEnabled) { _, _ in progress.save() }
        .onChange(of: progress.hapticsEnabled) { _, _ in progress.save() }
        .onChange(of: progress.largeHUD) { _, _ in progress.save() }
        .onChange(of: progress.leftHandedControls) { _, _ in progress.save() }
        .onChange(of: progress.controlScale) { _, _ in progress.save() }
        .onChange(of: progress.selectedVehicle) { _, _ in progress.save() }
        .sheet(isPresented: $showShare) {
            if let shareURL { ActivityView(items: [shareURL]) }
        }
        .fileImporter(isPresented: $showImportPicker, allowedContentTypes: [.json], allowsMultipleSelection: false) { result in
            importSave(result)
        }
        .alert("Reset all progress?",isPresented:$showReset) {
            Button("Cancel",role:.cancel){}
            Button("Reset",role:.destructive){ progress.reset(); selectedLevel=0; selectedArea=0; garageVehicle=0 }
        } message:{Text("This permanently clears local game progress.")}
    }

    private var home:some View {
        let challenge = DailyChallengeSpec.current()
        let challengeProgress = progress.dailyChallengeDate == challenge.date ? progress.dailyChallengeProgress : 0
        let challengeComplete = progress.dailyChallengeDate == challenge.date && progress.dailyChallengeClaimed
        return ScrollView(.vertical) {
            HStack(spacing:22) {
                VStack(alignment:.leading,spacing:14) {
                    Text("THE ROAD DOESN'T END")
                        .font(.system(size:35,weight:.black,design:.rounded))
                        .tracking(-0.8)
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                    Text("WASTELAND SURVIVAL  /  10 REGIONS  /  NO SAFE STOPS")
                        .font(.system(size:9,weight:.black,design:.rounded))
                        .tracking(1.6)
                        .foregroundStyle(.orange)
                    HStack(spacing:10) {
                        metric("BEST DISTANCE","\(progress.bestDistance)m")
                        metric("INFECTED","\(progress.totalKills)")
                        metric("VEHICLES","\(progress.unlockedVehicles.count)/10")
                    }
                    Button {
                        explorationMode=false
                        selectedLevel=progress.unlockedLevel
                        selectedArea=0
                        screen="run"
                    } label: {
                        Label("START DRIVING",systemImage:"play.fill").frame(maxWidth:300)
                    }.buttonStyle(PrimaryStyle())
                    HStack(spacing:18) {
                        Button { screen="howto" } label: {
                            Label("SURVIVAL GUIDE",systemImage:"book.closed.fill")
                                .font(.system(size:10,weight:.black))
                                .foregroundStyle(.white.opacity(0.72))
                        }
                        Button { screen="achievements" } label: {
                            Label("FIELD RECORDS",systemImage:"medal.fill")
                                .font(.system(size:10,weight:.black))
                                .foregroundStyle(.white.opacity(0.72))
                        }
                    }
                }
                .frame(maxWidth:.infinity,alignment:.leading)

                VStack(alignment:.leading,spacing:9) {
                    HStack {
                        Label("DAILY CONTRACT",systemImage:"target")
                            .font(.system(size:10,weight:.black))
                            .foregroundStyle(.orange)
                        Spacer()
                        Text(challengeComplete ? "PAID" : "+$\(challenge.reward)")
                            .font(.system(size:10,weight:.black))
                            .foregroundStyle(.yellow)
                    }
                    Text(challenge.title)
                        .font(.system(size:17,weight:.black,design:.rounded))
                    Text(challenge.detail)
                        .font(.system(size:10,weight:.medium))
                        .foregroundStyle(.white.opacity(0.65))
                    ProgressView(value:Double(min(challengeProgress,challenge.target)),total:Double(challenge.target))
                        .tint(challengeComplete ? .green : .orange)
                    Text("\(min(challengeProgress,challenge.target)) / \(challenge.target)")
                        .font(.system(size:9,weight:.bold,design:.monospaced))
                        .foregroundStyle(.white.opacity(0.55))
                    Button {
                        let reward=progress.claimDaily()
                        dailyMessage = reward > 0 ? "SUPPLY CLAIMED  +$\(reward)" : "ALREADY CLAIMED TODAY"
                    } label: {
                        Label(dailyMessage,systemImage:"gift.fill")
                            .font(.system(size:9,weight:.black))
                            .foregroundStyle(.yellow)
                    }
                    if progress.explorationUnlocked {
                        Button {
                            explorationMode=true
                            selectedLevel=9
                            selectedArea=2
                            screen="run"
                        } label: {
                            Label("FREE ROAM  ·  CACHES",systemImage:"binoculars.fill")
                                .font(.system(size:9,weight:.black))
                                .foregroundStyle(.cyan)
                        }
                    }
                }
                .padding(16)
                .frame(width:320,alignment:.leading)
                .background(LinearGradient(colors:[Color.black.opacity(0.45),Color.black.opacity(0.22)],startPoint:.topLeading,endPoint:.bottomTrailing),in:RoundedRectangle(cornerRadius:18))
                .overlay(RoundedRectangle(cornerRadius:18).stroke(.white.opacity(0.13),lineWidth:1))
            }
            .padding(.horizontal,14)
            .padding(.vertical,12)
        }
        .scrollIndicators(.hidden)
    }
    @State private var dailyMessage = "CLAIM DAILY SUPPLY"

    private var levels:some View {
        VStack(spacing:12) {
            Text("THE WASTELAND").font(.system(size:30,weight:.black,design:.rounded))
            Text("Choose your next route").foregroundStyle(.white.opacity(0.6))
            ScrollView(.horizontal) {
                HStack(spacing:12) {
                    ForEach(Biome.all) { biome in
                        Button { if biome.id<=progress.unlockedLevel { selectedLevel=biome.id } } label:{
                            VStack(alignment:.leading,spacing:10) {
                                Text(String(format:"%02d",biome.id+1)).font(.system(size:26,weight:.black,design:.rounded))
                                Text(biome.name).font(.system(size:12,weight:.heavy)).lineLimit(2)
                                Text(biome.id<=progress.unlockedLevel ? (selectedLevel==biome.id ? "SELECTED" : "AVAILABLE") : "LOCKED").font(.system(size:9,weight:.black)).foregroundStyle(biome.id<=progress.unlockedLevel ? .green : .gray)
                            }.frame(width:142,height:120,alignment:.leading).padding(12).background(Color(red:biome.sky.0,green:biome.sky.1,blue:biome.sky.2).opacity(0.8),in:RoundedRectangle(cornerRadius:16))
                        }.disabled(biome.id>progress.unlockedLevel)
                    }
                }.padding(.horizontal,6)
            }.frame(height:165)
            Text(Biome.all[min(max(selectedLevel,0),9)].name).font(.system(size:14,weight:.black)).foregroundStyle(.orange)
            HStack(spacing:10) {
                ForEach(0..<3,id:\.self) { area in
                    let key = "\(selectedLevel)-\(area-1)"
                    let unlocked = area == 0 || progress.areaProgress[key,default:0] > 0
                    Button {
                        if unlocked { selectedArea=area;screen="run" }
                    } label: {
                        VStack(spacing:5) {
                            Text("AREA \(area+1)").font(.system(size:12,weight:.black))
                            Text("\(Int(Biome.all[selectedLevel].areaLengths[area])) m").font(.system(size:10,weight:.bold))
                            Text(progress.areaProgress["\(selectedLevel)-\(area)",default:0] > 0 ? "CLEARED" : (unlocked ? "DRIVE" : "LOCKED")).font(.system(size:9,weight:.black))
                        }.frame(maxWidth:.infinity).padding(.vertical,13).background(unlocked ? Color.orange.opacity(0.22) : Color.white.opacity(0.05),in:RoundedRectangle(cornerRadius:12))
                    }.disabled(!unlocked)
                }
            }
            Text("Clear each area to unlock the next. The three routes grow longer and pay more.").font(.system(size:12)).foregroundStyle(.white.opacity(0.6)).multilineTextAlignment(.center)
        }
    }

    private var garage: some View {
        GeometryReader { geometry in
            let spec = VehicleSpec.roster[min(max(garageVehicle,0),VehicleSpec.roster.count-1)]
            ScrollView(.vertical) {
                VStack(spacing:10) {
                    HStack(alignment:.firstTextBaseline) {
                        Text("MOTOR POOL")
                            .font(.system(size:25,weight:.black,design:.rounded))
                            .tracking(1.5)
                        Spacer()
                        Text(String(format:"VEHICLE %02d / 10",garageVehicle+1))
                            .font(.system(size:10,weight:.black,design:.monospaced))
                            .foregroundStyle(.orange)
                    }

                    HStack(spacing:14) {
                        TabView(selection:$garageVehicle) {
                            ForEach(VehicleSpec.roster) { vehicle in
                                Image(uiImage:UIImage(cgImage:ArtFactory.vehicle(colorHex:vehicle.color,style:vehicle.id).cgImage()))
                                    .resizable()
                                    .scaledToFit()
                                    .padding(.horizontal,14)
                                    .padding(.vertical,22)
                                    .tag(vehicle.id)
                            }
                        }
                        .tabViewStyle(.page(indexDisplayMode:.never))
                        .frame(width:geometry.size.width*0.50,height:min(166,max(130,geometry.size.height*0.48)))
                        .background(
                            LinearGradient(colors:[Color(red:0.22,green:0.17,blue:0.15),Color(red:0.08,green:0.09,blue:0.11)],startPoint:.topLeading,endPoint:.bottomTrailing),
                            in:RoundedRectangle(cornerRadius:18)
                        )
                        .overlay(RoundedRectangle(cornerRadius:18).stroke(.white.opacity(0.13),lineWidth:1))

                        VStack(alignment:.leading,spacing:9) {
                            HStack {
                                Button {
                                    garageVehicle = max(0,garageVehicle-1)
                                } label: {
                                    Image(systemName:"chevron.left").font(.system(size:12,weight:.black))
                                }.disabled(garageVehicle == 0)
                                Spacer()
                                Button {
                                    garageVehicle = min(9,garageVehicle+1)
                                } label: {
                                    Image(systemName:"chevron.right").font(.system(size:12,weight:.black))
                                }.disabled(garageVehicle == 9)
                            }.foregroundStyle(.orange)

                            Text(spec.name)
                                .font(.system(size:21,weight:.black,design:.rounded))
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                            HStack(spacing:6) {
                                statBar("POWER",spec.power/3.1)
                                statBar("ARMOR",spec.armor/4.5)
                                statBar("FUEL",spec.fuel/230)
                            }
                            if progress.unlockedVehicles.contains(spec.id) {
                                Button(progress.selectedVehicle == spec.id ? "EQUIPPED" : "EQUIP VEHICLE") {
                                    progress.selectedVehicle = spec.id
                                    progress.save()
                                }.buttonStyle(PrimaryStyle()).disabled(progress.selectedVehicle == spec.id)
                            } else {
                                Button("UNLOCK  ·  $\(spec.price)") {
                                    _ = progress.buyVehicle(spec.id)
                                }.buttonStyle(PrimaryStyle()).disabled(progress.cash < spec.price)
                            }
                        }
                        .frame(maxWidth:.infinity,alignment:.leading)
                        .padding(.vertical,8)
                    }

                    HStack(spacing:8) {
                        upgradeButton("ENGINE","engine","Acceleration")
                        upgradeButton("FUEL","fuel","Run time")
                        upgradeButton("ARMOR","armor","Impact strength")
                        upgradeButton("WEAPON","weapon","Mounted gun")
                    }

                    HStack {
                        Text("NEXT RECOMMENDATION")
                            .font(.system(size:9,weight:.black,design:.rounded))
                            .foregroundStyle(.white.opacity(0.5))
                        Spacer()
                        Text(progress.tier("engine") < 2 ? "ENGINE" : progress.tier("fuel") < 2 ? "FUEL TANK" : progress.tier("armor") < 2 ? "ARMOR" : "WEAPON")
                            .font(.system(size:11,weight:.black,design:.rounded))
                            .foregroundStyle(.orange)
                    }
                }
                .padding(.horizontal,8)
                .padding(.vertical,6)
            }
            .scrollIndicators(.hidden)
            .onAppear { garageVehicle = progress.selectedVehicle }
        }
    }

    private var missions:some View {
        VStack(spacing:14) {
            Text("SURVIVAL CONTRACTS").font(.system(size:28,weight:.black,design:.rounded))
            if progress.missionsUnlocked {
                Text("50 contracts · rewards are credited automatically").font(.system(size:11,weight:.medium)).foregroundStyle(.white.opacity(0.55))
                ScrollView {
                    LazyVStack(spacing:8) {
                        ForEach(MissionSpec.all) { mission in
                            let current = progress.missionProgress(mission)
                            let completed = progress.claimedMissions.contains(mission.id)
                            HStack(spacing:12) {
                                Image(systemName: completed ? "checkmark.seal.fill" : "target")
                                    .font(.system(size:20,weight:.bold))
                                    .foregroundStyle(completed ? .green : .orange)
                                    .frame(width:28)
                                VStack(alignment:.leading,spacing:5) {
                                    Text(mission.title).font(.system(size:11,weight:.black))
                                    Text(mission.detail).font(.system(size:10)).foregroundStyle(.white.opacity(0.65))
                                    ProgressView(value:Double(min(current,mission.target)),total:Double(max(1,mission.target)))
                                        .tint(completed ? .green : .orange)
                                    Text("\(min(current,mission.target)) / \(mission.target)")
                                        .font(.system(size:9,weight:.bold,design:.monospaced)).foregroundStyle(.white.opacity(0.55))
                                }
                                Spacer(minLength:4)
                                VStack(spacing:3) {
                                    Text(completed ? "PAID" : "+$\(mission.reward)")
                                        .font(.system(size:10,weight:.black)).foregroundStyle(completed ? .green : .yellow)
                                    Text(String(repeating:"★",count:progress.missionStars[mission.id,default:0]) + String(repeating:"☆",count:3-progress.missionStars[mission.id,default:0]))
                                        .font(.system(size:10,weight:.black)).foregroundStyle(.yellow)
                                }
                            }.padding(10).background(.white.opacity(0.06),in:RoundedRectangle(cornerRadius:10))
                        }
                    }
                }.frame(maxHeight:300)
            } else {
                Image(systemName:"lock.fill").font(.largeTitle).foregroundStyle(.orange)
                Text("Clear area 3 of the first region to unlock contracts. Reach the evacuation port to unlock exploration.").multilineTextAlignment(.center).foregroundStyle(.white.opacity(0.65))
            }
        }
    }

    private var settings:some View {
        VStack(spacing:18) {
            Text("SETTINGS").font(.system(size:30,weight:.black,design:.rounded))
            Toggle("Game audio",isOn:$progress.audioEnabled).tint(.orange)
            Toggle("Haptic feedback",isOn:$progress.hapticsEnabled).tint(.orange)
            Toggle("Large HUD",isOn:$progress.largeHUD).tint(.orange)
            Toggle("Left-handed controls",isOn:$progress.leftHandedControls).tint(.orange)
            VStack(alignment:.leading) { Text("Control size");Slider(value:$progress.controlScale,in:0.8...1.3) }
            Button("RESET PROGRESS",role:.destructive){showReset=true}
            Button("PREPARE SAVE EXPORT") { exportSave() }.buttonStyle(SecondaryStyle())
            Button("IMPORT SAVE FILE") { showImportConfirm = true }.buttonStyle(SecondaryStyle())
            if shareURL != nil {
                Button("SHARE SAVE FILE") { showShare = true }.buttonStyle(SecondaryStyle())
            }
        }.padding(.horizontal,40).frame(maxWidth:520)
            .confirmationDialog("Importing replaces the current local progress.", isPresented: $showImportConfirm, titleVisibility: .visible) {
                Button("Choose JSON Save", role: .destructive) { showImportPicker = true }
                Button("Cancel", role: .cancel) {}
            }
            .alert("Save import", isPresented: $showImportNotice) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(importNotice)
            }
    }

    private var howto:some View {
        VStack(spacing:15) {
            Text("SURVIVAL 101").font(.system(size:30,weight:.black,design:.rounded))
            instruction("GAS","Hold the right pedal to accelerate.")
            instruction("BRAKE / REVERSE","Use the left pedal to slow down or reverse.")
            instruction("TILT","Use the two center controls to rotate in mid-air.")
            instruction("BOOST","Boost charges are collected on the road. Spend them for a burst.")
            instruction("WEAPON","Buy a mounted weapon upgrade, then hold FIRE to clear infected ahead.")
            instruction("FUEL","Fuel cans refill your tank. When empty, keep rolling to stretch your run.")
            instruction("GAMEPAD","Triggers accelerate/brake, left stick tilts, B boosts, and A fires when a weapon is installed.")
            instruction("EXPLORATION","After clearing the final region, free roam for hidden survival caches.")
        }.padding(.horizontal,40).frame(maxWidth:600)
    }

    private var achievements:some View {
        VStack(spacing:10) {
            Text("FIELD RECORDS").font(.system(size:28,weight:.black,design:.rounded))
            metric("FIRST BLOOD","\(progress.totalKills) / 1 infected")
            metric("ROAD WARRIOR","\(progress.bestDistance) / 5,000 m")
            metric("MILE EATER","\(progress.runs) runs completed")
            metric("FLEET COMMANDER","\(progress.unlockedVehicles.count) / 10 vehicles")
            metric("CACHE RUNNER","\(progress.totalHiddenKits) survival kits")
            metric("ROUTE CLEARER","\(progress.areasCleared) / 30 areas")
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
        let tier = progress.tier(key)
        let cost = progress.upgradeCost(key)
        let canBuy = tier < 5 && progress.cash >= cost && progress.unlockedVehicles.contains(progress.selectedVehicle)
        return Button {
            _ = progress.buyUpgrade(key)
        } label: {
            VStack(alignment:.leading,spacing:5) {
                HStack {
                    Text(title).font(.system(size:10,weight:.black,design:.rounded))
                    Spacer(minLength:2)
                    Text("LV \(tier)/5").font(.system(size:8,weight:.bold,design:.monospaced)).foregroundStyle(.orange)
                }
                ProgressView(value:Double(tier),total:5).tint(.orange)
                HStack {
                    Text(tier < 5 ? "$\(cost)" : "MAX LEVEL")
                        .font(.system(size:12,weight:.black,design:.rounded))
                        .foregroundStyle(canBuy ? .yellow : .white.opacity(0.6))
                    Spacer(minLength:0)
                    Image(systemName:tier < 5 ? "plus.circle.fill" : "checkmark.seal.fill")
                        .font(.system(size:11,weight:.bold))
                        .foregroundStyle(canBuy ? .orange : .white.opacity(0.4))
                }
                Text(detail).font(.system(size:8,weight:.medium)).foregroundStyle(.white.opacity(0.58)).lineLimit(1)
            }
            .padding(9)
            .frame(maxWidth:.infinity,minHeight:67,alignment:.leading)
            .background(LinearGradient(colors:[Color.white.opacity(0.10),Color.white.opacity(0.035)],startPoint:.topLeading,endPoint:.bottomTrailing),in:RoundedRectangle(cornerRadius:12))
            .overlay(RoundedRectangle(cornerRadius:12).stroke(canBuy ? Color.orange.opacity(0.30) : Color.white.opacity(0.08),lineWidth:1))
        }
        .buttonStyle(.plain)
        .disabled(!canBuy)
    }
    private func statBar(_ title:String,_ value:Double)->some View {
        VStack(spacing:3) { Text(title).font(.system(size:8,weight:.black));ProgressView(value:min(1,max(0,value))).tint(.orange).frame(width:75) }
    }
    private func instruction(_ title:String,_ text:String)->some View {
        HStack(alignment:.top) { Text(title).font(.system(size:12,weight:.black)).frame(width:130,alignment:.leading).foregroundStyle(.orange);Text(text).font(.system(size:12)).foregroundStyle(.white.opacity(0.75));Spacer(minLength:0) }
    }
    private func importSave(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else {
                importNotice = "No save file was selected."
                showImportNotice = true
                return
            }
            let accessed = url.startAccessingSecurityScopedResource()
            defer { if accessed { url.stopAccessingSecurityScopedResource() } }
            do {
                let data = try Data(contentsOf: url)
                importNotice = progress.importSave(data: data) ? "Save imported successfully." : "That file is not a valid DEAD MILE save."
            } catch {
                importNotice = "Could not read the selected file: \(error.localizedDescription)"
            }
        case .failure(let error):
            importNotice = "Import failed: \(error.localizedDescription)"
        }
        showImportNotice = true
    }

    private func exportSave() {
        let url=FileManager.default.temporaryDirectory.appendingPathComponent("deadmile-save-v1.json")
        progress.save()
        if let data=try? Data(contentsOf:FileManager.default.urls(for:.applicationSupportDirectory,in:.userDomainMask)[0].appendingPathComponent("deadmile-save-v1.json")) {
            do {
                try data.write(to:url, options:.atomic)
                shareURL=url
            } catch {
                print("Save export failed: \(error.localizedDescription)")
            }
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


private struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

private struct MenuBackdrop: View {
    var body: some View {
        Canvas { context, size in
            let sky = Path(CGRect(origin:.zero,size:size))
            context.fill(sky,with:.linearGradient(Gradient(colors:[Color(red:0.10,green:0.12,blue:0.17),Color(red:0.30,green:0.15,blue:0.14),Color(red:0.08,green:0.08,blue:0.10)]),startPoint:CGPoint(x:0,y:0),endPoint:CGPoint(x:size.width*0.72,y:size.height)))

            let sunRect = CGRect(x:size.width*0.66,y:size.height*0.20,width:size.height*0.34,height:size.height*0.34)
            context.fill(Path(ellipseIn:sunRect.insetBy(dx:-size.height*0.12,dy:-size.height*0.12)),with:.radialGradient(Gradient(colors:[Color.orange.opacity(0.34),Color.orange.opacity(0)]),center:CGPoint(x:sunRect.midX,y:sunRect.midY),startRadius:2,endRadius:size.height*0.34))
            context.fill(Path(ellipseIn:sunRect),with:.linearGradient(Gradient(colors:[Color(red:1,green:0.68,blue:0.35),Color(red:0.73,green:0.24,blue:0.17)]),startPoint:CGPoint(x:sunRect.midX,y:sunRect.minY),endPoint:CGPoint(x:sunRect.midX,y:sunRect.maxY)))

            var far = Path()
            far.move(to:CGPoint(x:0,y:size.height*0.70))
            for i in 0...14 {
                let x = size.width*CGFloat(i)/14
                let waveA = sin(Double(i)*1.2) * 0.10
                let waveB = cos(Double(i)*2.1) * 0.035
                let relativeY: Double = 0.55 + waveA + waveB
                let y = size.height * CGFloat(relativeY)
                far.addLine(to:CGPoint(x:x,y:y))
            }
            far.addLine(to:CGPoint(x:size.width,y:size.height))
            far.addLine(to:CGPoint(x:0,y:size.height))
            far.closeSubpath()
            context.fill(far,with:.color(Color(red:0.19,green:0.12,blue:0.13).opacity(0.92)))

            var near = Path()
            near.move(to:CGPoint(x:0,y:size.height*0.78))
            for i in 0...12 {
                let x = size.width*CGFloat(i)/12
                let waveA = sin(Double(i)*1.65) * 0.035
                let waveB = cos(Double(i)*0.72) * 0.025
                let relativeY: Double = 0.66 + waveA + waveB
                let y = size.height * CGFloat(relativeY)
                near.addLine(to:CGPoint(x:x,y:y))
            }
            near.addLine(to:CGPoint(x:size.width,y:size.height))
            near.addLine(to:CGPoint(x:0,y:size.height))
            near.closeSubpath()
            context.fill(near,with:.color(Color(red:0.075,green:0.075,blue:0.085)))

            for i in 0..<18 {
                let x = size.width*CGFloat(i)/18
                let width = size.width*CGFloat(0.018 + Double(i%4)*0.004)
                let height = size.height*CGFloat(0.10 + Double((i*7)%9)*0.025)
                let building = CGRect(x:x,y:size.height*0.69-height,width:width,height:height)
                context.fill(Path(building),with:.color(Color(red:0.065,green:0.07,blue:0.08).opacity(0.92)))
                for row in 0..<3 {
                    let windowX: CGFloat = building.minX + width * 0.24
                    let rowFactor: CGFloat = 0.20 + CGFloat(row) * 0.22
                    let windowY: CGFloat = building.minY + height * rowFactor
                    let windowWidth: CGFloat = width * 0.16
                    let windowRect = CGRect(x:windowX,y:windowY,width:windowWidth,height:3)
                    let windowPath = Path(windowRect)
                    let windowColor = Color.orange.opacity(0.32)
                    context.fill(windowPath,with:.color(windowColor))
                }
            }

            var road = Path()
            road.move(to:CGPoint(x:0,y:size.height*0.82))
            road.addCurve(to:CGPoint(x:size.width,y:size.height*0.83),control1:CGPoint(x:size.width*0.30,y:size.height*0.77),control2:CGPoint(x:size.width*0.68,y:size.height*0.87))
            context.stroke(road,with:.color(Color(red:0.75,green:0.31,blue:0.16).opacity(0.75)),style:StrokeStyle(lineWidth:max(8,size.height*0.025),lineCap:.round))
            var roadMark = Path()
            roadMark.move(to:CGPoint(x:0,y:size.height*0.82))
            roadMark.addCurve(to:CGPoint(x:size.width,y:size.height*0.83),control1:CGPoint(x:size.width*0.30,y:size.height*0.77),control2:CGPoint(x:size.width*0.68,y:size.height*0.87))
            context.stroke(roadMark,with:.color(Color(red:0.93,green:0.67,blue:0.39).opacity(0.55)),style:StrokeStyle(lineWidth:2,dash:[18,24]))
            context.fill(Path(CGRect(x:0,y:size.height*0.88,width:size.width,height:size.height*0.12)),with:.linearGradient(Gradient(colors:[Color.black.opacity(0.15),Color.black.opacity(0.75)]),startPoint:CGPoint(x:0,y:size.height*0.88),endPoint:CGPoint(x:0,y:size.height)))
        }
    }
}
