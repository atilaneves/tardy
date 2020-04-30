module modules.ufcs.stringfy;


import modules.types: Negative, Point, String;
import std.conv: text;


string stringify(int* i) {
    return text(*i);
}

string stringify(double* d) {
    return text(*d);
}

string stringify(string* s) {
    return *s;
}

string stringify(Negative* n) {
    return "Negative";
}

string stringify(Point* p) {
    return text("Point(", p.x, ", ", p.y, ")");
}

string stringify(String* s) {
    return s.value;
}
