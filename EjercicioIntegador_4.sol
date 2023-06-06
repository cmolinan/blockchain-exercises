// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

/** CUASI SUBASTA INGLESA
 *
 * Descripción:
 * Tienen la tarea de crear un contrato inteligente que permita crear subastas Inglesas (English auction).
 * Se paga 1 Ether para crear una subasta y se debe especificar su hora de inicio y finalización.
 * Los ofertantes envian sus ofertas a la subasta que ellos deseen durante el tiempo que la subasta esté abierta.
 * Cada subasta tiene un ID único que permite a los ofertantes identificar la subasta a la que desean ofertar.
 * Los ofertantes para poder proponer su oferta envían Ether al contrato (llamando al método 'proponerOferta' o enviando directamente).
 * Las ofertas deben ser mayores a la oferta más alta actual para una subasta en particular.
 * Si se realiza una oferta dentro de los 5 minutos finales de la subasta, el tiempo de finalización se extiende en 5 minutos
 * Una vez que el tiempo de la subasta se cumple, cualquier puede llamar al método 'finalizarSubasta' para finalizar la subasta.
 * Cuando finaliza la subasta, el ganador recupera su oferta y se lleva el 1 Ether depositado por el creador.
 * Cuando finaliza la subasta se emite un evento con el ganador (address)
 * Las personas que no ganaron la subasta pueden recuperar su oferta después de que finalice la subasta
 *
 * ¿Qué es una subasta Inglesa?
 * En una subasta inglesa el precio comienza bajo y los postores pujan el precio haciendo ofertas.
 * Cuando se cierra la subasta, se emite un evento con el mejor postor.
 *
 * Métodos a implementar:
 * - El método 'creaSubasta(uint256 _startTime, uint256 _endTime)':
 *      * Crea un ID único del typo bytes32 para la subasta y lo guarda en la lista de subastas activas
 *      * Permite a cualquier usuario crear una subasta pagando 1 Ether
 *          - Error en caso el usuario no envíe 1 Ether: CantidadIncorrectaEth();
 *      * Verifica que el tiempo de finalización sea mayor al tiempo de inicio
 *          - Error en caso el tiempo de finalización sea mayo al tiempo de inicio: TiempoInvalido();
 *      * Disparar un evento llamado 'SubastaCreada' con el ID de la subasta y el creador de la subasta (address)
 *
 * - El método 'proponerOferta(bytes32 _auctionId)':
 *      * Verifica que ese ID de subasta (_auctionId) exista
 *          - Error si el ID de subasta no existe: SubastaInexistente();
 *      * Usando el ID de una subasta (_auctionId), el ofertante propone una oferta y envía Ether al contrato
 *          - Error si la oferta no es mayor a la oferta más alta actual: OfertaInvalida();
 *      * Solo es llamado durante el tiempo de la subasta (entre el inicio y el final)
 *          - Error si la subasta no está en progreso: FueraDeTiempo();
 *      * Emite el evento 'OfertaPropuesta' con el postor y el monto de la oferta
 *      * Guarda la cantidad de Ether enviado por el postor para luego poder recuperar su oferta en caso no gane la subasta
 *      * Añade 5 minutos al tiempo de finalización de la subasta si la oferta se realizó dentro de los últimos 5 minutos
 *      Nota: Cuando se hace una oferta, incluye el Ether enviado anteriormente por el ofertante
 *
 * - El método 'finalizarSubasta(bytes32 _auctionId)':
 *      * Verifica que ese ID de subasta (_auctionId) exista
 *          - Error si el ID de subasta no existe: SubastaInexistente();
 *      * Es llamado luego del tiempo de finalización de la subasta usando su ID (_auctionId)
 *          - Error si la subasta aún no termina: SubastaEnMarcha();
 *      * Elimina el ID de la subasta (_auctionId) de la lista de subastas activas
 *      * Emite el evento 'SubastaFinalizada' con el ganador de la subasta y el monto de la oferta
 *      * Añade 1 Ether al balance del ganador de la subasta para que éste lo puedo retirar después
 *
 * - El método 'recuperarOferta(bytes32 _auctionId)':
 *      * Permite a los usuarios recuperar su oferta (tanto si ganaron como si perdieron la subasta)
 *      * Verifica que la subasta haya finalizado
 *      * El smart contract le envía el balance de Ether que tiene a favor del ofertante
 *
 * - El método 'verSubastasActivas() returns(bytes32[])':
 *      * Devuelve la lista de subastas activas en un array
 *
 * Para correr el test de este contrato:
 * $ npx hardhat test test/EjercicioIntegrador_4.ts
 */

