module abandonedtemple.demos.demo3;

import std.math : PI, sin;
import std.stdio : writefln;

import derelict.glfw3.glfw3;
import derelict.opengl3.gl3;

import gl3n.linalg;
import gl3n.math;

import abandonedtemple.glwrapper :
    VertexArray, ArrayBuffer, ElementArrayBuffer, Texture2D,
    UniformBuffer, UniformBufferData;
import abandonedtemple.font : Font, Glyph, FontDrawer;

import abandonedtemple.demos.base : DemoBase;
import abandonedtemple.demos.demo3_program : program_from_shader_filenames;
import abandonedtemple.demos.demo3_mixin : DemoMixin;
import abandonedtemple.demos.demo3_assets : describeScene, importFile, Asset;
import abandonedtemple.demos.demo3_camera : ICamera, Camera, CityCamera, Direction;
import abandonedtemple.callbacks;

mixin(program_from_shader_filenames("_AssetProgram", ["Asset.frag","Asset.vert"]));
mixin(program_from_shader_filenames("FontProgram", ["Font.frag","Font.vert"]));

enum UniformBindings : uint {
    material = 1,
    wvp = 2,
    global_lighting = 3,
}

struct WVP {
    mat4 world;
    mat4 view;
    mat4 projection;
    mat4 wvp;
    mat4 wv;
}

struct GlobalLighting {
    vec4 color;
    vec4 direction;
    float diffuse;
    float ambient;
}

class AssetProgram {
    _AssetProgram assetProgram;
    alias assetProgram this;

    this() {
        assetProgram = new _AssetProgram();
        assetProgram.use();
        assetProgram.uniforms.bumpTex = 1;
        {
            uint index = glGetUniformBlockIndex(location, "Material");
            glUniformBlockBinding(location, index, UniformBindings.material);
        }
        {
            uint index = glGetUniformBlockIndex(location, "WVP");
            glUniformBlockBinding(location, index, UniformBindings.wvp);
        }
        {
            uint index = glGetUniformBlockIndex(location, "GlobalLighting");
            glUniformBlockBinding(location, index, UniformBindings.global_lighting);
        }
    }
}

class FpsDrawer(P) : FontDrawer!P {
    this(P program_, int fontSize_) {
        super(program_, fontSize_, " 0123456789.fps");
        rightMargin = 150;
    }

    void updateFps(float fps_) {
        displayString = format("%0.2f fps", fps_);
        update();
    }
}

class TimeDrawer(P) : FontDrawer!P {
    this(P program_, int fontSize_) {
        super(program_, fontSize_, " 0123456789.second");
    }

    override void draw(double timeDiff) {
        displayString = format("%0.2f", timeDiff);
        update();
        FontDrawer!P.draw(timeDiff);
    }
}

class ModeDrawer(P) : FontDrawer!P {
    DirectionKeyMode mode;
    this(P program_, int fontSize_) {
        super(program_, fontSize_, "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ.");
        rightMargin = 300;
    }

    void updateMode(DirectionKeyMode mode_) {
        mode = mode_;
        final switch(mode) {
        case DirectionKeyMode.offset:
            displayString = "offset";
            break;
        case DirectionKeyMode.rotation:
            displayString = "rotate";
            break;
        case DirectionKeyMode.zoom:
            displayString = "zoom";
            break;
        }
        update();
    }
}

class MouseStatusDrawer(P) : FontDrawer!P {
    this(P program_, int fontSize_) {
        super(program_, fontSize_, "0123456789-,. ");
        rightMargin = 300;
        //bottomMargin = 1;
    }
    void updateMousePosition(double xpos, double ypos) {
        displayString = format("%0d, %0d", cast(int)xpos,cast(int)ypos);
        update();
    }
    override void draw(double timeDiff) {
        FontDrawer!P.draw(timeDiff);
    }
}

class AssetDrawer {
    AssetProgram program;
    Asset asset;

    vec3 offset;
    vec3 rotation;
    vec3 rotation_rate;
    vec3 scale;
    static UniformBuffer matrixBuffer;
    static UniformBuffer lightingBuffer;

    float diffuse;
    float ambient;

    static bool normal_mapping = true;
    static DebugViewMode debugMode;

    this(AssetProgram program_, string filename) {
        auto scene = importFile(filename);
        Asset asset_ = new Asset(scene, UniformBindings.material);
        this(program_, asset_);
    }

