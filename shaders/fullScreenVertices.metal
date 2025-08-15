#include <metal_stdlib>
#include "VertexShaderResult.hpp"

using namespace metal;

// screen-filling tri-strip
constant float2 quadVertices[] = {
	float2(-1, -1),
	float2(-1,  1),
	float2( 1, -1),
	float2( 1,  1)
};

vertex VertexShaderResult fullScreenVertices(unsigned short vid [[vertex_id]]) {
	float2 position = quadVertices[vid];
	
	return VertexShaderResult {
		float4(position, 0, 1),
		position / 2 + 0.5 // remap to 0-1
	};
}
