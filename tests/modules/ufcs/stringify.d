module modules.ufcs.stringify;


import modules.types: Negative, Point, String;
import std.conv: text;


string stringify(const(int)* i) @safe pure {
    return text(*i);
}

string stringify(const(double)* d) @safe /* not pure */ {
    return text(*d);
}

string stringify(const(string)* s) @safe pure {
    return *s;
}

string stringify(const(Negative)* n) @safe pure {
    return "Negative";
}

string stringify(const(Point)* p) @safe pure {
    return text("Point(", p.x, ", ", p.y, ")");
}

string stringify(const(String)* s) @safe pure {
    return s.value;
}
