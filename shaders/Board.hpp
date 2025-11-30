#ifndef Board_hpp
#define Board_hpp

#include "../SharedTypes.hpp"
#include "Goal.hpp"

struct Board {
	device Pixel* pixels;
	int2 size;
	
	Board(
		device Pixel* inputPixels,
		constant const Uniforms* uniforms
	);
	
	bool containsPosition(Position position);
	
	Pixel pixelAt(Position position);
	
	void setPixelTo(Position position, Pixel newValue);
	
	Goal goalForCellAt(Position position, unsigned int frameNumber);
	
	/// should only be called if `position` is the target of at least one swap
	Position whoGetsToSwapTo(
		Position position,
		constant const Goal* goals,
		unsigned int frameNumber
	);
};

#endif /* Board_hpp */
