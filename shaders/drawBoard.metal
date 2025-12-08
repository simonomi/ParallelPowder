#include <metal_stdlib>
#include "../SharedTypes.hpp"
#include "VertexShaderResult.hpp"
#include "InputBoard.hpp"
#include "OutputBoard.hpp"

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
	const constant Pixel* previousTick [[buffer(1)]],
	device Pixel* currentTick [[buffer(2)]],
	const constant Goal* goals [[buffer(3)]]
) {
	const Position position {
		int16_t(in.uv.x * uniforms.width),
		int16_t(in.uv.y * uniforms.height)
	};
	
	const InputBoard previous { previousTick, uniforms };
	OutputBoard current { currentTick, uniforms };
	
	const Goal myGoal = goals[int(position.y) * int(uniforms.width) + int(position.x)];
	
	switch (myGoal.kind) {
		case Goal::Kind::change: {
			const Position whoSwaps = previous.whoGetsToSwapTo(
				position,
				goals,
				uniforms.frameNumber
			);
			
			if (whoSwaps == position) { // i get to change
				current.setPixelAt(position, myGoal.data.newPixel);
				return colorFor(myGoal.data.newPixel);
			} else { // someone swaps with me
				Pixel newValue = previous.uncheckedPixelAt(whoSwaps);
				current.setPixelAt(position, newValue);
				return colorFor(newValue);
			}
		}
		case Goal::Kind::swap: {
			const Position targetPosition = myGoal.data.target;
			const Goal targetsGoal = goals[targetPosition.y * uniforms.width + targetPosition.x];
			
			// if our target is swapping, do nothing
			if (targetsGoal.kind == Goal::Kind::swap) {
				Pixel newValue = previous.uncheckedPixelAt(position);
				current.setPixelAt(position, newValue);
				return colorFor(newValue);
			}
			
			const Position whoSwaps = previous.whoGetsToSwapTo(
				targetPosition,
				goals,
				uniforms.frameNumber
			);
			
			if (whoSwaps == position) { // i get to swap
				Pixel newValue = previous.uncheckedPixelAt(targetPosition);
				current.setPixelAt(position, newValue);
				return colorFor(newValue);
			} else { // someone else swaps
				Pixel newValue = previous.uncheckedPixelAt(position);
				current.setPixelAt(position, newValue);
				return colorFor(newValue);
			}
		}
	}
}
