module lang::solidity::m3::Containment

import lang::solidity::m3::AST;
import String;
import List;

// Add relation to containment list
rel[loc, loc] addContainment(loc parent, list[loc] children) {
    rel[loc, loc] containment = {};
    for (child <- children) {
        containment += <parent, child>;
    }
    return containment;
}

// Recursively traverse through the AST
rel[loc, loc] traverseAST(value \node, loc parent) {
    rel[loc, loc] containment = {};
    switch(\node) {
        // Declaration containment
        case \pragma(_):
            containment += addContainment(|file:///| + parent.path, [parent]);
        case \import(_):{
            containment += addContainment(|file:///| + parent.path, [parent]);
        }
        case \contract(_, contractBody):{
            containment += addContainment(|file:///| + parent.path, [parent]);
            containment += addContainment(parent, [declaration.src | declaration <- contractBody]);
            for(declaration <- contractBody) {
                containment += traverseAST(declaration, declaration.src);
            }
        }
        case \interface(_, interfaceBody):{
            containment += addContainment(|file:///| + parent.path, [parent]);
            containment += addContainment(parent, [declaration.src | declaration <- interfaceBody]);
            for(declaration <- interfaceBody) {
                containment += traverseAST(declaration, declaration.src);
            }
        }
        case \library(_, libraryBody):{
            containment += addContainment(|file:///| + parent.path, [parent]);
            containment += addContainment(parent, [declaration.src | declaration <- libraryBody]);
            for(declaration <- libraryBody) {
                containment += traverseAST(declaration, declaration.src);
            }
        }
        case \function(_, parameters, returnParameters, functionBody):{
            containment += addContainment(parent, [parameters.src, returnParameters.src, functionBody.src]);
            containment += traverseAST(parameters, parameters.src);
            containment += traverseAST(returnParameters, returnParameters.src);
            containment += traverseAST(functionBody, functionBody.src);
        }
        case \function(_, parameters, returnParameters):{ 
            containment += addContainment(parent, [parameters.src, returnParameters.src]);
            containment += traverseAST(parameters, parameters.src);
            containment += traverseAST(returnParameters, returnParameters.src);
        }
        case \fallback(_, parameters, returnParameters, functionBody):{
            containment += addContainment(parent, [parameters.src, returnParameters.src, functionBody.src]);
            containment += traverseAST(parameters, parameters.src);
            containment += traverseAST(returnParameters, returnParameters.src);
            containment += traverseAST(functionBody, functionBody.src);
        }
        case \event(_, eventParameter):{
            containment += addContainment(parent, [eventParameter.src]);
            containment += traverseAST(eventParameter, eventParameter.src);
        }
        case \constructor(parameters, constructorBody): {
            containment += addContainment(parent, [parameters.src, constructorBody.src]);
            containment += traverseAST(parameters, parameters.src);
            containment += traverseAST(constructorBody, constructorBody.src);
        }
        case \parameterList(parameters):{
            containment += addContainment(parent, [declaration.src | declaration <- parameters]);
            for(declaration <- parameters) {
                containment += traverseAST(declaration, declaration.src);
            }
        }
        case \struct(_, members):{
            containment += addContainment(|file:///| + parent.path, [parent]);
            containment += addContainment(parent, [declaration.src | declaration <- members]);
            for(declaration <- members) {
                containment += traverseAST(declaration, declaration.src);
            }
        }
        case \modifier(_, parameter, modifierBody):{
            containment += addContainment(parent, [parameter.src, modifierBody.src]);
            containment += traverseAST(parameter, parameter.src);
            containment += traverseAST(modifierBody, modifierBody.src);
        }
        case \enum(_, enumMembers):{
            containment += addContainment(|file:///| + parent.path, [parent]);
            containment += addContainment(parent, [expression.src | expression <- enumMembers]);
            for(expression <- enumMembers) {
                containment += traverseAST(expression, expression.src);
            }
        }

        // Expression containment
        case \binaryOperation(left, _, right):{
            containment += addContainment(parent, [left.src, right.src]);
            containment += traverseAST(left, left.src);
            containment += traverseAST(right, right.src);
        }
        case \unaryOperation(expression, _):{
            containment += addContainment(parent, [expression.src]);
            containment += traverseAST(expression, expression.src);
        }
        case \assignment(lhs, _, rhs):{
            containment += addContainment(parent, [lhs.src, rhs.src]);
            containment += traverseAST(lhs, lhs.src);
            containment += traverseAST(rhs, rhs.src);
        }
        case \indexAccess(base, index):{
            containment += addContainment(parent, [base.src, index.src]);
            containment += traverseAST(base, base.src);
            containment += traverseAST(index, index.src);
        }
        case \memberAccess(expression, _):{
            containment += addContainment(parent, [expression.src]);
            containment += traverseAST(expression, expression.src);
        }
        case \functionCall(arguments):{
            containment += addContainment(parent, [expression.src | expression <- arguments]);
            for(expression <- arguments) {
                containment += traverseAST(expression, expression.src);
            }
        }
        case \tuple(components):{
            containment += addContainment(parent, [expression.src | expression <- components]);
            for(expression <- components) {
                containment += traverseAST(expression, expression.src);
            }
        }
        case \conditional(trueExpr, falseExpr):{
            containment += addContainment(parent, [trueExpr.src, falseExpr.src]);
            containment += traverseAST(trueExpr, trueExpr.src);
            containment += traverseAST(falseExpr, falseExpr.src);
        }

        // Statement containment
        case \block(statements):{
            containment += addContainment(parent, [statement.src | statement <- statements]);
            for(statement <- statements) {
                containment += traverseAST(statement, statement.src);
            }
        }
        case \uncheckedBlock(statements):{
            containment += addContainment(parent, [statement.src | statement <- statements]);
            for(statement <- statements) {
                containment += traverseAST(statement, statement.src);
            }
        }
        case \variableStatement(declaration, expression):{
            containment += addContainment(parent, [decl.src | decl <- declaration]);
            for(decl <- declaration) {
                containment += traverseAST(decl, decl.src);
            }
            containment += traverseAST(expression, expression.src);
            containment += addContainment(parent, [expression.src]);  
        }
        case \variableStatement(declaration):{
            containment += addContainment(parent, [decl.src | decl <- declaration]);
            for(decl <- declaration) {
                containment += traverseAST(decl, decl.src);
            }
        }
        case \expressionStatement(expression):{
            containment += addContainment(parent, [expression.src]);
            containment += traverseAST(expression, expression.src);
        }
        case \if(condition, thenBranch):{
            containment += addContainment(parent, [condition.src, thenBranch.src]);
            containment += traverseAST(condition, condition.src);
            containment += traverseAST(thenBranch, thenBranch.src);
        }
        case \if(condition, thenBranch, elseBranch):{
            containment += addContainment(parent, [condition.src, thenBranch.src, elseBranch.src]);
            containment += traverseAST(condition, condition.src);
            containment += traverseAST(thenBranch, thenBranch.src);
            containment += traverseAST(elseBranch, elseBranch.src);
        }
        case \for(initializer, condition, loopExpression, body):{
            containment += addContainment(parent, [initializer.src, condition.src, loopExpression.src, body.src]);
            containment += traverseAST(initializer, initializer.src);
            containment += traverseAST(condition, condition.src);
            containment += traverseAST(loopExpression, loopExpression.src);
            containment += traverseAST(body, body.src);
        }
        case \while(condition, body):{
            containment += addContainment(parent, [condition.src, body.src]);
            containment += traverseAST(condition, condition.src);
            containment += traverseAST(body, body.src);
        }
        case \doWhile(doStmt, condition, body):{
            containment += addContainment(parent, [doStmt.src, condition.src, body.src]);
            containment += traverseAST(doStmt, doStmt.src);
            containment += traverseAST(condition, condition.src);
            containment += traverseAST(body, body.src);
        }
        case \return(expression):{
            containment += addContainment(parent, [expression.src]);
            containment += traverseAST(expression, expression.src);
        }
        case \revert(expression):{
            containment += addContainment(parent, [expression.src]);
            containment += traverseAST(expression, expression.src);
        }
        case \emit(expression):{
            containment += addContainment(parent, [expression.src]);
            containment += traverseAST(expression, expression.src);
        }
    }
    return containment;
}

// Returns all relations between code statements
rel[loc,loc] codeContainment(list[Declaration] ast){
    rel[loc, loc] containment = {};
    for(declaration <- ast) {
        containment += traverseAST(declaration, declaration.src);
    }
    return containment;
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
        // Change "/Github" to the location of which the analysis directory is in
        if(folder == "/Github") {
            break;
        }
        containment += <|file:///| + loc1, |file:///| + loc2>;
        loc2=loc1;
    }
    return containment;
}

// Returns all relations in a directory 
rel[loc,loc] buildContainment(list[list[Declaration]] rascalASTs) {
    rel[loc, loc] containment = {};
    for(ast <- rascalASTs) {
        if(!isEmpty(ast)) {
            containment += fileContainment(ast[0]);
        }
        containment += codeContainment(ast);
    }
    for(relation <- containment) {
        if(relation[0]==relation[1]) {
            containment -= relation;
        }
    }
    return containment;
}