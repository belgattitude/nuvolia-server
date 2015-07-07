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
vagrant ssh -c "/shared/install/build_php_package.sh"
```

If no error, the generated builds are generated on the host in the 'builds' directory.

To install

```shell
cd ./builds
sudo dpkg -i nuvolia-server-<version>.deb
```

Benchmarks with cclang

php_bin_size: 14.497.170 
test suite: 44.75Mb
- 7.83 secs 
- 6.71 
- 6.42
- 6.42
- 6.31

with gcc
php_bin_size: 15.037.470
test_suite: - 44.75 Mb
- 6.69 secs
- 6.29
- 6.57
- 6.41
- 6.26
