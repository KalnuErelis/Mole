import SwiftUI
import SwiftTerm

struct TerminalContainerView: NSViewRepresentable {
    @ObservedObject var session: TerminalSession

    func makeNSView(context: Context) -> LocalProcessTerminalView {
        let terminalView = LocalProcessTerminalView(frame: .zero)
        session.attach(view: terminalView)
        return terminalView
    }

    func updateNSView(_ nsView: LocalProcessTerminalView, context: Context) {
        if session.terminalView !== nsView {
            session.attach(view: nsView)
        }
    }
}
