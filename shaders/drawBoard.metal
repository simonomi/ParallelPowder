#include <metal_stdlib>
#include "../SharedTypes.hpp"
#include "VertexShaderResult.hpp"
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

fragment float4 drawBoard(
	VertexShaderResult in [[stage_in]],
	constant const Uniforms* uniforms [[buffer(0)]],
	device Pixel* currentTick [[buffer(1)]]
) {
	Position position { int(in.uv.x * uniforms->width), int(in.uv.y * uniforms->height) };
	
	Board current { currentTick, uniforms };
	
	return colorFor(current.pixelAt(position));
}
