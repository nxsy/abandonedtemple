module abandonedtemple.demos.demo3_image;

import std.string: toStringz;
version (Windows) {
    import derelict.freeimage.freeimage;

    char* loadFreeImage(string filename, int *width, int *height) {
        auto file = toStringz(filename);

        FREE_IMAGE_FORMAT fif = FreeImage_GetFileType(file, 0);
        if(fif == FIF_UNKNOWN) {
            fif = FreeImage_GetFIFFromFilename(file);
        }
        if(fif == FIF_UNKNOWN) {
            return null;
        }

        // check that the plugin has reading capabilities ...
        if(!FreeImage_FIFSupportsReading(fif)) {
            return null;
        }

        auto flag = 0;
        FIBITMAP *bitmap = FreeImage_Load(fif, file, flag);

        FIBITMAP *pImage = FreeImage_ConvertTo32Bits(bitmap);
        *width = FreeImage_GetWidth(pImage);
        *height = FreeImage_GetHeight(pImage);

        char *ret = cast(char *)FreeImage_GetBits(pImage);
        //FreeImage_Unload(bitmap);
        //FreeImage_Unload(pImage);

        return ret;
    }
}
