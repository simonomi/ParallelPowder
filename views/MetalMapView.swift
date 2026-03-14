import SwiftUI
import MetalKit

struct MetalMapView: NSViewRepresentable {
	@Binding var isPaused: Bool
	
	func makeCoordinator() -> Renderer {
		Renderer(isPaused: $isPaused)
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
