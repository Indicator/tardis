# Auto sync with this file, DO NOT SYNC ON CORP COMPUTERS.
# Load with the following commands in .bash_profile.
# TODO: Add user check for shared account. Load the profile if session client is zywang.
# if [ "$SSH_TTY" ] ; then 
# (mkdir -p ~/tardis ; cd ~/tardis/ ; git init ; git pull git@github.com:Indicator/tardis.git master)
# . ~/tardis/.zywang.bashrc ; 
# fi
# CHECK WHERE IT GOES.
# 
#

# hex replace in binary , http://everydaywithlinux.blogspot.com/2012/11/patch-strings-in-binary-files-with-sed.html
function binsed(){ # unfinished.
hexdump -ve '1/1 "%.2X"' file.bin | \
sed "s/<pattern>/<replacement>/g" | \
xxd -r -p > file.bin.patched
}
