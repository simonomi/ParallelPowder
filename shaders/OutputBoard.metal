#include <metal_stdlib>
#include "OutputBoard.hpp"
#include "RNG.hpp"

using namespace metal;

OutputBoard::OutputBoard(
	device Pixel* inputPixels,
	constant const Uniforms* uniforms
) : pixels(inputPixels) {
	size = ushort2(uniforms->width, uniforms->height);
}

void OutputBoard::setPixelAt(Position position, Pixel newValue) {
	pixels[uint(position.y) * uint(size.x) + uint(position.x)] = newValue;
}
