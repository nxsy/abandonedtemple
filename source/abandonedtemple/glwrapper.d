module abandonedtemple.glwrapper;

import std.range : ElementType;
import std.stdio : writefln;
import std.traits : isArray;

import derelict.opengl3.gl3:
    glGenBuffers,
    glGenTextures,
    glGenVertexArrays,
    glBindBuffer,
    glBindBufferBase,
    glBindTexture,
    glBindVertexArray,
    glBufferData,
    glDeleteBuffers,
    glDeleteVertexArrays,
    glGetIntegerv,
    glTexImage2D,
    glTexParameteri,
    GL_ARRAY_BUFFER,
    GL_CLAMP_TO_EDGE,
    GL_ELEMENT_ARRAY_BUFFER,
    GL_LINEAR,
    GL_RGB,
    GL_RGBA,
    GL_RGB8,
    GL_RGBA8,
    GL_TEXTURE_2D,
    GL_TEXTURE_MIN_FILTER,
    GL_TEXTURE_MAG_FILTER,
    GL_TEXTURE_WRAP_S,
    GL_TEXTURE_WRAP_T,
    GL_UNIFORM_BUFFER,
    GL_UNIFORM_BUFFER_OFFSET_ALIGNMENT,
    GL_UNSIGNED_BYTE
    ;

class VertexArray {
    private uint _location;
    this() {
        glGenVertexArrays(1, &_location);
    }

    ~this() {
        writefln("Destroying Vertex Array at location %d", _location);
        glDeleteVertexArrays(1, &_location);
    }

    void bind() {
        glBindVertexArray(_location);
    }

    void unbind() {
        glBindVertexArray(0);
    }
}

mixin template Buffer() {
    private uint _location;
    this() {
        glGenBuffers(1, &_location);
    }
    ~this() {
        writefln("Destroying buffer of type %s at location %d", _type, _location);
        glDeleteBuffers(1, &_location);
    }

    void bind() {
        glBindBuffer(_type, _location);
    }

    void unbind() {
        glBindBuffer(_type, 0);
    }

    void setData(T)(const auto ref T data, uint usage) if (isArray!T) {
        glBindBuffer(_type, _location);
        auto size = data.length * ElementType!T.sizeof;
        glBufferData(_type,
            size,
            data.ptr,
            usage);
    }
}

class ArrayBuffer {
    static uint _type = GL_ARRAY_BUFFER;
    mixin Buffer;
}

class ElementArrayBuffer {
    static uint _type = GL_ELEMENT_ARRAY_BUFFER;
    mixin Buffer;
}

class UniformBuffer {
    static uint _type = GL_UNIFORM_BUFFER;
    mixin Buffer;

    void bindBase(int binding) {
        glBindBufferBase(GL_UNIFORM_BUFFER, binding, _location);
    }
}

/**
 * Converts an object (including array of objects) into byte representation
 * with individual objects starting on multiples of
 * GL_UNIFORM_BUFFER_OFFSET_ALIGNMENT.
 */
template UniformBufferData(T) {
    ubyte[] getData(T[] ms) {
        writefln("getData(T[] ms)");
        ubyte data[];
        int alignment;
        glGetIntegerv(GL_UNIFORM_BUFFER_OFFSET_ALIGNMENT, &alignment);

        ulong padding = alignment - (T.sizeof % alignment);
        ulong elementsize = T.sizeof + padding;

        data.length = ms.length * elementsize;

        foreach (int i, T m; ms) {
            ulong start = ms.length * i;
            data[start..start+T.sizeof] = (cast(ubyte *)(&m))[0..T.sizeof];
        }
        return data;
    }

    ubyte[] getData(T m) {
        writefln("getData(T m)");
        ubyte data[];
        int alignment;
        glGetIntegerv(GL_UNIFORM_BUFFER_OFFSET_ALIGNMENT, &alignment);

        ulong padding = alignment - (T.sizeof % alignment);
        ulong elementsize = T.sizeof + padding;

        data.length = elementsize;

        data[0..T.sizeof] = (cast(ubyte *)(&m))[0..T.sizeof];
        return data;
    }
}

class Texture2D {
    private uint _location;
    this() {
        glGenTextures(1, &_location);
    }
    ~this() {
        writefln("Destroying texture at location %d", _location);
        glDeleteBuffers(1, &_location);
    }
    void bind() {
        glBindTexture(GL_TEXTURE_2D, _location);
    }
    void unbind() {
        glBindTexture(GL_TEXTURE_2D, 0);
    }
    void setData(char* data, int width, int height) {
        setData(data, width, height, GL_RGBA8, GL_RGBA);
    }

    void setData(char* data, int width, int height, uint internalFormat, uint format) {
        glTexImage2D(GL_TEXTURE_2D, 0, internalFormat, width, height, 0, format, GL_UNSIGNED_BYTE, data);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    }
}
