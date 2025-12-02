#include <metal_stdlib>
#include "InputBoard.hpp"
#include "RNG.hpp"

using namespace metal;

InputBoard::InputBoard(
	constant const Pixel* inputPixels,
	constant const Uniforms* uniforms
) : pixels(inputPixels) {
	size = int2(uniforms->width, uniforms->height);
}

bool InputBoard::containsPosition(Position position) {
	return position.x >= 0 && position.x < size.x &&
	       position.y >= 0 && position.y < size.y;
}

// TODO: is there any way to remove this bounds check?
// i think this is called in a lot of places, so itd probably be worth it?
// - some kind of special case for border pixels??
Pixel InputBoard::pixelAt(Position position) {
	if (containsPosition(position)) {
		return pixels[position.y * size.x + position.x];
	} else {
		return Pixel::outOfBounds;
	}
}

/// randomly pick one of the swaps/changes targeting a given pixel
///
/// should only be called if `position` is the target of at least one swap (or change)
Position InputBoard::whoGetsToSwapTo(
	Position position,
	constant const Goal* goals,
	unsigned int frameNumber
) {
	int numberConsidered = -1;
	Position currentWinner { -1, -1 };
	RNG rng { position, frameNumber };
	
	// TODO: make these i8s?
	for (int y : {-1, 0, 1}) {
		for (int x : {-1, 0, 1}) {
			Position candidate = position.offsetBy(x, y);
			Goal goal = goals[candidate.y * this->size.x + candidate.x];
			
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
