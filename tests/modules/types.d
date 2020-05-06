module modules.types;


struct Negative {
    int transform(int i) @safe const {
        return -i;
    }
}


struct Point {
    int x, y;
}

struct String {
    string value;
}
