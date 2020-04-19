#!/bin/bash
rm -f /var/run/yum.pid	&&
yum install -y wget	&&
yum install -y git	&&
git clone https://github.com/sivel/speedtest-cli.git&&
yum -y install net-tools&&
yum -y install vim&&
git clone https://github.com/arut/nginx-rtmp-module.git&&
wget http://nginx.org/download/nginx-1.8.1.tar.gz&&
yum -y install gcc-c++&&
yum -y install openssl openssl-devel&&
yum -y install pcre pcre-devel&&
yum -y install zlib zlib-devel&&
yum -y install vsftpd&&
tar -zxvf nginx-1.8.1.tar.gz&&
cd nginx-1.8.1&&
./configure --prefix=/usr/local/nginx  --add-module=../nginx-rtmp-module  --with-http_ssl_module&&
make	&& 
make install	&&
cd /root &&
mkdir -p /home/html/hls	&&
chmod 777 /home/html/hls	&&
mkdir -p /home/html/record	&&
chmod 777 /home/html/record	&&
cp /usr/local/nginx/conf/nginx.conf /usr/local/nginx/conf/nginx.conf.bak	&&
rm -f /usr/local/nginx/conf/nginx.conf&&
cat>/usr/local/nginx/conf/nginx.conf<<EOF
#user  nobody;
worker_processes  1;

#error_log  logs/error.log;
#error_log  logs/error.log  notice;
#error_log  logs/error.log  info;

#pid        logs/nginx.pid;


events {
    worker_connections  1024;
}


http {
    include       mime.types;
    default_type  application/octet-stream;

    #log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
    #                  '$status $body_bytes_sent "$http_referer" '
    #                  '"$http_user_agent" "$http_x_forwarded_for"';

    #access_log  logs/access.log  main;

    sendfile        on;
    #tcp_nopush     on;

    #keepalive_timeout  0;
    keepalive_timeout  65;

    #gzip  on;

    server {
        listen       81;
        server_name  localhost;

        #charset koi8-r;

        #access_log  logs/host.access.log  main;
	
	location /stat {
	  	rtmp_stat all;
		rtmp_stat_stylesheet stat.xsl;
        }
	location stat.xsl{
	root /root/nginx-rtmp-module/;
	}
        location /{
		root	 /home/html;
		index index.html index.htm;
        }

        #error_page  404              /404.html;

        # redirect server error pages to the static page /50x.html
        #
        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   html;
        }

        # proxy the PHP scripts to Apache listening on 127.0.0.1:80
        #
        #location ~ \.php$ {
        #    proxy_pass   http://127.0.0.1;
        #}

        # pass the PHP scripts to FastCGI server listening on 127.0.0.1:9000
        #
        #location ~ \.php$ {
        #    root           html;
        #    fastcgi_pass   127.0.0.1:9000;
        #    fastcgi_index  index.php;
        #    fastcgi_param  SCRIPT_FILENAME  /scripts$fastcgi_script_name;
        #    include        fastcgi_params;
        #}

        # deny access to .htaccess files, if Apache's document root
        # concurs with nginx's one
        #
        #location ~ /\.ht {
        #    deny  all;
        #}
    }


    # another virtual host using mix of IP-, name-, and port-based configuration
    #
    #server {
    #    listen       8000;
    #    listen       somename:8080;
    #    server_name  somename  alias  another.alias;

    #    location / {
    #        root   html;
    #        index  index.html index.htm;
    #    }
    #}


    # HTTPS server
    #
    #server {
    #    listen       443 ssl;
    #    server_name  localhost;

    #    ssl_certificate      cert.pem;
    #    ssl_certificate_key  cert.key;

    #    ssl_session_cache    shared:SSL:1m;
    #    ssl_session_timeout  5m;

    #    ssl_ciphers  HIGH:!aNULL:!MD5;
    #    ssl_prefer_server_ciphers  on;

    #    location / {
    #        root   html;
    #        index  index.html index.htm;
    #    }
    #}

}
rtmp{
	server{
		listen 1935;
		chunk_size 4096;
	application hls{
	live on;
	#push rtmp://p1.weizan.cn/v/11886982_132294270062269007?t=2e8e2;
	#push rtmp://167.179.77.30:1935/hls/live;
	#pull rtmp://r2.weizan.cn/v/11886982_132310524333578171;
	hls on;
	hls_path /home/html/hls;
	hls_fragment 5s;
	record all;
	record_path /home/html/record;
	record_interval 60m;
	record_suffix rec.mp4;
	record_unique on;
	#record_max_size 51200K;
	}

	application vod{
	play  /home/html/record;
        }
}
}

EOF
/usr/local/nginx/sbin/nginx -c  /usr/local/nginx/conf/nginx.conf	&&
cat>/lib/systemd/system/nginx.service<<EOF
[Unit]
Description=nginx
After=network.target
 
[Service]
Type=forking
ExecStart=/usr/local/nginx/sbin/nginx -c  /usr/local/nginx/conf/nginx.conf
ExecReload=/usr/local/nginx/sbin/nginx -s reload
ExecStop=/usr/local/nginx/sbin/nginx -s quit
PrivateTmp=true
 
[Install]
WantedBy=multi-user.target
EOF
systemctl enable nginx.service	&&
mv /usr/local/nginx/html/index.html  /usr/local/nginx/html/index.html.bak	&&
cat>/home/html/index.html<<EOF
<html>
<head>
    <title>live</title>
    <meta charset="utf-8">
    <link href="http://vjs.zencdn.net/5.5.3/video-js.css" rel="stylesheet">
    <!-- If you'd like to support IE8 -->
    <script src="http://vjs.zencdn.net/ie8/1.1.1/videojs-ie8.min.js"></script>
    <script src="http://vjs.zencdn.net/5.5.3/video.js"></script>
</head>
<body>
<video id="my-video" class="video-js" controls preload="auto" width="640" height="480"
       poster="http://ppt.downhot.com/d/file/p/2014/08/12/9d92575b4962a981bd9af247ef142449.jpg" data-setup="{}">
    <source src="rtmp://211.143.153.21/hls/live" type="rtmp/flv">
    </p>
</video>

</body>
</html>
EOF
cd /root	&&
cat>>/etc/bashrc<<EOF
alias cdng="cd /usr/local/nginx/conf"
alias cdhtml="cd /home/html"
alias cdrecord="cd /home/html/record"
alias reloadng="/usr/local/nginx/sbin/nginx -s reload"
alias stopng="/usr/local/nginx/sbin/nginx -s stop"
alias startng="/usr/local/nginx/sbin/nginx -c  /usr/local/nginx/conf/nginx.conf"
alias vimng="vim /usr/local/nginx/conf/nginx.conf"
EOF
firewall-cmd --add-port=1935/tcp --permanent	&&
firewall-cmd --add-port=81/tcp --permanent	&&
firewall-cmd --add-service=ftp --permanent	&&
firewall-cmd --add-service=http --permanent	&&
firewall-cmd --reload	&&
systemctl restart firewalld	&&
echo anonymous_enable=NO>>/etc/vsftpd/vsftpd.conf	&&
echo chroot_local_user=YES>>/etc/vsftpd/vsftpd.conf	&&
echo allow_writeable_chroot=YES>>/etc/vsftpd/vsftpd.conf	&&
systemctl start vsftpd	&&
source  /etc/bashrc	&&
cd speedtest-cli	&&
./speedtest.py --server 16171	&&
echo “all install completed” 