    static bool init = false;
    private void _init() {
        matrixBuffer = new UniformBuffer();
        lightingBuffer = new UniformBuffer();
        init = true;
    }

    this(AssetProgram program_, Asset asset_) {
        if (!init) {
            _init();
        }

        asset = asset_;
        program = program_;

        scale = vec3(0.5);
        offset = vec3(0, 0, -2.5);
        rotation = vec3(0);
        rotation_rate = vec3(0);

        diffuse = 0.75f;
        ambient = 0.25f;
    }

    void setWVP(mat4 world, mat4 view, mat4 projection) {
        world = world.transposed;
        view = view.transposed;

        /*
        world = mat4.identity;
        view = mat4.identity;
        projection = mat4.identity;
        */

        WVP wvp;
        wvp.world = world;
        wvp.view = view;
        wvp.projection = projection;
        wvp.wvp = world * view * projection;
        wvp.wv = world * view;

        ubyte data[] = UniformBufferData!WVP.getData(wvp);
        matrixBuffer.setData(data, GL_STATIC_DRAW);
        matrixBuffer.bindBase(UniformBindings.wvp);
    }

    void setGlobalLighting() {
        GlobalLighting g;
        g.color = vec4(1,1,1,1);
        g.direction = vec4(
            vec3(-0.5,-0.5,1).normalized,
            1);
        g.diffuse = diffuse;
        g.ambient = ambient;

        ubyte data[] = UniformBufferData!GlobalLighting.getData(g);
        lightingBuffer.setData(data, GL_STATIC_DRAW);
        lightingBuffer.bindBase(UniformBindings.global_lighting);
    }

    void draw(double timeDiff, mat4 view, mat4 projection) {
        auto world = mat4.identity
            .scale(scale.x, scale.y, scale.z)
            .rotatez(timeDiff * rotation_rate.z)
            .rotatey(timeDiff * rotation_rate.y)
            .rotatex(timeDiff * rotation_rate.x)
            .rotatex(rotation.x)
            .rotatey(rotation.y)
            .rotatez(rotation.z)
            .translate(offset.x, offset.y, offset.z)
            ;

        setWVP(world, view, projection);
        setGlobalLighting();

        program.use();
        program.uniforms.normal_mapping = normal_mapping ? 1 : 0;

        program.uniforms.show_diffuse_factor = debugMode == DebugViewMode.diffuse_factor ? 1 : 0;
        program.uniforms.show_bump_map = debugMode == DebugViewMode.show_bump_map ? 1 : 0;
        program.uniforms.show_bump_map_raw = debugMode == DebugViewMode.show_bump_map_raw ? 1 : 0;
        asset.draw();
    }
}

enum DirectionKeyMode {
    offset,
    rotation,
    zoom,
}

enum DebugViewMode {
    normal,
    diffuse_factor,
    show_bump_map,
    show_bump_map_raw,
}

