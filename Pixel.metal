#include <metal_stdlib>
#include "Pixel.hpp"

using namespace metal;

uint8_t densityOf(const Pixel pixel) {
	switch (pixel) {
		case Pixel::air:
			return 0;
		case Pixel::sand:
			return 2;
		case Pixel::water:
			return 1;
		case Pixel::outOfBounds:
		case Pixel::block:
		case Pixel::tree:
		case Pixel::fire:
			return 255;
	}
}
