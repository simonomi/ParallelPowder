#include <metal_stdlib>
#include "../SharedTypes.hpp"
#include "InputBoard.hpp"
#include "OutputBoard.hpp"

using namespace metal;

kernel void updatePixels(
	const ushort2 tid [[thread_position_in_grid]],
	const constant Uniforms& uniforms [[buffer(0)]],
	const constant Pixel* previousTick [[buffer(1)]],
	device Pixel* currentTick [[buffer(2)]],
	const constant Goal* goals [[buffer(3)]]
) {
	const Position position { tid };
	
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
			} else { // someone swaps with me
				current.setPixelAt(position, previous.uncheckedPixelAt(whoSwaps));
			}
			
			break;
		}
		case Goal::Kind::swap: {
			const Goal targetsGoal = goals[myGoal.data.target.y * uniforms.width + myGoal.data.target.x];
			
			// if our target is swapping, do nothing
			if (targetsGoal.kind == Goal::Kind::swap) {
				current.setPixelAt(position, previous.uncheckedPixelAt(position));
				break;
			}
			
			const Position whoSwaps = previous.whoGetsToSwapTo(
				myGoal.data.target,
				goals,
				uniforms.frameNumber
			);
			
			if (whoSwaps == position) { // i get to swap
				current.setPixelAt(position, previous.uncheckedPixelAt(myGoal.data.target));
			} else { // someone else swaps
				current.setPixelAt(position, previous.uncheckedPixelAt(position));
			}
			
			break;
		}
	}
}
