//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.0;
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./AmmMVC.sol";

// @title AMMMVC Factory
// @notice factory contract that deploys new AMMMVC implementation
contract AmmMVCFactory {
    using SafeMath for uint256;

    string public constant name = "AMMMVC LP";
    string public constant symbol = "AMMMVC-LP";

    struct tokenPair {
        address tokenA;
        address tokenB;
    }

    mapping (address => tokenPair) public addressToTokenPair;
    mapping (address => mapping(address => bool)) public pairExists;

    event TokenPairCreated(address pair, address indexed tokenA, address indexed tokenB);

    //@notice create and return an address of the token pair
    //@dev the pair must not exist
    //@param _aToken address of A token
    //@param _bToken address of B token
    function createTokenPair(address _aToken, address _bToken) public returns (address _pair) {
        require(_aToken != address(0) && _bToken != address(0), "AmmMVCFactory: invalid address");
        require(
                !pairExists[_aToken][_bToken] || !pairExists[_bToken][_aToken],
                "AmmMVCFactory: pair already exists"
                );
        AmmMVC ammmvc = new AmmMVC(_aToken, _bToken, name, symbol);
        _pair = address(ammmvc);
        addressToTokenPair[_pair] = tokenPair(_aToken, _bToken);
        pairExists[_aToken][_bToken] = true;
        pairExists[_bToken][_aToken] = true;
        emit TokenPairCreated(_pair, _aToken, _bToken);
    }
}
