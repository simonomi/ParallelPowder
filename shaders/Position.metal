#include <metal_stdlib>
#include "Position.hpp"

using namespace metal;

Position::Position(int inputX, int inputY) :
	x(inputX),
	y(inputY)
{}
	
Position::Position(uint2 inputPosition) :
	x(inputPosition.x),
	y(inputPosition.y)
{}

bool Position::operator==(Position other) {
	return x == other.x && y == other.y;
}

Position Position::offsetBy(int8_t xOffset, int8_t yOffset) {
	return Position(x + xOffset, y + yOffset);
}
