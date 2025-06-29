#!/bin/bash

if [ "$(id -u)" -ne 0 ]; then
    echo -e "\033[1;31m[!] Hata: Bu script root olarak çalıştırılmalıdır!\033[0m"
    exit 1
fi

R='\033[1;31m'
G='\033[1;32m'
Y='\033[1;33m'
B='\033[1;34m'
M='\033[1;35m'
C='\033[1;36m'
W='\033[1;37m'
NC='\033[0m'

loading() {
    echo -ne "${Y}[FCK_FAVOR] ${W}Yükleniyor "
    for i in {1..3}; do
        echo -n "."
        sleep 0.3
    done
    echo -e "${NC}"
}

install_xray() {
    clear
    echo -e "${G}
    ███████╗ ██████╗██╗  ██╗    ███████╗ █████╗ ██╗   ██╗ ██████╗ ██████╗ 
    ██╔════╝██╔════╝██║ ██╔╝    ██╔════╝██╔══██╗██║   ██║██╔═══██╗██╔══██╗
    █████╗  ██║     █████╔╝     █████╗  ███████║██║   ██║██║   ██║██████╔╝
    ██╔══╝  ██║     ██╔═██╗     ██╔══╝  ██╔══██║╚██╗ ██╔╝██║   ██║██╔══██╗
    ██║     ╚██████╗██║  ██╗    ██║     ██║  ██║ ╚████╔╝ ╚██████╔╝██║  ██║
    ╚═╝      ╚═════╝╚═╝  ╚═╝    ╚═╝     ╚═╝  ╚═╝  ╚═══╝   ╚═════╝ ╚═╝  ╚═╝
    ${NC}"
    loading
    
    apt-get update > /dev/null 2>&1
    apt-get install -y -qq curl wget jq qrencode uuid-runtime openssl > /dev/null 2>&1
    bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install > /dev/null 2>&1

    IP=$(curl -4 ifconfig.co 2>/dev/null || hostname -I | awk '{print $1}')
    UUID=$(uuidgen)
    mkdir -p /etc/xray/cert
    openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 \
        -subj "/CN=$IP" \
        -keyout /etc/xray/cert/key.pem \
        -out /etc/xray/cert/cert.pem > /dev/null 2>&1
        chmod 600 /etc/xray/cert/key.pem
        chmod 644 /etc/xray/cert/cert.pem
        chown -R nobody:nogroup /etc/xray/cert

    cat > /usr/local/etc/xray/config.json <<EOF
{
  "inbounds": [
    {
      "port": 443,
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "$UUID",
            "email": "fck_favor@xray.com"
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "ws",
        "security": "tls",
        "tlsSettings": {
          "certificates": [
            {
              "certificateFile": "/etc/xray/cert/cert.pem",
              "keyFile": "/etc/xray/cert/key.pem"
            }
          ]
        },
        "wsSettings": {
          "path": "/fckfavor",
          "headers": {}
        }
      }
    },
    {
      "port": 8080,
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "$UUID",
            "email": "fck_favor@xray.com"
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "/fckfavor",
          "headers": {}
        }
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "tag": "direct"
    },
    {
      "protocol": "blackhole",
      "tag": "blocked"
    }
  ]
}
EOF

    cat > /usr/local/bin/fckfavor <<'EOF'
#!/bin/bash

CONFIG="/usr/local/etc/xray/config.json"
IP=$(curl -4 ifconfig.co 2>/dev/null || hostname -I | awk '{print $1}')

show_menu() {
    clear
    echo -e "${C}
    ███████╗ ██████╗██╗  ██╗    ███████╗ █████╗ ██╗   ██╗ ██████╗ ██████╗ 
    ██╔════╝██╔════╝██║ ██╔╝    ██╔════╝██╔══██╗██║   ██║██╔═══██╗██╔══██╗
    █████╗  ██║     █████╔╝     █████╗  ███████║██║   ██║██║   ██║██████╔╝
    ██╔══╝  ██║     ██╔═██╗     ██╔══╝  ██╔══██║╚██╗ ██╔╝██║   ██║██╔══██╗
    ██║     ╚██████╗██║  ██╗    ██║     ██║  ██║ ╚████╔╝ ╚██████╔╝██║  ██║
    ╚═╝      ╚═════╝╚═╝  ╚═╝    ╚═╝     ╚═╝  ╚═╝  ╚═══╝   ╚═════╝ ╚═╝  ╚═╝
    ${NC}"
    echo -e "${M}╔════════════════════════════════════════╗"
    echo -e "║   ${W}FCK_FAVOR Xray Manager ${M}v3.0       ║"
    echo -e "╠════════════════════════════════════════╣"
    echo -e "║ ${G}1. ${W}Yeni Kullanıcı Ekle               ${M}║"
    echo -e "║ ${G}2. ${W}Kullanıcıları Listele             ${M}║"
    echo -e "║ ${G}3. ${W}Kullanıcı Sil                    ${M}║"
    echo -e "║ ${G}4. ${W}Bağlantı Bilgilerini Göster       ${M}║"
    echo -e "║ ${G}5. ${W}Xray Servis Durumu                ${M}║"
    echo -e "║ ${R}6. ${W}Çıkış                            ${M}║"
    echo -e "╚════════════════════════════════════════╝${NC}"
    echo -ne "${C}[FCK_FAVOR] ${W}Seçiminiz [1-6]: ${NC}"
}

