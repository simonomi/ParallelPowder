#ifndef Uniforms_hpp
#define Uniforms_hpp

#ifndef __METAL__
#include <stdint.h>
#endif

struct Uniforms {
	uint16_t width;
	uint16_t height;
	uint16_t frameNumber; // u16.max is 18 minutes at 60fps, wrapping is fine
};

#endif /* Uniforms_hpp */
