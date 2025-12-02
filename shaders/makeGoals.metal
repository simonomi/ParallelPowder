#include <metal_stdlib>
#include "../SharedTypes.hpp"
#include "InputBoard.hpp"

using namespace metal;

kernel void makeGoals(
	const ushort2 tid [[thread_position_in_grid]],
	const constant Uniforms& uniforms [[buffer(0)]],
	const constant Pixel* previousTick [[buffer(1)]],
	device Goal* goals [[buffer(2)]]
) {
	const Position position { tid };
	
	const InputBoard previous { previousTick, uniforms };
	
	const Goal myGoal = previous.goalForCellAt(position, uniforms.frameNumber);
	
	goals[int(position.y) * int(uniforms.width) + int(position.x)] = myGoal;
}
