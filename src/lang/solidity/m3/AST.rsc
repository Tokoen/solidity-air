module lang::solidity::m3::AST

extend analysis::m3::AST;

import lang::json::IO;
import IO;
import List;
import Node;
import String;

loc sourceLocation;

// Solidity grammar defined in rascal data structures
data Declaration 
    = \pragma(list[str] literals)
    | \import(str path)
    | \contract(str name, list[Declaration] contractBody)
    | \variable(Type \type, str name)
    | \function(str name, Declaration parameters, Declaration returnParameters, Statement functionBody)
    | \function(str name, Declaration parameters, Declaration returnParameters)
    | \event(str name, Declaration eventParameter)
    | \constructor(Declaration parameters, Statement constructorBody)
    | \parameterList(list[Declaration])
    | \struct(str name, list[Declaration] members)
    | \modifier(str name, Declaration parameter, Statement modifierBody)
    | \receive(Statement receiveBody)
    ;

data Expression 
    = \binaryOperation(Expression left, str operator, Expression right)
    | \unaryOperation(Expression expression, str operator)
    | \assignment(Expression lhs, str operator, Expression rhs)
    | \indexAccess(Expression base, Expression index)
    | \memberAccess(Expression expression, str name)
    | \identifier(str name)
    | \functionCall(list[Expression] arguments)
    | \stringLiteral(str stringValue)
    | \numberLiteral(str numberValue)
    | \booleanLiteral(str boolValue)
    | \new(Type \type)
    | \tuple(list[Expression] components)
    | \ElementaryTypeNameExpression(Type \type)
    ;

data Statement 
    = \block(list[Statement] statements)
    | \variableStatement(list[Declaration] declaration, Expression expression)
    | \variableStatement(list[Declaration] declaration) 
    | \expressionStatement(Expression expression)
    | \if(Expression condition, Statement thenBranch)
    | \if(Expression condition, Statement thenBranch, Statement elseBranch)
    | \for(Statement initializer, Expression condition, Statement loopExpression, Statement body)
    | \while(Expression condition, Statement body)
    | \doWhile(Statement do, Expression condition, Statement body)
    | \continue()
    | \break()
    | \return()
    | \return(Expression expression)
    | \revert(Expression expression)
    | \emit(Expression expression)
    | \placeholder()
    | \assembly()
    ;

data Type 
    = \int()
    | \uint()
    | \string()
    | \bytes()
    | \boolean()
    | \address()
    | \mapping(Type keyType, Type valueType)
    | \identifierPath(str identifier)
    | \array(Type \type)
    ;

// Parse location based on JSON AST src field
loc parseLocation(str src){
    // Replace JSON AST file location with Solidity file location
    str astLocation = sourceLocation.path;
    str solLocation = replaceAll(astLocation, "AST.json", ".sol");
    loc codeLocation = |file:///| + solLocation;
    
    // Split up src field
    list[str] parts = split(":", src);
    int offset = toInt(parts[0]);
    int length = toInt(parts[1]);

    return codeLocation(offset, length);
}

// Parse list of declarations
list[Declaration] parseDeclarations(list[node] nodes){
    return [parseDeclaration(declaration) | declaration <- nodes];
}

// Parse declarations based on JSON ast node type
Declaration parseDeclaration(node declaration) { 
    switch(declaration.nodeType){
        case "PragmaDirective": 
            return \pragma(declaration.literals, src=parseLocation(declaration.src));
        case "ContractDefinition": 
            return \contract(declaration.name, parseDeclarations(declaration.nodes), src=parseLocation(declaration.src));
        case "VariableDeclaration":
            return \variable(parseType(declaration.typeName), declaration.name, src=parseLocation(declaration.src));
        case "FunctionDefinition": 
        {
            switch(declaration.kind) {
                case "function":
                {
                    map[str,value] children = getKeywordParameters(declaration);
                    if("body" in children) {
                        return \function(declaration.name, parseDeclaration(declaration.parameters), parseDeclaration(declaration.returnParameters), parseStatement(declaration.body), src=parseLocation(declaration.src));
                    } else {
                        return \function(declaration.name, parseDeclaration(declaration.parameters), parseDeclaration(declaration.returnParameters), src=parseLocation(declaration.src));
                    }
                }
                case "constructor":
                    return \constructor(parseDeclaration(declaration.parameters), parseStatement(declaration.body), src=parseLocation(declaration.src));
                case "receive":
                    return \receive(parseStatement(declaration.body), src=parseLocation(declaration.src));
                default: throw "Unknown function declaration: <declaration.kind>";
            }
        }
        case "EventDefinition":
            return \event(declaration.name, parseDeclaration(declaration.parameters), src=parseLocation(declaration.src));
        case "ParameterList":
            return \parameterList(parseDeclarations(declaration.parameters), src=parseLocation(declaration.src));
        case "StructDefinition":
            return \struct(declaration.name, parseDeclarations(declaration.members), src=parseLocation(declaration.src));
        case "ModifierDefinition":
            return \modifier(declaration.name, parseDeclaration(declaration.parameters), parseStatement(declaration.body), src=parseLocation(declaration.src));
        default: throw "Unknown declaration type: <declaration.nodeType>";
    }
}

list[Expression] parseExpressions(list[node] expressions){
    return [parseExpression(expression) | expression <- expressions];
}

