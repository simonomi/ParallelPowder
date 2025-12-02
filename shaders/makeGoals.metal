#include <metal_stdlib>
#include "../SharedTypes.hpp"
#include "InputBoard.hpp"

using namespace metal;

kernel void makeGoals(
	uint2 tid [[thread_position_in_grid]],
	constant const Uniforms* uniforms [[buffer(0)]],
	constant const Pixel* previousTick [[buffer(1)]],
	device Goal* goals [[buffer(2)]]
) {
	if (tid.y >= uniforms->height || tid.x >= uniforms->width) {
		return;
	}
	
	Position position { tid };
	
	InputBoard previous { previousTick, uniforms };
	
	Goal myGoal = previous.goalForCellAt(position, uniforms->frameNumber);
	
	goals[uint(position.y) * uint(uniforms->width) + uint(position.x)] = myGoal;
}
