module abandonedtemple.demos.demo3_program;

import std.conv : to;
import std.string : chomp, splitLines, split;

import derelict.opengl3.gl3;
import gl3n.linalg : vec3, vec4, mat4;

enum ShaderType {
    Vertex = GL_VERTEX_SHADER,
    Fragment = GL_FRAGMENT_SHADER,
}

interface ShaderBase {
    @property uint location();
}

mixin template Shader() {
    import std.algorithm : startsWith;
    import std.stdio : writefln;
    import derelict.opengl3.gl3 :
        glCreateShader,
        glShaderSource,
        glCompileShader,
        glGetShaderiv,
        GL_COMPILE_STATUS,
        glGetShaderInfoLog,
        glDeleteShader;

    static ShaderType type;
    static string source;

    private uint _location;
    @property uint location() {
        return _location;
    }

    uint loadShader() {
        int compileStatus;

        uint shader = glCreateShader(type);
        immutable(char) *sourcePtr = source.ptr;
        int length = cast(int) source.length;
        glShaderSource(shader, 1, &sourcePtr, &length);

        glCompileShader(shader);
        glGetShaderiv(shader, GL_COMPILE_STATUS, &compileStatus);
        if (!compileStatus) {
            char compileLog[1024];
            glGetShaderInfoLog(shader, cast(int)compileLog.sizeof, null,
                compileLog.ptr);
            writefln("Error compiling shader type %d: %s", type,
                compileLog);
            throw new Error("Shader compilation failure");
        }
        return shader;
    }

}

string shader(string name, ShaderType type, string source) {
    return
"class " ~ name ~ " : ShaderBase {
    mixin Shader;
    static this() {
        source = `" ~ source ~ "`;
        type = ShaderType." ~ to!string(type) ~ ";
    }

    this() {
        _location = loadShader();
    }

    ~this() {
        if (_location) {
            writefln(`Deleting shader at location %d`, _location);
            glDeleteShader(_location);
        }
    }
}";
}

class Uniform(T) {
    private string _name;
    private ProgramBase _program;
    private uint _location;

    this(string name, ProgramBase p) {
        _name = name;
        _program = p;
        _location = glGetUniformLocation(_program.location, _name.ptr);
        if (_location == -1) {
            throw new Error("Uniform bind failure");
        }
    }

    private bool is_transposed;
    void setTranspose(bool t) {
        is_transposed = t;
    }

    ref Uniform!T opAssign(T)(T value) if (is(T == mat4)) {
        ubyte glbool = GL_FALSE;
        if (is_transposed) {
            glbool = GL_TRUE;
        }
        glUniformMatrix4fv(_location, 1, glbool, value.value_ptr);
        return this;
    }

    ref Uniform!T opAssign(T)(T value) if (is(T == vec4)) {
        glUniform4f(_location, value.x, value.y, value.z, value.w);
        return this;
    }

    ref Uniform!T opAssign(T)(T value) if (is(T == vec3)) {
        glUniform3f(_location, value.x, value.y, value.z);
        return this;
    }

    ref Uniform!T opAssign(T)(T value) if (is(T == int)) {
        glUniform1i(_location, value);
        return this;
    }
}

interface ProgramBase {
    @property int location();
}

mixin template _Program() {
    import std.stdio : writefln;
    import derelict.opengl3.gl3 :
        glUseProgram,
        glCreateProgram,
        glAttachShader,
        glLinkProgram,
        glGetProgramiv,
        GL_LINK_STATUS,
        glGetProgramInfoLog;

    int _location;
    ShaderBase[] shaders;

    @property int location() {
        return _location;
    }

    void use() {
        glUseProgram(_location);
    }

    void loadProgram() {
        _location = glCreateProgram();
        foreach (ShaderBase shader; shaders) {
            glAttachShader(_location, shader.location);
        }
        glLinkProgram(_location);

        int linkStatus;
        glGetProgramiv(_location, GL_LINK_STATUS, &linkStatus);

        if (!linkStatus) {
            char linkerLog[1024];
            glGetProgramInfoLog(_location, cast(int)linkerLog.sizeof, null,
                linkerLog.ptr);
            writefln("Error linking program: %s", linkerLog);
            throw new Error("Program linker failure");
        }
    }
}

