import { UTCBlockchainDate } from "../utils/timeUnits";
import { Address, Bytes, Deployer } from "../web3webdeploy/types";
import {
  deploy as validatorPassDeploy,
  ValidatorPassDeployment,
} from "../lib/validator-pass/deploy/deploy";
import {
  DeployOpenmeshGenesisSettings,
  deployOpenmeshGenesis,
} from "./internal/OpenmeshGenesis";
import { ether, gwei } from "../utils/ethersUnits";

export interface MerkleTreeItem {
  account: Address;
  mintTime: number;
}

export interface OpenmeshGenesisDeploymentSettings {
  validatorPassDeployment: ValidatorPassDeployment;
  openmeshGenesisSettings: Omit<DeployOpenmeshGenesisSettings, "validatorPass">;
  forceRedeploy?: boolean;
}

export interface OpenmeshGenesisDeployment {
  openmeshGenesis: Address;
}

export async function deploy(
  deployer: Deployer,
  settings?: OpenmeshGenesisDeploymentSettings
): Promise<OpenmeshGenesisDeployment> {
  if (settings?.forceRedeploy !== undefined && !settings.forceRedeploy) {
    const existingDeployment = await deployer.loadDeployment({
      deploymentName: "latest.json",
    });
    if (existingDeployment !== undefined) {
      return existingDeployment;
    }
  }

  deployer.startContext("lib/validator-pass");
  const validatorPassDeployment =
    settings?.validatorPassDeployment ??
    (await validatorPassDeploy(deployer, {
      validatorPassSettings: { salt: "Genesis" + deployer.settings.batchId },
    }));
  deployer.finishContext();

  const openmeshGenesis = await deployOpenmeshGenesis(deployer, {
    validatorPass: validatorPassDeployment.validatorPass,
    ...(settings?.openmeshGenesisSettings ?? {
      mintThresholds: [
        {
          mintCount: BigInt(1),
          price: gwei / BigInt(2),
        },
        {
          mintCount: BigInt(2),
          price: gwei,
        },
        {
          mintCount: BigInt(3),
          price: gwei + gwei / BigInt(2),
        },
        {
          mintCount: BigInt(4),
          price: BigInt(2) * gwei,
        },
      ],
      publicMintTime: UTCBlockchainDate(2024, 5, 8),
      whitelistRoot:
        "0xba1872253c7519232843b5a162f2892aa0117d55f10376955554838e892214a4",
    }),
  });

  const deployment: OpenmeshGenesisDeployment = {
    openmeshGenesis: openmeshGenesis,
  };
  await deployer.saveDeployment({
    deploymentName: "latest.json",
    deployment: deployment,
  });
  return deployment;
}
