module abandonedtemple.demos.demo3_assets;

import std.range : iota;
import std.stdio : writef, writefln;

import derelict.assimp3.assimp;
import derelict.opengl3.gl3;

import derelict.stb_image.stb_image : stbi_load;

import gl3n.linalg : vec4;

import abandonedtemple.demos.demo3_glwrapper :
    VertexArray, ArrayBuffer, ElementArrayBuffer, Texture2D, UniformBuffer,
    UniformBufferData;

struct Material {
    vec4 diffuse;
    vec4 ambient;
    vec4 specular;
    vec4 emissive;
    float shininess;
    int texCount;
}

void describeAiNode(const aiNode *node) {
    string name = aiStringToString(node.mName);
    writefln("Node %s with name %s has %d children and %d meshes",
        node, name, node.mNumChildren, node.mNumMeshes
    );
    writefln("  Transform matrix:");
    aiMatrix4x4 a = node.mTransformation;
    writefln("    %0.4f, %0.4f, %0.4f, %0.4f", a.a1, a.a2, a.a3, a.a4);
    writefln("    %0.4f, %0.4f, %0.4f, %0.4f", a.b1, a.b2, a.b3, a.b4);
    writefln("    %0.4f, %0.4f, %0.4f, %0.4f", a.c1, a.c2, a.c3, a.c4);
    writefln("    %0.4f, %0.4f, %0.4f, %0.4f", a.d1, a.d2, a.d3, a.d4);

    const aiNode *children[] = node.mChildren[0..node.mNumChildren];
    foreach (const aiNode *child; children) {
        describeAiNode(child);
    }
}

void describeMesh(const aiMesh* mesh) {
    string name = aiStringToString(mesh.mName);
    writefln("Mesh %s with name %s has %d vertices, %d faces, %d bones, and %d animation meshes",
        mesh, aiStringToString(mesh.mName), mesh.mNumVertices, mesh.mNumFaces, mesh.mNumBones,
        mesh.mNumAnimMeshes
    );

    uint max_texture_coords = 0;
    foreach (int j; iota(AI_MAX_NUMBER_OF_TEXTURECOORDS)) {
        const aiVector3D *vptr = mesh.mTextureCoords[j];
        if (vptr != null) {
            max_texture_coords++;
        }
    }

    uint max_color_sets = 0;
    foreach (int j; iota(AI_MAX_NUMBER_OF_COLOR_SETS)) {
        const aiColor4D *v4ptr = mesh.mColors[j];
        if (v4ptr != null) {
            max_color_sets++;
        }
    }

    foreach (int i; iota(mesh.mNumVertices)) {
        aiVector3D v = mesh.mVertices[i];
        writefln("  Vertex %d:", i);
        writefln("    Location: %s, %s, %s", v.x, v.y, v.z);
        aiVector3D normals = mesh.mNormals[i];
        writefln("    Normal: %s, %s, %s", normals.x, normals.y, normals.z);
        if (max_texture_coords) {
            writefln("    Texture Coords:");
            foreach (int j; iota(max_texture_coords)) {
                v = mesh.mTextureCoords[j][i];
                writefln("      %d: %s, %s, %s", j, v.x, v.y, v.z);
            }
        }
        if (max_color_sets) {
            writefln("    Colors:");
            foreach (int j; iota(max_color_sets)) {
                auto v4 = mesh.mColors[j][i];
                writefln("      %d: r:%s, g:%s, b:%s, a:%s", j, v4.r, v4.g, v4.b, v4.a);
            }
        }
    }

    foreach (int i; iota(mesh.mNumFaces)) {
        const aiFace f = mesh.mFaces[i];
        writef("  Face %d: ", i);
        auto comma = "";

        foreach (int j; iota(f.mNumIndices)) {
            writef("%s%d", comma, f.mIndices[j]);
            comma = ", ";
        }
        writefln("");
    }
}

void describeMaterial(const aiMaterial* material) {
    writefln("Material %s has %d properties and num allocated of %d",
        material, material.mNumProperties, material.mNumAllocated
    );

    foreach(int i; iota(material.mNumProperties)) {
        const aiMaterialProperty *property = material.mProperties[i];
        writefln("  Property %s named %s has semantic %d, index %d, datalength %d, property type %s",
            property, aiStringToString(property.mKey), property.mSemantic, property.mIndex, property.mDataLength, property.mType);
        writef("    Value: ");
        switch (property.mType) {
            case aiPTI_Float:
                auto comma = "";
                float[] data = (cast(float *)property.mData)[0..property.mDataLength/4];
                foreach (int j, float d; data) {
                    writef("%s%d:%.4f", comma, j, d);
                    comma = ", ";
                }
                version(none) {
                void *mData = cast(void *)property.mData;
                const float *data = cast(const float*)mData;
                foreach (int j; iota(property.mDataLength)) {
                    writef("%s%.4f", comma, data[j]);
                    comma = ", ";
                }
                }
                break;
            case aiPTI_Integer:
                const int *data = cast(const int*)property.mData;
                auto comma = "";
                foreach (int j; iota(property.mDataLength)) {
                    writef("%s%d", comma, data[j]);
                    comma = ", ";
                }
                break;
            case aiPTI_String:
                void *mData = cast(void *)property.mData;
                const char *data = cast(const char*)mData;
                foreach (int j; iota(property.mDataLength)) {
                    writef("%s", data[j]);
                }
                break;
            default:
        }
        writefln("");
    }
}

