module modules.ufcs.ref_.transform;


int transform(ref const int i, int j) @safe pure {
    return i * j;
}

int transform(ref const double d, int i) @safe pure {
    return cast(int) d + i;
}
