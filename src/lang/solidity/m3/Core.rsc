module lang::solidity::m3::Core

extend analysis::m3::Core;

import lang::solidity::m3::AST;
import util::FileSystem;
import IO;
import String;
import List;

void createM3(loc directory) { // Insert path and change backward slash \ to forward slash /: |file:///<path>|;

    // |file:///C:/Users/tobia/OneDrive/Bureaublad/Github/aave-v3-core|

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

    /* Error: |std:///lang/json/IO.rsc|(2599,303,<49,0>,<52,144>): IO("NPE")
        at *** somewhere ***(|std:///lang/json/IO.rsc|(2599,303,<49,0>,<52,144>))
        at parseJSON(|std:///lang/json/IO.rsc|(2895,5,<52,137>,<52,142>)) */
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
    int count = 0;
    for(jsonAST <- jsonASTs) {
        println("Currently parsing: <jsonAST>");
        rascalASTs += [createAST(jsonAST)];
        count += 1;
    }
    println("Amount of programs: <count>");

    list[int] complexities=[0 | i <- [0..20]];
    for(rascalAST <- rascalASTs){
        int complexity = calculateComplexity(rascalAST);
        complexities[complexity]+=1;
    }
    println(complexities);
}

/*TO DO: 
- Global variable in AST?
- Null error 
- Complexity graph
- M3 mapping
*/ 