string aiStringToString(const aiString k) {
    char name[] = [];
    foreach(ulong i; iota(k.length)) {
        name ~= k.data[i];
    }
    return cast(string) name;
}

void describeScene(const aiScene* scene) {
    writefln("Scene %s has %d meshes, %d materials, %d animations, %d textures, %d lights, and %d cameras",
        scene, scene.mNumMeshes, scene.mNumMaterials, scene.mNumAnimations, scene.mNumTextures, scene.mNumLights, scene.mNumCameras);
    describeAiNode(scene.mRootNode);
    foreach (int i; iota(scene.mNumMeshes)) {
        describeMesh(scene.mMeshes[i]);
    }
    foreach (int i; iota(scene.mNumMaterials)) {
        describeMaterial(scene.mMaterials[i]);
    }
}

ArrayBuffer buildBuffer(bool invert_y = false)(const aiVector3D* list, uint number) {
        ArrayBuffer f;
        const aiVector3D vecs[] = list[0..number];
        float data_[];
        data_.length = number * 3;

        foreach (int i, aiVector3D vec3_; vecs) {
            int start = i * 3;
            int end = start + 3;
            if (invert_y) {
                data_[start..end] = [vecs[i].x, 1 - vecs[i].y, vecs[i].z];
            } else {
                data_[start..end] = [vecs[i].x, vecs[i].y, vecs[i].z];
            }
        }

        f = new ArrayBuffer();
        f.setData!(const float[])(data_, GL_STATIC_DRAW);
        return f;
}

class Texture {
    Texture2D texture;
    alias texture this;

    this(string filepath) {
        texture = new Texture2D();
        glActiveTexture(GL_TEXTURE0);
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        texture.bind();

        int width, height, comp;
        char* image_data = stbi_load(filepath.ptr, &width, &height, &comp, 4);
        texture.setData(image_data, width, height);
    }
}

class TextureMap {
    Texture _bound;
    Texture[string] textures;

    Texture add(string k) {
        if (k !in textures) {
            textures[k] = new Texture(k);
        }
        return textures[k];
    }

    void bind(string k) {
        textures[k].bind();
        _bound = textures[k];
    }

    void unbind() {
        _bound.unbind();
        _bound = null;
    }
}

float[] propertyToFloat(const aiMaterialProperty* property) {
    return (cast(float *)property.mData)[0..property.mDataLength/4];
}

int[] propertyToInt(const aiMaterialProperty* property) {
    return (cast(int*)property.mData)[0..property.mDataLength/4];
}

string propertyToString(const aiMaterialProperty* property) {
    char[] t = (cast(char *)property.mData)[4..property.mDataLength-1];
    return cast(string)t;
}

struct AnnotatedMaterial {
    Material _material;
    alias _material this;

    /// Key is AssImp's "mSemantic" for now.  "1" is diffusion texture.
    Texture[int] textures;

    UniformBuffer uniformBuffer;
}

class Materials {
    AnnotatedMaterial[] materials;
    //UniformBuffer[] materialBuffers;
    TextureMap textures;
    uint materialBinding;

    this(const aiScene* scene, uint materialBinding_, TextureMap textures_) {
        materialBinding = materialBinding_;
        const aiMaterial* materials_[] = scene.mMaterials[0..scene.mNumMaterials];
        textures = textures_;

        foreach (int i, const aiMaterial* m; materials_) {
            addMaterial(m);
        }
    }

    void populateMaterialWithFloats(ref AnnotatedMaterial m, const aiMaterialProperty *property) {
        string name = aiStringToString(property.mKey);
        float f[] = propertyToFloat(property);
        switch (name) {
            case "$clr.ambient":
                if (f.length == 3) {
                    f ~= 1;
                }
                m.ambient = vec4(f);
                break;
            case "$clr.diffuse":
                if (f.length == 3) {
                    f ~= 1;
                }
                m.diffuse = vec4(f);
                break;
            case "$clr.specular":
                if (f.length == 3) {
                    f ~= 1;
                }
                m.specular = vec4(f);
                break;
            case "$clr.emissive":
                if (f.length == 3) {
                    f ~= 1;
                }
                m.emissive = vec4(f);
                break;
            default:
        }
    }

