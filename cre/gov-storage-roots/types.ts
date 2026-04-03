export type VotingNetworkConfig = {
  /** Address of the voting portal on Ethereum */
  votingPortalAddress: string;
  /** CRE chain selector name for the voting chain (e.g. "polygon-mainnet") */
  chainSelectorName: string;
  /** DataWarehouse contract address on the voting chain */
  dataWarehouseAddress: string;
  /** Mailbox contract address on the voting chain */
  mailboxAddress: string;
};

export type Config = {
  /** CRE chain selector name for Ethereum mainnet */
  ethereumChainSelectorName: string;
  /** Governance contract address on Ethereum */
  governanceAddress: string;
  /** Token addresses on Ethereum */
  tokens: {
    aave: string;
    aAave: string;
    stkAave: string;
  };
  /** Voting network configurations (one per voting portal) */
  votingNetworks: VotingNetworkConfig[];
};
