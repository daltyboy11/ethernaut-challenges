// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/cec0800c541c809f883a37f2dfb91ec4c90263c5/contracts/access/Ownable.sol";
import "./IDetectionBot.sol";
import "./Forta.sol";
import "./CryptoVault.sol";

contract DetectionBot is IDetectionBot, Ownable {
    Forta public immutable forta;
    CryptoVault public immutable cryptoVault;

    constructor(address _forta, address _cryptoVault) Ownable() public {
        forta = Forta(_forta);
        cryptoVault = CryptoVault(_cryptoVault);
    }

    function handleTransaction(address, bytes calldata msgData) external override {
        bytes4 sig = bytes4(msgData[0]) | bytes4(msgData[1]) >> 8 | bytes4(msgData[2]) >> 16 | bytes4(msgData[3]) >> 24;
        bytes4 delegateTransferSig = bytes4(keccak256(abi.encodePacked("delegateTransfer(address,uint256,address)")));
        if (sig == delegateTransferSig) {
            (,,address origSender) = abi.decode(msgData[4:], (address, uint256, address));
            // A delegateTransfer from the vault is an attempt to transfer the underlying via
            // the legacy token. We must disallow this.
            if (origSender == address(cryptoVault)) {
                forta.raiseAlert(owner());
            }
        }
    }
}
