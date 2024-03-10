import { Ether, ether } from "../utils/ethersUnits";
import { UTCBlockchainDate } from "../utils/timeUnits";
import { Address, Deployer } from "../web3webdeploy/types";
import {
  deploy as openTokenDeploy,
  OpenTokenDeployment,
} from "../lib/open-token/deploy/deploy";
import {
  deploy as validatorPassDeploy,
  ValidatorPassDeployment,
} from "../lib/validator-pass/deploy/deploy";
import {
  DeployOpenmeshGenesisSettings,
  deployOpenmeshGenesis,
} from "./genesis/OpenmeshGenesis";

export interface OpenmeshGenesisDeploymentSettings {
  openTokenDeployment: OpenTokenDeployment;
  validatorPassDeployment: ValidatorPassDeployment;
  openmeshGenesisSettings: Omit<DeployOpenmeshGenesisSettings, "token" | "nft">;
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
    return await deployer.loadDeployment({ deploymentName: "latest.json" });
  }

  deployer.startContext("lib/open-token");
  const openTokenDeployment =
    settings?.openTokenDeployment ?? (await openTokenDeploy(deployer));
  deployer.finishContext();
  deployer.startContext("lib/validator-pass");
  const validatorPassDeployment =
    settings?.validatorPassDeployment ?? (await validatorPassDeploy(deployer));
  deployer.finishContext();

  const openmeshGenesis = await deployOpenmeshGenesis(deployer, {
    token: openTokenDeployment.openToken,
    nft: validatorPassDeployment.validatorPass,
    ...(settings?.openmeshGenesisSettings ?? {
      tokensPerWeiPerPeriod: [BigInt(30_000), BigInt(27_500), BigInt(25_000)],
      start: UTCBlockchainDate(2024, 3, 2), // 2 March 2024
      periodEnds: [
        UTCBlockchainDate(2024, 3, 10), // 10 March 2024
        UTCBlockchainDate(2024, 3, 20), // 20 March 2024
        UTCBlockchainDate(2024, 3, 30), // 30 March 2024
      ],
      minWeiPerAccount: ether / BigInt(2), // 0.5 ETH
      maxWeiPerAccount: Ether(2), // 2 ETH
    }),
  });

  const deployment = {
    openmeshGenesis: openmeshGenesis,
  };
  await deployer.saveDeployment({
    deploymentName: "latest.json",
    deployment: deployment,
  });
  return deployment;
}
