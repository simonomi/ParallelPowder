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

struct Position {
	int x;
	int y;
	
	Position(int inputX, int inputY) :
		x(inputX),
		y(inputY)
	{};
	
	Position(uint2 inputPosition) :
		x(inputPosition.x),
		y(inputPosition.y)
	{};
	
	bool operator==(Position other) {
		return x == other.x && y == other.y;
	}
	
	Position below() {
		return Position(x, y - 1);
	};
	
	Position offsetBy(int xOffset, int yOffset) {
		return Position(x + xOffset, y + yOffset);
	};
};

// yoinked from https://stackoverflow.com/a/47499626
// Generate a random float in the range [0.0f, 1.0f] using x, y, and z (based on the xor128 algorithm)
float rand(int x, int y, int z) {
	int seed = x + y * 57 + z * 241;
	seed = (seed << 13) ^ seed;
	return ((1.0 - ((seed * (seed * seed * 15731 + 789221) + 1376312589) & 2147483647) / 1073741824.0f) + 1.0f) / 2.0f;
}

struct RNG {
	unsigned int frameNumber;
	Position position;
	int repetition;
	
	RNG(
		unsigned int inputFrameNumber,
		Position inputPosition
	) :
		frameNumber(inputFrameNumber),
		position(inputPosition),
		repetition(0)
	{}
	
	// TODO: does this work... like at all?
	// should return [0, maximum]
	int generateUpTo(int maximum) {
		repetition += 1; // TODO: does this mutate self.repetition?
		
		return rand(
			frameNumber + repetition,
			position.x + repetition,
			position.y + repetition
		) * float(maximum);
	}
};

struct Goal {
	enum struct Kind { change, swap } kind;
	
	union Data {
		Pixel newPixel;
		Position target;
	} data;
	
	int priority;
	
	static Goal changeTo(
		Pixel newPixel,
		int priority
	) {
		return Goal(
			Kind::change,
			Data { .newPixel = newPixel },
			priority
		);
	};
	
	static Goal swapWith(
		Position target,
		int priority
	) {
		return Goal(
			Kind::swap,
			Data { .target = target },
			priority
		);
	};
	
private:
	Goal(
		Kind inputKind,
		Data inputData,
		int inputPriority
	) :
		kind(inputKind),
		data(inputData),
		priority(inputPriority)
	{};
};

struct Board {
	device Pixel* pixels;
	int2 size;
	
	Board(
		device Pixel* inputPixels,
		constant const Uniforms* uniforms
	) : pixels(inputPixels) {
		size = int2(uniforms->width, uniforms->height);
	}
	
	bool containsPosition(Position position) {
		return position.x >= 0 && position.x < size.x &&
		       position.y >= 0 && position.y < size.y;
	}
	
	Pixel pixelAt(Position position) {
		return pixels[position.y * size.x + position.x];
	}
	
	void setPixelTo(Position position, Pixel newValue) {
		pixels[position.y * size.x + position.x] = newValue;
	}
	
	Goal goalForCellAt(Position position) {
		if (pixelAt(position) == Pixel::sand && pixelAt(position.below()) == Pixel::air) {
			return Goal::swapWith(position.below(), 0);
		} else {
			return Goal::changeTo(pixelAt(position), 0);
		}
	}
	
	/// should only be called if `position` is the target of at least one swap
	Position whoGetsToSwapTo(Position position, unsigned int frameNumber) {
		int highestPriority = -1;
		int numberConsidered = -1;
		Position currentWinner { -1, -1 };
		RNG rng { frameNumber, position };
		
		for (int y : {-1, 0, 1}) {
			for (int x : {-1, 0, 1}) {
				Position candidate = position.offsetBy(x, y);
				Goal goal = goalForCellAt(candidate);
				
				if (
					(goal.kind == Goal::Kind::swap && goal.data.target == position) ||
					(goal.kind == Goal::Kind::change && candidate == position)
				) {
					if (goal.priority > highestPriority) {
						highestPriority = goal.priority;
						numberConsidered = 1;
						currentWinner = candidate;
					} else if (goal.priority == highestPriority) {
						// each candidate has a (1/n) chance of winning,
						// which is equivalent to randomly selecting one
						if (rng.generateUpTo(numberConsidered) == 0) {
							currentWinner = candidate;
						}
						
						numberConsidered += 1;
					}
				}
			}
		}
		
		return currentWinner;
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
	
	Position position { tid };
	
	Board previous { previousTick, uniforms };
	Board current { currentTick, uniforms };
	
	Goal myGoal = previous.goalForCellAt(position);
	
	switch (myGoal.kind) {
		case Goal::Kind::change: {
			Position whoSwaps = previous.whoGetsToSwapTo(position, uniforms->frameNumber);
			
			if (whoSwaps == position) { // i get to change
				current.setPixelTo(position, myGoal.data.newPixel);
			} else { // someone swaps with me
				current.setPixelTo(position, previous.pixelAt(whoSwaps));
			}
			
			break;
		}
		case Goal::Kind::swap: {
			if (previous.goalForCellAt(myGoal.data.target).kind == Goal::Kind::swap) {
				current.setPixelTo(position, previous.pixelAt(position));
				break;
			}
			
			Position whoSwaps = previous.whoGetsToSwapTo(myGoal.data.target, uniforms->frameNumber);
			
			if (whoSwaps == position) { // i get to swap
				current.setPixelTo(position, previous.pixelAt(myGoal.data.target));
			} else { // someone else swaps
				current.setPixelTo(position, previous.pixelAt(position));
			}
			
			break;
		}
	}
	
	displayBuffer.write(colorFor(current.pixelAt(position)), tid);
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
