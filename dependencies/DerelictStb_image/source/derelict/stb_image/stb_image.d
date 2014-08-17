module derelict.stb_image.stb_image;

version(OSX) {
    private {
        import derelict.util.loader;
        import derelict.util.system;

        static if( Derelict_OS_Mac ) {
            enum libNames = "stb_image.0.dylib";
        } else {
            static assert( 0, "Need to implement stb_image libNames for this operating system." );
        }
    }

    extern( C ) nothrow {
        alias da_stbi_load = char* function(const(char)*, int*, int*, int*, int);
        alias da_stbi_image_free = void function(void*);
    }

    __gshared {
        da_stbi_load stbi_load;
        da_stbi_image_free stbi_image_free;
    }

    class DerelictStb_imageLoader : SharedLibLoader {
        public this() {
            super( libNames );
        }

        protected override void loadSymbols() {
            bindFunc( cast( void** )&stbi_load, "stbi_load" );
            bindFunc( cast( void** )&stbi_image_free, "stbi_image_free" );
        }
    }

    __gshared DerelictStb_imageLoader DerelictStb_image;

    shared static this() {
        DerelictStb_image = new DerelictStb_imageLoader();
    }
}
