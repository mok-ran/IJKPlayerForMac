//
//  Shader.vsh
//  GLSLTest
//
//  Created by Zenny Chen on 4/11/10.
//  Copyright GreenGames Studio 2010. All rights reserved.
//

// 在OpenGL3.2 Core Profile中，版本号必须显式地给出
#version 410

precision highp float;
in    highp vec2 vv2_Texcoord;
uniform         mat3 um3_ColorConversion;
uniform   lowp  sampler2D us2_SamplerX;
uniform   lowp  sampler2D us2_SamplerY;
out vec4 colorOut;
void main()
{
    mediump vec3 yuv;
    lowp    vec3 rgb;
    
    yuv.x  = (texture(us2_SamplerX,  vv2_Texcoord).r  - (16.0 / 255.0));
    yuv.yz = (texture(us2_SamplerY,  vv2_Texcoord).rg - vec2(0.5, 0.5));
    rgb = um3_ColorConversion * yuv;
    colorOut = vec4(rgb, 1);
}
