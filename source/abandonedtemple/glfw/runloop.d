module abandonedtemple.glfw.runloop;

import derelict.glfw3.glfw3;
import derelict.opengl3.gl3;
version (Windows) {
    import derelict.opengl3.wglext;
}
import abandonedtemple.glfw.callbacks;
import abandonedtemple.callbacks;
import std.stdio;

struct GlfwWindowCreateParams {
    int width;
    int height;
    string programName;
}

class GlfwRunLoop {
    this(GlfwWindowCreateParams windowCreateParams_, HasCallbacks hc_, void delegate(GLFWwindow *) initFunc_, void delegate() displayFunc_) {
        windowCreateParams = windowCreateParams_;
        hc = hc_;
        initFunc = initFunc_;
        displayFunc = displayFunc_;
    }

    void run() {
        init();
        initFunc(window);

        int width = windowCreateParams.width,
            height = windowCreateParams.height;

        foreach (WindowSizeCallback cb; hc.getCallbacks().dimensionCallbacks) {
            cb(width, height);
        }

        while (!glfwWindowShouldClose(window)) {
            auto t = glfwGetTime();

            foreach (TimeCallback cb; hc.getCallbacks().timeCallbacks) {
                cb(t);
            }

            int old_width = width, old_height = height;
            glfwGetFramebufferSize(window, &width, &height);
            if (width != old_width || height != old_height) {
                glViewport(0, 0, width, height);
                foreach (WindowSizeCallback cb; hc.getCallbacks().dimensionCallbacks) {
                    cb(width, height);
                }
            }

            displayFunc();

            glfwSwapBuffers(window);
            glfwPollEvents();

            foreach (PostPollCallback cb; hc.getCallbacks().postPollCallbacks) {
                cb();
            }
        }
    }

    void shouldStop() {
        glfwSetWindowShouldClose(window, 1);
    }

private:
    void init() {
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
        
        window = glfwCreateWindow(windowCreateParams.width, windowCreateParams.height, windowCreateParams.programName.ptr, null,
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
        setCallbacks(window, hc);
    }

    HasCallbacks hc;
    GLFWwindow *window;
    void delegate(GLFWwindow *) initFunc;
    void delegate() displayFunc;
    GlfwWindowCreateParams windowCreateParams;
}