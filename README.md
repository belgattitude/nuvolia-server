# Nuvolia server

> **NO LONGER MAINTAINED**, use [the ondrej/ppa repo](https://launchpad.net/~ondrej/+archive/ubuntu/php) instead.
> PHP 5.6 soon to be EOL'd.

> For the geeks, the various shell scripts present in this repo can give 
> nice examples for to create debian packages with [fpm](https://github.com/jordansissel/fpm). 

Produce ready-to-install deb packages for custom PHP install (php-fpm, php-cli, libxl) 
on debian/ubuntu with vagrant/puppet and a lot of bash scripting. MIT licensed.

## Requirements

- Linux 64 bits
- Vagrant and Virtualbox

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

*Packages will be installed in `/opt/nuvolia`.*

## Usage

### Service

```shell
sudo service nuvolia-phpfpm restart
```

### Configuration

WIP

## License

MIT License

