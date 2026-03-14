#ifndef Board_hpp
#define Board_hpp

#include "../SharedTypes.hpp"
#include "Goal.hpp"

struct OutputBoard {
	device Pixel* pixels;
	ushort2 size;
	
	OutputBoard(
		device Pixel* inputPixels,
		const constant Uniforms& uniforms
	);
	
	bool containsPosition(Position position) const;
	
	Pixel pixelAt(Position position) const;
	
	void setPixelAt(Position position, Pixel newValue);
};

#endif /* Board_hpp */
