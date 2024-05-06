import { StandardMerkleTree } from "@openzeppelin/merkle-tree";
import { writeFileSync } from "fs";
import { whitelist } from "./whitelist.js";

const tree = StandardMerkleTree.of(
  whitelist.map((item) => [item.account, item.mintTime]) as [
    `0x${string}`,
    number
  ][],
  ["address", "uint32"]
);

console.log("Merkle Root:", tree.root);

writeFileSync("tree.json", JSON.stringify(tree.dump()));
