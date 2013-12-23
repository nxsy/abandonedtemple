module abandonedtemple.demos.demo2;

import std.stdio : writefln;

import derelict.glfw3.glfw3;
import derelict.opengl3.gl3;

import gl3n.linalg;

import abandonedtemple.demos.base : DemoBase;

string vertexShaderSource = "#version 330 core
layout(location = 0) in vec4 pos;
layout(location = 1) in vec3 color;

uniform mat4 u_transform;
uniform int is_line;

out vec3 Color;

void main(){
    if (is_line == 0) {
        Color = color;
    } else {
        Color = vec3(1, 1, 1);
    }
    gl_Position = pos * u_transform;
}
";

string fragmentShaderSource = "#version 330 core
out vec3 color;
in vec3 Color;

void main()
{
    color = Color;
}
";

class Demo : DemoBase {
    private {
        int width, height;
        string programName;

        GLFWwindow *window;

        GLint program;

        GLuint vertexArray;
        GLuint vertexBuffer;
        GLuint cubeElements;
        GLuint lineElements;
        GLint transformMatrix;
        GLint isLine;

        double startTime = 0;
        double timeDiff = 0;

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

        GLuint loadShader(GLenum type, string source) {
            GLint compileStatus;

            GLuint shader = glCreateShader(type);
            immutable(char) *sourcePtr = source.ptr;
            GLint length = cast(GLint) source.length;
            glShaderSource(shader, 1, &sourcePtr, &length);

            glCompileShader(shader);
            glGetShaderiv(shader, GL_COMPILE_STATUS, &compileStatus);
            if (!compileStatus) {
                GLchar compileLog[1024];
                glGetShaderInfoLog(shader, cast(int)compileLog.sizeof, null,
                    compileLog.ptr);
                writefln("Error compiling shader type %d: %s", type,
                    compileLog);
                throw new Error("Shader compilation failure");
            }
            return shader;
        }

        void programInit() {
            GLint linkStatus;

            program = glCreateProgram();

            GLint vs = loadShader(GL_VERTEX_SHADER, vertexShaderSource);
            glAttachShader(program, vs);
            GLint fs = loadShader(GL_FRAGMENT_SHADER, fragmentShaderSource);
            glAttachShader(program, fs);
            glDeleteShader(fs);
            glDeleteShader(vs);

            glLinkProgram(program);
            glGetProgramiv(program, GL_LINK_STATUS, &linkStatus);

            if (!linkStatus) {
                GLchar linkerLog[1024];
                glGetProgramInfoLog(program, cast(int)linkerLog.sizeof, null,
                    linkerLog.ptr);
                writefln("Error linking program: %s", linkerLog);
                throw new Error("Program linker failure");
            }

            string transformMatrixName = "u_transform";
            transformMatrix = glGetUniformLocation(program, transformMatrixName.ptr);
            if (transformMatrix == -1) {
                writefln("Could not bind uniform %s", transformMatrixName);
                throw new Error("Uniform bind failure");
            }

            string isLineName = "is_line";
            isLine = glGetUniformLocation(program, isLineName.ptr);
            if (isLine == -1) {
                writefln("Could not bind uniform %s", isLineName);
                throw new Error("Uniform bind failure");
            }
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

        void display() {
            if (!startTime) {
                startTime = glfwGetTime();
            }
            timeDiff = glfwGetTime() - startTime;

            glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);

            // Enable all the things
            glUseProgram(program);
            glBindVertexArray(vertexArray);
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
                    .translate(translation[0], translation[1], translation[2])
                    ;
                glUniformMatrix4fv(transformMatrix, 1, GL_FALSE, matrix.value_ptr);
                glUniform1i(isLine, 0);

                // What to draw
                glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
                glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, cubeElements);
                // Layout of the stuff to draw
                glVertexAttribPointer(0, 4, GL_FLOAT, GL_FALSE, 7 * GLfloat.sizeof, cast(void*)(0 * GLfloat.sizeof));
                glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 7 * GLfloat.sizeof, cast(void*)(4 * GLfloat.sizeof));

                // Draw it!
                glDrawElements(GL_TRIANGLES, 36, GL_UNSIGNED_SHORT, cast(void *)0);

                glUniform1i(isLine, 1);
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
            glClearDepth(1f);
            glEnable(GL_DEPTH_TEST);
            glDepthFunc(GL_LESS);

            while (!glfwWindowShouldClose(window)) {
                display();
                glfwSwapBuffers(window);
                glfwPollEvents();
            }
        }
    }
}
