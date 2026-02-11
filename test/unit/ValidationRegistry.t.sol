// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {TestHelper} from "../TestHelper.sol";
import {IERC8004Validation} from "../../src/interfaces/IERC8004Validation.sol";
import {ValidationRegistry} from "../../src/ValidationRegistry.sol";

contract ValidationRegistryTest is TestHelper {
    function test_ValidationRequest() public {
        uint256 agentId = registerAgent(alice, "ipfs://agent1");
        bytes32 requestHash = keccak256("request1");

        // Owner can request validation
        requestValidation(alice, validator1, agentId, requestHash);

        (address validatorAddr, uint256 returnedAgentId, uint8 response, , , ) =
            validationRegistry.getValidationStatus(requestHash);

        assertEq(validatorAddr, validator1);
        assertEq(returnedAgentId, agentId);
        assertEq(response, 0); // Pending

        bytes32[] memory agentValidations = validationRegistry.getAgentValidations(agentId);
        assertEq(agentValidations.length, 1);
        assertEq(agentValidations[0], requestHash);
    }

    function test_RevertWhen_ValidationRequest_NotOwner() public {
        uint256 agentId = registerAgent(alice, "ipfs://agent1");
        bytes32 requestHash = keccak256("request1");

        // Bob is not owner/operator
        vm.prank(bob);
        vm.expectRevert(ValidationRegistry.NotAuthorized.selector);
        validationRegistry.validationRequest(validator1, agentId, "ipfs://validation", requestHash);
    }

    function test_RevertWhen_ValidationRequest_AgentNotFound() public {
        vm.prank(alice);
        vm.expectRevert();
        validationRegistry.validationRequest(validator1, 999, "ipfs://validation", keccak256("request"));
    }

    function test_ValidationResponse() public {
        uint256 agentId = registerAgent(alice, "ipfs://agent1");
        bytes32 requestHash = keccak256("request1");
        requestValidation(alice, validator1, agentId, requestHash);

        submitValidationResponse(validator1, requestHash, 85, "security");

        (address validatorAddr, , uint8 response, , string memory tag, ) =
            validationRegistry.getValidationStatus(requestHash);

        assertEq(validatorAddr, validator1);
        assertEq(response, 85);
        assertEq(tag, "security");
    }

    function test_ValidationResponse_ZeroIsValid() public {
        uint256 agentId = registerAgent(alice, "ipfs://agent1");
        bytes32 requestHash = keccak256("request1");
        requestValidation(alice, validator1, agentId, requestHash);

        // 0 is a valid response score per spec
        submitValidationResponse(validator1, requestHash, 0, "security");

        (, , uint8 response, , , ) = validationRegistry.getValidationStatus(requestHash);
        assertEq(response, 0);
    }

    function test_ValidationResponse_ProgressiveUpdate() public {
        uint256 agentId = registerAgent(alice, "ipfs://agent1");
        bytes32 requestHash = keccak256("request1");
        requestValidation(alice, validator1, agentId, requestHash);

        // First response
        submitValidationResponse(validator1, requestHash, 60, "security");
        (, , uint8 response1, , , ) = validationRegistry.getValidationStatus(requestHash);
        assertEq(response1, 60);

        // Update response
        submitValidationResponse(validator1, requestHash, 85, "security-v2");
        (, , uint8 response2, , string memory tag2, ) = validationRegistry.getValidationStatus(requestHash);
        assertEq(response2, 85);
        assertEq(tag2, "security-v2");
    }

    function test_RevertWhen_ValidationResponse_NotValidator() public {
        uint256 agentId = registerAgent(alice, "ipfs://agent1");
        bytes32 requestHash = keccak256("request1");
        requestValidation(alice, validator1, agentId, requestHash);

        vm.prank(validator2);
        vm.expectRevert(ValidationRegistry.NotAuthorized.selector);
        validationRegistry.validationResponse(requestHash, 85, "", bytes32(0), "tag");
    }

    function test_RevertWhen_ValidationResponse_InvalidScore_Above100() public {
        uint256 agentId = registerAgent(alice, "ipfs://agent1");
        bytes32 requestHash = keccak256("request1");
        requestValidation(alice, validator1, agentId, requestHash);

        vm.prank(validator1);
        vm.expectRevert(ValidationRegistry.InvalidResponse.selector);
        validationRegistry.validationResponse(requestHash, 101, "", bytes32(0), "tag");
    }

    function test_GetSummary() public {
        uint256 agentId = registerAgent(alice, "ipfs://agent1");

        bytes32 req1 = keccak256("req1");
        bytes32 req2 = keccak256("req2");
        bytes32 req3 = keccak256("req3");

        requestValidation(alice, validator1, agentId, req1);
        requestValidation(alice, validator2, agentId, req2);
        requestValidation(alice, validator1, agentId, req3);

        submitValidationResponse(validator1, req1, 80, "security");
        submitValidationResponse(validator2, req2, 60, "performance");
        submitValidationResponse(validator1, req3, 90, "security");

        address[] memory validators = new address[](0);
        (uint64 count, uint8 avgResponse) = validationRegistry.getSummary(agentId, validators, "");

        assertEq(count, 3);
        assertEq(avgResponse, 76); // (80 + 60 + 90) / 3
    }

    function test_GetSummary_FilterByValidator() public {
        uint256 agentId = registerAgent(alice, "ipfs://agent1");

        bytes32 req1 = keccak256("req1");
        bytes32 req2 = keccak256("req2");

        requestValidation(alice, validator1, agentId, req1);
        requestValidation(alice, validator2, agentId, req2);

        submitValidationResponse(validator1, req1, 80, "security");
        submitValidationResponse(validator2, req2, 60, "performance");

        address[] memory validators = new address[](1);
        validators[0] = validator1;
        (uint64 count, uint8 avgResponse) = validationRegistry.getSummary(agentId, validators, "");

        assertEq(count, 1);
        assertEq(avgResponse, 80);
    }

    function test_GetSummary_FilterByTag() public {
        uint256 agentId = registerAgent(alice, "ipfs://agent1");

        bytes32 req1 = keccak256("req1");
        bytes32 req2 = keccak256("req2");
        bytes32 req3 = keccak256("req3");

        requestValidation(alice, validator1, agentId, req1);
        requestValidation(alice, validator2, agentId, req2);
        requestValidation(alice, validator1, agentId, req3);

        submitValidationResponse(validator1, req1, 80, "security");
        submitValidationResponse(validator2, req2, 60, "performance");
        submitValidationResponse(validator1, req3, 90, "security");

        address[] memory validators = new address[](0);
        (uint64 count, uint8 avgResponse) = validationRegistry.getSummary(agentId, validators, "security");

        assertEq(count, 2);
        assertEq(avgResponse, 85); // (80 + 90) / 2
    }

    function test_GetValidatorRequests() public {
        uint256 agentId = registerAgent(alice, "ipfs://agent1");

        bytes32 req1 = keccak256("req1");
        bytes32 req2 = keccak256("req2");

        requestValidation(alice, validator1, agentId, req1);
        requestValidation(alice, validator1, agentId, req2);

        bytes32[] memory requests = validationRegistry.getValidatorRequests(validator1);
        assertEq(requests.length, 2);
        assertEq(requests[0], req1);
        assertEq(requests[1], req2);
    }

    function test_GetAgentValidations() public {
        uint256 agentId = registerAgent(alice, "ipfs://agent1");

        bytes32 req1 = keccak256("req1");
        bytes32 req2 = keccak256("req2");

        requestValidation(alice, validator1, agentId, req1);
        requestValidation(alice, validator2, agentId, req2);

        bytes32[] memory validations = validationRegistry.getAgentValidations(agentId);
        assertEq(validations.length, 2);
    }

    function test_RevertWhen_GetValidationStatus_NotFound() public {
        vm.expectRevert();
        validationRegistry.getValidationStatus(bytes32(uint256(999)));
    }
}
