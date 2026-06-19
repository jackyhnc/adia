import SwiftUI

struct NotchRootView: View {
    @ObservedObject var state: NotchState
    @ObservedObject var session: SessionManager

    var body: some View {
        ZStack {
            if state.isExpanded {
                ExpandedView(state: state, session: session)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.96, anchor: .top).combined(with: .opacity),
                        removal:   .scale(scale: 0.96, anchor: .top).combined(with: .opacity)
                    ))
            } else {
                CollapsedView(state: state, session: session)
                    .transition(.opacity)
            }
        }
        .animation(.spring(response: 0.28, dampingFraction: 0.82), value: state.isExpanded)
    }
}