contract EjercicioCuatro {
    event SubastaCreada(bytes32 indexed _auctionId, address indexed _creator);
    event OfertaPropuesta(address indexed _bidder, uint256 _bid);
    event SubastaFinalizada(address indexed _winner, uint256 _bid);

    error CantidadIncorrectaEth();
    error TiempoInvalido();
    error SubastaInexistente();
    error FueraDeTiempo();
    error OfertaInvalida();
    error SubastaEnMarcha();

    receive() external payable {}
    fallback() external payable {}


    struct Ofertas {
        address bidder;
        uint256 amount;
    }    

    struct DatosAuction {
        address creator;        
        uint256 dateIni;
        uint256 dateEnd;
        bool active;      
        uint256 highOffer;  
        uint256 dateOffer;
        address highBidder;
        uint256 idInArray;
    }

    mapping (bytes32 auctionId => DatosAuction) subastas;    

    mapping(bytes32 auctionId => mapping(address bidder => uint256 amount)) public amountPerBidder;

    bytes32[] subastasActivas;

//  * - El método 'creaSubasta(uint256 _startTime, uint256 _endTime)':
//  *      * Crea un ID único del typo bytes32 para la subasta y lo guarda en la lista de subastas activas
//  *      * Permite a cualquier usuario crear una subasta pagando 1 Ether
//  *          - Error en caso el usuario no envíe 1 Ether: CantidadIncorrectaEth();
//  *      * Verifica que el tiempo de finalización sea mayor al tiempo de inicio
//  *          - Error en caso el tiempo de finalización sea mayo al tiempo de inicio: TiempoInvalido();
//  *      * Disparar un evento llamado 'SubastaCreada' con el ID de la subasta y el creador de la subasta (address) 
    function creaSubasta(uint256 _startTime, uint256 _endTime) public payable {
                
        bytes32 _auctionId = _createId(_startTime, _endTime);  
        
        if (msg.value != 1 ether) revert CantidadIncorrectaEth();
        if (_endTime <= _startTime) revert TiempoInvalido();
        
        payable(address(this)).transfer(1);
        DatosAuction memory datosAuction;
        datosAuction.creator = msg.sender;
        datosAuction.dateIni = _startTime;
        datosAuction.dateEnd = _endTime;
        datosAuction.highOffer = 0;
        datosAuction.dateOffer = 0;        
        datosAuction.highBidder = address(0);
        datosAuction.active  = true;

        subastasActivas.push(_auctionId);

        datosAuction.idInArray = subastasActivas.length -1;

        subastas[_auctionId] = datosAuction;  //add new auction in mapping Table 

        emit SubastaCreada(_auctionId, msg.sender);        
    }

//  * - El método 'proponerOferta(bytes32 _auctionId)':
//  *      * Verifica que ese ID de subasta (_auctionId) exista
//  *          - Error si el ID de subasta no existe: SubastaInexistente();
//  *      * Usando el ID de una subasta (_auctionId), el ofertante propone una oferta y envía Ether al contrato
//  *          - Error si la oferta no es mayor a la oferta más alta actual: OfertaInvalida();
//  *      * Solo es llamado durante el tiempo de la subasta (entre el inicio y el final)
//  *          - Error si la subasta no está en progreso: FueraDeTiempo();
//  *      * Emite el evento 'OfertaPropuesta' con el postor y el monto de la oferta
//  *      * Guarda la cantidad de Ether enviado por el postor para luego poder recuperar su oferta en caso no gane la subasta
//  *      * Añade 5 minutos al tiempo de finalización de la subasta si la oferta se realizó dentro de los últimos 5 minutos
//  *      Nota: Cuando se hace una oferta, incluye el Ether enviado anteriormente por el ofertante
//  *
    function proponerOferta(bytes32 _auctionId) public payable {

        if(subastas[_auctionId].creator == address(0)) revert SubastaInexistente();

        uint256 fechaActual = block.timestamp;
        if( fechaActual > subastas[_auctionId].dateEnd || fechaActual < subastas[_auctionId].dateIni ) revert FueraDeTiempo();

        if( subastas[_auctionId].highOffer > msg.value) revert OfertaInvalida();
        subastas[_auctionId].highOffer = msg.value;  //actualiza oferta mas alta
        subastas[_auctionId].dateOffer = fechaActual; //actualiza fecha de oferta mas alta
        subastas[_auctionId].highBidder = msg.sender; //actualiza id del ofertante        

        amountPerBidder[_auctionId][msg.sender] = msg.value; //agrega ofertante y el monto

        emit OfertaPropuesta(msg.sender, subastas[_auctionId].highOffer); 

        payable(address(this)).transfer(msg.value);

        //extiende 5 minutos si la ultima oferta valida fue menos de 5 minutos antes del cierre
        if( subastas[_auctionId].dateEnd - fechaActual < 300 ) subastas[_auctionId].dateEnd += 300 ;

    }

//  * - El método 'finalizarSubasta(bytes32 _auctionId)':
//  *      * Verifica que ese ID de subasta (_auctionId) exista
//  *          - Error si el ID de subasta no existe: SubastaInexistente();
//  *      * Es llamado luego del tiempo de finalización de la subasta usando su ID (_auctionId)
//  *          - Error si la subasta aún no termina: SubastaEnMarcha();
//  *      * Elimina el ID de la subasta (_auctionId) de la lista de subastas activas
//  *      * Emite el evento 'SubastaFinalizada' con el ganador de la subasta y el monto de la oferta
//  *      * Añade 1 Ether al balance del ganador de la subasta para que éste lo puedo retirar después
//  *
    function finalizarSubasta(bytes32 _auctionId) public {
                
        if(!subastas[_auctionId].active) revert SubastaInexistente();
        
        if(block.timestamp <= subastas[_auctionId].dateEnd ) revert SubastaEnMarcha();
        
        amountPerBidder[_auctionId][subastas[_auctionId].highBidder] += 1 ether; //1 ether al ganador

        subastas[_auctionId].active = false;  //declarar subasta inactiva
        
        subastasActivas[subastas[_auctionId].idInArray] = subastasActivas[subastasActivas.length - 1];
        subastasActivas.pop();
        
                
        emit SubastaFinalizada(subastas[_auctionId].highBidder, subastas[_auctionId].highOffer);
    }

//  * - El método 'recuperarOferta(bytes32 _auctionId)':
//  *      * Permite a los usuarios recuperar su oferta (tanto si ganaron como si perdieron la subasta)
//  *      * Verifica que la subasta haya finalizado
//  *      * El smart contract le envía el balance de Ether que tiene a favor del ofertante
//  *
    function recuperarOferta(bytes32 _auctionId) public payable returns(uint256) {
        
        if(subastas[_auctionId].active) revert SubastaEnMarcha();
        payable(msg.sender).transfer(amountPerBidder[_auctionId][msg.sender]);

        return address(msg.sender).balance;
    }

//  * - El método 'verSubastasActivas() returns(bytes32[])':
//  *      * Devuelve la lista de subastas activas en un array
    function verSubastasActivas() public view returns (bytes32[] memory) {        
        return subastasActivas;
    }
     
    ////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////   INTERNAL METHODS  ///////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////

    function _createId(
        uint256 _startTime,
        uint256 _endTime
    ) internal view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    _startTime,
                    _endTime,
                    msg.sender,
                    block.timestamp
                )
            );
    }
}
