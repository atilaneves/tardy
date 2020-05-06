module tardy.refraction;


auto refractMixin(alias F)(in string newName) {
    import bolts.experimental.refraction: refract;
    return refract!(F, __traits(identifier, F)).setName(newName).mixture;
}


string methodRecipe(string symbol = "")
    in(__ctfe)
    do
{
    import std.conv: text;
    import std.traits: fullyQualifiedName;

    return text(`std.traits.ReturnType!(`, symbol, `) function(void*)`);
}
