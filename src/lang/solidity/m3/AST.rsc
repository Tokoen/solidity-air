module lang::solidity::m3::AST

extend analysis::m3::AST;

import lang::json::IO;
import IO;
import List;
import Node;

// Solidity grammar defined in rascal data structures
data Declaration 
    = \pragma(list[str] literals)
    | \import(str path)
    | \contract(str name, list[Declaration] contractBody)
    | \variable(Type \type, str name)
    | \function(str name, Declaration parameters, str visibility, str stateMutability, Declaration returnParameters, Statement functionBody)
    | \event(str name, Declaration eventParameter)
    | \constructor(Declaration parameters, Statement constructorBody)
    | \parameterList(list[Declaration])
    ;

data Expression 
    = \binaryOperation(Expression left, str operator, Expression right)
    | \assignment(Expression lhs, str operator, Expression rhs)
    | \memberAccess(Expression expression, str name)
    | \identifier(str name)
    | \functionCall(list[Expression] arguments)
    | \stringLiteral(str stringValue)
    | \numberLiteral(str numberValue)
    | \booleanLiteral(bool boolValue)
    | \type(Type \type)
    | \postfix(Expression operand, str operator)
    | \prefix(str operator, Expression operand)
    | \new(Type \type)
    | \tuple(list[Expression] elements)
    ;

data Statement 
    = \block(list[Statement] statements)
    | \variableStatement(Declaration declaration, Expression expression)
    | \expressionStatement(Expression expression)
    | \if(Expression condition, Statement thenBranch)
    | \if(Expression condition, Statement thenBranch, Statement elseBranch)
    | \for(list[Expression] initializers, list[Expression] updaters, Statement body)
    | \for(list[Expression] initializers, Expression condition, list[Expression] updaters, Statement body)
    | \while(Expression condition, Statement body)
    | \doWhile(Statement do, Expression condition, Statement body)
    | \continue()
    | \break()
    | \return()
    | \return(Expression expression)
    | \revert(Expression expression)
    | \emit(Expression expression)
    ;

data Type 
    = \int()
    | \uint()
    | \string()
    | \bytes()
    | \boolean()
    | \address()
    ;

// Parse list of declarations
list[Declaration] parseNodes(list[node] nodes){
    return [parseDeclaration(declaration) | declaration <- nodes];
}

// Parse declarations based on JSON ast node type
Declaration parseDeclaration(node declaration) { 
    switch(declaration.nodeType){
        case "PragmaDirective": 
            return \pragma(declaration.literals);
        case "ContractDefinition": 
            return \contract(declaration.name, parseNodes(declaration.nodes));
        case "VariableDeclaration":
            return \variable(parseType(declaration.typeName), declaration.name);
        case "FunctionDefinition": 
        {
                if(declaration.kind == "constructor") {
                    return \constructor(parseDeclaration(declaration.parameters), parseStatement(declaration.body));
                } else {
                    return \function(declaration.name, parseDeclaration(declaration.parameters), declaration.visibility, 
                    declaration.stateMutability, parseDeclaration(declaration.returnParameters), parseStatement(declaration.body));
                }
        }
        case "EventDefinition":
            return \event(declaration.name, parseDeclaration(declaration.parameters));
        case "ParameterList":
            return \parameterList(parseNodes(declaration.parameters));
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
            return \binaryOperation(parseExpression(expression.leftExpression), expression.operator, parseExpression(expression.rightExpression));
        case "Assignment":
            return \assignment(parseExpression(expression.leftHandSide), expression.operator, parseExpression(expression.rightHandSide));
        case "Identifier":
            return \identifier(expression.name);
        case "FunctionCall":
            return \functionCall(parseExpressions(expression.arguments));
        case "Literal": 
        {
            if(expression.kind == "number") {
                return \numberLiteral(expression.\value);
            } else if (expression.kind == "boolean") {
                return \booleanLiteral(expression.\value);
            } else {
                return \stringLiteral(expression.\value);
            }     
        }
        case "MemberAccess":
            return \memberAccess(parseExpression(expression.expression), expression.memberName);
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
            return \block(parseStatements(statement.statements));
        case "ExpressionStatement":
            return \expressionStatement(parseExpression(statement.expression));
        case "IfStatement": 
        {   
            map[str,value] children = getKeywordParameters(statement);
            if("falseBody" in children) {
                return \if(parseExpression(statement.condition), parseStatement(statement.trueBody), parseStatement(statement.falseBody));
            } else {
                return \if(parseExpression(statement.condition), parseStatement(statement.trueBody));
            }
        }
        case "Return":
            return \return(parseExpression(statement.expression));
        default: throw "Unknown statement type: <statement.nodeType>";
    }
}

// Parse type based on JSON ast node type.
Type parseType(node \type){
    switch(\type.name) {
        case "uint256": 
            return \uint();
        case "address":
            return \address();
        default: throw "Unknown type: <\type.name>";
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
        case \function(_,_,_,_,_,Statement functionBody): 
            count += countDecisionPoints(functionBody);
        case \contract(_,list[Declaration] contractBody):
            for(Declaration declaration <- contractBody) {
                count += visitStatements(declaration);
            }
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
    }
    return count;
}

void main() {

    // Read the contents of the json AST
    str jsonAST = readFile(|project://Solidity-air/programs/testAST.json|);

    // Parse json string
    map[str,value] parsedJsonAST = parseJSON(#map[str,value], jsonAST);

    // Extract nodes
    value nodes = parsedJsonAST["nodes"];

    // Make AST
    list[Declaration] ast = parseNodes(nodes);

    // Print AST
    iprintln(ast);

    // Calculate complexity
    int complexity = calculateComplexity(ast);
    println("Cyclomatic complexity: <complexity>");

}

/* TO DO:
- add sources
- extend grammar, parser and complexity calculator
*/