string generateUniformClass(string name, string[string] uniforms) {
    import std.algorithm : join;
    string[] uniformInit;
    string[] uniformLoad;
    foreach (string name, string type; uniforms) {
        if (type == "sampler2D") {
            type = "int";
        }
        uniformInit ~= name ~ ` = new Uniform!` ~ type ~ `("` ~ name ~ `", _program);`;
    }
    string prelog = `
    class Uniforms {
        string[string] _uniforms;
        ` ~ name ~ ` _program;
        this(` ~ name ~ ` program) {
            _program = program;
            _uniforms = ` ~ to!string(uniforms) ~ `;
            ` ~ uniformInit.join() ~ `
        }
        string[string] getUniforms() {
            return this._uniforms;
        }
`;
    string guts = "";
    foreach (string name, string type; uniforms) {
        if (type == "sampler2D") {
            type = "int";
        }
        guts ~= "        Uniform!" ~ type ~ " " ~ name ~ ";\n";
    }
    string postlog = `    }`;
    return prelog ~ guts ~ postlog;
}

struct ShaderData {
    ShaderType type;
    string source;
}

string program_from_shader_filenames(string name, string[] shaders) {
    return "mixin(program_from_shader_filenames(`" ~ name ~ "`, __FILE__, " ~ to!string(shaders) ~ "));";
}

string program_from_shader_filenames(string name, string basepath, string[] shaders) {
    import std.path : dirName, buildPath;
    import std.algorithm : join;
    string baseDir = dirName(basepath);
    string shaderdata[];

    foreach(string filepath; shaders) {
        ShaderType st;
        if (filepath[$-5 .. $] == ".vert") {
            st = ShaderType.Vertex;
        }
        if (filepath[$-5 .. $] == ".frag") {
            st = ShaderType.Fragment;
        }
        auto fullpath = filepath; // buildPath(baseDir, filepath);
        shaderdata ~= `ShaderData(ShaderType.` ~ to!string(st) ~ `, import(r"` ~ fullpath ~ `"))`;
 
    
    return `
import abandonedtemple.demos.demo3_program : program_from_shaders, ShaderData, ShaderType;
mixin(program_from_shaders("` ~ name ~ `", [
    ` ~ shaderdata.join(",") ~ `
]));
`;
}

string program_from_shaders(string name, ShaderData[] shaders) {
    import std.algorithm : startsWith;
    import std.string : chomp, split, splitLines;
    string[string] uniforms;
    string shaderSetup;
    string shaderLoad;
    string shaderClasses;
    foreach(ShaderData shaderData; shaders) {
        ShaderType st = shaderData.type;
        string shaderclass = name ~ to!string(st);

        auto lines = shaderData.source.splitLines();
        foreach (string l; lines) {
            if (l.startsWith("uniform")) {
                l = l.chomp(";");
                auto p = l.split();
                uniforms[p[2]] = p[1];
            }
        }
        shaderSetup ~= shader(shaderclass, st, shaderData.source);
        shaderLoad ~= "shaders ~= new " ~ shaderclass ~ "();";
        shaderClasses ~= shaderclass;
    }
    return /*shaderSetup ~*/ `
import abandonedtemple.demos.demo3_program : ProgramBase, ShaderBase, Shader, Uniform, _Program;
class ` ~ name ~ ` : ProgramBase {
    ` ~ shaderSetup ~ `
    ` ~ generateUniformClass(name, uniforms) ~ `
    Uniforms uniforms;
    mixin _Program;

    this() {
        ` ~ shaderLoad ~ `
        loadProgram();
        uniforms = new Uniforms(this);
    }

    ~this() {
        writefln("Deleting shader at location %d", _location);
        glDeleteProgram(_location);
    }

}
`;
}

