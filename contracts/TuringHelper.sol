//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { UUPSUpgradeable, Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { IERC165Upgradeable } from "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import { IBobaTuringCredit } from "@dirtycajunrice/contracts/third-party/boba/turing/IBobaTuringCredit.sol";
import { StandardAccessControl } from "@dirtycajunrice/contracts/utils/access/StandardAccessControl.sol";
import { ITuringHelper } from "@dirtycajunrice/contracts/third-party/boba/turing/ITuringHelper.sol";

import { AddressBook } from "./library/AddressBook.sol";

/**
 * @title TuringHelper
 * @dev This contract acts as an interface for interacting with off-chain Turing system.
 * It provides off-chain random number generation and API call capabilities through a deterministic interface.
 * This contract also integrates with the Boba Network's Turing Credit system for billing the off-chain calls.
 *
 * The contract includes safety measures such as Pausable which enables operators to pause contract functionalities
 * in case of an issue.
 * It also follows the UUPS (Universal Upgradeable Proxy Standard) pattern for contract upgradeability.
 *
 * This contract follows a role-based access control scheme (StandardAccessControl),
 * ensuring secure access management.
 *
 * Note: This contract was modified from Boba Network's default Turing Helper
 *
 * @author DirtyCajunRice
 */
contract TuringHelper is ITuringHelper, Initializable, StandardAccessControl, PausableUpgradeable, UUPSUpgradeable {
/**
     * @dev __TuringHelper_NoPayload
     * Indicates that required payload is missing.
     */
    error __TuringHelper_NoPayload();

    /**
     * @dev __TuringHelper_NotSelf
     * Raised when the address that is expected to match the contract's own address doesn't match.
     * @param expected The expected contract's own address.
     * @param actual The actual address against which the contract's address was compared.
     */
    error __TuringHelper_NotSelf(address expected, address actual);

    /**
     * @dev __TuringHelper_InvalidAddress
     * Raised when an address that is expected to be valid is not valid.
     * @param addr The invalid address.
     */
    error __TuringHelper_InvalidAddress(address addr);

    /**
     * @dev __TuringHelper_GethInterceptFailure
     * Indicates that the geth intercept operation failed.
     */
    error __TuringHelper_GethInterceptFailure();

    /**
     * @dev __TuringHelper_IncorrectInputState
     * Indicates that the input state is incorrect.
     */
    error __TuringHelper_IncorrectInputState();

    /**
     * @dev __TuringHelper_CallDataTooShort
     * Indicates that the call data provided is too short.
     */
    error __TuringHelper_CallDataTooShort();

    /**
     * @dev __TuringHelper_UrlGt64Bytes
     * Indicates that the provided URL exceeds 64 bytes in length.
     */
    error __TuringHelper_UrlGt64Bytes();

    /**
     * @dev __TuringHelper_ServerError
     * Indicates an error from the server.
     */
    error __TuringHelper_ServerError();

    /**
     * @dev __TuringHelper_CouldNotDecodeServerResponse
     * Indicates that the server response could not be decoded.
     */
    error __TuringHelper_CouldNotDecodeServerResponse();

    /**
     * @dev __TuringHelper_CouldNotCreateRpcClient
     * Indicates that a RPC client could not be created.
     */
    error __TuringHelper_CouldNotCreateRpcClient();

    /**
     * @dev __TuringHelper_RngFailure
     * Indicates that there was a failure in generating a random number.
     */
    error __TuringHelper_RngFailure();

    /**
     * @dev __TuringHelper_ApiResponseGt322Chars
     * Indicates that an API response was greater than 322 characters.
     */
    error __TuringHelper_ApiResponseGt322Chars();

    /**
     * @dev __TuringHelper_ApiResponseGt160Bytes
     * Indicates that an API response was greater than 160 bytes.
     */
    error __TuringHelper_ApiResponseGt160Bytes();

    /**
     * @dev __TuringHelper_InsufficientCredit
     * Indicates that there is insufficient credit for the operation.
     */
    error __TuringHelper_InsufficientCredit();

    /**
     * @dev __TuringHelper_MissingCacheEntry
     * Indicates that a needed cache entry is missing.
     */
    error __TuringHelper_MissingCacheEntry();

    /// @dev Instance to TuringHelper
    TuringHelper private Self;

    /// @dev Interface to Boba Turing Credit Contract
    IBobaTuringCredit private _turingCredit;

    /// @dev Transaction Cost for Turing API Call
    uint256 private txCost;

    /// @dev Modifier to ensure only contract itself can run the function
    modifier onlySelf() {
        if (msg.sender != address(this)) revert __TuringHelper_NotSelf(address(this), msg.sender);
        _;
    }

    /// @dev l2geth can pass values here to provide debug information
    modifier onlyR2(uint32 rType) {
        _checkResponseType(rType);
        _;
    }

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
     * @notice This function is used to initialize different types of contracts in the overall contract structure.
     * @dev This function should be called only once, immediately after the contract deployment.
     * Safe to override, as far as the initializer modifier is used to ensure single initialization.
     *
     * Initializes:
     * - Pausable (pauses the contract in case of bugs or flaws).
     * - StandardAccessControl (manages permissions).
     * - UUPSUpgradeable (proxy for upgrading contracts).
     *
     * Additionally, it sets the `Self` variable to the address of the contract itself,
     * and initializes the `_turingCredit` variable with the address of the Turing Credit contract from AddressBook
     * based on the chain it has been deployed to
     */
    function initialize() initializer public {
        __Pausable_init();
        __StandardAccessControl_init();
        __UUPSUpgradeable_init();

        Self = TuringHelper(address(this));
        _turingCredit = IBobaTuringCredit(AddressBook.turingCredit());
    }

    /**
     * @dev Retrieves an error code based on the response type.
     *
     * @param rType A Uint32 representing the response type.
     *        This type value is used to determine the error code to return
     *
     * This function is internal and pure, meaning it does not alter the blockchain state.
     * It is meant to be a helper function within the contract for retrieving
     * error codes as per the provided response type without interacting with the
     * contract's state data.
     *
     * Currently, it returns an empty string as error. However, it can be extended to return
     * corresponding error codes based on the response type in future versions.
     *
     * @return A string which represents the error code. Currently, it returns an empty string.
     */
    function GetErrorCode(uint32 rType) internal pure returns (string memory) {
        return '';
    }

    /**
     * @dev This function checks the response type (`rType`) and throws an error based on its value.
     * The error guides us to understand the type of issue that occurred.
     *
     * This function is marked with `internal`, which means it can only be called from within
     * the current contract or contracts that inherit from this contract.
     * It is marked with `pure` because it does not modify or read from the contract's state.
     *
     * @param rType The response type received from an external system that is evaluated for errors.
     */
    function _checkResponseType(uint32 rType) internal pure {
        if(rType ==  1) revert __TuringHelper_GethInterceptFailure();
        if(rType == 10) revert __TuringHelper_IncorrectInputState();
        if(rType == 11) revert __TuringHelper_CallDataTooShort();
        if(rType == 12) revert __TuringHelper_UrlGt64Bytes();
        if(rType == 13) revert __TuringHelper_ServerError();
        if(rType == 14) revert __TuringHelper_CouldNotDecodeServerResponse();
        if(rType == 15) revert __TuringHelper_CouldNotCreateRpcClient();
        if(rType == 16) revert __TuringHelper_RngFailure();
        if(rType == 17) revert __TuringHelper_ApiResponseGt322Chars();
        if(rType == 18) revert __TuringHelper_ApiResponseGt160Bytes();
        if(rType == 19) revert __TuringHelper_InsufficientCredit();
        if(rType == 20) revert __TuringHelper_MissingCacheEntry();
    }

    /**
     * @dev This function is integral to the communication bridge between on-chain and off-chain mechanisms,
     * providing a request-response pattern for off-chain data fetch.
     * Though marked as "public", usage of this function is confined within the contract, with permissions limited
     * to `TuringCall()` or `TuringTX()`.
     *
     * @param rType A Uint32 which designates the response type. A value of '1' connotes a request,
     *        whereas a value of '2' means a response.
     *
     * @param _url A string that consists of the URL for the off-chain call to be executed.
     *
     * @param _payload Depending upon the rType, this byte array could either represent
     * the parameters for off-chain calls (rType == 1), or hold the response data from off-chain calls (rType == 2).
     * An empty payload on a request type operation triggers a revert using the `__TuringHelper_NoPayload()` function.
     *
     * On successful execution of off-chain call and retrieval of response, the rType is updated to '2'.
     *
     * @return A byte array that contains the payload which could be parameters for an off-chain request or the
     * response from a completed off-chain call, depending on the rType parameter.
     *
     * Preconditions:
     * The function can only be called within the contract (check by `onlySelf` modifier).
     * The rType parameter must pass the conditions defined under the `onlyR2(rType)` modifier.
     * The _checkResponseType function provides further validation of the rType parameter.
     */
    function GetResponse(uint32 rType, string memory _url, bytes memory _payload) public onlySelf onlyR2(rType) returns(bytes memory) {
        if (_payload.length == 0) revert __TuringHelper_NoPayload();
        _checkResponseType(rType);
        return _payload;
    }

    /**
     * @dev Function that gets a random number based on a defined type and applies a response type check.
     *
     * @param rType A Uint32 representing the response type.
     *        This type value is used to determine the format of the random number generated
     *        and must be valid as per the response type rules.
     * @param _random A Uint256 that serves as the base value for generating
     *        the random number.
     *
     * The function is only callable by the contract itself and should only be used with
     * response types that pass the `_checkResponseType(rType)` validation.
     *
     * Note that this function requires the caller to be the contract itself (onlySelf)
     * and the rType needs to fit specific conditions (onlyR2).
     *
     * Contract safety is granted by accurate design of smart contract privileges (onlySelf)
     * and thorough parameter validation by design (`_checkResponseType`).
     *
     * @return A Uint256 which is a random number generated based on the provided rType parameter.
     */
    function GetRandom(uint32 rType, uint256 _random) public onlySelf onlyR2(rType) returns(uint256) {
        _checkResponseType(rType);
        return _random;
    }

    /**
     * @dev This function is used to perform a Turing transaction.
     *
     * @param _url A string, which is the URL to be used in the transaction.
     *        This could be a link to a server-side script, a path to a file, etc.
     * @param _payload A byte array, which contains the data to be transacted.
     *        The payload must not be empty; if it is, the function reverts with an error.
     *
     * The function first checks if the payload is empty; if so, it reverts the transaction
     * and calls the `__TuringHelper_NoPayload()` function to handle the error.
     *
     * It then sends an off-chain request, encapsulating the type of response, the URL, and the payload.
     * The response of the request is stored in a byte array.
     *
     * The function finally emits an `OffchainResponse` event with the transaction ID and the response,
     * and returns the response.
     *
     * Note that this function requires the caller to be the contract itself (onlySelf).
     *
     * It provides a way for a smart contract to interact with the off-chain world through Turing Network.
     *
     * @return A byte array that contains the response received from the off-chain request.
     */
    function TuringTx(string memory _url, bytes memory _payload) public onlySelf returns (bytes memory) {
        if (_payload.length == 0) revert __TuringHelper_NoPayload();
        bytes memory response = Self.GetResponse(1, _url, _payload);
        emit OffchainResponse(1, response);
        return response;
    }

    /**
     * @dev Executes an API call to an off-chain service.
     *
     * This function is designed to interface with external services via APIs. The API endpoint
     * URL is supplied via `_url`, and request parameters are supplied via `_payload`.
     *
     * @param _url An endpoint URL as a string, indicating where the contract should send the API call.
     * @param _payload A bytes array, which holds the ABI-encoded request parameters. If payload is found to be empty,
     *        the function will revert the operation, triggering the `__TuringHelper_NoPayload()` function.
     *
     * The method initiates an off-chain call, encapsulating the request type, the URL and the payload
     * through Self.GetResponse() function, and stores the response from this off-chain call.
     *
     * This function emits an event `OffchainResponse`, encapsulating the request's type and received response.
     * This could be useful in maintaining a verifiable history or aiding in fraud detection mechanisms in future.
     *
     * @return A bytes array containing the response from the API call.
     *
     * Note:
     * - This function checks the contract status against any potential pause in operations. The function
         will not execute if the contract is in paused state (`whenNotPaused` modifier).
     * - The function can only be executed by another contract, it cannot be directly called by a
         contract's owner or a regular address (`onlyContract` modifier).
     */
    function APICall(string memory _url, bytes memory _payload) public whenNotPaused onlyContract returns (bytes memory) {
        if (_payload.length == 0) revert __TuringHelper_NoPayload();
        bytes memory response = Self.GetResponse(1, _url, _payload);
        emit OffchainResponse(1, response);
        return response;
    }

    /**
     * @dev Generates a random number using the GetRandom function from the Self contract.
     *
     * The function checks if the contract is paused. If not, it gets a random number
     * using the GetRandom function from the Self contract with the response type set to 1.
     *
     * An OnChainRandom event is then emitted with the type of response and the generated random number.
     *
     * @return Returns the randomly generated number as a uint256.
     *
     * Note: This function requires the contract to be in 'not paused' state (`whenNotPaused` modifier)
     * and the caller to be a contract (`onlyContract` modifier) for function execution.
     */
    function Random() public whenNotPaused onlyContract returns (uint256) {
        uint256 response = Self.GetRandom(1, 0);
        emit OnChainRandom(1, response);
        return response;
    }

    /**
     * @dev This function is used to pause the execution of the contract.
     *
     * The function pauses all the contract functions by calling internal function '_pause()'.
     *
     * Note: This function can be only performed by an administrator (as defined by the 'onlyAdmin' modifier).
     */
    function pause() external onlyAdmin {
        _pause();
    }

    /**
     * @dev This function is used to resume the execution of the contract.
     *
     * The function allows the contract to resume its regular operations by calling the internal function '_unpause()'.
     *
     * Note: This function can only be performed by an administrator (as defined by the 'onlyAdmin' modifier).
     */
    function unpause() external onlyAdmin {
        _unpause();
    }

    /**
     * @dev This function is used to update the Turing Credit address in the contract.
     *
     * The function first checks if the new address provided supports the IBobaTuringCredit
     * interface by calling the supportsInterface function on IERC165Upgradeable.
     *
     * If the new address does not support the interface, the function reverts with an
     * invalid address error. If the address supports the interface, it gets assigned
     * to the _turingCredit variable.
     *
     * @param _address The new address to be set as the Turing Credit address.
     *
     * Note: This function can only be called by an administrator (`onlyAdmin` modifier).
     */
    function setTuringCredit(address _address) external onlyAdmin {
        if (!IERC165Upgradeable(_address).supportsInterface(type(IBobaTuringCredit).interfaceId)) {
            revert __TuringHelper_InvalidAddress(_address);
        }
        _turingCredit = IBobaTuringCredit(_address);
    }

    /**
     * @dev Returns the current Turing Credit contract address.
     *
     * This function is provided to offer visibility of the Turing Credit contract address
     * that is currently engaged by the contract.
     *
     * @return The Ethereum address of the Turing Credit contract.
     */
    function turingCredit() external view returns (address) {
        return address(_turingCredit);
    }

    /**
     * @dev Checks whether the contract supports a specific interface via feature detection based on ERC165.
     *
     * The ability to inspect which interfaces are supported lends flexibility
     * and offers future-proofing of contracts by facilitating backwards compatibility.
     *
     * @param interfaceId A unique identifier of the interface to be checked.
     *
     * @return A boolean that is true if the contract supports the given interface, false otherwise.
     */
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return interfaceId == ITuringHelper.TuringTx.selector || super.supportsInterface(interfaceId);
    }

    /**
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
