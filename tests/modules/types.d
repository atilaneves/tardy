module modules.types;


struct Negative {
    int transform(int i) @safe pure const {
        return -i;
    }
}


struct Point {
    int x, y;
}

struct String {
    string value;
}
