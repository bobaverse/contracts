// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { EnumerableMapUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableMapUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import { BobaL2TuringClient as TuringClient } from "@dirtycajunrice/contracts/third-party/boba/TuringClient.sol";
import { StandardAccessControl } from "@dirtycajunrice/contracts/utils/access/StandardAccessControl.sol";
import { Numbers } from "@dirtycajunrice/contracts/utils/math/Numbers.sol";

import { BokkyPooBahsDateTimeLibrary } from "./third-party/BokkyPooBahsDateTimeLibrary.sol";
import { IBobaVerseArcade } from "./IBobaVerseArcade.sol";

/**
* @title BobaVerse Arcade v1.0.0
* @author @DirtyCajunRice
*/
contract BobaVerseArcade is
    IBobaVerseArcade,
    Initializable,
    PausableUpgradeable,
    StandardAccessControl,
    ReentrancyGuardUpgradeable,
    TuringClient,
    UUPSUpgradeable
{
    using EnumerableMapUpgradeable for EnumerableMapUpgradeable.AddressToUintMap;
    using BokkyPooBahsDateTimeLibrary for uint256;
    using Numbers for uint256;

    // Game Type => Year => Month => Address => Score
    mapping(GameType => mapping(uint256 => mapping(uint256 => EnumerableMapUpgradeable.AddressToUintMap))) private leaderboards;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __Pausable_init();
        __StandardAccessControl_init();
        __UUPSUpgradeable_init();

        __BobaL2TuringClient_init(
            0x4200000000000000000000000000000000000020,
            0x680e176b2bbdB2336063d0C82961BDB7a52CF13c
        );
    }

    function playPlinko() external whenNotPaused nonReentrant {
        _payTuringFee();
        uint256 random = TuringHelper.Random();
        // 77 digit number can be chunked up to 25 times without remainder
        // first 20 results are used for ball drop locations, 21st result used for final score;
        uint256[] memory chunks = random.chunkUintX(1_000, 21);
        uint256[] memory ballLocations = new uint256[](20);
        for (uint256 i = 0; i < 20; i++) {
            ballLocations[i] = chunks[i] % 100;
        }
        uint256 score = (chunks[20] % 200) + 1;
        uint256 year = block.timestamp.getYear();
        uint256 month = block.timestamp.getMonth();
        (,uint256 lastScore) = leaderboards[GameType.Plinko][year][month].tryGet(msg.sender);
        if (lastScore < score) {
            leaderboards[GameType.Plinko][year][month].set(msg.sender, score);
        }

        emit PlinkoResult(msg.sender, ballLocations, score);
    }

    function getLeaderboardFor(
        GameType gameType,
        uint256 year,
        uint256 month
    ) external view returns (address[] memory addresses, uint256[] memory scores) {
        uint256 len = leaderboards[gameType][year][month].length();
        addresses = new address[](len);
        scores = new uint256[](len);
        for (uint256 i = 0; i > len; i++) {
        (addresses[i], scores[i]) = leaderboards[gameType][year][month].at(i);
        }
    }

    function getLeaderboard(
        GameType gameType
    ) external view returns (address[] memory addresses, uint256[] memory scores) {
        uint256 year = block.timestamp.getYear();
        uint256 month = block.timestamp.getMonth();
        uint256 len = leaderboards[gameType][year][month].length();
        addresses = new address[](len);
        scores = new uint256[](len);
        for (uint256 i = 0; i > len; i++) {
            (addresses[i], scores[i]) = leaderboards[gameType][year][month].at(i);
        }
    }

    function _authorizeUpgrade(address newImplementation) internal virtual override onlyDefaultAdmin {}
}