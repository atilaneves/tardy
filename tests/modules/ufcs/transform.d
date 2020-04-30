module modules.ufcs.transform;


int transform(int* i, int j) {
    return *i * j;
}

int transform(double* d, int i) {
    return cast(int) *d + i;
}
