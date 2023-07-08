// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IBobaVerseArcade
 * @dev This is an interface specifying the functionalities that need to be implemented
 *      for interacting with a BobaVerseArcade.
 *
 * A contract that implements this interface can participate in the BobaVerse gaming ecosystem,
 * which includes game types like 'Plinko', and can emit events to broadcast game results.
 *
 * @author DirtyCajunRice
 */
interface IBobaVerseArcade {

    /**
     * @dev Enum representing the list of supported game types in the BobaVerse gaming ecosystem.
     * - Plinko: Represents the Plinko game.
     */
    enum GameType { Plinko }

    /**
     * @dev Event emitted when a game of Plinko concludes.
     *
     * The address of the player, the positions of the balls, and the final score are included
     * as part of the event when it's emitted.
     *
     * @param from The address of player who played the game.
     * @param ballPositions An array representing the positions of the balls dropped during the game.
     * @param score The final score achieved by the player.
     */
    event PlinkoResult(address from, uint256[] ballPositions, uint256 score);
}