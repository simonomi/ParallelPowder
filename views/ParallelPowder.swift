import SwiftUI

@main
struct ParallelPowder: App {
	@FocusState private var isFocused: Bool
	
	@State private var cursorIsHidden: Bool = false
	
	@State private var inspectorPresented: Bool = true
	
	@State private var isPaused: Bool = false
	
	@State var reset = false
	
	@State var drawLocation: CGPoint?
	
	@State var radius = 20
	
	@State var drawCanvas: Pixel = .air
	@State var drawPaint: Pixel = .sand
	
	var body: some Scene {
		WindowGroup {
			MetalMapView(
				isPaused: $isPaused,
				reset: $reset,
				drawLocation: $drawLocation,
				radius: $radius,
				drawCanvas: $drawCanvas,
				drawPaint: $drawPaint
			)
			.inspector(isPresented: $inspectorPresented) {
				Text("gadget")
			}
			.toolbar {
				Button(
					isPaused ? "Play" : "Pause",
					systemImage: isPaused ? "play.fill" : "pause.fill"
				) {
					isPaused.toggle()
				}
				
				Spacer()
				
				Button("Inspector", systemImage: "sidebar.trailing") {
					inspectorPresented.toggle()
				}
			}
			.focusable()
			.focusEffectDisabled()
			.focused($isFocused)
			.onAppear {
				isFocused = true
			}
			.onKeyPress(.space) {
				isPaused.toggle()
				
				return .handled
			}
			.onKeyPress("r") {
				reset = true
				
				return .handled
			}
			.onKeyPress("w") {
				if drawPaint == .sand {
					drawPaint = .water
				} else if drawPaint == .water {
					drawPaint = .block
				} else if drawPaint == .block {
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
			.onKeyPress("h") {
				cursorIsHidden.toggle()
				inspectorPresented = !cursorIsHidden
				
				if cursorIsHidden {
					NSCursor.hide()
				} else {
					NSCursor.unhide()
				}
				
				return .handled
			}
			.gesture(
				DragGesture()
					.onChanged { state in
						drawLocation = state.location
					}
					.onEnded { _ in
						drawLocation = nil
					}
			)
		}
	}
}
