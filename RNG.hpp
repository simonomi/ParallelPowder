#ifndef RNG_hpp
#define RNG_hpp

struct RNG {
	Position position;
	unsigned int frameNumber;
	int repetition;
	
	RNG(
		Position inputPosition,
		unsigned int inputFrameNumber
	);
	
	int generateUpTo(int maximum);
};

#endif /* RNG_hpp */
