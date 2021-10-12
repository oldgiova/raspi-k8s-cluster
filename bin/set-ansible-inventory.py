# author: roberto.giova@gmail.com
# description: update ansible inventory host


import sys, configparser

ini_file = '/etc/ansible/hosts'
ini_section = sys.argv[1]
ini_key = sys.argv[1]

config = configparser.ConfigParser(allow_no_value=True)
config.read(ini_file)
config.set(ini_section, ini_key)

with open(ini_file, 'w') as configfile:
    config.write(configfile)