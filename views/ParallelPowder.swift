import SwiftUI

@main
struct ParallelPowder: App {
	@FocusState private var isFocused: Bool
	
	var body: some Scene {
		WindowGroup {
			MetalMapView()
				.focusable()
				.focusEffectDisabled()
				.focused($isFocused)
				.onAppear {
					isFocused = true
				}
				.onKeyPress("r") {
					reset = true
					return .handled
				}
				.gesture(
					DragGesture()
						.onChanged { state in
							print("drag", state.location)
						}
						.onEnded { _ in
							print("drag ended")
						}
				)
		}
	}
}
