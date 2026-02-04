// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ERC20} from "@solmate/tokens/ERC20.sol";

interface ERC677Receiver {
    function onTokenTransfer(
        address sender,
        uint256 value,
        bytes calldata data
    ) external;
}

contract LinkToken is ERC20 {
    uint256 constant INITIAL_SUPPLY = 1000 * 10**18;

    constructor() ERC20("Chainlink Token", "Link", 18) {
        _mint(msg.sender, INITIAL_SUPPLY);
    }

    function mint(address to, uint256 value) public {
        _mint(to, value);
    }

    function transferAndCall(
        address to,
        uint256 value,
        bytes calldata data
    ) public returns (bool success) {
        // 1. 普通转账
        super.transfer(to, value);

        // 2. 检查对方是不是个“智能合约”
        if (isContract(to)) {
            // 3. 通知
            contractFallback(to, value, data);
        }
        return true;
    }

    // 检查目标地址是否为合约地址，如果是EOA，就不需要触发回调
    function isContract(address _addr) private view returns (bool is_contract) {
        uint256 length;
        assembly {
            // 检查该地址是否有代码
            length := extcodesize(_addr)
        }
        return length > 0;
    }


    function contractFallback(
        address _to,
        uint256 _value,
        bytes memory _data
    ) private {
        // 类型转换
        ERC677Receiver receiver = ERC677Receiver(_to);
        // 回调
        receiver.onTokenTransfer(msg.sender, _value, _data);
    }


}