add_user() {
    echo -ne "${C}[FCK_FAVOR] ${W}Kullanıcı adı: ${NC}"
    read username
    NEW_UUID=$(uuidgen)
    jq --arg uuid "$NEW_UUID" --arg email "$username@fckfavor" '.inbounds[].settings.clients += [{"id": $uuid, "email": $email}]' $CONFIG > /tmp/xray.json && mv /tmp/xray.json $CONFIG
    systemctl restart xray 2>/dev/null
    
    echo -e "\n${G}[+] Yeni kullanıcı eklendi:${NC}"
    echo -e "${W}Kullanıcı Adı: ${Y}$username${NC}"
    echo -e "${W}UUID: ${Y}$NEW_UUID${NC}"
    
    echo -e "\n${C}[*] TLS Bağlantı (443):${NC}"
    echo "vless://$NEW_UUID@$IP:443?security=tls&type=ws&path=%2Ffckfavor&sni=$IP#$username-TLS"
    
    echo -e "\n${C}[*] WS Bağlantı (8080):${NC}"
    echo "vless://$NEW_UUID@$IP:8080?type=ws&path=%2Ffckfavor#$username-WS"
    
    echo -ne "\n${C}[?] QR kod oluşturulsun mu? [y/N]: ${NC}"
    read qr
    if [[ $qr =~ [yY] ]]; then
        echo -e "\n${M}[TLS QR Code]${NC}"
        qrencode -t UTF8 "vless://$NEW_UUID@$IP:443?security=tls&type=ws&path=%2Ffckfavor&sni=$IP#$username-TLS"
        echo -e "\n${M}[WS QR Code]${NC}"
        qrencode -t UTF8 "vless://$NEW_UUID@$IP:8080?type=ws&path=%2Ffckfavor#$username-WS"
    fi
    read -p "Devam etmek için Enter..."
}

list_users() {
    echo -e "\n${C}[*] Kayıtlı Kullanıcılar:${NC}"
    jq -r '.inbounds[0].settings.clients[] | "• " + .email + " - " + .id' $CONFIG
    echo ""
    read -p "Devam etmek için Enter..."
}

delete_user() {
    list_users
    echo -ne "${C}[FCK_FAVOR] ${W}Silinecek UUID: ${NC}"
    read DEL_UUID
    if jq --arg uuid "$DEL_UUID" '.inbounds[].settings.clients[] | select(.id == $uuid)' $CONFIG >/dev/null; then
        jq --arg uuid "$DEL_UUID" 'del(.inbounds[].settings.clients[] | select(.id == $uuid))' $CONFIG > /tmp/xray.json && mv /tmp/xray.json $CONFIG
        systemctl restart xray 2>/dev/null
        echo -e "${G}[+] Kullanıcı silindi${NC}"
    else
        echo -e "${R}[!] UUID bulunamadı!${NC}"
    fi
    read -p "Devam etmek için Enter..."
}

show_configs() {
    list_users
    echo -ne "${C}[FCK_FAVOR] ${W}Bilgilerini görmek istediğiniz UUID: ${NC}"
    read SHOW_UUID
    if jq --arg uuid "$SHOW_UUID" '.inbounds[].settings.clients[] | select(.id == $uuid)' $CONFIG >/dev/null; then
        USER_EMAIL=$(jq -r --arg uuid "$SHOW_UUID" '.inbounds[0].settings.clients[] | select(.id == $uuid) | .email' $CONFIG)
        echo -e "\n${G}[*] Kullanıcı Bilgileri:${NC}"
        echo -e "${W}Email: ${Y}$USER_EMAIL${NC}"
        echo -e "${W}UUID: ${Y}$SHOW_UUID${NC}"
        
        echo -e "\n${C}[*] TLS Bağlantı (443):${NC}"
        echo "vless://$SHOW_UUID@$IP:443?security=tls&type=ws&path=%2Ffckfavor&sni=$IP#$USER_EMAIL-TLS"
        
        echo -e "\n${C}[*] WS Bağlantı (8080):${NC}"
        echo "vless://$SHOW_UUID@$IP:8080?type=ws&path=%2Ffckfavor#$USER_EMAIL-WS"
        
        echo -ne "\n${C}[?] QR kod oluşturulsun mu? [y/N]: ${NC}"
        read qr
        if [[ $qr =~ [yY] ]]; then
            echo -e "\n${M}[TLS QR Code]${NC}"
            qrencode -t UTF8 "vless://$SHOW_UUID@$IP:443?security=tls&type=ws&path=%2Ffckfavor&sni=$IP#$USER_EMAIL-TLS"
            echo -e "\n${M}[WS QR Code]${NC}"
            qrencode -t UTF8 "vless://$SHOW_UUID@$IP:8080?type=ws&path=%2Ffckfavor#$USER_EMAIL-WS"
        fi
    else
        echo -e "${R}[!] UUID bulunamadı!${NC}"
    fi
    read -p "Devam etmek için Enter..."
}

