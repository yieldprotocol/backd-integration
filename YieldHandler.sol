// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import "./ITopUpHandler.sol";

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
    Vault public vault;

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
        require(underlying == cauldron.assets(bytes6(vault.seriesId)), "Wrong underlying!");
        ladle.pour(vault.seriesId, address(0), int128(int256(amount)), 0);
        return true;
    }

    /**
     * @notice Returns a factor for the user which should always be >= 1 for sufficiently
     *         colletaralized positions and should get closer to 1 when collaterization level decreases
     * This should be an aggregate value including all the collateral of the user
     * @param account account for which to get the factor
     */
    function getUserFactor(address account) external view returns (uint256) {
        require(account == vault.owner, "Wrong vault!");
        return uint256(cauldron.level(vault.seriesId));
    }

}
