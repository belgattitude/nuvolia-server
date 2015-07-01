# nuvolia-server
Bash scripts to generate debian packages with latest PHP,


## Requirements

- Ubuntu 14.04+ 64 bits
- Build environnement

## Prepare your system

Ensure installation of build essentials and ruby for fpm package management.

```shell
sudo apt-get install build-essential autoconf bison lemon g++ re2c flex clang ruby ruby-dev shtool libtool git
```

Optionally install the latest ruby version.

```shell
sudo apt-add-repository ppa:brightbox/ruby-ng
sudo apt-get update
sudo apt-get install ruby1.9.1 ruby1.9.1-dev ruby2.2 ruby2.2-dev ruby-switch
sudo ruby-switch --set ruby2.2
```

Install FPM (not php-fpm) for easy package management

```shell
sudo gem install fpm
```


## Install php server


```shell
./create_php_fpm_package.sh
```

Will create an archive

```shell
sudo dpkg -i nuvolia-server-php_5.6.10-trusty1_amd64.deb
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
