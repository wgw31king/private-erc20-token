// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {MyToken} from "../src/MyToken.sol";

/// @notice Deploy {MyToken} using env: TOKEN_NAME, TOKEN_SYMBOL, INITIAL_OWNER, PRIVATE_KEY (see `.env.example`).
contract Deploy is Script {
    function run() external returns (MyToken token) {
        string memory name = vm.envString("TOKEN_NAME");
        string memory symbol = vm.envString("TOKEN_SYMBOL");
        address initialOwner = vm.envAddress("INITIAL_OWNER");

        uint256 pk = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(pk);
        console2.log("Deployer:", deployer);
        console2.log("Initial owner (Ownable):", initialOwner);

        vm.startBroadcast(pk);
        token = new MyToken(name, symbol, initialOwner);
        vm.stopBroadcast();

        console2.log("MyToken deployed at:", address(token));
    }
}
