// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Marketplace {
    address public owner;

    uint public productCount = 0;
    uint public productCount_buyer = 0;

    mapping(uint => Product) public products;
    mapping(uint => ProductBuyer) public products_buyer;

    struct Product {
        uint id;
        uint price;
        string energy;
        address payable owner;
        bool purchased;
    }

    struct ProductBuyer {
        uint id;
        uint price;
        string energy;
        address payable owner;
        bool fulfilled; 
    }

    //para obtener las transacciones y realizar el trading
    struct Transaccion {
        uint id;
        uint price;
        string energy;
        address buyer;
        address seller;
    }

    Transaccion[] public transacciones;
    uint public totalTransacciones = 0;

    event ProductCreated(
        uint id,
        uint price,
        string energy,
        address payable owner,
        bool purchased
    );

    event ProductPurchased(
        uint id,
        uint price,
        string energy,
        address payable owner,
        bool purchased
    );

    event ProductSoldToBuyer(
        uint id,
        uint price,
        string energy,
        address payable buyer,
        address payable seller
    );

    constructor() {
        owner = msg.sender;
    }

    function createProduct(uint _price, string memory _energy) public {
        require(_price > 0, "Product price must be greater than zero");
        require(bytes(_energy).length > 0, "Energy must be specified");

        productCount++;
        products[productCount] = Product(productCount, _price, _energy, payable(msg.sender), false);

        emit ProductCreated(productCount, _price, _energy, payable(msg.sender), false);
    }

    function createProduct_buyer(uint _price, string memory _energy) public {
        require(_price > 0, "Price must be greater than zero");
        require(bytes(_energy).length > 0, "Energy must be specified");

        productCount_buyer++;
        products_buyer[productCount_buyer] = ProductBuyer(productCount_buyer, _price, _energy, payable(msg.sender), false);

        emit ProductCreated(productCount_buyer, _price, _energy, payable(msg.sender), false);
    }

    function purchaseProduct(uint _id) public payable {
        Product memory _product = products[_id];
        address payable _seller = _product.owner;

        require(_product.id > 0 && _product.id <= productCount, "Invalid product ID");
        require(msg.value >= _product.price, "Not enough Ether to cover price");
        require(!_product.purchased, "Already purchased");
        require(_seller != msg.sender, "Buyer cannot be the seller");

        _product.owner = payable(msg.sender);
        _product.purchased = true;
        products[_id] = _product;

        (bool success, ) = _seller.call{value: msg.value}("");
        require(success, "Transfer failed");

        transacciones.push(Transaccion({ //para el registro de las transacciones
            id: _product.id,
            price: _product.price,
            energy: _product.energy,
            buyer: msg.sender,
            seller: _seller
        }));
        totalTransacciones++;


        emit ProductPurchased(_id, _product.price, _product.energy, payable(msg.sender), true);
    }

    function sellToBuyerRequest(uint _id) public payable{
        ProductBuyer memory _request = products_buyer[_id];

        require(_request.id > 0 && _request.id <= productCount_buyer, "Invalid buyer request ID");
        require(!_request.fulfilled, "Request already fulfilled");
        require(_request.owner != msg.sender, "Cannot sell to your own request");

        (bool success, ) = _request.owner.call{value: _request.price}("");
        require(success, "Payment failed");

        _request.fulfilled = true;
        products_buyer[_id] = _request;

        transacciones.push(Transaccion({
            id: _request.id,
            price: _request.price,
            energy: _request.energy,
            buyer: _request.owner,
            seller: msg.sender
        }));
        totalTransacciones++;

        emit ProductSoldToBuyer(
            _id,
            _request.price,
            _request.energy,
            _request.owner,
            payable(msg.sender)
        );
    }

    function getTransaccion(uint index) public view returns (
        uint id,
        uint price,
        string memory energy,
        address buyer,
        address seller
    ) {
        require(index < totalTransacciones, "Fuera de rango");
        Transaccion memory t = transacciones[index];
        return (t.id, t.price, t.energy, t.buyer, t.seller);
    }

    function getCantidadTransacciones() public view returns (uint) {
        return totalTransacciones;
    }


}
