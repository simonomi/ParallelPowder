#include <metal_stdlib>
#include "../SharedTypes.hpp"
#include "VertexShaderResult.hpp"
#include "InputBoard.hpp"

using namespace metal;

float4 colorFor(Pixel pixel) {
	switch (pixel) {
		case Pixel::outOfBounds:
			return float4(1, 0, 1, 1);
		case Pixel::air:
			return float4(0, 0, 0, 1);
		case Pixel::sand:
			return float4(1, 0.9, 0.8, 1);
		case Pixel::water:
			return float4(0, 0.4, 0.6, 1);
		case Pixel::block:
			return float4(0.5, 0.5, 0.5, 1);
		case Pixel::tree:
			return float4(0.33, 0.72, 0.30, 1);
		case Pixel::fire:
			return float4(1, 1, 0, 1);
	}
}

fragment float4 drawBoard(
	VertexShaderResult in [[stage_in]],
	constant const Uniforms* uniforms [[buffer(0)]],
	constant const Pixel* currentTick [[buffer(1)]]
) {
	Position position { int(in.uv.x * uniforms->width), int(in.uv.y * uniforms->height) };
	
	InputBoard current { currentTick, uniforms };
	
	return colorFor(current.pixelAt(position));
}
