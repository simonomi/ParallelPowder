#ifndef ConstantBoard_hpp
#define ConstantBoard_hpp

#include "../SharedTypes.hpp"
#include "Goal.hpp"

struct InputBoard {
	constant const Pixel* pixels;
	ushort2 size;
	
	InputBoard(
		constant const Pixel* inputPixels,
		constant const Uniforms* uniforms
	);
	
	bool containsPosition(Position position);
	
	Pixel pixelAt(Position position);
	
	Goal goalForCellAt(Position position, uint16_t frameNumber);
	
	/// should only be called if `position` is the target of at least one swap
	Position whoGetsToSwapTo(
		Position position,
		constant const Goal* goals,
		uint16_t frameNumber
	);
};

#endif /* ConstantBoard_hpp */
