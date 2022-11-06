/**
 *Submitted for verification at BscScan.com on 2020-09-22
*/

pragma solidity 0.6.12;

import "./Lib/BEP20.sol";
import "./Lib/DateTime.sol";

// MrDriverToken with Governance.
contract MrDriverToken is BEP20('MrDriver', 'MDR') {
    uint256 public maxSupply = 200 * 10 ** 6 * 10 ** 18;

    uint256 public presaleRate = 1000;
    uint256 public safuRate = 200;
    uint256 public teamRate = 1000;
    uint256 public treasuryRate = 2800;
    uint256 public monthlyRate = 50;

    address public presaleAdmin = 0xFa3d3799a51e131d4DD5BF34d6505A9C0171eead;
    address public safuAddr = 0xFa3d3799a51e131d4DD5BF34d6505A9C0171eead;
    address public teamAddr = 0xFa3d3799a51e131d4DD5BF34d6505A9C0171eead;
    address public treasuryAddr = 0xFa3d3799a51e131d4DD5BF34d6505A9C0171eead;
    address public releaseAddr = 0xFa3d3799a51e131d4DD5BF34d6505A9C0171eead;

    bool presaleStarted = false;
    bool presaleEnded = false;

    uint lastReleaseTime = 0;
    uint releaseStartTime = 0;
    
    DateTime dateTime;

    constructor() public {

    }

    /// @notice Creates `_amount` token to `_to`. Must only be called by the owner (MasterChef).
    function mint(address _to, uint256 _amount) public onlyOwner returns(bool) {
        uint256 totalSupplyAfterMint = totalSupply().add(_amount);
        require(totalSupplyAfterMint < maxSupply, "MDR::can't mint over max supply");
        _mint(_to, _amount);
        _moveDelegates(address(0), _delegates[_to], _amount);
        return true;
    }

    function updatePresaleAdmin(address _presaleAdmin) public onlyOwner {
        presaleAdmin = _presaleAdmin;
    }

    function updateSafuAddr(address _safuAddr) public onlyOwner {
        safuAddr = _safuAddr;
    }

    function updateTeamAddr(address _teamAddr) public onlyOwner {
        teamAddr = _teamAddr;
    }

    function updateTreasuryAddr(address _treasuryAddr) public onlyOwner {
        treasuryAddr = _treasuryAddr;
    }

    function updateReleaseAddr(address _releaseAddr) public onlyOwner {
        releaseAddr = _releaseAddr;
    }

    function updatePresaleRate(uint16 _presaleRate) public onlyOwner {
        require(_presaleRate <= 2000, "MDR:: presale rate must not exceed 20%.");
        require(_presaleRate > 0, "MDR:: presale rate must be greater than 0.");

        presaleRate = _presaleRate;
    }

    function updateSafuRate(uint16 _safuRate) public onlyOwner {
        require(_safuRate <= 2000, "MDR:: safu rate must not exceed 20%.");
        require(_safuRate > 0, "MDR:: safu rate must be greater than 0.");

        safuRate = _safuRate;
    }

    function updateTeamRate(uint16 _teamRate) public onlyOwner {
        require(_teamRate <= 2000, "MDR:: team rate must not exceed 20%.");
        require(_teamRate > 0, "MDR:: team rate must be greater than 0.");

        teamRate = _teamRate;
    }

    function updateTreasuryRate(uint16 _treasuryRate) public onlyOwner {
        require(_treasuryRate <= 5000, "MDR:: treasury rate must not exceed 50%.");
        require(_treasuryRate > 0, "MDR:: treasury rate must be greater than 0.");

        treasuryRate = _treasuryRate;
    }

    function updateMonthlyRate(uint16 _monthlyRate) public onlyOwner {
        require(_monthlyRate <= 200, "MDR:: monthly rate must not exceed 2%.");
        require(_monthlyRate > 0, "MDR:: monthly rate must be greater than 0.");

        monthlyRate = _monthlyRate;
    }

    function startPresale() public onlyOwner {
        require(presaleStarted == false, "MDR:: presale started");
        require(presaleEnded == false, "MDR:: presale ended");

        _mint(presaleAdmin, maxSupply.mul(presaleRate).div(10000));
        presaleStarted = true;
    }

    function endPresale() public onlyOwner {
        require(presaleStarted == true, "MDR:: presale not started");
        require(presaleEnded == false, "MDR:: presale ended");

        _mint(safuAddr, maxSupply.mul(safuRate).div(10000));
        _mint(teamAddr, maxSupply.mul(teamRate).div(10000));
        _mint(treasuryAddr, maxSupply.mul(treasuryRate).div(10000));
        presaleEnded = true;
        lastReleaseTime = block.timestamp;
        releaseStartTime = block.timestamp;
    }

    function releaseTokenMonthly() public onlyOwner {
        uint startYear = dateTime.getYear(releaseStartTime);
        uint startMonth = dateTime.getMonth(releaseStartTime);
        uint lastYear = dateTime.getYear(lastReleaseTime);
        uint lastMonth = dateTime.getMonth(lastReleaseTime);
        uint curYear = dateTime.getYear(block.timestamp);
        uint curMonth = dateTime.getMonth(block.timestamp);

        require(curYear >= lastYear, "MDR:: release time is not valid");
        require(curMonth > lastMonth, "MDR:: release time is not valid");
        require(maxSupply > totalSupply(), "MDR:: all tokens released");

        uint diffMonth = (curYear * 12 + curMonth) - (startYear * 12 + startMonth);
        uint tSupply = maxSupply * diffMonth * monthlyRate / 10000 + totalSupply();

        if (tSupply > maxSupply) 
            tSupply = maxSupply;

        uint releaseAmount = tSupply - totalSupply();

        require(releaseAmount > 0, "MDR:: release amount is not valid" );

        _mint(releaseAddr, releaseAmount);
    }


    /// @dev A record of each accounts delegate
    mapping (address => address) internal _delegates;

    /// @notice A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint256 votes;
    }

    /// @notice A record of votes checkpoints for each account, by index
    mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping (address => uint32) public numCheckpoints;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    /// @notice A record of states for signing / validating signatures
    mapping (address => uint) public nonces;

      /// @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);

    /**
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param delegator The address to get delegatee for
     */
    function delegates(address delegator)
        external
        view
        returns (address)
    {
        return _delegates[delegator];
    }

   /**
    * @notice Delegate votes from `msg.sender` to `delegatee`
    * @param delegatee The address to delegate votes to
    */
    function delegate(address delegatee) external {
        return _delegate(msg.sender, delegatee);
    }

    /**
     * @notice Delegates votes from signatory to `delegatee`
     * @param delegatee The address to delegate votes to
     * @param nonce The contract state required to match the signature
     * @param expiry The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function delegateBySig(
        address delegatee,
        uint nonce,
        uint expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
    {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(name())),
                getChainId(),
                address(this)
            )
        );

        bytes32 structHash = keccak256(
            abi.encode(
                DELEGATION_TYPEHASH,
                delegatee,
                nonce,
                expiry
            )
        );

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                structHash
            )
        );

        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "MDR::delegateBySig: invalid signature");
        require(nonce == nonces[signatory]++, "MDR::delegateBySig: invalid nonce");
        require(now <= expiry, "MDR::delegateBySig: signature expired");
        return _delegate(signatory, delegatee);
    }

    /**
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account)
        external
        view
        returns (uint256)
    {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address account, uint blockNumber)
        external
        view
        returns (uint256)
    {
        require(blockNumber < block.number, "MDR::getPriorVotes: not yet determined");

        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }

    function _delegate(address delegator, address delegatee)
        internal
    {
        address currentDelegate = _delegates[delegator];
        uint256 delegatorBalance = balanceOf(delegator); // balance of underlying MDRs (not scaled);
        _delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _moveDelegates(address srcRep, address dstRep, uint256 amount) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                // decrease old representative
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint256 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint256 srcRepNew = srcRepOld.sub(amount);
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                // increase new representative
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint256 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint256 dstRepNew = dstRepOld.add(amount);
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(
        address delegatee,
        uint32 nCheckpoints,
        uint256 oldVotes,
        uint256 newVotes
    )
        internal
    {
        uint32 blockNumber = safe32(block.number, "MDR::_writeCheckpoint: block number exceeds 32 bits");

        if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function getChainId() internal pure returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }    


}