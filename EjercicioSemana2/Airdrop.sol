// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * Desarrollar un contrato Airdrop
 *
 * Contexto: has creado un nuevo token ERC20 y te gustaría distribuirlo entre los primeros early adopters.
 * Asegurar una amplia distribución contribuye a generar expectativas en la comunidad y podría contribuir
 * al éxito del nuevo token.
 *
 * Has ideado varias maneras de distribuir tus tokens y son las siguientes:
 *
 *      1 - Has creado una lista blanca en la cual tu podrás inscribir cuentas (addresses) en batch.
 *          Esta es una cuenta protegida que solamente el 'owner' puede llamar.
 *          Las cuentas agregadas a la lista blanca tienen que reclamar sus token dentro de las 24 horas
 *          después de haber sido inscritos.  De otra manera pierden la oportunidad de recibir tokens.
 *          Pueden reclamar un número random de 1 - 1000 tokens. Un mismo usuario, solo puede participar
 *          una vez hasta que vuelva ser añadido por el admin o por el punto 4.
 *
 *          El contrato Airdrop, realizará una llamada intercontrato al contrato de tokens (TokenAIRDRP)
 *          para poder acuñar tokens a favor del participante.
 *
 *              - metodo batch: addToWhiteListBatch(address[] memory _addresses)
 *              - método mint: mintWithWhiteList()
 *                  * Mensaje error por no estar en whitelist: "Participante no esta en whitelist"
 *                  * Mensaje error cuando pasaron mas de 24 horas: "Pasaron mas de 24 horas"
 *
 *      2 - Has creado una lista azul en la cual puedes inscribir personas en batch.
 *          Esta es una cuenta protegida que solamente el 'owner' puede llamar.
 *          Esta lista azul es para cuentas (addresses) premium. Aquí las personas pueden obtener 10,000 tokens.
 *          Sin embargo, solo disponen de 60 minutos para reclamar sus tokens. A medida que pasa el tiempo,
 *          pueden obtener menos tokens. Si ya pasó 30 minutos, solo pueden reclamar 5,000 tokens. Si ya pasó
 *          45 minutos (3/4 del tiempo), solo pueden reclamar 2,500 tokens y así sucesivamente hasta llegar a 0.
 *          Si pasó más de 60 minutos, emitir un mensaje de error: "Pasaron mas de 60 minutos"
 *          Es decir, los tokens a recibir son indirectamente proporcional al tiempo pasado: a más tiempo pasado,
 *          menos tokens.
 *              - metodo batch: addToBlueListBatch(address[] memory _addresses)
 *              - método mint: mintWithBlueList()
 *                  * Mensaje error por no estar en bluelist: "Participante no esta en bluelist"
 *                  * Mensaje error cuando pasa mas de 60 minutos: "Pasaron mas de 60 minutos"
 *
 *                                      m                 |                 r
 *                  |_____________________________________._________________________________|
 *
 *      User ingresa a blue list                     User hace mint                      60 minutos
 *
 *                  m: tiempo pasado para hacer mint
 *                  r: tiempo restante para completar 60 minutos
 *                  m + r = 60 minutos
 *
 *                  prizeInTokens = 10,000
 *                  tokens a entregar = r / ( m + r) * prizeInTokens
 *
 *                  note: en solidity es mejor multiplicar primero y luego dividir
 *                  tokens a entregar = (r * prizeInTokens) / ( m + r)
 *
 *                  note: para capturar el momento en el que se llama un método usa 'block.timestamp'
 *
 *      3 - Las personas que deseen ingresar a la lista blanca, pueden quemar 1,000 tokens para ser incluidos
 *          automáticamente en la lista blanca. No puede ingresar a la lista blanca una cuenta que ya está en la lista
 *          blanca.
 *              - metodo para quemar: burnMyTokensToParticipate()
 *                  * Mensaje error si no tiene 1,000 tokens: "No tiene suficientes tokens para quemar"
 *                  * Mensaje error si ya está en la lista: "Esta en lista blanca"
 *
 */

