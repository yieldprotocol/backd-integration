// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.14;

import {console} from "forge-std/console.sol";
import {Test} from "./utils/Test.sol";
import {HealerModule} from "./utils/HealerModule.sol";
import {Mocks} from "./utils/Mocks.sol";
import {IERC20} from "yield-utils-v2/contracts/token/IERC20.sol";
import {IWETH9} from "yield-utils-v2/contracts/interfaces/IWETH9.sol";
import "../YieldHandler.sol";

abstract contract TestBase is Test {
    using Mocks for *;

    YieldHandler public yieldHandler;
    ICauldron public cauldron = ICauldron(0xc88191F8cb8e6D4a668B047c1C8503432c3Ca867);
    ILadle public ladle = ILadle(0x6cB18fF2A33e981D1e38A663Ca056c0a5265066A);
    HealerModule public healer;
    IWETH9 public weth;

    address dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F; // DAI token address
    bytes6 ilkId = 0x303100000000; // DAI
    bytes6 seriesId = 0x303130370000; // ETH/DAI Sept 22 series
    bytes12 vaultId;

    function setUp() public {
        weth = IWETH9(Mocks.mock("WETH9"));
        healer = new HealerModule(cauldron, weth);
        yieldHandler = new YieldHandler(cauldron, healer, ladle);
        (vaultId, ) = ladle.build(seriesId, ilkId, 0);
    }

}

contract YieldHandlerTest is TestBase {
    function testMismatchedVaultAndUnderlying() public {
        console.log("Cannot use mismatched vault and underlying");
        bytes memory filler = "sabnock";
        vm.expectRevert("Mismatched vault and underlying");
        yieldHandler.topUp(bytes32(vaultId), address(0), 1, filler);
    }

    function testTopUp() public {
        console.log("Tops up the vault with the amount of asset");
        bytes memory filler = "sabnock";
        deal(dai, address(yieldHandler), 1000);
        assertEq(IERC20(dai).balanceOf(address(yieldHandler)), 1000);
        console.logBytes12(vaultId);
        yieldHandler.topUp(bytes32(vaultId), dai, 1, filler);
    }

    function testGetUserFactor() public {
        console.log("Retrieves the health factor for the given vault id");
        bytes memory filler = "sabnock";
        yieldHandler.getUserFactor(vaultId, filler);
    }
}