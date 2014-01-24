module abandonedtemple.demos.demo3;

import std.math : sin;
import std.stdio : writefln;

import derelict.glfw3.glfw3;
import derelict.opengl3.gl3;

import gl3n.linalg;

import abandonedtemple.glwrapper :
    VertexArray, ArrayBuffer, ElementArrayBuffer, Texture2D;
import abandonedtemple.font : Font, Glyph;

import abandonedtemple.demos.base : DemoBase;
import abandonedtemple.demos.demo3_program : program_from_shader_filenames;
import abandonedtemple.demos.demo3_mixin : DemoMixin;
import abandonedtemple.demos.demo3_assets : describeScene, importFile, Asset;

mixin(program_from_shader_filenames("_AssetProgram", ["demo3/Asset.frag","demo3/Asset.vert"]));
mixin(program_from_shader_filenames("FontProgram", ["demo3/Font.frag","demo3/Font.vert"]));

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

class FontDrawer {
    private {
        Font font;

        FontProgram program;

        VertexArray va;
        ArrayBuffer vertices;
        ElementArrayBuffer elements;

        int fontSize;

        /// screen pixel dimensions
        int width;
        int height;

        // ratio from pixels to opengl coordinates
        float widthRatio;
        float heightRatio;

        // Number of vertices needed to print word
        uint num_vertices;

        /// pixel margin from the right/bottom of the screen
        int rightMargin = 10;
        int bottomMargin = 10;

        /// string to display
        string displayString;
    }

    this(FontProgram program_, int fontSize_, string alphabet) {
        program = program_;
        fontSize = fontSize_;
        font = new Font("geo_1.ttf", fontSize, alphabet);

        vertices = new ArrayBuffer();
        vertices.bind();

        va = new VertexArray();
    }

    void draw(double timeDiff) {
        program.use();
        va.bind();
        vertices.bind();
        font.bind();
        program.uniforms.tex = 0;

        glEnableVertexAttribArray(0);
        glEnableVertexAttribArray(1);
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        glDrawArrays(GL_TRIANGLES, 0, num_vertices);
        glDisableVertexAttribArray(1);
        glDisableVertexAttribArray(0);
    }

    void update() {
        int pixelWidth = 0;

        Glyph glyphs[];
        foreach (char c; displayString) {
            Glyph g = font.getGlyph(c);
            glyphs ~= g;
            pixelWidth += g.width;
        }

        int scale = 1;

        float glLeft = 1.0 - (scale * widthRatio * (pixelWidth + rightMargin));
        float glBottom = -1.0 + (scale * heightRatio * (fontSize + bottomMargin));
        float glTop = -1.0 + (scale * heightRatio * bottomMargin);

        float vertices_[];

        foreach (Glyph g; glyphs) {
            float glRight = glLeft + (scale * widthRatio * g.width);
            float texture_left = g.tex_x_left;
            float texture_right = g.tex_x_right;

            vertices_ ~= [
                glLeft, glBottom, 0, texture_left, 0,
                glLeft, glTop, 0, texture_left, 1,
                glRight, glBottom, 0, texture_right, 0,

                glLeft, glTop, 0, texture_left, 1,
                glRight, glBottom, 0, texture_right, 0,
                glRight, glTop, 0, texture_right, 1,
            ];
            glLeft = glRight;
        }
        num_vertices = cast(uint)glyphs.length * 6;

        vertices.setData!(const float[])(vertices_, GL_STATIC_DRAW);

        va.bind();
        glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 5 * float.sizeof, cast(void*)(0 * float.sizeof));
        glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 5 * float.sizeof, cast(void*)(3 * float.sizeof));
        va.unbind();
    }

}

class FpsDrawer : FontDrawer {
    private {
        float fps = 0;
    }

    this(FontProgram program_, int fontSize_) {
        super(program_, fontSize_, " 0123456789.fps");
        rightMargin = 150;
    }

    void updateFps(float fps_) {
        fps = fps_;
        displayString = format("%0.2f fps", fps);
        update();
    }

    void updateDimensions(int width_, int height_) {
        width = width_;
        height = height_;

        widthRatio = 2.0 / width;
        heightRatio = 2.0 / height;

        if (fps) {
            update();
        }
    }

    override void draw(double timeDiff) {
        if (fps) {
            FontDrawer.draw(timeDiff);
        }
    }
}

class TimeDrawer : FontDrawer {
    this(FontProgram program_, int fontSize_) {
        super(program_, fontSize_, " 0123456789.second");
    }

    void updateDimensions(int width_, int height_) {
        width = width_;
        height = height_;

        widthRatio = 2.0 / width;
        heightRatio = 2.0 / height;

        if (displayString) {
            update();
        }
    }

    override void draw(double timeDiff) {
        displayString = format("%0.2f", timeDiff);
        update();
        FontDrawer.draw(timeDiff);
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
        FpsDrawer fpsDrawer;
        TimeDrawer timeDrawer;

        AssetProgram assetProgram;
        FontProgram fontProgram;

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

            fpsDrawer = new FpsDrawer(fontProgram, 25);
            fpsCallbacks ~= (float fps) { fpsDrawer.updateFps(fps); };
            dimensionCallbacks ~= (int width, int height) { fpsDrawer.updateDimensions(width, height); };

            timeDrawer = new TimeDrawer(fontProgram, 25);
            dimensionCallbacks ~= (int width, int height) { timeDrawer.updateDimensions(width, height); };
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

        void updateFrustum(int width, int height) {
            auto aspect = cast(float)width / height;
            frustumMatrix = calculateFrustum(1f, aspect, 0.5f, 100f);
        }

        void drawAsset() {
            assetProgram.use();
            assetProgram.uniforms.u_frustum.setTranspose(true);
            assetProgram.uniforms.u_frustum = frustumMatrix;

            foreach(AssetDrawer assetDrawer; assetDrawers) {
                assetDrawer.draw(timeDiff);
            }
        }

        void drawFps() {
            fpsDrawer.draw(timeDiff);
        }

        void drawTime() {
            timeDrawer.draw(timeDiff);
        }

        void display() {
            glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);

            drawAsset();
            drawFps();
            drawTime();
        }

        void init() {
            assetProgram = new AssetProgram();
            fontProgram = new FontProgram();

            dimensionCallbacks ~= (int width, int height) { updateFrustum(width, height); };

            glClearColor(0.0f, 0.0f, 0.3f, 0.0f);

            bufferInit();

            glEnable(GL_DEPTH_TEST);
            glDepthMask(GL_TRUE);
            glDepthFunc(GL_GREATER);
            glClearDepth(-1f);

            glEnable(GL_TEXTURE_2D);
        }
    }
}
