#include <metal_stdlib>
#include "../SharedTypes.hpp"
#include "Board.hpp"

using namespace metal;

float4 colorFor(Pixel pixel) {
	switch (pixel) {
		case Pixel::outOfBounds:
			return float4(1, 1, 1, 1);
		case Pixel::air:
			return float4(0, 0, 0, 1);
		case Pixel::sand:
			return float4(1, 0.9, 0.8, 1);
		case Pixel::water:
			return float4(0, 0.4, 0.6, 1);
		default:
			return float4(1, 0, 1, 1);
	}
}

kernel void drawBoard(
	uint2 tid [[thread_position_in_grid]],
	constant const Uniforms* uniforms [[buffer(0)]],
	device Pixel* currentTick [[buffer(1)]],
	texture2d<float, access::write> displayBuffer [[texture(0)]]
) {
	if (tid.y >= uniforms->height || tid.x >= uniforms->width) {
		return;
	}
	
	Position position { tid };
	
	Board current { currentTick, uniforms };
	
	displayBuffer.write(colorFor(current.pixelAt(position)), tid);
}
