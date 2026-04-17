#!/bin/bash

# サーバリスト（IPアドレスと名前）
SERVERS=(
    "10.1.241.151,s1"
    "10.1.241.152,s2"
    "10.1.241.153,s3"
)

OUTPUT="/usr/local/etc/dnsdist/rtt.csv"
THRESHOLD=1  # 遅延閾値（秒）

# CSV ヘッダー
echo "address,name,weight" > "$OUTPUT"

for s in "${SERVERS[@]}"; do
    IFS=',' read -r ip name <<< "$s"

    # ping 3回
    PING_OUTPUT=$(ping -c 3 -W 1 "$ip" 2>/dev/null)

    # タイムアウトや RTT の取得
    # RTTがすべて閾値以上かタイムアウトなら weight=1
    ALL_SLOW=1
    while read -r line; do
        if [[ $line =~ time=([0-9.]+) ]]; then
            RTT=${BASH_REMATCH[1]}
            if (( $(echo "$RTT < $THRESHOLD" | bc -l) )); then
                ALL_SLOW=0
                break
            fi
        fi
    done <<< "$PING_OUTPUT"

    WEIGHT=$ALL_SLOW
    echo "$ip,$name,$WEIGHT" >> "$OUTPUT"
done
