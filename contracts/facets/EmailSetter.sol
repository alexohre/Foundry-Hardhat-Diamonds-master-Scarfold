// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {LibAppStorage} from "../libraries/LibAppStorage.sol";

contract EmailSetter {
    LibAppStorage.Layout layout;

    function setEmail(string memory _email) external {
        layout.email = _email;
    }

    function getEmail() external view returns (string memory email_) {
        email_ = layout.email;
        return email_;
    }
}
