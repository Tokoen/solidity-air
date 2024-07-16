module lang::solidity::m3::Core

extend analysis::m3::Core;

import lang::solidity::m3::AST;
import lang::solidity::m3::Containment;
import lang::solidity::m3::Uses;

// Create M3 model of a directory
M3 createM3(loc directory) { 
    M3 model = emptyM3(directory);
    list[list[Declaration]] rascalASTs = createRascalASTs(directory);
    model.containment+=buildContainment(rascalASTs);
    model.uses+=importUses(rascalASTs);
    return model;
}

