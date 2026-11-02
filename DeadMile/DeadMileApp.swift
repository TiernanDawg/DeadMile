import SwiftUI

@main
struct DeadMileApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var progress = PlayerProgress.load()

    var body: some Scene {
        WindowGroup {
            RootView(progress: progress)
                .preferredColorScheme(.dark)
                .statusBarHidden()
                .onChange(of: scenePhase) { _, phase in
                    if phase != .active { progress.save() }
                }
        }
    }
}
