#!/usr/bin/env bash

#get root node data
rootNodes=$(cat rootnodes.json)
echo "rootNodes --->" 
echo $(jq -r '.nodes[].name' <<< ${rootNodes[@]})

#loop through root nodes
for node in $(jq '.nodes | keys | .[]' <<< ${rootNodes[@]}); do
    echo ""
    echo "**** starting new node ****"
    data=$(jq -r ".nodes[$node]" <<< ${rootNodes[@]});
    numRootNodes=$(jq -r '.nodes | length' <<< ${rootNodes[@]})
    echo "numRootNodes = $numRootNodes"    
    name=$(jq -r '.name' <<< $data);
    echo "name = $name"
    pubKey=$(jq -r '.pub_key' <<< $data);
    echo "pubkey = $pubKey"
    socket=$(jq -r '.rpcserver' <<< $data);
    echo "socket = $socket"
    macaroonpath=$(jq -r '.macaroon_path' <<< $data);
    echo "macaroon path = $macaroonpath"
    tlscertpath=$(jq -r '.tlscert_path' <<< $data);
    echo "tlscert path = $tlscertpath"
    
   #get channels for all root nodes from the current root node
    for rNode in $(jq '.nodes | keys | .[]' <<< ${rootNodes[@]}); do
        listData=$(jq -r ".nodes[$rNode]" <<< ${rootNodes[@]});
        rPubKey=$(jq -r '.pub_key' <<< $listData);
        if [ $pubKey != $rPubKey ]; then
            echo "local pubKey = $pubKey" 
            echo "remote pub_key = $rPubKey"
            echo "get channels"
            chanData=$(lncli --rpcserver $socket --macaroonpath $macaroonpath --tlscertpath $tlscertpath listchannels --peer $rPubKey)
            numChannels=$(jq -r '.channels | length' <<< ${chanData[@]})
            echo "numChannels = $numChannels"
            echo "---"
            #we may have multiple channels, loop through all
            for channel in $(jq -r '.channels | keys | .[]' <<< ${chanData[@]}); do
                cData=$(jq -r ".channels[$channel]" <<< ${chanData[@]});
                chanID=$(jq -r '.chan_id' <<< $cData)
                echo "chanID = $chanID"
                capacity=$(jq -r '.capacity' <<< $cData)
                echo "capacity = $capacity"       
                localBal=$(jq -r '.local_balance' <<< $cData)
                echo "localBal = $localBal"
                remoteBal=$(jq -r '.remote_balance' <<< $cData)
                echo "remoteBal = $remoteBal"
                active=$(jq -r '.active' <<< $cData);
                echo "active = $active"

               #only attempt active channels
                if [ $active ]; then
                    targetBal=$(bc <<< "($capacity/2)+21000") #account for channel reserve and avoid small
                    echo "target balance = $targetBal"
                 if [ "$localBal" -ge "$targetBal" ] ; then
                        echo "*** balance me ***"
                        amt=$(bc <<< "($capacity/2)-$remoteBal")
                        echo "amt = $amt"
 # Comment this section out for testing
                        # SEND PAYMENT **********
                        lncli --rpcserver $socket --macaroonpath $macaroonpath --tlscertpath $tlscertpath \
                        sendpayment --keysend --amt $amt --fee_limit 0 --dest $rPubKey --outgoing_chan_id $chanID --data 34349334=496e7465726c696e6b20526562616c616e6365
 #######################
                    fi #finished if not balanced    
                fi #finished if active
                echo "---"
            done #completed channel loop
        fi #finished pubKey!=pub_key
    done #completed node loop

done #finished root node loop
