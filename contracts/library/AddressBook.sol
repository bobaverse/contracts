//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library AddressBook {
    address constant internal TuringCreditBobaEth = 0xc8849f32138de93F6097199C5721a9EfD91ceE01;
    address constant internal TuringCreditBobaOpera = 0x4200000000000000000000000000000000000020;
    address constant internal TuringCreditBobaAvax = 0x4200000000000000000000000000000000000020;
    address constant internal TuringCreditBobaBnb = 0x4200000000000000000000000000000000000020;

    address constant internal TuringHelperBobaEth = 0x5c1b6dba534fB4E1828278C9d9d6Fa1B15A67dB8;
    address constant internal TuringHelperBobaOpera = 0x0000000000000000000000000000000000000000;
    address constant internal TuringHelperBobaAvax = 0xe6e44a9F71940b13C44CC3782528E52B611dD1f4;
    address constant internal TuringHelperBobaBnb = 0xa0830985871c69c5F4788A6f95B3a238e2Bb8afC;

    function turingCredit() internal view returns (address) {
        if (block.chainid == 288) return TuringCreditBobaEth;
        if (block.chainid == 301) return TuringCreditBobaOpera;
        if (block.chainid == 43_288) return TuringCreditBobaAvax;
        if (block.chainid == 56_288) return TuringCreditBobaBnb;
        return address(0);
    }

    function turingHelper() internal view returns (address) {
        if (block.chainid == 288) return TuringHelperBobaEth;
        if (block.chainid == 301) return TuringHelperBobaOpera;
        if (block.chainid == 43_288) return TuringHelperBobaAvax;
        if (block.chainid == 56_288) return TuringHelperBobaBnb;
        return address(0);
    }
}
