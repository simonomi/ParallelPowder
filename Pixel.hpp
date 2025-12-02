#ifndef Pixel_hpp
#define Pixel_hpp

#ifndef __METAL__
#include <stdint.h>
#endif

enum struct Pixel: uint8_t {
	outOfBounds, air, sand, water, block, tree, fire
};

uint8_t densityOf(Pixel pixel);

#endif /* Pixel_hpp */
