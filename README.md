# Experiment on how to create php debs.

Produce ready-to-install deb packages for latest php on debian/ubuntu with vagrant/puppet and a lot of bash scripting.

> **Warning** Don't use it ;) **it's an experiment and prefer [the ondrej/ppa repo](https://launchpad.net/~ondrej/+archive/ubuntu/php)
> if you need to install different versions of php on Ubuntu/Debian. Some examples might reveal useful, check the sources and make your own idea. 


## Requirements

- Ubuntu 14.04+, 16.04+ 64 bits
- Vagrant/Virtualbox

## Clone the project

```shell
$ git clone https://github.com/belgattitude/nuvolia-server.git
```

## Build a the debs

For ubuntu/trusty64

```shell
$ cd ./nuvolia-server/vagrant/trusty64_build_box
$ vagrant up
$ vagrant provision 
$ vagrant ssh -c "/shared/install/build_libxl_package.sh"
$ vagrant ssh -c "/shared/install/build_php_package.sh"
$ vagrant ssh -c "/shared/install/build_php_ext_libxl_package.sh"

# Alternatively, all components can be build with
$ vagrant ssh -c "/shared/install/build_all.sh"
```

If no error, the generated builds are generated on the host in the `builds/trusty` directory.

## Install

To install

```shell
$ cd ./builds
$ sudo dpkg -i nuvolia-server-<version>.deb
```

