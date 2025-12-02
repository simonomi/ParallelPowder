#include <metal_stdlib>
#include "Position.hpp"

using namespace metal;

Position::Position(const int16_t inputX, const int16_t inputY) :
	x(inputX),
	y(inputY)
{}
	
Position::Position(const uint2 inputPosition) :
	x(inputPosition.x),
	y(inputPosition.y)
{}

bool Position::operator==(const Position other) const {
	return x == other.x && y == other.y;
}

Position Position::offsetBy(const int8_t xOffset, const int8_t yOffset) const {
	return Position(x + xOffset, y + yOffset);
}
