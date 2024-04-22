
# Recovery Phrase and root



## Generate a seed phrase (and back it up!)
cardano-address recovery-phrase generate --size 24 > phrase.prv

## Generate Root ext priv key from the phrase
cardano-address key from-recovery-phrase Shelley < phrase.prv > root.xsk



# Create CC COLD KEY


## generate ext priv skey (cardano-address-key format)
cardano-address key child 1852H/1815H/1H/4/0  < root.xsk > cc_cold.skey.tmp


## CONVERTING cardano-address-key to NODE-CLI KEY

## cc cold skey - NODE-CLI KEY
cardano-cli key convert-cardano-address-key --shelley-payment-key --signing-key-file cc_cold.skey.tmp --out-file cc_cold.skey

## intermediate step
cardano-cli key verification-key --signing-key-file  cc_cold.skey --verification-key-file cc_cold.vkey.tmp

## cc cold vkey - NODE-CLI KEY
cardano-cli key non-extended-key --extended-verification-key-file cc_cold.vkey.tmp --verification-key-file cc_cold.vkey




# Create CC HOT KEY *(skip this step if a script hash becomes the HOT KEY)*



## generate ext priv skey (cardano-address-key format)
cardano-address key child 1852H/1815H/1H/5/0  < root.xsk > cc_hot.skey.tmp

### (second, nth HOT KEY)
cardano-address key child 1852H/1815H/1H/5/n-1  < root.xsk > cc_hot_ *n*.skey.tmp


## CONVERTING cardano-address-key to NODE-CLI KEY

### cc hot skey - NODE-CLI KEY
cardano-cli key convert-cardano-address-key --shelley-payment-key --signing-key-file cc_hot.skey.tmp --out-file cc_hot.skey

### intermediate step
cardano-cli key verification-key --signing-key-file  cc_hot.skey--verification-key-file cc_hot.vkey.tmp

### cc hot vkey - NODE-CLI KEY
cardano-cli key non-extended-key --extended-verification-key-file cc_hot.vkey.tmp --verification-key-file cc_hot.vkey



# create CC SCRIPT AUTH KEYS *(these would be the keys referenced in the script*)


If these keys are not generated as stand-alone keys, they follow this schema: 
COLD KEY 1           -> (HOT KEY doesnt exist)          -> authorized key in script
1852H/1815H/1H/4/0   -> script hash 1 e.g. 3 of 5       -> 1852H/1815H/1H/5/100
1852H/1815H/1H/4/0   -> (would be: 1852H/1815H/1H/5/0)  -> 1852H/1815H/1H/5/200
1852H/1815H/1H/4/0   ->                                 -> 1852H/1815H/1H/5/300
1852H/1815H/1H/4/0   ->                                 -> 1852H/1815H/1H/5/400
1852H/1815H/1H/4/0   ->                                 -> 1852H/1815H/1H/5/500

COLD KEY 1           -> (HOT KEY doesnt exist)          -> authorized key in script
1852H/1815H/1H/4/0   -> script hash 2 e.g. 1 of 3       -> 1852H/1815H/1H/5/101
1852H/1815H/1H/4/0   -> (would be: 1852H/1815H/1H/5/1)  -> 1852H/1815H/1H/5/201
1852H/1815H/1H/4/0   ->                                 -> 1852H/1815H/1H/5/301

COLD KEY 1           -> HOT KEY 3 (not a script)  -> /na
1852H/1815H/1H/4/0   -> 1852H/1815H/1H/4/2        
(sorting the schema in such a way that this becomes the first hot key 4/0 would be beneficial)

COLD KEY 1           -> (HOT KEY doesnt exist)          -> authorized key in script
1852H/1815H/1H/4/0   -> script hash 3 e.g. 1 of 3       -> 1852H/1815H/1H/5/103
1852H/1815H/1H/4/0   -> (would be: 1852H/1815H/1H/5/3)  -> 1852H/1815H/1H/5/203
1852H/1815H/1H/4/0   ->                                 -> 1852H/1815H/1H/5/303

COLD KEY 2           -> (HOT KEY doesnt exist)          -> authorized key in script
1852H/1815H/1H/4/1   -> script hash 1 e.g. 1 of 3       -> 1852H/1815H/1H/5/104
1852H/1815H/1H/4/1   -> (would be: 1852H/1815H/1H/5/4)  -> 1852H/1815H/1H/5/204
1852H/1815H/1H/4/1   ->                                 -> 1852H/1815H/1H/5/304



## get the address assosiated with each hot credential:
cardano-address address payment --network-tag testnet < cc_hot_100.vkey > cc_hot_100.addr
cardano-address address payment --network-tag testnet < cc_hot_200.vkey > cc_hot_200.addr
cardano-address address payment --network-tag testnet < cc_hot_300.vkey > cc_hot_300.addr

## get script address:
cardano-address script hash "at_least 2 [$(cat cc_hot_100.addr), $(cat cc_hot_200.addr), $(cat cc_hot_300.addr)]" > script.hash
---> some script address like this: script1gr69m385thgvkrtspk73zmkwk537wxyxuevs2u9cukglvtlkz4k




# Create cold-to-hot auth certificate and broadcast


## create cert
cardano-cli conway governance committee create-hot-key-authorization-certificate \
    --cold-verification-key-file cc-cold.vkey \
    --hot-key-file cc-hot.vkey \
    --out-file cc-hot-key-authorization.cert

## build tx
cardano-cli conway transaction build \
  --testnet-magic 4 \
  --tx-in "$(cardano-cli query utxo --address "$(cat payment.addr)" --testnet-magic 4 --out-file /dev/stdout | jq -r 'keys[0]')" \
  --change-address payment.addr \
  --certificate-file cc-hot-key-authorization.cert \
  --witness-override 2 \
  --out-file tx.raw

## cardano-cli conway transaction sign \
  --testnet-magic 4 \
  --tx-body-file tx.raw \
  --signing-key-file payment.skey \
  --signing-key-file cc-cold.skey \
  --out-file tx.signed

  ## submit
  cardano-cli conway transaction submit \
  --testnet-magic 4 \
  --tx-file tx.signed
