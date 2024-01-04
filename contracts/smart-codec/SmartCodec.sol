// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {Base64} from "./Base64.sol";

/// @title Libraries/Utils for Encoding and Decoding Smart Assets
library SmartCodec {
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
        return
            string(
                abi.encodePacked(
                    "data:text/html;base64,",
                    encode64(encodeMarkup(title, style, body, setting, script))
                )
            );
    }

    function encodeMarkup(
        string memory title,
        string memory style,
        string memory markup,
        string memory config,
        string memory script
    ) public pure returns (string memory) {
        string memory encodedMarkup = string(
            abi.encodePacked(
                "<!DOCTYPE html> <html lang=en> <head> <title>", // byte array[0]
                title,
                '</title> <meta http-equiv=content-type content="text/html; charset=UTF-8"> <meta charset=UTF-8><meta http-equiv=X-UA-Compatible content="IE=edge"> <meta name=viewport content="width=device-width,initial-scale=1"> <style>', // byte array[2]
                style,
                "</style></head><body>", // byte array[2]
                markup,
                " ",
                config,
                " <script type=module> ", // byte array[3]
                script,
                " </script> </body> </html>" // byte array[4]
            )
        );
        return encodedMarkup;
    }
}
