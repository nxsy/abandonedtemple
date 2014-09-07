module abandonedtemple.callbacks;

alias KeyCallback = void delegate (int key, int scancode, int action, int mods);
alias FpsCallback = void delegate (float fps);
alias WindowSizeCallback = void delegate (int width, int height);
alias PostPollCallback = void delegate ();
alias MouseButtonCallback = void delegate (int button, int action, int mods);
alias MouseMoveCallback = void delegate (double xpos, double ypos);
alias MouseScrollCallback = void delegate (double xoffset, double yoffset);
alias TimeCallback = void delegate (double time);

struct Callbacks
{
    KeyCallback keyCallbacks[];
    FpsCallback fpsCallbacks[];
    WindowSizeCallback dimensionCallbacks[];
    PostPollCallback postPollCallbacks[];
    MouseButtonCallback mouseButtonCallbacks[];
    MouseMoveCallback mouseCursorCallbacks[];
    MouseScrollCallback scrollCallbacks[];
    TimeCallback timeCallbacks[];
}

interface HasCallbacks {
    ref Callbacks getCallbacks();
}