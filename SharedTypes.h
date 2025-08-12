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

typedef uint8_t Pixel;

#ifdef __METAL__
constant
#endif
Pixel BORDER = 0;

#ifdef __METAL__
constant
#endif
Pixel AIR = 1;

#ifdef __METAL__
constant
#endif
Pixel SAND = 2;

#ifdef __METAL__
constant
#endif
Pixel WATER = 3;

#endif /* SharedTypes_h */
