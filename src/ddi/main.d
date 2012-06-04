// Written in the D Programming Language
// Copyright (C) 2012 Nathan M. Swan
// Distributed under the Boost Software License (see LICENSE file)

/*
This contains all the logic of communicating with the user.
TODO put more communication in ddi.msg
*/

module ddi.main;

import std.array;

import ddi.csv;
import ddi.io;
import ddi.msg;

void main(string[] args) {
    writeln(Message.INTRO);
    while(!stdin.eof) {
        try {
            workFile();
        } catch (QuitException qe) {
            // QuitExceptions trigger scope blocks
            break;
        } catch (DDIException ddie) {
            warnln(ddie.msg);
        } catch (Exception e) {
            warnln("Unexpected error: ", e);
        }
    }
    goodBye();
}

void workFile() {
    CsvData data = beginWorkFile(); // gives opening instructions, opens file
    scope(exit) save(data);
    while (receiveInput(data)) {    // returns whether .done not pressed
        promptln("Okay, next row:");
    }
}

CsvData beginWorkFile() {
    prompt(Message.OPENING_INSTRUCTIONS);
    auto r = openFile();
    askHeaders(r);
    promptln(Message.START_INPUT);
    return r;
}

CsvData openFile() {
    auto r = new CsvData();
    while (true) {
        auto cmd = readCommand();
        if (cmd.toLower() == ".new") {
            break;
        } else {
            if (cmd.exists) {
                r.file = cmd;
                try {
                    r.readFromFile();
                    break;
                } catch (CsvException e) {
                    warnln(e.msg);
                    warn("Try again:\n\t");
                }
            } else {
                warn("The file doen't exist. Try again:\n\t");
            }
        }   
    } 
    return r;
}

void askHeaders(CsvData data) {
    if (data.data == []) {
        queryHeaders(data);
    } else {
        prompt("Does the first row contain a header (y/n)? ");
        if (readBoolean()) {
            shiftHeaders(data);
        } else {
            queryHeaders(data);
        }
    }
}

void queryHeaders(CsvData data) {
    data.headersAreVisible = false;
    promptln(`Input the headers, one per line, ending with ".done"`);
    while(true) {
        write("    ");
        auto cmd = readCommand();
        if (cmd.toLower() == ".done") {
            break;
        } else {
            data.headers ~= cmd;
        }
    }
}

void shiftHeaders(CsvData data) {
    data.headersAreVisible = true;
    data.headers = data.data[0];
    data.data = data.data[1 .. $];
}

bool receiveInput(CsvData data) {
    CsvRow row;
    foreach(hd; data.headers) {
        write("    ", hd, ": ");
        auto cmd = readCommand();
        if (cmd.toLower() == ".mistake") {
            fixMistake(data, row);
            break;
        } else if (cmd.toLower() == ".done") {
            return false;
        } else {
            row ~= cmd;
        }
    }
    data.data ~= row;
    return true;
}

void fixMistake(CsvData data, CsvRow buf) {
    warnln("Sorry, mistake doesn't work yet :(");
    return;
    
    if (data.data.empty && buf.empty) {
        warnln("You haven't inputted any data yet!");
        return;
    }
    
    auto table = mistakeTable(data, buf);
    auto letters = ['A', 'B', 'C'];
    foreach(row; table) {
        writeln(row);
        writeln(letters, " ", join(row, "\t"));
        letters.popFront();
    }
    write("Which row do you want to redo? ");
    auto req = readCommand();
}

CsvRow[] mistakeTable(CsvData data, CsvRow row) {
    auto table = data.data ~ row;
    if (table.length > 3) {
        table = table[$-3 .. $];
    }
    return table;
}

void save(CsvData data) {
    if (data.file == "") {
        prompt("What should you save the file as (name OR .nosave)? ");
        auto cmd = readCommand();
        if (cmd.toLower == ".nosave") return;
        data.file = cmd;
    }
    data.writeToFile();
}

void goodBye() {
    writeln("Goodbye!");
    write("Press enter to quit...");
    stdin.readln();
}

class DDIException : Exception {
    this(string msg, bool shouldQuit=false) {
        super("Error: "~msg);
    }
    
    bool shouldQuit;
}

