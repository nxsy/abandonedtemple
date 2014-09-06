module abandonedtemple.callbacks;

alias FpsCallback = void delegate (float fps);
alias WindowSizeCallback = void delegate (int width, int height);
alias PostPollCallback = void delegate ();
alias MouseButtonCallback = void delegate (int button, int action, int mods);
alias MouseMoveCallback = void delegate (double xpos, double ypos);
alias MouseScrollCallback = void delegate (double xoffset, double yoffset);

struct Callbacks
{
    FpsCallback fpsCallbacks[];
    WindowSizeCallback dimensionCallbacks[];
    PostPollCallback postPollCallbacks[];
    MouseButtonCallback mouseButtonCallbacks[];
    MouseMoveCallback mouseCursorCallbacks[];
    MouseScrollCallback scrollCallbacks[];
}
