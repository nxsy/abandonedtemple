module abandonedtemple.demos.demo3;

import std.math : sin;
import std.stdio : writefln;

import derelict.glfw3.glfw3;
import derelict.opengl3.gl3;

import gl3n.linalg;

import abandonedtemple.glwrapper :
    VertexArray, ArrayBuffer, ElementArrayBuffer, Texture2D,
    UniformBuffer, UniformBufferData;
import abandonedtemple.font : Font, Glyph, FontDrawer;

import abandonedtemple.demos.base : DemoBase, DemoCallbacksBase;
import abandonedtemple.demos.demo3_program : program_from_shader_filenames;
import abandonedtemple.demos.demo3_mixin : DemoMixin;
import abandonedtemple.demos.demo3_assets : describeScene, importFile, Asset;

mixin(program_from_shader_filenames("_AssetProgram", ["demo3/Asset.frag","demo3/Asset.vert"]));
mixin(program_from_shader_filenames("FontProgram", ["demo3/Font.frag","demo3/Font.vert"]));

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

class AssetDrawer {
    AssetProgram program;
    Asset asset;

    vec3 offset;
    vec3 rotation;
    vec3 rotation_rate;
    vec3 scale;
    UniformBuffer matrixBuffer;
    UniformBuffer lightingBuffer;

    float diffuse;
    float ambient;

    this(AssetProgram program_, string filename) {
        matrixBuffer = new UniformBuffer();
        lightingBuffer = new UniformBuffer();
        program = program_;

        auto scene = importFile(filename);
        //describeScene(scene);
        asset = new Asset(scene, UniformBindings.material);
        scale = vec3(0.5);
        offset = vec3(0, 0, -2.5);
        rotation = vec3(0);
        rotation_rate = vec4(1);

        diffuse = 0.85f;
        ambient = 0.15f;
    }

    void setWVP(mat4 world, mat4 view, mat4 projection) {
        world = world.transposed;
        view = view.transposed;

        WVP wvp;
        wvp.world = world;
        wvp.view = view;
        wvp.projection = projection;
        wvp.wvp = world * view * projection;

        ubyte data[] = UniformBufferData!WVP.getData(wvp);
        matrixBuffer.setData(data, GL_STATIC_DRAW);
        matrixBuffer.bindBase(UniformBindings.wvp);
    }

    void setGlobalLighting() {
        GlobalLighting g;
        g.color = vec4(1,0.8,0.8,1);
        g.direction = vec4(
            vec3(1,0,1).normalized,
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
        asset.draw();
    }
}

enum DirectionKeyMode {
    offset,
    rotation,
    zoom,
}


class Demo : DemoBase, DemoCallbacksBase {
    mixin DemoMixin;
    private {
        AssetDrawer assetDrawers[];
        FpsDrawer!FontProgram fpsDrawer;
        TimeDrawer!FontProgram timeDrawer;
        ModeDrawer!FontProgram modeDrawer;

        AssetProgram assetProgram;
        FontProgram fontProgram;

        mat4 frustumMatrix;
        mat4 camera;

        vec3 camera_offset = vec3(0f);
        vec3 camera_rotation = vec3(0f);

        void bufferInit() {
            AssetDrawer a;

            a  = new AssetDrawer(assetProgram, "golem.obj");
            a.offset = vec3(4.5, 2.5, 5);
            a.scale = vec3(0.8);
            a.rotation_rate = vec3(0, 1.25, 0);
            assetDrawers ~= a;

            a  = new AssetDrawer(assetProgram, "golem.obj");
            a.offset = vec3(-4.5, 2.5, 5);
            a.scale = vec3(0.8);
            a.rotation_rate = vec3(0, 1.25, 0);
            a.diffuse = 0f;
            a.ambient = 1f;
            assetDrawers ~= a;

            a  = new AssetDrawer(assetProgram, "golem.obj");
            a.offset = vec3(0, 2.5, 5);
            a.scale = vec3(0.8);
            a.rotation_rate = vec3(0, 1.25, 0);
            a.diffuse = 0.25f;
            a.ambient = 0.75f;
            assetDrawers ~= a;

            fpsDrawer = new FpsDrawer!FontProgram(fontProgram, 25);
            fpsCallbacks ~= (float fps) { fpsDrawer.updateFps(fps); };
            dimensionCallbacks ~= (int width, int height) { fpsDrawer.updateDimensions(width, height); };

            timeDrawer = new TimeDrawer!FontProgram(fontProgram, 25);
            dimensionCallbacks ~= (int width, int height) { timeDrawer.updateDimensions(width, height); };

            modeDrawer = new ModeDrawer!FontProgram(fontProgram, 25);
            dimensionCallbacks ~= (int width, int height) { modeDrawer.updateDimensions(width, height); };
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
            frustumMatrix = calculateFrustum(1f, aspect, 0.1f, 100f);
        }

        void drawAsset() {
            assetProgram.use();

            foreach(AssetDrawer assetDrawer; assetDrawers) {
                assetDrawer.draw(timeDiff, camera, frustumMatrix);
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
            drawMode();
        }

        void init() {
            assetProgram = new AssetProgram();
            fontProgram = new FontProgram();

            dimensionCallbacks ~= (int width, int height) { updateFrustum(width, height); };

            glClearColor(0.0f, 0.0f, 0.3f, 0.0f);

            bufferInit();

            glEnable(GL_DEPTH_TEST);
            glDepthMask(GL_TRUE);
            glDepthFunc(GL_LEQUAL);
            glClearDepth(1f);

            glEnable(GL_TEXTURE_2D);

            updateCamera();
        }

        void updateCamera() {
            camera = mat4.identity
                .translate(camera_offset.x, camera_offset.y, camera_offset.z)
                .rotatex(camera_rotation.x)
                .rotatey(camera_rotation.y)
                .rotatez(camera_rotation.z)
                ;
        }
    }

    DirectionKeyMode mode;

    void keyCallback(GLFWwindow *window, int key, int scancode, int action, int mods) {
        if (action == GLFW_PRESS || action == GLFW_REPEAT) {
            if (key == GLFW_KEY_ESCAPE || key == GLFW_KEY_Q) {
                glfwSetWindowShouldClose(window, 1);
            }

            if (key == GLFW_KEY_M) {
                mode++;
                mode %= DirectionKeyMode.max + 1;
            }

            if (key == GLFW_KEY_C) {
                camera_offset = vec3(0);
                camera_rotation = vec3(0);
            }

            if (mode == DirectionKeyMode.offset) {
                if (key == GLFW_KEY_RIGHT) { camera_offset.x += 0.1f; }
                if (key == GLFW_KEY_LEFT) { camera_offset.x -= 0.1f; }
                if (key == GLFW_KEY_UP) { camera_offset.y += 0.1f; }
                if (key == GLFW_KEY_DOWN) { camera_offset.y -= 0.1f; }
            }

            if (mode == DirectionKeyMode.rotation) {
                if (key == GLFW_KEY_RIGHT) { camera_rotation.y += 0.1f; }
                if (key == GLFW_KEY_LEFT) { camera_rotation.y -= 0.1f; }
                if (key == GLFW_KEY_UP) { camera_rotation.x += 0.1f; }
                if (key == GLFW_KEY_DOWN) { camera_rotation.x -= 0.1f; }
            }

            if (mode == DirectionKeyMode.zoom) {
                if (key == GLFW_KEY_UP) { camera_offset.z -= 0.1f; }
                if (key == GLFW_KEY_DOWN) { camera_offset.z += 0.1f; }
            }
        }

        updateCamera();
    }
}
