// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract TokenFarm is Ownable {
    //stake tokens
    // unstake tokens
    // issue tokens
    // add allowed tokens
    // get eth value
    address[] public allowedTokens;
    mapping(address => mapping(address => uint256)) public stakingBalance;
    address[] public stakers;
    mapping(address => uint256) public uniqueTokensStaked;
    IERC20 public dapptoken;
    mapping(address => address) public priceFeedToken;

    constructor(address _dapptoken) public {
        dapptoken = IERC20(_dapptoken);
    }

    function setPriceFeedContract(address _token, address _pricefeed)
        public
        onlyOwner
    {
        priceFeedToken[_token] = _pricefeed;
    }

    function issueTokens() public {
        for (
            uint256 stakeholders = 0;
            stakeholders < stakers.length;
            stakeholders++
        ) {
            address recepient = stakers[stakeholders];
            uint256 usertotalValue = getUserTotalVal(recepient);
            dapptoken.transfer(recepient, usertotalValue);
        }
    }

    function getUserTotalVal(address _recepient) public view returns (uint256) {
        uint256 totalvalue = 0;
        require(uniqueTokensStaked[_recepient] > 0, "No tokens staked!!");
        for (
            uint256 allowedTokenIndex = 0;
            allowedTokenIndex < allowedTokens.length;
            allowedTokenIndex++
        ) {
            totalvalue =
                totalvalue +
                getUserSingleTokenValue(
                    _recepient,
                    allowedTokens[allowedTokenIndex]
                );
        }
        return totalvalue;
    }

    function getUserSingleTokenValue(address _recepient, address _token)
        public
        view
        returns (uint256)
    {
        if (uniqueTokensStaked[_recepient] <= 0) {
            return 0;
        }
        (uint256 price, uint256 decimals) = getTokenValue(_token);
        return ((stakingBalance[_token][_recepient] * price) / 10**decimals);
    }

    function getTokenValue(address _token)
        public
        view
        returns (uint256, uint256)
    {
        address priceFeedAddress = priceFeedToken[_token];
        AggregatorV3Interface pricefeed = AggregatorV3Interface(
            priceFeedAddress
        );
        (, int256 price, , , ) = pricefeed.latestRoundData();
        uint256 decimals = uint256(pricefeed.decimals());
        return (uint256(price), decimals);
    }

    function stakeTokens(uint256 _amount, address _token) public {
        require(isTokenAllowed(_token), "currently token is not allowed");
        require(_amount > 0, "amount should be greater than zero");
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        updateUniqueTokensStaked(msg.sender, _token);
        stakingBalance[_token][msg.sender] =
            stakingBalance[_token][msg.sender] +
            _amount;
        if (uniqueTokensStaked[msg.sender] == 1) {
            stakers.push(msg.sender);
        }
    }

    function unStakeTokens(address _token) public {
        uint256 balance = stakingBalance[_token][msg.sender];
        require(balance > 0, "The staking balance shoule not be zero");
        dapptoken.transfer(msg.sender, balance);
        stakingBalance[_token][msg.sender] = 0;
        uniqueTokensStaked[msg.sender] = uniqueTokensStaked[msg.sender] - 1;
    }

    function updateUniqueTokensStaked(address _user, address _token) internal {
        if (stakingBalance[_token][_user] <= 0) {
            uniqueTokensStaked[_user] = uniqueTokensStaked[_user] + 1;
        }
    }

    function addAllowedTokens(address _token) public onlyOwner {
        allowedTokens.push(_token);
    }

    function isTokenAllowed(address _token) public view returns (bool) {
        for (
            uint256 allowedTokenAddress = 0;
            allowedTokenAddress < allowedTokens.length;
            allowedTokenAddress++
        ) {
            if (allowedTokens[allowedTokenAddress] == _token) {
                return true;
            }
        }
        return false;
    }
}
