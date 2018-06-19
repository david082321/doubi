#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#=================================================
#	System Required: CentOS/Debian/Ubuntu
#	Description: Libsodium Install
#	Version: 1.0.0
#	Author: Toyo
#	Blog: https://doub.io/shell-jc6/
#=================================================

Libsodiumr_file="/usr/local/lib/libsodium.so"
Libsodiumr_ver_backup="1.0.15"

Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[訊息]${Font_color_suffix}" && Error="${Red_font_prefix}[錯誤]${Font_color_suffix}" && Tip="${Green_font_prefix}[注意]${Font_color_suffix}"

Check_Libsodium_ver(){
	echo -e "${Info} 開始獲取 libsodium 最新版本..."
	Libsodiumr_ver=$(wget -qO- "https://github.com/jedisct1/libsodium/tags"|grep "/jedisct1/libsodium/releases/tag/"|head -1|sed -r 's/.*tag\/(.+)\">.*/\1/')
	[[ -z ${Libsodiumr_ver} ]] && Libsodiumr_ver=${Libsodiumr_ver_backup}
	echo -e "${Info} libsodium 最新版本為 ${Green_font_prefix}[${Libsodiumr_ver}]${Font_color_suffix} !"
}
Install_Libsodium(){
	if [[ -e ${Libsodiumr_file} ]]; then
		echo -e "${Error} libsodium 已安裝 , 是否覆蓋安裝(或者更新)？[y/N]"
		stty erase '^H' && read -p "(預設: n):" yn
		[[ -z ${yn} ]] && yn="n"
		if [[ ${yn} == [Nn] ]]; then
			echo "已取消..." && exit 1
		fi
	else
		echo -e "${Info} libsodium 未安裝，開始安裝..."
	fi
	Check_Libsodium_ver
	if [[ ${release} == "centos" ]]; then
		yum update
		echo -e "${Info} 安裝依賴..."
		yum -y groupinstall "Development Tools"
		echo -e "${Info} 下載..."
		wget  --no-check-certificate -N "https://github.com/jedisct1/libsodium/releases/download/${Libsodiumr_ver}/libsodium-${Libsodiumr_ver}.tar.gz"
		echo -e "${Info} 解壓..."
		tar -xzf libsodium-${Libsodiumr_ver}.tar.gz
		cd libsodium-${Libsodiumr_ver}
		echo -e "${Info} 編譯安裝..."
		./configure --disable-maintainer-mode
		make -j2
		make install
		echo /usr/local/lib > /etc/ld.so.conf.d/usr_local_lib.conf
	else
		apt-get update
		echo -e "${Info} 安裝依賴..."
		apt-get install -y build-essential
		echo -e "${Info} 下載..."
		wget  --no-check-certificate -N "https://github.com/jedisct1/libsodium/releases/download/${Libsodiumr_ver}/libsodium-${Libsodiumr_ver}.tar.gz"
		echo -e "${Info} 解壓..."
		tar -xzf libsodium-${Libsodiumr_ver}.tar.gz
		cd libsodium-${Libsodiumr_ver}
		echo -e "${Info} 編譯安裝..."
		./configure --disable-maintainer-mode
		make -j2
		make install
	fi
	ldconfig
	cd ..
	rm -rf libsodium-${Libsodiumr_ver}.tar.gz
	rm -rf libsodium-${Libsodiumr_ver}
	[[ ! -e ${Libsodiumr_file} ]] && echo -e "${Error} libsodium 安裝失敗 !" && exit 1
	echo && echo -e "${Info} libsodium 安裝成功 !" && echo
}
action=$1
[[ -z $1 ]] && action=install
case "$action" in
	install)
	Install_Libsodium
	;;
    *)
    echo "輸入錯誤 !"
    echo "用法: [ install ]"
    ;;
esac