    void populateMaterialWithStrings(ref AnnotatedMaterial m, const aiMaterialProperty *property) {
        string name = aiStringToString(property.mKey);
        string s = propertyToString(property);

        switch (name) {
            case "$tex.file":
                auto t = textures.add(s);
                m.textures[property.mSemantic] = t;
                m.texCount++;
                break;
            default:
        }
    }

    void populateMaterialWithProperty(ref AnnotatedMaterial m, const aiMaterialProperty *property) {
        switch (property.mType) {
            case aiPTI_Integer:
                int i[] = propertyToInt(property);
                break;
            case aiPTI_Float:
                populateMaterialWithFloats(m, property);
                break;
            case aiPTI_String:
                populateMaterialWithStrings(m, property);
                break;
            default:
                writefln("Unhandled propery named %s", aiStringToString(property.mKey));
        }
    }

    void addMaterial(const aiMaterial* material) {
        AnnotatedMaterial m;
        m.uniformBuffer = new UniformBuffer();
        const aiMaterialProperty *properties[] =
            material.mProperties[0..material.mNumProperties];
        foreach (const aiMaterialProperty *property; properties) {
            populateMaterialWithProperty(m, property);
        }
        materials ~= m;
        ubyte data[] = UniformBufferData!Material.getData(m);
        m.uniformBuffer.setData(data, GL_STATIC_DRAW);
    }

    void bind(int index) {
        AnnotatedMaterial m = materials[index];
        UniformBuffer ub = m.uniformBuffer;
        ub.bind();
        // Texture type 1 is Diffuse
        if (1 in m.textures) {
            m.textures[1].bind();
        }
        //glBindTexture(GL_TEXTURE_2D, m.texCount);
        ub.bindBase(materialBinding);
    }
}

class Mesh {
    VertexArray va;
    ArrayBuffer vertices;
    ArrayBuffer texture_coords;
    ElementArrayBuffer indices;
    Materials materials;
    uint numIndices;
    int materialIndex;

    this(const aiMesh *mesh, Materials materials_) {
        materials = materials_;
        materialIndex = mesh.mMaterialIndex;
        va = new VertexArray();
        va.bind();
        vertices = buildBuffer(mesh.mVertices, mesh.mNumVertices);
        if (mesh.mTextureCoords[0]) {
            texture_coords = buildBuffer!true(mesh.mTextureCoords[0], mesh.mNumVertices);
        }

        const aiFace faces[] = mesh.mFaces[0..mesh.mNumFaces];
        ushort indices_[];
        indices_.length = mesh.mNumFaces * 3;
        foreach (int i, const aiFace face_; faces) {
            int start = i * 3;
            int end = start + 3;
            indices_[start] = cast(ushort)face_.mIndices[0];
            indices_[start+1] = cast(ushort)face_.mIndices[1];
            indices_[start+2] = cast(ushort)face_.mIndices[2];
        }

        numIndices = cast(int)indices_.length;

        indices = new ElementArrayBuffer();
        indices.setData!(ushort[])(indices_, GL_STATIC_DRAW);
    }

    void draw() {
        va.bind();
        indices.bind();

        materials.bind(materialIndex);

        glEnableVertexAttribArray(0);
        glEnableVertexAttribArray(1);

        vertices.bind();
        glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, null);
        vertices.unbind();

        if (texture_coords) {
            texture_coords.bind();
            glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 0, null);
            texture_coords.unbind();
        }

        glDrawElements(GL_TRIANGLES, numIndices, GL_UNSIGNED_SHORT, cast(void *)0);

        glDisableVertexAttribArray(1);
        glDisableVertexAttribArray(0);

        indices.unbind();
        va.unbind();
    }
}

class Asset {
    Mesh[] meshes;
    Materials materials;
    TextureMap textures;

    this(const aiScene* scene, uint materialBinding) {
        textures = new TextureMap();
        materials = new Materials(scene, materialBinding, textures);

        const aiMesh* meshes_[] = scene.mMeshes[0..scene.mNumMeshes];

        foreach (const aiMesh *aimesh; meshes_) {
            Mesh mesh = new Mesh(aimesh, materials);
            meshes ~= mesh;
        }
    }
    ~this() {
    }
    void draw() {
        foreach (Mesh m; meshes) {
            m.draw();
        }
    }
}

const(aiScene*) importFile(string filename) {
    return aiImportFile(filename.ptr,
        aiProcessPreset_TargetRealtime_Fast);
}
