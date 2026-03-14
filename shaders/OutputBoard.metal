#include <metal_stdlib>
#include "OutputBoard.hpp"
#include "RNG.hpp"

using namespace metal;

OutputBoard::OutputBoard(
	device Pixel* inputPixels,
	const constant Uniforms& uniforms
) : pixels(inputPixels) {
	size = ushort2(uniforms.width, uniforms.height);
}

bool OutputBoard::containsPosition(const Position position) const {
	return position.x >= 0 && position.x < size.x &&
	       position.y >= 0 && position.y < size.y;
}

Pixel OutputBoard::pixelAt(const Position position) const {
	if (containsPosition(position)) {
		return pixels[int(position.y) * int(size.x) + int(position.x)];
	} else {
		return Pixel::outOfBounds;
	}
}

void OutputBoard::setPixelAt(const Position position, const Pixel newValue) {
	pixels[int(position.y) * int(size.x) + int(position.x)] = newValue;
}
