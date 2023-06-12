// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 *
 * Contrato para comprar tokens usando una moneda estable.
 *
 * USDC es considerado una moneda estable porque tiende a tener una equivalencia de
 * uno a uno con el dolar. Es decir, para poder obtener un USDC se tiene que pagar
 * un dolar. La mayoría de los exchanges acepta moneda fiat para poder cambiarlo
 * por otras monedas estables (USDC, USDT, entre otros).
 *
 * Para este ejercicio, utilizaremos una moneda estable (USDC) para poder comprar
 * un token recién creado (MTPV). En esencia, el smart contract de la moneda recién
 * creada recibe en primer lugar USDC y luego acuña una cantidad de MTPV a favor del
 * depositante. Para intercambiar de USDC a MTPV se utiliza un tipo de cambio que puede
 * ser fijo o cambiante dependiendo de ciertos criterios. En este ejercicio implementaremos
 * dos tipos de cambios: uno fijo y otro variable
 *
 * Tipo de cambio fijo:
 * 1 USDC = 25 MTPV
 * Un usuario llamará al método purchaseFixRate(uint256 _usdcAmount) para comprar MTPV.
 * Usar las siguientes viñetas como guía:
 *  - se valida que el usuario tenga suficiente balance de UDSC (balances >= _usdcAmount) - Error message: No tiene suficiente UDSC
 *  - se valida que el usuario haya dado allowance de USDC al contrato MTPV (allowance >= _usdcAmount) - Error message: No tiene suficiente
 *  - se transfieren USDC al contrato MTPV
 *  - se calcula la cantidad de MTPV tokens a recibir por la cantidad de USDC a depositar
 *  - se acuña la cantidad de MTPV calculados a favor del comprador
 *
 * Tipo de cambio variable:
 * Un usuario llamará al método purchaseVariableRate(uint256 _usdcAmount) para comprar MTPV.
 * Usar las siguientes viñetas como guía:
 *  - se valida que el usuario tenga suficiente balance de UDSC (balances >= _usdcAmount) - Error message: No tiene suficiente UDSC
 *  - se valida que el usuario haya dado allowance de USDC al contrato MTPV (allowance >= _usdcAmount) - Error message: No tiene suficiente
 *  - se transfieren USDC al contrato MTPV
 *  - se calcula la cantidad de MTPV tokens a recibir por la cantidad de USDC a depositar usando la fórmula de _getTokensByChange(uint256 _usdcAmount)
 *  - se acuña la cantidad de MTPV calculados a favor del comprador
 *
 * El objetivo de este ejercicio es practicar llamadas intercontrato y también
 * cómo se puede intercambiar un token por otro usando un tipo de cambio fijo o variable.
 */

// Do not modify USDC
contract USDC is ERC20, ERC20Burnable, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    constructor() ERC20("UDS Coin", "USDC") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) public onlyRole(BURNER_ROLE) {
        _burn(from, amount);
    }
}

interface IUSDC {
    function mint(address to, uint256 amount) external;

    function burn(address from, uint256 amount) external;

    function balanceOf(address account) external returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external;

    function allowance(address owner, address spender)
        external
        returns (uint256);
}

contract MiTokenParaVenta is ERC20, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    IUSDC usdc;
    uint256 public constant exchangeRate = 25;

    constructor(address _usdcAddress) ERC20("Mi Token Para Venta", "MTPV") {
        usdc = IUSDC(_usdcAddress);

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function purchaseFixRate(uint256 _usdcAmount) external {
        // verifica que caller tiene balance en USDC
        // usar usdc.balanceOf(msg.sender)

        require( IUSDC(usdc).balanceOf(msg.sender)>= _usdcAmount , "No tiene suficiente UDSC");

        // verifica que caller ha dado permiso al contrato MTPV
         // usar usdc.allowance(msg.sender, address(this))
        require( IUSDC(usdc).allowance(msg.sender, address(this)) >= _usdcAmount, "No tiene suficiente permiso");

        // transfiere USDC del caller al contrato MTPV
        IUSDC(usdc).transferFrom(msg.sender, address(this), _usdcAmount);

        // acuña tokens MTPV a favor del caller
        uint256 mtpvTokens = _getTokensByRate(_usdcAmount);
        _mint(msg.sender, mtpvTokens);
    }

    function purchaseVariableRate(uint256 _usdcAmount) external {
        // verifica que caller tiene balance en USDC
        // usar usdc.balanceOf(msg.sender)
        // require(?, "No tiene suficiente UDSC");
        require( IUSDC(usdc).balanceOf(msg.sender)>= _usdcAmount , "No tiene suficiente UDSC");
        
        // verifica que caller ha dado permiso al contrato MTPV
        // usar usdc.allowance(msg.sender, address(this))
        require( IUSDC(usdc).allowance(msg.sender, address(this)) >= _usdcAmount, "No tiene suficiente permiso");        

        // transfiere USDC del caller al contrato MTPV        
        IUSDC(usdc).transferFrom(msg.sender, address(this), _usdcAmount);

        // acuña tokens MTPV a favor del caller
        uint256 mtpvTokens = _getTokensByChange(_usdcAmount);
        _mint(msg.sender, mtpvTokens);
    }

    //////////////////////////////////////////////////
    //////////            HELPERS           //////////
    //////////////////////////////////////////////////

    function _getTokensByRate(uint256 _usdcAmount) internal pure returns (uint256) {
        // retorna aqui la cantidad de usdc que se deposita por el tipo de cambio exchangeRate
        // 1 USDC = 25 MTPV
        return _usdcAmount * 25;
    }

    function _getTokensByChange(uint256 _usdcAmount) internal view returns (uint256) {
        uint256 ts = totalSupply() / 10**18;
        uint256 price = ts**2 - 2 * ts + 1000;
        return _usdcAmount / price;
    }
}
