//
//  Shader.fsh
//  GLSLTest
//
//  Created by Zenny Chen on 4/11/10.
//  Copyright GreenGames Studio 2010. All rights reserved.
//

// 在OpenGL3.2 Core Profile中，版本号必须显式地给出
#version 410

in vec2 textureCoords;
out vec4 myOutput;
uniform sampler2D texSampler;

void main()
{
    myOutput = texture(texSampler, textureCoords.st);
}
