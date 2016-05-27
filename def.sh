#!/bin/bash

iex --name def@192.168.8.104 -pa _build/dev/lib/distro/ebin/ --app distro --erl "-config config/def"
