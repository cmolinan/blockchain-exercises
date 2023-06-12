// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// 8.
// import "@openzeppelin/contracts/access/AccessControl.sol"; // Usa esto mientras no completes ./AccessControlLearning.sol

// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./AccessControlLearning.sol";

/**

    Construir un TOKEN que cumple con las estándares del ERC20.
    Sigues las instrucciones a continuación:

    1. Heredar la interface IERC20 en TokenERC20_1 e implementar sus métodos requeridos
       Cada método dentro de la interface está definida.
       Crear los mappings y demás variables internas necesarias
        - approve:
            Cuando se aprueba a zero address: Mensaje de require: "Spender no puede ser zero"
        - transferFrom:
            Cuando la cuenta que llama no tiene permiso: Mensaje de require: "No tiene permiso para transferir"

    2. Heredar la interface IERC20Metadata en TokenERC20_1 e implementar sus métodos requeridos
       Cada método dentro de la interface está definida.
       Crear los mappings y demás variables internas necesarias

       Nota:
       - IERC20 define los metodos necesarios para transferir, dar permiso y llevar las cuentas del token
       - IERC20Metadata define los metodos que describen al token (nombre, simbolo y decimales)

    3. Nombre, símbolo y decimales serán incluidos en el smart contract a través del constructor

    4. Crear el método 'mint' que permite acuñar tokens a favor de una cuenta
        - mint no es parte del estándar ERC20
        - verifica que no se acuñe tokens a favor de la cuenta zero address. Mensaje require: "Mint a favor del address zero"
        - emite el evento Transfer(address(0), to, amount)
        - hacer publico este método
        - function mint(address to, uint256 amount) public {}

    5. Crear el método 'burn' que permite a una cuenta quemar SUS tokens
        - burn no es parte del estándar ERC20
        - verifica que de quien se queme tokens no es el address zero. Mensaje require: "Se quema tokens de address zero"
        - verifica que la cuenta de quien se quema tenga suficiente balance. Mensaje require: "Cuenta no tiene suficientes tokens"
        - emite el evento Transfer(from, address(0), amount)

    EXTRA:

    6. Incrementar permiso
       function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool);
       Permite incrementar el permiso otorgado con el método 'approve'
       No es parte del estandar ERC20 pero lo complementa
       emite el evento Approval(from, to, nuevoMonto)

    7. Decrementar permiso
       function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool);
       Permite disminuir el permiso otorgado con el método 'approve'
       No es parte del estandar ERC20 pero lo complementa
       emite el evento Approval(from, to, nuevoMonto)

    8. Incluir roles y proteger la acuñación
       Crear un método adicional y llamarlo 'mintProtected' que inlcuye el modifier 'onlyRole(MINTER_ROLE)'
       Importar al inicio del archivo el contrato roles import "./AccessControlLearning.sol";
       Heredar dicho contrato en el contrato 'TokenERC20_1'
       Crear un rol en el contrato:
       bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");


Testing:
ejecutar el comando: $ npx hardhat test test/testToken.js
 */

