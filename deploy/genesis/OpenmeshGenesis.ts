import { Address, DeployInfo, Deployer } from "../../web3webdeploy/types";

export interface DeployOpenmeshGenesisSettingsInternal
  extends Omit<DeployInfo, "contract" | "args"> {
  tokensPerWeiPerPeriod: bigint[];
  token: Address;
  nft: Address;
  start: number;
  periodEnds: number[];
  minWeiPerAccount: bigint;
  maxWeiPerAccount: bigint;
}

export async function deployOpenmeshGenesis(
  deployer: Deployer,
  settings: DeployOpenmeshGenesisSettingsInternal
): Promise<Address> {
  return await deployer
    .deploy({
      id: "OpenmeshGenesis",
      contract: "OpenmeshGenesis",
      args: [
        settings.tokensPerWeiPerPeriod,
        settings.token,
        settings.nft,
        settings.start,
        settings.periodEnds,
        settings.minWeiPerAccount,
        settings.maxWeiPerAccount,
      ],
      ...settings,
    })
    .then((deployment) => deployment.address);
}
