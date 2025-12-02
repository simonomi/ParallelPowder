#ifndef ConstantBoard_hpp
#define ConstantBoard_hpp

#include "../SharedTypes.hpp"
#include "Goal.hpp"

struct InputBoard {
	constant const Pixel* pixels;
	ushort2 size;
	
	InputBoard(
		constant Pixel* inputPixels,
		constant Uniforms* uniforms
	);
	
	bool containsPosition(Position position) const;
	
	Pixel pixelAt(Position position) const;
	
	Pixel uncheckedPixelAt(Position position) const;
	
	Goal goalForCellAt(Position position, uint16_t frameNumber) const;
	
	/// should only be called if `position` is the target of at least one swap
	Position whoGetsToSwapTo(
		Position position,
		constant Goal* goals,
		uint16_t frameNumber
	) const;
};

#endif /* ConstantBoard_hpp */
