// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {LibAppStorage} from "../libraries/LibAppStorage.sol";

contract SetterAddress {
    LibAppStorage.Layout layout;

    function setAddr(string memory _addr) external {
        layout.addr = _addr;
    }

    function getAddr() external view returns (string memory addr_) {
        addr_ = layout.addr;
        return addr_;
    }
}
