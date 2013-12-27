module abandonedtemple.demos.demo3;

import std.math : sin;
import std.stdio : writefln;

import derelict.glfw3.glfw3;
import derelict.opengl3.gl3;
import derelict.stb_image.stb_image;

import gl3n.linalg;

import abandonedtemple.demos.base : DemoBase;
import abandonedtemple.demos.demo3_program : program_from_shader_filenames;
import abandonedtemple.demos.demo3_glwrapper :
    VertexArray, ArrayBuffer, ElementArrayBuffer, Texture2D;
import abandonedtemple.demos.demo3_mixin : DemoMixin;

mixin(program_from_shader_filenames("RainbowProgram", ["demo3/FragmentShader.frag","demo3/VertexShader.vert"]));
mixin(program_from_shader_filenames("ChessProgram", ["demo3/FragmentShader.frag","demo3/ChessBoard.vert"]));
mixin(program_from_shader_filenames("DiceFaceProgram", ["demo3/DiceFace.frag","demo3/DiceFace.vert"]));

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
        glDrawElementsInstanced(GL_TRIANGLES, 36, GL_UNSIGNED_SHORT, cast(void *)0, 8192);
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

class DiceFace {
    VertexArray va;
    ArrayBuffer vertices;
    ElementArrayBuffer cube;
    ElementArrayBuffer lines;
    Texture2D texture;

    DiceFaceProgram program;
    import std.path : buildPath, dirName;

    this(DiceFaceProgram p) {
        program = p;

        va = new VertexArray();
        va.bind();

        texture = new Texture2D();
        glActiveTexture(GL_TEXTURE0);
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        texture.bind();

        int width, height, comp;
        string filepath = "dice_texture.png";
        char* image_data = stbi_load(filepath.ptr, &width, &height, &comp, 4);
        writefln("Width: %d, Height: %d, Comp: %d", width, height, comp);
        texture.setData(image_data, width, height);

        const float vertices_[] = [
            // back face - 1
            -1f, -1f, -1f, 1f,   1, 0.5, 0.5,  (0/3f),  (0/2f),
            -1f,  1f, -1f, 1f,   1, 0.5, 0.5,  (0/3f),  (1/2f),
             1f,  1f, -1f, 1f,   1, 0.5, 0.5,  (1/3f),  (1/2f),
             1f, -1f, -1f, 1f,   1, 0.5, 0.5,  (1/3f),  (0/2f),

            // front face - 6
            -1f, -1f,  1f, 1f,   1, 0.5, 0.5,  (2/3f),  (1/2f),
            -1f,  1f,  1f, 1f,   1, 0.5, 0.5,  (2/3f),  (2/2f),
             1f,  1f,  1f, 1f,   1, 0.5, 0.5,  (3/3f),  (2/2f),
             1f, -1f,  1f, 1f,   1, 0.5, 0.5,  (3/3f),  (1/2f),

            // top face - 3
            -1f,  1f, -1f, 1f,   1, 0.5, 0.5,  (1/3f),  (0/2f),
            -1f,  1f,  1f, 1f,   1, 0.5, 0.5,  (1/3f),  (1/2f),
             1f,  1f,  1f, 1f,   1, 0.5, 0.5,  (2/3f),  (1/2f),
             1f,  1f, -1f, 1f,   1, 0.5, 0.5,  (2/3f),  (0/2f),

            // bottom face - 4
            -1f, -1f, -1f, 1f,   1, 0.5, 0.5,  (1/3f),  (1/2f),
            -1f, -1f,  1f, 1f,   1, 0.5, 0.5,  (1/3f),  (2/2f),
             1f, -1f,  1f, 1f,   1, 0.5, 0.5,  (2/3f),  (2/2f),
             1f, -1f, -1f, 1f,   1, 0.5, 0.5,  (2/3f),  (1/2f),

            // left face - 2
            -1f, -1f, -1f, 1f,   1, 0.5, 0.5,  (0/3f),  (1/2f),
            -1f, -1f,  1f, 1f,   1, 0.5, 0.5,  (0/3f),  (2/2f),
            -1f,  1f,  1f, 1f,   1, 0.5, 0.5,  (1/3f),  (2/2f),
            -1f,  1f, -1f, 1f,   1, 0.5, 0.5,  (1/3f),  (1/2f),

            // right face - 5
             1f, -1f, -1f, 1f,   1, 0.5, 0.5,  (2/3f),  (0/2f),
             1f, -1f,  1f, 1f,   1, 0.5, 0.5,  (2/3f),  (1/2f),
             1f,  1f,  1f, 1f,   1, 0.5, 0.5,  (3/3f),  (1/2f),
             1f,  1f, -1f, 1f,   1, 0.5, 0.5,  (3/3f),  (0/2f),

        ];
        vertices = new ArrayBuffer();
        vertices.setData!(const float[])(vertices_, GL_STATIC_DRAW);

        ushort cube_elements[];
        foreach (int x; [0,1,2,3,4,5]) {
            foreach (int y; [0, 1, 2, 0, 2, 3]) {
                cube_elements ~= cast(ushort)((x*4) + y);
            }
        }
        cube = new ElementArrayBuffer();
        cube.setData!(ushort[])(cube_elements, GL_STATIC_DRAW);

        ushort line_elements[];
        foreach (int x; [0,1,2,3,4,5]) {
            foreach (int y; [0, 1, 1, 2, 2, 3, 3, 0]) {
                line_elements ~= cast(ushort)((x*4) + y);
            }
        }
        lines = new ElementArrayBuffer();
        lines.setData!(ushort[])(line_elements, GL_STATIC_DRAW);

        lines.unbind();
        va.unbind();
    }

