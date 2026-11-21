const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("THALIARegistry Smart Contract", function () {
  let thalia;
  let owner, addr1;

  beforeEach(async function () {
    [owner, addr1] = await ethers.getSigners();
    const THALIARegistry = await ethers.getContractFactory("THALIARegistry");
    thalia = await THALIARegistry.deploy();
    await thalia.waitForDeployment();
  });

  it("Should initialize with 0 alerts and correct owner", async function () {
    expect(await thalia.totalAlerts()).to.equal(0);
    expect(await thalia.owner()).to.equal(owner.address);
  });

  it("Should log a critical alert and store data hash correctly", async function () {
    const fakeDataHash = ethers.keccak256(ethers.toUtf8Bytes("telemetry-snapshot-danger-001"));
    const location = "Desa Sukamaju, Lereng A";
    const summary = "BAHAYA: Kejenuhan tanah 88% dan curah hujan lebat 45mm/jam";
    const severity = 2; // Bahaya / Danger

    const tx = await thalia.logAlert(fakeDataHash, location, summary, severity);
    await tx.wait();

    expect(await thalia.totalAlerts()).to.equal(1);

    const alert = await thalia.getAlert(1);
    expect(alert.id).to.equal(1);
    expect(alert.dataHash).to.equal(fakeDataHash);
    expect(alert.location).to.equal(location);
    expect(alert.severity).to.equal(severity);

    // Verify hash
    const isValid = await thalia.verifyHash(1, fakeDataHash);
    expect(isValid).to.be.true;

    // Verify incorrect hash fails
    const wrongHash = ethers.keccak256(ethers.toUtf8Bytes("tampered-data"));
    const isTamperedValid = await thalia.verifyHash(1, wrongHash);
    expect(isTamperedValid).to.be.false;
  });

  it("Should reject invalid severity level (e.g. 0 Safe)", async function () {
    const fakeHash = ethers.keccak256(ethers.toUtf8Bytes("safe-telemetry"));
    await expect(
      thalia.logAlert(fakeHash, "Lokasi", "Aman", 0)
    ).to.be.revertedWith("Only Waspada (1) or Bahaya (2) can be logged");
  });
});
