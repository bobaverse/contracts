// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { EnumerableMapUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableMapUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import { BobaL2TuringClient as TuringClient } from "@dirtycajunrice/contracts/third-party/boba/turing/TuringClient.sol";
import { StandardAccessControl } from "@dirtycajunrice/contracts/utils/access/StandardAccessControl.sol";
import { Numbers } from "@dirtycajunrice/contracts/utils/math/Numbers.sol";

import { BokkyPooBahsDateTimeLibrary } from "./third-party/BokkyPooBahsDateTimeLibrary.sol";
import { IBobaVerseArcade } from "./IBobaVerseArcade.sol";
import { AddressBook } from "./library/AddressBook.sol";

/**
 * @title BobaVerseArcade
 * @author DirtyCajunRice
 * @dev This contract represents a gaming arcade in the blockchain world. The contract allows users
 * to play games and records their high scores.
 *
 * Features:
 * - Users can play Plinko game by calling `playPlinko` method.
 * - High scores are recorded on year, month, and game-type basis.
 * - Leaderboards can be fetched for any specific year, month, and game-type, as well as for
 *   the current year and month by calling `getLeaderboardFor` and `getLeaderboard` methods respectively.
 *
 * This contract inherits from:
 * - `IBobaVerseArcade`
 * - `Initializable`
 * - `PausableUpgradeable`
 * - `StandardAccessControl`
 * - `ReentrancyGuardUpgradeable`
 * - `TuringClient`
 * - `UUPSUpgradeable`
 *
 * Library usage:
 * - `EnumerableMapUpgradeable`
 * - `BokkyPooBahsDateTimeLibrary`
 * - `Numbers`
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
    /**
     * @dev Importing and setting up aliases for multiple libraries.
     *
     * @notice This contract uses three different libraries: EnumerableMapUpgradeable,
     * BokkyPooBahsDateTimeLibrary, and Numbers.
     *
     * - EnumerableMapUpgradeable: This is used for the internal data type `AddressToUintMap`.
     *   All functions from EnumerableMapUpgradeable become available to `AddressToUintMap` instances.
     * - BokkyPooBahsDateTimeLibrary: This library provides advanced features for working with date and time.
     *   All functions from this library become available to `uint256` instances, used to handle timestamp data.
     * - Numbers: This library is used to provide additional functionalities to the `uint256` type.
     */
    using EnumerableMapUpgradeable for EnumerableMapUpgradeable.AddressToUintMap;
    using BokkyPooBahsDateTimeLibrary for uint256;
    using Numbers for uint256;

    /**
     * @notice Nested mapping to store leaderboards data.
     *
     * @dev The `leaderboards` nested mapping carries the following structure:
     * - First level: the game types are mapped to the next level.
     * - Second level: the years are mapped to the next level.
     * - Third level: the months are mapped to `EnumerableMapUpgradeable.AddressToUintMap` which contains
     * address-to-uint pairs, representing a user along with their high score score.
     *
     * This variable is private, which means it's only accessible within the contract it's defined in.
     */
    mapping(GameType gameType =>
        mapping(uint256 year =>
            mapping(uint256 month =>
                EnumerableMapUpgradeable.AddressToUintMap users
            )
        )
    ) private leaderboards;

    /**
     * @dev constructor function
     *
     * It's a special function that gets executed only once during the contract's deployment.
     * This constructor disables future calls to any function that has been marked by the `initializer` modifier.
     *
     * This method uses the `_disableInitializers()` function.
     *
     * @custom:oz-upgrades-unsafe-allow constructor
     */
    constructor() {
        _disableInitializers();
    }

    /**
     * @title Initialize Function
     * @notice This function is used to initialize different types of contracts in the overall contract structure.
     * @dev This function should be called only once, immediately after the contract deployment.
     * Safe to override, as far as the initializer modifier is used to ensure single initialization.
     *
     * Initializes:
     * - Pausable (pauses the contract in case of bugs or flaws).
     * - StandardAccessControl (manages permissions).
     * - UUPSUpgradeable (proxy for upgrading contracts).
     * - BobaL2TuringClient (manages the connection with Turing Credit and Turing Helper services).
     */
    function initialize() public initializer {
        /// @notice Initialize the Pausable contract.
        /// @dev Pausable contracts can be paused and unpause by parties with pauser roles
        /// This is typically used if some critical bug or flaw is discovered.
        __Pausable_init();

        /// @notice Initialize the StandardAccessControl contract.
        /// @dev This contract manages special access and permissions within the contract.
        __StandardAccessControl_init();

        /// @notice Initialize the UUPSUpgradeable contract.
        /// @dev It is a proxy contract that helps to upgrade the implementation contract
        /// without losing state or funds.
        __UUPSUpgradeable_init();

        /// @notice Initialize the BobaL2TuringClient contract.
        /// @dev It manages the connection with the Turing Credit and Turing Helper services
        /// and gets the addresses of Turing Credit and Turing Helper from the address book.
        __BobaL2TuringClient_init(AddressBook.turingCredit(), AddressBook.turingHelper());
    }

    /**
     * @dev Play the Plinko game.
     * This function is payable, which means that it requires sending Ether to work.
     * It works only when the contract is not paused and prevents reentrancy attacks.
     * The function generates a pseudorandom number which is chunked into 21 parts
     * using `chunkUintX` function from TuringHelper contract.
     * The chunked number is used to determine the ball drop locations and the final score.
     * The function checks the leaderboards and updates the highest score.
     * For this purpose, it gets the `block.timestamp` which is converted to year and month.
     * It then tries to get the last score from the leaderboard.
     * If the last score is smaller than the current game score, the leaderboard is updated.
     * Finally, this function emits the `PlinkoResult` event.
     *
     * Restrictions:
     * -The game can be played only if the contract is not paused.
     * -The function is `nonReentrant` to prevent reentrancy attacks.
     * -The player must send an Ether to play this game.
     *
     * Emits:
     * -`PlinkoResult` with the address of the sender, ball locations, and the final score.
     *
     * @notice Requires Ether to play.
     */
    function playPlinko() external payable whenNotPaused nonReentrant {
        _payTuringFee();
        uint256 random = TuringHelper.Random();
        /// 77 digit number can be chunked up to 25 times without remainder
        /// first 20 results are used for ball drop locations, 21st result used for final score;
        uint256[] memory chunks = random.chunkUintX(1_000, 21);
        uint256[] memory ballLocations = new uint256[](20);
        for (uint256 i = 0; i < 20; i++) {
            ballLocations[i] = chunks[i] % 100;
        }
        uint256 score = (chunks[20] % 200) + 1;
        uint256 year = block.timestamp.getYear();
        uint256 month = block.timestamp.getMonth();
        leaderboards[GameType.Plinko][year][month];
        (,uint256 lastScore) = leaderboards[GameType.Plinko][year][month].tryGet(msg.sender);
        if (lastScore < score) {
            leaderboards[GameType.Plinko][year][month].set(msg.sender, score);
        }

        emit PlinkoResult(msg.sender, ballLocations, score);
    }

    /**
     * @title getLeaderboard
     * @dev fetches and returns the leaderboard for a specific game type
     * @param gameType a GameType object that represents the type of game for which the leaderboard is to be obtained
     * @return addresses an array of Ethereum addresses of players ranked in the leaderboard
     * @return scores an array of scores in the same sequence as the addresses, represents the score of each player
     * Note: The length of returned arrays 'addresses' and 'scores' are always identical.
     *
     * The function captures the current year and month from the block.timestamp, and fetches the corresponding
     * leaderboard for the provided 'gameType'.
     * This leaderboard is a list of players (their addresses) and their scores, for the given game type within the
     * current month of the current year.
     * The result is two aligned arrays, one with player addresses and one with their scores.
     */
    function getLeaderboardFor(
        GameType gameType,
        uint256 year,
        uint256 month
    ) external view returns (address[] memory addresses, uint256[] memory scores) {
        uint256 len = leaderboards[gameType][year][month].length();
        addresses = new address[](len);
        scores = new uint256[](len);
        for (uint256 i = 0; i < len; i++) {
            (addresses[i], scores[i]) = leaderboards[gameType][year][month].at(i);
        }
    }

    /**
     * @title getLeaderboard
     * @dev fetches and returns the leaderboard for a specific game type
     * @param gameType a GameType object that represents the type of game for which the leaderboard is to be obtained
     * @return addresses an array of Ethereum addresses of players ranked in the leaderboard
     * @return scores an array of scores in the same sequence as the addresses, represents the score of each player
     * Note: The length of returned arrays 'addresses' and 'scores' are always identical.
     *
     * The function captures the current year and month from the block.timestamp, and fetches the corresponding
     * leaderboard for the provided 'gameType'.
     * This leaderboard is a list of players (their addresses) and their scores, for the given game type within
     * the current month of the current year.
     * The result is two aligned arrays, one with player addresses and one with their scores.
     */
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

    /**
     * @title _authorizeUpgrade
     * @dev callable only by the defaultAdmin.
     * @param newImplementation an address that points to the new implementation of the contract
     *
     * It's part of a contract upgrade mechanism in which the defaultAdmin has the rights to authorize
     * a new implementation of the contract.
     * This function will typically contain logic to perform necessary preparations and assertions before the
     * contract implementation is switched. However, as it is empty here, it will not make any state changes.
     *
     * * Note: This function is part of OpenZeppelin's proxy-based upgradeability system, where `_authorizeUpgrade`
     * is a hook that you can use to add a custom authorization mechanism. By default it is an empty function,
     * because the actual upgradeability control is managed by the ProxyAdmin contract in the OpenZeppelin system.
     * The `onlyDefaultAdmin` modifier signifies that this function is only callable by the admin address.
     */
    function _authorizeUpgrade(address newImplementation) internal virtual override onlyDefaultAdmin {}
}