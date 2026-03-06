require('dotenv').config();
const Web3 = require('web3');
const axios = require('axios');
const contratoABI = require('./abi/contracts/Marketplace.json').abi; //cambiar en el caso de centralizado 

// Configuración Web3
const web3 = new Web3(new Web3.providers.HttpProvider(process.env.RPC_URL));
const account = web3.eth.accounts.privateKeyToAccount(process.env.PRIVATE_KEY);
web3.eth.accounts.wallet.add(account);

// Carga del contrato
const contrato = new web3.eth.Contract(contratoABI, process.env.CONTRACT_ADDRESS);

// Función para obtener los productos del contrato
async function obtenerProductos() {
  const totalProductos = await contrato.methods.productCount().call();
  const productos = [];

  for (let i = 1; i <= totalProductos; i++) {
    const producto = await contrato.methods.products(i).call();
    if (!producto.purchased) { // Solo productos no comprados
      productos.push(producto);
    }
  }
  return productos;
}

// Función para consultar la energía entregada desde el API
async function consultarEnergia(productId) {
  try {
    const respuesta = await axios.get(`http://${process.env.API_SENSORES_IP}:3000/energia-entregada/${productId}`);
    return respuesta.data.energiaEntregada;
  } catch (error) {
    console.error(`Error obteniendo energía para producto ${productId}:`, error.message);
    return 0;
  }
}

// Función para registrar la energía entregada en la blockchain
async function registrarEnergia(productId, energiaReal) {
  const data = contrato.methods.registrarEnergiaEntregada(productId, energiaReal).encodeABI();

  const tx = {
    from: account.address,
    to: process.env.CONTRACT_ADDRESS,
    gas: 300000,
    data: data
  };

  const receipt = await web3.eth.sendTransaction(tx);
  console.log(`Energía registrada para producto ${productId}. Tx Hash: ${receipt.transactionHash}`);
}

// Función principal
async function procesoOraculo() {
  console.log("Iniciando oráculo...");

  const productos = await obtenerProductos();
  console.log(`Productos activos encontrados: ${productos.length}`);

  for (const producto of productos) {
    const energiaReal = await consultarEnergia(producto.id);

    if (energiaReal > 0) {
      console.log(`Producto ${producto.id}: Registrando ${energiaReal} watts reales...`);
      await registrarEnergia(producto.id, energiaReal);
    } else {
      console.log(`Producto ${producto.id}: Sin energía medida aún.`);
    }
  }
}

// Ejecutarlo cada cierto tiempo
setInterval(procesoOraculo, 5 * 60 * 1000); // Cada 5 minutos
