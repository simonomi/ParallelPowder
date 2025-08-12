#include <metal_stdlib>
#include "SharedTypes.h"

using namespace metal;

float4 colorFor(Pixel pixel) {
	switch (pixel) {
		case Pixel::border:
			return float4(1, 1, 1, 1);
		case Pixel::air:
			return float4(0, 0, 0, 1);
		case Pixel::sand:
			return float4(1, 0.9, 0.8, 1);
		case Pixel::water:
			return float4(0, 0.4, 0.6, 1);
		default:
			return float4(1, 0, 1, 1);
	}
}

//struct Position {
//	int x;
//	int y;
//};

//enum struct Neighbor {
//	topLeft,    top,    topRight,
//	left,       self,   right,
//	bottomLeft, bottom, bottomRight
//};

//struct Goal {
//	enum struct Kind { change, swap } kind;
//	
//	union {
//		Pixel changeTo;
//		Neighbor swapWith;
//	} data;
//	
//	int priority;
//};

struct Board {
	device Pixel* pixels;
	uint2 size;
	
	Board(
		device Pixel* inputPixels,
		constant const Uniforms* uniforms
	) : pixels(inputPixels) {
		size = uint2(uniforms->width, uniforms->height);
	}
	
	bool containsPosition(int x, int y) {
		return x >= 0 && x < int(size.x) &&
		       y >= 0 && y < int(size.y);
	}
	
	Pixel pixelAt(uint2 position) {
		return pixels[position.y * size.x + position.x];
	}
	
	Pixel pixelAt(int x, int y) {
		return pixels[y * size.x + x];
	}
	
	void setPixelTo(uint2 position, Pixel newValue) {
		pixels[position.y * size.x + position.x] = newValue;
	}
	
//	Goal goalForCellAt(uint2 position) {
////		if (previous.value() == Pixel::air && previous.above() == Pixel::sand) {
////			current.setValueTo(Pixel::sand);
////		} else if (previous.value() == Pixel::sand && previous.below() == Pixel::air) {
////			current.setValueTo(Pixel::air);
////		} else {
////			current.setValueTo(previous.value());
////		}
//	}
};

struct Cell {
	Board board;
	uint2 cellPosition;
	
	Cell(
		device Pixel* inputBoard,
		constant const Uniforms* uniforms,
		uint2 position
	) : board(inputBoard, uniforms), cellPosition(position) {}
	
	Pixel value() {
		return board.pixelAt(cellPosition);
	}
	
	void setValueTo(Pixel newValue) {
		board.setPixelTo(cellPosition, newValue);
	}
	
	Pixel above() {
		return offsetBy(0, 1);
	}
	
	Pixel below() {
		return offsetBy(0, -1);
	}
	
	Pixel right() {
		return offsetBy(1, 0);
	}
	
	Pixel left() {
		return offsetBy(-1, 0);
	}
	
private:
	Pixel offsetBy(int x, int y) {
		int newX = int(cellPosition.x) + x;
		int newY = int(cellPosition.y) + y;
		
		if (board.containsPosition(newX, newY)) {
			return board.pixelAt(newX, newY);
		} else {
			return Pixel::border;
		}
	}
};

kernel void tick(
	uint2 tid [[thread_position_in_grid]],
	constant const Uniforms* uniforms [[buffer(0)]],
	device Pixel* previousTick [[buffer(1)]],
	device Pixel* currentTick [[buffer(2)]],
	texture2d<float, access::write> displayBuffer [[texture(0)]]
) {
	if (tid.y >= uniforms->height || tid.x >= uniforms->width) {
		return;
	}
	
//	Board previous { previousTick, uniforms };
//	Board current { currentTick, uniforms };
	
	Cell previous(previousTick, uniforms, tid);
	Cell current(currentTick, uniforms, tid);
	
	if (previous.value() == Pixel::air && previous.above() == Pixel::sand) {
		current.setValueTo(Pixel::sand);
	} else if (previous.value() == Pixel::sand && previous.below() == Pixel::air) {
		current.setValueTo(Pixel::air);
	} else {
		current.setValueTo(previous.value());
	}
	
	displayBuffer.write(colorFor(current.value()), tid);
}

// MARK: boring texture-rendering stuff
// screen-filling quad
constant float2 quadVertices[] = {
	float2(-1, -1),
	float2(-1,  1),
	float2( 1, -1),
	float2( 1,  1)
};

struct CopyVertexOut {
	float4 position [[position]];
	float2 uv;
};

vertex CopyVertexOut copyVertex(unsigned short vid [[vertex_id]]) {
	float2 position = quadVertices[vid];
	
	CopyVertexOut out;
	
	out.position = float4(position, 0, 1);
	out.uv = position / 2 + 0.5;
	
	return out;
}

fragment float4 copyFragment(CopyVertexOut in [[stage_in]], texture2d<float> texture) {
	return texture.sample(sampler(), in.uv);
}
