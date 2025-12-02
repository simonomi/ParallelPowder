#ifndef Goal_hpp
#define Goal_hpp

#include "Position.hpp"

struct Goal {
	// TODO: use u8 instead?
	int priority;
	
	union Data {
		Pixel newPixel;
		Position target;
	} data;
	
	enum struct Kind { change, swap } kind;
	
	static Goal changeTo(
		Pixel newPixel,
		int priority
	);
	
	static Goal swapWith(
		Position target,
		int priority
	);
	
private:
	Goal(
		Kind inputKind,
		Data inputData,
		int inputPriority
	);
};

#endif /* Goal_hpp */
