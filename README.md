# lncli-interlink-balance
Shell script using lncli, jq, and bc to balance root node interlink channels.  Will loop through all root nodes channels and keysend a balancing payment through each. 

# Installation
Place script and json file in the same directory. Build (and validate) json data for root nodes.

```
chmod +x autobalance.sh
./autobalance.sh
```
