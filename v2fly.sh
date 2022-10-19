#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#=================================================
#	System Required: Debian 6+/Ubuntu 14.04+
#	Description: Install the v2ray server
#	Version: 1.0.0.1
#	Author: 77-QiQi
#	GitHub: https://github.com/77-QiQi/
#=================================================

sh_ver="1.0.0.1"
Compose_ver="v2.12.0"
PWD="/root"
folder="$PWD/docker-v2fly"
config_folder="$folder/data"
config_file="$folder/view_info.conf"
uuid="$(cat /proc/sys/kernel/random/uuid)"
Green_font_prefix="\033[32m"
Red_font_prefix="\033[31m"
Green_background_prefix="\033[42;37m"
Red_background_prefix="\033[41;37m"
Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[信息]${Font_color_suffix}"
Error="${Red_font_prefix}[错误]${Font_color_suffix}"
Tip="${Green_font_prefix}[注意]${Font_color_suffix}"

check_root(){
	[[ $EUID != 0 ]] && echo -e "${Error} 当前账号非ROOT(或没有ROOT权限)，无法继续操作，请使用${Green_background_prefix} sudo su ${Font_color_suffix}来获取临时ROOT权限（执行后会提示输入当前账号的密码）。" && return 1
}
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
	bit=`uname -m`
}
Installation_dependency(){
	echo -e "${Info} 开始创建必要文件..."
	mkdir -p $config_folder/conf
	mkdir -p $config_folder/v2ray
	mkdir -p $config_folder/nginx/conf.d
	mkdir -p $config_folder/nginx/html
	curl https://raw.githubusercontent.com/77-QiQi/docker-v2fly/main/data/conf/config.json -o $config_folder/conf/config.json
	curl https://raw.githubusercontent.com/77-QiQi/docker-v2fly/main/data/conf/docker-compose.yml -o $config_folder/conf/docker-compose.yml
	curl https://raw.githubusercontent.com/77-QiQi/docker-v2fly/main/data/conf/info.conf -o $config_folder/conf/info.conf
	curl https://raw.githubusercontent.com/77-QiQi/docker-v2fly/main/data/conf/nginx.conf -o $config_folder/conf/nginx.conf
	curl https://raw.githubusercontent.com/77-QiQi/docker-v2fly/main/data/conf/index.html -o $config_folder/conf/index.html
	cp $config_folder/conf/index.html $config_folder/nginx/html/index.html
	echo -e "${Info} 开始下载/安装 docker..."
	curl -fsSL https://get.docker.com -o get-docker.sh
	sh get-docker.sh && rm -f get-docker.sh
	echo -e "${Info} 开始下载/安装 docker-compose..."
	curl -SL https://github.com/docker/compose/releases/download/${Compose_ver}/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
	chmod +x /usr/local/bin/docker-compose
	docker-compose -v
	return 0
}
Install_v2fly(){
	check_root
	[[ -e ${config_file} ]] && echo -e "${Error} v2fly 配置文件已存在，请检查( 如安装失败或者存在旧版本，请先卸载 ) !" && return 1
	if ! [ -x "$(command -v docker-compose)" ]; then
	  echo -e "${Error}: docker-compose is not installed." >&2
	  return 1
	fi
	echo -e "${Info} 开始设置 v2fly 配置..."
	read -r -p "请输入域名(eg:www.domain.com):" domains
	if [ -z $domains ];then
	    echo -e "${Error} 没有输入域名，已终止..." && return 0
	fi
	read -e -p "请输入端口号(默认: 443):" ports
	[[ -z ${ports} ]] && ports="443"
	if [[ $ports == "22" || $ports == "25" || $ports == "80" ]]; then
	    echo
	    echo -e "${Error} 端口不能为 22,25,80 ..." && return 0
	fi
	read -r -p "请输入路径(eg:v2ray):" paths
	if [ -z $paths ];then
	    echo -e "${Error} 没有输入路径，已终止..." && return 0
	else
	    case $paths in
	    *[/$]*)
	    echo
	    echo -e "${Error} 这个脚本太辣鸡了...所以路径不能包含 / 或 $ 这两个符号..."
	    echo "----------------------------------------------------------------"
	    return 0
	    ;;
	    esac
	fi
	read -r -p "请输入邮箱(eg:your@address.email):" email
	if [ -z $email ];then
	    echo -e "${Info} 没有输入邮箱..." && email="unknown" && read -s -n1 -p "将自动跳过邮箱，按任意键继续..."
		else
		mail=`echo $email | gawk '/^([a-zA-Z0-9_\-\.\+]+)@([a-zA-Z0-9_\-\.]+)\.([a-zA-Z]{2,5})$/{print $0}'`
		if [ ! -n "${mail}" ];then
		echo -e "${Info} 输入了不合法的邮箱，将自动跳过 ..." && email="unknown"
		fi
	fi
	echo
	if [ $email != "unknown" ]; then
	  	read -e -p "是否将邮箱地址与 EFF 共享？(默认:No):" yn
	  	[[ -z "${yn}" ]] && yn="n"
		if [[ $yn == [Yy] ]]; then
		echo -e "${Info} 已同意与 EFF 共享邮箱地址，将会收到 EFF 推送的新闻、活动等资讯..."
		share_email_address="yes"
	  else
	  	echo && echo -e "${Info} 已拒绝与 EFF 共享邮箱地址，将不会收到 EFF 推送的新闻、活动等资讯..."
		share_email_address="no"
		fi
	  fi
	echo
	read -s -n1 -p "UUID已自动生成，按任意键继续..."

	rm -f $folder/info.conf && cp $config_folder/conf/info.conf $folder/info.conf
	rm -f $folder/docker-compose.yml && cp $config_folder/conf/docker-compose.yml $folder/docker-compose.yml
	rm -f $config_folder/v2ray/config.json && cp $config_folder/conf/config.json $config_folder/v2ray/config.json
	rm -f $config_folder/nginx/conf.d/nginx.conf && cp $config_folder/conf/nginx.conf $config_folder/nginx/conf.d/nginx.conf
	sed -i "s/your_domain/${domains}/" $folder/info.conf
	sed -i "3s/your_ports/${ports}/" $folder/info.conf
	sed -i "6s/v2ray/${paths}/" $folder/info.conf
	sed -i "4s/your_uuid/${uuid}/" $folder/info.conf
	sed -i "10s/your_email_address/${email}/" $folder/info.conf
	sed -i "11s/no/${share_email_address}/" $folder/info.conf
	sed -i "15s/your_uuid/${uuid}/" $config_folder/v2ray/config.json
	sed -i "24s/v2ray/${paths}/" $config_folder/v2ray/config.json
