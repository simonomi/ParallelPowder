#include <metal_stdlib>
#include "InputBoard.hpp"
#include "RNG.hpp"

using namespace metal;

InputBoard::InputBoard(
	const constant Pixel* inputPixels,
	const constant Uniforms& uniforms
) : pixels(inputPixels) {
	size = ushort2(uniforms.width, uniforms.height);
}

bool InputBoard::containsPosition(const Position position) const {
	return position.x >= 0 && position.x < size.x &&
	       position.y >= 0 && position.y < size.y;
}

Pixel InputBoard::pixelAt(const Position position) const {
	if (containsPosition(position)) {
		return pixels[int(position.y) * int(size.x) + int(position.x)];
	} else {
		return Pixel::outOfBounds;
	}
}

Pixel InputBoard::uncheckedPixelAt(const Position position) const {
	return pixels[int(position.y) * int(size.x) + int(position.x)];
}

/// randomly pick one of the swaps/changes targeting a given pixel
///
/// should only be called if `position` is the target of at least one swap (or change)
Position InputBoard::whoGetsToSwapTo(
	const Position position,
	const constant Goal* goals,
	const uint16_t frameNumber
) const {
	int16_t numberConsidered = -1;
	Position currentWinner { -1, -1 };
	RNG rng { position, frameNumber };
	
	for (int8_t y : {-1, 0, 1}) {
		for (int8_t x : {-1, 0, 1}) {
			const Position candidate = position.offsetBy(x, y);
			
			if (!containsPosition(candidate)) {
				continue;
			}
			
			const Goal goal = goals[int(candidate.y) * int(this->size.x) + int(candidate.x)];
			
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
