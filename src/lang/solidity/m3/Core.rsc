module lang::solidity::m3::Core

extend analysis::m3::Core;

import lang::solidity::m3::AST;
import util::FileSystem;
import IO;
import String;

void createM3(loc directory) { // Insert path and change \ to / |file:///<path>|;
    // |file:///C:/Users/tobia/OneDrive/Bureaublad/Github/aave-v3-core|

    set[loc] jsonFiles = find(directory, "json");
    set[loc] jsonASTs = {};

    for(loc file <- jsonFiles) {
        str path = file.path;
        if (endsWith(path, "AST.json")) {
            jsonASTs += file;
        }
    }
    iprintln(jsonASTs);
}
