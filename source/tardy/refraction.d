module tardy.refraction;


/**
   Returns a string mixin that is the function pointer type of F,
   with an extra void* (or const(void)*) first parameter.
 */
string vtableEntryRecipe(alias F)(in string symbolName = "")
    in(__ctfe)
    do
{
    import std.conv: text;
    import std.algorithm: canFind, among, filter;
    import std.array: join;

    const symbol = symbolForTraits!F(symbolName);
    enum attrs = [ __traits(getFunctionAttributes, F) ];

    enum isConst = attrs.canFind("const");
    enum isImmutable = attrs.canFind("immutable");
    enum isShared = attrs.canFind("shared");

    enum selfType = isConst
        ? `const(void)*`
        : isImmutable
            ? `immutable(void)*`
            : isShared
                ? `shared(void)*`
                : `void*`;

    static bool isMemberFunctionOnly(in string attr) {
        return cast(bool) attr.among("const", "immutable", "shared", "inout", "return", "scope");
    }

    const selfAttrs = attrs
        .filter!(a => isMemberFunctionOnly(a) && !a.among("const", "immutable", "shared"))
        .join(" ");
    const vtableEntryAttrs = attrs
        .filter!(a => !isMemberFunctionOnly(a))
        .join(" ");

    return text(returnRecipe(symbol),
                ` function(`, selfAttrs, " ", selfType, `, `,
                parametersRecipe!F(symbol), `)`,
                vtableEntryAttrs);
}


/**
   Returns a string to be mixed in that replicates the signature
   of F. The string is meant to be mixed in inside a struct or class
   so as to be a member function.
 */
string methodRecipe(alias F)(in string symbolName = "")
    in(__ctfe)
     do
{
    import std.conv: text;
    import std.range: iota;
    import std.algorithm: map;
    import std.array: join;

    const symbol = symbolForTraits!F(symbolName);
    enum name = __traits(identifier, F);
    enum attrs = [ __traits(getFunctionAttributes, F) ].join(" ");

    return text(returnRecipe(symbol), `  `,
                name,
                `(`, parametersRecipe!F(symbol), `)`,
                ` `, attrs);
}


private string symbolForTraits(alias F)(in string symbolName = "")
    in(__ctfe)
    do
{
    import std.traits: fullyQualifiedName;
    return symbolName == "" ? fullyQualifiedName!F : symbolName;
}


private string returnRecipe(in string symbol)
    @safe pure
    in(__ctfe)
    do
{
    return `std.traits.ReturnType!(` ~ symbol ~ `)`;
}

private string parametersRecipe(alias F)(in string symbol) {

    import std.array: join;
    import std.traits: Parameters;

    string[] parameters;

    static foreach(i; 0 .. Parameters!F.length) {
        parameters ~= parameterRecipe!(F, i)(symbol);
    }

    return parameters.join(", ");
}


private string parameterRecipe(alias F, size_t i)(in string symbol) {
    import std.array: join;
    import std.conv: text;

    const string[] storageClasses = [ __traits(getParameterStorageClasses, F, i) ];
    return text(storageClasses.join(" "), " ",

                `std.traits.Parameters!(`, symbol, `)[`, i, `] `,
                `arg`, i);
}
