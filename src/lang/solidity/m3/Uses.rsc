module lang::solidity::m3::Uses

import lang::solidity::m3::AST;
import String;
import List;

loc getImportLocation(loc parent, str path){
    int backTrack = size(findAll(path, "./"))+1;
    str importLocation = parent.path;
    for(int i <- [1 .. backTrack]){
        int slash = findLast(importLocation, "/");
        importLocation = substring(importLocation, 0, slash);
    }
    importLocation = importLocation + "/" + replaceAll(replaceAll(path, "../", ""), "./" , "");
    return |file:///| + importLocation;
}

rel[loc, loc] addImport(value \node, loc parent) {
    rel[loc, loc] uses = {};
    switch(\node) {
        case \import(path):{
            loc importLocation = getImportLocation(parent, path);
            uses += <|file:///| + parent.path, importLocation>;
        }
    }
    return uses;
}

// Returns all relations in a directory 
rel[loc,loc] importUses(list[list[Declaration]] rascalASTs) {
    rel[loc, loc] uses = {};
    for(ast <- rascalASTs) {
        for(declaration <- ast) {
            uses += addImport(declaration, declaration.src);
        }
    }
    return uses;
}