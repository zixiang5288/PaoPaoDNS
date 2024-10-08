#!/bin/sh
blank() {
    echo "*********************************************************************************"
    echo
}
export no_proxy=""
export http_proxy=""
ping whoami.03k.org -c1 -W 1 -w 1 -i 1 -4 >/dev/null
IPREX4='([0-9]{1,2}|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.([0-9]{1,2}|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.([0-9]{1,2}|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.([0-9]{1,2}|1[0-9][0-9]|2[0-4][0-9]|25[0-5])'

echo "### == debug.sh : docker exec -it paopaodns sh =="
echo "-> debug start \`$(date +%s)\`"
echo "\`\`\`rust"
echo "[INFO]" images build time : {bulidtime}
if [ -w /data ]; then
    echo "[OK]DATA_writeable"
else
    echo "[ERROR]DATA_not_writeable"
fi

if [ -r /data ]; then
    echo "[OK]DATA_readable"
else
    echo "[ERROR]DATA_not_readable"
fi
#sleep 1
echo "[INFO]" NETWORK
blank
ip a | grep -E "UP|inet"
ip r
traceroute -m4 -w1 120.53.53.53
ping 223.5.5.5 -c1
ping 119.29.29.29 -c1
nslookup www.taobao.com 223.5.5.5
nslookup www.qq.com 119.29.29.29
blank
#sleep 1
echo "[INFO]" ENV
blank
cat /tmp/env.conf
ls -shan /data
blank
#sleep 5
echo "[INFO]" PS
blank
ps -ef
if ps -ef | grep -v grep | grep unbound_raw; then
    echo unbound OK.
else
    echo Try to run unbound...
    unbound -c /tmp/unbound_raw.conf -p -v -d &
    grep -E "(num-threads: |outgoing-range: |outgoing-num-tcp: |incoming-num-tcp: |msg-cache-size: |msg-cache-slabs: |num-queries-per-thread: |rrset-cache-size: |rrset-cache-slabs: )" /tmp/unbound_raw.conf
    echo RealCore:"$(grep -c ^processor /proc/cpuinfo)"
    echo ulimit:$(ulimit -n)
fi

if [ "$CNAUTO" != "no" ]; then
    if ps -ef | grep -v grep | grep unbound_forward; then
        echo unbound_forward OK.
    else
        echo Try to run unbound_forward...
        unbound -c /tmp/unbound_forward.conf -p -v -d &
        grep -E "(num-threads: |outgoing-range: |outgoing-num-tcp: |incoming-num-tcp: |msg-cache-size: |msg-cache-slabs: |num-queries-per-thread: |rrset-cache-size: |rrset-cache-slabs: )" /tmp/unbound_forward.conf
        echo RealCore:"$(grep -c ^processor /proc/cpuinfo)"
        echo ulimit:$(ulimit -n)
    fi
fi

blank
echo "[INFO]" TOP
blank
top -n1 | grep "%"
blank
#sleep 5
echo "[INFO]" REDIS
blank
redis-cli -s /tmp/redis.sock info | grep human
redis-cli -s /tmp/redis.sock dbsize
blank
#sleep 5
echo "[TEST]" IP ROUTE
blank
echo CN IP URL:
mosdns curl http://test.ipw.cn | grep -Eo "$IPREX4" | tail -1
echo -
mosdns curl http://ipsu.03k.org/cdn-cgi/trace | grep -Eo "$IPREX4" | tail -1
echo --
mosdns curl https://cf-ns.com/cdn-cgi/trace | grep -Eo "$IPREX4" | tail -1
echo CN RAW-IP URL:
mosdns curl http://182.242.62.199/cdn-cgi/trace | grep "ip=" | grep -Eo "$IPREX4" | tail -1
echo ------------------
echo Non-CN IP URL:
mosdns curl https://www.cloudflare.com/cdn-cgi/trace | grep -Eo "$IPREX4" | tail -1
echo -
mosdns curl http://checkip.synology.com/ | grep -Eo "$IPREX4" | tail -1
echo --
mosdns curl https://v4.ident.me/ | grep -Eo "$IPREX4" | tail -1
echo Non-CN RAW-IP URL:
mosdns curl https://1.0.0.3/cdn-cgi/trace | grep -Eo "$IPREX4" | tail -1
echo -
mosdns curl http://172.67.150.201/cdn-cgi/trace | grep -Eo "$IPREX4" | tail -1
echo --
mosdns curl https://1.0.0.2/cdn-cgi/trace | grep -Eo "$IPREX4" | tail -1
echo ---
mosdns curl http://104.16.124.96/cdn-cgi/trace | grep -Eo "$IPREX4" | tail -1
echo ------------------
#sleep 5
echo IP INFO:
mosdns curl http://ip.03k.org
echo
#sleep 1
echo "[INFO]" force_recurse_list
grep whoami /data/force_recurse_list.txt
echo MOSDNS WHOAMI :
echo -n "MOSDNS akahelp: "
dig +short whoami.ds.akahelp.net @127.0.0.1 txt -p53
echo -n "MOSDNS 03k: "
dig +short whoami.03k.org @127.0.0.1 a -p53
echo UNBOUND WHOAMI:
echo -n "UNBOUND akahelp: "
dig +short whoami.ds.akahelp.net @127.0.0.1 txt -p5301
echo -n "UNBOUND 03k: "
dig +short whoami.03k.org @127.0.0.1 a -p5301
#sleep 1
blank
echo "[TEST]" HIJACK
blank
dig +short www.qq.com @9.8.7.5 +retry=0 +timeout=1
dig +short whoami.ds.akahelp.net @9.8.7.6 txt -p53 +retry=0 +timeout=1
echo -n "HIJACK 127.0.0.1 = "
dig +short whether.114dns.com @114.114.114.114
blank
#sleep 1
echo "[TEST]" DIG-CN "[taobao]"
blank
echo MOSDNS CN:
dig +short www.taobao.com @127.0.0.1 -p53
echo UNBOUND CN:
test_unbound_raw=$(dig +short www.taobao.com @127.0.0.1 -p5301)
if echo "$test_unbound_raw" | grep -v "refused" | grep -qEo "$IPREX4"; then
    echo "$test_unbound_raw"
