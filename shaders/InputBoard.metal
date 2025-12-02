#include <metal_stdlib>
#include "InputBoard.hpp"
#include "RNG.hpp"

using namespace metal;

InputBoard::InputBoard(
	constant const Pixel* inputPixels,
	constant const Uniforms* uniforms
) : pixels(inputPixels) {
	size = ushort2(uniforms->width, uniforms->height);
}

bool InputBoard::containsPosition(Position position) {
	return position.x >= 0 && position.x < size.x &&
	       position.y >= 0 && position.y < size.y;
}

Pixel InputBoard::pixelAt(Position position) {
	if (containsPosition(position)) {
		return pixels[uint(position.y) * uint(size.x) + uint(position.x)];
	} else {
		return Pixel::outOfBounds;
	}
}

Pixel InputBoard::uncheckedPixelAt(Position position) {
	return pixels[uint(position.y) * uint(size.x) + uint(position.x)];
}

/// randomly pick one of the swaps/changes targeting a given pixel
///
/// should only be called if `position` is the target of at least one swap (or change)
Position InputBoard::whoGetsToSwapTo(
	Position position,
	constant const Goal* goals,
	uint16_t frameNumber
) {
	uint8_t numberConsidered = -1;
	Position currentWinner { -1, -1 };
	RNG rng { position, frameNumber };
	
	for (int8_t y : {-1, 0, 1}) {
		for (int8_t x : {-1, 0, 1}) {
			Position candidate = position.offsetBy(x, y);
			
			if (!containsPosition(candidate)) {
				continue;
			}
			
			Goal goal = goals[uint(candidate.y) * uint(this->size.x) + uint(candidate.x)];
			
			if (
				(goal.kind == Goal::Kind::swap && goal.data.target == position) ||
				(goal.kind == Goal::Kind::change && candidate == position)
			) {
				numberConsidered += 1;
				
				// each candidate has a (1/index) chance of winning,
				// which is equivalent to randomly selecting one
				if (rng.oneChanceIn(numberConsidered)) {
					currentWinner = candidate;
				}
			}
		}
	}
	
	return currentWinner;
}
