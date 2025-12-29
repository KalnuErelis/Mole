import Foundation
import SwiftTerm
import AppKit

final class TerminalSession: NSObject, ObservableObject, LocalProcessTerminalViewDelegate {
    @Published var isRunning: Bool = false
    @Published var exitCode: Int32?
    @Published var title: String = "Mole Terminal"

    private(set) weak var terminalView: LocalProcessTerminalView?

    func attach(view: LocalProcessTerminalView) {
        terminalView = view
        view.processDelegate = self
        view.caretViewTracksFocus = true
        view.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        view.terminal.backgroundColor = SwiftTerm.Color(
            red: UInt16(0.06 * 65535.0),
            green: UInt16(0.08 * 65535.0),
            blue: UInt16(0.07 * 65535.0)
        )
        view.terminal.foregroundColor = SwiftTerm.Color(
            red: UInt16(0.86 * 65535.0),
            green: UInt16(0.92 * 65535.0),
            blue: UInt16(0.89 * 65535.0)
        )
    }

    func run(executable: String, args: [String], environment: [String]) {
        guard let view = terminalView else {
            return
        }

        exitCode = nil
        isRunning = true
        title = "Mole Terminal"

        view.startProcess(
            executable: executable,
            args: args,
            environment: environment,
            execName: nil
        )

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            view.window?.makeFirstResponder(view)
        }
    }

    func terminate() {
        terminalView?.send(txt: "\u{03}")
    }

    func clear() {
        guard let view = terminalView else {
            return
        }
        view.terminal.resetToInitialState()
        view.needsDisplay = true
    }

    // MARK: - LocalProcessTerminalViewDelegate

    func sizeChanged(source: LocalProcessTerminalView, newCols: Int, newRows: Int) {}

    func setTerminalTitle(source: LocalProcessTerminalView, title: String) {
        DispatchQueue.main.async {
            self.title = title
        }
    }

    func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {}

    func processTerminated(source: TerminalView, exitCode: Int32?) {
        DispatchQueue.main.async {
            self.exitCode = exitCode
            self.isRunning = false
        }
    }
}
