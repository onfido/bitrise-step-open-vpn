#!/bin/bash
set -eu

case "$OSTYPE" in
  linux*)
    echo "Configuring for Ubuntu"

    echo ${ca_crt} | base64 -d > /etc/openvpn/ca.crt
    echo ${user_pass} | base64 -d > /etc/openvpn/login.conf

    cat <<EOF > /etc/openvpn/client.conf
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

    service openvpn start client > /dev/null 2>&1
    sleep 5

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

    sudo openvpn --client --route-nopull --route ${subnet1} 255.255.224.0 --route ${subnet2} 255.255.224.0 --dhcp-option DNS ${dns1} --dhcp-option DNS ${dns2} --dev tun --proto ${proto} --remote ${host} ${port} --remote-random-hostname --resolv-retry infinite --nobind --persist-key --persist-tun --remote-cert-tls server --ca ca.crt --verb 3 --auth-user-pass login.conf --reneg-sec 0

    sleep 5

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
