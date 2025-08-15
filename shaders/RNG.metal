#include <metal_stdlib>
#include "RNG.hpp"

using namespace metal;

// yoinked from https://stackoverflow.com/a/47499626
// Generate a random float in the range [0.0f, 1.0f] using x, y, and z (based on the xor128 algorithm)
float rand(int x, int y, int z) {
	int seed = x + y * 57 + z * 241;
	seed = (seed << 13) ^ seed;
	return ((1.0 - ((seed * (seed * seed * 15731 + 789221) + 1376312589) & 2147483647) / 1073741824.0f) + 1.0f) / 2.0f;
}

// TODO: include more seeds to prevent repetition
RNG::RNG(
	Position inputPosition,
	unsigned int inputFrameNumber
) :
	position(inputPosition),
	frameNumber(inputFrameNumber),
	repetition(0)
{}

// returns an int [0, maximum]
int RNG::generateUpTo(int maximum) {
	repetition += 1;
	
	return rand(
		position.x + repetition,
		position.y + repetition,
		frameNumber + repetition
	) * float(maximum + 1);
}
