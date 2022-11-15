## Passo a passo do tutorial

Link: [Terraform and Libvirt](https://www.youtube.com/watch?v=MdeJn1k2b8Y)

Verificar se a virtualização está implementada corretamente
Mostra quantos processadores estão disponíveis: `egrep -c '(svm|vmx)' /proc/cpuinfo`

Instalar pacotes:
`sudo apt install virt-top libguestfs-tools virt-manager`
