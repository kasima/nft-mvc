//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Token is ERC20 {

    constructor(string memory name, string memory symbol)
        ERC20(name, symbol) public {
    }

    function mint (address receiver, uint256 amount) public {
        _mint(receiver, amount);
    }

    function burn (uint256 amount) public {
        _burn(msg.sender, amount);
    }
}
