# Yield Protocol Vault v2
This is a handler for (Backd)[https://backd.fund/] Top-up (Actions)[https://docs.backd.fund/protocol-architecture/actions].

Bacd allows users to register on-chain actions to increase the efficiency of their assets. (Collateral Top-ups)[https://docs.backd.fund/protocol-architecture/actions/top-ups] are one such action. These inject additional collater into a debt position to increase the health factor of the position and in turn decrease the risk of liquidation.

In the event that a position approaches liquidation, the borrower that holds the position can register a top up action to the Backd keeper. This action includes the health factor trigger, an increment amount and a max allocation amount. When the value of the trigger is hit, this will be reported to the Backd smart contract by the keeper to initiate the top up. A collateral amount equal to the increment value will be allocated to the position to increase its health factor. This process will continue up to the max allocation amount.

This repo includes a Top-up handler interface and its implementation for Yield Protocol.