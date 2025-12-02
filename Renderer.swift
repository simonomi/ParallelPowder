import Foundation
import MetalKit

var isPaused = false

var reset = false
var isDrawing = false
var drawLocation = CGPoint(x: -1, y: -1)

var radius = 1

var drawCanvas: Pixel = .air
var drawPaint: Pixel = .sand

var previousFrameDate = Date()

class Renderer: NSObject, MTKViewDelegate {
	var device: MTLDevice
	var commandQueue: MTLCommandQueue
	
	let makeGoalsPipeline: MTLComputePipelineState
	let updatePixelsPipeline: MTLComputePipelineState
	let renderPipeline: MTLRenderPipelineState
	
	let uniformsBuffer: MTLBuffer
	
	var boards: [MTLBuffer]
	
	var goalsBuffer: MTLBuffer
	
	var currentSize: CGSize
	
	init(metalKitView: MTKView) {
		device = metalKitView.device!
		commandQueue = device.makeCommandQueue()!
		
		let library = device.makeDefaultLibrary()!
		
		makeGoalsPipeline = Self.buildMakeGoalsPipeline(device, library)
		updatePixelsPipeline = Self.buildUpdatePixelsPipeline(device, library)
		renderPipeline = Self.buildRenderPipeline(device, metalKitView)
		
		var initialUniforms = Uniforms(
			width: UInt16(metalKitView.drawableSize.width),
			height: UInt16(metalKitView.drawableSize.height),
			frameNumber: 1,
		)
		uniformsBuffer = device.makeBuffer(
			bytes: &initialUniforms,
			length: MemoryLayout<Uniforms>.size
		)!
		
		boards = []
		
		goalsBuffer = device.makeBuffer(length: 1)!
		
		currentSize = metalKitView.drawableSize
		
		super.init()
	}
	
	static func buildMakeGoalsPipeline(
		_ device: MTLDevice,
		_ library: MTLLibrary
	) -> MTLComputePipelineState {
		let makeGoals = library.makeFunction(name: "makeGoals")!
		return try! device.makeComputePipelineState(function: makeGoals)
	}
	
	static func buildUpdatePixelsPipeline(
		_ device: MTLDevice,
		_ library: MTLLibrary
	) -> MTLComputePipelineState {
		let makeGoals = library.makeFunction(name: "updatePixels")!
		return try! device.makeComputePipelineState(function: makeGoals)
	}
	
	static func buildRenderPipeline(
		_ device: MTLDevice,
		_ metalKitView: MTKView
	) -> MTLRenderPipelineState {
		let library = device.makeDefaultLibrary()!
		
		let pipelineDescriptor = MTLRenderPipelineDescriptor()
		pipelineDescriptor.vertexFunction = library.makeFunction(name: "fullScreenVertices")
		pipelineDescriptor.fragmentFunction = library.makeFunction(name: "drawBoard")
		pipelineDescriptor.colorAttachments[0].pixelFormat = metalKitView.colorPixelFormat
		
		return try! device.makeRenderPipelineState(descriptor: pipelineDescriptor)
	}
	
	func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
		currentSize = size
		let (width, height) = (Int(size.width), Int(size.height))
		
		print("resized to \(width)x\(height)")
		
		boards = (0..<2).map { _ in
			device.makeBuffer(
				bytes: Self.allAir(width: width, height: height),
				length: width * height
			)!
		}
		
		goalsBuffer = device.makeBuffer(
			length: width * height * MemoryLayout<Goal>.stride
		)!
		
