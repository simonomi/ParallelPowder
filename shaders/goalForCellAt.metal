#include <metal_stdlib>
#include "Board.hpp"
#include "RNG.hpp"

using namespace metal;

struct GoalAndCriteria {
	Goal (*goal)(Position position);
	bool (*criteria)(Board board, Position position);
	
	GoalAndCriteria(
		Goal (*inputGoal)(Position position),
		bool (*inputCriteria)(Board board, Position position)
	) :
		goal(inputGoal),
		criteria(inputCriteria)
	{};
};

// goals must be sorted by priority high->low
constant GoalAndCriteria sandGoals[] = {
	GoalAndCriteria {
		[](Position position) {
			return Goal::swapWith(position.offsetBy(0, -1), 1);
		},
		[](Board board, Position position) {
			return board.pixelAt(position.offsetBy(0, -1)) == Pixel::air;
		}
	},
	GoalAndCriteria {
		[](Position position) {
			return Goal::swapWith(position.offsetBy(-1, -1), 1);
		},
		[](Board board, Position position) {
			return board.pixelAt(position.offsetBy(-1, -1)) == Pixel::air;
		}
	},
	GoalAndCriteria {
		[](Position position) {
			return Goal::swapWith(position.offsetBy(1, -1), 1);
		},
		[](Board board, Position position) {
			return board.pixelAt(position.offsetBy(1, -1)) == Pixel::air;
		}
	}
};

Goal Board::goalForCellAt(Position position, unsigned int frameNumber) {
	constant GoalAndCriteria* whatever;
	int whateverCount;
	
	switch (pixelAt(position)) {
		case Pixel::sand:
			whatever = sandGoals;
			whateverCount = sizeof(sandGoals) / sizeof(*sandGoals);
			break;
		default:
			whatever = {};
			whateverCount = 0;
			break;
	}
	
	RNG rng { position, frameNumber };
	
	Goal currentGoal = Goal::changeTo(pixelAt(position), 0);
	int numberConsidered = 0;
	
	for (int i = 0; i < whateverCount; i += 1) {
		if (!whatever[i].criteria(*this, position)) {
			continue; // this goal's criteria is not met
		}
		
		Goal candidateGoal = whatever[i].goal(position);
		
		if (candidateGoal.priority < currentGoal.priority) {
			break; // because goals are sorted by priority
			       // the one we have is of the highest priority left
		}
		
		numberConsidered += 1;
		
		if (candidateGoal.priority > currentGoal.priority) {
			currentGoal = candidateGoal;
			numberConsidered = 1;
		} else if (rng.generateUpTo(numberConsidered) == 0) {
			// each candidate has a (1/index) chance of winning,
			// which is equivalent to randomly selecting one
			currentGoal = candidateGoal;
		}
	}
	
	return currentGoal;
}
