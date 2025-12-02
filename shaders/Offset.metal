#include <metal_stdlib>
#include "Offset.hpp"

using namespace metal;

int16_t xOffsetFor(Offset offset) {
	switch (offset) {
		case Offset::upLeft:
		case Offset::left:
		case Offset::downLeft:
			return -1;
		case Offset::upRight:
		case Offset::right:
		case Offset::downRight:
			return 1;
		case Offset::up:
		case Offset::down:
			return 0;
	}
}

int16_t yOffsetFor(Offset offset) {
	switch (offset) {
		case Offset::upLeft:
		case Offset::up:
		case Offset::upRight:
			return 1;
		case Offset::downLeft:
		case Offset::down:
		case Offset::downRight:
			return -1;
		case Offset::left:
		case Offset::right:
			return 0;
	}
}
