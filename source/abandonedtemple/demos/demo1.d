module abandonedtemple.demos.demo1;

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
        GLuint tetrahedronElements;
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

            const GLfloat triangleVertices[] = [
                -1f, -1f,  0f, 1f,   1f,  0f, 0f,
                 1f, -1f,  0f, 1f,   0f,  1f, 0f,
                 0f,  1f,  0f, 1f,   0f,  0f, 1f,
                 0f,  0f, -1f, 1f,   1f,  1f, 0f,
            ];
            GLushort tetrahedron_elements[] = [
                0, 1, 2,
                0, 1, 3,
                0, 2, 3,
                1, 2, 3,
            ];

            GLushort line_elements[] = [
                0, 1,
                0, 2,
                1, 2,
                0, 3,
                2, 3,
                1, 3,
            ];

            glGenBuffers(1, &vertexBuffer);
            glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
            glBufferData(GL_ARRAY_BUFFER,
                triangleVertices.length * GLfloat.sizeof,
                triangleVertices.ptr,
                GL_STATIC_DRAW);

            glGenBuffers(1, &tetrahedronElements);
            glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, tetrahedronElements);
            glBufferData(GL_ELEMENT_ARRAY_BUFFER, tetrahedron_elements.length * GLushort.sizeof, tetrahedron_elements.ptr, GL_STATIC_DRAW);

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

            auto matrix = mat4.identity
                .rotatey(timeDiff)
                .rotatex(timeDiff / PI)
                .scale(0.7, 0.7, 0.7);
            glUniformMatrix4fv(transformMatrix, 1, GL_FALSE, matrix.value_ptr);
            glUniform1i(isLine, 0);

            // What to draw
            glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
            glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, tetrahedronElements);
            // Layout of the stuff to draw
            glVertexAttribPointer(0, 4, GL_FLOAT, GL_FALSE, 7 * GLfloat.sizeof, cast(void*)(0 * GLfloat.sizeof));
            glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 7 * GLfloat.sizeof, cast(void*)(4 * GLfloat.sizeof));

            // Draw it!
            glDrawElements(GL_TRIANGLES, 12, GL_UNSIGNED_SHORT, cast(void *)0);

            glUniform1i(isLine, 1);
            glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, lineElements);

            glDrawElements(GL_LINES, 12, GL_UNSIGNED_SHORT, cast(void *)0);

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
            this(640, 480, this.toString());
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
