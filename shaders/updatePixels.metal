#include <metal_stdlib>
#include "../SharedTypes.hpp"
#include "Board.hpp"

using namespace metal;

kernel void updatePixels(
	uint2 tid [[thread_position_in_grid]],
	constant const Uniforms* uniforms [[buffer(0)]],
	device Pixel* previousTick [[buffer(1)]],
	device Pixel* currentTick [[buffer(2)]],
	constant const Goal* goals [[buffer(3)]]
) {
	if (tid.y >= uniforms->height || tid.x >= uniforms->width) {
		return;
	}
	
	Position position { tid };
	
	Board previous { previousTick, uniforms };
	Board current { currentTick, uniforms };
	
	Goal myGoal = goals[position.y * uniforms->width + position.x];
	
	switch (myGoal.kind) {
		case Goal::Kind::change: {
			Position whoSwaps = previous.whoGetsToSwapTo(
				position,
				goals,
				uniforms->frameNumber
			);
			
			if (whoSwaps == position) { // i get to change
				current.setPixelTo(position, myGoal.data.newPixel);
			} else { // someone swaps with me
				current.setPixelTo(position, previous.pixelAt(whoSwaps));
			}
			
			break;
		}
		case Goal::Kind::swap: {
			Goal targetsGoal = goals[myGoal.data.target.y * uniforms->width + myGoal.data.target.x];
			
			if (targetsGoal.kind == Goal::Kind::swap) {
				current.setPixelTo(position, previous.pixelAt(position));
				break;
			}
			
			Position whoSwaps = previous.whoGetsToSwapTo(
				myGoal.data.target,
				goals,
				uniforms->frameNumber
			);
			
			if (whoSwaps == position) { // i get to swap
				current.setPixelTo(position, previous.pixelAt(myGoal.data.target));
			} else { // someone else swaps
				current.setPixelTo(position, previous.pixelAt(position));
			}
			
			break;
		}
	}
}
