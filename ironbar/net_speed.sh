#!/bin/bash
now=$(date +%s)
curr=$(awk 'NR>2 && !/lo/{rx+=$2; tx+=$10} END{print rx+0, tx+0}' /proc/net/dev)

# Append current sample and keep last 5 entries
echo "$now $curr" >> /tmp/net_stat
tail -n 5 /tmp/net_stat > /tmp/net_stat.tmp && mv /tmp/net_stat.tmp /tmp/net_stat

awk '
    function fmt(b) {
        if      (b < 100)         return sprintf("%02dB", b);
        else if (b < 1000)        return sprintf(".%01dK", int(b/100));
        else if (b < 100000)      return sprintf("%02dK", int(b/1000));
        else if (b < 1000000)     return sprintf(".%01dM", int(b/100000));
        else if (b < 100000000)   return sprintf("%02dM", int(b/1000000));
        else if (b < 1000000000)  return sprintf(".%01dG", int(b/100000000));
        else                      return sprintf("%02dG", int(b/1000000000));
    }
    NR==1 { t0=$1; rx0=$2; tx0=$3 }
    END   {
        dt = $1 - t0;
        if (dt <= 0) dt = 1;
        dr = ($2 - rx0) / dt;
        du = ($3 - tx0) / dt;
        if (dr < 0) dr = 0;
        if (du < 0) du = 0;
        printf "↓%s ↑%s\n", fmt(dr), fmt(du)
    }
' /tmp/net_stat
