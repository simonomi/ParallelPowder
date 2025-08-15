#include <metal_stdlib>
#include "../Pixel.hpp"
#include "Goal.hpp"

using namespace metal;

Goal Goal::changeTo(
	Pixel newPixel,
	int priority
) {
	return Goal(
		Kind::change,
		Data { .newPixel = newPixel },
		priority
	);
}

Goal Goal::swapWith(
	Position target,
	int priority
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
	int inputPriority
) :
	kind(inputKind),
	data(inputData),
	priority(inputPriority)
{}
