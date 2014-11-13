#!/bin/sh

handler="/tmp/firewall-hotplug/${INTERFACE}.sh"
[ -x "$handler" ] && "$handler"

