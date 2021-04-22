# NAS Forwarder VPN

- Image repository [Dockerhub: mlefkon/nas-forwarder-vpn](https://hub.docker.com/r/mlefkon/nas-forwarder-vpn)

- Source repository [Github: mlefkon/nas-forwarder-vpn](https://github.com/mlefkon/nas-forwarder-vpn)

## **What It Does**

### **ISP Blocking Problem**

You can't connect to your NAS from outside the home if:

- Your ISP blocks some ports.
- Your ISP gives you a private IP address.  
  
  Your home modem is hidden behind the ISP's NAT router. The ISP has a single public IP on one side of the router and many homes' private IPs on the other side.  This is probably the case if the ISP is cellular, but could happen as well with a landline ISP.  ISPs do this to conserve IP addresses.

  To check this:

  - Logon to admin page of your router and check the "Internet Status". Find the IP address.  If it differs from [https://whatismyipaddress.com](https://whatismyipaddress.com) then your IP is private.

Dynamic DNS (DDNS) will not work in either of these situations.

### **VPN Solution**

The problem above only happens to connections started from outside the home. It does not affect connections originating from within your home, ie. your NAS.

So the solution is to have your NAS contact an outside server to start a connection. Further communications are unaffected after the connection is established.

This outside server is an unrestricted VPN server that has a static public IP. Any traffic on any port that it receives can be forwarded to your NAS.

## **Setup** (for Dummies)

1. Sign up with a cloud provider, eg. Hetzner ([20€ coupon](https://hetzner.cloud/?ref=qfeTgy8M0mjf) - full disclosure: affiliate link).

1. Create a cloud server:

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

1. Decide your `(vpn_user_name)`, `(vpn_user_password)` and `(vpn_pre_shared_key)` to be used below.

    Do not use spaces.

    The vpn_user_password and vpn_pre_shared_key are both passwords.  Enter 8-12 characters and make them different.

1. Choose Ports

   Decide what apps you need to access on your NAS and choose the corresponding ports. Service/App/Port lists can be found here: [Synology](https://www.synology.com/en-us/knowledgebase/DSM/tutorial/Network/What_network_ports_are_used_by_Synology_services), [QNap](https://www.qnap.com.cn/en/how-to/faq/article/what-is-the-port-number-used-by-the-turbo-nas), [TrueNAS](https://www.truenas.com/docs/references/defaultports/), [Asustor](https://www.asustor.com/knowledge/detail/?id=6&group_id=601), [NetGear ReadyNAS](https://kb.netgear.com/1166/Port-numbers-for-port-forwarding)

1. Run the VPN Server

    Copy/Paste this code onto the command line substituting (data):

    ```bash
    docker run --name nas-forwarder -d --privileged --restart=always -p 500:500/udp -p 4500:4500/udp \
      -p (1st Port from above):(1st Port from above)/tcp \
      -p (2nd Port):(2nd Port)/tcp \
          etc...
      -p (Last Port):(Last Port)/tcp \
      -e VPN_IPSEC_PSK=(vpn_pre_shared_key) \
      -e VPN_USER=(vpn_user_name) \
      -e VPN_PASSWORD=(vpn_user_password) \
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

      ![-For images see: github.com/mlefkon/nas-forwarder-vpn](./images/nas.a.png)

    - Select L2TP/IPSec

      ![-For images see: github.com/mlefkon/nas-forwarder-vpn](./images/nas.b.png)

    - General Settings

      Profile Name: Any name will do

      Server Address: Use the same `(IP Address)` as you used in the `ssh` command above.

      Username, Password, Pre-shared Key: use the ones that you filled into the `docker run` command above.

      ![-For images see: github.com/mlefkon/nas-forwarder-vpn](./images/nas.c.png)

    - Advanced Settings

      Authentication: use 'PAP

      Select:

      - Use default gateway on remote network

      - Server is behind NAT device

      - Reconnect when the VPN connection is lost

      ![-For images see: github.com/mlefkon/nas-forwarder-vpn](./images/nas.d.png)

      Hit 'Apply'

    - Select your NAS Forwarder VPN, right-click and 'Connect'

      ![-For images see: github.com/mlefkon/nas-forwarder-vpn](./images/nas.e.png)

    - And Success

      ![-For images see: github.com/mlefkon/nas-forwarder-vpn](./images/nas.f.png)

      Note: the IP Address here is irrelevant because it is the NAS's IP within the private VPN network.

1. Use your NAS

    Now you can use your NAS and it's services in an app or a web browser.  When you connect, make sure you use your new `(IP address)` (from `ssh`, not from the NAS's Connected indicator above) and the port number needed.

      ![-For images see: github.com/mlefkon/nas-forwarder-vpn](./images/nas.g.png)

### Note

Only make one connection (with your NAS) to this VPN.  Do not connect other PCs or devices.  The VPN forwards to the first device connected, so if a phone connected first for some reason, the NAS connecting later would not see any traffic.

## Make Your Server Friendlier

Your new server is a bit annoying right now:

- You need to remember it's IP address
- Web browsers warn that the connection is insecure
- The port must be appended to the URL

With a domain name, the security message will be eliminated and you won't have to type the port each time.

### Get a Domain Name

  Link your new cloud server's IP address to a domain name via a registar (eg. [Hetzner](https://www.hetzner.com/domainregistration), [GoDaddy](https://www.godaddy.com)).

  In the example below (for a Synology NAS), these sub-domains are used:

- nas.(my_domain).com
- www.nas.(my_domain).com
- dsm.nas.(my_domain).com
- webdav.nas.(my_domain).com
- traefik.(my_domain).com

### Attach the Domain Name to your Cloud Server

Use a free product like [Traefik](https://traefik.io/) to handle your domain name with the (also free) [Let's Encrypt](https://letsencrypt.org/) Certificate Authority.  

First `ssh root@(IP Address)` into your cloud server and remove any current VPN you may have up:

```bash
docker rm -f nas-forwarder
```

Setup an internal Traefik network:

```bash
docker network create traefik-net
```

Create permanent storage for SSL keys:

```bash
docker volume create letsencryptstorage
```

Copy/paste the following, filling in `(vpn_user_name)`, `(vpn_user_password)` and `(vpn_pre_shared_key)` again as well as `(my_domain)` and `(my_email_address)`:

```bash
docker run --restart=always --network=traefik-net --detach --name traefik \
-v "//var/run/docker.sock://var/run/docker.sock:ro" \
-v letsencryptstorage:/letsencrypt \
-p 80:80/tcp -p 443:443/tcp \
--label 'traefik.enable=true' \
--label 'traefik.docker.network=traefik-net' \
--label 'traefik.http.routers.AllHttp.rule=hostregexp(`{host:.+}`)' \
--label 'traefik.http.routers.AllHttp.entrypoints=Web' \
--label 'traefik.http.routers.AllHttp.middlewares=RedirectToHttps' \
--label 'traefik.http.routers.AllHttp.service=noop@internal' \
--label 'traefik.http.routers.TraefikDashboard.rule=Host(`traefik.(my_domain).com`)' \
--label 'traefik.http.routers.TraefikDashboard.entrypoints=WebSecure' \
--label 'traefik.http.routers.TraefikDashboard.tls=true' \
--label 'traefik.http.routers.TraefikDashboard.tls.certresolver=LetsEncryptCert' \
--label 'traefik.http.routers.TraefikDashboard.service=api@internal' \
--label 'traefik.http.middlewares.RedirectToHttps.redirectscheme.scheme=https' \
traefik:v2.4 \
--providers.docker=true \
--providers.docker.exposedbydefault=false \
--entrypoints.Web.address=:80 \
--entrypoints.WebSecure.address=:443 \
--certificatesresolvers.LetsEncryptCert.acme.email=(my_email_address) \
--certificatesresolvers.LetsEncryptCert.acme.storage=/etc/acme.json \
--certificatesresolvers.LetsEncryptCert.acme.tlschallenge=true \
--serverstransport.insecureskipverify=true \
--api \
--api.dashboard \
--log=true \
--log.filePath=/logs/traefik.log \
--log.format=common \
--accesslog=true \
--accesslog.filepath=/logs/access.log \
--accesslog.format=common

docker run --restart=always --network=traefik-net --detach --name nas-forwarder --privileged \
-p 500:500/udp -p 4500:4500/udp -p 20:20/tcp -p 21:21/tcp -p 4022:22/tcp -p 873:873/tcp -p 6690:6690/tcp \
--expose 443/tcp --expose 5001/tcp --expose 5006/tcp \
--label 'traefik.enable=true' \
--label 'traefik.docker.network=traefik-net' \
--label 'traefik.http.routers.NasAdmin.rule=Host(`dsm.nas.(my_domain).com`)' \
--label 'traefik.http.routers.NasAdmin.entrypoints=WebSecure' \
--label 'traefik.http.routers.NasAdmin.tls=true' \
--label 'traefik.http.routers.NasAdmin.tls.certresolver=LetsEncryptCert' \
--label 'traefik.http.routers.NasAdmin.service=NasAdminServer' \
--label 'traefik.http.services.NasAdminServer.loadbalancer.server.port=5001' \
--label 'traefik.http.services.NasAdminServer.loadbalancer.server.scheme=https' \
--label 'traefik.http.routers.NasWeb.rule=Host(`www.nas.(my_domain).com`)' \
--label 'traefik.http.routers.NasWeb.entrypoints=WebSecure' \
--label 'traefik.http.routers.NasWeb.tls=true' \
--label 'traefik.http.routers.NasWeb.tls.certresolver=LetsEncryptCert' \
--label 'traefik.http.routers.NasWeb.service=NasWebServer' \
--label 'traefik.http.services.NasWebServer.loadbalancer.server.port=443' \
--label 'traefik.http.services.NasWebServer.loadbalancer.server.scheme=https' \
--label 'traefik.http.routers.NasWebDAV.rule=Host(`webdav.nas.(my_domain).com`)' \
--label 'traefik.http.routers.NasWebDAV.entrypoints=WebSecure' \
--label 'traefik.http.routers.NasWebDAV.tls=true' \
--label 'traefik.http.routers.NasWebDAV.tls.certresolver=LetsEncryptCert' \
--label 'traefik.http.routers.NasWebDAV.service=NasWebDAVServer' \
--label 'traefik.http.services.NasWebDAVServer.loadbalancer.server.port=5006' \
--label 'traefik.http.services.NasWebDAVServer.loadbalancer.server.scheme=https' \
-e VPN_IPSEC_PSK=(vpn_pre_shared_key) \
-e VPN_USER=(vpn_user_name)) \
-e VPN_PASSWORD=(vpn_user_password) \
-e FORWARD_TCP_PORTS='5001,5006,443,6690,873,22,20,21' \
mlefkon/nas-forwarder-vpn

```

Lastly, update the IP address that you entered into your NAS's VPN Profile above and change it to [nas.(my_domain).com](nas.(my_domain).com).

### All Done

Now you can browse to your NAS:

- [https://dsm.nas.(my_domain).com](https://dsm.nas.(my_domain).com) - NAS Administration
- [https://www.nas.(my_domain).com](https://www.nas.(my_domain).com) - NAS's web server (blog, etc)
- [https://webdav.nas.(my_domain).com](https://webdav.nas.(my_domain).com) - Supply this to applications that sync files, contacts, calendar, etc

See the state of Traefik:

- [https://traefik.(my_domain).com](https://traefik.(my_domain).com) - You may want to secure this with [Traefik Basic Authentication](https://doc.traefik.io/traefik/v2.0/middlewares/basicauth/)

To `ssh` into the NAS, use the alternate SSH port defined above (4022) because otherwise access to your cloud server would be blocked:

- `ssh username@nas.(my_domain).com -p 4022`

Similarly, `rsync` to the NAS using port 4022 as well:

- `rsync -e 'ssh -p 4022' /src/path username@nas.(my_domain).com:/dest/path`

## Troubleshooting

Log into your cloud server, `ssh root@(IP Address/Domain Name)`, then copy/paste:

  Command|To See
  ---|---
  `docker logs nas-forwarder`|docker's logs for VPN
  `docker logs traefik`|docker's logs for Traefik
  `docker exec traefik cat /logs/traefik.log`|Traefik errors
  `docker exec traefik cat /logs/access.log`|Outside Visitors (not your NAS)
  `docker exec syno-forwarder ipsec trafficstatus`|See connections to VPN (there should only be one, your NAS)
