#ifdef __METAL__
#include <metal_stdlib>
#include "../Pixel.hpp"
#include "Goal.hpp"

using namespace metal;

Goal Goal::changeTo(const Pixel newPixel) {
	return Goal(
		Kind::change,
		Data { .newPixel = newPixel }
	);
}

Goal Goal::swapWith(const Position target) {
	return Goal {
		Kind::swap,
		Data { .target = target }
	};
}

Goal::Goal(
	const Kind inputKind,
	const Data inputData
) :
	kind(inputKind),
	data(inputData)
{}
#endif
