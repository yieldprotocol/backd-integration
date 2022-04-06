// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import "./ITopUpHandler.sol";

// TODO: These interfaces can be imported using npm from vault-interfaces
// If there are functions missing, they can be added there.
// The structs are in DataTypes.sol.
struct Vault {
    address owner;
    bytes6 seriesId;
    bytes6 ilkId;
}

interface Ladle {
    function pour(bytes12 vaultId_, address to, int128 ink, int128 art)
        external payable;
}

interface Cauldron {
    function assets(bytes6) external view returns (address);
    function vaults(bytes12 vaultId) external view returns (Vault memory);
    function level(bytes12 vaultId)
        external
        returns (int256);
}

contract YieldHandler is ITopUpHandler {
    Cauldron public immutable cauldron;
    Ladle public immutable ladle;
    // TODO: I assume that only one YieldHandler will be deployed. A contract-wide vault
    // would mean that only one account can use the handler.
    // Since we have to conform to the `topUp` function signature, we will need to devise
    // a way to go from `address account` to `bytes12 vaultId`. Let's discuss with backd
    // some options.
    Vault public vault;

    // TODO: The parameters in the constructor can be of ICauldron and ILadle type, so that
    // you don't need to cast.
    constructor(address cauldronAddress, address ladleAddress, bytes12 vaultId) {
        cauldron = Cauldron(cauldronAddress);
        ladle = Ladle(ladleAddress);
        vault = cauldron.vaults(bytes12(vaultId));
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
        address account,
        address underlying,
        uint256 amount,
        bool repayDebt
    ) external returns (bool) {
        require(account == vault.owner, "Wrong vault!");
        // TODO: The line below won't exactly work. From the vaultId you retrieve the seriesId
        // seriesId = cauldron.vaults(vaultId).seriesId
        // Then you can retrieve the assetId for the underlying
        // baseId == cauldron.series(seriesId).baseId
        // Now you can match the address
        // require(underlying == cauldron.assets(baseId));
        require(underlying == cauldron.assets(bytes6(vault.seriesId)), "Wrong underlying!");
        // TODO: Check the Cast contracts in yield-utils-v2, and use one or two of them.
        ladle.pour(vault.seriesId, address(0), int128(int256(amount)), 0);
        return true;
    }

    /**
     * @notice Returns a factor for the user which should always be >= 1 for sufficiently
     *         collateralized positions and should get closer to 1 when collaterization level decreases
     * This should be an aggregate value including all the collateral of the user
     * @param account account for which to get the factor
     */
    function getUserFactor(address account) external view returns (uint256) {
        require(account == vault.owner, "Wrong vault!");
        // TODO: In Yield, if `level` >= 0 then the vault is collateralized.
        // For now, it seems that we can just add 1 to cauldron.level and backd would be happy,
        // But it might be interesting to check with them how they use this health factor. It might
        // be better UX if we convert from our `level`, which returns the value of the collateral in
        // underlying terms minus the debt. We could instead return the proportion of the value of the
        // collateral in underlying terms, divided by the value of the debt, as a fixed point number.
        return uint256(cauldron.level(vault.seriesId));
    }

}
