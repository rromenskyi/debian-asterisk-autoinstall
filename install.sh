#!/bin/sh
#asterisk 18-cert autoinstall script on debian 12

###
# install packages/deps
###
apt-get -y install mc fail2ban docker docker.io libedit-dev git curl wget libnewt-dev libssl-dev libncurses5-dev subversion libsqlite3-dev build-essential libjansson-dev libxml2-dev uuid-dev autoconf libpcap-dev libxml2-utils odbc-mariadb mariadb-server pwgen libmariadb-dev unixodbc-dev

###
# system config
###
#echo "root            soft    nofile          16384\nroot            hard    nofile          65535\nasterisk        soft    nofile          16384\nasterisk        hard    nofile          65535" | sudo tee -a /etc/security/limits.conf

###
# fail2ban install/conf
###
mkdir -p /var/run/fail2ban
sudo tee /etc/fail2ban/jail.d/defaults-debian.conf << END
[sshd]
backend=systemd
enabled=true

[asterisk]
enabled  = true
port     = 5060,5061
action   = %(action_mwl)s
filter   = asterisk
logpath  = /var/log/asterisk/full
maxretry = 5
bantime  = 600
findtime  = 600

END
systemctl restart fail2ban
###
# tz conf
###
timedatectl set-timezone UTC
###
# asterisk cert configuration
###
mkdir -p /usr/src/
cd /usr/src/
wget -cq https://downloads.asterisk.org/pub/telephony/certified-asterisk/asterisk-certified-current.tar.gz
wget -cq https://downloads.asterisk.org/pub/telephony/certified-asterisk/asterisk-certified-current.md5
ln -sf `cat /usr/src/asterisk-certified-current.md5 | awk '{print $2}' | sed 's/\.tar\.gz$//'` asterisk-certified
sed -i 's/asterisk-.*\.tar\.gz/asterisk-certified-current.tar.gz/' /usr/src/asterisk-certified-current.md5

if [ `md5sum --ignore-missing -c asterisk-certified-current.md5 | awk '{print $2}'` = "OK" ]; then
echo "asterisk source downlad compete, extracting tgz"
tar -zxf asterisk-certified-current.tar.gz
rm -f asterisk-certified-current/menuselect.makeopts

###
# building pjsip
###
if [ ! -d /usr/src/pjproject ]; then
git clone https://github.com/asterisk/pjproject pjproject
else
cd pjproject
git pull
cd ..
fi
if [ ! -f /usr/local/lib/libpjmedia-audiodev.so.2 ]; then
cd pjproject && ./configure --prefix=/usr/local --enable-shared --disable-sound --disable-resample --disable-video --disable-opencore-amr
make dep && make -j8 && make install
cd ..
fi

###
# building sngrep
###
if [ ! -d /usr/src/sngrep ]; then
git clone https://github.com/irontec/sngrep sngrep
else
cd sngrep 
git pull
cd ..
fi
if [ ! -f /usr/local/bin/sngrep ]; then
cd sngrep
./bootstrap.sh && ./configure --prefix=/usr/local && make -j8 && make install
cd ..
fi

if [ ! -f /usr/sbin/asterisk ]; then
cd asterisk-certified
contrib/scripts/get_mp3_source.sh
#contrib/scripts/install_prereq install
./configure && make -j8 && make samples && make config && make install
echo asterisk installed!
cd ..
fi



# Check if group exists
if getent group "asterisk" &>/dev/null; then
    echo "Group asterisk exists."
else
    addgroup asterisk
    echo "Group asterisk does not exist."
fi

# Check if user exists
if id "asterisk" &>/dev/null; then
    echo "User asterisk exists."
else
    echo "User asterisk does not exist."
    useradd asterisk -d /var/lib/asterisk -g asterisk
fi


#wget -c http://downloads.digium.com/pub/telephony/codec_opus/asterisk-18.0/x86-64/codec_opus-18.0_current-x86_64.tar.gz
#tar -zxf codec_opus-18.0_current-x86_64.tar.gz
#cd codec_opus-18.0_1.3.0-x86_64
#mkdir -p /usr/lib/asterisk/modules
#cp codec_opus.so /usr/lib/asterisk/modules
#cp format_ogg_opus.so /usr/lib/asterisk/modules
#mkdir -p /var/lib/asterisk/documentation/thirdparty
#cp codec_opus_config-en_US.xml /var/lib/asterisk/documentation/thirdparty
#cd ..

#wget -c http://downloads.digium.com/pub/telephony/codec_g729/asterisk-18.0/x86-64/codec_g729a-18.0_3.1.10-x86_64.tar.gz


else
echo "asterisk md5 check error"
fi