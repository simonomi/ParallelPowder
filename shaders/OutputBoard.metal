#include <metal_stdlib>
#include "OutputBoard.hpp"
#include "RNG.hpp"

using namespace metal;

OutputBoard::OutputBoard(
	device Pixel* inputPixels,
	constant const Uniforms* uniforms
) : pixels(inputPixels) {
	size = int2(uniforms->width, uniforms->height);
}

void OutputBoard::setPixelAt(Position position, Pixel newValue) {
	pixels[position.y * size.x + position.x] = newValue;
}
