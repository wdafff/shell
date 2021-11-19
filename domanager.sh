red="\033[31m"
black="\033[0m"

#====================================================#
#	System Request:Ubuntu 18.04+/Centos 7+	     #
#	Author:	wdafff				     #
#	Dscription: do cli shell manager	     #
#	Version: 1.0				     #
#	email: wdafff@gmail.com			     #
#====================================================#

echo '欢迎使用DOCTL命令行管理' 

if type doctl >/dev/null 2>&1; then 
    echo "当前用户:"
    echo ""
    doctl account get
    echo ""
else 
    echo '请先安装DOCTL' 
fi

#查询所有VM
do-vm-list(){
    doctl compute droplet ls --format ID,Name,PublicIPv4,Memory,VCPUs,Disk,Region,Status
}
#管理VM
do-vm-manager(){
    do-vm-list
    echo  -e "${red}当前位置【管理DO】,请选择（请输入数字）？Ctrl+C 退出本脚本${black}"
    select todo in 开机 关机 重启 删除 重命名 返回
    do
        case $todo in
        开机)
            doid=$(echo `keep_user_input "请输入ID"`)
            doctl compute droplet-action power-on $doid
            do-vm-manager
            ;;
        关机)
            doid=$(echo `keep_user_input "请输入ID"`)
            doctl compute droplet-action power-off $doid
            do-vm-manager
            ;;
        重启)
            doid=$(echo `keep_user_input "请输入ID"`)
            doctl compute droplet-action reboot $doid
            do-vm-manager
            ;; 
        重命名)
            doid=$(echo `keep_user_input "请输入ID"`)
            donewname=$(echo `keep_user_input "请输入新名字"`)
            doctl compute droplet-action rename $doid --droplet-name $donewname
            do-vm-manager
            ;;
        修改密码)
            doid=$(echo `keep_user_input "请输入ID"`)
            doctl compute droplet-action password-reset $doid
            echo -e "${red}请查看邮箱，会有一封带有密码的邮件${black}"
            do-vm-manager
            ;;              
        返回)
            main
            ;;       
        *)
            echo "如果要退出，请按Ctrl+C"
            ;;
        esac
    done
}


#管理SSH-KEY
do-ssh-key-manager(){
    do-list-ssh-key
    echo  -e "${red}当前位置【管理SSH-KEY】,请选择（请输入数字）？Ctrl+C 退出本脚本${black}"
    select todo in 查看 新建 导入 删除 返回
    do
        case $todo in
        查看)
            doctl compute ssh-key list
            do-ssh-key-manager
            ;;
        新建)
            sshkeyname=$(echo `keep_user_input "请输入SSH-KEY名称"`)
            sshkeycont=$(echo `keep_user_input "请输入SSH-KEY Public-Key文本内容"`)
            doctl compute ssh-key create $sshkeyname --public-key "$sshkeycont"
            do-ssh-key-manager
            ;;
        导入)
            sshkeyname=$(echo `keep_user_input "将会导入本机的[/root/.ssh/id_rsa.pub],没有对应文件将会自动生成,请输入SSH-KEY名称"`)
            file=/root/.ssh/id_rsa.pub
            if [ ! -f "$file" ]; then
                ssh-keygen -t rsa -N '' -f id_rsa -q
            fi
            doctl compute ssh-key import  $sshkeyname --public-key-file $file
            do-ssh-key-manager
            ;; 
        删除)
            sshkeyid=$(echo `keep_user_input "请输入SSH-KEY ID"`)
            doctl compute ssh-key delete $sshkeyid
            do-ssh-key-manager
            ;;             
        返回)
            main
            ;;       
        *)
            echo "如果要退出，请按Ctrl+C"
            ;;
        esac
    done
}

#查看SSH-KEY
do-list-ssh-key(){
    echo ""
    echo -e "${red}SSH-KEY：${black}"
    doctl compute ssh-key list    
}

