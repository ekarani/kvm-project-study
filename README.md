# Subindo KVM com Terraform
## Passo a Passo
1. ```
   sudo apt update
   sudo apt install qemu-kvm libvirt-daemon-system
   ```
2. ```
   sudo systemctl start libvirtd
   sudo systemctl enable libvirtd
   sudo systemctl status libvirtd
   ```
3. ```
   sudo terraform init
   sudo terraform apply
   ```
   
### Glossário
- **KVM:**
    Kernel-based Virtual Machine
- **libvirt:**
    API open-source de virtualização, tendo também daemon e ferramenta para gerenciamento de plataforma de virtualização. Pode ser usado com variadas tecnologias de virtualização.
- **QEMU:**
    É o hypervisor que usaremos para rodar as máquinas virtuais. É um software que implementa um emulador de processador, permitindo virtualização de um sistema dentro do PC.
- **Terraform:**
    Ferramenta open-source de Infrastructure as Code (IAC) que possibilita a criação, mudança e melhoramento de infraestrutura. Com ela, é possível provisionar infraestrutura com códigos em linguagem declarativa e de fácil compreensão.

## Sobre KVM com libvirt
Primeiro é preciso verificar se o hardware do computador suporta as extensões para virtualização
        ```
        kvm-ok
        ```
Feito isso, instale os pacotes:
```
sudo apt update
sudo apt install qemu-kvm libvirt-daemon-system
```
Esses são os pacotes relacionados ao hypervisor QEMU e à API libvirt.
Também vale a pena checar se o daemon do libvirt está rodando.
```
sudo systemctl start libvirtd
sudo systemctl enable libvirtd
sudo systemctl status libvirtd
```
E habilitar o módulo kernel do vhost-net
```
sudo modprobe vhost_net
echo vhost_net | sudo tee -a /etc/modules
```

#### Virtual Machine Managenment
Vish é uma ferramenta de linha de comando que permite o gerenciamento de máquinas virtuais.

- Para listar VMs
```
virsh list
```
- Para iniciar, iniciar automaticamente após o boot e reiniciar uma VM, respectivamente
```
virsh [start/autostart/reboot] [nome da vm]
```
Ao longo do deploy do KVM com terraform, há esses outros comandos virsh que serão necessários:
- virsh net
    - Listar redes virtuais
    ```
    virsh net-list
    ```
    - Listar IPs de uma rede
    ```
    virsh net-dhcp-leases [nome da rede]
    ```

- virsh pool
    O libvirt fornece gerenciamento de armazenamento num KVM por meio de armazenamento em pools e volumes.
    Armazenamento em pool, ou storage pool, é uma quantidade de armazenamento alocada ao host do KVM para uso da máquina virtual. O storage pool é dividido em volumes de armazenamento, ou storage volumes, e associados às VMs como dispositivos de bloco, tais como HD, CDs, DVDs, imagens ISO etc. Não é possível ter storage volumes sem um storage pool.

    No nosso contexto, definiremos um pool do tipo "directory pool", que é usado para hospedar arquivos de imagem, por exemplo. O formato de armazenamento que usaremos para esse directory pool é *qcow2* (QEMU copy-on-write 2).

    - Listar todos os pools existentes
    ```
    virsh pool-list
    ```
    - Expor detalhes de um determinado pool
    ```
    virsh pool-info [nome do pool]
    ```
    - Criar pool
    ```
    virsh pool-define-as --name [nome] --type dir --target [diretório destino]
    ```
    - Inicializar pool
    ```
    virsh pool-start [nome]
    ```
    - Indefinir e destruir pool
    ``` 
    virsh pool-destroy [nome]
    virsh pool-undefine [nome]
    ```

## Terraform
Terraform cria e gerencia recursos em diversos serviços e plataformas por meio de sua API. É com essa API e providers que é possível que Terraform interaja com quase qualquer plataforma ou serviço com API acessível.
### Conceitos importantes
- **Variáveis (variables)**: pares chave-valor
- **Provider**: plugin que interage com APIs de serviços e seus recursos
- **Module**: Diretório com templates Terraform contendo configurações definidas
- **State**: Consiste em informação em cache sobre a infraestrutura gerenciada por Terraform
- **Resources**: "Infrastrusture objects" (por exemplo: redes virtuais, instâncias de compute) que são usados na configuração e gerenciamento da infraestrutura.

### Lifecycle
1. `terraform init`

    Inicializa o diretório onde estão os arquivos de configuração. Havendo já definidos os providers nos arquivos .tf, o comando se encarrega de clonar as configurações necessárias para fazer uso dos resources referenciados pelos providers
    
2. `terraform plan`

    Pode ser opcional, mas é útil para criar o plano de execução que leve ao estado final desejado na infraestrutura. Ele aponta se está tudo certo nos arquivos de configuração antes de rodar.

