// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import "./ITopUpHandler.sol";
import "@yield-protocol/vault-interfaces/DataTypes.sol";
import "@yield-protocol/vault-interfaces/ICauldron.sol";
import "@yield-protocol/vault-interfaces/ILadle.sol";
import "@yield-protocol/utils-v2/contracts/cast/CastU256I128.sol";
import "@yield-protocol/utils-v2/contracts/token/IERC20.sol";


contract YieldHandler is ITopUpHandler {
    using CastU256I128 for uint256;

    DataTypes.Vault vault;
    ICauldron cauldron;
    ILadle ladle;
    IJoin join;
    IERC20 collateral;

    constructor(ICauldron cauldronAddress, ILadle ladleAddress) {
        cauldron = cauldronAddress;
        ladle = ladleAddress;
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
        address underlying,      // Backd calls this underlying, but should be called just `asset` to avoid confusion.
        uint256 amount,
        bytes memory extra
    ) external returns (bool) {
        vault = cauldron.vaults(bytes12(account));
        bytes6 baseId = cauldron.series(vault.seriesId).baseId;
        require(underlying == cauldron.assets(baseId), "Underlying not found!");
        join = ladle.joins(vault.ilkId);
        IERC20(underlying).transfer(address(join), amount);
        ladle.pour(bytes12(account), address(0), amount.i128(), 0);
        return true;
    }

    /**
     * @notice Returns a factor for the user which should always be >= 1 for sufficiently
     *         collateralized positions and should get closer to 1 when collaterization level decreases
     * This should be an aggregate value including all the collateral of the user
     * @param account account for which to get the factor
     */
    function getUserFactor(bytes32 account) external view returns (uint256) {
        return uint256(cauldron.level(bytes12(account))) + 1;
    }

}
