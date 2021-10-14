# author: roberto.giova@gmail.com
# description: update ansible inventory host


import sys, configparser, os

ini_file = os.environ.get('INI_FILE_PATH') or '/etc/ansible/hosts'
try:
    ini_section = sys.argv[1]
except IndexError:
    ini_section = os.environ.get('INI_SECTION') or 'controlplanes'

try:
    ini_key = sys.argv[2]
except IndexError:
    ini_key = os.environ.get('INI_KEY') or 'cp1'


config = configparser.ConfigParser(allow_no_value=True)
try:
    config.read(ini_file)
except NameError as e:
    print("ERROR - exception occurred: %s".format(e))
    sys.exit(1)

config.set(ini_section, ini_key)

with open(ini_file, 'w') as configfile:
    config.write(configfile)

sys.exit(0)