//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../AmmMVC.sol";

contract AmmMVCMocked is AmmMVC {
    using SafeMath for uint256;
    constructor(address _aToken,
                address _bToken,
                string memory _lpname,
                string memory _lpsymbol)
        AmmMVC(_aToken, _bToken, _lpname, _lpsymbol){
    }

    //burn and reduce a reserve
    function mockReduceAReserve(uint256 _amount) public {
        _setAReserve(getAReserve().sub(_amount));
    }

    //burn and reduce b reserve
    function mockReduceBReserve(uint256 _amount) public {
        _setBReserve(getBReserve().sub(_amount));
    }

    function setReserves(uint256 _aAmount, uint256 _bAmount) public {
        _setAReserve(_aAmount);
        _setBReserve(_bAmount);
    }

}
