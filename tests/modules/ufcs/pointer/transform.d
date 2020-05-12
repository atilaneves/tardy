module modules.ufcs.pointer.transform;


int transform(const(int)* i, int j) @safe pure {
    return *i * j;
}

int transform(const(double)* d, int i) @safe pure {
    return cast(int) *d + i;
}
