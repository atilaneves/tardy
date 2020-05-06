module modules.ufcs.stringify;


import modules.types: Negative, Point, String;
import std.conv: text;


string stringify(int* i) @safe pure {
    return text(*i);
}

string stringify(double* d) @safe /* not pure */ {
    return text(*d);
}

string stringify(string* s) @safe pure {
    return *s;
}

string stringify(Negative* n) @safe pure {
    return "Negative";
}

string stringify(Point* p) @safe pure {
    return text("Point(", p.x, ", ", p.y, ")");
}

string stringify(String* s) @safe pure {
    return s.value;
}
