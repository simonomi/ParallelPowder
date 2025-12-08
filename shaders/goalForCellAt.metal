#include <metal_stdlib>
#include "InputBoard.hpp"
#include "RNG.hpp"

using namespace metal;

struct GoalAndCriteria {
	uint8_t priority;
	Goal (*goal)(Position position);
	bool (*criteria)(InputBoard board, Position position, RNG rng);
	
	GoalAndCriteria(
		uint8_t inputPriority,
		Goal (*inputGoal)(Position position),
		bool (*inputCriteria)(InputBoard board, Position position, RNG rng)
	) :
		priority(inputPriority),
		goal(inputGoal),
		criteria(inputCriteria)
	{};
};

const constant unsigned int treeGrowChance = /* 1 in */ 500;
const constant unsigned int treeBurnChance = /* 1 in */ 100000;

// goals must be sorted by priority high->low
//
// priority is used to decide between a pixel's valid goals.
// of the highest-priority valid goals, one is chosen at random.
//
// the default goal of a cell is to change to itself. this means
// that a cell with no goals _can_ be swapped with

const constant GoalAndCriteria airGoals[] = {
	GoalAndCriteria { // grow tree randomly
		1,
		[](Position position) {
			return Goal::changeTo(Pixel::tree);
		},
		[](InputBoard board, Position position, RNG rng) {
			return rng.oneChanceIn(treeGrowChance);
		}
	}
};

const constant GoalAndCriteria sandGoals[] = {
	GoalAndCriteria { // fall down
		1,
		[](Position position) {
			return Goal::swapWith(position.offsetBy(0, -1));
		},
		[](InputBoard board, Position position, RNG rng) {
			return densityOf(board.pixelAt(position.offsetBy(0, -1))) < densityOf(Pixel::sand);
		}
	},
	GoalAndCriteria { // fall diagonally left
		1,
		[](Position position) {
			return Goal::swapWith(position.offsetBy(-1, -1));
		},
		[](InputBoard board, Position position, RNG rng) {
			return densityOf(board.pixelAt(position.offsetBy(-1, -1))) < densityOf(Pixel::sand);
		}
	},
	GoalAndCriteria { // fall diagonally right
		1,
		[](Position position) {
			return Goal::swapWith(position.offsetBy(1, -1));
		},
		[](InputBoard board, Position position, RNG rng) {
			return densityOf(board.pixelAt(position.offsetBy(1, -1))) < densityOf(Pixel::sand);
		}
	}
};

const constant GoalAndCriteria waterGoals[] = {
	GoalAndCriteria { // fall down
		2,
		[](Position position) {
			return Goal::swapWith(position.offsetBy(0, -1));
		},
		[](InputBoard board, Position position, RNG rng) {
			return densityOf(board.pixelAt(position.offsetBy(0, -1))) < densityOf(Pixel::water);
		}
	},
	GoalAndCriteria { // fall diagonally left
		2,
		[](Position position) {
			return Goal::swapWith(position.offsetBy(-1, -1));
		},
		[](InputBoard board, Position position, RNG rng) {
			return densityOf(board.pixelAt(position.offsetBy(-1, -1))) < densityOf(Pixel::water);
		}
	},
	GoalAndCriteria { // fall diagonally right
		2,
		[](Position position) {
			return Goal::swapWith(position.offsetBy(1, -1));
		},
		[](InputBoard board, Position position, RNG rng) {
			return densityOf(board.pixelAt(position.offsetBy(1, -1))) < densityOf(Pixel::water);
		}
	},
	GoalAndCriteria { // move horizontally left
		1,
		[](Position position) {
			return Goal::swapWith(position.offsetBy(-1, 0));
		},
		[](InputBoard board, Position position, RNG rng) {
			return densityOf(board.pixelAt(position.offsetBy(-1, 0))) < densityOf(Pixel::water);
		}
	},
	GoalAndCriteria { // move horizontally right
		1,
		[](Position position) {
			return Goal::swapWith(position.offsetBy(1, 0));
		},
		[](InputBoard board, Position position, RNG rng) {
			return densityOf(board.pixelAt(position.offsetBy(1, 0))) < densityOf(Pixel::water);
		}
	}
};

const constant GoalAndCriteria treeGoals[] = {
	GoalAndCriteria { // burn if a neighbor is burning
		1,
		[](Position position) {
			return Goal::changeTo(Pixel::fire);
		},
		[](InputBoard board, Position position, RNG rng) {
			for (int8_t xOffset : {-1, 0, 1}) {
				for (int8_t yOffset : {-1, 0, 1}) {
					if (board.pixelAt(position.offsetBy(xOffset, yOffset)) == Pixel::fire) {
						return true;
					}
				}
			}
			
			return false;
		}
	},
	GoalAndCriteria { // start burning randomly
		1,
		[](Position position) {
			return Goal::changeTo(Pixel::fire);
		},
		[](InputBoard board, Position position, RNG rng) {
			return rng.oneChanceIn(treeBurnChance);
		}
	}
};

const constant GoalAndCriteria fireGoals[] = {
	GoalAndCriteria { // stop burning
		1,
		[](Position position) {
			return Goal::changeTo(Pixel::air);
		},
		[](InputBoard board, Position position, RNG rng) {
			return true;
		}
	}
};

Goal InputBoard::goalForCellAt(Position position, uint16_t frameNumber) const {
	const constant GoalAndCriteria* goals;
	uint16_t goalCount;
	
	switch (uncheckedPixelAt(position)) {
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
	
	Goal currentGoal = Goal::changeTo(uncheckedPixelAt(position));
	uint8_t currentPriority = 0;
	int16_t numberConsidered = 0;
	
	for (int16_t i = 0; i < goalCount; i += 1) {
		const Goal candidateGoal = goals[i].goal(position);
		
		if (goals[i].priority < currentPriority) {
			break; // because goals are sorted by priority
				   // the one we have is of the highest priority left
		}
		
		if (!goals[i].criteria(*this, position, criteriaRNG)) {
			continue; // this goal's criteria is not met
		}
		
		numberConsidered += 1;
		
		if (goalChoiceRNG.oneChanceIn(numberConsidered)) {
			// each candidate has a (1/index) chance of winning,
			// which is equivalent to randomly selecting one
			currentGoal = candidateGoal;
			currentPriority = goals[i].priority;
		}
	}
	
	return currentGoal;
}
