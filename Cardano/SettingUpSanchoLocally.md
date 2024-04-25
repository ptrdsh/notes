###############
 Running Sancho Locally
###############

1. Download, unpack and run latest cardano node
```console
wget https://github.com/IntersectMBO/cardano-node/releases/download/8.10.0-pre/cardano-node-8.10.0-macos.tar.gz
```
```console
tar -xf cardano-node-8.10.-macos.tar.gz
rm cardano-node-9.9.2.macos.tar.gz
```

2. if its a respin, delete everything in the db folder and recreate the protocolMagic file
```console
cd db
rm *
echo 4 > protocolMagicId
cd ..
```

3. set up configs in /configs : 

`cd configs`
```console
rm https://book.world.dev.cardano.org/environments/sanchonet/config.json
rm https://book.world.dev.cardano.org/environments/sanchonet/topology.json
rm https://book.world.dev.cardano.org/environments/sanchonet/byron-genesis.json
rm https://book.world.dev.cardano.org/environments/sanchonet/shelley-genesis.json
rm https://book.world.dev.cardano.org/environments/sanchonet/alonzo-genesis.json
rm https://book.world.dev.cardano.org/environments/sanchonet/conway-genesis.json
```
```console
wget https://book.world.dev.cardano.org/environments/sanchonet/config.json
wget https://book.world.dev.cardano.org/environments/sanchonet/topology.json
wget https://book.world.dev.cardano.org/environments/sanchonet/byron-genesis.json
wget https://book.world.dev.cardano.org/environments/sanchonet/shelley-genesis.json
wget https://book.world.dev.cardano.org/environments/sanchonet/alonzo-genesis.json
wget https://book.world.dev.cardano.org/environments/sanchonet/conway-genesis.json
```
`cd ..`

# run the node and wait till its synced
```console
./bin/cardano-node run --topology configs/topology.json --database-path db --socket-path node.socket --port 3001 --config configs/config.json
```

# interact with node:
```console
./bin/cardano-cli query tip --testnet-magic 4 --socket-path node.socket
```

