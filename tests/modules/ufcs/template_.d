module modules.ufcs.template_;


struct Struct {
    int i;
}


int transform(T)(T obj, int j) {
    import std.traits: Unqual;

    static if(is(Unqual!T == Struct))
        return obj.i + j;
    else static if(is(Unqual!T == int))
        return obj * j;
    else static if(is(Unqual!T == double))
        return cast(int) (obj - j);
}
