// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBobaVerseArcade {

    enum GameType { Plinko }

    event PlinkoResult(address from, uint256[] ballPositions, uint256 score);
}