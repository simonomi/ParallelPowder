#ifndef Board_hpp
#define Board_hpp

#include "../SharedTypes.hpp"
#include "Goal.hpp"

struct OutputBoard {
	device Pixel* pixels;
	int2 size; // TODO: make u16s?
	
	OutputBoard(
		device Pixel* inputPixels,
		constant const Uniforms* uniforms
	);
	
	void setPixelAt(Position position, Pixel newValue);
};

#endif /* Board_hpp */
