#ifndef Uniforms_hpp
#define Uniforms_hpp

struct Uniforms {
	// TODO: use u16s instead?
	unsigned int width;
	unsigned int height;
	unsigned int frameNumber; // u16.max is 18 minutes at 60fps, wrapping is fine
};

#endif /* Uniforms_hpp */
