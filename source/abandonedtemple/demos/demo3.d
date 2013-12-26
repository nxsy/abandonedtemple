module abandonedtemple.demos.demo3;

import std.stdio : writefln;

import derelict.glfw3.glfw3;
import derelict.opengl3.gl3;

import gl3n.linalg;

import abandonedtemple.demos.base : DemoBase;
import abandonedtemple.demos.demo3_program : program_from_shader_filenames;
import abandonedtemple.demos.demo3_glwrapper :
    VertexArray, ArrayBuffer, ElementArrayBuffer;
import abandonedtemple.demos.demo3_mixin : DemoMixin;

mixin(program_from_shader_filenames("RainbowProgram", ["demo3/FragmentShader.frag","demo3/VertexShader.vert"]));
mixin(program_from_shader_filenames("ChessProgram", ["demo3/FragmentShader.frag","demo3/ChessBoard.vert"]));

class RainbowCube {
    VertexArray va;
    ArrayBuffer vertices;
    ElementArrayBuffer cube;
    ElementArrayBuffer lines;

    RainbowProgram program;

    this(RainbowProgram p) {
        program = p;

        va = new VertexArray();
        va.bind();

        const float vertices_[] = [
            -1f, -1f, -1f, 1f,   1f,  0f, 0f,
            -1f,  1f, -1f, 1f,   0f,  1f, 0f,
             1f,  1f, -1f, 1f,   0f,  0f, 1f,
             1f, -1f, -1f, 1f,   1f,  1f, 0f,

            -1f, -1f,  1f, 1f,   0f,  0f, 1f,
            -1f,  1f,  1f, 1f,   1f,  1f, 0f,
             1f,  1f,  1f, 1f,   1f,  0f, 0f,
             1f, -1f,  1f, 1f,   0f,  1f, 0f,
        ];
        vertices = new ArrayBuffer();
        vertices.setData!(const float[])(vertices_, GL_STATIC_DRAW);

        ushort cube_elements[] = [
            // back face
            0, 1, 2,
            0, 2, 3,
            // front face
            4, 5, 6,
            4, 6, 7,
            // left face
            0, 4, 5,
            0, 1, 5,
            // right face
            2, 6, 7,
            2, 3, 7,
            // bottom face
            0, 3, 4,
            3, 4, 7,
            // top face
            1, 2, 5,
            2, 5, 6,
        ];
        cube = new ElementArrayBuffer();
        cube.setData!(ushort[])(cube_elements, GL_STATIC_DRAW);

        ushort line_elements[] = [
            // back face
            0, 1,
            1, 2,
            2, 3,
            3, 0,

            // front face
            4, 5,
            5, 6,
            6, 7,
            7, 4,

            // remainder of left face
            // 0, 1, // already in back face
            // 4, 5, // already in front face
            0, 4,
            1, 5,

            // remainder of right face
            // 2, 3, // already in back face
            // 6, 7, // already in front face
            2, 6,
            3, 7,

            // top and bottom faces already have all lines
        ];
        lines = new ElementArrayBuffer();
        lines.setData!(ushort[])(line_elements, GL_STATIC_DRAW);

        lines.unbind();
        va.unbind();
    }

    void draw() {
        program.uniforms.is_line = 0;
        vertices.bind();
        cube.bind();
        // Layout of the stuff to draw
        glVertexAttribPointer(0, 4, GL_FLOAT, GL_FALSE, 7 * float.sizeof, cast(void*)(0 * float.sizeof));
        glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 7 * float.sizeof, cast(void*)(4 * float.sizeof));

        // Draw it!
        glDrawElements(GL_TRIANGLES, 36, GL_UNSIGNED_SHORT, cast(void *)0);

        program.uniforms.is_line = 1;
        lines.bind();

        glDrawElements(GL_LINES, 24, GL_UNSIGNED_SHORT, cast(void *)0);
    }

    void bind() {
        va.bind();
        program.use();
        glEnableVertexAttribArray(0);
        glEnableVertexAttribArray(1);
    }

    void unbind() {
        glDisableVertexAttribArray(1);
        glDisableVertexAttribArray(0);
        va.unbind();
    }
}

class ChessCube {
    VertexArray va;
    ArrayBuffer vertices;
    ElementArrayBuffer cube;
    ElementArrayBuffer lines;

    ChessProgram program;

    this(ChessProgram p) {
        program = p;

        va = new VertexArray();
        va.bind();

        const float vertices_[] = [
            -1f, -1f, -1f, 1f,   0f,  0f, 0f,
            -1f,  1f, -1f, 1f,   1f,  1f, 1f,
             1f,  1f, -1f, 1f,   1f,  1f, 1f,
             1f, -1f, -1f, 1f,   0f,  0f, 0f,

            -1f, -1f,  1f, 1f,   0f,  0f, 0f,
            -1f,  1f,  1f, 1f,   1f,  1f, 1f,
             1f,  1f,  1f, 1f,   1f,  1f, 1f,
             1f, -1f,  1f, 1f,   0f,  0f, 0f,
        ];
        vertices = new ArrayBuffer();
        vertices.setData!(const float[])(vertices_, GL_STATIC_DRAW);

        ushort cube_elements[] = [
            // back face
            0, 1, 2,
            0, 2, 3,
            // front face
            4, 5, 6,
            4, 6, 7,
            // left face
            0, 4, 5,
            0, 1, 5,
            // right face
            2, 6, 7,
            2, 3, 7,
            // bottom face
            0, 3, 4,
            3, 4, 7,
            // top face
            1, 2, 5,
            2, 5, 6,
        ];
        cube = new ElementArrayBuffer();
        cube.setData!(ushort[])(cube_elements, GL_STATIC_DRAW);

        cube.unbind();
        va.unbind();
    }

