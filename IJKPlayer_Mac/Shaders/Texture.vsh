//
//  Shader.vsh
//  GLSLTest
//
//  Created by Zenny Chen on 4/11/10.
//  Copyright GreenGames Studio 2010. All rights reserved.
//

// 在OpenGL3.2 Core Profile中，版本号必须显式地给出
#version 410

in vec4 inPos;
in vec2 textureCoordsInput;
out vec2 textureCoords;

void main()
{
    gl_Position = inPos;
    textureCoords = textureCoordsInput;
}
