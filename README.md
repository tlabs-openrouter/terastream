# Introduction

WARNING: the code in this repository and these instructions are
work-in-progress and *do* contain serious bugs! Only use if you know exactly
what you are doing!

This repository contains work-in-progress experimental packages intended to use
an OpenWrt/LEDE router with Deutsche Telekom's Terastream network.

# How to use

## Compilation

This assumes a fresh LEDE checkout.

- add "src-git terastream https://github.com/tlabs-openrouter/terastream.git;lede" to feeds.conf
- enable the packages feeds in feeds.conf
- run "scripts/feeds update -a", "scripts/feeds install -a"

Configure as usual, select "terastream" package (in Telekom packages) and its dependencies.
Unselect "dnsmasq" in "Base Packages", keep "dnsmasq-full".

## Configuration

Configure networking on device in /etc/config/network:

- add "list ip6class '5f414e59'" to lan
- remove default wan block
- add these wan interface blocks (change eth<X> to the devices wan interface)

    config interface 'wan'
            option proto 'terastream'
            option ifname 'eth<X>'
            option accept_ra '1'
            option request_pd '3'
            option aftr_v4_local '192.0.0.2'
            option aftr_v4_remote '192.0.0.1'
            option request_na '0'
            option reqopts '21,23,31,56,64,67,88,96,99,123,198,199'

    config interface 'wan_ds'

    config interface 'wan4'



