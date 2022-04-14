// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import "./ITopUpHandler.sol";
import "@yield-protocol/vault-interfaces/DataTypes.sol";
import "@yield-protocol/vault-interfaces/ICauldron.sol";
import "@yield-protocol/vault-interfaces/ILadle.sol";
import "@yield-protocol/utils-v2/contracts/cast/CastU256I128.sol";


contract YieldHandler is ITopUpHandler {
    using CastU256I128 for uint256;

    ICauldron cauldron;
    ILadle ladle;
    DataTypes.Vault vault;

    constructor(ICauldron cauldronAddress, ILadle ladleAddress) {
        cauldron = cauldronAddress;
        ladle = ladleAddress;
    }

    /**
     * @notice Tops up the account for the protocol associated with this handler
     * This is designed to be called using delegatecall and should therefore
     * not assume that storage will be available
     *
     * @param account account to be topped up
     * @param underlying underlying currency to be used for top up
     * @param amount amount to be topped up
     * @return true if the top up succeeded and false otherwise
     */

    function topUp(
        bytes32 account,
        address underlying,
        uint256 amount,
        bytes memory vaultId
    ) external returns (bool) {
        vault = cauldron.vaults(bytes12(vaultId));
        require(address(uint160(bytes20(account))) == vault.owner, "Wrong vault!");
        bytes6 seriesId = cauldron.vaults(bytes12(vaultId)).seriesId;
        bytes6 baseId = cauldron.series(seriesId).baseId;
        require(underlying == cauldron.assets(baseId), "Wrong underlying!");
        ladle.pour(vault.seriesId, address(0), amount.i128(), 0);
        return true;
    }

    /**
     * @notice Returns a factor for the user which should always be >= 1 for sufficiently
     *         collateralized positions and should get closer to 1 when collaterization level decreases
     * This should be an aggregate value including all the collateral of the user
     * @param account account for which to get the factor
     */
    function getUserFactor(bytes32 account) external view returns (uint256) {
        require(address(account) == vault.owner, "Wrong vault!");
        // TODO: In Yield, if `level` >= 0 then the vault is collateralized.
        // For now, it seems that we can just add 1 to cauldron.level and backd would be happy,
        // But it might be interesting to check with them how they use this health factor. It might
        // be better UX if we convert from our `level`, which returns the value of the collateral in
        // underlying terms minus the debt. We could instead return the proportion of the value of the
        // collateral in underlying terms, divided by the value of the debt, as a fixed point number.
        return uint256(cauldron.level(vault.seriesId)) + 1;
    }

}
