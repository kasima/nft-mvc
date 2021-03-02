//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Token is ERC20 {

    constructor(string memory name, string memory symbol)
        ERC20(name, symbol) public {
    }

    function mint (uint256 _amount) public {
        _mint(msg.sender, _amount);
    }
}
