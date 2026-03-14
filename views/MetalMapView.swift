import SwiftUI
import MetalKit

struct MetalMapView: NSViewRepresentable {
	@Binding var isPaused: Bool
	
	@Binding var reset: Bool
	
	@Binding var drawLocation: CGPoint?
	
	@Binding var radius: Int
	
	@Binding var drawCanvas: Pixel
	@Binding var drawPaint: Pixel
	
	func makeCoordinator() -> Renderer {
		Renderer(
			isPaused: $isPaused,
			reset: $reset,
			drawLocation: $drawLocation,
			radius: $radius,
			drawCanvas: $drawCanvas,
			drawPaint: $drawPaint
		)
	}
	
	func makeNSView(context: Context) -> MTKView {
		let metalKitView = MTKView()
		metalKitView.device = MTLCreateSystemDefaultDevice()!
//		metalKitView.preferredFramesPerSecond = 2
		metalKitView.delegate = context.coordinator
		
		return metalKitView
	}
	
	func updateNSView(_ metalKitView: MTKView, context: Context) {
		metalKitView.device = MTLCreateSystemDefaultDevice()!
		metalKitView.delegate = context.coordinator
	}
}
