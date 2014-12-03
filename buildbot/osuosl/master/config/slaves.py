import buildbot
import buildbot.buildslave
import os

import config

def create_slave(name, *args, **kwargs):
    password = 'e'
    return buildbot.buildslave.BuildSlave(name, password=password, *args, **kwargs)

def get_build_slaves():
    return [
        # parkas bots 
        # Each is a:
        # 8 x Intel(R) Xeon(R) CPU E5430  @ 2.66GHz, Debian x86_64 GNU/Linux
        create_slave("parkas1_bot_ether", properties={'jobs': 8}, max_builds=1),

        create_slave("parkas2", properties={'jobs': 8}, max_builds=1),

        create_slave("parkas3", properties={'jobs': 8}, max_builds=1) 
    ]
