module abandonedtemple.demos.demo3;

import std.math : sin;
import std.stdio : writefln;

import derelict.glfw3.glfw3;
import derelict.opengl3.gl3;
import derelict.stb_image.stb_image;
import derelict.assimp3.assimp;

import gl3n.linalg;

import abandonedtemple.demos.base : DemoBase;
import abandonedtemple.demos.demo3_program : program_from_shader_filenames;
import abandonedtemple.demos.demo3_glwrapper :
    VertexArray, ArrayBuffer, ElementArrayBuffer, Texture2D;
import abandonedtemple.demos.demo3_mixin : DemoMixin;
import abandonedtemple.demos.demo3_assets : describeScene, importFile, Asset;

mixin(program_from_shader_filenames("_AssetProgram", ["demo3/Asset.frag","demo3/Asset.vert"]));

enum UniformBindings : uint {
    material = 1,
}

class AssetProgram {
    _AssetProgram assetProgram;
    alias assetProgram this;

    this() {
        assetProgram = new _AssetProgram();
        uint materialBlock = glGetUniformBlockIndex(location, "Material");
        glUniformBlockBinding(location, materialBlock, UniformBindings.material);
    }
}

class AssetDrawer {
    AssetProgram program;
    Asset asset;

    vec4 offset;
    vec3 rotation;
    vec3 rotation_rate;
    vec3 scale;

    this(AssetProgram program_, string filename) {
        program = program_;

        auto scene = importFile(filename);
        //describeScene(scene);
        asset = new Asset(scene, UniformBindings.material);
        scale = vec3(0.5);
        offset = vec4(0, 0, -2.5, 0);
        rotation = vec3(0);
        rotation_rate = vec4(1);
    }

    void draw(double timeDiff) {
        auto matrix = mat4.identity
            .rotatez(timeDiff * rotation_rate.z)
            .rotatey(timeDiff * rotation_rate.y)
            .rotatex(timeDiff * rotation_rate.x)
            .rotatex(rotation.x)
            .rotatey(rotation.y)
            .rotatez(rotation.z)
            .scale(scale.x, scale.y, scale.z);
        program.uniforms.u_transform = matrix;
        program.uniforms.u_offset = offset;

        program.use();
        asset.draw();
    }
}

class Demo : DemoBase {
    mixin DemoMixin;
    private {
        AssetDrawer assetDrawers[];

        AssetProgram assetProgram;

        mat4 frustumMatrix;

        void bufferInit() {
            AssetDrawer a;

            a  = new AssetDrawer(assetProgram, "dice.obj");
            a.offset = vec4(-2.25, 0, -4, 0);
            a.rotation_rate = vec3(2, 0.5, 0);
            a.scale = vec3(1);
            assetDrawers ~= a;

            a  = new AssetDrawer(assetProgram, "golem.obj");
            a.offset = vec4(2.25, 1, -4, 0);
            a.scale = vec3(0.4);
            a.rotation_rate = vec3(0, 1.25, 0);
            assetDrawers ~= a;
        }

        mat4 calculateFrustum(float scale, float aspect, float near, float far) {
            mat4 ret = mat4(0);
            ret[0][0] = scale / aspect;
            ret[1][1] = scale;
            ret[2][2] = (far+near)/(far-near);
            ret[2][3] = -1f;
            ret[3][2] = (2 * far * near)/(far-near);
            return ret;
        }

        void updateFrustum() {
            auto aspect = cast(float)width / height;
            frustumMatrix = mat4.identity * calculateFrustum(1f, aspect, 0.5f, 100f);
        }

        void drawAsset() {
            assetProgram.use();
            assetProgram.uniforms.u_frustum.setTranspose(true);
            assetProgram.uniforms.u_frustum = frustumMatrix;

            foreach(AssetDrawer assetDrawer; assetDrawers) {
                assetDrawer.draw(timeDiff);
            }
        }

        void display() {
            updateFrustum();

            glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);

            drawAsset();
        }

        void init() {
            DerelictStb_image.load();
            DerelictASSIMP3.load();
            assetProgram = new AssetProgram();
            glClearColor(0.0f, 0.0f, 0.3f, 0.0f);

            bufferInit();

            glEnable(GL_DEPTH_TEST);
            glDepthMask(GL_TRUE);
            glDepthFunc(GL_GREATER);
            glClearDepth(-1f);

            glEnable(GL_TEXTURE_2D);

            glEnable(GL_LINE_SMOOTH);
            glLineWidth(10);
        }
    }
}
