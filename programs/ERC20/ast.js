const solc = require('solc');
const fs = require('fs');

// Load the Solidity file
const source = fs.readFileSync('MyERC20Token.sol', 'utf8');

// Compile the code and generate the AST
const input = {
    language: 'Solidity',
    sources: {
        'MyERC20Token.sol': {
            content: source
        }
    },
    settings: {
        outputSelection: {
            '*': {
                '': ['ast']
            }
        }
    }
};

const output = JSON.parse(solc.compile(JSON.stringify(input)));

// Check for compilation errors or warnings
if (output.errors) {
    output.errors.forEach((err) => {
        console.error(err.formattedMessage);
    });
}

// Extract the AST
const ast = output.sources['MyERC20Token.sol'] ? output.sources['MyERC20Token.sol'].ast : null;

if (ast) {
    console.log(JSON.stringify(ast, null, 2));

    // Optionally, save the AST to a file
    fs.writeFileSync('MyERC20TokenAST.json', JSON.stringify(ast, null, 2), 'utf8');
    console.log('AST has been saved to MyERC20TokenAST.json');
} else {
    console.error('Failed to generate AST.');
    console.log('Full output:', JSON.stringify(output, null, 2));
}
