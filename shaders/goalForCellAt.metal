#include <metal_stdlib>
#include "InputBoard.hpp"
#include "RNG.hpp"

using namespace metal;

struct Rule {
	Goal (*goal)(Position position);
	bool (*criteria)(InputBoard board, Position position, RNG rng);
	
	Rule(
		Goal (*inputGoal)(Position position),
		bool (*inputCriteria)(InputBoard board, Position position, RNG rng)
	) :
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

// TODO: ising model https://en.wikipedia.org/wiki/Ising_model

const constant Rule airRules[] = {
	Rule { // grow tree randomly
		[](Position position) {
			return Goal::changeTo(Pixel::tree, 1);
		},
		[](InputBoard board, Position position, RNG rng) {
			return rng.oneChanceIn(treeGrowChance);
		}
	}
};

const constant Rule sandRules[] = {
	Rule { // fall down
		[](Position position) {
			return Goal::swapWith(position.offsetBy(0, -1), 1);
		},
		[](InputBoard board, Position position, RNG rng) {
			return densityOf(board.pixelAt(position.offsetBy(0, -1))) < densityOf(Pixel::sand);
		}
	},
	Rule { // fall diagonally left
		[](Position position) {
			return Goal::swapWith(position.offsetBy(-1, -1), 1);
		},
		[](InputBoard board, Position position, RNG rng) {
			return densityOf(board.pixelAt(position.offsetBy(-1, -1))) < densityOf(Pixel::sand);
		}
	},
	Rule { // fall diagonally right
		[](Position position) {
			return Goal::swapWith(position.offsetBy(1, -1), 1);
		},
		[](InputBoard board, Position position, RNG rng) {
			return densityOf(board.pixelAt(position.offsetBy(1, -1))) < densityOf(Pixel::sand);
		}
	}
};

const constant Rule waterRules[] = {
	Rule { // fall down
		[](Position position) {
			return Goal::swapWith(position.offsetBy(0, -1), 2);
		},
		[](InputBoard board, Position position, RNG rng) {
			return densityOf(board.pixelAt(position.offsetBy(0, -1))) < densityOf(Pixel::water);
		}
	},
	Rule { // fall diagonally left
		[](Position position) {
			return Goal::swapWith(position.offsetBy(-1, -1), 2);
		},
		[](InputBoard board, Position position, RNG rng) {
			return densityOf(board.pixelAt(position.offsetBy(-1, -1))) < densityOf(Pixel::water);
		}
	},
	Rule { // fall diagonally right
		[](Position position) {
			return Goal::swapWith(position.offsetBy(1, -1), 2);
		},
		[](InputBoard board, Position position, RNG rng) {
			return densityOf(board.pixelAt(position.offsetBy(1, -1))) < densityOf(Pixel::water);
		}
	},
	Rule { // move horizontally left
		[](Position position) {
			return Goal::swapWith(position.offsetBy(-1, 0), 1);
		},
		[](InputBoard board, Position position, RNG rng) {
			return densityOf(board.pixelAt(position.offsetBy(-1, 0))) < densityOf(Pixel::water);
		}
	},
	Rule { // move horizontally right
		[](Position position) {
			return Goal::swapWith(position.offsetBy(1, 0), 1);
		},
		[](InputBoard board, Position position, RNG rng) {
			return densityOf(board.pixelAt(position.offsetBy(1, 0))) < densityOf(Pixel::water);
		}
	}
};

const constant Rule treeRules[] = {
	Rule { // burn if a neighbor is burning
		[](Position position) {
			return Goal::changeTo(Pixel::fire, 1);
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
	Rule { // start burning randomly
		[](Position position) {
			return Goal::changeTo(Pixel::fire, 1);
		},
		[](InputBoard board, Position position, RNG rng) {
			return rng.oneChanceIn(treeBurnChance);
		}
	}
};

const constant Rule fireRules[] = {
	Rule { // stop burning
		[](Position position) {
			return Goal::changeTo(Pixel::air, 1);
		},
		[](InputBoard board, Position position, RNG rng) {
			return true;
		}
	}
};

Goal InputBoard::goalForCellAt(Position position, uint16_t frameNumber) const {
	const constant Rule* rules;
	uint16_t ruleCount;
	
	switch (uncheckedPixelAt(position)) {
		case Pixel::air:
			rules = airRules;
			ruleCount = sizeof(airRules) / sizeof(*airRules);
			break;
		case Pixel::sand:
			rules = sandRules;
			ruleCount = sizeof(sandRules) / sizeof(*sandRules);
			break;
		case Pixel::water:
			rules = waterRules;
			ruleCount = sizeof(waterRules) / sizeof(*waterRules);
			break;
		case Pixel::tree:
			rules = treeRules;
			ruleCount = sizeof(treeRules) / sizeof(*treeRules);
			break;
		case Pixel::fire:
			rules = fireRules;
			ruleCount = sizeof(fireRules) / sizeof(*fireRules);
			break;
		case Pixel::outOfBounds:
		case Pixel::block:
			rules = {};
			ruleCount = 0;
			break;
	}
	
	RNG ruleChoiceRNG { position, frameNumber };
	RNG criteriaRNG { position, frameNumber };
	
	Goal currentGoal = Goal::changeTo(uncheckedPixelAt(position), 0);
	int16_t numberConsidered = 0;
	
	for (int16_t i = 0; i < ruleCount; i += 1) {
		const Goal candidateGoal = rules[i].goal(position);
		
		if (candidateGoal.priority < currentGoal.priority) {
			break; // because rules are sorted by priority
				   // the one we have is of the highest priority left
		}
		
		if (!rules[i].criteria(*this, position, criteriaRNG)) {
			continue; // this goal's criteria is not met
		}
		
		numberConsidered += 1;
		
		if (ruleChoiceRNG.oneChanceIn(numberConsidered)) {
			// each candidate has a (1/index) chance of winning,
			// which is equivalent to randomly selecting one
			currentGoal = candidateGoal;
		}
	}
	
	return currentGoal;
}
