module lang::solidity::m3::Core

extend analysis::m3::Core;

import lang::solidity::m3::AST;
import util::FileSystem;
import IO;
import String;
import Set;

void createM3(loc directory) { // Insert path and change backward slash \ to forward slash /: |file:///<path>|;

    // |file:///C:/Users/tobia/OneDrive/Bureaublad/Github/aave-v3-core|

    set[loc] jsonFiles = find(directory, "json");
    set[loc] jsonASTs = {};

    for(loc file <- jsonFiles) {
        str path = file.path;
        if (endsWith(path, "AST.json")) {
            jsonASTs += file;
        }
    }
    //iprintln(jsonASTs);

    list[loc] ASTList = toList(jsonASTs);

    list[Declaration] ast = createAST(ASTList[0]);

    iprintln(ast);
}
