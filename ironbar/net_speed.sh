#!/bin/bash
prev=$(cat /tmp/net_stat 2>/dev/null || echo "0 0")
curr=$(awk 'NR>2 && !/lo/{rx+=$2; tx+=$10} END{print rx+0, tx+0}' /proc/net/dev)
echo "$curr" > /tmp/net_stat
echo "$prev $curr" | awk '
    function fmt(b) {
        if      (b < 100)         return sprintf("%02dB", b);
        else if (b < 1000)        return sprintf(".%01dK", int(b/100));
        else if (b < 100000)      return sprintf("%02dK", int(b/1000));
        else if (b < 1000000)     return sprintf(".%01dM", int(b/100000));
        else if (b < 100000000)   return sprintf("%02dM", int(b/1000000));
        else if (b < 1000000000)  return sprintf(".%01dG", int(b/100000000));
        else                      return sprintf("%02dG", int(b/1000000000));
    }
    {
        dt=($3-$1)/2; ut=($4-$2)/2;
        if(dt<0) dt=0; if(ut<0) ut=0;
        printf "↓%s ↑%s\n", fmt(dt), fmt(ut)
    }'
