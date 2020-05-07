module ut.refraction.vtable;


import ut;
import tardy.refraction;
import std.meta: AliasSeq;
static import std.traits;  // because refract uses it


// The original function declarations *and* the mixed in declarations that ape
// them need to be at module scope to prevent the compiler from inferring
// function attributes such as @safe or pure.

private int simple(double d, string s);
private int safe_(ubyte b, float f, double d) @safe;
private double pure_(double) @safe pure;
private int twice(const int i);

struct Struct {
    import modules.types: Point;

    int const_() const;
    Point point() const;
    void inc(int amount);
    void safeInc(int amount) @safe;
    void scopeInc(int amount) @safe scope;
}

alias functions = AliasSeq!(
    Struct.const_,
    Struct.point,
    Struct.inc,
    Struct.safeInc,
    Struct.scopeInc,
    simple,
    safe_,
    pure_,
    twice,
);

//pragma(msg, "");
static foreach(F; functions) {
    // pragma(msg, "F: ", std.traits.fullyQualifiedName!F, "\t\t", vtableEntryRecipe!F);
    mixin(vtableEntryRecipe!F, " ", vtableEntryId!F, ";");
    // pragma(msg, "");
}
// pragma(msg, "");


@("return")
@safe pure unittest {
    static foreach(F; functions) {
        shouldMatchReturnType!F;
    }
}

private void shouldMatchReturnType(alias F)() {
    import std.traits: ReturnType;
    import std.conv: text;
    enum vtableEntry = vtableEntryId!F;
    static assert(is(ReturnType!F == ReturnType!(mixin(vtableEntry))),
                  text("Wrong return type for " ~ __traits(identifier, F),
                       ": expected ", ReturnType!F.stringof, " but got ", ReturnType!(mixin(vtableEntry)).stringof));
}


@("self.mutable")
@safe pure unittest {
    shouldMatchSelf!(simple, void*);
    shouldMatchSelf!(Struct.inc, void*);
}


@("self.const")
@safe pure unittest {
    shouldMatchSelf!(twice, const(void)*);
    shouldMatchSelf!(Struct.const_, const(void)*);
}


private void shouldMatchSelf(alias F, T)() {
    import std.conv: text;
    import std.traits: Parameters;

    enum vtableEntry = vtableEntryId!F;
    alias params = Parameters!(mixin(vtableEntry));

    static assert(is(params[0] == T),
                  text("Wrong self type for ", __traits(identifier, F),
                       ": expected ", T.stringof, " but got ", params[0].stringof));
}


@("type.struct.inc")
@safe pure unittest {
    static assert(is(typeof(mixin(vtableEntryId!(Struct.inc))) == void function(void*, int) @system));
}


@("type.struct.safeInc")
@safe pure unittest {
    alias T = typeof(mixin(vtableEntryId!(Struct.safeInc)));
    static assert(is(T == void function(void*, int) @safe));
}


// FIXME: dmd bug
@("type.struct.scopeInc")
@safe pure unittest {
    alias T = typeof(mixin(vtableEntryId!(Struct.scopeInc)));
    //static assert(is(T == void function(scope void*, int) @safe));
}


private string vtableEntryId(alias F)() {
    return "asvtable_" ~ __traits(identifier, F);
}
