module lang::solidity::m3::Analysis

import lang::solidity::m3::AST;
import lang::solidity::m3::Complexity;
import lang::solidity::m3::Core;
import lang::solidity::m3::CyclicDependency;
import util::FileSystem;
import IO;
import List;
import Relation;
import Set;

// |file:///C:/Users/tobia/OneDrive/Bureaublad/Github/aave-v3-core|
// |file:///C:/Users/tobia/OneDrive/Bureaublad/Github/openzeppelin-contracts|
// |file:///C:/Users/tobia/OneDrive/Bureaublad/Github/solbase|
// cloc.pl

void complexity(loc directory) { // Insert path and change backward slash \ to forward slash /: |file:///<path>|;
    list[list[Declaration]] rascalASTs = createRascalASTs(directory);
    list[tuple[loc,int]] complexities = createComplexities(rascalASTs);
    println("Amount of functions:<size(complexities)>");
    
    int range = max([x |<_,x> <- complexities]);
    list[int] solComplexity = [0| i <- [0 .. range]];
    for(<_,complexity> <- complexities) {
        solComplexity[complexity-1]+=1;
    }
    println("Complexities of functions:<solComplexity>");
}

void cyclicDependency(loc directory) {
    M3 model = createM3(directory);
    rel[loc,loc] containment = model.containment;
    set[loc] containmentNodes = domain(containment) + range(containment);

    set[set[loc]] containmentCycles = detectCycles(containment, containmentNodes);
    println("Cyclic dependency:");
    iprintln(containmentCycles);

    rel[loc,loc] uses = model.uses;
    set[loc] usesNodes = domain(uses) + range(uses);

    set[set[loc]] importCycles = detectCycles(uses, usesNodes);
    println("Import cycles:");
    iprintln(importCycles);
}

void analyze(loc directory){
    complexity(directory);
    cyclicDependency(directory);
}