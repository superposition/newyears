// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {TestHelper} from "../TestHelper.sol";
import {IERC8004Validation} from "../../src/interfaces/IERC8004Validation.sol";

contract ValidationRegistryTest is TestHelper {
    function test_ValidationRequest() public {
        uint256 agentId = registerAgent(alice, "ipfs://agent1");

        bytes32 requestHash = requestValidation(bob, validator1, agentId, "security");

        IERC8004Validation.ValidationRecord memory record = validationRegistry.getValidation(requestHash);
        assertEq(record.requestor, bob);
        assertEq(record.validatorAddress, validator1);
        assertEq(record.agentId, agentId);
        assertEq(record.tag, "security");
        assertEq(record.response, 0); // Pending
        assertEq(validationRegistry.getValidationCount(agentId), 1);
    }

    function test_RevertWhen_ValidationRequest_AgentNotFound() public {
        vm.prank(bob);
        vm.expectRevert();
        validationRegistry.validationRequest(validator1, 999, "ipfs://validation", bytes32(0), "security");
    }

    function test_ValidationResponse() public {
        uint256 agentId = registerAgent(alice, "ipfs://agent1");
        bytes32 requestHash = requestValidation(bob, validator1, agentId, "security");

        submitValidationResponse(validator1, requestHash, 85);

        IERC8004Validation.ValidationRecord memory record = validationRegistry.getValidation(requestHash);
        assertEq(record.response, 85);
    }

    function test_RevertWhen_ValidationResponse_NotValidator() public {
        uint256 agentId = registerAgent(alice, "ipfs://agent1");
        bytes32 requestHash = requestValidation(bob, validator1, agentId, "security");

        vm.prank(validator2);
        vm.expectRevert();
        validationRegistry.validationResponse(requestHash, 85, "", bytes32(0));
    }

    function test_RevertWhen_ValidationResponse_InvalidScore_Zero() public {
        uint256 agentId = registerAgent(alice, "ipfs://agent1");
        bytes32 requestHash = requestValidation(bob, validator1, agentId, "security");

        vm.prank(validator1);
        vm.expectRevert();
        validationRegistry.validationResponse(requestHash, 0, "", bytes32(0));
    }

    function test_RevertWhen_ValidationResponse_InvalidScore_Above100() public {
        uint256 agentId = registerAgent(alice, "ipfs://agent1");
        bytes32 requestHash = requestValidation(bob, validator1, agentId, "security");

        vm.prank(validator1);
        vm.expectRevert();
        validationRegistry.validationResponse(requestHash, 101, "", bytes32(0));
    }

    function test_GetSummary_All() public {
        uint256 agentId = registerAgent(alice, "ipfs://agent1");

        bytes32 request1 = requestValidation(bob, validator1, agentId, "security");
        bytes32 request2 = requestValidation(bob, validator2, agentId, "performance");
        bytes32 request3 = requestValidation(charlie, validator1, agentId, "security");

        submitValidationResponse(validator1, request1, 80);
        submitValidationResponse(validator2, request2, 60);
        submitValidationResponse(validator1, request3, 90);

        address[] memory validators = new address[](0);
        IERC8004Validation.ValidationSummary memory summary = validationRegistry.getSummary(agentId, validators, "");

        assertEq(summary.totalValidations, 3);
        assertEq(summary.passedCount, 3); // All >= 50
        assertEq(summary.failedCount, 0);
        assertEq(summary.pendingCount, 0);
        assertEq(summary.averageScore, 76); // (80 + 60 + 90) / 3 = 76
    }

    function test_GetSummary_FilterByValidator() public {
        uint256 agentId = registerAgent(alice, "ipfs://agent1");

        bytes32 request1 = requestValidation(bob, validator1, agentId, "security");
        bytes32 request2 = requestValidation(bob, validator2, agentId, "performance");
        bytes32 request3 = requestValidation(charlie, validator1, agentId, "security");

        submitValidationResponse(validator1, request1, 80);
        submitValidationResponse(validator2, request2, 60);
        submitValidationResponse(validator1, request3, 90);

        address[] memory validators = new address[](1);
        validators[0] = validator1;
        IERC8004Validation.ValidationSummary memory summary = validationRegistry.getSummary(agentId, validators, "");

        assertEq(summary.totalValidations, 2);
        assertEq(summary.averageScore, 85); // (80 + 90) / 2
    }

    function test_GetSummary_FilterByTag() public {
        uint256 agentId = registerAgent(alice, "ipfs://agent1");

        bytes32 request1 = requestValidation(bob, validator1, agentId, "security");
        bytes32 request2 = requestValidation(bob, validator2, agentId, "performance");
        bytes32 request3 = requestValidation(charlie, validator1, agentId, "security");

        submitValidationResponse(validator1, request1, 80);
        submitValidationResponse(validator2, request2, 60);
        submitValidationResponse(validator1, request3, 90);

        address[] memory validators = new address[](0);
        IERC8004Validation.ValidationSummary memory summary =
            validationRegistry.getSummary(agentId, validators, "security");

        assertEq(summary.totalValidations, 2);
        assertEq(summary.averageScore, 85); // (80 + 90) / 2
    }

    function test_GetSummary_PendingValidations() public {
        uint256 agentId = registerAgent(alice, "ipfs://agent1");

        bytes32 request1 = requestValidation(bob, validator1, agentId, "security");
        bytes32 request2 = requestValidation(bob, validator2, agentId, "performance");

        // Only respond to one
        submitValidationResponse(validator1, request1, 80);

        address[] memory validators = new address[](0);
        IERC8004Validation.ValidationSummary memory summary = validationRegistry.getSummary(agentId, validators, "");

        assertEq(summary.totalValidations, 2);
        assertEq(summary.passedCount, 1);
        assertEq(summary.failedCount, 0);
        assertEq(summary.pendingCount, 1);
        assertEq(summary.averageScore, 80); // Only completed validation
    }

    function test_GetSummary_PassedFailedCount() public {
        uint256 agentId = registerAgent(alice, "ipfs://agent1");

        bytes32 request1 = requestValidation(bob, validator1, agentId, "security");
        bytes32 request2 = requestValidation(bob, validator2, agentId, "performance");
        bytes32 request3 = requestValidation(charlie, validator1, agentId, "security");

        submitValidationResponse(validator1, request1, 80); // Passed
        submitValidationResponse(validator2, request2, 30); // Failed
        submitValidationResponse(validator1, request3, 50); // Passed

        address[] memory validators = new address[](0);
        IERC8004Validation.ValidationSummary memory summary = validationRegistry.getSummary(agentId, validators, "");

        assertEq(summary.totalValidations, 3);
        assertEq(summary.passedCount, 2); // >= 50
        assertEq(summary.failedCount, 1); // < 50
        assertEq(summary.pendingCount, 0);
    }

    function test_GetAllValidations() public {
        uint256 agentId = registerAgent(alice, "ipfs://agent1");

        requestValidation(bob, validator1, agentId, "security");
        requestValidation(bob, validator2, agentId, "performance");

        IERC8004Validation.ValidationRecord[] memory validations = validationRegistry.getAllValidations(agentId);
        assertEq(validations.length, 2);
    }

    function test_ValidationExists() public {
        uint256 agentId = registerAgent(alice, "ipfs://agent1");
        bytes32 requestHash = requestValidation(bob, validator1, agentId, "security");

        assertTrue(validationRegistry.validationExists(requestHash));
        assertFalse(validationRegistry.validationExists(bytes32(uint256(999))));
    }

    function test_RevertWhen_GetValidation_NotFound() public {
        vm.expectRevert();
        validationRegistry.getValidation(bytes32(uint256(999)));
    }
}
