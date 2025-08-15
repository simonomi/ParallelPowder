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
	
	let copyPipeline: MTLRenderPipelineState
	
	let uniformsBuffer: MTLBuffer
	
	var boards: [MTLBuffer]
	
	var displayBuffer: MTLTexture?
	
	var currentSize: CGSize
	
	init(metalKitView: MTKView) {
		device = metalKitView.device!
		commandQueue = device.makeCommandQueue()!
		
		copyPipeline = Self.buildCopyPipeline(device, metalKitView)
		
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
		
		super.init()
	}
	
	static func buildCopyPipeline(_ device: MTLDevice, _ metalKitView: MTKView) -> MTLRenderPipelineState {
		let library = device.makeDefaultLibrary()!
		
		let pipelineDescriptor = MTLRenderPipelineDescriptor()
		pipelineDescriptor.vertexFunction = library.makeFunction(name: "copyVertex")
		pipelineDescriptor.fragmentFunction = library.makeFunction(name: "copyFragment")
		pipelineDescriptor.colorAttachments[0].pixelFormat = metalKitView.colorPixelFormat
		
		return try! device.makeRenderPipelineState(descriptor: pipelineDescriptor)
	}
	
	func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
		currentSize = size
		
		let (width, height) = (Int(size.width), Int(size.height))
		
		print(width, height)
		
		let textureDescriptor = MTLTextureDescriptor()
		textureDescriptor.pixelFormat = view.colorPixelFormat
		textureDescriptor.textureType = .type2D
		textureDescriptor.width = width
		textureDescriptor.height = height
		
		textureDescriptor.storageMode = .private
		textureDescriptor.usage = [.shaderRead, .shaderWrite]
		
		displayBuffer = device.makeTexture(descriptor: textureDescriptor)!
		
		boards = (0..<2).map { _ in
			device.makeBuffer(
				bytes: Self.randomPixels(width: width, height: height),
				length: width * height
			)!
		}
		
		updateUniforms(size: size)
	}
	
	func updateUniforms(size: CGSize) {
		uniformsBuffer.contents()
			.withMemoryRebound(to: Uniforms.self, capacity: 1) { uniforms in
				uniforms.pointee.width = UInt32(size.width)
				uniforms.pointee.height = UInt32(size.height)
				
				uniforms.pointee.frameNumber = 1
			}
	}
	
	func draw(in view: MTKView) {
		guard let drawable = view.currentDrawable else { return }
		
		processInput()
		
		uniformsBuffer.contents()
			.withMemoryRebound(to: Uniforms.self, capacity: 1) { uniforms in
				uniforms.pointee.frameNumber += 1
			}
		
		let commandBuffer = commandQueue.makeCommandBuffer()!
		
		let library = device.makeDefaultLibrary()!
		if !isPaused {
			// tick
			let tick = library.makeFunction(name: "tick")!
			let computePipelineState = try! device.makeComputePipelineState(function: tick)
			
			let computeEncoder = commandBuffer.makeComputeCommandEncoder()!
			
			computeEncoder.setBuffer(uniformsBuffer, offset: 0, index: 0)
			computeEncoder.setBuffer(boards[0], offset: 0, index: 1)
			computeEncoder.setBuffer(boards[1], offset: 0, index: 2)
			
			computeEncoder.setComputePipelineState(computePipelineState)
			
			let (width, height) = (Int(view.drawableSize.width), Int(view.drawableSize.height))
			let threadsPerThreadgroup = MTLSize(width: 8, height: 8, depth: 1)
			let threadGridSize = MTLSize(
				width: width / threadsPerThreadgroup.width + 1,
				height: height / threadsPerThreadgroup.height + 1,
				depth: 1
			)
			computeEncoder.dispatchThreadgroups(threadGridSize, threadsPerThreadgroup: threadsPerThreadgroup)
			
			computeEncoder.endEncoding()
			
			boards.swapAt(0, 1)
		}
		
		// drawBoard
		let drawBoard = library.makeFunction(name: "drawBoard")!
		let computePipelineState = try! device.makeComputePipelineState(function: drawBoard)
		
		let computeEncoder = commandBuffer.makeComputeCommandEncoder()!
		
		computeEncoder.setBuffer(uniformsBuffer, offset: 0, index: 0)
		computeEncoder.setBuffer(boards[0], offset: 0, index: 1)
		
		computeEncoder.setTexture(displayBuffer, index: 0)
		
		computeEncoder.setComputePipelineState(computePipelineState)
		
		let (width, height) = (Int(view.drawableSize.width), Int(view.drawableSize.height))
		let threadsPerThreadgroup = MTLSize(width: 8, height: 8, depth: 1)
		let threadGridSize = MTLSize(
			width: width / threadsPerThreadgroup.width + 1,
			height: height / threadsPerThreadgroup.height + 1,
			depth: 1
		)
		computeEncoder.dispatchThreadgroups(threadGridSize, threadsPerThreadgroup: threadsPerThreadgroup)
		
		computeEncoder.endEncoding()
			
		// render stuff
		let renderPassDescriptor = view.currentRenderPassDescriptor!
		
		renderPassDescriptor.colorAttachments[0].loadAction = .dontCare
		renderPassDescriptor.colorAttachments[0].storeAction = .store
		
		let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
		
		renderEncoder.setRenderPipelineState(copyPipeline)
		renderEncoder.setFragmentTexture(displayBuffer, index: 0)
		renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
		
		renderEncoder.endEncoding()
		
		commandBuffer.present(drawable)
		commandBuffer.commit()
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
