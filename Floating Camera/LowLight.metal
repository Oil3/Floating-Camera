//
//  brightness.metal
//  Floating Camera
//
//  Created by Almahdi Morris on 1/10/24.
//
#include <metal_stdlib>
using namespace metal;

kernel void brightnessAdjustment(texture2d<float> inTexture [[texture(0)]],
                                 texture2d<float, access::write> outTexture [[texture(1)]],
                                 constant float &brightness [[buffer(0)]],
                                 uint2 gid [[thread_position_in_grid]]) {
  uint width = outTexture.get_width();
  uint height = outTexture.get_height();
  
  if (gid.x >= width || gid.y >= height) {
    return;
  }
  
  // Calculate normalized coordinates (0.0 to 1.0)
  float2 uv = float2(gid) / float2(width, height);
  
  // Use a sampler for texture sampling
  constexpr sampler textureSampler (mag_filter::linear, min_filter::linear);
  
  // Sample the input texture using normalized coordinates
  float4 color = inTexture.sample(textureSampler, uv);
  
  // Apply brightness adjustment
  color.rgb *= brightness;
  
  // Write the adjusted color to the output texture
  outTexture.write(color, gid);
}
