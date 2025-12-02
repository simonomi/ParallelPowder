#include <metal_stdlib>
#include "../SharedTypes.hpp"
#include "InputBoard.hpp"

using namespace metal;

kernel void makeGoals(
	const uint2 tid [[thread_position_in_grid]],
	constant const Uniforms* uniforms [[buffer(0)]],
	constant const Pixel* previousTick [[buffer(1)]],
	device Goal* goals [[buffer(2)]]
) {
	if (tid.y >= uniforms->height || tid.x >= uniforms->width) {
		return;
	}
	
	const Position position { tid };
	
	const InputBoard previous { previousTick, uniforms };
	
	const Goal myGoal = previous.goalForCellAt(position, uniforms->frameNumber);
	
	goals[uint(position.y) * uint(uniforms->width) + uint(position.x)] = myGoal;
}
