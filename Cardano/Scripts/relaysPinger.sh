#!/bin/bash

# this script gets all registered relay IPs from an API (koios) and pings each of them once, waiting for 1sec. 
# The script echos each IPs status and saves all results in a csv. 
# API responses at koios are paginated with max 1000 entries. The main loop is capped at max_iterations for easy error handling, which also means a max of max_iterations/1000 pages.
# comment out rm relays_page_*.json for more data.

# Init
count_up=0
count_down=0
offset=0
max_iterations=10000

output_csv="relays_status.csv"
echo "Pool ID,IPv4,Status" > "$output_csv"


# Loop through API pages max times until there are no more results []
while [ $offset -lt $max_iterations ]; do

    response=$(curl -s -X GET "https://api.koios.rest/api/v1/pool_relays?offset=${offset}" -H "accept: application/json")

    if [ "$response" == "[]" ]; then
        echo "empty API response. exiting."
        break 
    fi

    echo $response > "relays_page_${offset}.json"

    cat "relays_page_${offset}.json" | jq -c '.[]' | while read i; do
        pool_id=$(echo $i | jq -r '.pool_id_bech32')
        relays=$(echo $i | jq -r '.relays[] | select(.ipv4 != null) | .ipv4')

        for ip in $relays; do
            ping -c 1 -W 1 $ip &> /dev/null
            if [ $? -eq 0 ]; then
                status="up"
                ((count_up+=1))
            else
                status="down"
                ((count_down+=1))
            fi

            echo "$pool_id, $ip, $status"
            echo "$pool_id,$ip,$status" >> "$output_csv"
        done
    done
    echo "#########################################"
    echo "Results of $offset to $((offset+1000)) : $count_up relays are up, $count_down relays are down."
    echo "continuing with next page"
    echo "#########################################"
    ((offset+=1000))
done
echo "#########################################"
echo "#########################################"
echo "Final Summary: $count_up relays are up, $count_down relays are down."
echo "Final Results have been saved to $output_csv, intermediate page results have been deleted"

rm relays_page_*.json