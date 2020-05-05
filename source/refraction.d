module refraction;


auto refractMixin(alias F)(in string newName) {
    import bolts.experimental.refraction: refract;
    return refract!(F, __traits(identifier, F)).setName(newName).mixture;
}
