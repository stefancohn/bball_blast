#version 460 core

#include <flutter/runtime_effect.glsl>

uniform float u_time;
uniform sampler2D texture0;
uniform vec2 resolution;
uniform vec4 color1;
uniform vec4 color2;
uniform vec4 color3;
uniform float speed;

out vec4 fragColor;

void main() 
{
    float x = FlutterFragCoord().x;
    float y = FlutterFragCoord().y;
    
    // Sample the texture and set up uv
    vec2 uv = vec2(x, y) / resolution;
    vec4 texColor = texture(texture0, uv);

    // Calculate grayscale
    float brightness = (texColor.r + texColor.g + texColor.b) / 3.f;
    vec4 grayScale = vec4(brightness, brightness, brightness, texColor.a);

    //define colors
    vec4 topColor = color1;
    vec4 middleColor = color2;
    vec4 bottomColor = color3;

    //animation offset
    float speed = speed; 
    float offset = mod(u_time * speed, 1);

    //apply offset to uv
    float offsetY = mod(uv.y + offset, 1.0);

    //segment into thirds
    float segment = 1.0 / 3.0;
    float segmentedY = offsetY / segment;
    float mixFactor = mod(segmentedY, 1.0); 
    int segmentIndex = int(floor(segmentedY));

    //interpolate colors on segment
    if (segmentIndex == 0) {
        fragColor = mix(bottomColor, middleColor, mixFactor) * grayScale;
        fragColor.a *= texColor.a; //preserve transparency
    } else if (segmentIndex == 1) {
        fragColor = mix(middleColor, topColor, mixFactor)* grayScale;
        fragColor.a *= texColor.a;
    } else {
         fragColor = mix(topColor, bottomColor, mixFactor) * grayScale; // Seamless transition back to bottom color
         fragColor.a *= texColor.a;
    }
}