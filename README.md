# HAProxy

Based on https://hub.docker.com/_/haproxy/

This image have `haproxy` user/group with uid/gid = 1042/1042

Usage:
```
docker run -it --rm -v $(pwd)/haproxy.cfg:/etc/haproxy/haproxy.cfg -p 8000:8000 -e PORT 8000 exodusmovement/haproxy
```

By default image use CMD for start: `exec haproxy -db -W -f /etc/haproxy/$HAPROXY_CONFIG`, where `HAPROXY_CONFIG` by default is `haproxy.cfg`
