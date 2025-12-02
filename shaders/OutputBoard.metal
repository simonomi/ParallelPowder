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

void OutputBoard::setPixelAt(const Position position, const Pixel newValue) {
	pixels[int(position.y) * int(size.x) + int(position.x)] = newValue;
}
