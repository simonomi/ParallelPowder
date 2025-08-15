#include <metal_stdlib>

using namespace metal;

// screen-filling tri-strip
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
