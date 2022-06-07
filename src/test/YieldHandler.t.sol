// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.14;

import {console} from "forge-std/console.sol";
import {Test} from "forge-std/Test.sol";
import {IERC20} from "yield-utils-v2/contracts/token/IERC20.sol";
import {IWETH9} from "yield-utils-v2/contracts/interfaces/IWETH9.sol";
import "../YieldHandler.sol";

abstract contract TestBase is Test {
    // Addresses for Cauldron, Ladle, HealerModule, and DAI are from the Goerli testnet
    YieldHandler public yieldHandler;
    ICauldron public cauldron = ICauldron(0xF39bf75997176915a117Bb274eF6F20784B91568);
    ILadle public ladle = ILadle(0xE34989E754e6fF29A0bcbe0A9b0ea818C93bff05);
    IHealerModule public healer = IHealerModule(0x9edb7D64aFD7B7A7d45369614d21cC2Abdc94aF8);
    IWETH9 public weth;

    address dai = 0x049E2f3fD58735c116Ba02cd3eC2E76BC01D40D1; // DAI token address
    bytes6 ilkId = 0x303100000000; // DAI
    bytes6 seriesId = 0x303130370000; // ETH/DAI Sept 22 series
    bytes12 vaultId;

    function setUp() public {
        yieldHandler = new YieldHandler(cauldron, ladle, healer);
        vm.prank(0x58A098e581Fc56760552415A372398750d0a7C14); // Timelock address on Goerli
        ILadleCustom(address(ladle)).addModule(address(healer), true);
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
        deal(dai, address(yieldHandler), 1);
        uint128 balance = cauldron.balances(vaultId).ink;
        yieldHandler.topUp(bytes32(vaultId), dai, 1, filler);
        assertEq(balance + 1, cauldron.balances(vaultId).ink, "TopUp failed");
    }

    function testGetUserFactor() public {
        console.log("Retrieves the health factor for the given vault id");
        bytes memory filler = "sabnock";
        uint256 userFactor = yieldHandler.getUserFactor(vaultId, filler);
        assertEq(ICauldronCustom(address(cauldron)).level(bytes12(vaultId)) + 1, int256(userFactor), "Incorrect user factor");

        deal(dai, address(yieldHandler), 1);
        yieldHandler.topUp(bytes32(vaultId), dai, 1, filler);
        assertEq(ICauldronCustom(address(cauldron)).level(bytes12(vaultId)) + 1, int256(userFactor + 1), "Incorrect user factor");
    }
}