else
    echo unbound_raw FAILED.
    if [ "$DEVLOG" = "yes" ]; then
        blank
        echo "[TEST]Run unbound trace test..."
        echo kill unbound and reload to debug mode...
        unbound_id=$(ps | grep -v "grep" | grep "unbound_raw" | grep -Eo "[0-9]+" | head -1)
        kill "$unbound_id"
        sed -i "s/verbosity:.*/verbosity: 2/g" /tmp/unbound_raw.conf
        unbound -c /tmp/unbound_raw.conf -p -d &
        dig www.jd.com @127.0.0.1 -p5301
        dig www.taobao.com @127.0.0.1 -p5301
        unbound_id=$(ps | grep -v "grep" | grep "unbound_raw" | grep -Eo "[0-9]+" | head -1)
        kill "$unbound_id"
        sed -i "s/verbosity:.*/verbosity: 0/g" /tmp/unbound_raw.conf
        unbound -c /tmp/unbound_raw.conf -p
    fi
    blank
fi
#sleep 3
echo "[TEST]" DIG-NOCN "[youtube]"
echo MOSDNS NOCN:
dig +short www.youtube.com @127.0.0.1 -p53 | head -3
echo DNSCRYPT-UNBOUND NOCN:
dig +short www.youtube.com @127.0.0.1 -p5304 | head -3
#sleep 1
echo DNSCRYPT NOCN:
dig +short www.youtube.com @127.0.0.1 -p5302 | head -3
#sleep 1
echo DNSCRYPT-SOCKS5 NOCN:
dig +short www.youtube.com @127.0.0.1 -p5303 +retry=0 | head -3
#sleep 1
blank
if echo "$CUSTOM_FORWARD" | grep -Eoq ":[0-9]+"; then
    CUSTOM_FORWARD=$(echo "$CUSTOM_FORWARD" | sed 's/"//g')
    if echo "$CUSTOM_FORWARD" | grep -q '\['; then
        CUSTOM_FORWARD_SERVER=$(echo "$CUSTOM_FORWARD" | sed 's/\[//' | cut -d']' -f1)
        CUSTOM_FORWARD_PORT=$(echo "$CUSTOM_FORWARD" | sed 's/.*\]://' | sed 's/[^0-9]*//')
    else
        CUSTOM_FORWARD_SERVER=$(echo "$CUSTOM_FORWARD" | cut -d':' -f1)
        CUSTOM_FORWARD_PORT=$(echo "$CUSTOM_FORWARD" | cut -d':' -f2)
    fi
    echo "CUSTOM_FORWARD TEST [youtube]":
    dig +short www.youtube.com @"$CUSTOM_FORWARD_SERVER" -p"$CUSTOM_FORWARD_PORT"
    echo "CUSTOM_FORWARD TEST [taobao]":
    dig +short www.taobao.com @"$CUSTOM_FORWARD_SERVER" -p"$CUSTOM_FORWARD_PORT"
    blank
fi
echo "[TEST]" DUAL CN "[IPv6=YES will have aaaa,taobao]"
blank
dig +short www.taobao.com @127.0.0.1 aaaa -p53

echo "[TEST]" DUAL NOCN "[IPv6=YES will block aaaa,youtube]"

dig +short www.youtube.com @127.0.0.1 aaaa -p53

echo "[TEST]" ONLY6 "[IPv6=only6 will block aaaa if a ok]"
echo -n "checkipv6.synology.com : "
dig +short checkipv6.synology.com @127.0.0.1 aaaa -p53
echo -n "ip6.03k.org : "
dig +short ip6.03k.org @127.0.0.1 aaaa -p53
echo -n "6.ipw.cn : "
dig +short 6.ipw.cn @127.0.0.1 aaaa -p53
echo
blank
echo "[info]" ALL TEST FINISH.
echo "\`\`\`"
echo "-> debug end \`$(date +%s)\`"
