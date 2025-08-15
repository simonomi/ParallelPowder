#ifndef RNG_hpp
#define RNG_hpp

#include "Position.hpp"

struct RNG {
	Position position;
	unsigned int frameNumber;
	int seed;
	
	RNG(
		Position inputPosition,
		unsigned int inputFrameNumber
	);
	
	/// returns true with a 1/denominator chance
	bool oneChanceIn(int denominator);
};

#endif /* RNG_hpp */
