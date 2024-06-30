module lang::solidity::m3::Core

extend analysis::m3::Core;

import lang::solidity::m3::AST;
import util::FileSystem;
import IO;
import String;
import List;
import Map;
import Set;

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

// Create map of all function locations in a directory paired with its complexity
list[tuple[loc,int]] createComplexities(list[list[Declaration]] rascalASTs) {

    list[tuple[loc,int]] complexities = [];
    for(ast <- rascalASTs) {
       complexities += calculateComplexity(ast); 
    }

    return complexities;
}

// Returns all relations between folders and files in a directory
rel[loc,loc] fileContainment(Declaration declaration) {
    rel[loc, loc] containment = {};
    str folder="", loc1="", loc2 = declaration.src.path;

    while(true){
        int slash = findLast(loc2, "/");
        loc1 = substring(loc2, 0, slash);
        slash = findLast(loc1, "/");
        folder = substring(loc1, slash, size(loc1));
        if(folder == "/Github") {
            break;
        }
        containment += <|file:///| + loc1, |file:///| + loc2>;
        loc2=loc1;
    }
    
    return containment;
}

// Returns all relations between code statements
rel[loc,loc] codeContainment(list[Declaration] ast){
    rel[loc, loc] containment = {};
    return containment;
}

// Returns all relations in a directory 
rel[loc,loc] buildContainment(list[list[Declaration]] rascalASTs) {
    rel[loc, loc] containment = {};
    for(ast <- rascalASTs) {
        containment += fileContainment(ast[0]);
        //containment += codeContainment(ast);
    }
    return containment;
}

// Create M3 model of a directory
M3 createM3(loc directory) { 
    M3 model = emptyM3(directory);
    list[list[Declaration]] rascalASTs = createRascalASTs(directory);
    model.containment+=buildContainment(rascalASTs);
    return model;
}

// |file:///C:/Users/tobia/OneDrive/Bureaublad/Github/aave-v3-core|
/*https://github.com/usethesource/rascal/tree/main/src/org/rascalmpl/library/lang/java/m3*/
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
