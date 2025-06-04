// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IWeb2Json} from "@flarenetwork/flare-periphery-contracts/coston2/IWeb2Json.sol";
import {ContractRegistry} from "@flarenetwork/flare-periphery-contracts/coston2/ContractRegistry.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract FlightDataVerifier {
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

    // Mapping para almacenar los datos verificados de vuelos
    mapping(bytes32 => FlightData) public verifiedFlights;
    // Mapping para almacenar el timestamp de la última verificación
    mapping(bytes32 => uint256) public lastVerificationTimestamp;

    event FlightDataVerified(bytes32 indexed flightId, FlightData data);
    event VerificationFailed(bytes32 indexed flightId, string reason);
    event FlightDataUpdated(bytes32 indexed flightId, FlightData data);

    // Función para verificar y almacenar datos de vuelo
    function verifyAndStoreFlightData(
        bytes32 flightId,
        IWeb2Json.Proof calldata proof
    ) external returns (bool) {
        require(isJsonApiProofValid(proof), "Invalid proof");

        try this.decodeFlightData(proof.data.responseBody.abiEncodedData) returns (FlightData memory flightData) {
            // Verificar que los datos son válidos
            require(bytes(flightData.flight_number).length > 0, "Invalid flight number");
            require(bytes(flightData.flight_airline).length > 0, "Invalid airline");
            
            // Almacenar los datos verificados
            verifiedFlights[flightId] = flightData;
            lastVerificationTimestamp[flightId] = block.timestamp;

            emit FlightDataVerified(flightId, flightData);
            return true;
        } catch {
            emit VerificationFailed(flightId, "Failed to decode flight data");
            return false;
        }
    }

    // Función para obtener datos verificados de un vuelo
    function getVerifiedFlightData(bytes32 flightId) external view returns (FlightData memory, uint256) {
        require(verifiedFlights[flightId].flight_date != 0, "Flight data not found");
        return (verifiedFlights[flightId], lastVerificationTimestamp[flightId]);
    }

    // Función para verificar si un vuelo está cancelado
    function isFlightCancelled(bytes32 flightId) external view returns (bool) {
        require(verifiedFlights[flightId].flight_date != 0, "Flight data not found");
        return keccak256(bytes(verifiedFlights[flightId].flight_status)) == 
               keccak256(bytes("CANCELLED"));
    }

    function decodeFlightData(bytes memory data) external pure returns (FlightData memory) {
        return abi.decode(data, (FlightData));
    }

    function isJsonApiProofValid(
        IWeb2Json.Proof calldata _proof
    ) private view returns (bool) {
        return ContractRegistry.getFdcVerification().verifyJsonApi(_proof);
    }
} 