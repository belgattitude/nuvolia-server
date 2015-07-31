# Nuvolia server factory

Produce ready-to-install deb packages for latest php on debian/ubuntu.

Heavily rely on Vagrant and puppet for automatic preparation of system boxes, used for compilation and tests.


## Requirements

- Ubuntu 14.04+ 64 bits
- Vagrant/Virtualbox


## Install php server

For ubuntu/trusty64

```shell
cd <my_install_dir>
https://github.com/belgattitude/nuvolia-server.git
cd ./nuvolia-server/vagrant/trusty64_build_box
vagrant up
vagrant provision 
vagrant ssh -c "/shared/install/build_libxl_package.sh"
vagrant ssh -c "/shared/install/build_php_package.sh"
vagrant ssh -c "/shared/install/build_php_ext_libxl_package.sh"

# Alternatively, all components can be build with
vagrant ssh -c "/shared/install/build_all.sh"


```

If no error, the generated builds are generated on the host in the 'builds' directory.

To install

```shell
cd ./builds
sudo dpkg -i nuvolia-server-<version>.deb
```


