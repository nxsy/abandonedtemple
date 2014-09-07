module abandonedtemple.demos.demo3_mixin;
import abandonedtemple.glfw.callbacks;

mixin template DemoMixin() {
    version (Windows) {
        import derelict.opengl3.wglext : wglSwapIntervalEXT;
    }
    import abandonedtemple.callbacks;
    import abandonedtemple.glfw.callbacks;

    ref Callbacks getCallbacks() {
        return callbacks;
    }

    private {
        Callbacks callbacks;

        int width, height;
        string programName;

        GLFWwindow *window;

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

            version (Windows) {
                wglSwapIntervalEXT(1);
            }
            setCallbacks(window, this);
        }
    }

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

        init();

        foreach (WindowSizeCallback cb; callbacks.dimensionCallbacks) {
            cb(width, height);
        }

        while (!glfwWindowShouldClose(window)) {
            auto t = glfwGetTime();

            foreach (TimeCallback cb; callbacks.timeCallbacks) {
                cb(t);
            }


            int old_width = width, old_height = height;
            glfwGetFramebufferSize(window, &width, &height);
            if (width != old_width || height != old_height) {
                glViewport(0, 0, width, height);
                foreach (WindowSizeCallback cb; callbacks.dimensionCallbacks) {
                    cb(width, height);
                }
            }

            display();
            glfwSwapBuffers(window);
            glfwPollEvents();

            foreach (PostPollCallback cb; callbacks.postPollCallbacks) {
                cb();
            }
        }
    }
}
