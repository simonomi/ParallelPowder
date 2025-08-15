#ifndef Pixel_hpp
#define Pixel_hpp

#ifndef __METAL__
#include <stdint.h>
#endif

enum struct Pixel: uint8_t {
	border, air, sand, water
};

#endif /* Pixel_hpp */
