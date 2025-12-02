#ifndef ConstantBoard_hpp
#define ConstantBoard_hpp

#include "../SharedTypes.hpp"
#include "Goal.hpp"

struct InputBoard {
	constant const Pixel* pixels;
	int2 size; // TODO: make u16s?
	
	InputBoard(
		constant const Pixel* inputPixels,
		constant const Uniforms* uniforms
	);
	
	bool containsPosition(Position position);
	
	Pixel pixelAt(Position position);
	
	Goal goalForCellAt(Position position, unsigned int frameNumber);
	
	/// should only be called if `position` is the target of at least one swap
	Position whoGetsToSwapTo(
		Position position,
		constant const Goal* goals,
		unsigned int frameNumber
	);
};

#endif /* ConstantBoard_hpp */
