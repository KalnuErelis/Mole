import SwiftUI
import AppKit

struct SettingsView: View {
    @AppStorage("moleCliPath") private var cliPath: String = ""

    var body: some View {
        Form {
            Section("Mole CLI") {
                TextField("Path to mo", text: $cliPath)
                HStack {
                    Button("Choose…") {
                        choosePath()
                    }
                    Button("Reset") {
                        cliPath = ""
                    }
                    Spacer()
                }
                if let defaultPath = defaultCLIPath {
                    Text("Default: \(defaultPath)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(20)
        .frame(width: 480)
    }

    private var defaultCLIPath: String? {
        Bundle.main.object(forInfoDictionaryKey: "MoleCLIPath") as? String
    }

    private func choosePath() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.showsHiddenFiles = true
        panel.allowedContentTypes = []
        if panel.runModal() == .OK {
            if let url = panel.url {
                cliPath = url.path
            }
        }
    }
}
