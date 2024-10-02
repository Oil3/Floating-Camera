//
//  brightness.metal
//  Floating Camera
//
//  Created by Almahdi Morris on 1/10/24.
//

#include <metal_stdlib>
using namespace metal;

kernel void brightnessAdjustment(texture2d<float, access::read> inTexture [[texture(0)]],
                                 texture2d<float, access::write> outTexture [[texture(1)]],
                                 constant float &brightness [[buffer(0)]],
                                 uint2 gid [[thread_position_in_grid]]) {
  if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) {
    return;
  }
  
  float4 color = inTexture.read(gid);
  color.rgb *= brightness; // multiply brightness
  color.rgb = clamp(color.rgb, 0.0, 1.0);
//  color.a = inTexture.read(gid).a; // no

  outTexture.write(color, gid);
}