3. `terraform apply`

    Implementa as modificações na infraestrutura especificadas nos arquivos de configuração.

4. `terraform destroy`

    É usado para deletar todos os recursos de infraesrtutura existentes, incluse para desfazer o que foi feito com o apply.

Para mais (e melhores) detalhes sobre Terraform para além do básico: [Learn Terraform: The Ultimate Terraform Tutorial](https://automateinfra.com/2022/01/14/learn-terraform-the-ultimate-terraform-tutorial-part-1/#what-is-terraform)


### Subindo KVM com Terraform
#### Instalando Terraform

Execute os comandos abaixo:
```
sudo apt-get update && sudo apt-get install -y gnupg software-properties-common curl
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install terraform
```
Para checar se a instalação do Terraform foi bem sucedida: `terraform -v`

#### Sobre o projeto terraform

Nesse projeto, usamos dois arquivos terraform (.tf) e dois arquivos de configuração.
Esses arquivos .tf poderiam ter sido reunidos num só arquivo, mas temos em mãos dois por fins de organização. Um arquivo, o *variables.tf* contém variáveis, entradas relacionadas à "customização". Essas variáveis são tamanho de memória, quantidade de vCPUs, número de máquinas virtuais a serem levantadas etc.
O arquivo *main.tf* é o arquivo com as principais configurações para o deploy com o terraform. Nele definimos quais os providers requeridos, que no nosso caso é o libvirt, e suas versões.

Agora, discutindo especificamente sobre o que é definido para um KVM nesse arquivo main.tf: todas essas definições são possíveis por meio de CLIs de ferramentas como libvirt e virsh, porém o propósito de aplicar tudas essas definições num arquivo terraform é para automatizar e agilizar o processo de levantar uma VM.
Referenciamos os arquivos de configuração da VM e da rede como "template_file" para em seguiga definirmos os elementos para o deploy da VM:
- libvirt_cloudinit

    Gerencia o disco ISO cloud-init.
    Cloud-init é um serviço automatiza a inicialização de instâncias em nuvem, assim como possibilita a customização de Sistemas Operacionais Linux na nuvem (para isso que também temos um arquivo de configuração *cloud-init.cfg*)
- libvirt_network

    Gerencia a rede virtual em libvirt. Essa rede pode ser qualquer rede virtual, não somente no contexto de KVM, mas também em contexto Kubernetes, por exemplo.
- libvirt_pool

    Gerencia o pool storage em libvirt.
- libvirt_volume

    Gerencia o volume storagem em libvirt.
- libvirt_domain

    Gerencia domínios em libvirt. Um domínio, no contexto do libvirt, é uma instância de VM.

### Últimos passos (finalmente)
Resumindo o que fazer para verificar se a VM subiu, se está rodando e acessível:
1. Verificar a lista de instâncias executando
    ```
    virsh list --all
    ```
2. Tentar acessar o console da VM
    Há duas maneiras para tal:
    1. Pelo `virsh console`
        Quando executamos `virsh list`, na lista é informado o id de cada instância de VM. Com esse id, executamos
        ```
        virsh console [id]
        ```
        Para termos acesso ao terminal da VM que levantamos.
    2. Por ssh
        Para isso, executamos primeiro
        ```
        virsh net-list 
        ```
        (Para o caso de não lembramos qual é o nome da rede virtual)
        No acesso via ssh, precisamos do IP da máquina. O seguinte comando irá nos informar isso:
        ```
        virsh net-dhcp-leases [nome da rede]
        ```

        Tendo o IP da máquina em mãos, basta executar:
        ```
        ssh -i [chave informada no cloud-init.cfg] [user]@[IP da máquina]
        ```

Esses são os procedimentos via linha de comando que permitem o acesso ao terminal da VM que subimos.
Alternativamente, há uma aplicação desktop desenvolvida pela Red Hat chamada Virtual Machine Manager ([virt-manager](https://virt-manager.org/))
    



### Referências
[Página de manuais](https://libvirt.org/manpages/index.html)    |
    [Virtualização com libvirt](https://ubuntu.com/server/docs/virtualization-libvirt)

[How to change kvm libvirt default storage location](https://ostechnix.com/how-to-change-kvm-libvirt-default-storage-pool-location/#:~:text=Libvirt%20provides%20storage%20management%20on%20a%20KVM%20host,and%20assigned%20to%20the%20VMs%20as%20block%20devices.)    |
    [How to provision VMs on KVM with terraform](https://computingforgeeks.com/how-to-provision-vms-on-kvm-with-terraform/)

[Terraform for beginners](https://geekflare.com/terraform-for-beginners/)   |
    [Libvirt Provider no Terraform Registry](https://registry.terraform.io/providers/dmacvicar/libvirt/latest/docs)
