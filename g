#!/usr/bin/env bash
# Usage: ./1-world_wide_web <domain> <subdomain>
# Display information about subdomains.

domain_information () {
    line=$(dig "$2"."$1" | grep -A1 'ANSWER SECTION:' | tr '\t' '\n' | tail -2 | tr '\n' ' ')
    echo "$2 $line" | awk '{print "The subdomain " $1 " is a " $2 " record and points to " $3}'
}

if [ "$#" == 1 ]
then
  domain_information "$1" "www"
  domain_information "$1" "lb-01"
  domain_information "$1" "web-01"
  domain_information "$1" "web-02"
elif [ "$#" == 2 ]
then
  domain_information "$1" "$2"
fi
 64  
0x10-https_ssl/1-haproxy_ssl_termination
@@ -0,0 +1,64 @@
global
    log /dev/log	local0
    log /dev/log	local1 notice
    chroot /var/lib/haproxy
    stats socket /run/haproxy/admin.sock mode 660 level admin expose-fd listeners
    stats timeout 30s
    maxconn 2048
    tune.ssl.default-dh-param 2048
    user haproxy
    group haproxy
    daemon

    # Default SSL material locations
    ca-base /etc/ssl/certs
    crt-base /etc/ssl/private

    # See: https://ssl-config.mozilla.org/#server=haproxy&server-version=2.0.3&config=intermediate
    ssl-default-bind-ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384
    ssl-default-bind-ciphersuites TLS_AES_128_GCM_SHA256:TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256
    ssl-default-bind-options ssl-min-ver TLSv1.2 no-tls-tickets

defaults
    log	global
    mode	http
    option forwardfor
    option http-server-close
    option	httplog
    option	dontlognull
    timeout connect 5000
    timeout client  50000
    timeout server  50000
    errorfile 400 /etc/haproxy/errors/400.http
    errorfile 403 /etc/haproxy/errors/403.http
    errorfile 408 /etc/haproxy/errors/408.http
    errorfile 500 /etc/haproxy/errors/500.http
    errorfile 502 /etc/haproxy/errors/502.http
    errorfile 503 /etc/haproxy/errors/503.http
    errorfile 504 /etc/haproxy/errors/504.http

frontend www-http
#	bind	0.0.0.0:80
    mode http
    reqadd X-Forwarded-Proto:\ http
    default_backend www-backend

frontend www-https
    mode http
    bind *:443 ssl crt /etc/haproxy/certs/www.topunderscodebnb.tech.pem
    reqadd X-Forwarded-Proto:\ https
    acl letsencrypt-acl path_beg /.well-known/acme-challenge/
    use_backend letsencrypt-backend if letsencrypt-acl
    default_backend www-backend

backend www-backend
    mode http
    http-request set-header X-Forwarded-For %[src]
    balance roundrobin
    redirect scheme https if !{ ssl_fc }
    server 1723-web-01 100.26.181.86:80 check
    server 1723-web-02 34.238.192.13:80 check

backend letsencrypt-backend
    mode http
    server letsencrypt 127.0.0.1:54321
 65  
0x10-https_ssl/100-redirect_http_to_https
@@ -0,0 +1,65 @@
global
    log /dev/log	local0
    log /dev/log	local1 notice
    chroot /var/lib/haproxy
    stats socket /run/haproxy/admin.sock mode 660 level admin expose-fd listeners
    stats timeout 30s
    maxconn 2048
    tune.ssl.default-dh-param 2048
    user haproxy
    group haproxy
    daemon

    # Default SSL material locations
    ca-base /etc/ssl/certs
    crt-base /etc/ssl/private

    # See: https://ssl-config.mozilla.org/#server=haproxy&server-version=2.0.3&config=intermediate
    ssl-default-bind-ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384
    ssl-default-bind-ciphersuites TLS_AES_128_GCM_SHA256:TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256
    ssl-default-bind-options ssl-min-ver TLSv1.2 no-tls-tickets

defaults
    log	global
    mode	http
    option forwardfor
    option http-server-close
    option	httplog
    option	dontlognull
    timeout connect 5000
    timeout client  50000
    timeout server  50000
    errorfile 400 /etc/haproxy/errors/400.http
    errorfile 403 /etc/haproxy/errors/403.http
    errorfile 408 /etc/haproxy/errors/408.http
    errorfile 500 /etc/haproxy/errors/500.http
    errorfile 502 /etc/haproxy/errors/502.http
    errorfile 503 /etc/haproxy/errors/503.http
    errorfile 504 /etc/haproxy/errors/504.http

frontend www-http
#	bind	0.0.0.0:80
    mode http
    reqadd X-Forwarded-Proto:\ http
    redirect scheme https code 301 if !{ ssl_fc }
    default_backend www-backend

frontend www-https
    mode http
    bind *:443 ssl crt /etc/haproxy/certs/www.topunderscodebnb.tech.pem
    reqadd X-Forwarded-Proto:\ https
    acl letsencrypt-acl path_beg /.well-known/acme-challenge/
    use_backend letsencrypt-backend if letsencrypt-acl
    default_backend www-backend

