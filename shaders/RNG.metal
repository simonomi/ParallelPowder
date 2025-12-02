#include <metal_stdlib>
#include "RNG.hpp"

using namespace metal;

// yoinked from https://stackoverflow.com/a/47499626
// Generate a random float in the range [0.0f, 1.0f] using x, y, and z (based on the xor128 algorithm)
float rand(const int x, const int y, const int z) {
	int seed = x + y * 57 + z * 241;
	seed = (seed << 13) ^ seed;
	return ((1.0 - ((seed * (seed * seed * 15731 + 789221) + 1376312589) & 2147483647) / 1073741824.0f) + 1.0f) / 2.0f;
}

RNG::RNG(
	const Position inputPosition,
	const uint16_t inputFrameNumber
) :
	position(inputPosition),
	frameNumber(inputFrameNumber),
	seed(0)
{}

/// returns true with a 1/denominator chance
bool RNG::oneChanceIn(const unsigned int denominator) {
	if (denominator == 1) { return true; }
	
	const float randomNumber = rand(
		42577 * position.x + 782941 * position.y,
		int(frameNumber),
		seed
	);
	
	seed = randomNumber * float(INT_MAX);
	
	const float zeroToDenominator = randomNumber * float(denominator);
	
	return zeroToDenominator < 1;
}
