//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./LockRegistry.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";



//what if different TOKENNAME?
contract DellNFT is ERC721("Avarik Saga", "AVARIK") {

	uint256 public constant BATCH_LIMIT = 20;
    
    // ChildChainManagerProxy
    address public constant MINT_ADDRESS = 0xA6FA4fB5f76172d178d61B04b0ecd319C5d1C0aa; //polygon mainnet
    // address public constant MINT_ADDRESS = 0xb5505a6d998549090530911180f38aC5130101c6; //mumbai

	event WithdrawnBatch(address indexed user, uint256[] tokenIds);

	modifier onlyMinter() {
		require(msg.sender == MINT_ADDRESS, "!minter");
		_;
	}

	/**
     * @notice called when token is deposited on root chain
     * @dev Should be callable only by ChildChainManager
     * Should handle deposit by minting the required tokenId for user
     * Make sure minting is done only by this function
     * @param user user address for whom deposit is being done
     * @param depositData abi encoded tokenId
     */
    function deposit(address user, bytes calldata depositData) external onlyMinter {
        // deposit single
        if (depositData.length == 32) {
            uint256 tokenId = abi.decode(depositData, (uint256));
            _mint(user, tokenId);

        // deposit batch
        } else {
            uint256[] memory tokenIds = abi.decode(depositData, (uint256[]));
            uint256 length = tokenIds.length;
            for (uint256 i; i < length; i++) {
                _mint(user, tokenIds[i]);
            }
        }
    }

	/**
     * @notice called when user wants to withdraw token back to root chain
     * @dev Should burn user's token. This transaction will be verified when exiting on root chain
     * @param tokenId tokenId to withdraw
     */
    function withdraw(uint256 tokenId) external {
        require(msg.sender == ownerOf(tokenId), "ChildERC721: INVALID_TOKEN_OWNER");
        require(isUnlocked(tokenId), "Token is locked");
        _burn(tokenId);
    }

    /**
     * @notice called when user wants to withdraw multiple tokens back to root chain
     * @dev Should burn user's tokens. This transaction will be verified when exiting on root chain
     * @param tokenIds tokenId list to withdraw
     */
    function withdrawBatch(uint256[] calldata tokenIds) external {
        uint256 length = tokenIds.length;
        require(length <= BATCH_LIMIT, "ChildERC721: EXCEEDS_BATCH_LIMIT");
        for (uint256 i; i < length; i++) {
            uint256 tokenId = tokenIds[i];
            require(isUnlocked(tokenId), "Token is locked");
            require(msg.sender == ownerOf(tokenId), string(abi.encodePacked("ChildERC721: INVALID_TOKEN_OWNER ", tokenId)));
            _burn(tokenId);
        }
        emit WithdrawnBatch(msg.sender, tokenIds);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override {
        require(isUnlocked(tokenId), "Token is locked");
		ERC721.transferFrom(from, to, tokenId);
	}

	function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public override {
        require(isUnlocked(tokenId), "Token is locked");
		ERC721.safeTransferFrom(from, to, tokenId, _data);
	}

    function lockId(uint256 _id) external  {
        require(_exists(_id), "ERC721: token !exist");
        _lockId(_id);
	}

	function unlockId(uint256 _id) external  {
        require(_exists(_id), "ERC721: token !exist");
        _unlockId(_id);
	}

	function freeId(uint256 _id, address _contract) external  {
        require(_exists(_id), "ERC721: token !exist");
        _freeId(_id, _contract);
	}
}