class Demo : DemoBase, HasCallbacks {
    mixin DemoMixin;
    private {
        AssetDrawer assetDrawers[];
        FpsDrawer!FontProgram fpsDrawer;
        TimeDrawer!FontProgram timeDrawer;
        ModeDrawer!FontProgram modeDrawer;
        MouseStatusDrawer!FontProgram mouseStatusDrawer;

        AssetProgram assetProgram;
        FontProgram fontProgram;

        mat4 frustumMatrix;

        ICamera camera;

        void bufferInit() {
            AssetDrawer a;

            auto scene = importFile("brick.obj");
            //describeScene(scene);
            Asset cube_asset = new Asset(scene, UniformBindings.material);

            a  = new AssetDrawer(assetProgram, cube_asset);
            a.offset = vec3(0, 0, 0);
            a.scale = vec3(0.1);
            assetDrawers ~= a;

            a  = new AssetDrawer(assetProgram, cube_asset);
            a.offset = vec3(2, 0, 14.4);
            a.scale = vec3(0.3);
            assetDrawers ~= a;

            a  = new AssetDrawer(assetProgram, cube_asset);
            a.offset = vec3(2, 0, 12);
            a.scale = vec3(0.3);
            assetDrawers ~= a;

            a  = new AssetDrawer(assetProgram, cube_asset);
            a.offset = vec3(4.4, 0, 12);
            a.scale = vec3(0.3);
            assetDrawers ~= a;

            a  = new AssetDrawer(assetProgram, cube_asset);
            a.offset = vec3(6.8, 0, 9.6);
            a.scale = vec3(0.3);
            assetDrawers ~= a;

            a  = new AssetDrawer(assetProgram, cube_asset);
            a.offset = vec3(6.8, 0, 7.2);
            a.scale = vec3(0.3);
            assetDrawers ~= a;

            a  = new AssetDrawer(assetProgram, cube_asset);
            a.offset = vec3(-4.4, 0, 14.4);
            a.scale = vec3(0.3);
            assetDrawers ~= a;

            a  = new AssetDrawer(assetProgram, cube_asset);
            a.offset = vec3(-4.4, 0, 12);
            a.scale = vec3(0.3);
            assetDrawers ~= a;

            a  = new AssetDrawer(assetProgram, cube_asset);
            a.offset = vec3(-6.8, 0, 9.6);
            a.scale = vec3(0.3);
            assetDrawers ~= a;

            a  = new AssetDrawer(assetProgram, cube_asset);
            a.offset = vec3(-6.8, 0, 7.2);
            a.scale = vec3(0.3);
            assetDrawers ~= a;

            /* */
            a  = new AssetDrawer(assetProgram, "golem.obj");
            a.offset = vec3(-2.5, 0.5, 6);
            a.scale = vec3(0.20);
            //a.rotation_rate = vec3(0, 0.25, 0);
            a.rotation = vec3(0, PI - 0.5, 0);
            a.diffuse = 0.9f;
            a.ambient = 0.1f;
            assetDrawers ~= a;

            /*
            a  = new AssetDrawer(assetProgram, "chest.obj");
            a.offset = vec3(3.5, -1, 8);
            a.scale = vec3(0.02);
            //a.rotation_rate = vec3(0, 0.25, 0);
            a.rotation = vec3(0, 3.75, 0);
            a.diffuse = 0.9f;
            a.ambient = 0.1f;
            assetDrawers ~= a;

            /*
            a  = new AssetDrawer(assetProgram, "rocks_03.obj");
            a.offset = vec3(2.5, -1, 6);
            a.scale = vec3(0.02);
            //a.rotation_rate = vec3(0, 0.25, 0);
            a.rotation = vec3(0, 3.75, 0);
            a.diffuse = 0.9f;
            a.ambient = 0.1f;
            assetDrawers ~= a;
            /* */

            fpsDrawer = new FpsDrawer!FontProgram(fontProgram, 25);
            callbacks.fpsCallbacks ~= (float fps) { fpsDrawer.updateFps(fps); };
            callbacks.dimensionCallbacks ~= (int width, int height) { fpsDrawer.updateDimensions(width, height); };

            timeDrawer = new TimeDrawer!FontProgram(fontProgram, 25);
            callbacks.dimensionCallbacks ~= (int width, int height) { timeDrawer.updateDimensions(width, height); };

            modeDrawer = new ModeDrawer!FontProgram(fontProgram, 25);
            callbacks.dimensionCallbacks ~= (int width, int height) { modeDrawer.updateDimensions(width, height); };

            mouseStatusDrawer = new MouseStatusDrawer!FontProgram(fontProgram, 25);
            callbacks.dimensionCallbacks ~= (int width, int height) { mouseStatusDrawer.updateDimensions(width, height); };
            callbacks.mouseCursorCallbacks ~= (double xpos, double ypos) { mouseStatusDrawer.updateMousePosition(xpos, ypos); };
        }

        mat4 calculateFrustum(float scale, float aspect, float near, float far) {
            mat4 ret = mat4(0);
            ret[0][0] = scale / aspect;
            ret[1][1] = scale;
            ret[2][2] = (far+near)/(far-near);
            ret[2][3] = 1f;
            ret[3][2] = -(2 * far * near)/(far-near);
            return ret;
        }

        void updateFrustum(int width, int height) {
            auto aspect = cast(float)width / height;
            auto fov_degrees = 60;
            writefln("fov_degrees: %s", fov_degrees);
            auto fov_radians = radians(fov_degrees);
            auto scale = 1f / tan(fov_radians / 2f);
            writefln("scale: %s", scale);
            frustumMatrix = calculateFrustum(scale, aspect, 0.1f, 100f);
        }

        void drawAsset() {
            assetProgram.use();

            foreach(AssetDrawer assetDrawer; assetDrawers) {
                assetDrawer.draw(timeDiff, camera.viewMatrix, frustumMatrix);
            }
        }

        void drawFps() {
            fpsDrawer.draw(timeDiff);
        }

        void drawTime() {
            timeDrawer.draw(timeDiff);
        }

        void drawMode() {
            modeDrawer.updateMode(mode);
            modeDrawer.draw(timeDiff);
        }

        void display() {
            glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);

            drawAsset();
            drawFps();
            drawTime();
            //drawMode();

            mouseStatusDrawer.draw(timeDiff);
        }