// Do no modify TokenAIRDRP
contract TokenAIRDRP is ERC20, ERC20Burnable, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    constructor() ERC20("Token para Airdrop", "TAIRDRP") {
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

interface ITokenAIRDRP {
    function mint(address to, uint256 amount) external;

    function burn(address from, uint256 amount) external;

    function balanceOf(address account) external returns (uint256);
}

contract Airdrop is AccessControl {
    address tokenAIRDRPAddress;
    uint256 constant prizeTokensBlueList = 10_000 * 10**18;
    uint256 constant amntTokensToBurn = 1_000 * 10**18;

    constructor(address _tokenAddress) {
        tokenAIRDRPAddress = _tokenAddress;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    mapping(address => uint256 timeOfAddition) _whiteList;
    mapping(address => uint256 timeOfAddition) _blueList;

    function addToWhiteListBatch(address[] memory _addresses) public onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 _length = _addresses.length;
        for (uint256 i = 0; i < _length; i++) {            
            _whiteList[_addresses[i]] = block.timestamp;            
        }
    }

    function mintWithWhiteList() external {
        // accede a la informacion de msg.sender en _whiteList        
        // verifica si esta en whitelist        
        require(_whiteList[msg.sender] != 0, "Participante no esta en whitelist");

        // valida que no hayan pasado mas de 24 h
        require(block.timestamp <= _whiteList[msg.sender] + 24*60*60, "Pasaron mas de 24 horas");           

        // entrega tokens a msg.sender
        uint256 _amntTokens = _getRandom();
        ITokenAIRDRP(tokenAIRDRPAddress).mint(msg.sender, _amntTokens);

        // eliminar de whitelist a msg.sender
        _whiteList[msg.sender] = 0;
    }

    function addToBlueListBatch(address[] memory _addresses) public onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 _length = _addresses.length;
        for (uint256 i = 0; i < _length; i++) {
            _blueList[_addresses[i]] = block.timestamp; 
        }
    }

    function mintWithBlueList() external {
        // accede a la informacion de msg.sender en _blueList
        // verifica si esta en bluelist
        require(_blueList[msg.sender] != 0, "Participante no esta en bluelist");

        require(block.timestamp <= _blueList[msg.sender] + 60*60, "Pasaron mas de 60 minutos");

        uint256 tEnQueIngresoMsgSender = block.timestamp;
        uint256 _amntTokens = _getTokensBasedOnTime(tEnQueIngresoMsgSender);
        ITokenAIRDRP(tokenAIRDRPAddress).mint(msg.sender, _amntTokens);        
        // eliminar de blue list
        _blueList[msg.sender] = 0;
    }

    function balanceOf() public returns(uint256) {
        return ITokenAIRDRP(tokenAIRDRPAddress).balanceOf(msg.sender);
    }

    function burnMyTokensToParticipate() external {
        // usar amntTokensToBurn que es igual a 1,000 tokens
        // incluye validaciones        
        uint256 bal = ITokenAIRDRP(tokenAIRDRPAddress).balanceOf(msg.sender);
        require( bal >= amntTokensToBurn, "No tiene suficientes tokens para quemar");

        require(_whiteList[msg.sender] == 0, "Esta en lista blanca");

        // burn tokens del caller
        ITokenAIRDRP(tokenAIRDRPAddress).burn(msg.sender, amntTokensToBurn);

        // ingresa a msg.sender en lista blanca
        _whiteList[msg.sender] = block.timestamp;
    }

    //////////////////////////////////////////////////
    //////////            HELPERS           //////////
    //////////////////////////////////////////////////

    function _getTokensBasedOnTime(uint256 _enterTime) internal view returns (uint256) {
        // usa la variable prizeTokensBlueList

        // uint256 prizeTokensBlueList = 10_000;
        // multiplica primero y luego divide

        // m: tiempo pasado para hacer mint
        // r: tiempo restante para completar 60 minutos
        // m + r = 60 minutos

        uint256 totalTime = 60 * 60; // m + r -> 60 min x 60 sec
        uint256 timePased = _enterTime - _blueList[msg.sender]; // m -> block.timestamp - _enterTime
        require(totalTime > timePased, "Pasaron mas de 60 minutos");


        uint256 remainingTime = totalTime - timePased; // r -> totalTime - m
        // tokens a entregar = (r * prizeTokensBlueList) / ( m + r)
        return  (remainingTime * prizeTokensBlueList) / (totalTime);
    }

    function _getRandom() internal view returns (uint256) {
        // denro de "abi.encodePacked" se pueden añadir tantas varialbes globales como sean posibles
        // lo importante es que devuelve un numero random cada vez que ejecuta el metodo
        // random =  uint256(keccak256(abi.encodePacked(msg.sender, address(this), block.timestamp)))
        // user el mod % N para encontrar un numero random menor a N
        // el mod % empieza en cero
        // multiplicar por 10**18 por los decimales
        
        uint256 random = (uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender))) %  1001) + 1;
        return random * 10**18;
    }
}
