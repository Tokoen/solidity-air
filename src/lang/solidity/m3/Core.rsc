module lang::solidity::m3::Core

extend analysis::m3::Core;

import lang::solidity::m3::Analysis;
import lang::solidity::m3::AST;
import lang::solidity::m3::Containment;

// Create M3 model of a directory
M3 createM3(loc directory) { // Insert path and change backward slash \ to forward slash /: |file:///<path>|;
    M3 model = emptyM3(directory);
    list[list[Declaration]] rascalASTs = createRascalASTs(directory);
    model.containment+=buildContainment(rascalASTs);
    return model;
}

/*TO DO: 
- M3 mapping
*/ 
