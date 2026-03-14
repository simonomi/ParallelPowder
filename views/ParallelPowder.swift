import SwiftUI

@main
struct ParallelPowder: App {
	@FocusState private var isFocused: Bool
	
	@State private var cursorIsHidden: Bool = false
	
	@State private var inspectorPresented: Bool = true
	
	@State private var isPaused: Bool = false
	
	@State private var reset = false
	
	@State private var drawLocation: CGPoint?
	
	@State private var radius = 20
	
	@State private var drawCanvas: Pixel = .air
	@State private var drawPaint: Pixel = .sand
	
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
				
				Button(
					"Reset",
					systemImage: "arrow.counterclockwise"
				) {
					reset = true
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
				
				return .handled
			}
			.onChange(of: cursorIsHidden) { (_, newValue) in
				if newValue {
					NSCursor.hide()
				} else {
					NSCursor.unhide()
				}
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
