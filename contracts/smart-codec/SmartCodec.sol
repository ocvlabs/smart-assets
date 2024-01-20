// SPDX-License-Identifier: MIT
// OnChainVision Contracts

pragma solidity ^0.8.20;

import {Base64} from "./Base64.sol";

/// @title Libraries/Utils for Encoding and Decoding Smart Assets
library SmartCodec {
    string internal constant MARKUP1 =
        "PCFET0NUWVBFIGh0bWw+IDxodG1sIGxhbmc9ZW4+IDxoZWFkPiA8dGl0bGU+";
    string internal constant MARKUP2 =
        "PC90aXRsZT4gPG1ldGEgaHR0cC1lcXVpdj1jb250ZW50LXR5cGUgY29udGVudD0idGV4dC9odG1sOyBjaGFyc2V0PVVURi04Ij4gPG1ldGEgY2hhcnNldD1VVEYtOD48bWV0YSBodHRwLWVxdWl2PVgtVUEtQ29tcGF0aWJsZSBjb250ZW50PSJJRT1lZGdlIj4gPG1ldGEgbmFtZT12aWV3cG9ydCBjb250ZW50PSJ3aWR0aD1kZXZpY2Utd2lkdGgsaW5pdGlhbC1zY2FsZT0xIj4gPHN0eWxlPg==";
    string internal constant MARKUP3 = "PC9zdHlsZT48L2hlYWQ+PGJvZHk+";
    string internal constant MARKUP4 = "IDxzY3JpcHQgdHlwZT1tb2R1bGU+IA==";
    string internal constant MARKUP5 = "IDwvc2NyaXB0PiA8L2JvZHk+IDwvaHRtbD4=";

    function encode64(string memory data) public pure returns (string memory) {
        return Base64.encode(bytes(data));
    }

    function decode64(string memory data) public pure returns (string memory) {
        bytes memory decodedData = Base64.decode(data);
        return string(abi.encodePacked(decodedData));
    }

    function encodeSvg64(
        string memory data
    ) external pure returns (string memory) {
        return
            string(
                abi.encodePacked("data:image/svg+xml;base64,", encode64(data))
            );
    }

    function encodeJson64(
        string memory data
    ) external pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    encode64(data)
                )
            );
    }

    function encodeMetadata(
        string memory name,
        string memory description,
        string memory image,
        string memory animation,
        string memory attributes
    ) external pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '{"name":"',
                    name,
                    '", "description":"',
                    description,
                    '", "image": "',
                    image,
                    '", "animation_url": "',
                    animation,
                    '", "attributes": [{',
                    attributes,
                    "}]}"
                )
            );
    }

    function encodeMarkup64(
        string memory data
    ) external pure returns (string memory) {
        return
            string(abi.encodePacked("data:text/html;base64,", encode64(data)));
    }

    function encodeMarkup64(
        string memory title,
        string memory style,
        string memory body,
        string memory setting,
        string memory script
    ) external pure returns (string memory) {
        string memory encodedMarkup = encodeMarkup(
            title,
            style,
            body,
            setting,
            script
        );
        string memory base64Document = string(
            abi.encodePacked("data:text/html;base64,", encode64(encodedMarkup))
        );
        return base64Document;
    }

    function encodeMarkup(
        string memory title,
        string memory style,
        string memory body,
        string memory setting,
        string memory script
    ) public pure returns (string memory) {
        string[] memory markups = processMarkup();
        string memory encodedMarkup = string(
            abi.encodePacked(
                markups[0],
                title,
                markups[1],
                style,
                markups[2],
                body,
                " ",
                setting,
                markups[3],
                script,
                markups[4]
            )
        );
        return encodedMarkup;
    }

    function processMarkup() internal pure returns (string[] memory markups) {
        markups = new string[](5);
        markups[0] = decode64(MARKUP1);
        markups[1] = decode64(MARKUP2);
        markups[2] = decode64(MARKUP3);
        markups[3] = decode64(MARKUP4);
        markups[4] = decode64(MARKUP5);
    }
}
