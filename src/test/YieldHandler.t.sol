// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import {console} from "forge-std/console.sol";
import {Test} from "forge-std/Test.sol";
import "../YieldHandler.sol";

abstract contract TestBase is Test {
    YieldHandler public yieldHandler;
    ICauldron public cauldron = ICauldron(0xc88191F8cb8e6D4a668B047c1C8503432c3Ca867);
    ILadle public ladle = ILadle(0x6cB18fF2A33e981D1e38A663Ca056c0a5265066A);

    address user;
    bytes6 seriesId = 0x5526292ad5b9;
    bytes6 ilkId = 0x303000000000;
    bytes12 vaultId;

    function setUp() public {
        yieldHandler = new YieldHandler(cauldron, ladle);
        user = address(1);
        (vaultId, ) = ladle.build(seriesId, ilkId, 0);
    }

}

contract YieldHandlerTest is TestBase {
    function testMismatchedVaultAndUnderlying() public {
        console.log("Cannot use mismatched vault and underlying");
    }

    function testTopUp() public {
        console.log("Tops up the vault with the amount of asset");
        bytes memory filler = "sabnock";
        // yieldHandler.topUp(bytes32(vaultId), asset, amount, filler);
    }

    function testGetUserFactor() public {
        console.log("Retrieves the health factor for the given vault id");
        bytes memory filler = "sabnock";
        yieldHandler.getUserFactor(vaultId, filler);
    }
}