#ifdef __METAL__
#include <metal_stdlib>
#include "../Pixel.hpp"
#include "Goal.hpp"

using namespace metal;

Goal Goal::changeTo(
	const Pixel newPixel,
	const uint8_t priority
) {
	return Goal(
		Kind::change,
		Data { .newPixel = newPixel },
		priority
	);
}

Goal Goal::swapWith(
	const Offset offset,
	const uint8_t priority
) {
	return Goal(
		Kind::swap,
		Data { .offset = offset },
		priority
	);
}

Position Goal::targetWhenAt(Position position) const {
	switch (kind) {
		case Kind::change:
			return position;
		case Kind::swap:
			return Position(
				position.x + xOffsetFor(this->data.offset),
				position.y + yOffsetFor(this->data.offset)
			);
	}
}

Goal::Goal(
	const Kind inputKind,
	const Data inputData,
	const uint8_t inputPriority
) :
	kind(inputKind),
	data(inputData),
	priority(inputPriority)
{}
#endif
