#ifndef Goal_hpp
#define Goal_hpp

#include "Position.hpp"

#ifndef __METAL__
#include <stdint.h>
#endif

struct Goal {
	union Data {
		Pixel newPixel;
		Position target; // could replace with an enum
						 // _ideally_, we could even bitpack the kind/data together 🤔
						 // if we're ALU-bound now though, is it still worth making Goals smaller?
	} data;
	
	uint8_t priority;
	
	enum struct Kind: uint8_t { change, swap } kind;
	
	static Goal changeTo(
		Pixel newPixel,
		uint8_t priority
	);
	
	static Goal swapWith(
		Position target,
		uint8_t priority
	);
	
private:
	Goal(
		Kind inputKind,
		Data inputData,
		uint8_t inputPriority
	);
};

#endif /* Goal_hpp */
