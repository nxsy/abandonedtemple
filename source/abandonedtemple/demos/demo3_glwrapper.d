module abandonedtemple.demos.demo3_glwrapper;

import std.range : ElementType;
import std.stdio : writefln;
import std.traits : isArray;

import derelict.opengl3.gl3:
    glGenBuffers,
    glGenTextures,
    glGenVertexArrays,
    glBindBuffer,
    glBindTexture,
    glBindVertexArray,
    glBufferData,
    glDeleteBuffers,
    glDeleteVertexArrays,
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
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, data);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    }
}
