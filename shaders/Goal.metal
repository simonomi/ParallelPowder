#ifdef __METAL__
#include <metal_stdlib>
#include "../Pixel.hpp"
#include "Goal.hpp"

using namespace metal;

Goal Goal::changeTo(
	Pixel newPixel,
	uint8_t priority
) {
	return Goal(
		Kind::change,
		Data { .newPixel = newPixel },
		priority
	);
}

Goal Goal::swapWith(
	Position target,
	uint8_t priority
) {
	return Goal(
		Kind::swap,
		Data { .target = target },
		priority
	);
}

Goal::Goal(
	Kind inputKind,
	Data inputData,
	uint8_t inputPriority
) :
	kind(inputKind),
	data(inputData),
	priority(inputPriority)
{}
#endif
