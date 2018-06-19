# 一些腳本的依賴都放到這裡

jq-1.5.tar.gz
======

- 說明：JQ是一個Linux平台上的 JSON 格式解析器。
- 依賴於此軟體的腳本為：ssr.sh

### 下載安裝:
Debian/Ubuntu系統：
``` bash
apt-get install -y build-essential
wget --no-check-certificate -N "https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/other/jq-1.5.tar.gz"
tar -xzf jq-1.5.tar.gz && cd jq-1.5
./configure --disable-maintainer-mode && make && make install
ldconfig
cd .. && rm -rf jq-1.5.tar.gz && rm -rf jq-1.5
```
