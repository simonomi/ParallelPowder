#include <metal_stdlib>
#include "../SharedTypes.hpp"
#include "VertexShaderResult.hpp"
#include "InputBoard.hpp"

using namespace metal;

float4 colorFor(const Pixel pixel) {
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

[[early_fragment_tests]]
fragment float4 drawBoard(
	const VertexShaderResult in [[stage_in]],
	const constant Uniforms& uniforms [[buffer(0)]],
	const constant Pixel* currentTick [[buffer(1)]]
) {
	const Position position {
		int16_t(in.uv.x * uniforms.width),
		int16_t(in.uv.y * uniforms.height)
	};
	
	const InputBoard current { currentTick, uniforms };
	
	return colorFor(current.pixelAt(position));
}