backend www-backend
    mode http
    http-request set-header X-Forwarded-For %[src]
    balance roundrobin
    redirect scheme https if !{ ssl_fc }
    server 1723-web-01 100.26.181.86:80 check
    server 1723-web-02 34.238.192.13:80 check

backend letsencrypt-backend
    mode http
    server letsencrypt 127.0.0.1:54321
 256  
0x10-https_ssl/README.md
@@ -0,0 +1,256 @@
0x10. HTTPS SSL
===============

-   By Sylvain Kalache, co-founder at Holberton School

#### In a nutshell...


Concepts
--------

*For this project, students are expected to look at these concepts:*

-   [DNS](https://alx-intranet.hbtn.io/concepts/12)
-   [Web stack debugging](https://alx-intranet.hbtn.io/concepts/68)

![](https://s3.amazonaws.com/intranet-projects-files/holbertonschool-sysadmin_devops/276/FlhGPEK.png)

Background Context
------------------

### What happens when you don't secure your website traffic?

![](https://s3.amazonaws.com/intranet-projects-files/holbertonschool-sysadmin_devops/276/xCmOCgw.gif)

Resources
---------

**Read or watch**:

-   [What is HTTPS?](https://alx-intranet.hbtn.io/rltoken/XT1BAiBL3Jpq1bn1q6IYXQ "What is HTTPS?")
-   [What are the 2 main elements that SSL is providing](https://alx-intranet.hbtn.io/rltoken/STj5WkAPACBxOvwB77Ycrw "What are the 2 main elements that SSL is providing")
-   [HAProxy SSL termination on Ubuntu16.04](https://alx-intranet.hbtn.io/rltoken/mJNlqZkTBxIxM2bpDK_VoA "HAProxy SSL termination on Ubuntu16.04")
-   [SSL termination](https://alx-intranet.hbtn.io/rltoken/CKUICfppIWI6UC0coEMB8g "SSL termination")
-   [Bash function](https://alx-intranet.hbtn.io/rltoken/zPjZ7-eSSQsLFsGA16C1HQ "Bash function")

**man or help**:

-   `awk`
-   `dig`

Learning Objectives
-------------------

At the end of this project, you are expected to be able to [explain to anyone](https://alx-intranet.hbtn.io/rltoken/fJ20wsMngb_yNAhGgBwzlQ "explain to anyone"), **without the help of Google**:

### General

-   What is HTTPS SSL 2 main roles
-   What is the purpose encrypting traffic
-   What SSL termination means

Requirements
------------

### General

-   Allowed editors: `vi`, `vim`, `emacs`
-   All your files will be interpreted on Ubuntu 16.04 LTS
-   All your files should end with a new line
-   A `README.md` file, at the root of the folder of the project, is mandatory
-   All your Bash script files must be executable
-   Your Bash script must pass `Shellcheck` (version `0.3.7`) without any error
-   The first line of all your Bash scripts should be exactly `#!/usr/bin/env bash`
-   The second line of all your Bash scripts should be a comment explaining what is the script doing

Quiz questions
--------------

**Great!** You've completed the quiz successfully! Keep going! (Show quiz)

Your servers
------------

| Name | Username | IP | State |\
 |
| --- | --- | --- | --- | --- |
| 1723-web-01 | `ubuntu` | `100.26.181.86` | running |\
 |

|\
 |
| 1723-web-02 | `ubuntu` | `34.238.192.13` | running |\
 |

|\
 |
| 1723-lb-01 | `ubuntu` | `34.239.164.90` | running |\
 |

|\
 |

Tasks
-----

### 0\. World wide web

mandatory


Configure your domain zone so that the subdomain `www` points to your load-balancer IP (`lb-01`). Let's also add other subdomains to make our life easier, and write a Bash script that will display information about subdomains.

Requirements:

-   Add the subdomain `www` to your domain, point it to your `lb-01` IP (your domain name might be configured with default subdomains, feel free to remove them)
-   Add the subdomain `lb-01` to your domain, point it to your `lb-01` IP
-   Add the subdomain `web-01` to your domain, point it to your `web-01` IP
-   Add the subdomain `web-02` to your domain, point it to your `web-02` IP
-   Your Bash script must accept 2 arguments:
    1.  `domain`:
        -   type: string
        -   what: domain name to audit
        -   mandatory: yes
    2.  `subdomain`:
        -   type: string
        -   what: specific subdomain to audit
        -   mandatory: no
-   Output: `The subdomain [SUB_DOMAIN] is a [RECORD_TYPE] record and points to [DESTINATION]`
-   When only the parameter `domain` is provided, display information for its subdomains `www`, `lb-01`, `web-01` and `web-02` - in this specific order
-   When passing `domain` and `subdomain` parameters, display information for the specified subdomain
-   Ignore `shellcheck` case `SC2086`
-   Must use:
    -   `awk`
    -   at least one Bash function
-   You do not need to handle edge cases such as:
    -   Empty parameters
    -   Nonexistent domain names
    -   Nonexistent subdomains

Example:

```
sylvain@ubuntu$ dig www.holberton.online | grep -A1 'ANSWER SECTION:'
;; ANSWER SECTION:
www.holberton.online.   87  IN  A   54.210.47.110
sylvain@ubuntu$ dig lb-01.holberton.online | grep -A1 'ANSWER SECTION:'
;; ANSWER SECTION:
lb-01.holberton.online. 101 IN  A   54.210.47.110
sylvain@ubuntu$ dig web-01.holberton.online | grep -A1 'ANSWER SECTION:'
;; ANSWER SECTION:
web-01.holberton.online. 212    IN  A   34.198.248.145
sylvain@ubuntu$ dig web-02.holberton.online | grep -A1 'ANSWER SECTION:'
;; ANSWER SECTION:
web-02.holberton.online. 298    IN  A   54.89.38.100
sylvain@ubuntu$
sylvain@ubuntu$
sylvain@ubuntu$ ./0-world_wide_web holberton.online
The subdomain www is a A record and points to 54.210.47.110
The subdomain lb-01 is a A record and points to 54.210.47.110
The subdomain web-01 is a A record and points to 34.198.248.145
The subdomain web-02 is a A record and points to 54.89.38.100
sylvain@ubuntu$
sylvain@ubuntu$ ./0-world_wide_web holberton.online web-02
The subdomain web-02 is a A record and points to 54.89.38.100
sylvain@ubuntu$
```

**Repo:**

-   GitHub repository: `alx-system_engineering-devops`
-   Directory: `0x10-https_ssl`
-   File: `0-world_wide_web`

### 1\. HAproxy SSL termination

mandatory


"Terminating SSL on HAproxy" means that HAproxy is configured to handle encrypted traffic, unencrypt it and pass it on to its destination.

Create a certificate using `certbot` and configure `HAproxy` to accept encrypted traffic for your subdomain `www.`.

Requirements:

-   HAproxy must be listening on port TCP 443
-   HAproxy must be accepting SSL traffic
-   HAproxy must serve encrypted traffic that will return the `/` of your web server
-   When querying the root of your domain name, the page returned must contain `Holberton School`
-   Share your HAproxy config as an answer file (`/etc/haproxy/haproxy.cfg`)

The file `1-haproxy_ssl_termination` must be your HAproxy configuration file

Make sure to install HAproxy 1.5 or higher, [SSL termination](https://alx-intranet.hbtn.io/rltoken/CKUICfppIWI6UC0coEMB8g "SSL termination") is not available before v1.5.

Example:

```
sylvain@ubuntu$ curl -sI https://www.holberton.online
HTTP/1.1 200 OK
Server: nginx/1.4.6 (Ubuntu)
Date: Tue, 28 Feb 2017 01:52:04 GMT
Content-Type: text/html
Content-Length: 30
Last-Modified: Tue, 21 Feb 2017 07:21:32 GMT
ETag: "58abea7c-1e"
X-Served-By: 03-web-01
Accept-Ranges: bytes
sylvain@ubuntu$
sylvain@ubuntu$ curl https://www.holberton.online
Holberton School for the win!
sylvain@ubuntu$
```

**Repo:**

-   GitHub repository: `alx-system_engineering-devops`
-   Directory: `0x10-https_ssl`
-   File: `1-haproxy_ssl_termination`

### 2\. No loophole in your website traffic

#advanced


A good habit is to enforce HTTPS traffic so that no unencrypted traffic is possible. Configure HAproxy to automatically redirect HTTP traffic to HTTPS.

Requirements:

-   This should be transparent to the user
-   HAproxy should return a [301](https://alx-intranet.hbtn.io/rltoken/yGdTSvZAzHMnDEhalTjNUw "301")
-   HAproxy should redirect HTTP traffic to HTTPS
-   Share your HAproxy config as an answer file (`/etc/haproxy/haproxy.cfg`)

The file `100-redirect_http_to_https` must be your HAproxy configuration file

Example:

```
sylvain@ubuntu$ curl -sIL http://www.holberton.online
HTTP/1.1 301 Moved Permanently
Content-length: 0
Location: https://www.holberton.online/
Connection: close
HTTP/1.1 200 OK
Server: nginx/1.4.6 (Ubuntu)
Date: Tue, 28 Feb 2017 02:19:18 GMT
Content-Type: text/html
Content-Length: 30
Last-Modified: Tue, 21 Feb 2017 07:21:32 GMT
ETag: "58abea7c-1e"
X-Served-By: 03-web-01
Accept-Ranges: bytes
sylvain@ubuntu$
```

**Repo:**

-   GitHub repository: `alx-system_engineering-devops`
-   Directory: `0x10-https_ssl`
-   File: `100-redirect_http_to_https
