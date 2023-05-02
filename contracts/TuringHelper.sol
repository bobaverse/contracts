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
* @title Turing Helper v1.0.0
* @author @DirtyCajunRice
* @dev Modified from Boba Network's default Turing Helper
*/
contract TuringHelper is ITuringHelper, Initializable, StandardAccessControl, PausableUpgradeable, UUPSUpgradeable {
    // Core Errors
    error __TuringHelper_NoPayload();
    error __TuringHelper_NotSelf(address expected, address actual);
    error __TuringHelper_InvalidAddress(address addr);

    // Turing Errors
    error __TuringHelper_GethInterceptFailure();
    error __TuringHelper_IncorrectInputState();
    error __TuringHelper_CallDataTooShort();
    error __TuringHelper_UrlGt64Bytes();
    error __TuringHelper_ServerError();
    error __TuringHelper_CouldNotDecodeServerResponse();
    error __TuringHelper_CouldNotCreateRpcClient();
    error __TuringHelper_RngFailure();
    error __TuringHelper_ApiResponseGt322Chars();
    error __TuringHelper_ApiResponseGt160Bytes();
    error __TuringHelper_InsufficientCredit();
    error __TuringHelper_MissingCacheEntry();

    TuringHelper Self;
    IBobaTuringCredit private _turingCredit;

    uint256 private txCost;

    modifier onlySelf() {
        if (msg.sender != address(this)) revert __TuringHelper_NotSelf(address(this), msg.sender);
        _;
    }

    modifier onlyR2(uint32 rType) {
        _checkResponseType(rType); // l2geth can pass values here to provide debug information
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() initializer public {
        __StandardAccessControl_init();
        __Pausable_init();
        __UUPSUpgradeable_init();

        Self = TuringHelper(address(this));
        _turingCredit = IBobaTuringCredit(AddressBook.turingCredit());
    }

    function GetErrorCode(uint32 rType) internal pure returns (string memory) {
        return '';
    }

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

    /* This is the interface to the off-chain mechanism. Although
       marked as "public", it is only to be called by TuringCall()
       or TuringTX().
       The _payload parameter is overloaded to represent either the
       request parameters or the off-chain response, with the rType
       parameter indicating which is which.
       When called as a request (rType == 1), it starts the offchain call,
       which, if all all goes well, results in the rType changing to 2.
       This response is then passed back to the caller.
    */
    function GetResponse(uint32 rType, string memory _url, bytes memory _payload) public onlySelf onlyR2(rType) returns(bytes memory) {
        if (_payload.length == 0) revert __TuringHelper_NoPayload();
        _checkResponseType(rType);
        return _payload;
    }

    function GetRandom(uint32 rType, uint256 _random) public onlySelf onlyR2(rType) returns(uint256) {
        _checkResponseType(rType);
        return _random;
    }

    function TuringTx(string memory _url, bytes memory _payload) public onlySelf returns (bytes memory) {
        if (_payload.length == 0) revert __TuringHelper_NoPayload();
        bytes memory response = Self.GetResponse(1, _url, _payload);
        emit OffchainResponse(1, response);
        return response;
    }
    /* Called from the external contract. It takes an api endpoint URL
       and an abi-encoded request payload. The URL and the list of allowed
       methods are supplied when the contract is created. In the future
       some of this registration might be moved into l2geth, allowing for
       security measures such as TLS client certificates. A configurable timeout
       could also be added.
       Logs the offchain response so that a future verifier or fraud prover
       can replay the transaction and ensure that it results in the same state
       root as during the initial execution. Note - a future version might
       need to include a timestamp and/or more details about the
       offchain interaction.
    */
    function APICall(string memory _url, bytes memory _payload) public whenNotPaused onlyContract returns (bytes memory) {
        if (_payload.length == 0) revert __TuringHelper_NoPayload();
        bytes memory response = Self.GetResponse(1, _url, _payload);
        emit OffchainResponse(1, response);
        return response;
    }

    function Random() public whenNotPaused onlyContract returns (uint256) {
        uint256 response = Self.GetRandom(1, 0);
        emit OnChainRandom(1, response);
        return response;
    }

    function pause() external onlyAdmin {
        _pause();
    }

    function unpause() external onlyAdmin {
        _unpause();
    }

    function setTuringCredit(address _address) external onlyAdmin {
        if (!IERC165Upgradeable(_address).supportsInterface(type(IBobaTuringCredit).interfaceId)) {
            revert __TuringHelper_InvalidAddress(_address);
        }
        _turingCredit = IBobaTuringCredit(_address);
    }

    function turingCredit() external view returns (address) {
        return address(_turingCredit);
    }

    // ERC165 check interface
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return interfaceId == ITuringHelper.TuringTx.selector || super.supportsInterface(interfaceId);
    }

    function _authorizeUpgrade(address newImplementation) internal virtual override onlyDefaultAdmin {}
}