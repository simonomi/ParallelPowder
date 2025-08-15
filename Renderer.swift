import MetalKit

var isPaused = false

var reset = false
var isDrawing = false
var drawLocation = CGPoint(x: -1, y: -1)

var radius = 1

var drawCanvas: Pixel = .air
var drawPaint: Pixel = .sand

class Renderer: NSObject, MTKViewDelegate {
	var device: MTLDevice
	var commandQueue: MTLCommandQueue
	
	let tickPipeline: MTLComputePipelineState
	let renderPipeline: MTLRenderPipelineState
	
	let uniformsBuffer: MTLBuffer
	
	var boards: [MTLBuffer]
	
	var currentSize: CGSize
	
	var threadGridSize: MTLSize
	var threadsPerThreadgroup: MTLSize
	
	init(metalKitView: MTKView) {
		device = metalKitView.device!
		commandQueue = device.makeCommandQueue()!
		
		let library = device.makeDefaultLibrary()!
		
		tickPipeline = Self.buildTickPipeline(device, library)
		renderPipeline = Self.buildRenderPipeline(device, metalKitView)
		
		var initialUniforms = Uniforms(
			width: UInt32(metalKitView.drawableSize.width),
			height: UInt32(metalKitView.drawableSize.height),
			frameNumber: 1,
		)
		uniformsBuffer = device.makeBuffer(
			bytes: &initialUniforms,
			length: MemoryLayout<Uniforms>.size
		)!
		
		boards = []
		
		currentSize = metalKitView.drawableSize
		
		(threadGridSize, threadsPerThreadgroup) = Self.threadSizes(for: currentSize)
		
		super.init()
	}
	
	static func buildTickPipeline(_ device: MTLDevice, _ library: MTLLibrary) -> MTLComputePipelineState {
		let tick = library.makeFunction(name: "tick")!
		return try! device.makeComputePipelineState(function: tick)
	}
	
	static func buildRenderPipeline(_ device: MTLDevice, _ metalKitView: MTKView) -> MTLRenderPipelineState {
		let library = device.makeDefaultLibrary()!
		
		let pipelineDescriptor = MTLRenderPipelineDescriptor()
		pipelineDescriptor.vertexFunction = library.makeFunction(name: "fullScreenVertices")
		pipelineDescriptor.fragmentFunction = library.makeFunction(name: "drawBoard")
		pipelineDescriptor.colorAttachments[0].pixelFormat = metalKitView.colorPixelFormat
		
		return try! device.makeRenderPipelineState(descriptor: pipelineDescriptor)
	}
	
	static func threadSizes(for viewSize: CGSize) -> (MTLSize, MTLSize) {
		let threadsPerThreadgroup = MTLSize(width: 8, height: 8, depth: 1)
		let threadGridSize = MTLSize(
			width: Int(viewSize.width) / threadsPerThreadgroup.width + 1,
			height: Int(viewSize.height) / threadsPerThreadgroup.height + 1,
			depth: 1
		)
		return (threadGridSize, threadsPerThreadgroup)
	}
	
	func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
		currentSize = size
		(threadGridSize, threadsPerThreadgroup) = Self.threadSizes(for: currentSize)
		
		let (width, height) = (Int(size.width), Int(size.height))
		
		print("resized to \(width)x\(height)")
		
		let textureDescriptor = MTLTextureDescriptor()
		textureDescriptor.pixelFormat = view.colorPixelFormat
		textureDescriptor.textureType = .type2D
		textureDescriptor.width = width
		textureDescriptor.height = height
		
		textureDescriptor.storageMode = .private
		textureDescriptor.usage = [.shaderRead, .shaderWrite]
		
		boards = (0..<2).map { _ in
			device.makeBuffer(
				bytes: Self.randomPixels(width: width, height: height),
				length: width * height
			)!
		}
		
		updateUniforms(to: size)
	}
	
	func updateUniforms(to size: CGSize) {
		uniformsBuffer.contents()
			.withMemoryRebound(to: Uniforms.self, capacity: 1) { uniforms in
				uniforms.pointee.width = UInt32(size.width)
				uniforms.pointee.height = UInt32(size.height)
				
				uniforms.pointee.frameNumber = 1
			}
	}
	
	func draw(in view: MTKView) {
		precondition(view.drawableSize == currentSize)
		
		guard let drawable = view.currentDrawable else { return }
		
		processInput()
		
		uniformsBuffer.contents()
			.withMemoryRebound(to: Uniforms.self, capacity: 1) { uniforms in
				uniforms.pointee.frameNumber += 1
			}
		
		let commandBuffer = commandQueue.makeCommandBuffer()!
		
		if !isPaused {
			tick(commandBuffer)
			boards.swapAt(0, 1)
		}
		
		render(view, commandBuffer)
		
		commandBuffer.present(drawable)
		commandBuffer.commit()
	}
	
	func tick(_ commandBuffer: any MTLCommandBuffer) {
		let computeEncoder = commandBuffer.makeComputeCommandEncoder()!
		
		computeEncoder.setBuffer(uniformsBuffer, offset: 0, index: 0)
		computeEncoder.setBuffer(boards[0], offset: 0, index: 1)
		computeEncoder.setBuffer(boards[1], offset: 0, index: 2)
		
		computeEncoder.setComputePipelineState(tickPipeline)
		
		computeEncoder.dispatchThreadgroups(threadGridSize, threadsPerThreadgroup: threadsPerThreadgroup)
		
		computeEncoder.endEncoding()
	}
	
	func render(_ view: MTKView, _ commandBuffer: any MTLCommandBuffer) {
		let renderPassDescriptor = view.currentRenderPassDescriptor!
		
		renderPassDescriptor.colorAttachments[0].loadAction = .dontCare
		renderPassDescriptor.colorAttachments[0].storeAction = .store
		
		let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
		
		renderEncoder.setFragmentBuffer(uniformsBuffer, offset: 0, index: 0)
		renderEncoder.setFragmentBuffer(boards[0], offset: 0, index: 1)
		
		renderEncoder.setRenderPipelineState(renderPipeline)
		
		renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
		
		renderEncoder.endEncoding()
	}
	
	func processInput() {
		if reset {
			let (width, height) = (Int(currentSize.width), Int(currentSize.height))
			
			boards[0] = device.makeBuffer(
				bytes: Self.randomPixels(width: width, height: height),
				length: width * height
			)!
			
			reset = false
		}
		
		if isDrawing {
			let (width, height) = (Int(currentSize.width), Int(currentSize.height))
			let (x, y) = (Int(drawLocation.x * 2), height - Int(drawLocation.y * 2))
			
			if 0 < x, x < width, 0 < y, y < height {
				boards[0].contents().withMemoryRebound(
					to: Pixel.self,
					capacity: width * height
				) { pointer in
					for yOffset in -radius...radius {
						for xOffset in -radius...radius {
							let newX = x + xOffset
							let newY = y + yOffset
							
							if 0 <= newX, newX < width, 0 <= newY, newY < height {
								if pointer[newY * width + newX] == drawCanvas {
									pointer[newY * width + newX] = drawPaint
								}
							}
						}
					}
				}
			}
		}
	}
	
	static func randomPixels(width: Int, height: Int) -> [Pixel] {
		(0..<(width * height)).map {
			if ($0 % width) > (width / 3) && ($0 % width) < (width / 3 * 2) {
				.random() ? .sand : .air
			} else {
				.air
			}
		}
	}
}
