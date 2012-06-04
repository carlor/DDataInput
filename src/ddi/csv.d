// Written in the D Programming Language
// Copyright (C) 2012 Nathan M. Swan
// Distributed under the Boost Software License (see LICENSE file)

/*
This module handles the CSV file format.
I didn't use std.csv because it only reads, and I couldn't figure out how to get
a simple string[][].
*/

module ddi.csv;

import std.algorithm;
import std.array;
import std.string;

import ddi.io;

public:
class CsvData {
    void readFromFile() {
        string str = std.file.readText!string(file);
        data = parseCsv(str);
    }
    
    void writeToFile() {
        auto f = File(file, "w");
        auto d = data;
        if (headersAreVisible) {
            d = headers ~ data;
        }
        foreach(row; data) {
            writeRow(f, row);
        }
    }
    
    CsvRow[] data;  // the actual data, TODO I should encapsulate it.
    CsvRow headers; // these serve as prompts in inputting
    
    // true: put them in the file, false: headers are only guides
    bool headersAreVisible;
    string file;
}

alias string[] CsvRow;

class CsvException : Exception {
    this() {
        super("Invalid CSV file.");
    }
}

private:

// --- reading csv ---
CsvRow[] parseCsv(string fstr) {
    CsvRow[] r;
    auto str = new Stream(fstr, 0);
    while (!str.empty) {
        r ~= consumeRow(str); // must consume CRLF as well
    }
    return r;
}

CsvRow consumeRow(Stream str) { // consumes CRLF
    CsvRow r;
    while (!str.empty) {
        r ~= consumeItem(str); // does NOT consume ,/CRLF
        switch (str.front) {
            case ',':
                str.popFront();
                continue;
            case '\r': case '\n':
                consumeLineEnding(str);
            case 0:
                return r;
            default:
                throw new CsvException();
        }
    }
    assert(0);
}

string consumeItem(Stream str) { // don't consume , or CRLF
    bool quoted = str.front == '"';
    if (quoted) {
        return consumeQuotedItem(str);
    } else {
        return consumeQuotelessItem(str);
    }
}

string consumeQuotedItem(Stream str) {
    string r;
    str.popFront();
    while (!str.empty) {
        if (str.front == '"') {
            if (str[1] == '"') {
                r ~= '"';
                str.consume(2);
            } else { // comma or CRLF or EOF
                str.popFront();
                return r;
            }
        } else if (str.front == 0) { // unclosed quote
            throw new CsvException();
        } else if (str.front == '\r' || str.front == '\n') {
            r ~= consumeLineEnding(str);
        } else {
            r ~= str.front;
            str.popFront();
        }
    }
    assert(0);
}

string consumeQuotelessItem(Stream str) {
    string r;
    while (!str.empty) {
        auto c = str.front;
        if (c == ',' || c == '\n' || c == '\r' || c == 0) { // done
            return r;
        } else {
            r ~= c;
            str.popFront();
        }
    }
    assert(0);
}

string consumeLineEnding(Stream str) {
    if (str.front == '\r') {
        if (str[1] == '\n') {
            str.consume(2);
        } else throw new CsvException(); // lone \r
    } else {
        assert(str.front == '\n');
        str.popFront();
    }
    return "\r\n";
}

alias Lookahead!(string, dchar) Stream;

// copied from dcaflib (https://github.com/carlor/dcaflib)
// TODO put it into Phobos
class Lookahead(R, T) {
    this(R range, T sentinel) {
        _range = range;
        _buffer = [];
        _sentinel = sentinel;
    }
    
    void consume(size_t howmuch=1) {
        if (howmuch < _buffer.length) {
            _buffer = _buffer[howmuch .. $];
        } else {
            howmuch -= _buffer.length;
            _buffer = [];
            while(howmuch-- && !_range.empty) {
                _range.popFront();
            }
        }
    }
    
    T get(size_t howmuch=0) {
        if (howmuch >= _buffer.length) {
            updateBuffer(howmuch+1);
        }
        if (_buffer.length <= howmuch) {
            return _sentinel;
        } else {
            return _buffer[howmuch];
        }
    }
    
    void updateBuffer(size_t howmuch) {
        howmuch -= _buffer.length;
        while(howmuch && !_range.empty) {
            _buffer ~= _range.front;
            _range.popFront();
            howmuch--;
        }           
    }     
    
    @property T front() {
        return get(0);
    }
    
    @property bool empty() {
        return !_buffer.length && _range.empty;
    }
    
    void popFront() {
        consume(1);
    }
    
    @property auto save() {
        typeof(this) r = new typeof(this)(_range, _sentinel);
        r._range = _range;
        r._buffer = _buffer;
        r._sentinel = _sentinel;
        return r;
    }
    
    T opIndex(size_t n) {
        return get(n);
    }
    
    private R _range;
    private T[] _buffer;
    private T _sentinel;                           
}

// --- writing csv ---
public string enquoteItem(string unformatted) {
    return `"` ~ replace(unformatted, `"`, `""`) ~ `"`;
        
}

void writeRow(File f, CsvRow row) {
    f.write(join(map!enquoteItem(row), ","), "\r\n");
}


