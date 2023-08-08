pragma solidity ^0.8.0;

contract SATO is ERC20, Ownable {
    constructor() ERC20("Sato", "SATO") {
        _mint(msg.sender, 1000000 * 10 ** decimals());
    }

    function burn(uint256 amount) public virtual{
        _burn(msg.sender, amount);
    }
}

