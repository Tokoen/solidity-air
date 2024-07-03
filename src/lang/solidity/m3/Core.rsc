module lang::solidity::m3::Core

extend analysis::m3::Core;

import lang::solidity::m3::AST;
import lang::solidity::m3::Containment;
import util::FileSystem;
import IO;
import String;
import List;
import Map;
import Set;

// Create map of all function locations in a directory paired with its complexity
list[tuple[loc,int]] createComplexities(list[list[Declaration]] rascalASTs) {
    list[tuple[loc,int]] complexities = [];
    for(ast <- rascalASTs) {
       complexities += calculateComplexity(ast); 
    }
    return complexities;
}

// Convert JSON ASTs to rascal data structures
list[list[Declaration]] createRascalASTs(loc directory){

    // Find all JSON files in directory
    set[loc] jsonFiles = find(directory, "json");
    list[loc] jsonASTs = [];

    // Find all ASTs
    for(loc file <- jsonFiles) {
        str path = file.path;
        if (endsWith(path, "AST.json")) {
            jsonASTs += file;
        }
    }
    jsonASTs -= |file:///C:/Users/tobia/OneDrive/Bureaublad/Github/aave-v3-core/contracts/protocol/configuration/PriceOracleSentinelAST.json|;
    jsonASTs -= |file:///C:/Users/tobia/OneDrive/Bureaublad/Github/aave-v3-core/contracts/dependencies/openzeppelin/upgradeability/BaseAdminUpgradeabilityProxyAST.json|;
    jsonASTs -= |file:///C:/Users/tobia/OneDrive/Bureaublad/Github/aave-v3-core/contracts/protocol/tokenization/StableDebtTokenAST.json|;
    jsonASTs -= |file:///C:/Users/tobia/OneDrive/Bureaublad/Github/aave-v3-core/contracts/dependencies/openzeppelin/contracts/AddressAST.json|;
    jsonASTs -= |file:///C:/Users/tobia/OneDrive/Bureaublad/Github/aave-v3-core/contracts/dependencies/openzeppelin/upgradeability/UpgradeabilityProxyAST.json|;
    jsonASTs -= |file:///C:/Users/tobia/OneDrive/Bureaublad/Github/aave-v3-core/contracts/misc/AaveProtocolDataProviderAST.json|;
    jsonASTs -= |file:///C:/Users/tobia/OneDrive/Bureaublad/Github/aave-v3-core/contracts/dependencies/openzeppelin/upgradeability/InitializableUpgradeabilityProxyAST.json|;
    jsonASTs -= |file:///C:/Users/tobia/OneDrive/Bureaublad/Github/aave-v3-core/contracts/protocol/libraries/logic/IsolationModeLogicAST.json|;
    jsonASTs -= |file:///C:/Users/tobia/OneDrive/Bureaublad/Github/aave-v3-core/contracts/protocol/libraries/aave-upgradeability/BaseImmutableAdminUpgradeabilityProxyAST.json|;

    // Create list of rascal ASTs
    list[list[Declaration]] rascalASTs = [];
    for(jsonAST <- jsonASTs) {
        println("Currently parsing: <jsonAST>");
        rascalASTs += [createAST(jsonAST)];
    }

    return rascalASTs;
}

// Create M3 model of a directory
M3 createM3(loc directory) { 
    M3 model = emptyM3(directory);
    list[list[Declaration]] rascalASTs = createRascalASTs(directory);
    model.containment+=buildContainment(rascalASTs);
    return model;
}

// |file:///C:/Users/tobia/OneDrive/Bureaublad/Github/aave-v3-core|
void main(loc directory) { // Insert path and change backward slash \ to forward slash /: |file:///<path>|;
    list[list[Declaration]] rascalASTs = createRascalASTs(directory);
    list[tuple[loc,int]] complexities = createComplexities(rascalASTs);
    println("Amount of functions:<size(complexities)>");
    list[int] solComplexity = [0| i <- range(toMap(complexities))];
    for(<_,complexity> <- complexities) {
        solComplexity[complexity-1]+=1;
    }
    println("Complexities of functions:<solComplexity>");
}

/*TO DO: 
- M3 mapping
*/ 
