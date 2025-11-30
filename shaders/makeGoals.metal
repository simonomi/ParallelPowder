#include <metal_stdlib>
#include "../SharedTypes.hpp"
#include "Board.hpp"

using namespace metal;

kernel void makeGoals(
	uint2 tid [[thread_position_in_grid]],
	constant const Uniforms* uniforms [[buffer(0)]],
	device Pixel* previousTick [[buffer(1)]],
	device Goal* goals [[buffer(2)]]
) {
	if (tid.y >= uniforms->height || tid.x >= uniforms->width) {
		return;
	}
	
	Position position { tid };
	
	Board previous { previousTick, uniforms };
	
	Goal myGoal = previous.goalForCellAt(position, uniforms->frameNumber);
	
	goals[position.y * uniforms->width + position.x] = myGoal;
}