        void updateCamera() {
            camera.update(timeDiff);
        }

        void init() {
            assetProgram = new AssetProgram();
            fontProgram = new FontProgram();
            camera = new CityCamera();

            callbacks.dimensionCallbacks ~= (int width, int height) { updateFrustum(width, height); };
            callbacks.mouseCursorCallbacks ~= (double xpos, double ypos) { updateRotation(xpos, ypos); };
            callbacks.scrollCallbacks ~= (double xoffset, double yoffset) { updateScroll(xoffset, yoffset); };
            callbacks.postPollCallbacks ~= () { updateCamera(); };
            callbacks.keyCallbacks ~= (int key, int scancode, int action, int mods) { keyCallback(key, scancode, action, mods); };

            glClearColor(0.0f, 0.0f, 0.3f, 0.0f);

            bufferInit();

            glEnable(GL_DEPTH_TEST);
            glDepthMask(GL_TRUE);
            glDepthFunc(GL_LEQUAL);
            glClearDepth(1f);

            glEnable(GL_TEXTURE_2D);

            camera.update(timeDiff);
        }


    }

    double lastXpos, lastYpos;
    void updateRotation(double xpos, double ypos) {
        if (isNaN(lastXpos)) {
            lastXpos = xpos;
            lastYpos = ypos;
            return;
        }

        CityCamera c = cast(CityCamera)camera;
        auto ydiff = lastYpos - ypos;
        auto xdiff = lastXpos - xpos;
        if (abs(ydiff) < abs(xdiff) / 2) {
            ydiff = 0;
        } else if (abs(xdiff) < abs(ydiff) / 2) {
            xdiff = 0;
        }
        c.updateRotation(ydiff / 4, xdiff / 4);
        lastXpos = xpos;
        lastYpos = ypos;
    }

    void updateScroll(double xoffset, double yoffset) {
        CityCamera c = cast(CityCamera)camera;
        c.updateDistance(yoffset);
    }


    DirectionKeyMode mode;
    DebugViewMode debugMode;

    void keyCallback(int key, int scancode, int action, int mods) {
        if (action == GLFW_PRESS || action == GLFW_REPEAT) {
            if (key == GLFW_KEY_ESCAPE || key == GLFW_KEY_Q) {
                glfwSetWindowShouldClose(window, 1);
            }

            if (mods == 4) {
                if (key == GLFW_KEY_M) {
                    mode++;
                    mode %= DirectionKeyMode.max + 1;
                }

                if (key == GLFW_KEY_D) {
                    debugMode++;
                    debugMode %= DebugViewMode.max + 1;
                    AssetDrawer.debugMode = debugMode;
                }

                if (key == GLFW_KEY_N) {
                    AssetDrawer.normal_mapping = !AssetDrawer.normal_mapping;
                }

                if (key == GLFW_KEY_C) {
                    camera.reset();
                }
                return;
            }
        }

        if (action == GLFW_PRESS) {
            if (key == GLFW_KEY_A) { camera.keyPressed(Direction.LEFT); }
            if (key == GLFW_KEY_D) { camera.keyPressed(Direction.RIGHT); }
            if (key == GLFW_KEY_S) { camera.keyPressed(Direction.DOWN); }
            if (key == GLFW_KEY_W) { camera.keyPressed(Direction.UP); }
        }
        if (action == GLFW_RELEASE) {
            if (key == GLFW_KEY_A) { camera.keyUnpressed(Direction.LEFT); }
            if (key == GLFW_KEY_D) { camera.keyUnpressed(Direction.RIGHT); }
            if (key == GLFW_KEY_S) { camera.keyUnpressed(Direction.DOWN); }
            if (key == GLFW_KEY_W) { camera.keyUnpressed(Direction.UP); }
        }
    }
}
