module modules.ufcs.transform;


int transform(int* i, int j) @safe pure {
    return *i * j;
}

int transform(double* d, int i) @safe pure {
    return cast(int) *d + i;
}
