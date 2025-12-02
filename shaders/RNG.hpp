#ifndef RNG_hpp
#define RNG_hpp

#include "Position.hpp"

#ifndef __METAL__
#include <stdint.h>
#endif

struct RNG {
	Position position;
	uint16_t frameNumber;
	int seed;
	
	RNG(
		Position inputPosition,
		uint16_t inputFrameNumber
	);
	
	/// returns true with a 1/denominator chance
	bool oneChanceIn(unsigned int denominator);
};

#endif /* RNG_hpp */
