module lang::solidity::m3::Complexity

import lang::solidity::m3::AST;

// Count the decision points
int countDecisionPoints(Statement statement) {
    int count=0;
    switch(statement) {
        case \if(_,_):
            count += 1;
        case \if(_,_,_):
            count += 1;
        case \block(list[Statement] statements):
            for(Statement statement <- statements) {
                count += countDecisionPoints(statement);
            }
        case \uncheckedBlock(list[Statement] statements):
            for(Statement statement <- statements) {
                count += countDecisionPoints(statement);
            }
        case \while(_,Statement body):{
            count+=1;
            count+=countDecisionPoints(body);
        }
        case \for(_,_,_,Statement body):{
            count+=1;
            count+=countDecisionPoints(body);
        }
    }
    return count;
}

// Visit all the statements to find decision points
list[tuple[loc,int]] visitDeclarations(Declaration declaration){
    list[tuple[loc,int]] complexities = [];
    switch(declaration) {
        case \function(_,_,_,Statement functionBody, src=location):
        {
            list[tuple[loc,int]] complexity = [<location,countDecisionPoints(functionBody)+1>];
            complexities += complexity;
        } 
        case \contract(_,list[Declaration] contractBody):
            for(Declaration declaration <- contractBody) {
                complexities += visitDeclarations(declaration);
            }
        case \interface(_,list[Declaration] interfaceBody):
            for(Declaration declaration <- interfaceBody) {
                complexities += visitDeclarations(declaration);
            }
        case \library(_,list[Declaration] libraryBody):
            for(Declaration declaration <- libraryBody) {
                complexities += visitDeclarations(declaration);
            }
    }
    return complexities;
}

// Create list of all function locations in a directory paired with its complexity
list[tuple[loc,int]] createComplexities(list[list[Declaration]] rascalASTs) {
    list[tuple[loc,int]] complexities = [];
    for(ast <- rascalASTs) {
       for (declaration <- ast) {
        complexities += visitDeclarations(declaration);
        }
    }
    return complexities;
}