#!/bin/bash

echo kamcmd Commands

sudo kamcmd ?
sudo kamcmd core.info
sudo kamcmd core.aliases_list
sudo kamcmd psx

echo kamctl Commands

kamctl domain add mack.com
mysql kamailio -e "select * from domain"
kamctl 