interface IERC20Metadata {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     * Returns a boolean value indicating whether the operation succeeded.
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     * Returns a boolean value indicating whether the operation succeeded.
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     * Returns a boolean value indicating whether the operation succeeded.
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

/**is IERC20, IERC20Metadata, AccessControl */
contract TokenERC20_1 is IERC20, IERC20Metadata, AccessControlLearning {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint256 totalMinted;

    // mapping de balances
    mapping(address billetera => uint256 balanceDeToken) _balances;

    // mapping de permisos:  owner => spender => amount
    mapping(address owner => mapping(address spender => uint256 amount)) _allowances;

    string _name;
    string _symbol;
    uint8 _decimals;

    // modifier onlyRole(bytes32 _role) override {
    //     require(roles[msg.sender][_role], "Cuenta no tiene el rol necesario");
    //     if (countsTemporalRole[msg.sender] != 0) {
    //         countsTemporalRole[msg.sender] -= 1;
    //         if (countsTemporalRole[msg.sender] == 0) roles[msg.sender][_role] = false;
    //     } 
    //     _;
    // }


    // 3. Nombre, símbolo y decimales serán incluidos en el smart contract a través del constructor
    constructor(string memory name_, string memory symbol_, uint8 decimals_) {
        // 4. El constructor debe inicializar el nombre, símbolo y decim
        //    al constructor de la clase base AccessControl.
        //        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        //        _setupRole(MINTER_ROLE, msg.sender);
        
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
    }

    /////////////////////////////////////////////////////////////////////////////
    ///////////     2. Heredar la interface IERC20Metadata            ///////////
    /////////////////////////////////////////////////////////////////////////////

    // name
    function name() public view returns (string memory) {
        return _name;        
    }

    // symbol
    function symbol() public view returns (string memory) {                
        return _symbol;
    }
    
    // decimals
    function decimals() public view returns (uint8) {
        return _decimals;
    }
 
    /////////////////////////////////////////////////////////////////////////////
    ///////////         1.  Heredar la interface IERC20               ///////////
    /////////////////////////////////////////////////////////////////////////////
    function totalSupply() public view returns (uint256) {
        return totalMinted;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        require(to != address(0), "No se puede transferir a la direccion cero");
        // 2. Validar que la cuenta de origen tenga suficientes
        // tokens para realizar la transferencia
        require(amount <= _balances[msg.sender], "No hay suficientes tokens para realizar la transferencia");
        // 3. Agregar la cantidad de tokens a la cuenta de destino
        _balances[to] += amount;
        // 4. Disminuir la cantidad de tokens de la cuenta de origen
        _balances[msg.sender] -= amount;
        // 5. Emitir evento Transfer
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];        
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        
        require(spender != address(0), "Spender no puede ser zero"); 

        // 2. Agregar la cantidad de tokens a la cuenta de destino
        _allowances[msg.sender][spender] = amount;
        // 3. Emitir evento Approval
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        require(to != address(0), "No se puede transferir a la direccion cero");
        require(amount <= _balances[from], "No hay suficientes tokens para realizar la transferencia");
        require(amount <= _allowances[from][msg.sender], "No hay suficientes tokens para realizar la transferencia");
        _balances[to] += amount;
        _balances[from] -= amount;
        _allowances[from][msg.sender] -= amount;
        emit Transfer(from, to, amount);
        return true;
    }

    /////////////////////////////////////////////////////////////////////////////
    ///////////                     Mint and Burn                     ///////////
    /////////////////////////////////////////////////////////////////////////////

    // 3. mint
    function mint(address to, uint256 amount) public {       
        require(to != address(0), "Mint a favor del address zero");
        _balances[to] += amount;        
        totalMinted += amount;
        emit Transfer(address(0), to, amount);
    }

    // 4. burn
    function burn(uint256 amount) public {        
        // require(msg.sender != address(0), "Se quema tokens de address zero"); 
        require((_balances[msg.sender]>= amount), "Cuenta no tiene suficientes tokens");
        _balances[msg.sender] -= amount;             
        totalMinted -= amount;
        emit Transfer(msg.sender, address(0), amount);
    }

    // EXTRA
    // 6. Incrementar permiso
    //    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool);
    //    Permite incrementar el permiso otorgado con el método 'approve'
    //    No es parte del estandar ERC20 pero lo complementa
    //    emite el evento Approval(from, to, nuevoMonto)

    function increaseAllowance(address spender, uint256 addedValue) public  returns (bool){
        _allowances[msg.sender][spender] += addedValue;
        emit Approval(msg.sender, spender, _allowances[msg.sender][spender]);
        return true;
    }

    // 7. Decrementar permiso
    //    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool);
    //    Permite disminuir el permiso otorgado con el método 'approve'
    //    No es parte del estandar ERC20 pero lo complementa
    //    emite el evento Approval(from, to, nuevoMonto)
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool){
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "El permiso no puede ser menor que el actual");
        _allowances[msg.sender][spender] -= subtractedValue;
        emit Approval(msg.sender, spender, _allowances[msg.sender][spender]);        
        return true;
   }

    // 8. Incluir roles y proteger la acuñación
    //    Crear un método adicional y llamarlo 'mintProtected' que inlcuye el modifier 'onlyRole(MINTER_ROLE)'
    //    Importar al inicio del archivo el contrato roles import "./AccessControlLearning.sol";
    //    Heredar dicho contrato en el contrato 'TokenERC20_1'
    //    Crear un rol en el contrato:
    //    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    function mintProtected(address to, uint256 amount) public onlyRole(MINTER_ROLE) {}

}
