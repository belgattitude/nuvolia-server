# nuvolia-server
Bash scripts to generate debian packages with latest PHP,


## Requirements

- Ubuntu 14.04+ 64 bits
- Build environnement

## System preparation

Ensure installation of build essentials and ruby for fpm package management.

```shell
sudo apt-get install build-essential autoconf ruby ruby-dev gcc bison lemon g++ re2c flex shtool libtool ruby git
```
Highly recommend upgrading default ruby interpreter:

```shell
sudo apt-add-repository ppa:brightbox/ruby-ng
sudo apt-get update
sudo apt-get install ruby1.9.1 ruby1.9.1-dev ruby2.2 ruby2.2-dev ruby-switch
sudo ruby-switch --set ruby2.2
```


Install FPM (not php-fpm) for easy package management

```shell

sudo gem install compass sass jekyll fpm

```


