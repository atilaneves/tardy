module tardy.refraction;


auto refractMixin(alias F)(in string newName) {
    import bolts.experimental.refraction: refract;
    return refract!(F, __traits(identifier, F)).setName(newName).mixture;
}


/**
   Given a function F, constructs a mixin string for a function
   pointer declaration that mimics that function's signature, adding a
   first explicit void* parameter analogous to `this`.
 */
string methodRecipe(alias F)()
    in(__ctfe)
    do
{
    import std.conv: text;
    import std.traits: fullyQualifiedName;
    enum fqn = fullyQualifiedName!F;
    return text(`std.traits.ReturnType!(`, fqn, `) function(void*)`);
}
