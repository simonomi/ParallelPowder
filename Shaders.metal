#include <metal_stdlib>
#include "SharedTypes.h"

using namespace metal;

float4 colorFor(Pixel pixel) {
	switch (pixel) {
		case AIR:
			return float4(0, 0, 0, 1);
		case SAND:
			return float4(1, 0.9, 0.8, 1);
		case WATER:
			return float4(0, 0.4, 0.6, 1);
		default:
			return float4(1, 0, 1, 1);
	}
}

class Cell {
public:
	constant Pixel *board;
	uint2 boardSize;
	uint2 cellPosition;
	
	Cell(
		constant Pixel* inputBoard,
		constant Uniforms *uniforms,
		uint2 position
	) {
		board = inputBoard;
		boardSize = uint2(uniforms->width, uniforms->height);
		cellPosition = position;
	}
	
	Pixel value() {
		return board[cellPosition.y * boardSize.x + cellPosition.x];
	}
	
	Pixel above() {
//		return offsetBy(0, 1);
		
		if (cellPosition.y + 1 >= boardSize.y) {
			return BORDER;
		} else {
			return board[(cellPosition.y + 1) * boardSize.x + cellPosition.x];
		}
	}
	
	Pixel below() {
//		return offsetBy(0, -1);
		
		if (cellPosition.y < 1) {
			return BORDER;
		} else {
			return board[(cellPosition.y - 1) * boardSize.x + cellPosition.x];
		}
	}
	
	Pixel right() {
//		return offsetBy(1, 0);
		
		if (cellPosition.x + 1 >= boardSize.x) {
			return BORDER;
		} else {
			return board[cellPosition.y * boardSize.x + (cellPosition.x + 1)];
		}
	}
	
	Pixel left() {
//		return offsetBy(-1, 0);
		
		if (cellPosition.x < 1) {
			return BORDER;
		} else {
			return board[cellPosition.y * boardSize.x + (cellPosition.x - 1)];
		}
	}
	
	// doesnt work right for some reason
	Pixel offsetBy(int x, int y) {
		if (
			(x < 0 && cellPosition.x - x < 0) ||
			(x > 0 && cellPosition.x + x >= boardSize.x) ||
			(y < 0 && cellPosition.y - y < 0) ||
			(y > 0 && cellPosition.y + y >= boardSize.y)
		) {
			return BORDER;
		} else {
			return board[(cellPosition.y + y) * boardSize.x + (cellPosition.x + x)];
		}
	}
};

class MutableCell {
public:
	device Pixel *board;
	uint boardWidth;
	uint2 cellPosition;
	
	MutableCell(
		device Pixel* inputBoard,
		constant Uniforms *uniforms,
		uint2 position
	) {
		board = inputBoard;
		boardWidth = uniforms->width;
		cellPosition = position;
	}
	
	Pixel value() {
		return board[cellPosition.y * boardWidth + cellPosition.x];
	}
	
	void setValueTo(Pixel newValue) {
		board[cellPosition.y * boardWidth + cellPosition.x] = newValue;
	}
};

kernel void tick(
	uint2 tid [[thread_position_in_grid]],
	constant Uniforms *uniforms [[buffer(0)]],
	constant Pixel *previousTick [[buffer(1)]],
	device Pixel *currentTick [[buffer(2)]],
	texture2d<float, access::write> displayBuffer [[texture(0)]]
) {
	if (tid.y >= uniforms->height || tid.x >= uniforms->width) {
		return;
	}
	
	Cell previous(previousTick, uniforms, tid);
	MutableCell current(currentTick, uniforms, tid);
	
//	uint num = 12;
//	int x = 2;
//	bool condition = num + x == 14;
//	bool condition = previous.left() == SAND;
//	
//	if (condition) {
//		displayBuffer.write(float4(0, 1, 0, 1), tid);
//		return;
//	} else {
//		displayBuffer.write(float4(1, 0, 0, 1), tid);
//		return;
//	}
	
	
	
	if (previous.value() == AIR && previous.above() == SAND) {
		current.setValueTo(SAND);
	} else if (previous.value() == SAND && previous.below() == AIR) {
		current.setValueTo(AIR);
	} else {
		current.setValueTo(previous.value());
	}
	
	displayBuffer.write(colorFor(current.value()), tid);
	
	
//	if (tid.x == 0 || tid.x == uniforms->width - 1 || tid.y == 0 || tid.y == uniforms->height - 1) {
//	if (tid.x < 5 && tid.y < 5) {
//		displayBuffer.write(float4(1, 0, 1, 1), tid);
//	}
}

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
