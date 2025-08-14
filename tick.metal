#include <metal_stdlib>
#include "SharedTypes.hpp"
#include "Position.hpp"
#include "RNG.hpp"
#include "Goal.hpp"
#include "Board.hpp"

using namespace metal;

kernel void tick(
	uint2 tid [[thread_position_in_grid]],
	constant const Uniforms* uniforms [[buffer(0)]],
	device Pixel* previousTick [[buffer(1)]],
	device Pixel* currentTick [[buffer(2)]],
	texture2d<float, access::write> displayBuffer [[texture(0)]]
) {
	if (tid.y >= uniforms->height || tid.x >= uniforms->width) {
		return;
	}
	
	Position position { tid };
	
	Board previous { previousTick, uniforms };
	Board current { currentTick, uniforms };
	
	Goal myGoal = previous.goalForCellAt(position);
	
	switch (myGoal.kind) {
		case Goal::Kind::change: {
			Position whoSwaps = previous.whoGetsToSwapTo(position, uniforms->frameNumber);
			
			if (whoSwaps == position) { // i get to change
				current.setPixelTo(position, myGoal.data.newPixel);
			} else { // someone swaps with me
				current.setPixelTo(position, previous.pixelAt(whoSwaps));
			}
			
			break;
		}
		case Goal::Kind::swap: {
			if (previous.goalForCellAt(myGoal.data.target).kind == Goal::Kind::swap) {
				current.setPixelTo(position, previous.pixelAt(position));
				break;
			}
			
			Position whoSwaps = previous.whoGetsToSwapTo(myGoal.data.target, uniforms->frameNumber);
			
			if (whoSwaps == position) { // i get to swap
				current.setPixelTo(position, previous.pixelAt(myGoal.data.target));
			} else { // someone else swaps
				current.setPixelTo(position, previous.pixelAt(position));
			}
			
			break;
		}
	}
	
	displayBuffer.write(colorFor(current.pixelAt(position)), tid);
}
