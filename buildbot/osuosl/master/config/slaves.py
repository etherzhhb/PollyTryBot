import buildbot
import buildbot.buildslave
import os

import config

def create_slave(name, *args, **kwargs):
    password = config.options.get('Slave Passwords', name)
    return buildbot.buildslave.BuildSlave(name, password=password, *args, **kwargs)

def get_build_slaves():
    return [
        # gcc farm bots, for light weight regression test only
        # gcc10: 2x12x1.5 GHz AMD Opteron Magny-Cours / 64 GB RAM / Supermicro AS-1022G-BTF / Debian x86-64
        create_slave("gcc10", properties={'jobs': 24}, max_builds=1),

        # gcc14: 2x4x3.0 GHz Intel Xeon X5450 / 16GB RAM / Dell Poweredge 1950 / Debian x86-64
        create_slave("gcc14", properties={'jobs': 8}, max_builds=1),

        # gcc16: 2x4x2.2 GHz AMD Opteron 8354 (Barcelona B3) / 16 GB RAM / Debian x86-64
        create_slave("gcc16", properties={'jobs': 8}, max_builds=1),

        # gcc20: 2x6x2.93 GHz Intel Dual Xeon X5670 2.93 GHz 12 cores 24 threads / 24 GB RAM / Debian amd64
        create_slave("gcc20", properties={'jobs': 12}, max_builds=1),
        
        # parkas bots 
        # Each is a:
        # 8 x Intel(R) Xeon(R) CPU E5430  @ 2.66GHz, Debian x86_64 GNU/Linux
        create_slave("parkas1", properties={'jobs': 8}, max_builds=1),

        create_slave("parkas2", properties={'jobs': 8}, max_builds=1),

        create_slave("parkas3", properties={'jobs': 8}, max_builds=1) 
    ]
