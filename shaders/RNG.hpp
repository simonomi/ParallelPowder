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
	
	// TODO: can this be a u16 or u8 or smthn?
	/// returns true with a 1/denominator chance
	bool oneChanceIn(unsigned int denominator);
};

#endif /* RNG_hpp */