    void draw() {
        program.uniforms.is_line = 0;
        program.uniforms.tex = 0;
        vertices.bind();
        cube.bind();
        texture.bind();
        // Layout of the stuff to draw
        glVertexAttribPointer(0, 4, GL_FLOAT, GL_FALSE, 9 * float.sizeof, cast(void*)(0 * float.sizeof));
        glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 9 * float.sizeof, cast(void*)(4 * float.sizeof));
        glVertexAttribPointer(2, 2, GL_FLOAT, GL_FALSE, 9 * float.sizeof, cast(void*)(7 * float.sizeof));

        // Draw it!
        glDrawElements(GL_TRIANGLES, 36, GL_UNSIGNED_SHORT, cast(void *)0);

        program.uniforms.is_line = 1;
        lines.bind();

        glDrawElements(GL_LINES, 48, GL_UNSIGNED_SHORT, cast(void *)0);
    }

    void bind() {
        va.bind();
        program.use();
        glEnableVertexAttribArray(0);
        glEnableVertexAttribArray(1);
        glEnableVertexAttribArray(2);
    }

    void unbind() {
        glDisableVertexAttribArray(2);
        glDisableVertexAttribArray(1);
        glDisableVertexAttribArray(0);
        va.unbind();
    }
}

class Demo : DemoBase {
    mixin DemoMixin;
    private {
        RainbowCube rainbowCube;
        ChessCube chessCube;
        DiceFace diceFace;

        ChessProgram chessProgram;
        RainbowProgram rainbowProgram;
        DiceFaceProgram diceFaceProgram;

        mat4 frustumMatrix;

        void bufferInit() {
            chessCube = new ChessCube(chessProgram);
            rainbowCube = new RainbowCube(rainbowProgram);
            diceFace = new DiceFace(diceFaceProgram);
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
            frustumMatrix = mat4.identity * calculateFrustum(1f, aspect, 0.5f, 100f);
        }

        void drawRainbowCubes() {
            rainbowCube.bind();

            rainbowProgram.uniforms.u_frustum.setTranspose(true);
            rainbowProgram.uniforms.u_frustum = frustumMatrix;

            auto cube_translations = [
                [ -1.2f, -1.0f, -1.2f, 2f, -4.5f ], // left, bottom, back
                [ -1.2f,    0f,  1.2f, -2f, -3.5f ], // left, middle, front
                [ -1.2f,  1.2f,    0f, 1f, 2.5f ], // left, top, middle
                [    0f, -1.0f,  1.2f, -1f, 2.5f ], // middle, bottom, front
//                [    0f,    0f,    0f, 9f, 5.5f ], // middle, middle, middle
                [    0f,  1.2f, -1.2f, -3f, 6.5f ], // middle, top, back
                [  1.2f, -1.0f,    0f, 1f, -2.5f ], // right, bottom, middle
                [  1.2f,    0f, -1.2f, -2f, -4.5f ], // right, middle, back
                [  1.2f,  1.2f,  1.2f, 2f, 7.5f ], // right, top, front
            ];

            foreach (float[] translation; cube_translations) {
                auto matrix = mat4.identity
                    .rotatez(timeDiff * translation[3])
                    .rotatex(timeDiff * translation[4])
                    .scale(0.3, 0.3, 0.3)
                    ;
                rainbowProgram.uniforms.u_transform = matrix;
                rainbowProgram.uniforms.u_offset = vec4((translation[0] + 0.1) * (1 + sin(timeDiff * (4 / translation[3])) / 2), translation[1] * (1 + sin(timeDiff / 2) / 4), -3.5 + translation[2], 0f);

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

            auto matrix = mat4.identity.scale(0.4, 0.4, 0.4);
            chessProgram.uniforms.u_transform = matrix;
            chessProgram.uniforms.u_offset = vec4(-48, -2, -2, 0);
            chessProgram.uniforms.width = 128;


            // What to draw
            chessCube.draw();

            // Disable all the things
            chessCube.unbind();
            glUseProgram(0);
        }

        void drawDiceFace() {
            diceFace.bind();

            diceFaceProgram.uniforms.u_frustum.setTranspose(true);
            diceFaceProgram.uniforms.u_frustum = frustumMatrix;

            auto matrix = mat4.identity
                .rotatez(timeDiff)
                .rotatex(timeDiff)
                .scale(0.5, 0.5, 0.5);
            diceFaceProgram.uniforms.u_transform = matrix;
            diceFaceProgram.uniforms.u_offset = vec4(0, 0, -4, 0);


            // What to draw
            diceFace.draw();

            // Disable all the things
            diceFace.unbind();
            glUseProgram(0);
        }


        void display() {
            updateFrustum();

            glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);

            drawRainbowCubes();
            drawChessCubes();
            drawDiceFace();
        }

        void init() {
            DerelictStb_image.load();
            rainbowProgram = new RainbowProgram();
            diceFaceProgram = new DiceFaceProgram();
            chessProgram = new ChessProgram();
            glClearColor(0.0f, 0.0f, 0.3f, 0.0f);

            bufferInit();

            glEnable(GL_DEPTH_TEST);
            glDepthMask(GL_TRUE);
            glDepthFunc(GL_GREATER);
            glClearDepth(-1f);

            glEnable(GL_TEXTURE_2D);

            glEnable(GL_LINE_SMOOTH);
            glLineWidth(10);
        }
    }
}
