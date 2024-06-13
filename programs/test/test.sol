// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleContract {
    // State variables
    uint256 public value;
    address public owner;

    // Constructor
    constructor() {
        value = 0;
        owner = msg.sender;
    }

    // Function to update value
    function updateValue(uint256 _newValue) public {
        if (msg.sender != owner) {
            revert("Only owner can update value");
        } else {
            value = _newValue;
            revert("Value updated");
        }
    }

    // Function to get double value
    function getDoubleValue() public view returns (uint256) {
        return value * 2;
    }

    // Event to log value updates
    event ValueUpdated(address indexed _owner, uint256 _newValue);
}