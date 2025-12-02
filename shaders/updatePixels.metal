#include <metal_stdlib>
#include "../SharedTypes.hpp"
#include "InputBoard.hpp"
#include "OutputBoard.hpp"

using namespace metal;

kernel void updatePixels(
	uint2 tid [[thread_position_in_grid]],
	constant const Uniforms* uniforms [[buffer(0)]],
	constant const Pixel* previousTick [[buffer(1)]],
	device Pixel* currentTick [[buffer(2)]],
	constant const Goal* goals [[buffer(3)]]
) {
	if (tid.y >= uniforms->height || tid.x >= uniforms->width) {
		return;
	}
	
	Position position { tid };
	
	InputBoard previous { previousTick, uniforms };
	OutputBoard current { currentTick, uniforms };
	
	Goal myGoal = goals[uint(position.y) * uint(uniforms->width) + uint(position.x)];
	
	switch (myGoal.kind) {
		case Goal::Kind::change: {
			Position whoSwaps = previous.whoGetsToSwapTo(
				position,
				goals,
				uniforms->frameNumber
			);
			
			if (whoSwaps == position) { // i get to change
				current.setPixelAt(position, myGoal.data.newPixel);
			} else { // someone swaps with me
				current.setPixelAt(position, previous.uncheckedPixelAt(whoSwaps));
			}
			
			break;
		}
		case Goal::Kind::swap: {
			Goal targetsGoal = goals[myGoal.data.target.y * uniforms->width + myGoal.data.target.x];
			
			// if our target is swapping, do nothing
			if (targetsGoal.kind == Goal::Kind::swap) {
				current.setPixelAt(position, previous.uncheckedPixelAt(position));
				break;
			}
			
			Position whoSwaps = previous.whoGetsToSwapTo(
				myGoal.data.target,
				goals,
				uniforms->frameNumber
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
