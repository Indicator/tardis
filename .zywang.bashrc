# Auto sync with this file, DO NOT SYNC ON CORP COMPUTERS.
# Load with the following commands in .bash_profile.
# TODO: Add user check for shared account. Load the profile if session client is zywang.
# if [[ $TERM != "screen" ]] ; then 
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

get_screen_pid(){
  pstree -p $$|grep -o -P 'screen\(.*?\)'|sed -e 's/screen(\|)//g'
}

get_screen_session_name(){
  if [[ $# -gt 0 ]]; then
    ps -o cmd="" -f -p $1 | awk '{print $NF}'
  fi
}

SCREEN_WINDOW=$(get_screen_session_name $(get_screen_pid))-$WINDOW


custom_prompt(){
# host color prompt
#color_list="\e[1;32m" "\e[1;33m" "\e[1;34m" "\e[1;35m" "\e[1;36m" "\e[1;37m"
#line_style_list="=" "-" "+"

case "$TERM" in
xterm*|rxvt*)
    PROMPT_COMMAND='echo -ne "\033]0;${USER}@${HOSTNAME}: ${PWD}\007"'
    ;;
*)
    ;;
esac
if [[ $TERM=="screen" ]] ; then 
PS_main="-------------------------------------------------------------$WINDOW"
fi
HOST=`hostname` 
case $HOST in
*Rosus*)
PS1="\e[1;34m====RISE AND RISE AGAIN, UNTIL LAMB BECOME LION=====================\e[0m[\t]\n\u@\h:\w$ "
;;
*gouda*)
PS1="\e[1;36m====================================================================\e[0m[\t]\n\u@\h:\w$ "
;;
*beagle*)
PS1="\e[1;35m====================================================================\e[0m[\t]\n\u@\h:\w$ "
;;
*midway*)
PS1="\e[1;32m====================================================================\e[0m[\t]\n\u@\h:\w$ "
;;
*)
PS1="\e[1;33m$PS_main\e[0m[\t]\n\u@\h:\w$ "
esac

export PS1

}

