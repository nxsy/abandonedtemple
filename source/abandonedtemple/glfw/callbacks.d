module abandonedtemple.glfw.callbacks;
import derelict.glfw3.glfw3;
import std.stdio;
import abandonedtemple.callbacks;

void setCallbacks(GLFWwindow *window, HasCallbacks hascb) {
    glfwSetWindowUserPointer(window, cast(void *)hascb);
    glfwSetKeyCallback(window, &key_callback);

    glfwSetCursorPosCallback(window, &cursorpos_callback);
    glfwSetScrollCallback(window, &scroll_callback);
    glfwSetInputMode(window, GLFW_CURSOR, GLFW_CURSOR_DISABLED);
}

extern(C) static void key_callback(GLFWwindow* window, int key, int scancode, int action, int mods) nothrow {
    try {
        void *ptr = glfwGetWindowUserPointer(window);
        HasCallbacks c = cast(HasCallbacks)ptr;
        foreach (KeyCallback cb; c.getCallbacks().keyCallbacks) {
            cb(key, scancode, action, mods);
        }
    } catch (Exception e) {
        try {
            writefln("Exception caught: %s", e);
        } catch (Exception e) {
        }
    }
}

extern(C) static void cursorpos_callback(GLFWwindow* window, double xpos, double ypos) nothrow {
    try {
        void *ptr = glfwGetWindowUserPointer(window);
        HasCallbacks c = cast(HasCallbacks)ptr;
        foreach (MouseMoveCallback cb; c.getCallbacks().mouseCursorCallbacks) {
            cb(xpos, ypos);
        }
    } catch (Exception e) {
        try {
            writefln("Exception caught: %s", e);
        } catch (Exception e) {
        }
    }
}

extern(C) static void scroll_callback(GLFWwindow* window, double xoffset, double yoffset) nothrow {
    try {
        void *ptr = glfwGetWindowUserPointer(window);
        HasCallbacks c = cast(HasCallbacks)ptr;
        foreach (MouseScrollCallback cb; c.getCallbacks.scrollCallbacks) {
            cb(xoffset, yoffset);
        }
    } catch (Exception e) {
        try {
            writefln("Exception caught: %s", e);
        } catch (Exception e) {
        }
    }
}
