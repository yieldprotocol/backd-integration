// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.14;

import "./ITopUpHandler.sol";
import "vault-interfaces/src/DataTypes.sol";
import "vault-interfaces/src/ICauldron.sol";
import "vault-interfaces/src/ILadle.sol";
import "yield-utils-v2/contracts/cast/CastBytes32Bytes12.sol";
import "yield-utils-v2/contracts/token/IERC20.sol";

interface ICauldronCustom {
    function level(bytes12 vaultId) external view returns (int256);
}

interface ILadleCustom {
    function addModule(address module, bool set) external;

    function moduleCall(address module, bytes calldata data) external payable returns (bytes memory result);
}

interface IHealerModule {
    function heal(bytes12 vaultId_, int128 ink, int128 art) external payable;
}

contract YieldHandler is ITopUpHandler {
    using CastBytes32Bytes12 for bytes32;

    ICauldron cauldron;
    ILadle ladle;
    IJoin join;
    IHealerModule healer;
    DataTypes.Vault vault;

    constructor(ICauldron cauldron_, ILadle ladle_, IHealerModule healer_) {
        cauldron = cauldron_;
        ladle = ladle_;
        healer = healer_;
    }

    /**
     * @notice Tops up the account for the protocol associated with this handler
     * This is designed to be called using delegatecall and should therefore
     * not assume that storage will be available
     *
     * @param account account to be topped up (vaultId)
     * @param underlying underlying currency to be used for top up (collateral)
     * @param amount amount to be topped up
     * @return true if the top up succeeded and false otherwise
     */

    function topUp(
        bytes32 account,        // This will be the vaultId, packed as a bytes32
        address underlying,     // Backd calls this underlying, but should be called just `asset` to avoid confusion.
        uint256 amount,
        bytes memory extra
    ) external returns (bool) {
        vault = cauldron.vaults(account.b12());
        require(underlying == cauldron.assets(vault.ilkId), "Mismatched vault and underlying");
        join = ladle.joins(vault.ilkId);
        IERC20(underlying).transfer(address(join), amount);
        ILadleCustom(address(ladle)).moduleCall(
            address(healer), 
            abi.encodeWithSelector(bytes4(healer.heal.selector), account, amount, 0)
        );
        return true;
    }

    /**
     * @notice Returns a factor for the user which should always be >= 1 for sufficiently
     *         collateralized positions and should get closer to 1 when collaterization level decreases
     * This should be an aggregate value including all the collateral of the user
     * @dev This transaction will revert if the position has a collateral that uses transactional oracles
     * @param account account for which to get the factor (in our case it is the vaultId, packed as a bytes32)
     */
    function getUserFactor(bytes32 account, bytes memory extra) external view returns (uint256) {
        return uint256(ICauldronCustom(address(cauldron)).level(bytes12(account))) + 1;
    }

}
