#!/bin/bash
set -e

echo "=== 1. KIEM TRA TRANG THAI TUONG LUA UFW ==="
sudo ufw status verbose
echo ""

echo "=== 2. KIEM TRA CAC PORT DANG LANG NGHE (SS -TLNP) ==="
ss -tlnp
echo ""

echo "=== 3. KHOI DONG DICH VU WEB THU NGHIEM TAI PORT 8080 ==="
python3 -m http.server 8080 >/dev/null 2>&1 &
SERVER_PID=$!
sleep 1

echo "=== 4. KIEM TRA LAI CAC PORT DANG LANG NGHE ==="
ss -tlnp
echo ""

echo "=== 5. CHUAN DOAN KET NOI PORT 8080 BANG CURL ==="
curl -I http://127.0.0.1:8080
echo ""

kill $SERVER_PID
wait $SERVER_PID 2>/dev/null || true

echo "=== HOAN TAT KIEM TRA ==="
