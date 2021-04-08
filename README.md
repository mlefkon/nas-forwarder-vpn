# NAS Forwarder VPN

- Image repository [Dockerhub: mlefkon/nas-forwarder-vpn](https://hub.docker.com/r/mlefkon/nas-forwarder-vpn)

- Source repository [Github: mlefkon/nas-forwarder-vpn](https://github.com/mlefkon/nas-forwarder-vpn)

## **What It Does**

### **ISP Blocking Problem**

You can't connect to your NAS from outside the home if:

- Your ISP blocks some ports.
- Your ISP gives you a private IP address.  
  
  > Your home modem is hidden behind the ISP's NAT router. The ISP has a single public IP on one side of the router and many homes' private IPs on the other side.  This is probably the case if the ISP is cellular, but could happen as well with a landline ISP.  ISPs do this to conserve IP addresses.

   To check this: Logon to admin page of your router and check the "Internet Status" IP.  If it differs from [https://whatismyipaddress.com](https://whatismyipaddress.com) then your IP is private.

Dynamic DNS (DDNS) will not work in either of these situations.

### **VPN Solution**

The problem above only happens to connections started from outside the home. It does not affect connections originating from within your home, ie. your NAS.

So the solution is to have your NAS contact an outside server to start a connection. Further communications are unaffected after the connection is established.

This outside server is an unrestricted VPN server that has a static public IP. Any traffic on any port that it receives can be forwarded to your NAS.

## **Setup** (for Dummies)

1. Sign up with a cloud provider.

    I use Hetzner ([20€ coupon](https://hetzner.cloud/?ref=qfeTgy8M0mjf) - full disclosure: affiliate link).

1. Create a server:

    Choose CentOS-7 as the Operating System Image, and the smallest size should suffice.

    You should get an email or notification with an `(IP Address)` and `(root password)`.

1. Sign in

    If using Windows, press (Windows Key)-R and enter: `ssh root@(IP Address)`

    Enter the `(root password)` when asked.

    When prompted, change the given password to one you'll remember.

1. Install docker
  
    Copy/paste this onto the command line:

   ```bash
   yum install -y docker
   systemctl enable docker.service
   systemctl start docker.service
   ```

1. Decide your `(user_name)`, `(vpn_password)` and `(pre_shared_key)` to be used below.

    Do not use spaces.

    The vpn_password and pre_shared_key are both passwords.  Enter 8-12 characters and make them different.

1. Choose Ports

   Decide what apps you need to access on your NAS and choose the corresponding ports. An App/Port list can be found here for [Synology](https://www.synology.com/en-us/knowledgebase/DSM/tutorial/Network/What_network_ports_are_used_by_Synology_services) and [QNap](https://www.qnap.com.cn/en/how-to/faq/article/what-is-the-port-number-used-by-the-turbo-nas).

1. Run the Server

    Copy/Paste this code onto the command line substituting (data):

    ```bash
    docker run --name nas-forwarder -d --privileged --restart=always -p 500:500/udp -p 4500:4500/udp \
      -p (1st Port from above):(1st Port from above)/tcp \
      -p (2nd Port):(2nd Port)/tcp \
          etc...
      -p (Last Port):(Last Port)/tcp \
      -e VPN_IPSEC_PSK=(pre_shared_key) \
      -e VPN_USER=(user_name) \
      -e VPN_PASSWORD=(vpn_password) \
      -e FORWARD_TCP_PORTS=(list of ports from above) \
      mlefkon/nas-forwarder-vpn
    ```

    **Important**: The list of `-p` ports must match the list of `FORWARD_TCP_PORTS`.

    eg. On a Synology NAS to enable DSM, WebDAV and DS-Audio/File/Get/Photo (ports: 5000, 5001, 5005, 5006, 80 and 443):

    ```bash
    docker run --name nas-forwarder -d --privileged --restart=always -p 500:500/udp -p 4500:4500/udp \
      -p 5000:5000/tcp \
      -p 5001:5001/tcp \
      -p 5005:5005/tcp \
      -p 5006:5006/tcp \
      -p 80:80/tcp \
      -p 443:443/tcp \
      -e VPN_IPSEC_PSK='myipsecpresharedkey' \
      -e VPN_USER='testuser' \
      -e VPN_PASSWORD='testpassword' \
      -e FORWARD_TCP_PORTS='5000,5001,5005,5006,80,443' \
      mlefkon/nas-forwarder-vpn
    ```

1. Connect your NAS (example with Synology)
  
    - In Control Panel, select Network -> Network Interface (tab) -> Create Menu -> Create VPN Profile

      ![-See github.com/mlefkon/nas-forwarder-vpn for images](./images/nas.a.png)

    - Select L2TP/IPSec

      ![-See github.com/mlefkon/nas-forwarder-vpn for images](./images/nas.b.png)

    - General Settings

      Profile Name: Any name will do

      Server Address: Use the same `(IP Address)` as you used in the `ssh` command above.

      Username, Password, Pre-shared Key: use the ones that you filled into the `docker run` command above.

      ![-See github.com/mlefkon/nas-forwarder-vpn for images](./images/nas.c.png)

    - Advanced Settings

      Authentication: use 'PAP

      Select:

      - Use default gateway on remote network

      - Server is behind NAT device

      - Reconnect when the VPN connection is lost

      ![-See github.com/mlefkon/nas-forwarder-vpn for images](./images/nas.d.png)

      Hit 'Apply'

    - Select your NAS Forwarder VPN, right-click and 'Connect'

      ![-See github.com/mlefkon/nas-forwarder-vpn for images](./images/nas.e.png)

    - And Success

      ![-See github.com/mlefkon/nas-forwarder-vpn for images](./images/nas.f.png)

      Note: the IP Address here is irrelevant because it is the NAS's IP within the private VPN network.

1. Use your NAS

    Now you can use your NAS and it's services in an app or a web browser.  When you connect, make sure you use your new `(IP address)` (from `ssh`, not from the NAS's Connected indicator above) and the port number needed.

      ![-See github.com/mlefkon/nas-forwarder-vpn for images](./images/nas.g.png)

## Notes

Only make one connection (with your NAS) to this VPN.  Do not connect other PCs or devices.  The VPN forwards to the first device connected, so if a phone connected first for some reason, the NAS connecting later would not see any traffic.

## Trouble Shooting

Log into your cloud server, `ssh root@(IP Address)`, and look at the VPN's logs:

```bash
docker logs nas-forwarder
```

## Make Your Server Friendlier

- Domain Name

    Names are easier to remember than IP addresses.  Link your IP address to a domain name at a registar (eg. [Hetzner](https://www.hetzner.com/domainregistration), [GoDaddy](https://www.godaddy.com)) to make connecting earier.

- Security (Advanced)

    It's annoying to click 'Proceed to Unsafe Website' every time you want visit your NAS and then see the 'Not Secure' message above.

    Use a free product like [Traefik](https://traefik.io/) to secure your domain name with the  (also free) [Let's Encrypt](https://letsencrypt.org/) Certificate Authority.
