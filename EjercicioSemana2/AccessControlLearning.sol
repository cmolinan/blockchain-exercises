// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
    Desarrollar un sistema complejo de control de accesos. Seguir las instrucciones:
    Cada cuenta puede tener uno o más roles. Los roles se pueden repetir en varias cuentas.

    0. Definir el rol de admin con el cual se inicializa el smart contract
    
    |           | MINTER | BURNER | PAUSER |
    | --------- | ------ | ------ | ------ |
    | Account 1 | True   | True   | True   |
    | Account 2 | True   | False  | True   |
    | Account 3 | False  | False  | True   |
    |   ...     |   ...  |  ...   |  ...   |
    
    1. definir un mapping doble para guardar una matriz de información.
       El mapping debe ser 'private'
    mapping 1 -> address => role
    mapping 2 -> role => boolean
    mapping(address => mapping(bytes32 => bool)) roles;

    2. definir metodo de lectura de datos de la matriz
        hasRole

    3. definir método para escribir datos en la matriz
        grantRole
        mapping[accout 1][MINTER] = true
        mapping[accout 1][BURNER] = true
        mapping[accout 1][PAUSER] = true
        
        mapping[accout 2][MINTER] = true
        mapping[accout 2][PAUSER] = true
        
        mapping[accout 3][PAUSER] = true

    4. crear modifier que verifica el acceso de los roles
    
    5. utilizar el constructor para inicializar valores

    EXTRA:

    6. Crear un método que se llame 'transferOwnership(address _newOwner)'
       Recibe un argumento: el address del nuevo owner
       Solo Puede ser llamado por una cuenta admin
       La cuenta admin transfiere sus derechos de admin a '_newOwner'
       Dispara el evento 'TransferOwnership(address _prevOwner, address _newOwner)'

    7. Crear un método lalmada 'renounceOwnership'
       La cuenta que lo llama es una cuenta admin
       Esta cuenta renuncia su derecho a ser admin
       Dispara un evento RenounceOwnership(msg.sender)

    8. Crear un método llamado 'grantRoleTemporarily'
       Le asigna un rol determinado a una cuenta por una cantidad 'N' de veces
       Dicha cuenta solo puede llamar métodos del tipo rol '_role' hasta 'N'
       function grantRoleTemporarily(address _account, bytes32 _role, uint256 _limit)
       El argumento '_limit' es mayor a uno - require
    
    9. Definir su getter llamado 'hasTemporaryRole(address _account, bytes32 _role) returns (bool, uint256)'
       Retorna dos valores:
        - indica si dicha cuenta tiene una rol temporal: true/false
        - indica la cantidad de veces restantes que puede llamar métodos del tipo rol '_role'
        - si no tiene rol temporal, devolver (false, 0)

 */
contract AccessControlLearning {
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
    

    // 4. crear modifier llamado 'onlyRole' que verifica el acceso de los roles
    //    Si falla la verificación emitir el error "Cuenta no tiene el rol necesario"
    //    Continúa con el otro elemnto "_ñ"
    modifier onlyRole(bytes32 _role) {
        require(roles[msg.sender][_role], "Cuenta no tiene el rol necesario");
        if (countsTemporalRole[msg.sender] != 0) {
            countsTemporalRole[msg.sender] -= 1;
            if (countsTemporalRole[msg.sender] == 0) roles[msg.sender][_role] = false;
        } 
        _;
    }

    // 6.    
    event TransferOwnership(address owner, address _newOwner);
    event RenounceOwnership(address owner);

    // 1. definir un mapping doble para guardar datos en una matriz
    // mapping 1 -> address => role
    // mapping 2 -> role => boolean
    mapping(address operador => mapping(bytes32 nombreRol => bool siTieneRolNo)) roles;
    
    // 5. utilizar el constructor para inicializar valores    
    constructor() {        
        roles[msg.sender][DEFAULT_ADMIN_ROLE] = true;
    }

    // 2. definir metodo de lectura de datos de la matriz llamado 'hasRole'
    //    debe ser un metodo que se puede heredar y también puede ser llamado de afuera (público)
    //    es un método de solo consulta

    function hasRole(
        address _account,
        bytes32 _role
    ) public view returns (bool) {
        return roles[_account][_role];
    }


    // 3. definir método para escribir datos en la matriz llamado 'grantRole'
    //    metodo protegido por el modifier 'onlyRole(DEFAULT_ADMIN_ROLE)'
    //    método público, puede ser heredado. es de escritura
    // function grantRole(address _account, bytes32 role) public;
    function grantRole(
        address _account,
        bytes32 _role
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        roles[_account][_role] = true;        
    }

    // 6. Crear un método que se llame 'transferOwnership(address _newOwner)'
    //    Recibe un argumento: el address del nuevo owner
    //    Solo Puede ser llamado por una cuenta admin
    //    La cuenta admin transfiere sus derechos de admin a '_newOwner'
    //    Dispara el evento 'TransferOwnership(address _prevOwner, address _newOwner)'
    function transferOwnership(
        address _newOwner
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        roles[msg.sender][DEFAULT_ADMIN_ROLE] = false;        
        roles[_newOwner][DEFAULT_ADMIN_ROLE] = true;        
        emit TransferOwnership(msg.sender, _newOwner);
    }

    // 7. Crear un método lalmada 'renounceOwnership'
    //    La cuenta que lo llama es una cuenta admin
    //    Esta cuenta renuncia su derecho a ser admin
    //    Dispara un evento RenounceOwnership(msg.sender)
    function renounceOwnership() public {
        roles[msg.sender][DEFAULT_ADMIN_ROLE] = false;        
        emit RenounceOwnership(msg.sender);
    }

    // 8. Crear un método llamado 'grantRoleTemporarily'
    //    Este metodo solo es llamado por una cuenta 'admin'
    //    Le asigna un rol determinado a una cuenta por una cantidad 'N' de veces
    //    Dicha cuenta solo puede llamar métodos del tipo rol '_role' hasta 'N'
    //    function grantRoleTemporarily(address _account, bytes32 _role, uint256 _limit)
    //    El argumento '_limit' es mayor a uno - require

    mapping(address account => uint256 limitTemporalRole) countsTemporalRole;

    function grantRoleTemporarily(
        address _account,
        bytes32 _role,
        uint256 _limit
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_limit >= 1, "El limite es mayor a 1");
        roles[_account][_role] = true;
        countsTemporalRole[_account] = _limit;
    }

    //  9. Definir su getter llamado 'hasTemporaryRole(address _account, bytes32 _role) returns (bool, uint256)'
    //    Retorna dos valores:
    //     - indica si dicha cuenta tiene una rol temporal: true/false
    //     - indica la cantidad de veces restantes que puede llamar métodos del tipo rol '_role'
    //     - si no tiene rol temporal, devolver (false, 0)

    function hasTemporaryRole(
        address _account,
        bytes32 _role
    ) public view returns (bool, uint256) {                 
         return  countsTemporalRole[_account] != 0 ? (roles[_account][_role], countsTemporalRole[_account]) : (false, 0);
    }
}
