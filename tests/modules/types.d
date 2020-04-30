module modules.types;


struct Negative {
    int transform(int i) const {
        return -i;
    }
}


struct Point {
    int x, y;
}

struct String {
    string value;
}
