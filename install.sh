echo -e "\x1B[01;90m\n¦ installing some libs ...\n \x1B[0m"
sudo apt install build-essential libreadline-dev unzip
sudo apt-get install libssl-dev -y
echo -e "\x1B[01;90m\n¦ installing redis-server ...\n \x1B[0m"
sudo apt-get install redis -y
echo -e "\x1B[01;90m\n¦ starting redis-server ...\n \x1B[0m"
redis-server --daemonize yes
echo -e "\x1B[01;90m\n¦ installing lua ...\n \x1B[0m"
curl -R -O http://www.lua.org/ftp/lua-5.3.5.tar.gz
tar -zxf lua-5.3.5.tar.gz
cd lua-5.3.5
make linux test
sudo make install
echo -e "\x1B[01;90m\n¦ installing luarocks ...\n \x1B[0m"
wget https://luarocks.org/releases/luarocks-3.8.0.tar.gz
tar zxpf luarocks-3.8.0.tar.gz
cd luarocks-3.8.0
./configure --with-lua-include=/usr/local/include && make && make install
echo -e "\x1B[01;90m\n¦ installing luarocks libs ...\n \x1B[0m"
sudo luarocks install telegram-bot-lua
sudo luarocks install lua-llthreads2
sudo luarocks install redis-lua
sudo luarocks install lua-requests
echo -e "\x1B[01;90m\n¦ installing python packages ...\n \x1B[0m"
sudo pip install redis
sudo pip install telethon
clear
echo -e "\x1B[01;90m\n¦ done. ...\n \x1B[0m"
