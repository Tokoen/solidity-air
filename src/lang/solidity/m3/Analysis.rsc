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

// Calculates the complexities of the functions in Solidity programs
void complexity(loc directory) { 
    list[list[Declaration]] rascalASTs = createRascalASTs(directory);

    // Create list of tuples with location of function and its cyclomatic complexity
    list[tuple[loc,int]] complexities = createComplexities(rascalASTs);
    println("Amount of functions:<size(complexities)>");
    
    // Extract the complexities and add to count in list
    int range = max([x |<_,x> <- complexities]);
    list[int] solComplexity = [0| i <- [0 .. range]];
    for(<_,complexity> <- complexities) {
        solComplexity[complexity-1]+=1;
    }
    println("Complexities of functions:<solComplexity>");
}

// Detect cyclic dependencies in Solidity programs
void cyclicDependency(loc directory) {
    // Create M3 model and retrieve containment
    M3 model = createM3(directory);
    rel[loc,loc] containment = model.containment;
    set[loc] containmentNodes = domain(containment) + range(containment);

    // Detect cyclic dependencies between code declarations
    set[set[loc]] containmentCycles = detectCycles(containment, containmentNodes);
    println("Cyclic dependency:");
    iprintln(containmentCycles);

    // Retrieve import uses
    rel[loc,loc] uses = model.uses;
    set[loc] usesNodes = domain(uses) + range(uses);

    // Detect cyclic dependencies between import declarations
    set[set[loc]] importCycles = detectCycles(uses, usesNodes);
    println("Import cycles:");
    iprintln(importCycles);
}

// Call all analysis functions
void analyze(loc directory){
    complexity(directory);
    cyclicDependency(directory);
}