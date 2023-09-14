import { task } from 'hardhat/config';
import { keccak256, toUtf8Bytes } from 'ethers';

task("add-contract-admin", "Add an admin to a proxy contract")
  .addPositionalParam("name", "Contract name")
  .addPositionalParam("address", "Admin to add")
  .addPositionalParam("role", "Contract role", "ADMIN_ROLE")
  .setAction(async ({ name, address: adminAddress, role: contractRole }, hre) => {
      const role = keccak256(toUtf8Bytes(contractRole));
      const contract = await hre.dcr.getContract(name);
      if (hre.network.config.chainId === 56_288) {
          // @ts-ignore
          contract.runner["_gasLimit"] = BigInt(1_000_000);
      }
      const hasRole = await contract.hasRole(role, adminAddress);
      if (hasRole) {
          return console.log(`${adminAddress} already has ${role} (${role})`);
      }
      console.log(`Granting ${role} (${role}) to`, adminAddress);
      const tx = await contract.grantRole(role, adminAddress)
      await tx.wait();
      console.log("Done!")
  });
