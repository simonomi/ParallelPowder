#ifndef SharedTypes_h
#define SharedTypes_h

#ifndef __METAL__
#include <stdint.h>
#endif

struct Uniforms {
	unsigned int width;
	unsigned int height;
	unsigned int frameNumber;
};

enum struct Pixel: uint8_t {
	border, air, sand, water
};

#endif /* SharedTypes_h */
