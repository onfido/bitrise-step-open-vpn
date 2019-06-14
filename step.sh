#!/bin/bash
set -eu

    cat <<EOF > client.ovpn
client
dev tun
route-nopull
route ${subnet1} 255.255.224.0
route ${subnet2} 255.255.224.0
dhcp-option DNS ${dns1}
dhcp-option DNS ${dns2}
proto ${proto}
remote ${host} ${port}
remote-random-hostname
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
verb 3
ca ca.crt
auth-user-pass login.conf
reneg-sec 0
EOF

case "$OSTYPE" in
  linux*)
    echo "Configuring for Ubuntu"

    echo ${ca_crt} | base64 -d > /etc/openvpn/ca.crt
    echo ${user_pass} | base64 -d > /etc/openvpn/login.conf

    sudo cp client.ovpn /etc/openvpn/client.conf

    service openvpn start client > /dev/null 2>&1
    sleep 5
    echo nameserver ${dns1} | sudo tee /etc/resolv.conf
    echo nameserver ${dns2} | sudo tee -a /etc/resolv.conf

    if ifconfig | grep tun0 > /dev/null
    then
      echo "VPN connection succeeded"
    else
      echo "VPN connection failed!"
      exit 1
    fi
    ;;
  darwin*)
    echo "Configuring for Mac OS"

    echo ${ca_crt} | base64 -D -o ca.crt > /dev/null 2>&1
    echo ${user_pass} | base64 -D -o login.conf > /dev/null 2>&1

    sudo openvpn --config client.ovpn &
    sleep 5
    echo nameserver ${dns1} | sudo tee /etc/resolv.conf
    echo nameserver ${dns2} | sudo tee -a /etc/resolv.conf

    if ifconfig -l | grep utun0 > /dev/null
    then
      echo "VPN connection succeeded"
    else
      echo "VPN connection failed!"
      exit 1
    fi
    ;;
  *)
    echo "Unknown operative system: $OSTYPE, exiting"
    exit 1
    ;;
esac

nslookup google.com
dig google.com

