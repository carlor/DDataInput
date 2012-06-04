// Written in the D Programming Language
// Copyright (C) 2012 Nathan M. Swan
// Distributed under the Boost Software License (see LICENSE file)

/*
This contains all the functions for I/O (duh)
*/

module ddi.io;

public import std.file : readText, exists;
public import std.stdio;
public import std.string;

public import ddi.color;

// gets the line, handling .quit
string readCommand() {
    auto r = readLine();
    if (r.toLower() == ".quit") {
        prompt("Are you sure you want to quit (y/n)? ");
        if (readBoolean!true()) {
            throw new QuitException();
        } else {
            return readCommand();
        }
    }
    return r;
}

/*
Why the ignoreQuit? I don't want this to happen:

Are you sure you want to quit (y/n)? .quit
Are you sure you want to quit (y/n)? 
...
*/
bool readBoolean(bool ignoreQuit=false)() {
    auto cf = ignoreQuit ? readLine() : readCommand();
    return cf.length && (cf[0] == 'y' || cf[0] == 'Y');
}

string readLine() {
    return stdin.readln().strip().idup;
}

// warnings display these as error messages
void warn(T...)(T args) {
    setConsoleForeground(Color.Red);
    stdout.write(args);
    setConsoleForeground(Color.Default);
}

void warnln(T...)(T args) {
    setConsoleForeground(Color.Red);
    stdout.writeln(args);
    setConsoleForeground(Color.Default);
}

// prompting, rather than just writing, draws more attention
void prompt(T...)(T args) {
    setFontHighlight(true);
    stdout.write(args);
    setFontHighlight(false);
}

void promptln(T...)(T args) {
    prompt(args, "\n");
}

class QuitException : Exception {
    this() {
        super("");
    }
}
