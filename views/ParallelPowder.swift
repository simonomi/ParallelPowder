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
				.onKeyPress("w") {
					if drawPaint == .sand {
						drawPaint = .water
					} else if drawPaint == .water {
						drawPaint = .sand
					}
					
					return .handled
				}
				.onKeyPress(.tab) {
					(drawCanvas, drawPaint) = (drawPaint, drawCanvas)
					print("swap paint")
					
					return .handled
				}
				.onKeyPress("=") {
					radius += 1
					print("radius", radius)
					
					return .handled
				}
				.onKeyPress("-") {
					if radius > 0 {
						radius -= 1
						print("radius", radius)
					}
					
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
