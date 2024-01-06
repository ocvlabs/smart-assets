# smart-assets

OnChainVision SmartAsset Library is a suite of Solidity contracts and codecs for creating and developing "Digital Assets as Smart Contracts," a.k.a. "Smart Assets."

## Overview

### Installation

#### Hardhat (npm)

```bash
npm install @ocvlabs/smart-assets
```

### Usage

Once installed, you can use the contracts by importing them and play around with your smart-asset:

```solidity
pragma solidity ^0.8.20;

import {SmartAsset, ISmartAsset} from "@ocvlabs/smart-assets/contracts/smart-asset/SmartAsset.sol";

contract SimpleSmartAssetRegistry {
    address public _assetAddress;
    address public _creatorAddress;

    constructor(address creatorAddress) {
        _creatorAddress = creatorAddress;
    }

    function createSmartAsset(
        string memory assetName, // your asset name
        string memory assetData, // could be text or anything
        string memory assetType, // (e.g. image, script, markup)
        bool isEncoded // tell if already encoded as base64
    ) public returns (address assetAddress) {
        // deploy asset as smart contract
        SmartAsset asset = new SmartAsset(
            address(this),
            _creatorAddress,
            assetName,
            assetData,
            assetType,
            isEncoded
        );
        // record asset address
        _assetAddress = address(asset);
        return assetAddress;
    }

    function viewSmartAsset(
        address assetAddress
    ) public view returns (string memory assetData) {
        assetData = ISmartAsset(assetAddress).viewAsset();
    }
}
```

_If you prefer not to code, you can use our [Smart Asset Deployer](https://smart-deployer.ocvlabs.com) or [Interactive Asset Builder](https://builder.ocvlabs.com) for secure and straightforward digital asset creation and deployment of smart interactive assets._

## License

OnChainVision Contracts is released under the [MIT License](LICENSE).
