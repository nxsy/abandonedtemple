module app;

import std.stdio : writefln;
import std.getopt : getopt;

import abandonedtemple.demos.base;

void main(string[] args) {
    auto demo = "demo3";
    getopt(args, "demo", &demo);

    auto demo_classname = "abandonedtemple.demos." ~ demo ~ ".Demo";
    auto o = Object.factory(demo_classname);
    if (o) {
        (cast(DemoBase)o).run();
        return;
    }
    writefln("Could not find specified demo: %s", demo);
}
