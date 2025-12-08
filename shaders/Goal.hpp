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
	
	enum struct Kind: uint8_t { change, swap } kind;
	
	static Goal changeTo(Pixel newPixel);
	
	static Goal swapWith(Position target);
	
private:
	Goal(
		Kind inputKind,
		Data inputData
	);
};

#endif /* Goal_hpp */
