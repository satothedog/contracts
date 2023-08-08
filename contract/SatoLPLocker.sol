pragma solidity 0.8.19;

interface IERC721 {
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

interface INonfungiblePositionManager is IERC721 {
    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    function collect(CollectParams calldata params)
        external
        payable
        returns (uint256 amount0, uint256 amount1);
}

contract SatoLPLocker {
    address constant NONFUNGIBLE_POSITION_MANAGER =
        0x03a520b32C04BF3bEEf7BEb72E919cf822Ed34f1;
    INonfungiblePositionManager immutable _positionManager;

    address public lpFeeCollector;

    mapping(uint256 => uint256) public lockUpDeadline;

    mapping(uint256 => bool) public nftLocked;
    mapping(uint256 => bool) public withdrawTriggered;

    modifier onlyLPFeeCollector() {
        require(msg.sender == lpFeeCollector);
        _;
    }

    constructor() {
        _positionManager = INonfungiblePositionManager(
            NONFUNGIBLE_POSITION_MANAGER
        );
        lpFeeCollector = msg.sender;
    }

    function lockNFT(uint256 _tokenId) external onlyLPFeeCollector {
        require(!nftLocked[_tokenId], "NFT is already locked");

        IERC721(NONFUNGIBLE_POSITION_MANAGER).transferFrom(
            msg.sender,
            address(this),
            _tokenId
        );

        nftLocked[_tokenId] = true;
        lockUpDeadline[_tokenId] = block.timestamp + 60*60*24*30;
    }


    function withdrawNFT(uint256 _tokenId) external onlyLPFeeCollector {
        require(nftLocked[_tokenId], "NFT is not locked");

        require(
            block.timestamp >= lockUpDeadline[_tokenId],
            "Lock-up period has not ended yet"
        );

        IERC721(NONFUNGIBLE_POSITION_MANAGER).transferFrom(
            address(this),
            msg.sender,
            _tokenId
        );

        nftLocked[_tokenId] = false;
        lockUpDeadline[_tokenId] = 0;
        withdrawTriggered[_tokenId] = false;
    }

    function collectLPFees(uint256 _tokenId) external onlyLPFeeCollector {
        _positionManager.collect(
            INonfungiblePositionManager.CollectParams({
                tokenId: _tokenId,
                recipient: lpFeeCollector,
                amount0Max: type(uint128).max,
                amount1Max: type(uint128).max
            })
        );
    }

    function changeLPFeeCollector(address account) external onlyLPFeeCollector {
        require(account != address(0), "Address 0");
        lpFeeCollector = account;
    }
}
