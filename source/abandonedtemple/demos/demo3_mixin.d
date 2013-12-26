module abandonedtemple.demos.demo3_mixin;

mixin template DemoMixin() {
    private {
        int width, height;
        string programName;

        GLFWwindow *window;

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
    }

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

        init();

        while (!glfwWindowShouldClose(window)) {
            if (!startTime) {
                startTime = glfwGetTime();
            }
            timeDiff = glfwGetTime() - startTime;
            glfwGetFramebufferSize(window, &width, &height);
            display();
            glfwSwapBuffers(window);
            glfwPollEvents();
        }
    }
}
