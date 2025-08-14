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
							isDrawing = true
							drawLocation = state.location
						}
						.onEnded { _ in
							isDrawing = false
						}
				)
		}
	}
}
