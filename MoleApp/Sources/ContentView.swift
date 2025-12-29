import SwiftUI
import AppKit

struct ContentView: View {
    @StateObject private var session = TerminalSession()
    @State private var selection: MoleModule = .overview
    @State private var options = ModuleOptions()
    @State private var showOptions = true

    @AppStorage("moleCliPath") private var cliPath: String = ""

    var body: some View {
        NavigationSplitView {
            List(MoleModule.allCases, selection: $selection) { module in
                VStack(alignment: .leading, spacing: 4) {
                    Text(module.title)
                        .font(.system(.body, design: .rounded).weight(.semibold))
                    Text(module.subtitle)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 6)
            }
            .listStyle(.sidebar)
            .navigationTitle("Mole")
        } detail: {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.08, green: 0.12, blue: 0.1),
                        Color(red: 0.06, green: 0.08, blue: 0.07)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 18) {
                    header
                    if showOptions {
                        optionsPanel
                    }
                    commandPanel
                    terminalPanel
                }
                .padding(24)
            }
        }
        .onChange(of: selection) { _ in
            options = ModuleOptions()
        }
        .toolbar {
            ToolbarItemGroup {
                Button {
                    runSelected()
                } label: {
                    Label("Run", systemImage: "play.fill")
                }
                .disabled(resolvedCLIPath == nil)

                Button {
                    session.terminate()
                } label: {
                    Label("Stop", systemImage: "stop.fill")
                }
                .disabled(!session.isRunning)

                Button {
                    session.clear()
                } label: {
                    Label("Clear", systemImage: "trash")
                }

                Button {
                    showOptions.toggle()
                } label: {
                    Label("Options", systemImage: showOptions ? "slider.horizontal.3" : "slider.horizontal.3")
                }
            }
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 6) {
                Text(selection.title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                Text(selection.subtitle)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                if let path = resolvedCLIPath {
                    Text("CLI: \(path)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    Text("CLI not found")
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
                statusBadge
            }
        }
    }

    private var statusBadge: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(session.isRunning ? Color.green : Color.gray)
                .frame(width: 8, height: 8)
            Text(session.isRunning ? "Running" : "Idle")
                .font(.footnote)
            if let exitCode = session.exitCode, !session.isRunning {
                Text("Exit: \(exitCode)")
                    .font(.footnote)
                    .foregroundStyle(exitCode == 0 ? .green : .orange)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.black.opacity(0.25))
        .clipShape(Capsule())
    }

    private var optionsPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Options")
                .font(.headline)
            HStack(spacing: 16) {
                if selection.supportsDryRun {
                    Toggle("Dry run", isOn: $options.dryRun)
                }
                if selection.supportsWhitelist {
                    Toggle("Whitelist", isOn: $options.whitelist)
                }
                if selection.supportsPaths {
                    Toggle("Manage paths", isOn: $options.managePaths)
                }
                if selection.supportsDebug {
                    Toggle("Debug", isOn: $options.debug)
                }
            }
            TextField("Extra arguments", text: $options.extraArgs)
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var commandPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Command preview")
                .font(.headline)
            Text(commandPreview)
                .font(.system(.body, design: .monospaced))
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.black.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var terminalPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(session.title)
                    .font(.headline)
                Spacer()
                Button("Focus Terminal") {
                    session.terminalView?.window?.makeFirstResponder(session.terminalView)
                }
            }
            TerminalContainerView(session: session)
                .frame(minHeight: 320)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08)))
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    private func runSelected() {
        guard let cliPath = resolvedCLIPath else {
            return
        }

        let args = buildArguments(for: selection, options: options)
        let environment = buildEnvironment()
        session.run(executable: cliPath, args: args, environment: environment)
    }

    private func buildArguments(for module: MoleModule, options: ModuleOptions) -> [String] {
        var args: [String] = []
        if !module.command.isEmpty {
            args.append(module.command)
        }

        if options.dryRun {
            args.append("--dry-run")
        }
        if options.whitelist {
            args.append("--whitelist")
        }
        if options.managePaths {
            args.append("--paths")
        }
        if options.debug {
            args.append("--debug")
        }

        if !options.extraArgs.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let extra = options.extraArgs
                .split(whereSeparator: { $0.isWhitespace })
                .map(String.init)
            args.append(contentsOf: extra)
        }

        return args
    }

    private func buildEnvironment() -> [String] {
        var env = ProcessInfo.processInfo.environment
        env["TERM"] = "xterm-256color"
        env["LC_ALL"] = "C"
        env["LANG"] = "C"
        return env.map { "\($0.key)=\($0.value)" }
    }

    private var commandPreview: String {
        let cli = resolvedCLIPath ?? "mo"
        let args = buildArguments(for: selection, options: options)
        return ([cli] + args).joined(separator: " ")
    }

    private var resolvedCLIPath: String? {
        let trimmed = cliPath.trimmingCharacters(in: .whitespacesAndNewlines)
        if let resolved = resolvePath(trimmed), FileManager.default.isExecutableFile(atPath: resolved) {
            return resolved
        }

        if let bundleValue = Bundle.main.object(forInfoDictionaryKey: "MoleCLIPath") as? String,
           let resolved = resolvePath(bundleValue), FileManager.default.isExecutableFile(atPath: resolved) {
            return resolved
        }

        let fallback = [
            "/opt/homebrew/bin/mo",
            "/usr/local/bin/mo",
            "/usr/bin/mo",
            "/opt/homebrew/bin/mole",
            "/usr/local/bin/mole"
        ]

        for path in fallback {
            if FileManager.default.isExecutableFile(atPath: path) {
                return path
            }
        }

        return resolveInPath("mo") ?? resolveInPath("mole")
    }

    private func resolvePath(_ input: String) -> String? {
        guard !input.isEmpty else { return nil }
        if input.hasPrefix("~") {
            return (input as NSString).expandingTildeInPath
        }
        return input
    }

    private func resolveInPath(_ executable: String) -> String? {
        let pathVar = ProcessInfo.processInfo.environment["PATH"] ?? ""
        for entry in pathVar.split(separator: ":") {
            let candidate = String(entry) + "/" + executable
            if FileManager.default.isExecutableFile(atPath: candidate) {
                return candidate
            }
        }
        return nil
    }

}
