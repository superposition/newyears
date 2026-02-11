export const AgentIdentityRegistryABI = [
  {
    "type": "constructor",
    "inputs": [
      {
        "name": "_stakingManager",
        "type": "address",
        "internalType": "address payable"
      }
    ],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "approve",
    "inputs": [
      {
        "name": "to",
        "type": "address",
        "internalType": "address"
      },
      {
        "name": "tokenId",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "balanceOf",
    "inputs": [
      {
        "name": "owner",
        "type": "address",
        "internalType": "address"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "deregister",
    "inputs": [
      {
        "name": "agentId",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "exists",
    "inputs": [
      {
        "name": "agentId",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "bool",
        "internalType": "bool"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "getAgentURI",
    "inputs": [
      {
        "name": "agentId",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "string",
        "internalType": "string"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "getAgentWallet",
    "inputs": [
      {
        "name": "agentId",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "address",
        "internalType": "address"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "getApproved",
    "inputs": [
      {
        "name": "tokenId",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "address",
        "internalType": "address"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "getDomainSeparator",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "bytes32",
        "internalType": "bytes32"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "getMetadata",
    "inputs": [
      {
        "name": "agentId",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "metadataKey",
        "type": "string",
        "internalType": "string"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "bytes",
        "internalType": "bytes"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "isApprovedForAll",
    "inputs": [
      {
        "name": "owner",
        "type": "address",
        "internalType": "address"
      },
      {
        "name": "operator",
        "type": "address",
        "internalType": "address"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "bool",
        "internalType": "bool"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "isAuthorizedOrOwner",
    "inputs": [
      {
        "name": "spender",
        "type": "address",
        "internalType": "address"
      },
      {
        "name": "agentId",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "bool",
        "internalType": "bool"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "name",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "string",
        "internalType": "string"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "owner",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "address",
        "internalType": "address"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "ownerOf",
    "inputs": [
      {
        "name": "tokenId",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "address",
        "internalType": "address"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "register",
    "inputs": [],
    "outputs": [
      {
        "name": "agentId",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "stateMutability": "payable"
  },
  {
    "type": "function",
    "name": "register",
    "inputs": [
      {
        "name": "agentURI",
        "type": "string",
        "internalType": "string"
      },
      {
        "name": "metadata",
        "type": "tuple[]",
        "internalType": "struct IERC8004Identity.MetadataEntry[]",
        "components": [
          {
            "name": "metadataKey",
            "type": "string",
            "internalType": "string"
          },
          {
            "name": "metadataValue",
            "type": "bytes",
            "internalType": "bytes"
          }
        ]
      }
    ],
    "outputs": [
      {
        "name": "agentId",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "stateMutability": "payable"
  },
  {
    "type": "function",
    "name": "register",
    "inputs": [
      {
        "name": "agentURI",
        "type": "string",
        "internalType": "string"
      }
    ],
    "outputs": [
      {
        "name": "agentId",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "stateMutability": "payable"
  },
  {
    "type": "function",
    "name": "renounceOwnership",
    "inputs": [],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "safeTransferFrom",
    "inputs": [
      {
        "name": "from",
        "type": "address",
        "internalType": "address"
      },
      {
        "name": "to",
        "type": "address",
        "internalType": "address"
      },
      {
        "name": "tokenId",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "safeTransferFrom",
    "inputs": [
      {
        "name": "from",
        "type": "address",
        "internalType": "address"
      },
      {
        "name": "to",
        "type": "address",
        "internalType": "address"
      },
      {
        "name": "tokenId",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "data",
        "type": "bytes",
        "internalType": "bytes"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "setAgentURI",
    "inputs": [
      {
        "name": "agentId",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "newURI",
        "type": "string",
        "internalType": "string"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "setAgentWallet",
    "inputs": [
      {
        "name": "agentId",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "newWallet",
        "type": "address",
        "internalType": "address"
      },
      {
        "name": "deadline",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "signature",
        "type": "bytes",
        "internalType": "bytes"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "setApprovalForAll",
    "inputs": [
      {
        "name": "operator",
        "type": "address",
        "internalType": "address"
      },
      {
        "name": "approved",
        "type": "bool",
        "internalType": "bool"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "setMetadata",
    "inputs": [
      {
        "name": "agentId",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "metadataKey",
        "type": "string",
        "internalType": "string"
      },
      {
        "name": "metadataValue",
        "type": "bytes",
        "internalType": "bytes"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "stakingManager",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "address",
        "internalType": "contract StakingManager"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "supportsInterface",
    "inputs": [
      {
        "name": "interfaceId",
        "type": "bytes4",
        "internalType": "bytes4"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "bool",
        "internalType": "bool"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "symbol",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "string",
        "internalType": "string"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "tokenByIndex",
    "inputs": [
      {
        "name": "index",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "tokenOfOwnerByIndex",
    "inputs": [
      {
        "name": "owner",
        "type": "address",
        "internalType": "address"
      },
      {
        "name": "index",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "tokenURI",
    "inputs": [
      {
        "name": "tokenId",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "string",
        "internalType": "string"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "totalSupply",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "transferFrom",
    "inputs": [
      {
        "name": "from",
        "type": "address",
        "internalType": "address"
      },
      {
        "name": "to",
        "type": "address",
        "internalType": "address"
      },
      {
        "name": "tokenId",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "transferOwnership",
    "inputs": [
      {
        "name": "newOwner",
        "type": "address",
        "internalType": "address"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "unsetAgentWallet",
    "inputs": [
      {
        "name": "agentId",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "event",
    "name": "AgentDeregistered",
    "inputs": [
      {
        "name": "agentId",
        "type": "uint256",
        "indexed": true,
        "internalType": "uint256"
      },
      {
        "name": "owner",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "Approval",
    "inputs": [
      {
        "name": "owner",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      },
      {
        "name": "approved",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      },
      {
        "name": "tokenId",
        "type": "uint256",
        "indexed": true,
        "internalType": "uint256"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "ApprovalForAll",
    "inputs": [
      {
        "name": "owner",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      },
      {
        "name": "operator",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      },
      {
        "name": "approved",
        "type": "bool",
        "indexed": false,
        "internalType": "bool"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "BatchMetadataUpdate",
    "inputs": [
      {
        "name": "_fromTokenId",
        "type": "uint256",
        "indexed": false,
        "internalType": "uint256"
      },
      {
        "name": "_toTokenId",
        "type": "uint256",
        "indexed": false,
        "internalType": "uint256"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "MetadataSet",
    "inputs": [
      {
        "name": "agentId",
        "type": "uint256",
        "indexed": true,
        "internalType": "uint256"
      },
      {
        "name": "indexedMetadataKey",
        "type": "string",
        "indexed": true,
        "internalType": "string"
      },
      {
        "name": "metadataKey",
        "type": "string",
        "indexed": false,
        "internalType": "string"
      },
      {
        "name": "metadataValue",
        "type": "bytes",
        "indexed": false,
        "internalType": "bytes"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "MetadataUpdate",
    "inputs": [
      {
        "name": "_tokenId",
        "type": "uint256",
        "indexed": false,
        "internalType": "uint256"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "OwnershipTransferred",
    "inputs": [
      {
        "name": "previousOwner",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      },
      {
        "name": "newOwner",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "Registered",
    "inputs": [
      {
        "name": "agentId",
        "type": "uint256",
        "indexed": true,
        "internalType": "uint256"
      },
      {
        "name": "agentURI",
        "type": "string",
        "indexed": false,
        "internalType": "string"
      },
      {
        "name": "owner",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "Transfer",
    "inputs": [
      {
        "name": "from",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      },
      {
        "name": "to",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      },
      {
        "name": "tokenId",
        "type": "uint256",
        "indexed": true,
        "internalType": "uint256"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "URIUpdated",
    "inputs": [
      {
        "name": "agentId",
        "type": "uint256",
        "indexed": true,
        "internalType": "uint256"
      },
      {
        "name": "newURI",
        "type": "string",
        "indexed": false,
        "internalType": "string"
      },
      {
        "name": "updatedBy",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      }
    ],
    "anonymous": false
  },
  {
    "type": "error",
    "name": "AgentNotFound",
    "inputs": []
  },
  {
    "type": "error",
    "name": "DeadlineTooFar",
    "inputs": []
  },
  {
    "type": "error",
    "name": "ECDSAInvalidSignature",
    "inputs": []
  },
  {
    "type": "error",
    "name": "ECDSAInvalidSignatureLength",
    "inputs": [
      {
        "name": "length",
        "type": "uint256",
        "internalType": "uint256"
      }
    ]
  },
  {
    "type": "error",
    "name": "ECDSAInvalidSignatureS",
    "inputs": [
      {
        "name": "s",
        "type": "bytes32",
        "internalType": "bytes32"
      }
    ]
  },
  {
    "type": "error",
    "name": "ERC721EnumerableForbiddenBatchMint",
    "inputs": []
  },
  {
    "type": "error",
    "name": "ERC721IncorrectOwner",
    "inputs": [
      {
        "name": "sender",
        "type": "address",
        "internalType": "address"
      },
      {
        "name": "tokenId",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "owner",
        "type": "address",
        "internalType": "address"
      }
    ]
  },
  {
    "type": "error",
    "name": "ERC721InsufficientApproval",
    "inputs": [
      {
        "name": "operator",
        "type": "address",
        "internalType": "address"
      },
      {
        "name": "tokenId",
        "type": "uint256",
        "internalType": "uint256"
      }
    ]
  },
  {
    "type": "error",
    "name": "ERC721InvalidApprover",
    "inputs": [
      {
        "name": "approver",
        "type": "address",
        "internalType": "address"
      }
    ]
  },
  {
    "type": "error",
    "name": "ERC721InvalidOperator",
    "inputs": [
      {
        "name": "operator",
        "type": "address",
        "internalType": "address"
      }
    ]
  },
  {
    "type": "error",
    "name": "ERC721InvalidOwner",
    "inputs": [
      {
        "name": "owner",
        "type": "address",
        "internalType": "address"
      }
    ]
  },
  {
    "type": "error",
    "name": "ERC721InvalidReceiver",
    "inputs": [
      {
        "name": "receiver",
        "type": "address",
        "internalType": "address"
      }
    ]
  },
  {
    "type": "error",
    "name": "ERC721InvalidSender",
    "inputs": [
      {
        "name": "sender",
        "type": "address",
        "internalType": "address"
      }
    ]
  },
  {
    "type": "error",
    "name": "ERC721NonexistentToken",
    "inputs": [
      {
        "name": "tokenId",
        "type": "uint256",
        "internalType": "uint256"
      }
    ]
  },
  {
    "type": "error",
    "name": "ERC721OutOfBoundsIndex",
    "inputs": [
      {
        "name": "owner",
        "type": "address",
        "internalType": "address"
      },
      {
        "name": "index",
        "type": "uint256",
        "internalType": "uint256"
      }
    ]
  },
  {
    "type": "error",
    "name": "InvalidAddress",
    "inputs": []
  },
  {
    "type": "error",
    "name": "InvalidSignature",
    "inputs": []
  },
  {
    "type": "error",
    "name": "NotAuthorized",
    "inputs": []
  },
  {
    "type": "error",
    "name": "OwnableInvalidOwner",
    "inputs": [
      {
        "name": "owner",
        "type": "address",
        "internalType": "address"
      }
    ]
  },
  {
    "type": "error",
    "name": "OwnableUnauthorizedAccount",
    "inputs": [
      {
        "name": "account",
        "type": "address",
        "internalType": "address"
      }
    ]
  },
  {
    "type": "error",
    "name": "ReservedMetadataKey",
    "inputs": []
  },
  {
    "type": "error",
    "name": "SignatureExpired",
    "inputs": []
  }
] as const;

export const ReputationRegistryABI = [
  {
    "type": "constructor",
    "inputs": [
      {
        "name": "_identityRegistry",
        "type": "address",
        "internalType": "address"
      }
    ],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "appendResponse",
    "inputs": [
      {
        "name": "agentId",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "clientAddress",
        "type": "address",
        "internalType": "address"
      },
      {
        "name": "feedbackIndex",
        "type": "uint64",
        "internalType": "uint64"
      },
      {
        "name": "responseURI",
        "type": "string",
        "internalType": "string"
      },
      {
        "name": "responseHash",
        "type": "bytes32",
        "internalType": "bytes32"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "getClients",
    "inputs": [
      {
        "name": "agentId",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "address[]",
        "internalType": "address[]"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "getIdentityRegistry",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "address",
        "internalType": "address"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "getLastIndex",
    "inputs": [
      {
        "name": "agentId",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "clientAddress",
        "type": "address",
        "internalType": "address"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "uint64",
        "internalType": "uint64"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "getResponseCount",
    "inputs": [
      {
        "name": "agentId",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "clientAddress",
        "type": "address",
        "internalType": "address"
      },
      {
        "name": "feedbackIndex",
        "type": "uint64",
        "internalType": "uint64"
      },
      {
        "name": "responders",
        "type": "address[]",
        "internalType": "address[]"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "uint64",
        "internalType": "uint64"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "getSummary",
    "inputs": [
      {
        "name": "agentId",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "clientAddresses",
        "type": "address[]",
        "internalType": "address[]"
      },
      {
        "name": "tag1",
        "type": "string",
        "internalType": "string"
      },
      {
        "name": "tag2",
        "type": "string",
        "internalType": "string"
      }
    ],
    "outputs": [
      {
        "name": "count",
        "type": "uint64",
        "internalType": "uint64"
      },
      {
        "name": "summaryValue",
        "type": "int128",
        "internalType": "int128"
      },
      {
        "name": "summaryValueDecimals",
        "type": "uint8",
        "internalType": "uint8"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "giveFeedback",
    "inputs": [
      {
        "name": "agentId",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "value",
        "type": "int128",
        "internalType": "int128"
      },
      {
        "name": "valueDecimals",
        "type": "uint8",
        "internalType": "uint8"
      },
      {
        "name": "tag1",
        "type": "string",
        "internalType": "string"
      },
      {
        "name": "tag2",
        "type": "string",
        "internalType": "string"
      },
      {
        "name": "endpoint",
        "type": "string",
        "internalType": "string"
      },
      {
        "name": "feedbackURI",
        "type": "string",
        "internalType": "string"
      },
      {
        "name": "feedbackHash",
        "type": "bytes32",
        "internalType": "bytes32"
      }
    ],
    "outputs": [
      {
        "name": "feedbackIndex",
        "type": "uint64",
        "internalType": "uint64"
      }
    ],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "identityRegistry",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "address",
        "internalType": "contract AgentIdentityRegistry"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "readAllFeedback",
    "inputs": [
      {
        "name": "agentId",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "clientAddresses",
        "type": "address[]",
        "internalType": "address[]"
      },
      {
        "name": "tag1",
        "type": "string",
        "internalType": "string"
      },
      {
        "name": "tag2",
        "type": "string",
        "internalType": "string"
      },
      {
        "name": "includeRevoked",
        "type": "bool",
        "internalType": "bool"
      }
    ],
    "outputs": [
      {
        "name": "agentIds",
        "type": "uint256[]",
        "internalType": "uint256[]"
      },
      {
        "name": "clients",
        "type": "address[]",
        "internalType": "address[]"
      },
      {
        "name": "feedbackIndexes",
        "type": "uint64[]",
        "internalType": "uint64[]"
      },
      {
        "name": "values",
        "type": "int128[]",
        "internalType": "int128[]"
      },
      {
        "name": "valueDecimalsArr",
        "type": "uint8[]",
        "internalType": "uint8[]"
      },
      {
        "name": "tag1s",
        "type": "string[]",
        "internalType": "string[]"
      },
      {
        "name": "tag2s",
        "type": "string[]",
        "internalType": "string[]"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "readFeedback",
    "inputs": [
      {
        "name": "agentId",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "clientAddress",
        "type": "address",
        "internalType": "address"
      },
      {
        "name": "feedbackIndex",
        "type": "uint64",
        "internalType": "uint64"
      }
    ],
    "outputs": [
      {
        "name": "value",
        "type": "int128",
        "internalType": "int128"
      },
      {
        "name": "valueDecimals",
        "type": "uint8",
        "internalType": "uint8"
      },
      {
        "name": "tag1",
        "type": "string",
        "internalType": "string"
      },
      {
        "name": "tag2",
        "type": "string",
        "internalType": "string"
      },
      {
        "name": "isRevoked",
        "type": "bool",
        "internalType": "bool"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "revokeFeedback",
    "inputs": [
      {
        "name": "agentId",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "feedbackIndex",
        "type": "uint64",
        "internalType": "uint64"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "stakingManager",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "address",
        "internalType": "contract StakingManager"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "event",
    "name": "FeedbackRevoked",
    "inputs": [
      {
        "name": "agentId",
        "type": "uint256",
        "indexed": true,
        "internalType": "uint256"
      },
      {
        "name": "clientAddress",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      },
      {
        "name": "feedbackIndex",
        "type": "uint64",
        "indexed": true,
        "internalType": "uint64"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "NewFeedback",
    "inputs": [
      {
        "name": "agentId",
        "type": "uint256",
        "indexed": true,
        "internalType": "uint256"
      },
      {
        "name": "clientAddress",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      },
      {
        "name": "feedbackIndex",
        "type": "uint64",
        "indexed": false,
        "internalType": "uint64"
      },
      {
        "name": "value",
        "type": "int128",
        "indexed": false,
        "internalType": "int128"
      },
      {
        "name": "valueDecimals",
        "type": "uint8",
        "indexed": false,
        "internalType": "uint8"
      },
      {
        "name": "indexedTag1",
        "type": "string",
        "indexed": true,
        "internalType": "string"
      },
      {
        "name": "tag1",
        "type": "string",
        "indexed": false,
        "internalType": "string"
      },
      {
        "name": "tag2",
        "type": "string",
        "indexed": false,
        "internalType": "string"
      },
      {
        "name": "endpoint",
        "type": "string",
        "indexed": false,
        "internalType": "string"
      },
      {
        "name": "feedbackURI",
        "type": "string",
        "indexed": false,
        "internalType": "string"
      },
      {
        "name": "feedbackHash",
        "type": "bytes32",
        "indexed": false,
        "internalType": "bytes32"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "ResponseAppended",
    "inputs": [
      {
        "name": "agentId",
        "type": "uint256",
        "indexed": true,
        "internalType": "uint256"
      },
      {
        "name": "clientAddress",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      },
      {
        "name": "feedbackIndex",
        "type": "uint64",
        "indexed": false,
        "internalType": "uint64"
      },
      {
        "name": "responder",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      },
      {
        "name": "responseURI",
        "type": "string",
        "indexed": false,
        "internalType": "string"
      },
      {
        "name": "responseHash",
        "type": "bytes32",
        "indexed": false,
        "internalType": "bytes32"
      }
    ],
    "anonymous": false
  },
  {
    "type": "error",
    "name": "AgentNotFound",
    "inputs": []
  },
  {
    "type": "error",
    "name": "AlreadyRevoked",
    "inputs": []
  },
  {
    "type": "error",
    "name": "DecimalsTooHigh",
    "inputs": []
  },
  {
    "type": "error",
    "name": "FeedbackNotFound",
    "inputs": []
  },
  {
    "type": "error",
    "name": "SelfFeedbackNotAllowed",
    "inputs": []
  },
  {
    "type": "error",
    "name": "Unauthorized",
    "inputs": []
  },
  {
    "type": "error",
    "name": "ValueOutOfRange",
    "inputs": []
  }
] as const;

export const ValidationRegistryABI = [
  {
    "type": "constructor",
    "inputs": [
      {
        "name": "_identityRegistry",
        "type": "address",
        "internalType": "address"
      }
    ],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "getAgentValidations",
    "inputs": [
      {
        "name": "agentId",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "bytes32[]",
        "internalType": "bytes32[]"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "getSummary",
    "inputs": [
      {
        "name": "agentId",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "validatorAddresses",
        "type": "address[]",
        "internalType": "address[]"
      },
      {
        "name": "tag",
        "type": "string",
        "internalType": "string"
      }
    ],
    "outputs": [
      {
        "name": "count",
        "type": "uint64",
        "internalType": "uint64"
      },
      {
        "name": "averageResponse",
        "type": "uint8",
        "internalType": "uint8"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "getValidationStatus",
    "inputs": [
      {
        "name": "requestHash",
        "type": "bytes32",
        "internalType": "bytes32"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "address",
        "internalType": "address"
      },
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "",
        "type": "uint8",
        "internalType": "uint8"
      },
      {
        "name": "",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "",
        "type": "string",
        "internalType": "string"
      },
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "getValidatorRequests",
    "inputs": [
      {
        "name": "validatorAddress",
        "type": "address",
        "internalType": "address"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "bytes32[]",
        "internalType": "bytes32[]"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "identityRegistry",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "address",
        "internalType": "contract AgentIdentityRegistry"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "validationRequest",
    "inputs": [
      {
        "name": "validatorAddress",
        "type": "address",
        "internalType": "address"
      },
      {
        "name": "agentId",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "requestURI",
        "type": "string",
        "internalType": "string"
      },
      {
        "name": "requestHash",
        "type": "bytes32",
        "internalType": "bytes32"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "validationResponse",
    "inputs": [
      {
        "name": "requestHash",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "response",
        "type": "uint8",
        "internalType": "uint8"
      },
      {
        "name": "responseURI",
        "type": "string",
        "internalType": "string"
      },
      {
        "name": "responseHash",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "tag",
        "type": "string",
        "internalType": "string"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "event",
    "name": "ValidationRequest",
    "inputs": [
      {
        "name": "validatorAddress",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      },
      {
        "name": "agentId",
        "type": "uint256",
        "indexed": true,
        "internalType": "uint256"
      },
      {
        "name": "requestURI",
        "type": "string",
        "indexed": false,
        "internalType": "string"
      },
      {
        "name": "requestHash",
        "type": "bytes32",
        "indexed": true,
        "internalType": "bytes32"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "ValidationResponse",
    "inputs": [
      {
        "name": "validatorAddress",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      },
      {
        "name": "agentId",
        "type": "uint256",
        "indexed": true,
        "internalType": "uint256"
      },
      {
        "name": "requestHash",
        "type": "bytes32",
        "indexed": true,
        "internalType": "bytes32"
      },
      {
        "name": "response",
        "type": "uint8",
        "indexed": false,
        "internalType": "uint8"
      },
      {
        "name": "responseURI",
        "type": "string",
        "indexed": false,
        "internalType": "string"
      },
      {
        "name": "responseHash",
        "type": "bytes32",
        "indexed": false,
        "internalType": "bytes32"
      },
      {
        "name": "tag",
        "type": "string",
        "indexed": false,
        "internalType": "string"
      }
    ],
    "anonymous": false
  },
  {
    "type": "error",
    "name": "AgentNotFound",
    "inputs": []
  },
  {
    "type": "error",
    "name": "InvalidResponse",
    "inputs": []
  },
  {
    "type": "error",
    "name": "NotAuthorized",
    "inputs": []
  },
  {
    "type": "error",
    "name": "ValidationAlreadyExists",
    "inputs": []
  },
  {
    "type": "error",
    "name": "ValidationNotFound",
    "inputs": []
  }
] as const;

export const StakingManagerABI = [
  {
    "type": "constructor",
    "inputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "receive",
    "stateMutability": "payable"
  },
  {
    "type": "function",
    "name": "SLASH_PERCENTAGE",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "STAKE_AMOUNT",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "agentSlashed",
    "inputs": [
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "bool",
        "internalType": "bool"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "agentStakes",
    "inputs": [
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "checkAndSlash",
    "inputs": [
      {
        "name": "agentId",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "averageReputation",
        "type": "int256",
        "internalType": "int256"
      },
      {
        "name": "feedbackCount",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "getStakeInfo",
    "inputs": [
      {
        "name": "agentId",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [
      {
        "name": "stakedAmount",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "isSlashed",
        "type": "bool",
        "internalType": "bool"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "getTotalStaked",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "identityRegistry",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "address",
        "internalType": "address"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "owner",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "address",
        "internalType": "address"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "renounceOwnership",
    "inputs": [],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "reputationRegistry",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "address",
        "internalType": "address"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "setIdentityRegistry",
    "inputs": [
      {
        "name": "_identityRegistry",
        "type": "address",
        "internalType": "address"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "setReputationRegistry",
    "inputs": [
      {
        "name": "_reputationRegistry",
        "type": "address",
        "internalType": "address"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "stake",
    "inputs": [
      {
        "name": "agentId",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [],
    "stateMutability": "payable"
  },
  {
    "type": "function",
    "name": "transferOwnership",
    "inputs": [
      {
        "name": "newOwner",
        "type": "address",
        "internalType": "address"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "unstake",
    "inputs": [
      {
        "name": "recipient",
        "type": "address",
        "internalType": "address"
      },
      {
        "name": "agentId",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "event",
    "name": "IdentityRegistrySet",
    "inputs": [
      {
        "name": "identityRegistry",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "OwnershipTransferred",
    "inputs": [
      {
        "name": "previousOwner",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      },
      {
        "name": "newOwner",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "ReputationRegistrySet",
    "inputs": [
      {
        "name": "reputationRegistry",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "StakeLocked",
    "inputs": [
      {
        "name": "agentId",
        "type": "uint256",
        "indexed": true,
        "internalType": "uint256"
      },
      {
        "name": "staker",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      },
      {
        "name": "amount",
        "type": "uint256",
        "indexed": false,
        "internalType": "uint256"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "StakeRefunded",
    "inputs": [
      {
        "name": "agentId",
        "type": "uint256",
        "indexed": true,
        "internalType": "uint256"
      },
      {
        "name": "recipient",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      },
      {
        "name": "amount",
        "type": "uint256",
        "indexed": false,
        "internalType": "uint256"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "StakeSlashed",
    "inputs": [
      {
        "name": "agentId",
        "type": "uint256",
        "indexed": true,
        "internalType": "uint256"
      },
      {
        "name": "slashedAmount",
        "type": "uint256",
        "indexed": false,
        "internalType": "uint256"
      },
      {
        "name": "remainingAmount",
        "type": "uint256",
        "indexed": false,
        "internalType": "uint256"
      }
    ],
    "anonymous": false
  },
  {
    "type": "error",
    "name": "AlreadySlashed",
    "inputs": []
  },
  {
    "type": "error",
    "name": "AlreadyStaked",
    "inputs": []
  },
  {
    "type": "error",
    "name": "InsufficientStake",
    "inputs": []
  },
  {
    "type": "error",
    "name": "InvalidAddress",
    "inputs": []
  },
  {
    "type": "error",
    "name": "InvalidAmount",
    "inputs": []
  },
  {
    "type": "error",
    "name": "NotStaked",
    "inputs": []
  },
  {
    "type": "error",
    "name": "OwnableInvalidOwner",
    "inputs": [
      {
        "name": "owner",
        "type": "address",
        "internalType": "address"
      }
    ]
  },
  {
    "type": "error",
    "name": "OwnableUnauthorizedAccount",
    "inputs": [
      {
        "name": "account",
        "type": "address",
        "internalType": "address"
      }
    ]
  },
  {
    "type": "error",
    "name": "ReentrancyGuardReentrantCall",
    "inputs": []
  },
  {
    "type": "error",
    "name": "TransferFailed",
    "inputs": []
  },
  {
    "type": "error",
    "name": "Unauthorized",
    "inputs": []
  }
] as const;
