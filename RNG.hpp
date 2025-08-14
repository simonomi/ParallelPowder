#ifndef RNG_hpp
#define RNG_hpp

struct RNG {
	unsigned int frameNumber;
	Position position;
	int repetition;
	
	RNG(
		unsigned int inputFrameNumber,
		Position inputPosition
	);
	
	int generateUpTo(int maximum);
};

#endif /* RNG_hpp */
