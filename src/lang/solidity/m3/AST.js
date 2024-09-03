const solc = require('solc');
const fs = require('fs');
const path = require('path');

// Directory containing Solidity files
if (process.argv.length !== 3) {
    console.error('Usage: node ast.js <path>');
    process.exit(1);
}

const rootDirectoryPath = process.argv[2];

// Function to recursively find all .sol files
function getSolFiles(dirPath, arrayOfFiles) {
    const files = fs.readdirSync(dirPath);

    arrayOfFiles = arrayOfFiles || [];

    files.forEach(file => {
        const fullPath = path.join(dirPath, file);

        if (fs.statSync(fullPath).isDirectory()) {
            arrayOfFiles = getSolFiles(fullPath, arrayOfFiles);
        } else if (path.extname(fullPath) === '.sol') {
            arrayOfFiles.push(fullPath);
        }
    });

    return arrayOfFiles;
}

// Custom import callback to handle file imports
function findImports(importPath) {
    try {
        const importFileName = path.basename(importPath);
        const importFile = solFiles.find(file => path.basename(file) === importFileName);

        if (importFile && fs.existsSync(importFile)) {
            return {
                contents: fs.readFileSync(importFile, 'utf8')
            };
        } else {
            return { error: 'File not found' };
        }
    } catch (error) {
        return { error: error.message };
    }
}

// Get all .sol files in the directory (including nested directories)
const solFiles = getSolFiles(rootDirectoryPath);

solFiles.forEach(filePath => {
    // Load the Solidity file
    const source = fs.readFileSync(filePath, 'utf8');

    // Compile the code and generate the AST
    const input = {
        language: 'Solidity',
        sources: {
            [path.basename(filePath)]: {
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

    const output = JSON.parse(solc.compile(JSON.stringify(input), {
        import: findImports
    }));

    // Check for compilation errors or warnings
    if (output.errors) {
        output.errors.forEach((err) => {
            console.error(err.formattedMessage);
        });
    }

    // Extract the AST
    const ast = output.sources[path.basename(filePath)] ? output.sources[path.basename(filePath)].ast : null;

    if (ast) {
        const outputFileName = path.basename(filePath, '.sol') + 'AST.json';
        const outputFilePath = path.join(path.dirname(filePath), outputFileName);
        fs.writeFileSync(outputFilePath, JSON.stringify(ast, null, 2), 'utf8');
        console.log(`AST has been saved to ${outputFilePath}`);
    } else {
        console.error(`Failed to generate AST for ${filePath}.`);
        console.log('Full output:', JSON.stringify(output, null, 2));
    }
});

// Print the root directory path in rascal format
const formattedRootDirectoryPath = `|file:///${rootDirectoryPath.replace(/\\/g, '/')}|`;
console.log(formattedRootDirectoryPath);