		setUniforms(to: size)
	}
	
	func setUniforms(to size: CGSize) {
		uniformsBuffer.contents()
			.withMemoryRebound(to: Uniforms.self, capacity: 1) { uniforms in
				uniforms.pointee.width = UInt16(size.width)
				uniforms.pointee.height = UInt16(size.height)
				
				uniforms.pointee.frameNumber = 1
			}
	}
	
	func draw(in view: MTKView) {
		precondition(view.drawableSize == currentSize)
		
		let fps = 1 / -previousFrameDate.timeIntervalSinceNow
		if fps.isFinite {
			print(Int(fps), "fps", separator: "")
		}
		
		previousFrameDate = .now
		
		guard let drawable = view.currentDrawable else { return }
		
		processInput()
		
		uniformsBuffer.contents()
			.withMemoryRebound(to: Uniforms.self, capacity: 1) { uniforms in
				uniforms.pointee.frameNumber &+= 1
			}
		
		let commandBuffer = commandQueue.makeCommandBuffer()!
		
		if !isPaused {
//			for _ in 0..<10 {
				tick(commandBuffer)
				boards.swapAt(0, 1)
//			}
		}
		
		render(view, commandBuffer)
		
		commandBuffer.present(drawable)
		commandBuffer.commit()
	}
	
	func tick(_ commandBuffer: any MTLCommandBuffer) {
		makeGoals(commandBuffer)
		updatePixels(commandBuffer)
	}
	
	func makeGoals(_ commandBuffer: any MTLCommandBuffer) {
		let computeEncoder = commandBuffer.makeComputeCommandEncoder()!
		
		computeEncoder.label = "makeGoals"
		
		computeEncoder.setBuffer(uniformsBuffer, offset: 0, index: 0)
		computeEncoder.setBuffer(boards[0], offset: 0, index: 1)
		computeEncoder.setBuffer(goalsBuffer, offset: 0, index: 2)
		
		computeEncoder.setComputePipelineState(makeGoalsPipeline)
		
		let threadsPerGrid = MTLSize(
			width: Int(currentSize.width),
			height: Int(currentSize.height),
			depth: 1
		)
		
		let w = makeGoalsPipeline.threadExecutionWidth
		let h = makeGoalsPipeline.maxTotalThreadsPerThreadgroup / w
		let threadsPerThreadgroup = MTLSize(width: w, height: h, depth: 1)
		
		computeEncoder.dispatchThreads(
			threadsPerGrid,
			threadsPerThreadgroup: threadsPerThreadgroup
		)
		
		computeEncoder.endEncoding()
	}
	
	func updatePixels(_ commandBuffer: any MTLCommandBuffer) {
		let computeEncoder = commandBuffer.makeComputeCommandEncoder()!
		
		computeEncoder.label = "updatePixels"
		
		computeEncoder.setBuffer(uniformsBuffer, offset: 0, index: 0)
		computeEncoder.setBuffer(boards[0], offset: 0, index: 1)
		computeEncoder.setBuffer(boards[1], offset: 0, index: 2)
		computeEncoder.setBuffer(goalsBuffer, offset: 0, index: 3)
		
		computeEncoder.setComputePipelineState(updatePixelsPipeline)
		
		let threadsPerGrid = MTLSize(
			width: Int(currentSize.width),
			height: Int(currentSize.height),
			depth: 1
		)
		
		let w = updatePixelsPipeline.threadExecutionWidth
		let h = updatePixelsPipeline.maxTotalThreadsPerThreadgroup / w
		let threadsPerThreadgroup = MTLSize(width: w, height: h, depth: 1)
		
		computeEncoder.dispatchThreads(
			threadsPerGrid,
			threadsPerThreadgroup: threadsPerThreadgroup
		)
		
		computeEncoder.endEncoding()
	}
	
	func render(_ view: MTKView, _ commandBuffer: any MTLCommandBuffer) {
		let renderPassDescriptor = view.currentRenderPassDescriptor!
		
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
				bytes: Self.allAir(width: width, height: height),
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
	
	static func allAir(width: Int, height: Int) -> [Pixel] {
		Array(repeating: .air, count: width * height)
	}
	
	static func randomTrees(width: Int, height: Int) -> [Pixel] {
		(0..<(width * height)).map { _ in
			if Int.random(in: 0..<5) == 0 {
				.tree
			} else {
				.air
			}
		}
	}
}
