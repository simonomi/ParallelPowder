import SwiftUI
import MetalKit

struct MetalMapView: NSViewRepresentable {
	var metalKitView: MTKView
	var renderer: Renderer
	
	init() {
		metalKitView = MTKView()
		metalKitView.device = MTLCreateSystemDefaultDevice()!
//		metalKitView.preferredFramesPerSecond = 2
		
		renderer = Renderer(metalKitView: metalKitView)
		metalKitView.delegate = renderer
	}
	
	func makeNSView(context: NSViewRepresentableContext<MetalMapView>) -> MTKView {
		metalKitView
	}
	
	func updateNSView(_ uiView: MTKView, context: NSViewRepresentableContext<MetalMapView>) {}
}
