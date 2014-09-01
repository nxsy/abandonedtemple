module abandonedtemple.demos.base;

import derelict.glfw3.glfw3;

interface DemoBase {
    void run();
}

interface DemoCallbacksBase {
    void keyCallback(GLFWwindow *window, int key, int scancode, int action, int mods);
    void cursorPosCallback(GLFWwindow *window, double xpos, double ypos);
}
