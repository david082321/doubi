#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#=================================================
#	System Required: Debian/Ubuntu
#	Description: TCP-BBR
#	Version: 1.0.22
#	Author: Toyo
#	Blog: https://doub.io/wlzy-16/
#=================================================

Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[訊息]${Font_color_suffix}"
Error="${Red_font_prefix}[錯誤]${Font_color_suffix}"
Tip="${Green_font_prefix}[注意]${Font_color_suffix}"
filepath=$(cd "$(dirname "$0")"; pwd)
file=$(echo -e "${filepath}"|awk -F "$0" '{print $1}')

check_root(){
	[[ $EUID != 0 ]] && echo -e "${Error} 目前帳號非ROOT(或沒有ROOT權限)，無法繼續操作，請使用${Green_background_prefix} sudo su ${Font_color_suffix}來獲取臨時ROOT權限（執行後會提示輸入目前帳號的密碼）。" && exit 1
}
#檢查系統
check_sys(){
	if [[ -f /etc/redhat-release ]]; then
		release="centos"
	elif cat /etc/issue | grep -q -E -i "debian"; then
		release="debian"
	elif cat /etc/issue | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
	elif cat /proc/version | grep -q -E -i "debian"; then
		release="debian"
	elif cat /proc/version | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
    fi
}
# 本段獲取最新版本的程式碼來源自: https://teddysun.com/489.html
Set_latest_new_version(){
	echo -e "請輸入 要下載安裝的Linux核心版本(BBR) ${Green_font_prefix}[ 格式: x.xx.xx ，例如: 4.9.96 ]${Font_color_suffix}
${Tip} 核心版本列表請去這裡獲取：${Green_font_prefix}[ http://kernel.ubuntu.com/~kernel-ppa/mainline/ ]${Font_color_suffix}
建議使用${Green_font_prefix}穩定版本：4.9.XX ${Font_color_suffix}，4.9 以上版本屬於測試版，穩定版與測試版同步更新，BBR 加速效果無區別。"
	stty erase '^H' && read -p "(直接回車，自動獲取最新穩定版本):" latest_version
	[[ -z "${latest_version}" ]] && get_latest_new_version
	echo
}
get_latest_new_version(){
	echo -e "${Info} 檢測穩定版核心最新版本中..."
	latest_version=$(wget -qO- -t1 -T2 "http://kernel.ubuntu.com/~kernel-ppa/mainline/" | awk -F'\"v' '/v4.9.*/{print $2}' |grep -v '\-rc'| cut -d/ -f1 | sort -V | tail -1)
	[[ -z ${latest_version} ]] && echo -e "${Error} 檢測核心最新版本失敗 !" && exit 1
	echo -e "${Info} 穩定版核心最新版本為 : ${latest_version}"
}
get_latest_version(){
	Set_latest_new_version
	bit=`uname -m`
	if [[ ${bit} == "x86_64" ]]; then
		deb_name=$(wget -qO- http://kernel.ubuntu.com/~kernel-ppa/mainline/v${latest_version}/ | grep "linux-image" | grep "generic" | awk -F'\">' '/amd64.deb/{print $2}' | cut -d'<' -f1 | head -1 )
		deb_kernel_url="http://kernel.ubuntu.com/~kernel-ppa/mainline/v${latest_version}/${deb_name}"
		deb_kernel_name="linux-image-${latest_version}-amd64.deb"
	else
		deb_name=$(wget -qO- http://kernel.ubuntu.com/~kernel-ppa/mainline/v${latest_version}/ | grep "linux-image" | grep "generic" | awk -F'\">' '/i386.deb/{print $2}' | cut -d'<' -f1 | head -1)
		deb_kernel_url="http://kernel.ubuntu.com/~kernel-ppa/mainline/v${latest_version}/${deb_name}"
		deb_kernel_name="linux-image-${latest_version}-i386.deb"
	fi
}
#檢查核心是否滿足
check_deb_off(){
	get_latest_new_version
	deb_ver=`dpkg -l|grep linux-image | awk '{print $2}' | awk -F '-' '{print $3}' | grep '[4-9].[0-9]*.'`
	latest_version_2=$(echo "${latest_version}"|grep -o '\.'|wc -l)
	if [[ "${latest_version_2}" == "1" ]]; then
		latest_version="${latest_version}.0"
	fi
	if [[ "${deb_ver}" != "" ]]; then
		if [[ "${deb_ver}" == "${latest_version}" ]]; then
			echo -e "${Info} 檢測到目前核心版本[${deb_ver}] 已滿足要求，繼續..."
		else
			echo -e "${Tip} 檢測到目前核心版本[${deb_ver}] 支援開啟BBR 但不是最新核心版本，可以使用${Green_font_prefix} bash ${file}/bbr.sh ${Font_color_suffix}來升級核心 !(注意：並不是越新的核心越好，4.9 以上版本的核心 目前皆為測試版，不保證穩定性，舊版本如使用無問題 建議不要升級！)"
		fi
	else
		echo -e "${Error} 檢測到目前核心版本[${deb_ver}] 不支援開啟BBR，請使用${Green_font_prefix} bash ${file}/bbr.sh ${Font_color_suffix}來更換最新核心 !" && exit 1
	fi
}
# 刪除其餘核心
del_deb(){
	deb_total=`dpkg -l | grep linux-image | awk '{print $2}' | grep -v "${latest_version}" | wc -l`
	if [[ "${deb_total}" -ge "1" ]]; then
		echo -e "${Info} 檢測到 ${deb_total} 個其餘核心，開始移除..."
		for((integer = 1; integer <= ${deb_total}; integer++))
		do
			deb_del=`dpkg -l|grep linux-image | awk '{print $2}' | grep -v "${latest_version}" | head -${integer}`
			echo -e "${Info} 開始移除 ${deb_del} 核心..."
			apt-get purge -y ${deb_del}
			echo -e "${Info} 移除 ${deb_del} 核心移除完成，繼續..."
		done
		deb_total=`dpkg -l|grep linux-image | awk '{print $2}' | wc -l`
		if [[ "${deb_total}" = "1" ]]; then
			echo -e "${Info} 核心移除完畢，繼續..."
		else
			echo -e "${Error} 核心移除異常，請檢查 !" && exit 1
		fi
	else
		echo -e "${Info} 檢測到除剛安裝的核心以外已無多餘核心，跳過移除多餘核心步驟 !"
	fi
}
del_deb_over(){
	del_deb
	update-grub
	addsysctl
	echo -e "${Tip} 重啟VPS後，請執行腳本查看 BBR 是否正常載入，執行指令： ${Green_background_prefix} bash ${file}/bbr.sh status ${Font_color_suffix}"
	stty erase '^H' && read -p "需要重啟VPS後，才能開啟BBR，是否現在重啟 ? [Y/n] :" yn
	[[ -z "${yn}" ]] && yn="y"
	if [[ $yn == [Yy] ]]; then
		echo -e "${Info} VPS 重啟中..."
		reboot
	fi
}
# 安裝BBR
installbbr(){
	check_root
	get_latest_version
	deb_ver=`dpkg -l|grep linux-image | awk '{print $2}' | awk -F '-' '{print $3}' | grep '[4-9].[0-9]*.'`
	latest_version_2=$(echo "${latest_version}"|grep -o '\.'|wc -l)
	if [[ "${latest_version_2}" == "1" ]]; then
		latest_version="${latest_version}.0"
	fi
	if [[ "${deb_ver}" != "" ]]; then	
		if [[ "${deb_ver}" == "${latest_version}" ]]; then
			echo -e "${Info} 檢測到目前核心版本[${${deb_ver}}] 已是最新版本，無需繼續 !"
			deb_total=`dpkg -l|grep linux-image | awk '{print $2}' | grep -v "${latest_version}" | wc -l`
			if [[ "${deb_total}" != "0" ]]; then
				echo -e "${Info} 檢測到核心數量異常，存在多餘核心，開始刪除..."
				del_deb_over
			else
				exit 1
			fi
		else
			echo -e "${Info} 檢測到目前核心版本支援開啟BBR 但不是最新核心版本，開始升級(或降級)核心..."
		fi
	else
		echo -e "${Info} 檢測到目前核心版本不支援開啟BBR，開始..."
		virt=`virt-what`
		if [[ -z ${virt} ]]; then
			apt-get update && apt-get install virt-what -y
			virt=`virt-what`
		fi
		if [[ ${virt} == "openvz" ]]; then
			echo -e "${Error} BBR 不支援 OpenVZ 虛擬化(不支援更換核心) !" && exit 1
		fi
	fi
	echo "nameserver 8.8.8.8" > /etc/resolv.conf
	echo "nameserver 8.8.4.4" >> /etc/resolv.conf
	
	wget -O "${deb_kernel_name}" "${deb_kernel_url}"
	if [[ -s ${deb_kernel_name} ]]; then
		echo -e "${Info} 核心安裝包下載成功，開始安裝核心..."
		dpkg -i ${deb_kernel_name}
		rm -rf ${deb_kernel_name}
	else
		echo -e "${Error} 核心安裝包下載失敗，請檢查 !" && exit 1
	fi
	#判斷核心是否安裝成功
	deb_ver=`dpkg -l | grep linux-image | awk '{print $2}' | awk -F '-' '{print $3}' | grep "${latest_version}"`
	if [[ "${deb_ver}" != "" ]]; then
		echo -e "${Info} 檢測到核心安裝成功，開始移除其餘核心..."
		del_deb_over
	else
		echo -e "${Error} 檢測到核心安裝失敗，請檢查 !" && exit 1
	fi
}
bbrstatus(){
	check_bbr_status_on=`sysctl net.ipv4.tcp_congestion_control | awk '{print $3}'`
	if [[ "${check_bbr_status_on}" = "bbr" ]]; then
		echo -e "${Info} 檢測到 BBR 已開啟 !"
		# 檢查是否啟動BBR
		check_bbr_status_off=`lsmod | grep bbr`
		if [[ "${check_bbr_status_off}" = "" ]]; then
			echo -e "${Error} 檢測到 BBR 已開啟但未正常啟動，請嘗試使用低版本核心(可能是存著相容性問題，雖然核心設定中打開了BBR，但是核心載入BBR模組失敗) !"
		else
			echo -e "${Info} 檢測到 BBR 已開啟並已正常啟動 !"
		fi
		exit 1
	fi
}
addsysctl(){
	sed -i '/net\.core\.default_qdisc=fq/d' /etc/sysctl.conf
	sed -i '/net\.ipv4\.tcp_congestion_control=bbr/d' /etc/sysctl.conf
	
	echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
	echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
	sysctl -p
}
startbbr(){
	check_deb_off
	bbrstatus
	addsysctl
	sleep 1s
	bbrstatus
}
# 關閉BBR
stopbbr(){
	check_deb_off
	sed -i '/net\.core\.default_qdisc=fq/d' /etc/sysctl.conf
	sed -i '/net\.ipv4\.tcp_congestion_control=bbr/d' /etc/sysctl.conf
	sysctl -p
	sleep 1s
	
	stty erase '^H' && read -p "需要重啟VPS後，才能徹底停止BBR，是否現在重啟 ? [Y/n] :" yn
	[[ -z "${yn}" ]] && yn="y"
	if [[ $yn == [Yy] ]]; then
		echo -e "${Info} VPS 重啟中..."
		reboot
	fi
}
# 查看BBR狀態
statusbbr(){
	check_deb_off
	bbrstatus
	echo -e "${Error} BBR 未開啟 !"
}
check_sys
[[ ${release} != "debian" ]] && [[ ${release} != "ubuntu" ]] && echo -e "${Error} 本腳本不支援目前系統 ${release} !" && exit 1
action=$1
[[ -z $1 ]] && action=install
case "$action" in
	install|start|stop|status)
	${action}bbr
	;;
	*)
	echo "輸入錯誤 !"
	echo "用法: { install | start | stop | status }"
	;;
esac
