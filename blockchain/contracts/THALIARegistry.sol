// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/**
 * @title THALIARegistry
 * @notice Smart contract for immutable hydrometeorological disaster audit trail
 * Project: T.H.A.L.I.A (Tri-Habitat Analysis & Climate Forecasting Intelligence)
 * Competition: HACKSPHERE 2026
 */
contract THALIARegistry {
    address public owner;

    enum SeverityLevel { Safe, Waspada, Bahaya }

    struct AlertRecord {
        uint256 id;
        bytes32 dataHash;
        string location;
        string habitatSummary;
        SeverityLevel severity;
        uint256 timestamp;
        address recordedBy;
    }

    uint256 public alertCounter;
    mapping(uint256 => AlertRecord) public alerts;

    event AlertLogged(
        uint256 indexed id,
        bytes32 indexed dataHash,
        string location,
        SeverityLevel severity,
        uint256 timestamp,
        address indexed recordedBy
    );

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can invoke this");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /**
     * @notice Records critical hydrometeorological event into immutable blockchain ledger
     */
    function logAlert(
        bytes32 _dataHash,
        string memory _location,
        string memory _habitatSummary,
        uint8 _severity
    ) external returns (uint256) {
        require(_severity == 1 || _severity == 2, "Only Waspada (1) or Bahaya (2) can be logged");

        alertCounter++;
        uint256 newId = alertCounter;

        SeverityLevel severityEnum = SeverityLevel(_severity);

        alerts[newId] = AlertRecord({
            id: newId,
            dataHash: _dataHash,
            location: _location,
            habitatSummary: _habitatSummary,
            severity: severityEnum,
            timestamp: block.timestamp,
            recordedBy: msg.sender
        });

        emit AlertLogged(
            newId,
            _dataHash,
            _location,
            severityEnum,
            block.timestamp,
            msg.sender
        );

        return newId;
    }

    /**
     * @notice Retrieve an alert record by ID
     */
    function getAlert(uint256 _id) external view returns (AlertRecord memory) {
        require(_id > 0 && _id <= alertCounter, "Alert record does not exist");
        return alerts[_id];
    }

    /**
     * @notice Verify whether a hash matches the on-chain stored record
     */
    function verifyHash(uint256 _id, bytes32 _dataHash) external view returns (bool) {
        require(_id > 0 && _id <= alertCounter, "Alert record does not exist");
        return alerts[_id].dataHash == _dataHash;
    }

    /**
     * @notice Get total alert count
     */
    function totalAlerts() external view returns (uint256) {
        return alertCounter;
    }
}