function cd(){
if [[ $# -ge 1 ]]; then pushd $@ ; else pushd $HOME ; fi
}

configure_command_history(){

  export HISTCONTROL=ignoredups:erasedups
  export HISTSIZE=100000
  export HISTFILESIZE=1000000
  shopt -s histappend
  export PROMPT_COMMAND="history -a ; history -c; history -r; $PROMPT_COMMAND"
}

configure_emacs(){
if [[ $(hostname) == "cruncher.ttic.edu" ]] ; then 
EMACS_DIR=/home/zywang/program/emacs-24.4/usr/local/ \
EMACSDATA=/home/zywang/program/emacs-24.4/usr/local/share/emacs/24.4/etc \
alias emacs="EMACSLOADPATH=/home/zywang/program/emacs-24.4/usr/local/share/emacs/24.4/lisp /home/zywang/program/emacs-24.4/usr/local/bin/emacs -nw"

fi

alias emacsclient="emacsclient -nw"
if [[ $TERM == "screen" ]] ; then
  alias emacsclient='TERM=xterm emacsclinet -nw'
fi
}

function emacsserver(){
  if [ $# -gt 0 ] ; then
    emacs -q --eval "(progn (load \"~/.emacs\") (setq server-name \"$1\") (server-start))" --daemon
  else
    echo "eamcsserver <server name> "
  fi
}

function emacslight(){
emacs -nw -q $@
}


configure_alias(){
ssh_parameter=' -o TCPKeepAlive=no -o ServerAliveInterval=7 '
alias gitok='git commit -m "ok" -a'

alias rb='sudo /etc/init.d/bluetooth restart'
alias sshlonghorn='ssh zywang@tg-login.longhorn.tacc.teragrid.org'
alias sshabe='ssh  zywang2@honest2.ncsa.uiuc.edu'
alias ssho='ssh zywang@engage-submit.renci.org'
alias sshc='ssh zywang@cruncher.ttic.edu -L 5901:localhost:5901 ${ssh_parameter}'
alias sshbigred='ssh tg-zywang@login.bigred.iu.teragrid.org' 
alias sshcondor='ssh zywang@tg-condor.purdue.teragrid.org' 
alias sshrx='ssh zywang@raptorx.uchicago.edu'
alias sshrx2='ssh RaptorX@raptorx2.uchicago.edu'
alias sshg="ssh zywang@gouda.uchicago.edu -X -C -c blowfish"
alias sshfg="sshfs -o uid=1000 -o gid=1000 -o workaround=rename -o follow_symlinks zywang@gouda.uchicago.edu: /home/wzy/remote/gouda"
alias sshfb="sshfs -o uid=1000 -o gid=1000 -o workaround=rename -o follow_symlinks zywang@login.beagle.ci.uchicago.edu: /home/wzy/remote/beagle"
alias ssh2="ssh fzhao@saw.sharcnet.ca"
alias ssh3="sshfs fzhao@saw.sharcnet.ca:/work/fzhao/zywang /home/wzy/sharchome"
alias sshr="ssh zywang@tg-login.ranger.tacc.teragrid.org"
alias sshp="ssh zywang@login.pads.ci.uchicago.edu"
alias sshvfs="sshfs -o workaround=rename zywang@velociraptor.tti-c.org: /home/wzy/vrhome"
alias lr='ls -lrt'
alias lt='ls -lrt|tail'
alias ll='ls -l'
alias la='ls -A'
alias l='ls -CF'
alias sshb="ssh zywang@login.beagle.ci.uchicago.edu"
alias matlabbio=/share/apps/matlab.bio/bin/matlab
alias getctrls='stty -ixon -ixoff'
alias getecho='stty echo'
alias qsubi="qsub -q ccm_queue -I -l mppwidth=24 -l walltime=0:0:30:0"

}

configure_key_bind(){
#key-bind for some hosts
bind '"\e[1;5D": backward-word'
bind '"\e[1;5C": forward-word'
}

configure_path(){
# TODO: clean the path, some are broken on beagle.
# environment path

export sshx=" -Y -C -c blowfish"

export svndir="https://bleu.uchicago.edu/svn/zywang/"
export PATH=$HOME/program/emacs-24.4/usr/local/bin/:$PATH
export PATH=$PATH:/home/wzy/bin/modeller9.9/bin:/share/apps/matlab.bio/bin/:~/work/sdcp/bin/
export PATH=$PATH:~/program/cuda/bin/
export PATH=$PATH:/export/apps/matlab/bin
export PYTHONPATH=/home/zywang/pre-install-packages:/home/zywang/pre-install-packages/lib64:/home/zywang/pre-install-packages/lib64/python2.4/site-packages/:/home/zywang/program/modeller/modlib:/home/zywang/program/modeller/lib/x86_64-intel8
export PYTHONPATH=/home/zywang/pre-install-packages:/home/zywang/pre-install-packages/lib64:/home/zywang/pre-install-packages/lib64/python2.4/site-packages/:/home/zywang/program/modeller/modlib:/home/zywang/program/modeller/lib/x86_64-intel8
export LD_LIBRARY_PATH=/opt/gridengine/lib/lx26-amd64:/opt/openmpi/lib:/home/zywang/program/modeller/lib/x86_64-intel8:/home/zywang/work/sdcp/src/BALL-1.2/lib/Linux-x86_64-g++_4.1.2/
LD_LIBRARY_PATH=/opt/gridengine/lib/lx26-amd64:/opt/openmpi/lib:/home/zywang/program/modeller/lib/x86_64-intel8:/home/zywang/work/sdcp/src/BALL-1.2/lib/Linux-x86_64-g++_4.1.2/:/share/apps/gcc/4.7.3/lib64/

export PATH=$PATH:~/work/admodeller/bin:~/work/epmi/bin/
export PATH=$PATH:/share/apps/matlab/bin/:/home/zywang/perl5/bin:/usr/java/latest/bin:/share/apps/matlab/bin/:/home/zywang/perl5/bin:/usr/java/latest/bin:/home/zywang/perl5/bin:/opt/openmpi/bin:/usr/kerberos/bin:/usr/java/latest/bin:/usr/local/bin:/bin:/usr/bin:/opt/bio/ncbi/bin:/opt/bio/mpiblast/bin/:/opt/bio/hmmer/bin:/opt/bio/EMBOSS/bin:/opt/bio/clustalw/bin:/opt/bio/tcoffee/bin:/opt/bio/phylip/exe:/opt/bio/mrbayes:/opt/bio/fasta:/opt/bio/glimmer/bin://opt/bio/glimmer/scripts:/opt/bio/gromacs/bin:/opt/bio/gmap/bin:/opt/bio/tigr/bin:/opt/bio/autodocksuite/bin:/opt/bio/wgs/bin:/opt/ganglia/bin:/opt/ganglia/sbin:/opt/rocks/bin:/opt/rocks/sbin:/opt/gridengine/bin/lx26-amd64:/home/wzy/bin/modeller9.9/bin:/home/zywang/program/cuda/bin/:/home/zywang/work/sdcp/bin/:/home/zywang/bin:/tmp/zywang_py/parallel/src:/opt/bio/ncbi/bin:/opt/bio/mpiblast/bin/:/opt/bio/hmmer/bin:/opt/bio/EMBOSS/bin:/opt/bio/clustalw/bin:/opt/bio/tcoffee/bin:/opt/bio/phylip/exe:/opt/bio/mrbayes:/opt/bio/fasta:/opt/bio/glimmer/bin://opt/bio/glimmer/scripts:/opt/bio/gromacs/bin:/opt/bio/gmap/bin:/opt/bio/tigr/bin:/opt/bio/autodocksuite/bin:/opt/bio/wgs/bin:/opt/eclipse:/opt/ganglia/bin:/opt/ganglia/sbin:/opt/maven/bin:/opt/pdsh/bin:/opt/rocks/bin:/opt/rocks/sbin:/opt/gridengine/bin/lx26-amd64:/home/wzy/bin/modeller9.9/bin:/home/zywang/program/cuda/bin/:/home/zywang/work/sdcp/bin/:/home/zywang/program/hdf5-1.8.10-linux-x86_64-shared/bin:/home/zywang/parallel/src:/home/zywang/work/dpln/bin/:/home/zywang/bin:/opt/bio/ncbi/bin:/opt/bio/mpiblast/bin/:/opt/bio/hmmer/bin:/opt/bio/EMBOSS/bin:/opt/bio/clustalw/bin:/opt/bio/tcoffee/bin:/opt/bio/phylip/exe:/opt/bio/mrbayes:/opt/bio/fasta:/opt/bio/glimmer/bin://opt/bio/glimmer/scripts:/opt/bio/gromacs/bin:/opt/bio/gmap/bin:/opt/bio/tigr/bin:/opt/bio/autodocksuite/bin:/opt/bio/wgs/bin:/opt/eclipse:/opt/ganglia/bin:/opt/ganglia/sbin:/opt/maven/bin:/opt/pdsh/bin:/opt/rocks/bin:/opt/rocks/sbin:/opt/gridengine/bin/lx26-amd64:/home/wzy/bin/modeller9.9/bin:/home/zywang/program/cuda/bin/:/home/zywang/work/sdcp/bin/:/home/zywang/program/hdf5-1.8.10-linux-x86_64-shared/bin:/home/zywang/parallel/src:/home/zywang/work/dpln/bin/:/home/zywang/program/bin:/home/zywang/program/bin
export PERL_MM_USE_DEFAULT=1

}

# Start the mongodb
function start_daemon(){
	echo "start mongodb"
	~/program/mongodb-linux-x86_64-2.6.3/bin/mongod --auth --dbpath ~/work/data/ &> mongdb.log & 
	echo "start dropbox"
	~/.dropbox-dist/dropboxd &> dropbox.log &
	# (cd ~/program/abyssws ; ./abyssws &> ~/abyssws.log &  )
	echo "start vnc"
	vncserver -geometry 1400x900
}

function move_backup(){
	for i in $@ ; do 
		mv $i $i.bak
	done
}
function foriincat(){
_listfile=$1
shift
for i in $(cat $_listfile) ; do
cmd=$(echo $@ |replace "\$i" $i)
$cmd
done
}

function get_node(){
node=all.q@compute-0-4
if [ $@ -gt 0 ] ; then 
	node=$1
fi
SGE_JSV_TIMEOUT=2000; 
qlogin -q $node -N .simple 
}

function configure_gnome_terminal(){
css='
##TABACTIVE## Do not delete this line.
TerminalWindow .notebook tab:active {
    background-color: #6699FF;
}
'
if [[ ! -e ~/.config/gtk-3.0/gtk.css || $(grep TABACTIVE ~/.config/gtk-3.0/gtk.css) == "" ]] ; then
echo -e "$css" >> ~/.config/gtk-3.0/gtk.css 
fi

}

function configure_git(){
alias gitok='git commit -a -m "ok" '
if [[ $( grep '\[alias\]' ~/.gitconfig ) == "" ]] ; then

git_aliases="
[alias]
	ci = commit
	br = branch
	co = checkout
	di = diff --color
	do = diff --name-only
"

echo -e "${git_aliases}" >> ~/.gitconfig
fi



}

### Main part. 

custom_prompt
configure_command_history
configure_emacs
configure_alias
configure_key_bind
configure_gnome_terminal
configure_git
