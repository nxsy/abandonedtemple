module abandonedtemple.demos.demo3_mixin;

mixin template DemoMixin() {
    private {
        int width, height;
        string programName;

        GLFWwindow *window;

        double startTime = 0;
        double frameStart = 0;
        double timeDiff = 0;

        int frames;
        double lastTime = 0;
        float fps;

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

    void delegate (float fps) fpsCallbacks[];
    void delegate (int width, int height) dimensionCallbacks[];

    void updateFps() {
        if (!lastTime) {
            lastTime = frameStart;
        }
        if (frameStart > (lastTime + 1)) {
            fps = frames / (frameStart - lastTime);
            // writefln("FPS: %f", fps);
            lastTime = frameStart;
            frames = 0;
            foreach (void delegate(float fps) cb; fpsCallbacks) {
                cb(fps);
            }
        }
        frames++;
    }

    void run() {
        glInit();

        init();

        foreach (void delegate(int width, int height) cb; dimensionCallbacks) {
            cb(width, height);
        }

        while (!glfwWindowShouldClose(window)) {
            frameStart = glfwGetTime();
            if (!startTime) {
                startTime = frameStart;
            }
            updateFps();
            timeDiff = glfwGetTime() - startTime;
            int old_width = width, old_height = height;
            glfwGetFramebufferSize(window, &width, &height);
            if (width != old_width || height != old_height) {
                foreach (void delegate(int width, int height) cb; dimensionCallbacks) {
                    cb(width, height);
                }
            }

            display();
            glfwSwapBuffers(window);
            glfwPollEvents();
        }
    }
}
