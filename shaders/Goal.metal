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
	const Position target,
	const uint8_t priority
) {
	return Goal(
		Kind::swap,
		Data { .target = target },
		priority
	);
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
