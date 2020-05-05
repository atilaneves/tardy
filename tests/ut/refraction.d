module ut.refraction;


import ut;
import refraction: refractMixin;
import std.meta: AliasSeq;
static import std.traits;  // because refract uses it


// The original function declarations *and* the mixed in declarations that ape
// them need to be at module scope to prevent the compiler from inferring
// function attributes such as @safe or pure.

int simple(double d, string s);
int safe_(ubyte b, float f, double d) @safe;

alias functions = AliasSeq!(
    simple,
    safe_,
);

static foreach(F; functions) {
    mixin(refractMixin!F(newId!F));
    static assert(is(typeof(mixin(newId!F)) == typeof(F)));
}

private string newId(alias F)() {
    return "as_" ~ __traits(identifier, F);
}
