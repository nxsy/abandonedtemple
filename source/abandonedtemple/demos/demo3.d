module abandonedtemple.demos.demo3;

import derelict.glfw3.glfw3;
import derelict.opengl3.gl3;

import gl3n.linalg;

import abandonedtemple.demos.base : DemoBase;
import abandonedtemple.demos.demo3_program : program_from_shader_filenames;

mixin(program_from_shader_filenames("Program", ["demo3/FragmentShader.frag","demo3/VertexShader.vert"]));

class Demo : DemoBase {
    private {
        int width, height;
        string programName;

        GLFWwindow *window;

        GLint program;
        Program _program;

        GLuint vertexArray;
        GLuint vertexBuffer;
        GLuint cubeElements;
        GLuint lineElements;

        double startTime = 0;
        double timeDiff = 0;

        mat4 frustumMatrix;

        void glInit() {
            DerelictGL3.load();
            DerelictGLFW3.load();

            if(!glfwInit()) {
                glfwTerminate();
                throw new Exception("Failed to create glcontext");
            }

            glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
            glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 2);
            glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE);
            glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);

            window = glfwCreateWindow(width, height, programName.ptr, null,
                null);
            if(!window) {
                glfwTerminate();
                throw new Exception("Failed to create window");
            }

            glfwMakeContextCurrent(window);

            DerelictGL3.reload();
        }

        void programInit() {
            _program = new Program();
        }

        void bufferInit() {
            glGenVertexArrays(1, &vertexArray);
            glBindVertexArray(vertexArray);

            const GLfloat vertices[] = [
                -1f, -1f, -1f, 1f,   1f,  0f, 0f,
                -1f,  1f, -1f, 1f,   0f,  1f, 0f,
                 1f,  1f, -1f, 1f,   0f,  0f, 1f,
                 1f, -1f, -1f, 1f,   1f,  1f, 0f,

                -1f, -1f,  1f, 1f,   0f,  0f, 1f,
                -1f,  1f,  1f, 1f,   1f,  1f, 0f,
                 1f,  1f,  1f, 1f,   1f,  0f, 0f,
                 1f, -1f,  1f, 1f,   0f,  1f, 0f,
            ];
            GLushort cube_elements[] = [
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

            GLushort line_elements[] = [
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

            glGenBuffers(1, &vertexBuffer);
            glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
            glBufferData(GL_ARRAY_BUFFER,
                vertices.length * GLfloat.sizeof,
                vertices.ptr,
                GL_STATIC_DRAW);

            glGenBuffers(1, &cubeElements);
            glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, cubeElements);
            glBufferData(GL_ELEMENT_ARRAY_BUFFER, cube_elements.length * GLushort.sizeof, cube_elements.ptr, GL_STATIC_DRAW);

            glGenBuffers(1, &lineElements);
            glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, lineElements);
            glBufferData(GL_ELEMENT_ARRAY_BUFFER, line_elements.length * GLushort.sizeof, line_elements.ptr, GL_STATIC_DRAW);

            glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
            glBindVertexArray(0);
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
            frustumMatrix = mat4.identity * calculateFrustum(1f, aspect, 0.5f, 3f);
        }

        void display() {
            if (!startTime) {
                startTime = glfwGetTime();
            }
            timeDiff = glfwGetTime() - startTime;
            glfwGetFramebufferSize(window, &width, &height);
            updateFrustum();

            glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);

            // Enable all the things
            _program.use();
            glBindVertexArray(vertexArray);

            _program.uniforms.u_frustum.setTranspose(true);
            _program.uniforms.u_frustum = frustumMatrix;

            glEnableVertexAttribArray(0);
            glEnableVertexAttribArray(1);

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
                _program.uniforms.u_transform = matrix;
                _program.uniforms.u_offset = vec4(translation[0], translation[1], -2 + translation[2], 0f);
                _program.uniforms.is_line = 0;

                // What to draw
                glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
                glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, cubeElements);
                // Layout of the stuff to draw
                glVertexAttribPointer(0, 4, GL_FLOAT, GL_FALSE, 7 * GLfloat.sizeof, cast(void*)(0 * GLfloat.sizeof));
                glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 7 * GLfloat.sizeof, cast(void*)(4 * GLfloat.sizeof));

                // Draw it!
                glDrawElements(GL_TRIANGLES, 36, GL_UNSIGNED_SHORT, cast(void *)0);

                _program.uniforms.is_line = 1;
                glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, lineElements);

                glDrawElements(GL_LINES, 24, GL_UNSIGNED_SHORT, cast(void *)0);
            }

            // Disable all the things
            glDisableVertexAttribArray(1);
            glDisableVertexAttribArray(0);
            glBindVertexArray(0);
            glUseProgram(0);
        }

    }

    public {
        this(int width, int height, string programName) {
            this.width = width;
            this.height = height;
            this.programName = programName;
        }
        this() {
            this(1280, 720, this.toString());
        }

        void run() {
            glInit();
            programInit();
            bufferInit();

            glClearColor(0.0f, 0.0f, 0.3f, 0.0f);

            glEnable(GL_DEPTH_TEST);
            glDepthMask(GL_TRUE);
            glDepthFunc(GL_GREATER);
            glClearDepth(-1f);

            glEnable(GL_LINE_SMOOTH);
            glLineWidth(10);

            while (!glfwWindowShouldClose(window)) {
                display();
                glfwSwapBuffers(window);
                glfwPollEvents();
            }
        }
    }
}
