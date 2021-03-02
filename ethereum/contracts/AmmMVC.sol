//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
/* import "hardhat/console.sol"; */

interface IAmmMVC {
    function swapAtoB(uint256 _aAmount) external returns (uint256);

    function swapBtoA(uint256 _bAmount) external returns (uint256);

    function getBtoAOutput(uint256 _bAmount) external returns (uint256);

    function getAtoBOutput(uint256 _aAmount) external returns (uint256);
}

contract AmmReserve {
    address tokenA;
    address tokenB;

    function getBReserve() public view returns (uint256){
        return IERC20(tokenB).balanceOf(address(this));
    }

    function getAReserve() public view returns (uint256){
        return IERC20(tokenA).balanceOf(address(this));
    }

    // TODO: hack to manually add liquidity reserve for now
    function setAReserve(uint256 _amount) public returns (bool) {
        return IERC20(tokenA).transferFrom(msg.sender, address(this), _amount);
    }

    // TODO: hack to manually add liquidity reserve for now
    function setBReserve(uint256 _amount) public returns (bool) {
        return IERC20(tokenB).transferFrom(msg.sender, address(this), _amount);
    }

}

contract AmmMVC is AmmReserve {
    using SafeMath for uint256;

    constructor(address _tokenA, address _tokenB) public {
        tokenA = _tokenA;
        tokenB = _tokenB;
    }

    function getBtoAOutput(uint256 _bAmount) public view returns (uint256) {
        uint256 invarient = getAReserve().mul(getBReserve());
        uint256 newAReserve = invarient.div(getBReserve().add(_bAmount));
        return getAReserve().sub(newAReserve);
    }

    function getAtoBOutput(uint256 _aAmount) public view returns (uint256) {
        uint256 invarient = getAReserve().mul(getBReserve());
        uint256 newBReserve = invarient.div(getAReserve().add(_aAmount));
        return getBReserve().sub(newBReserve);
    }

    function swapBtoA(uint256 _bAmount) public returns (uint256) {
        uint256 aOutput = getBtoAOutput(_bAmount);
        IERC20(tokenB).transferFrom(msg.sender, address(this), _bAmount);
        IERC20(tokenA).transfer(msg.sender, aOutput);
        return aOutput;
    }

    function swapAtoB(uint256 _aAmount) public returns (uint256) {
        uint256 bOutput = getAtoBOutput(_aAmount);
        IERC20(tokenA).transferFrom(msg.sender, address(this), _aAmount);
        IERC20(tokenB).transfer(msg.sender, bOutput);
        return bOutput;
    }
}
