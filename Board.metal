#include <metal_stdlib>
#include "Board.hpp"
#include "RNG.hpp"

using namespace metal;

Board::Board(
	device Pixel* inputPixels,
	constant const Uniforms* uniforms
) : pixels(inputPixels) {
	size = int2(uniforms->width, uniforms->height);
}

bool Board::containsPosition(Position position) {
	return position.x >= 0 && position.x < size.x &&
	position.y >= 0 && position.y < size.y;
}

Pixel Board::pixelAt(Position position) {
	return pixels[position.y * size.x + position.x];
}

void Board::setPixelTo(Position position, Pixel newValue) {
	pixels[position.y * size.x + position.x] = newValue;
}

Goal Board::goalForCellAt(Position position) {
	if (pixelAt(position) == Pixel::sand && pixelAt(position.offsetBy(0, -1)) == Pixel::air) {
		return Goal::swapWith(position.offsetBy(0, -1), 2);
		// TODO: prefers falling left over right, should be random
	} else if (pixelAt(position) == Pixel::sand && pixelAt(position.offsetBy(-1, -1)) == Pixel::air) {
		return Goal::swapWith(position.offsetBy(-1, -1), 1);
	} else if (pixelAt(position) == Pixel::sand && pixelAt(position.offsetBy(1, -1)) == Pixel::air) {
		return Goal::swapWith(position.offsetBy(1, -1), 1);
	} else {
		return Goal::changeTo(pixelAt(position), 0);
	}
}

/// should only be called if `position` is the target of at least one swap
Position Board::whoGetsToSwapTo(Position position, unsigned int frameNumber) {
	int highestPriority = -1;
	int numberConsidered = -1;
	Position currentWinner { -1, -1 };
	RNG rng { frameNumber, position };
	
	for (int y : {-1, 0, 1}) {
		for (int x : {-1, 0, 1}) {
			Position candidate = position.offsetBy(x, y);
			Goal goal = goalForCellAt(candidate);
			
			if (
				(goal.kind == Goal::Kind::swap && goal.data.target == position) ||
				(goal.kind == Goal::Kind::change && candidate == position)
				) {
					if (goal.priority > highestPriority) {
						highestPriority = goal.priority;
						numberConsidered = 1;
						currentWinner = candidate;
					} else if (goal.priority == highestPriority) {
						// each candidate has a (1/n) chance of winning,
						// which is equivalent to randomly selecting one
						if (rng.generateUpTo(numberConsidered) == 0) {
							currentWinner = candidate;
						}
						
						numberConsidered += 1;
					}
				}
		}
	}
	
	return currentWinner;
}
