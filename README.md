# Vagrant multi-machine environment

Config file driven multi-machine environment with NAT network and static IP addresses. Uses Hyper-V on Windows, Libvirt on Ubuntu and VirtualBox on MacOS.

Based on the original work found [here](https://github.com/to-bar/vagrant-hyperv-multi-vm-env) and [here](https://github.com/seriva/vm-cluster).

## Requirements

### Windows

- Windows Hyper-V [enabled](https://docs.microsoft.com/en-us/virtualization/hyper-v-on-windows/quick-start/enable-hyper-v)
- [Vagrant](https://www.vagrantup.com/downloads.html) (tested with v2.2.18)

### MacOS

- Virtualbox: `brew install virtualbox`
- Vagrant: `brew install vagrant`
- Vagrant Manager: `brew install vagrant-manager`

### Ubuntu

- Ubuntu with [libvirt](https://ubuntu.com/server/docs/virtualization-libvirt)
- [Vagrant](https://www.vagrantup.com/downloads.html) (tested with v2.2.18)
- Vagrant [libvirt provider](https://github.com/vagrant-libvirt/vagrant-libvirt)

*Other Linux distros should work but are untested.*

## Installation

```shell
git clone --depth=1 https://github.com/epiphany-platform/vagrant-multi-vm-env.git
```

## Usage

1. Open command prompt as administrator
2. Go to project's directory

    Windows (Hyper-V):

    ```shell
    cd vagrant-multi-vm-env/hyperv
    ```

    Ubuntu (Libvirt):

    ```shell
    cd vagrant-multi-vm-env/libvirt
    ```

    MacOS (VirtualBox):

    ```shell
    cd vagrant-multi-vm-env/virtualbox
    ```

3. Edit `config.yml` file
4. Run Vagrant

    - Create environment

        ```shell
        vagrant up
        ```

    - Stop environment

        ```shell
        vagrant halt
        ```

    - Destroy environment (append `-f` to destroy without confirmation)

        ```shell
        vagrant destroy
        ```

    - Create snapshot of entire environment

        ```shell
        vagrant snapshot save <snapshot-name>
        ```

    - Create snapshot of single machine

        ```shell
        vagrant snapshot save <vm-name> <snapshot-name>
        ```

    - Restore environment from snapshot

        ```shell
        vagrant snapshot restore <snapshot-name>
        ```

    - List snapshots

        ```shell
        vagrant snapshot list
        ```

    - Remove snapshot

        ```shell
        vagrant snapshot delete <snapshot-name>
        ```

5. Connect to VM

    - Using SSH client

        ```shell
        ssh vagrant@<vm-ip>
        ```

    - Using Vagrant

        ```shell
        vagrant ssh [options] [name|id] [-- extra ssh args]
        ```

## Supported boxes

This project was tested with the following boxes:

- almalinux/8
- centos/7
- generic/rhel7
- generic/rhel8
- generic/rocky8
- generic/ubuntu1804
- generic/ubuntu2004
