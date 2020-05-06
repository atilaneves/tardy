module tardy.refraction;


auto refractMixin(alias F)(in string newName) {
    import bolts.experimental.refraction: refract;
    return refract!(F, __traits(identifier, F)).setName(newName).mixture;
}


string methodRecipe(alias F)()
    in(__ctfe)
    do
{
    import std.conv: text;
    import std.traits: fullyQualifiedName, functionAttributes, FA = FunctionAttribute;

    enum symbol = fullyQualifiedName!F;
    enum attrs = functionAttributes!F;

    static if(isMemberFunction!F)
        enum isConst = attrs & FA.const_;
    else static if(is(typeof(F) parameters == __parameters))
        enum isConst = is(parameters[0] == const);
    else
        static assert(false);

    enum selfType = isConst ? `const(void)*` : `void*`;

    return text(`std.traits.ReturnType!(`, symbol, `) function(`, selfType,`, std.traits.Parameters!(`, symbol, `))`);
}


enum isMemberFunction(alias F) = is(__traits(parent, F) == struct) || is(__traits(parent, F) == class);
