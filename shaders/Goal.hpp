#ifndef Goal_hpp
#define Goal_hpp

#include "Position.hpp"
#include "Offset.hpp"

#ifndef __METAL__
#include <stdint.h>
#endif

struct Goal {
	union Data {
		Pixel newPixel;
		Offset offset;
	} data;
	
	uint8_t priority;
	
	enum struct Kind: uint8_t { change, swap } kind;
	
	static Goal changeTo(
		Pixel newPixel,
		uint8_t priority
	);
	
	static Goal swapWith(
		Offset offset,
		uint8_t priority
	);
	
	Position targetWhenAt(Position position) const;
	
private:
	Goal(
		Kind inputKind,
		Data inputData,
		uint8_t inputPriority
	);
};

#endif /* Goal_hpp */
