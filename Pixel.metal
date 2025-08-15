#include <metal_stdlib>
#include "Pixel.hpp"

using namespace metal;

int densityOf(Pixel pixel) {
	switch (pixel) {
		case Pixel::air:
			return 0;
		case Pixel::sand:
			return 2;
		case Pixel::water:
			return 1;
		default:
			return 999;
	}
}