#查看地区
do-list-location(){
    echo ""
    echo -e "${red}地区：${black}"
    doctl compute region list
}
#查询实例类型
do-vm-list-sizes(){
    echo ""
    echo -e "${red}实例：${black}"
    doctl compute size list
}
#查看镜像
do-vm-image-list(){
    echo ""
    echo -e "${red}镜像：${black}"
    doctl compute image list --public --format Name,Slug,MinDisk | grep 'centos\|ubuntu\|debian\|Slug'
}
#删除VM
do-vm-delete(){
    do-vm-list
    doid=$(echo `keep_user_input "请输入需要删除的ID"`)
    doctl compute droplet delete $doid
}
keep_user_input(){
    info=$1
    read -rp "$info:" input
    while [[ -z ${input} ]]
    do
        keep_user_input $info
    done
    echo $input
}
#创建VM
do-vm-create(){

    read -p "仅支持通过秘钥SSH-KEY方式创建机器，请确认账户中是否存在(Y/N): " go_create
    [[ -z ${go_create} ]] && go_create="Y"
    case $go_create in
    [yY][eE][sS]|[yY])
        ;;
    *)
        do-ssh-key-manager
        ;;
    esac

    vmname=$(echo `keep_user_input "请输入VM名称"`)

    doctl compute region list
    read -rp "请选择地区location（Default: nyc1）:" location
    [[ -z ${location} ]] && location="nyc1"
    echo -e "${red}你选择了【$location】${black}。"

    do-vm-list-sizes
    read -rp "请选择实例类型size（Default: s-1vcpu-1gb）:" size
    [[ -z ${size} ]] && size="s-1vcpu-1gb"
    echo -e "${red}你选择了【$size】。${black}"

    do-vm-image-list
    read -rp "请选择镜像image（Default: ubuntu-20-04-x64）:" image
    [[ -z ${image} ]] && image="ubuntu-20-04-x64"
    echo -e "${red}你选择了【$image】。${black}"

    echo -e "${red}SSH-KEY：${black}"
    doctl compute ssh-key list
    sshid=$(echo `keep_user_input "请输入SSH-KEY ID"`)

    printf "%-10s %-10s\n" vmname: $vmname
    printf "%-10s %-10s\n" size: $size
    printf "%-10s %-10s\n" image: $image
    printf "%-10s %-10s\n" location: $location
    printf "%-10s %-10s\n" sshid: $sshid

    read -p "请确认实例信息(Y/N): " go_create
    [[ -z ${go_create} ]] && go_create="Y"
    case $go_create in
    [yY][eE][sS]|[yY])
        echo -e "${GreenBG} 开始创建VM... ${black}"
        sleep 1
        doctl compute droplet create --image $image --size $size --region $location  --ssh-keys $sshid --format Name,Memory,VCPUs,Disk,Image,Status  $vmname
        ;;
    *)
        echo -e "${RedBG} 终止创建... ${black}"
        break
        ;;
    esac
}

main(){
echo  -e "${red}当前位置【主菜单】,请选择（请输入数字）？Ctrl+C 退出本脚本${black}"
select todo in 创建DOVM 查看DOVM 管理DOVM 删除DOVM 管理SSH-KEY 查看积分余额 查看历史账单 安装DOCTL
do
	case $todo in
    创建DOVM)
		do-vm-create
		main
        ;;
    查看DOVM)
		do-vm-list
		main
        ;;
    管理DOVM)
		do-vm-manager
		main
        ;;    
    删除DOVM)
        do-vm-delete
		main
        ;;
    管理SSH-KEY)
        do-ssh-key-manager
		main
        ;; 
    查看积分余额)
        doctl balance get
		main
        ;;
    查看历史账单)
        doctl billing-history list --format Date,Description,Amount
		main
        ;;              	
    安装DOCTL)
        if type doctl >/dev/null 2>&1; then 
        echo 'DOCTL已经安装过。' 
        else 
        echo '开始安装。' 
        cd ~
        wget https://github.com/digitalocean/doctl/releases/download/v1.66.0/doctl-1.66.0-linux-amd64.tar.gz
        tar xf ~/doctl-1.66.0-linux-amd64.tar.gz
        sudo mv ~/doctl /usr/local/bin
        echo '安装完成，请按提示输入Token' 
        doctl auth init
        fi
        ;;
    *)
        echo "如果要退出，请按Ctrl+C"
        ;;
    esac
done
}

main