service_status() {
    echo -e "\n${C}[*] Xray Servis Durumu:${NC}"
    systemctl status xray --no-pager -l
    
    echo -e "\n${C}[*] Son 10 Log:${NC}"
    journalctl -u xray -n 10 --no-pager
    
    read -p "Devam etmek için Enter..."
}

while true; do
    show_menu
    read choice
    case $choice in
        1) add_user ;;
        2) list_users ;;
        3) delete_user ;;
        4) show_configs ;;
        5) service_status ;;
        6) exit 0 ;;
        *) echo -e "${R}[!] Geçersiz seçim!${NC}"; sleep 1 ;;
    esac
done
EOF

    chmod +x /usr/local/bin/fckfavor
    systemctl restart xray
    systemctl enable xray > /dev/null 2>&1

    echo -e "\n${G}[+] Xray başarıyla kuruldu!${NC}"
    echo -e "${W}İlk kullanıcı UUID: ${Y}$UUID${NC}"
    echo -e "${W}Yönetim için: ${C}fckfavor${W} komutunu kullanın${NC}"
}

uninstall_xray() {
    clear
    echo -e "${R}
    ███████╗ ██████╗██╗  ██╗    ███████╗ █████╗ ██╗   ██╗ ██████╗ ██████╗ 
    ██╔════╝██╔════╝██║ ██╔╝    ██╔════╝██╔══██╗██║   ██║██╔═══██╗██╔══██╗
    █████╗  ██║     █████╔╝     █████╗  ███████║██║   ██║██║   ██║██████╔╝
    ██╔══╝  ██║     ██╔═██╗     ██╔══╝  ██╔══██║╚██╗ ██╔╝██║   ██║██╔══██╗
    ██║     ╚██████╗██║  ██╗    ██║     ██║  ██║ ╚████╔╝ ╚██████╔╝██║  ██║
    ╚═╝      ╚═════╝╚═╝  ╚═╝    ╚═╝     ╚═╝  ╚═╝  ╚═══╝   ╚═════╝ ╚═╝  ╚═╝
    ${NC}"
    loading
    
    bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ remove > /dev/null 2>&1
    rm -rf /usr/local/bin/fckfavor /etc/xray/cert
    
    echo -e "\n${G}[+] Xray başarıyla kaldırıldı!${NC}"
}

clear
echo -e "${M}
╔════════════════════════════════════════════════════════════╗
║                                                            ║
║  ███████╗ ██████╗██╗  ██╗    ███████╗ █████╗ ██╗   ██╗    ║
║  ██╔════╝██╔════╝██║ ██╔╝    ██╔════╝██╔══██╗██║   ██║    ║
║  █████╗  ██║     █████╔╝     █████╗  ███████║██║   ██║    ║
║  ██╔══╝  ██║     ██╔═██╗     ██╔══╝  ██╔══██║╚██╗ ██╔╝    ║
║  ██║     ╚██████╗██║  ██╗    ██║     ██║  ██║ ╚████╔╝     ║
║  ╚═╝      ╚═════╝╚═╝  ╚═╝    ╚═╝     ╚═╝  ╚═╝  ╚═══╝      ║
║                                                            ║
║               ${W}FCK_FAVOR Xray Manager v3.0${M}               ║
║                                                            ║
╠════════════════════════════════════════════════════════════╣
║ ${G}1.${W} Xray Kurulumu                                   ${M}║
║ ${R}2.${W} Xray Kaldırma                                   ${M}║
║ ${B}3.${W} Çıkış                                           ${M}║
╚════════════════════════════════════════════════════════════╝
${NC}"
echo -ne "${C}[FCK_FAVOR] ${W}Seçiminiz [1-3]: ${NC}"

read option
case $option in
    1) install_xray ;;
    2) uninstall_xray ;;
    3) exit 0 ;;
    *) echo -e "${R}[!] Geçersiz seçim!${NC}"; exit 1 ;;
esac
