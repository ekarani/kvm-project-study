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

[Página de manuais](https://libvirt.org/manpages/index.html)    |
    [Virtualização com libvirt](https://ubuntu.com/server/docs/virtualization-libvirt)

Ao longo do deploy do KVM com terraform, há esses outros comandos virsh que serão necessários:
- Listar redes virtuais
```
virsh net-list
```

- Listar IPs de uma rede
```
virsh net-dhcp-leases [nome da rede]
```

- Listar pools criadas


