module tardy.refraction;


/**
   Returns a string mixin that is the function pointer type of F,
   with an extra void* (or const(void)*) first parameter.
 */
string methodRecipe(alias F)(in string symbolName = "")
    in(__ctfe)
    do
{
    import std.conv: text;
    import std.traits: fullyQualifiedName;
    import std.algorithm: canFind, among, filter;
    import std.array: join;

    const symbol = symbolName == "" ? fullyQualifiedName!F : symbolName;
    enum attrs = [ __traits(getFunctionAttributes, F) ];

    static if(isMemberFunction!F)
        enum isConst = attrs.canFind("const");
    else static if(is(typeof(F) parameters == __parameters))
        enum isConst = is(parameters[0] == const);
    else
        static assert(false);

    const returnType = `std.traits.ReturnType!(` ~ symbol ~ `)`;
    enum selfType = isConst ? `const(void)*` : `void*`;

    static bool isMemberFunctionOnly(in string attr) {
        return cast(bool) attr.among("const", "immutable", "shared", "inout", "return", "scope");
    }

    const selfAttrs = attrs.filter!(a => isMemberFunctionOnly(a) && a != "const").join(" ");
    const methodAttrs = attrs.filter!(a => !isMemberFunctionOnly(a)).join(" ");

    return text(returnType, ` function(`, selfAttrs, " ", selfType,`, std.traits.Parameters!(`, symbol, `)) `, methodAttrs);
}


enum isMemberFunction(alias F) =
    is(__traits(parent, F) == struct)
    || is(__traits(parent, F) == class)
    || is(__traits(parent, F) == interface)
    ;
