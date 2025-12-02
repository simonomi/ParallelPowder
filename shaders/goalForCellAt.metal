#include <metal_stdlib>
#include "Board.hpp"
#include "RNG.hpp"

using namespace metal;

struct GoalAndCriteria {
	Goal (*goal)(Position position);
	bool (*criteria)(Board board, Position position, RNG rng);
	
	GoalAndCriteria(
		Goal (*inputGoal)(Position position),
		bool (*inputCriteria)(Board board, Position position, RNG rng)
	) :
		goal(inputGoal),
		criteria(inputCriteria)
	{};
};

constant unsigned int treeGrowChance = /* 1 in */ 500;
constant unsigned int treeBurnChance = /* 1 in */ 100000;

// goals must be sorted by priority high->low
//
// priority is used to decide between a pixel's valid goals.
// of the highest-priority valid goals, one is chosen at random.
//
// the default goal of a cell is to change to itself. this means
// that a cell with no goals _can_ be swapped with

constant GoalAndCriteria airGoals[] = {
	GoalAndCriteria { // grow tree randomly
		[](Position position) {
			return Goal::changeTo(Pixel::tree, 1);
		},
		[](Board board, Position position, RNG rng) {
			return rng.oneChanceIn(treeGrowChance);
		}
	}
};

constant GoalAndCriteria sandGoals[] = {
	GoalAndCriteria { // fall down
		[](Position position) {
			return Goal::swapWith(position.offsetBy(0, -1), 1);
		},
		[](Board board, Position position, RNG rng) {
			return densityOf(board.pixelAt(position.offsetBy(0, -1))) < densityOf(Pixel::sand);
		}
	},
	GoalAndCriteria { // fall diagonally left
		[](Position position) {
			return Goal::swapWith(position.offsetBy(-1, -1), 1);
		},
		[](Board board, Position position, RNG rng) {
			return densityOf(board.pixelAt(position.offsetBy(-1, -1))) < densityOf(Pixel::sand);
		}
	},
	GoalAndCriteria { // fall diagonally right
		[](Position position) {
			return Goal::swapWith(position.offsetBy(1, -1), 1);
		},
		[](Board board, Position position, RNG rng) {
			return densityOf(board.pixelAt(position.offsetBy(1, -1))) < densityOf(Pixel::sand);
		}
	}
};

constant GoalAndCriteria waterGoals[] = {
	GoalAndCriteria { // fall down
		[](Position position) {
			return Goal::swapWith(position.offsetBy(0, -1), 2);
		},
		[](Board board, Position position, RNG rng) {
			return densityOf(board.pixelAt(position.offsetBy(0, -1))) < densityOf(Pixel::water);
		}
	},
	GoalAndCriteria { // fall diagonally left
		[](Position position) {
			return Goal::swapWith(position.offsetBy(-1, -1), 2);
		},
		[](Board board, Position position, RNG rng) {
			return densityOf(board.pixelAt(position.offsetBy(-1, -1))) < densityOf(Pixel::water);
		}
	},
	GoalAndCriteria { // fall diagonally right
		[](Position position) {
			return Goal::swapWith(position.offsetBy(1, -1), 2);
		},
		[](Board board, Position position, RNG rng) {
			return densityOf(board.pixelAt(position.offsetBy(1, -1))) < densityOf(Pixel::water);
		}
	},
	GoalAndCriteria { // move horizontally left
		[](Position position) {
			return Goal::swapWith(position.offsetBy(-1, 0), 1);
		},
		[](Board board, Position position, RNG rng) {
			return densityOf(board.pixelAt(position.offsetBy(-1, 0))) < densityOf(Pixel::water);
		}
	},
	GoalAndCriteria { // move horizontally right
		[](Position position) {
			return Goal::swapWith(position.offsetBy(1, 0), 1);
		},
		[](Board board, Position position, RNG rng) {
			return densityOf(board.pixelAt(position.offsetBy(1, 0))) < densityOf(Pixel::water);
		}
	}
};

constant GoalAndCriteria treeGoals[] = {
	GoalAndCriteria { // burn if a neighbor is burning
		[](Position position) {
			return Goal::changeTo(Pixel::fire, 1);
		},
		[](Board board, Position position, RNG rng) {
			// TODO: make i8?
			for (int xOffset : {-1, 0, 1}) {
				for (int yOffset : {-1, 0, 1}) {
					if (board.pixelAt(position.offsetBy(xOffset, yOffset)) == Pixel::fire) {
						return true;
					}
				}
			}
			
			return false;
		}
	},
	GoalAndCriteria { // start burning randomly
		[](Position position) {
			return Goal::changeTo(Pixel::fire, 1);
		},
		[](Board board, Position position, RNG rng) {
			return rng.oneChanceIn(treeBurnChance);
		}
	}
};

constant GoalAndCriteria fireGoals[] = {
	GoalAndCriteria { // stop burning
		[](Position position) {
			return Goal::changeTo(Pixel::air, 1);
		},
		[](Board board, Position position, RNG rng) {
			return true;
		}
	}
};

Goal Board::goalForCellAt(Position position, unsigned int frameNumber) {
	constant GoalAndCriteria* goals;
	// TODO: make u8?
	unsigned int goalCount;
	
	switch (pixelAt(position)) {
		case Pixel::air:
			goals = airGoals;
			goalCount = sizeof(airGoals) / sizeof(*airGoals);
			break;
		case Pixel::sand:
			goals = sandGoals;
			goalCount = sizeof(sandGoals) / sizeof(*sandGoals);
			break;
		case Pixel::water:
			goals = waterGoals;
			goalCount = sizeof(waterGoals) / sizeof(*waterGoals);
			break;
		case Pixel::tree:
			goals = treeGoals;
			goalCount = sizeof(treeGoals) / sizeof(*treeGoals);
			break;
		case Pixel::fire:
			goals = fireGoals;
			goalCount = sizeof(fireGoals) / sizeof(*fireGoals);
			break;
		case Pixel::outOfBounds:
		case Pixel::block:
			goals = {};
			goalCount = 0;
			break;
	}
	
	RNG goalChoiceRNG { position, frameNumber };
	RNG criteriaRNG { position, frameNumber };
	
	Goal currentGoal = Goal::changeTo(pixelAt(position), 0);
	unsigned int numberConsidered = 0;
	
	for (unsigned int i = 0; i < goalCount; i += 1) {
		Goal candidateGoal = goals[i].goal(position);
		
		if (candidateGoal.priority < currentGoal.priority) {
			break; // because goals are sorted by priority
				   // the one we have is of the highest priority left
		}
		
		// function groups
		// [[function_groups("")]]
		if (!goals[i].criteria(*this, position, criteriaRNG)) {
			continue; // this goal's criteria is not met
		}
		
		numberConsidered += 1;
		
		if (goalChoiceRNG.oneChanceIn(numberConsidered)) {
			// each candidate has a (1/index) chance of winning,
			// which is equivalent to randomly selecting one
			currentGoal = candidateGoal;
		}
	}
	
	return currentGoal;
}
