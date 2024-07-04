module lang::solidity::m3::CyclicDependency

import List;

set[set[loc]] detectCycles(rel[loc, loc] graph, set[loc] nodes) {
    list[loc] visited = [];
    list[loc] stack = [];
    set[set[loc]] cycles = {};

    for (loc \node <- nodes) {
        if (!(\node in visited)) {
            cycles += dfs(\node, graph, visited, stack);
        }
    }

    return cycles;
}

set[set[loc]] dfs(loc \node, rel[loc, loc] graph, list[loc] visited, list[loc] stack) {
    set[set[loc]] cycles = {};
    visited += \node;
    stack += \node;

    for (loc neighbor <- graph[\node]) {
        if (!(neighbor in visited)) {
            cycles += dfs(neighbor, graph, visited, stack);
        } else if (neighbor in stack) {
            list[loc] cycleList = [neighbor] + stack[indexOf(stack, neighbor) .. size(stack)];
            set[loc] cycle = toSet(cycleList);
            cycles += {cycle};
        }
    }
    stack -= \node;
    return cycles;
}