    void draw() {
        vertices.bind();
        cube.bind();
        // Layout of the stuff to draw
        glVertexAttribPointer(0, 4, GL_FLOAT, GL_FALSE, 7 * float.sizeof, cast(void*)(0 * float.sizeof));
        glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 7 * float.sizeof, cast(void*)(4 * float.sizeof));

        // Draw it!
        glDrawElementsInstanced(GL_TRIANGLES, 36, GL_UNSIGNED_SHORT, cast(void *)0, 256);
    }

    void bind() {
        va.bind();
        program.use();
        glEnableVertexAttribArray(0);
        glEnableVertexAttribArray(1);
    }

    void unbind() {
        glDisableVertexAttribArray(1);
        glDisableVertexAttribArray(0);
        va.unbind();
    }
}

class Demo : DemoBase {
    mixin DemoMixin;
    private {
        /*
        VertexArray va;
        ArrayBuffer vertices;
        ElementArrayBuffer cube;
        ElementArrayBuffer lines;
        */

        RainbowCube rainbowCube;
        ChessCube chessCube;

        ChessProgram chessProgram;
        RainbowProgram rainbowProgram;

        mat4 frustumMatrix;

        void bufferInit() {
            chessCube = new ChessCube(chessProgram);
            rainbowCube = new RainbowCube(rainbowProgram);
        }

        mat4 calculateFrustum(float scale, float aspect, float near, float far) {
            mat4 ret = mat4(0);
            ret[0][0] = scale / aspect;
            ret[1][1] = scale;
            ret[2][2] = (far+near)/(far-near);
            ret[2][3] = -1f;
            ret[3][2] = (2 * far * near)/(far-near);
            return ret;
        }

        void updateFrustum() {
            auto aspect = cast(float)width / height;
            frustumMatrix = mat4.identity * calculateFrustum(1f, aspect, 0.5f, 25f);
        }

        void drawRainbowCubes() {
            rainbowCube.bind();

            rainbowProgram.uniforms.u_frustum.setTranspose(true);
            rainbowProgram.uniforms.u_frustum = frustumMatrix;

            auto cube_translations = [
                [ -0.6f, -0.6f, -0.6f ], // left, bottom, back
                [ -0.6f,    0f,  0.6f ], // left, middle, front
                [ -0.6f,  0.6f,    0f ], // left, top, middle
                [    0f, -0.6f,  0.6f ], // middle, bottom, front
                [    0f,    0f,    0f ], // middle, middle, middle
                [    0f,  0.6f, -0.6f ], // middle, top, back
                [  0.6f, -0.6f,    0f ], // right, bottom, middle
                [  0.6f,    0f, -0.6f ], // right, middle, back
                [  0.6f,  0.6f,  0.6f ], // right, top, front
            ];

            foreach (float[] translation; cube_translations) {
                auto matrix = mat4.identity
                    .scale(0.2, 0.2, 0.2)
                    ;
                rainbowProgram.uniforms.u_transform = matrix;
                rainbowProgram.uniforms.u_offset = vec4(translation[0], translation[1], -2 + translation[2], 0f);

                // What to draw
                rainbowCube.draw();
            }

            // Disable all the things
            rainbowCube.unbind();
            glUseProgram(0);
        }

        void drawChessCubes() {
            chessCube.bind();

            chessProgram.uniforms.u_frustum.setTranspose(true);
            chessProgram.uniforms.u_frustum = frustumMatrix;

            auto matrix = mat4.identity.scale(0.2, 0.2, 0.2);
            chessProgram.uniforms.u_transform = matrix;
            chessProgram.uniforms.u_offset = vec4(-3, -2, -2, 0);
            chessProgram.uniforms.width = 16;


            // What to draw
            chessCube.draw();

            // Disable all the things
            chessCube.unbind();
            glUseProgram(0);
        }

        void display() {
            updateFrustum();

            glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);

            drawRainbowCubes();
            drawChessCubes();
        }

        void init() {
            rainbowProgram = new RainbowProgram();
            chessProgram = new ChessProgram();
            glClearColor(0.0f, 0.0f, 0.3f, 0.0f);

            bufferInit();

            glEnable(GL_DEPTH_TEST);
            glDepthMask(GL_TRUE);
            glDepthFunc(GL_GREATER);
            glClearDepth(-1f);

            glEnable(GL_LINE_SMOOTH);
            glLineWidth(10);
        }
    }
}
