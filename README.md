# Estudos e testes em Terraform
## Subindo uma KVM com Terraform

### Glossário
- KVM
    Kernel-based Virtual Machine
- libvirt
    API open-source de virtualização, tendo também daemon e ferramenta para gerenciamento de plataforma de virtualização. Pode ser usado com variadas tecnologias de virtualização.
- QEMU
    É o hypervisor que usaremos para rodar as máquinas virtuais. É um software que implementa um emulador de processador, permitindo virtualização de um sistema dentro do PC.

### Sobre KVM com libvirt
Primeiro é preciso verificar se o hardware do computador suporta as extensões para virtualização
        ```kvm-ok```
Feito isso, instale os pacotes:
```
sudo apt update
sudo apt install qemu-kvm libvirt-daemon-system
```
Esses são os pacotes relacionados ao hypervisor QEMU e à API libvirt

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
    virsh pool-indefine [nome]
    ```


    




[Página de manuais](https://libvirt.org/manpages/index.html)    |
    [Virtualização com libvirt](https://ubuntu.com/server/docs/virtualization-libvirt)