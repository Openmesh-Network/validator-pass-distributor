import {
  Address,
  Bytes,
  DeployInfo,
  Deployer,
} from "../../web3webdeploy/types";

export interface PriceThreshold {
  mintCount: bigint;
  price: bigint;
}

export interface DeployOpenmeshGenesisSettings
  extends Omit<DeployInfo, "contract" | "args"> {
  validatorPass: Address;
  mintThresholds: PriceThreshold[];
  publicMintTime: number;
  whitelistRoot: Bytes;
}

export async function deployOpenmeshGenesis(
  deployer: Deployer,
  settings: DeployOpenmeshGenesisSettings
): Promise<Address> {
  return await deployer
    .deploy({
      id: "OpenmeshGenesis",
      contract: "OpenmeshGenesis",
      args: [
        settings.validatorPass,
        settings.mintThresholds,
        settings.publicMintTime,
        settings.whitelistRoot,
      ],
      ...settings,
    })
    .then((deployment) => deployment.address);
}
