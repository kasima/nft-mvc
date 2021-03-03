//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Token.sol";
import "hardhat/console.sol";

contract AmmReserve {
    address public aToken;
    address public bToken;
    address public lpTokenAddress;
    Token lpToken;
    uint256 poolA;
    uint256 poolB;

    function getBReserve() public view returns (uint256){
        return poolB;
    }

    function getAReserve() public view returns (uint256){
        return poolA;
    }

}

contract AmmMVC is AmmReserve {
    using SafeMath for uint256;

    constructor(address _aToken, address _bToken, string memory _lpname, string memory _lpsymbol) public {
        aToken = _aToken;
        bToken = _bToken;
        lpToken= new Token(_lpname, _lpsymbol);
        lpToken= new Token(_lpname, _lpsymbol);
        lpTokenAddress = address(lpToken);
    }

    function addLiquidity(uint256 _aAmount, uint256 _bAmount) public {
        uint256 oldInvariant = getAReserve().mul(getBReserve());
        require(
                SafeMath.mod(oldInvariant, _aAmount.mul(_bAmount) ) == 0,
                "LP inputs is not proportional to the reserves"
                );
        uint256 toMint;
        if (lpToken.totalSupply() == 0) {
            // liquidity provisioned should reflect the total Invariant in the system
            toMint = _aAmount.mul(_bAmount);
        } else {
            uint256 addInvariant = _aAmount.mul(_bAmount);
            uint256 newTotalSupply = addInvariant
                .add(oldInvariant)
                .mul(lpToken.totalSupply())
                .div(oldInvariant);
            toMint = newTotalSupply.sub(lpToken.totalSupply());
        }
        IERC20(aToken).transferFrom(msg.sender, address(this), _aAmount);
        IERC20(bToken).transferFrom(msg.sender, address(this), _bAmount);
        poolA += _aAmount;
        poolB += _bAmount;
        lpToken.mint(msg.sender, toMint);
    }

    function removeLiquidity(uint256 _amount) public {
        lpToken.transferFrom(msg.sender, address(this), _amount);
        uint256 proportion = _amount.div(lpToken.totalSupply());
        uint256 aRemoved = poolA.mul(proportion);
        uint256 bRemoved = poolB.mul(proportion);
        lpToken.burn(_amount);
        poolA -= aRemoved;
        poolB -= bRemoved;
        IERC20(aToken).transfer(msg.sender, aRemoved);
        IERC20(bToken).transfer(msg.sender, bRemoved);
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
        IERC20(bToken).transferFrom(msg.sender, address(this), _bAmount);
        IERC20(aToken).transfer(msg.sender, aOutput);
        poolB += _bAmount;
        poolA -= aOutput;
        return aOutput;
    }

    function swapAtoB(uint256 _aAmount) public returns (uint256) {
        uint256 bOutput = getAtoBOutput(_aAmount);
        IERC20(aToken).transferFrom(msg.sender, address(this), _aAmount);
        IERC20(bToken).transfer(msg.sender, bOutput);
        poolA += _aAmount;
        poolB -= bOutput;
        return bOutput;
    }
}