// Parse expressions based on JSON ast node type
Expression parseExpression(node expression){
    switch(expression.nodeType) {
        case "BinaryOperation":
            return \binaryOperation(parseExpression(expression.leftExpression), expression.operator, parseExpression(expression.rightExpression), src=parseLocation(expression.src));
        case "UnaryOperation":
            return unaryOperation(parseExpression(expression.subExpression), expression.operator, src=parseLocation(expression.src));
        case "Assignment":
            return \assignment(parseExpression(expression.leftHandSide), expression.operator, parseExpression(expression.rightHandSide), src=parseLocation(expression.src));
        case "Identifier":
            return \identifier(expression.name, src=parseLocation(expression.src));
        case "FunctionCall":
            return \functionCall(parseExpressions(expression.arguments), src=parseLocation(expression.src));
        case "Literal": 
        {
            switch(expression.kind) {
                case "string":
                    return \stringLiteral(expression.\value, src=parseLocation(expression.src));
                case "number":
                    return \numberLiteral(expression.\value, src=parseLocation(expression.src));
                case "bool":
                    return \booleanLiteral(expression.\value, src=parseLocation(expression.src));
                default: throw "Unknown literal: <expression.kind>";
            }     
        }
        case "MemberAccess":
            return \memberAccess(parseExpression(expression.expression), expression.memberName, src=parseLocation(expression.src));
        case "IndexAccess":
            return \indexAccess(parseExpression(expression.baseExpression), parseExpression(expression.indexExpression), src=parseLocation(expression.src));
        case "TupleExpression":
            return \tuple(parseExpressions(expression.components), src=parseLocation(expression.src));
        case "ElementaryTypeNameExpression":
            return \ElementaryTypeNameExpression(parseType(expression.typeName));
        default: throw "Unknown expression type: <expression.nodeType>";
    }
}

// Parse list of statements
list[Statement] parseStatements(list[node] statements) {
    return [parseStatement(statement) | statement <- statements];
}

// Parse statements based on JSON ast node type.
Statement parseStatement(node statement){
    switch(statement.nodeType) {
        case "Block":
            return \block(parseStatements(statement.statements), src=parseLocation(statement.src));
        case "ExpressionStatement":
            return \expressionStatement(parseExpression(statement.expression), src=parseLocation(statement.src));
        case "VariableDeclarationStatement": 
        {
            map[str,value] children = getKeywordParameters(statement);
            if("initialValue" in children) {
                 return \variableStatement(parseDeclarations(statement.declarations), parseExpression(statement.initialValue), src=parseLocation(statement.src));
            } else {
                 return \variableStatement(parseDeclarations(statement.declarations), src=parseLocation(statement.src));
            }
        }
        case "IfStatement": 
        {   
            map[str,value] children = getKeywordParameters(statement);
            if("falseBody" in children) {
                return \if(parseExpression(statement.condition), parseStatement(statement.trueBody), parseStatement(statement.falseBody), src=parseLocation(statement.src));
            } else {
                return \if(parseExpression(statement.condition), parseStatement(statement.trueBody), src=parseLocation(statement.src));
            }
        }
        case "ForStatement":
            return \for(parseStatement(statement.initializationExpression), parseExpression(statement.condition), parseStatement(statement.loopExpression), parseStatement(statement.body), src=parseLocation(statement.src));
        case "WhileStatement":
            return \while(parseExpression(statement.condition), parseStatement(statement.body), src=parseLocation(statement.src));
        case "Return":
            return \return(parseExpression(statement.expression), src=parseLocation(statement.src));
        case "PlaceholderStatement":
            return \return(src=parseLocation(statement.src));
        case "EmitStatement":
            return \emit(parseExpression(statement.eventCall), src=parseLocation(statement.src));
        case "InlineAssembly":
            return \assembly();
        default: throw "Unknown statement type: <statement.nodeType>";
    }
}

// Parse type based on JSON ast node type.
Type parseType(node \type){
    switch(\type.nodeType) {
        case "ElementaryTypeName":
        {
            switch(\type.name) {
                case /uint[0-9]*/:
                    return \uint();
                case "address":
                    return \address();
                case "bool":
                    return \boolean();
                case "bytes32":
                    return \bytes();
                case "string":
                    return \string();
                default: throw "Unknown ElementaryTypeName: <\type.name>";
            }
        }
        case "Mapping":
            return \mapping(parseType(\type.keyType), parseType(\type.valueType));
        case "UserDefinedTypeName": 
            return parseType(\type.pathNode);
        case "IdentifierPath":
            return \identifierPath(\type.name);
        case "ArrayTypeName":
            return \array(parseType(\type.baseType));
        default: throw "Unknown type: <\type.nodeType>";
    }
}

// Calculate cyclomatic complexity = decision points + 1
int calculateComplexity(list[Declaration] ast) {
    int complexity = 1;
    for (Declaration declaration <- ast) {
        complexity += visitStatements(declaration);
    }
    return complexity;
}

// Visit all the statements to find decision points
int visitStatements(Declaration declaration){
    int count=0;
    switch(declaration) {
        case \function(_,_,_,Statement functionBody): 
            count += countDecisionPoints(functionBody);
        case \contract(_,list[Declaration] contractBody):
            for(Declaration declaration <- contractBody) {
                count += visitStatements(declaration);
            }
        case \constructor(_,Statement constructorBody):
            count+= countDecisionPoints(constructorBody);
        case \modifier(_,_,Statement modifierBody):
            count += countDecisionPoints(modifierBody);
        case \receive(Statement receiveBody):
            count += countDecisionPoints(receiveBody);
    }
    return count;
}

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

list[Declaration] createAST(loc file) {

    // Set location of file
    sourceLocation = file;

    // Read the contents of the json AST
    str jsonAST = readFile(file);

    // Parse json string
    map[str,value] parsedJsonAST = parseJSON(#map[str,value], jsonAST);

    // Extract nodes
    value nodes = parsedJsonAST["nodes"];

    // Make AST
    list[Declaration] ast = parseDeclarations(nodes);

    return ast;
}