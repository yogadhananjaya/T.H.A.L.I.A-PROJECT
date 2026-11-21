const hre = require("hardhat");
const fs = require("fs");
const path = require("path");

async function main() {
  console.log("Starting THALIARegistry deployment on Hardhat Local Network...");

  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying contract with account:", deployer.address);

  const balance = await hre.ethers.provider.getBalance(deployer.address);
  console.log("Account balance:", hre.ethers.formatEther(balance), "ETH");

  const THALIARegistry = await hre.ethers.getContractFactory("THALIARegistry");
  const thalia = await THALIARegistry.deploy();
  await thalia.waitForDeployment();

  const contractAddress = await thalia.getAddress();
  console.log("--------------------------------------------------");
  console.log(">>> THALIARegistry deployed successfully! <<<");
  console.log("Contract Address:", contractAddress);
  console.log("--------------------------------------------------");

  // Export ABI and address for FastAPI backend
  const artifactPath = path.join(__dirname, "../artifacts/contracts/THALIARegistry.sol/THALIARegistry.json");
  if (fs.existsSync(artifactPath)) {
    const artifact = JSON.parse(fs.readFileSync(artifactPath, "utf8"));
    const contractInfo = {
      address: contractAddress,
      network: "hardhat_localhost",
      rpcUrl: "http://127.0.0.1:8545",
      abi: artifact.abi
    };

    const backendDir = path.join(__dirname, "../../backend/app/core");
    if (!fs.existsSync(backendDir)) {
      fs.mkdirSync(backendDir, { recursive: true });
    }

    const outputPath = path.join(backendDir, "contract_info.json");
    fs.writeFileSync(outputPath, JSON.stringify(contractInfo, null, 2));
    console.log("Contract metadata exported to:", outputPath);
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
