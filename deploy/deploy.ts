import { Ether, ether } from "../utils/ethersUnits";
import { UTCBlockchainDate } from "../utils/timeUnits";
import { Address, DeployInfo, Deployer } from "../web3webdeploy/types";
import {
  deploy as openTokenDeploy,
  OpenTokenDeployment,
} from "../lib/open-token/deploy/deploy";
import {
  deploy as validatorPassDeploy,
  ValidatorPassDeployment,
} from "../lib/validator-pass/deploy/deploy";

export interface OpenmeshGenesisDeploymentSettings
  extends Omit<DeployInfo, "contract" | "args"> {
  tokensPerWeiPerPeriod: bigint[];
  token: OpenTokenDeployment;
  nft: ValidatorPassDeployment;
  start: number;
  periodEnds: number[];
  minWeiPerAccount: bigint;
  maxWeiPerAccount: bigint;
}

export interface OpenmeshGenesisDeployment {
  openmeshGenesis: Address;
}

export async function deploy(
  deployer: Deployer,
  settings?: OpenmeshGenesisDeploymentSettings
): Promise<OpenmeshGenesisDeployment> {
  const tokensPerWeiPerPeriod = settings?.tokensPerWeiPerPeriod ?? [
    BigInt(30_000),
    BigInt(27_500),
    BigInt(25_000),
  ];
  deployer.startContext("lib/open-token");
  const token = settings?.token ?? (await openTokenDeploy(deployer));
  deployer.finishContext();
  deployer.startContext("lib/validator-pass");
  const nft = settings?.nft ?? (await validatorPassDeploy(deployer));
  deployer.finishContext();
  const start = settings?.start ?? UTCBlockchainDate(2024, 3, 2); // 2 March 2024
  const periodEnds = settings?.periodEnds ?? [
    UTCBlockchainDate(2024, 3, 10), // 10 March 2024
    UTCBlockchainDate(2024, 3, 20), // 20 March 2024
    UTCBlockchainDate(2024, 3, 30), // 30 March 2024
  ];
  const minWeiPerAccount = settings?.minWeiPerAccount ?? ether / BigInt(2); // 0.5 ETH
  const maxWeiPerAccount = settings?.maxWeiPerAccount ?? Ether(2); // 2 ETH

  const openmeshGenesis = await deployer.deploy({
    id: "Openmesh Genesis",
    contract: "OpenmeshGenesis",
    args: [
      tokensPerWeiPerPeriod,
      token.openToken,
      nft.validatorPass,
      start,
      periodEnds,
      minWeiPerAccount,
      maxWeiPerAccount,
    ],
    ...settings,
  });

  return {
    openmeshGenesis: openmeshGenesis,
  };
}
