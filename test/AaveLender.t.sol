// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/AaveLender.sol";

contract AaveLenderTest is Test {
    AaveLender public aaveLender;
    // The following addresses apply for Scroll Sepolia, change them depending on the network you're using
    address AAVE_POOL = 0x48914C788295b5db23aF2b5F0B3BE775C4eA9440;
    address DAI_TOKEN = 0x7984E363c38b590bB4CA35aEd5133Ef2c6619C40;
    address DAI_HOLDER = 0x707e55a12557E89915D121932F83dEeEf09E5d70;

    function setUp() public {
        // Start by deploying the AaveLender contract by passing the Aave Pool contract and the token to be lended, DAI in this case
        aaveLender = new AaveLender();
    }

    function testEarnYield() public {
        // This is the DAI AToken on Scroll Sepolia, we'll need this address later on this test
        address daiATokenAddress = address(IPool(AAVE_POOL).getReserveData(DAI_TOKEN).aTokenAddress);
        uint balanceStart = IERC20(DAI_TOKEN).balanceOf(DAI_HOLDER);
        // The DAI_HOLDER account already has testnet DAI on Scroll Sepolia, let's impersonify it
        vm.startPrank(DAI_HOLDER);

        // Remember to approve before staking the DAI
        IERC20(DAI_TOKEN).approve(address(aaveLender), 10 ether);
        aaveLender.stake(10 ether);

        // Let's travel to 50 days to the future to earn some DAI
        skip(50 days);

        // The staker should be able to unstake what was originally staked plus a little extra reward
        uint totalATokenBalance = IERC20(daiATokenAddress).balanceOf(DAI_HOLDER);
        IERC20(daiATokenAddress).approve(address(aaveLender), totalATokenBalance);
        aaveLender.withdraw(totalATokenBalance);
        vm.stopPrank();

        // The owner should be able to earn some DAI during the process, so his balance now should be greater than the balance at the beginning of this test
        uint balanceEnd = IERC20(DAI_TOKEN).balanceOf(DAI_HOLDER);
        assertGt(balanceEnd, balanceStart, "DAI Balance should increase.");
    }
}
