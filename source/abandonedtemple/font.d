module abandonedtemple.font;

private {
    import std.algorithm: max;
    import std.math: ceil, log2, pow;
    import std.range : iota;

    import derelict.freetype.ft;
    import derelict.opengl3.gl3;

    import abandonedtemple.glwrapper :
        VertexArray, ArrayBuffer, ElementArrayBuffer, Texture2D;
}

struct Glyph {
    ushort width; // pixel width
    ushort x; // pixel location in the texture

    float tex_x_left;
    float tex_x_right;
}

class Font {
    static this() {
        DerelictFT.load();
    }

    private {
        Glyph[char] glyphs;
        Texture2D texture;
    }

    this(string fontfile, int font_size, string chars_) {
        string chars = chars_ ~ '\xFF';

        FT_Library library;
        if (FT_Init_FreeType(&library) != 0) {
            throw new Exception("Could not initialize FreeType2 library.");
        }

        FT_Face face;
        if (FT_New_Face(library, fontfile.ptr, 0, &face) != 0) {
            throw new Exception("Could not load font file.");
        }

        if (!(face.face_flags & FT_FACE_FLAG_SCALABLE) ||
            !(face.face_flags & FT_FACE_FLAG_HORIZONTAL)) {
            throw new Exception("Not a scalable/true type font.");
        }

        FT_Set_Pixel_Sizes(face, font_size, 0);

        uint[char] char_indices;
        uint maxAscent;

        int data_height = font_size + 4;
        ushort texture_width = 2;
        foreach(char c; chars) {
            uint char_index = FT_Get_Char_Index(face, cast(uint)c);
            if (c == '\xFF') {
                  char_index = 0;
            }
            char_indices[c] = char_index;

            FT_Load_Glyph(face, char_index, FT_LOAD_DEFAULT);
            FT_Render_Glyph(face.glyph, FT_RENDER_MODE_NORMAL);

            ushort width = cast(ushort)face.glyph.metrics.horiAdvance >> 6;

            Glyph g;
            g.width = width;
            g.x = texture_width;
            glyphs[c] = g;

            texture_width += width + 2;
            maxAscent = max(maxAscent, face.glyph.bitmap_top);
        }

        // Width needs to be a power of two
        texture_width = cast(ushort)pow(2, ceil(log2(texture_width)));

        ubyte data[];
        data.length = data_height * texture_width;

        foreach(char c; chars) {
            Glyph *g = &glyphs[c];
            g.tex_x_left = cast(float)g.x / texture_width;
            g.tex_x_right = cast(float)(g.x + g.width) / texture_width;
            uint char_index = char_indices[c];
            FT_Load_Glyph(face, char_index, FT_LOAD_DEFAULT);
            FT_Render_Glyph(face.glyph, FT_RENDER_MODE_NORMAL);

            size_t height = face.glyph.metrics.vertAdvance >> 6;


            uint y = (maxAscent - face.glyph.bitmap_top) + 2;
            foreach (int row; iota(face.glyph.bitmap.rows)) {
                auto row_start = row * face.glyph.bitmap.pitch;
                auto row_end = (row+1) * face.glyph.bitmap.pitch;
                auto row_data = face.glyph.bitmap.buffer[row_start .. row_end];

                auto data_start = g.x + ((y+row) * texture_width);
                auto data_end = data_start + row_data.length;
                data[data_start .. data_end] = row_data;
            }
        }

        FT_Done_FreeType(library);

        glActiveTexture(GL_TEXTURE0);
        texture = new Texture2D();
        texture.bind();
        texture.setData(cast(char *)(data.ptr), texture_width, data_height, GL_R8, GL_RED);
    }

    void bind() {
        texture.bind();
    }

    Glyph getGlyph(char c) {
        if (c in glyphs) {
            return glyphs[c];
        } else {
            return glyphs['\xFF'];
        }
    }
}

