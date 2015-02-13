# auto sync with this file, DO NOT SYNC ON CORP COMPUTERS.
# CHECK WHERE IT GOES.
# wget 


# hex replace in binary , http://everydaywithlinux.blogspot.com/2012/11/patch-strings-in-binary-files-with-sed.html
function binsed(){ # unfinished.
hexdump -ve '1/1 "%.2X"' file.bin | \
sed "s/<pattern>/<replacement>/g" | \
xxd -r -p > file.bin.patched
}
