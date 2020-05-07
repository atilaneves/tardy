module ut.refraction.method;


import ut;
import tardy.refraction;
import std.meta: AliasSeq;
static import std.traits;  // because refract uses it


private interface Interface {
    int fun(double d, string s) @safe pure const;
}

struct Instance {
    mixin(methodRecipe!(Interface.fun), `;`);
}


@("fun")
@safe pure unittest {
    static assert(is(typeof(Instance.fun) == typeof(Interface.fun)));
}
