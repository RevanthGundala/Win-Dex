// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./WinPair.sol";

error WinDex__IdenticalAddress(address tokenA, address tokenB);
error WinDex__PairAlreadyExists(address pair);
error WinDex__PairDoesNotExist(address pair);
error WinDex__ZeroAddress(address token);

contract WinFactory {
    // maps two token addresses to a pair address
    mapping(address => mapping(address => address)) public s_tokenPairing;

    // an array of pair addresses
    address[] private s_liquidityPool;

    // pair address is mapped to true or false if it exists or not
    mapping(address => bool) private s_pairExists;

    /* Events */
    event pairingCreated(
        address indexed tokenA,
        address indexed tokenB,
        address pair
    );
    event pairingDeleted(address indexed pair);

    // Creates a liquidity pool/pairing between two tokens
    function createNewPairing(address tokenA, address tokenB)
        external
        returns (address pair)
    {
        // require statements
        checkTokens(tokenA, tokenB);
        checkPairAlreadyExists(s_tokenPairing[tokenA][tokenB]);

        // calculating the address for the pair contract
        bytes memory bytecode = type(WinPair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(tokenA, tokenB));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        // updating the mappings with the pair address
        s_tokenPairing[tokenA][tokenB] = pair;
        s_tokenPairing[tokenB][tokenA] = pair;
        s_pairExists[pair] = true;

        // adding the pair to the liquidity pool array
        s_liquidityPool.push(pair);

        // emit the pairing created event
        emit pairingCreated(tokenA, tokenB, pair);

        // return the pair address
        return pair;
    }

    // deletes a pairing between two tokens
    function deletePairing(address _pair) external {
        // require statements
        checkPairDoesNotExist(_pair);

        // iterate through the liquidity pool array to find the index where the pair is stored
        for (uint i = 0; i < s_liquidityPool.length; i++) {
            if (_pair == s_liquidityPool[i]) {
                // delete the pair address from the array
                delete s_liquidityPool[i];

                // take a copy of the last element in the array and place it into the index
                // where the pair was deleted to fill in the gap
                address token_pair = s_liquidityPool[
                    s_liquidityPool.length - 1
                ];
                s_liquidityPool[i] = token_pair;

                // remove the last element in the array
                s_liquidityPool.pop();

                // emit the pairing deleted event
                emit pairingDeleted(_pair);
            }
        }
    }

    // return the number of pairs in the liquidity pool array
    function getNumPairs() external view returns (uint) {
        return s_liquidityPool.length;
    }

    // return the address of a specific pair in the liquidity pool array
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address)
    {
        // require statements
        checkTokens(tokenA, tokenB);
        checkPairDoesNotExist(s_tokenPairing[tokenA][tokenB]);

        // return the pair address that corresponds to the tokens
        return s_tokenPairing[tokenA][tokenB];
    }

    // should make sure tokens are valid addresses
    function checkTokens(address tokenA, address tokenB) internal pure {
        if (tokenA == address(0)) {
            revert WinDex__ZeroAddress(tokenA);
        }
        if (tokenB == address(0)) {
            revert WinDex__ZeroAddress(tokenB);
        }
        if (tokenA == tokenB) {
            revert WinDex__IdenticalAddress(tokenA, tokenB);
        }
    }

    // should make sure that the pair does not exist
    function checkPairDoesNotExist(address _pair) internal view {
        if (!s_pairExists[_pair]) {
            revert WinDex__PairDoesNotExist(_pair);
        }
    }

    // should make sure that the pair exists
    function checkPairAlreadyExists(address _pair) internal view {
        if (s_pairExists[_pair]) {
            revert WinDex__PairAlreadyExists(_pair);
        }
    }
}