#	sed -i "/"id"/c\            '"id"': '"${uuid}"'," $config_folder/v2ray/config.json
#	sed -i "/"path"/c\          '"path"': '"${paths}"'" $config_folder/v2ray/config.json
#	sed -i '15,24s/'"'"/'"''/g' $config_folder/v2ray/config.json
	sed -i "33s/v2ray/${paths}/" $config_folder/nginx/conf.d/nginx.conf
	sed -i "s/your_domain/${domains}/" $config_folder/nginx/conf.d/nginx.conf
	sed -i "16s/your_ports/${ports}/" $folder/docker-compose.yml

	touch $folder/check_info.conf
	# ------------------------------
	# 配置信息
	# ------------------------------
	echo "====================================="  >> $folder/check_info.conf
	echo "V2ray 配置信息"  >> $folder/check_info.conf
	echo "地址（address）：${domains}"  >> $folder/check_info.conf
	echo "端口（port）：${ports}"  >> $folder/check_info.conf
	echo "用户id（UUID）：${uuid}"  >> $folder/check_info.conf
	echo "额外id（alterId）：0"  >> $folder/check_info.conf
	echo "加密方式（security）：auto"  >> $folder/check_info.conf
	echo "传输协议（network）：ws"  >> $folder/check_info.conf
	echo "伪装类型（type）：none"  >> $folder/check_info.conf
	echo "路径（path）：/${paths}"  >> $folder/check_info.conf
	echo "底层传输安全：TLS"  >> $folder/check_info.conf
	echo "====================================="  >> $folder/check_info.conf


	mv $folder/check_info.conf $folder/view_info.conf

	echo
	echo -e "${Info} 开始安装 v2fly..."
	Install_tls
	return 0
}
Install_tls(){
	if ! [ -x "$(command -v docker-compose)" ]; then
	  echo -e "${Error}: docker-compose is not installed." >&2
	  return 1
	fi
	cd $folder
	source $folder/info.conf
	data_path="$config_folder/certbot"

	if [ -d "$data_path" ]; then
	  read -e -p "正在更新: $domains 的证书！是否继续？[y/N] :" yn
	  [[ -z "${yn}" ]] && yn="n"
	  if [[ $yn == [Yy] ]]; then
	  	echo -e "${Info} 开始更新..."
	  	docker-compose down
	  	rm -rf $config_folder/tls-old
	  	cp -r $config_folder/certbot $config_folder/tls-old
	  	rm -rf $config_folder/certbot
	  else
	  	echo && echo -e "${Info} 已取消..." && echo
	    return 0
	  fi
	fi

	if [ ! -e "$data_path/conf/options-ssl-nginx.conf" ] || [ ! -e "$data_path/conf/ssl-dhparams.pem" ]; then
	  echo -e "${Info} loading..."
	  mkdir -p "$data_path/conf"
	  curl -s https://raw.githubusercontent.com/77-QiQi/certbot/master/certbot-nginx/certbot_nginx/_internal/tls_configs/options-ssl-nginx.conf > "$data_path/conf/options-ssl-nginx.conf"
	  openssl dhparam -out "$data_path/conf/ssl-dhparams.pem" 2048
	  echo -e "${Info} ready..."
	fi

	echo -e "${Info} Creating dummy certificate for $domains ..."

	mv $config_folder/nginx/conf.d/nginx.conf $config_folder/nginx/conf.d/nginx.conf.bak
	touch $config_folder/nginx/conf.d/nginx.conf
	echo "server{" >> $config_folder/nginx/conf.d/nginx.conf
	echo "   listen 80;" >> $config_folder/nginx/conf.d/nginx.conf
	echo "   server_name $domains;" >> $config_folder/nginx/conf.d/nginx.conf
	echo "   location /.well-known/acme-challenge/ {" >> $config_folder/nginx/conf.d/nginx.conf
	echo "     root /var/www/certbot;"  >> $config_folder/nginx/conf.d/nginx.conf
	echo "   }"  >> $config_folder/nginx/conf.d/nginx.conf
	echo "   location / { "  >> $config_folder/nginx/conf.d/nginx.conf
	echo "       return 301 https://\$host\$request_uri;"  >> $config_folder/nginx/conf.d/nginx.conf
	echo "   }"   >> $config_folder/nginx/conf.d/nginx.conf
	echo "}" >> $config_folder/nginx/conf.d/nginx.conf

	path="/etc/letsencrypt/live/$domains"
	mkdir -p "$data_path/conf/live/$domains"
	docker-compose run --rm --entrypoint "\
	  openssl req -x509 -nodes -newkey rsa:2048 -days 1\
	    -keyout '$path/privkey.pem' \
	    -out '$path/fullchain.pem' \
	    -subj '/CN=localhost'" certbot
	echo

	echo -e "${Info} Starting nginx ..."
	docker-compose up --force-recreate -d nginx
	echo

	echo -e "${Info} Deleting dummy certificate for $domains ..."
	docker-compose run --rm --entrypoint "\
	  rm -Rf /etc/letsencrypt/live/$domains && \
	  rm -Rf /etc/letsencrypt/archive/$domains && \
	  rm -Rf /etc/letsencrypt/renewal/$domains.conf" certbot
	echo

	echo -e "${Info} Requesting Let's Encrypt certificate for $domains ..."
	#Join $domains to -d args
	domain_args=""
	for domain in "${domains[@]}"; do
	  domain_args="$domain_args -d $domain"
	done

	# Select appropriate email arg
	case "$email" in
	  "unknown") email_arg="--register-unsafely-without-email" ;;
	  *) email_arg="--email $email" ;;
	esac

	# Share your e-mail address with EFF (default: No)
	case "$share_email_address" in
	  "no") share_arg="--no-eff-email" ;;
	  *) share_arg="--eff-email" ;;
	esac

	# Enable staging mode if needed
	if [ $staging != "0" ]; then staging_arg="--staging"; fi

	docker-compose run --rm --entrypoint "\
	  certbot certonly --webroot -w /var/www/certbot \
	    $staging_arg \
	    $email_arg \
	    $share_arg \
	    $domain_args \
	    --rsa-key-size $rsa_key_size \
	    --agree-tos \
	    --force-renewal" certbot
	echo

	rm -f $config_folder/nginx/conf.d/nginx.conf
	mv $config_folder/nginx/conf.d/nginx.conf.bak $config_folder/nginx/conf.d/nginx.conf
	# docker-compose up --force-recreate -d nginx v2ray certbot
	echo -e "${Info} Reloading nginx ..."
	docker-compose exec nginx nginx -s reload
	echo -e "${Info} done..."
	cd ~
	return 0
}
Update_Service(){
	[[ ! -e ${config_file} ]] && echo -e "${Error} 没有安装 v2fly ，请检查 !" && return 1
	if ! [ -x "$(command -v docker-compose)" ]; then
	  echo -e "${Error}: docker-compose is not installed." >&2
	  return 1
	fi
	cd $folder
	docker-compose down
	docker-compose pull
	echo -e "${Info} 更新完成，重启中 ..."
	docker-compose up --force-recreate -d nginx v2ray
	echo -e "${Info} done..."
	cd ~
	return 0
}
Update_Setting(){
	[[ ! -e ${config_file} ]] && echo -e "${Error} 没有安装 v2fly ，请检查 !" && return 1
	if ! [ -x "$(command -v docker-compose)" ]; then
	  echo -e "${Error}: docker-compose is not installed." >&2
	  return 1
	fi
	source $folder/info.conf
	echo && echo -e "  你想修改什么？
————————
 ${Green_font_prefix}1.${Font_color_suffix} 修改 域名
————————
 ${Green_font_prefix}2.${Font_color_suffix} 修改 端口
————————
 ${Green_font_prefix}3.${Font_color_suffix} 修改 路径
————————
 ${Green_font_prefix}4.${Font_color_suffix} 修改 UUID
————————
 ${Green_font_prefix}5.${Font_color_suffix} 修改 邮箱" && echo
	read -e -p "(默认: 取消):" cancel
	[[ -z "${cancel}" ]] && echo -e "${Info}已取消..." && return 1
	if [[ ${cancel} == "1" ]]; then
		Domains_Setting
	elif [[ ${cancel} == "2" ]]; then
		Ports_Setting
	elif [[ ${cancel} == "3" ]]; then
		Paths_Setting
	elif [[ ${cancel} == "4" ]]; then
		uuid_Setting
	elif [[ ${cancel} == "5" ]]; then
		Email_Setting
	else
		echo -e "${Error} 请输入正确的数字(1-5)" && return 1
	fi
}
Domains_Setting(){
	read -r -p "请输入域名(当前域名:${domains}):" new_domains
		if [ -z $new_domains ];then
	    echo -e "${Error} 没有输入域名，已取消修改..." && return 0
		fi
	sed -i "s/${domains}/${new_domains}/" $folder/info.conf
	sed -i "s/${domains}/${new_domains}/" $config_folder/nginx/conf.d/nginx.conf
	sed -i "3s/${domains}/${new_domains}/" $folder/view_info.conf
	rm -rf $config_folder/certbot
	Install_tls
	return 0
}
Ports_Setting(){
	read -r -p "请输入端口号(当前默认端口:${ports}):" new_ports
		if [ -z $new_ports ];then
		echo -e "${Error} 没有输入端口，已取消修改..." && return 0
		fi
		if [[ $new_ports == "22" || $new_ports == "25" || $new_ports == "80" ]]; then
		echo
		echo -e "${Error} 端口不能为 22,25,80 ..." && return 0
		fi
	sed -i "3s/${ports}/${new_ports}/" $folder/info.conf
	sed -i "16s/${ports}/${new_ports}/" $folder/docker-compose.yml
	sed -i "4s/${ports}/${new_ports}/" $folder/view_info.conf
	cd $folder
	docker-compose up --force-recreate -d nginx v2ray
	cd ~
	return 0
}
Paths_Setting(){
	read -r -p "请输入路径(当前路径:${paths}):" new_paths
		if [ -z $new_paths ];then
	    echo -e "${Error} 没有输入路径，已取消修改..." && return 0
		fi
		case $new_paths in
	    *[/$]*)
	    echo
	    echo -e "${Error} 这个脚本太辣鸡了...所以路径不能包含 / 或 $ 这两个符号..."
	    echo "----------------------------------------------------------------"
	    return 0
	    ;;
	    esac
	sed -i "6s/${paths}/${new_paths}/" $folder/info.conf
	sed -i "24s/${paths}/${new_paths}/" $config_folder/v2ray/config.json
	sed -i "33s/${paths}/${new_paths}/" $config_folder/nginx/conf.d/nginx.conf
	sed -i "10s/${paths}/${new_paths}/" $folder/view_info.conf
	cd $folder
	docker-compose up --force-recreate -d nginx v2ray
	cd ~
	return 0
}
uuid_Setting(){
	read -e -p "确认修改UUID？[y/N] :" yn
	  [[ -z "${yn}" ]] && yn="n"
	  if [[ $yn == [Yy] ]]; then
	  	new_uuid="$(cat /proc/sys/kernel/random/uuid)"
	  	echo
	  	read -s -n1 -p "UUID已自动生成，按任意键继续..."
		echo
	  else
		echo && echo -e "${Info} 默认不修改UUID" && return 0
	  fi
	sed -i "4s/${uuid}/${new_uuid}/" $folder/info.conf
	sed -i "5s/${uuid}/${new_uuid}/" $folder/view_info.conf
	sed -i "15s/${uuid}/${new_uuid}/" $config_folder/v2ray/config.json
	cd $folder
	docker-compose up --force-recreate -d nginx v2ray
	cd ~
	return 0
}
Email_Setting(){
	read -r -p "请输入邮箱(当前邮箱:${email}):" new_email
		if [ -z $new_email ];then
	    echo -e "${Info} 没有输入邮箱..." && return 0
		else
		mail=`echo $new_email | gawk '/^([a-zA-Z0-9_\-\.\+]+)@([a-zA-Z0-9_\-\.]+)\.([a-zA-Z]{2,5})$/{print $0}'`
		if [ ! -n "${mail}" ];then
		echo -e "${Info} 输入了不合法的邮箱，邮箱未修改成功 ..." && return 0
		fi
		fi
	read -e -p "是否将邮箱地址与 EFF 共享？(默认:No):" yn
	  [[ -z "${yn}" ]] && yn="n"
	  if [[ $yn == [Yy] ]]; then
	  	echo -e "${Info} 已同意与 EFF 共享邮箱地址，将会收到 EFF 推送的新闻、活动等资讯(申请/续订证书后生效) ..."
	  	share_email="yes"
	  else
	  	echo && echo -e "${Info} 已拒绝与 EFF 共享邮箱地址，将不会收到 EFF 推送的新闻、活动等资讯(申请/续订证书后生效) ..."
		share_email="no"
	  fi
	sed -i "11s/${share_email_address}/${share_email}/" $folder/info.conf
	sed -i "10s/${email}/${new_email}/" $folder/info.conf
	echo -e "${Info} 修改完成 ..."
	return 0
}
Uninstall_v2fly(){
	[[ ! -e ${config_folder} ]] && [[ ! -e ${config_file} ]] && echo -e "${Error} 没有安装 v2fly ，请检查 !" && return 1
	echo "确定要 卸载 v2fly ？[y/N]" && echo
	read -e -p "(默认: n):" uninstall
	[[ -z ${uninstall} ]] && uninstall="n"
	if [[ ${uninstall} == [Yy] ]]; then
		if ! [ -x "$(command -v docker-compose)" ]; then
		  echo -e "${Error}: docker-compose is not installed." >&2
		  return 1
		fi
		cd $folder
		echo -e "${Info} 移除容器..."
		docker-compose down
		echo -e "${Info} done..."
		rm -rf ${folder}
		echo -e "${Info} 开始移除 compose..."
		rm -rf /usr/local/bin/docker-compose
		echo -e "${Info} 开始移除 docker..."
		apt-get purge docker-ce docker-ce-cli containerd.io docker-compose-plugin -y
		rm -rf /var/lib/docker
		rm -rf /var/lib/containerd
		echo && echo -e "${Info} 卸载已完成 !" && echo
		cd ~
		echo -e "${Tip} 将于10秒后重启"
		sleep 10s && reboot
	else
		echo && echo -e "${Info} 卸载已取消..." && echo
	fi
}
Stop_v2fly(){
	[[ ! -e ${config_file} ]] && echo -e "${Error} 没有安装 v2fly ，请检查 !" && return 1
	if ! [ -x "$(command -v docker-compose)" ]; then
	  echo -e "${Error}: docker-compose is not installed." >&2
	  return 1
	fi
	echo -e "${Info} 停止容器..."
	docker stop nginx v2ray
	echo -e "${Info} done..."
	return 0
}
Restart_v2fly(){
	[[ ! -e ${config_file} ]] && echo -e "${Error} 没有安装 v2fly ，请检查 !" && return 1
	if ! [ -x "$(command -v docker-compose)" ]; then
	  echo -e "${Error}: docker-compose is not installed." >&2
	  return 1
	fi
	echo -e "${Info} 重启容器..."
	docker restart nginx v2ray
	echo -e "${Info} done..."
	return 0
}
View_connection_info(){
	[[ ! -e ${config_file} ]] && echo -e "${Error} v2fly 配置文件不存在，请检查 !" && return 1
	cat $folder/view_info.conf
	return 0
}
Renewals_v2fly(){
	[[ ! -e ${config_file} ]] && echo -e "${Error} 没有安装 v2fly ，请检查 !" && return 1
	Install_tls
	return 0
}
Reset_v2fly(){
	[[ ! -e ${config_folder} ]] && [[ ! -e ${config_file} ]] && echo -e "${Error} 没有安装 v2fly ，请检查 !" && return 1
	echo "确定要 初始化 v2fly ？[y/N]" && echo
	read -e -p "(默认: n):" reset
	[[ -z ${reset} ]] && reset="n"
	if [[ ${reset} == [Yy] ]]; then
		if ! [ -x "$(command -v docker-compose)" ]; then
		  echo -e "${Error}: docker-compose is not installed." >&2
		  return 1
		fi
		cd $folder
		echo -e "${Info} 移除容器..."
		docker-compose down
		echo -e "${Info} done..."
		rm -f ${config_file}
		rm -rf $folder/logs
		rm -rf $config_folder/v2ray/*
		rm -rf $config_folder/nginx/conf.d/*
		rm -rf $config_folder/certbot
		rm -rf $config_folder/tls-old
		rm -f $folder/docker-compose.yml
		rm -f $folder/info.conf
		echo && echo -e "${Info} 初始化已完成 !" && echo
		cd ~
		echo -e "${Tip} 请等待5秒..."
		sleep 5s && return 0
	else
		echo && echo -e "${Info} 初始化已取消..." && echo
	fi
}
# BBR
Configure_BBR(){
	echo && echo -e "  你要做什么？

 ${Green_font_prefix}1.${Font_color_suffix} 查看 BBR 状态
————————
 ${Green_font_prefix}2.${Font_color_suffix} 启用 BBR" && echo
echo -e "${Red_font_prefix} [开启前，请注意] ${Font_color_suffix}
1. 本脚本仅支持 Debian / Ubuntu 系统
2. 查看 BBR 状态若有返回 tcp_bbr 则已启用 BBR
3. 启用 BBR 需系统内核支持，本脚本不更换内核，不存在更换失败等风险(重启后无法开机)" && echo
	read -e -p "(默认: 取消):" bbr_num
	[[ -z "${bbr_num}" ]] && echo -e "${Info}已取消..." && return 1
	if [[ ${bbr_num} == "1" ]]; then
		BBR_Status
	elif [[ ${bbr_num} == "2" ]]; then
		Start_BBR
	else
		echo -e "${Error} 请输入正确的数字(1-2)" && return 1
	fi
}
BBR_Status(){
	[[ ${release} = "centos" ]] && echo -e "${Error} 本脚本不支持 CentOS系统安装 BBR !" && return 1
	lsmod | grep bbr
}
Start_BBR(){
	echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
	echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
	sysctl -p
	lsmod | grep bbr
}
Update_Compose(){
	[[ ! -e ${config_file} ]] && echo -e "${Error} 没有安装 v2fly ，请检查 !" && return 1
	if ! [ -x "$(command -v docker-compose)" ]; then
	  echo -e "${Error}: docker-compose is not installed." >&2
	  return 1
	fi
	cd $folder
	echo -e "${Info} 移除容器......"
	docker-compose down
	echo -e "${Info} 开始移除 docker-compose..."
	rm -rf /usr/local/bin/docker-compose
	echo -e "${Info} 开始下载/安装 docker-compose..."
	curl -SL https://github.com/docker/compose/releases/download/${Compose_ver}/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
	chmod +x /usr/local/bin/docker-compose
	docker-compose -v
	echo -e "${Info}docker-compose 已更新，重启中 ..."
	docker-compose up --force-recreate -d nginx v2ray
	echo -e "${Info} done..."
	cd ~
	return 0
}
Update_Shell(){
	curl https://raw.githubusercontent.com/77-QiQi/docker-v2fly/main/v2fly.sh -o v2fly.sh && chmod +x v2fly.sh && echo -e "${Info} 更新完成 ..."
	source v2fly.sh
}

check_sys
[[ ${release} != "debian" ]] && [[ ${release} != "ubuntu" ]] && [[ ${release} = "centos" ]] && echo -e "${Error} 本脚本不支持当前系统 ${release} !" && return 1
check_root
echo -e "  v2ray 一键管理脚本 ${Red_font_prefix}[v${sh_ver}]${Font_color_suffix}
  ---- 77-QiQi | github.com/77-QiQi ----

  ${Green_font_prefix}0.${Font_color_suffix} 安装 依赖
  ${Green_font_prefix}1.${Font_color_suffix} 安装 v2fly
  ${Green_font_prefix}2.${Font_color_suffix} 更新 v2fly
  ${Green_font_prefix}3.${Font_color_suffix} 卸载 v2fly
————————————
  ${Green_font_prefix}4.${Font_color_suffix} 查看 连接信息
  ${Green_font_prefix}5.${Font_color_suffix} 修改 连接信息
  ${Green_font_prefix}6.${Font_color_suffix} 续订 TLS证书
————————————
  ${Green_font_prefix}7.${Font_color_suffix} 停止 v2fly
  ${Green_font_prefix}8.${Font_color_suffix} 重启 v2fly
————————————
  ${Green_font_prefix}9.${Font_color_suffix} BBR 状态
 ${Green_font_prefix}10.${Font_color_suffix} 更新 compose
————————————
 ${Green_font_prefix}11.${Font_color_suffix} 初始化 ...
 ${Green_font_prefix}12.${Font_color_suffix} 升级脚本 ...
 "
echo -e "${Red_font_prefix} [注意：首次安装及卸载重装，请先执行安装依赖！] ${Font_color_suffix}"
echo -e "${Red_font_prefix} [注意：初始化，将恢复至 v2fly 安装之前(依赖安装之后)的状态！] ${Font_color_suffix}"
echo && read -e -p "请输入数字 [0-12]：" num
case "$num" in
	0)
	Installation_dependency
	;;
	1)
	Install_v2fly
	;;
	2)
	Update_Service
	;;
	3)
	Uninstall_v2fly
	;;
	4)
	View_connection_info
	;;
	5)
	Update_Setting
	;;
	6)
	Renewals_v2fly
	;;
	7)
	Stop_v2fly
	;;
	8)
	Restart_v2fly
	;;
	9)
	Configure_BBR
	;;
	10)
	Update_Compose
	;;
	11)
	Reset_v2fly
	;;
	12)
	Update_Shell
	;;
	*)
	echo -e "${Error} 请输入正确的数字 [0-12]"
	;;
esac
