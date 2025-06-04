// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Insurance is Ownable {
    using SafeERC20 for IERC20;

    enum PolicyStatus {
        Active,
        Claimed,
        Settled,
        Expired
    }

    struct InsurancePolicy {
        PolicyStatus status;
        string insuredEvent;
        address insuredAddress;
        uint256 insuredAmount;
        string flightId;
        uint256 startTimestamp;
        uint256 expirationTimestamp;
    }

    struct FlightData {
        string flight_origin;
        string flight_destination;
        uint256 flight_date;
        uint256 flight_time;
        string flight_number;
        string flight_airline;
        string flight_status;
        uint16 flight_gate;
    }

    // References all active insurance policies by policyId.
    mapping(bytes32 => InsurancePolicy) public insurancePolicies;
    // Maps hash of initiated claims to their policyId.
    mapping(bytes32 => bytes32) public insuranceClaims;
    // Almacena los datos de vuelo verificados por el relayer
    mapping(bytes32 => FlightData) public verifiedFlightData;
    mapping(bytes32 => uint256) public lastVerificationTimestamp;

    IERC20 public immutable currency;
    address public relayer;

    uint256 public constant MAX_EVENT_DESCRIPTION_SIZE = 6;
    string constant ancillaryDataHead = 'q:"Had the following insured event occurred as of request timestamp: ';
    string constant ancillaryDataTail = '?"';

    event PolicyIssued(
        bytes32 indexed policyId,
        address indexed insurer,
        string insuredEvent,
        address indexed insuredAddress,
        uint256 insuredAmount,
        string flightId
    );
    event ClaimSubmitted(
        uint256 claimTimestamp,
        bytes32 indexed claimId,
        bytes32 indexed policyId
    );
    event ClaimAccepted(bytes32 indexed claimId, bytes32 indexed policyId);
    event ClaimRejected(bytes32 indexed claimId, bytes32 indexed policyId);
    event PolicyExpired(bytes32 indexed policyId);
    event FlightDataUpdated(bytes32 indexed flightId, FlightData data);
    event RelayerUpdated(address indexed oldRelayer, address indexed newRelayer);

    constructor(address _currency) Ownable(msg.sender) {
        currency = IERC20(_currency);
    }

    modifier onlyRelayer() {
        require(msg.sender == relayer, "Only relayer can call this function");
        _;
    }

    function setRelayer(address _relayer) external onlyOwner {
        require(_relayer != address(0), "Invalid relayer address");
        emit RelayerUpdated(relayer, _relayer);
        relayer = _relayer;
    }

    // Función que el relayer usará para actualizar los datos de vuelo
    function updateFlightData(
        bytes32 flightId,
        FlightData calldata data,
        uint256 timestamp
    ) external onlyRelayer {
        verifiedFlightData[flightId] = data;
        lastVerificationTimestamp[flightId] = timestamp;
        emit FlightDataUpdated(flightId, data);
    }

    function issueInsurance(
        string calldata insuredEvent,
        address insuredAddress,
        uint256 insuredAmount,
        string memory flightId,
        uint256 startTimestamp,
        uint256 expirationTimestamp
    ) external returns (bytes32 policyId) {
        require(bytes(insuredEvent).length <= MAX_EVENT_DESCRIPTION_SIZE, "Event description too long");
        require(insuredAddress != address(0), "Invalid insured address");
        require(insuredAmount > 0, "Amount should be above 0");
        require(startTimestamp < expirationTimestamp, "Invalid timestamps");

        policyId = _getPolicyId(
            block.number,
            insuredEvent,
            insuredAddress,
            insuredAmount
        );
        require(insurancePolicies[policyId].insuredAddress == address(0), "Policy already issued");

        InsurancePolicy storage newPolicy = insurancePolicies[policyId];
        newPolicy.status = PolicyStatus.Active;
        newPolicy.insuredEvent = insuredEvent;
        newPolicy.insuredAddress = insuredAddress;
        newPolicy.insuredAmount = insuredAmount;
        newPolicy.flightId = flightId;
        newPolicy.startTimestamp = startTimestamp;
        newPolicy.expirationTimestamp = expirationTimestamp;

        currency.safeTransferFrom(msg.sender, address(this), insuredAmount);

        emit PolicyIssued(
            policyId,
            msg.sender,
            insuredEvent,
            insuredAddress,
            insuredAmount,
            flightId
        );
    }

    function submitClaim(bytes32 policyId) external {
        InsurancePolicy storage policy = insurancePolicies[policyId];
        require(policy.status == PolicyStatus.Active, "Policy not active");
        require(block.timestamp >= policy.startTimestamp, "Policy not yet active");
        require(block.timestamp <= policy.expirationTimestamp, "Policy expired");

        bytes32 flightId = keccak256(abi.encodePacked(policy.flightId));
        require(verifiedFlightData[flightId].flight_date != 0, "Flight data not verified");
        require(
            keccak256(bytes(verifiedFlightData[flightId].flight_status)) == 
            keccak256(bytes("CANCELLED")),
            "Flight not cancelled"
        );

        policy.status = PolicyStatus.Claimed;
        bytes32 claimId = _getClaimId(block.timestamp, policy.flightId);
        insuranceClaims[claimId] = policyId;

        uint256 proposerBond = (policy.insuredAmount * 0.001e18) / 1e18;
        currency.safeTransferFrom(msg.sender, address(this), proposerBond);

        emit ClaimSubmitted(block.timestamp, claimId, policyId);
    }

    function settleClaim(bytes32 claimId) external {
        bytes32 policyId = insuranceClaims[claimId];
        InsurancePolicy storage policy = insurancePolicies[policyId];
        require(policy.status == PolicyStatus.Claimed, "Policy not claimed");

        policy.status = PolicyStatus.Settled;
        currency.safeTransfer(policy.insuredAddress, policy.insuredAmount);

        emit ClaimAccepted(claimId, policyId);
    }

    function rejectClaim(bytes32 claimId) external {
        bytes32 policyId = insuranceClaims[claimId];
        InsurancePolicy storage policy = insurancePolicies[policyId];
        require(policy.status == PolicyStatus.Claimed, "Policy not claimed");

        policy.status = PolicyStatus.Active;
        emit ClaimRejected(claimId, policyId);
    }

    function expirePolicy(bytes32 policyId) external {
        InsurancePolicy storage policy = insurancePolicies[policyId];
        require(policy.status == PolicyStatus.Active, "Policy not active");
        require(block.timestamp > policy.expirationTimestamp, "Policy not expired");

        policy.status = PolicyStatus.Expired;
        emit PolicyExpired(policyId);
    }

    function _getPolicyId(
        uint256 blockNumber,
        string memory insuredEvent,
        address insuredAddress,
        uint256 insuredAmount
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(blockNumber, insuredEvent, insuredAddress, insuredAmount));
    }

    function _getClaimId(
        uint256 timestamp,
        string memory flightId
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(timestamp, flightId));
    }
}
