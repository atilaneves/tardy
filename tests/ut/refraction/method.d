module ut.refraction.method;


import ut;
import tardy.refraction;


private interface Interface {
    import modules.types: Point;
    int fun(double d, string s) @safe pure const;
    char gun(int i, float f, Point p) @system immutable;
}


struct Instance {
    static import std.traits;  // because refract uses it
    mixin(methodRecipe!(Interface.fun), `;`);
    mixin(methodRecipe!(Interface.gun), `;`);
}


@("fun")
@safe pure unittest {
    static assert(is(typeof(Instance.fun) == typeof(Interface.fun)));
}


@("gun")
@safe pure unittest {
    static assert(is(typeof(Instance.gun) == typeof(Interface.gun)));
}
