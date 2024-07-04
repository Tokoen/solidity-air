module lang::solidity::m3::Analysis

import lang::solidity::m3::AST;
import lang::solidity::m3::Complexity;
import lang::solidity::m3::Core;
import lang::solidity::m3::CyclicDependency;
import util::FileSystem;
import IO;
import List;
import Map;
import Relation;

// |file:///C:/Users/tobia/OneDrive/Bureaublad/Github/aave-v3-core|

void complexity(loc directory) { // Insert path and change backward slash \ to forward slash /: |file:///<path>|;
    list[list[Declaration]] rascalASTs = createRascalASTs(directory);
    list[tuple[loc,int]] complexities = createComplexities(rascalASTs);
    println("Amount of functions:<size(complexities)>");

    list[int] solComplexity = [0| i <- range(toMap(complexities))];
    for(<_,complexity> <- complexities) {
        solComplexity[complexity-1]+=1;
    }
    println("Complexities of functions:<solComplexity>");
}

void cyclicDependency(loc directory) {
    M3 model = createM3(directory);
    rel[loc,loc] containment = model.containment;
    //To prove it works:
    containment += <|file:///C:/Users/tobia/OneDrive/Bureaublad/Github/aave-v3-core/contracts/protocol/libraries/aave-upgradeability/InitializableImmutableAdminUpgradeabilityProxy.sol|(939,155),|file:///C:/Users/tobia/OneDrive/Bureaublad/Github/aave-v3-core/contracts/protocol/libraries/aave-upgradeability/InitializableImmutableAdminUpgradeabilityProxy.sol|>;
    set[loc] nodes = domain(containment) + range(containment);

    set[set[loc]] cycles = detectCycles(containment, nodes);
    println("Cycles:");
    iprintln(cycles);
}