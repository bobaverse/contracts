//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title AddressBook
 * @dev This library provides functions to get the address of TuringCredit and TuringHelper contracts
 * on multiple Boba L2 chains including Ethereum (Boba Network), Avalanche (BobaAvax),
 * and Binance Smart Chain (BobaBnb).
 *
 * The library maintains internal constants that store the address of TuringCredit and TuringHelper
 * contracts on each chain. These addresses are returned based on the `block.chainid`. If a chain is not
 * supported, the address `0x0` is returned.
 *
 * @author DirtyCajunRice
 */
library AddressBook {

    /// @dev Address of the TuringCredit contract on Boba's Ethereum L2 (Boba Network).
    address constant internal TuringCreditBobaEth = 0xc8849f32138de93F6097199C5721a9EfD91ceE01;

    /// @dev Address of the TuringCredit contract on Boba's Avalanche L2 (BobaAvax).
    address constant internal TuringCreditBobaAvax = 0x4200000000000000000000000000000000000020;

    /// @dev Address of the TuringCredit contract on Boba's Binance Smart Chain L2 (BobaBnb).
    address constant internal TuringCreditBobaBnb = 0x4200000000000000000000000000000000000020;

    /// @dev Address of the TuringHelper contract on Boba's Ethereum L2 (Boba Network).
    address constant internal TuringHelperBobaEth = 0x5c1b6dba534fB4E1828278C9d9d6Fa1B15A67dB8;

    /// @dev Address of the TuringHelper contract on Boba's Avalanche L2 (BobaAvax).
    address constant internal TuringHelperBobaAvax = 0xe6e44a9F71940b13C44CC3782528E52B611dD1f4;

    /// @dev Address of the TuringHelper contract on Boba's Binance Smart Chain L2 (BobaBnb).
    address constant internal TuringHelperBobaBnb = 0xa0830985871c69c5F4788A6f95B3a238e2Bb8afC;

    /**
     * @dev Returns the address of TuringCredit contract based on chain ID.
     * If the chain is not supported, returns address 0x0.
     *
     * @return The address of TuringCredit contract on the current chain.
     */
    function turingCredit() internal view returns (address) {
        if (block.chainid == 288) return TuringCreditBobaEth;
        if (block.chainid == 43_288) return TuringCreditBobaAvax;
        if (block.chainid == 56_288) return TuringCreditBobaBnb;
        return address(0);
    }

    /**
     * @dev Returns the address of TuringHelper contract based on chain ID.
     * If the chain is not supported, returns address 0x0.
     *
     * @return The address of TuringHelper contract on the current chain.
     */
    function turingHelper() internal view returns (address) {
        if (block.chainid == 288) return TuringHelperBobaEth;
        if (block.chainid == 43_288) return TuringHelperBobaAvax;
        if (block.chainid == 56_288) return TuringHelperBobaBnb;
        return address(0);
    }
}