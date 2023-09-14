import { task } from 'hardhat/config';

task("tenderly-verify", "Verify a contract's source code on Tenderly")
  .addPositionalParam("name", "Contract name")
  .setAction(async ({ name }, hre) => {
    const { address, data } = await hre.dcr.getContractAndData(name);
    console.log("Verifying contracts:")
    console.log("Proxy:", address)
    console.log("Impl:", data.impl)
    await hre.tenderly.verify({ name, address: data.impl! }, { name: "ERC1967Proxy", address });

  });
