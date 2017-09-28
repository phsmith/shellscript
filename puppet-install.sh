#!/bin/bash

# Exportando variáveis de proxy
export http_proxy=http://10.1.0.99:5865
export https_proxy=${http_proxy}

# Definindo a ranger como servidor puppet no /etc/hosts
[ $(grep -c '10.1.3.143.*puppet' /etc/hosts) -eq 0 ] && echo '10.1.3.143  puppet puppetserver' >> /etc/hosts

# Verificando versão do sistema operacional
if [ -f '/etc/redhat-release' ]; then
    os_version=$(sed -nr 's/.* ([0-9]).*/\1/p' /etc/redhat-release)
    
    # Baixando repositório do puppet e instalando o agente
    [ $(grep -c "proxy=" /etc/yum.conf) -eq 0 ] && sed -i "12 a proxy=http://bravo:3142" /etc/yum.conf
    rpm -ivh https://yum.puppetlabs.com/puppetlabs-release-pc1-el-${os_version}.noarch.rpm
    yum -y install puppet-agent || exit 1
    
    /opt/puppetlabs/bin/puppet resource service puppet ensure=running enable=true
    /opt/puppetlabs/bin/puppet agent --test
else
    os_version=$(lsb_release -rs)
    os_version_name=$(lsb_release -cs)

    # Baixando repositório do puppet e instalando o agente
    cd /tmp && wget https://apt.puppetlabs.com/puppetlabs-release-pc1-${os_version_name}.deb
    dpkg -i puppetlabs-release-pc1-${os_version_name}.deb
    apt-get update
    apt-get -y install puppet-agent || exit 1
    
    sed 's/START=no/START=yes/' /etc/default/puppet
    /opt/puppetlabs/bin/puppet agent --test
    service puppet start
fi


echo -e "\nApós assinar o certificado na RANGER, forçar a execução do agente novamente (como root):\n/opt/puppetlabs/bin/puppet agent --test\n"
