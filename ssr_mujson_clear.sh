#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#=================================================
#	System Required: CentOS 6+/Debian 7+/Ubuntu 14.04+
#	Description: ShadowsocksR mujson mode traffic clear script
#	Version: 1.0.1
#	Author: Toyo
#=================================================
SSR_file="/usr/local/shadowsocksr"
# 這裡填寫 mujson_mgr.py 檔案的上層絕對路徑
Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Font_color_suffix="\033[0m" && Info="${Green_font_prefix}[訊息]${Font_color_suffix}" && Error="${Red_font_prefix}[錯誤]${Font_color_suffix}" && Tip="${Green_font_prefix}[注意]${Font_color_suffix}"
check_ssr(){
	[[ ! -e ${SSR_file} ]] && echo -e "${Error} mujson_mgr.py 檔案不存在或變數設定錯誤 !" && exit 1
}
scan_port(){
	cd "${SSR_file}"
	port_all=$(python "mujson_mgr.py" -l)
	[[ -z ${port_all} ]] && echo -e "${Error} 沒有發現任何埠(使用者) !" && exit 1
	port_num=$(echo "${port_all}"|wc -l)
	[[ ${port_num} = 0 ]] && echo -e "${Error} 沒有發現任何埠(使用者) !" && exit 1
}
clear_traffic(){
	for((integer = 1; integer <= ${port_num}; integer++))
	do
		port=$(echo -e "${port_all}"|sed -n "${integer}p"|awk '{print $NF}')
		[[ -z ${port} ]] && echo -e "${Error} 獲取的埠(使用者)為空 !" && exit 1
		result=$(python "mujson_mgr.py" -c -p "${port}")
		echo -e "${Info} 埠[${port}] 流量已清零 !"
	done
	echo -e "${Info} 所有埠(使用者)流量已清零 !"
}
c_ssr(){
	check_ssr
	scan_port
	clear_traffic
}
action=$1
[[ -z $1 ]] && action=c
case "$action" in
    c)
    ${action}_ssr
    ;;
    *)
    echo -e "輸入錯誤 !
 用法: c 清空 所有使用者已使用流量"
    ;;
esac
