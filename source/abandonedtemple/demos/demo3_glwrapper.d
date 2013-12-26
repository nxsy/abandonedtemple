module abandonedtemple.demos.demo3_glwrapper;

import std.range : ElementType;
import std.traits : isArray;

import derelict.opengl3.gl3:
    glGenVertexArrays,
    glBindVertexArray,
    glGenBuffers,
    glBindBuffer,
    glBufferData,
    GL_ARRAY_BUFFER,
    GL_ELEMENT_ARRAY_BUFFER;

class VertexArray {
    private uint _location;
    this() {
        glGenVertexArrays(1, &_location);
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

