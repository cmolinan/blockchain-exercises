// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

/**
 * Ejercicio integrador 1
 *
 * Vamos a usar mappings para manejar la propiedad de activos de usuario.
 * Usaremos los tres niveles de mapping más usados:
 * - single mapping
 * - double mapping
 * - triple mapping
 *
 * 1 - Mapping simple:
 * Usaremos un mapping simple para guardar la cantidad de activos que tiene cada usuario
 * Los usuarios se ven representados por sus billeteras
 * Los cantidad de activos es un número entero
 * mapping(address usuario => uint256 cantidad) public activosSimple;
 * Nota:
 *  - crear un método setter guardarActivoSimple que reciba un address y un uint256
 *  - validar que el address no sea 0x00. Mensaje de error: "El address no puede ser 0x00"
 *
 * 2 - Mapping doble:
 * Usaremos un mapping doble para guardar la cantidad de cada tipo de activo que tiene cada usuario
 * Es decir, un usuario puede tener varios tipos de activos y cada uno de ellos puede tener una cantidad distinta
 * Los usuarios se ven representados por sus billeteras
 * Los activos se represetan con códigos que van del 000001 al 999999
 * La cantidad de activos es un número entero
 * mapping(address usuario => mapping(uint256 activoId => uint256 cantidad)) public activosDouble;
 * Nota:
 *  - crear un método setter guardarActivoDoble que reciba un address, un uint256 y un uint256
 *  - validar que el address no sea 0x00. Mensaje de error: "El address no puede ser 0x00"
 *  - validar que los códigos de activo estén entre 000001 y 999999. Mensaje de error: "Codigo de activo invalido"
 *
 * 3 - Mapping triple:
 * Usaremos un mapping triple para guardar la cantidad de cada tipo de activo que tiene cada usuario de cada ciudad
 * Es decir, en cada ciudad hay un usuario que tiene varios tipos de activos y cada uno de ellos puede tener una cantidad distinta
 * Las ciudades se representan con códigos que van del 000001 al 999999
 * Los usuarios se ven representados por sus billeteras
 * Los activos se represetan con códigos que van del 000001 al 999999
 * La cantidad de activos es un número entero
 * mapping(uint256 ciudadId => mapping(address usuario => mapping(uint256 activoId => uint256 cantidad))) public activosTriple;
 * Nota:
 *  - crear un método setter guardarActivoTriple que reciba un address, un uint256, un uint256 y un uint256
 *  - validar que el address no sea 0x00. Mensaje de error: "El address no puede ser 0x00"
 *  - validar que los códigos de activo estén entre 000001 y 999999. Mensaje de error: "Codigo de activo invalido"
 *  - validar que los códigos de ciudad estén entre 000001 y 999999. Mensaje de error: "Codigo de ciudad invalido"
 *
 * Para manejar los tres errores mencionados:
 * 1 - Validar que el address no sea 0x00
 *      Usar un require con la condición: _usuario != address(0)
 *      (pude ir en un modifier o en el propio método)
 *
 * 2 - Validar que los códigos de activo
 *      Usar un revert
 *
 * 3 - Validar que los códigos de ciudad
 *      Crear un Custom Error llamado CiudadInvalidaError(uint256 ciudadId)
 *      npx hardhat test test/EjercicioIntegrador_1.ts
 */

contract Mapping {
    // 1 - Mapping simple
    mapping(address usuario => uint256 cantidad) public activosSimple;

    function guardarActivoSimple(address _usuario, uint256 _cantidad) public {        
        require(_usuario != address(0), "El address no puede ser 0x00");        
        activosSimple[_usuario] = _cantidad;
    }

    // 2 - Mapping double
    mapping(address usuario => mapping(uint256 activoId => uint256 cantidad))
        public activosDouble;

    function guardarActivoDoble(
        address _usuario,
        uint256 _activoID,
        uint256 _cantidad
    ) public {
        require(_usuario != address(0), "El address no puede ser 0x00");        
        require(_activoID > 0 && _activoID  < 1000000, "Codigo de activo invalido");        
        activosDouble[_usuario][_activoID] = _cantidad;
    }

    // 3 - Mapping triple
    error CiudadInvalidaError(uint256 ciudadId);

    mapping(uint256 ciudadId => mapping(address usuario => mapping(uint256 activoId => uint256 cantidad)))
        public activosTriple;

    function guardarActivoTriple(
        uint256 _ciudadId,
        address _usuario,
        uint256 _activoID,
        uint256 _cantidad

    ) public {
        require(_usuario != address(0), "El address no puede ser 0x00");        
        
        if (_activoID <= 0 || _activoID  >= 1000000)
            revert("Codigo de activo invalido");

        if (_ciudadId <= 0 || _ciudadId  >= 1000000) revert CiudadInvalidaError({ciudadId: _ciudadId});

        activosTriple[_ciudadId][_usuario][_activoID] = _cantidad;
        assert(activosTriple[_ciudadId][_usuario][_activoID] == _cantidad);
    }
}
