__author__ = 'Zhiyong Wang\nToyota Technological Institute at Chicago\n zywang@ttic.edu \n 2014'

from subprocess import Popen, PIPE
import StringIO
import re
import time
import threading
import os


# This library provides a universal interface of several computing clusters in the
# community of Toyota Technological Institute at Chicago and the University of Chicago,
# such as Beagle, Cruncher, OpenScienceGrid.
# Midway, Gouda and other RCC machine will be included in the future.
# Change the username to yours
__module_username__="zywang"

# Every remote computer is assumed has SSH connect setup correctly without password, which means,
# > ssh gouda.uchicago.edu
# will connect your to gouda by authentication of public key without any input.


class Runnable(object):
    def __init__(self,cmd=""):
        # Assume: the program can be run in a local environment, with necessary library and package at the right relative path
        # Assume: copy these files are fast, normal for testing a model.
        # require executable, library, config files.
        # setup remote working path
        self.cmd=cmd
        self.executable=" "
        self.computer=ComputingHost()
        # if there samples for each run with run_id
        # sample input files, output_file(run_id), output_path(run_id)
    def get_cmd(self):
        return self.cmd
    def run(self,runlater=True,*args,**kwargs ):
        if runlater:
            cmd=self.get_run_string(*args,**kwargs) # construct a command line for run
            return self.computer.run_and_wait(cmd)
        else:
            return self.computer.run_and_wait(self,**kwargs)


class Sample(object):
    # This is more of a data type
    def __init__(self,sample_id):
        self.sample_id=sample_id

class ComputingHost(object): # The default localhost
    # input: command line , return stdout and stderr.
    def __init__(self,ncpu=3):
        self.ncpu=ncpu
        self.remote_pipe_string=None
        pass
    def try_connect(self,f,test=False):
        self.connect_cooldown.acquire()
        (stdout,stderr)=(0,0)
        for i in range(self.max_connect):
            (stdout,stderr)=f(0)
            if stderr==None or re.match("ssh:",stderr)==None:
                break
            #time.sleep(i*10+random.uniform(0,1))
            if not test:
                time.sleep(self.cooldown_time)
        print "cooldown %dsec" % self.cooldown_time
        time.sleep(self.cooldown_time)
        self.connect_cooldown.release()
        return (stdout,stderr)
    def run_and_wait(self,cmd, dryrun=False,return_full=False):
        # Can be overlapped by qsub_and_wait in local cruncher subclass
        if isinstance(cmd,str):
            cmd=Runnable(cmd)
        if dryrun :
            print cmd.get_cmd()
            return 0
        else:
            # Popen has a length limit to cmd,
            if return_full: # Wrong! communicate(cmd)[0] return the full of stdout, [1] return stderr
                return Popen(os.environ['SHELL'],shell=True,stdin=PIPE,stdout=PIPE).communicate(cmd.get_cmd())
            else:
                return Popen(os.environ['SHELL'],shell=True,stdin=PIPE,stdout=PIPE).communicate(cmd.get_cmd())[0]

    def runlocal_from_remote(self,cmd, dryrun=False,return_full=False):
        if dryrun :
            print cmd
            return 0
        else:
            if self.remote_pipe_string != None :
                shellstr="cat - | {pipe_string} -T ".format(pipe_string=self.remote_pipe_string)
            else:
                shellstr=os.environ['SHELL']
            res=Popen(shellstr,shell=True,stdin=PIPE,stdout=PIPE).communicate(cmd)[0]
        if not return_full:
            res=res[0]
        return res

    def runbatch_and_wait(self,cmd_list,run_list=list(),dryrun=False,ncpu=0):
        #input: a list of command lines, each return one line , return stdout
        # this function start a thread pool to run each command with size of ncpu
        # return list of output.

        # Convert it to Runnable list
        if isinstance(cmd_list[0],str):
            cmd_list = [ Runnable(cmd,computer=self) for cmd in cmd_list ]

        if ncpu==0:
            ncpu=self.ncpu

        if dryrun :
            print "\n".join(cmd_list)
            return
        import threading
        import time
        allthread=[]
        class MyThread(threading.Thread):
            def __init__(self,cmd, computer):
                super(MyThread, self).__init__()
                self.output=""
                self.computer=computer
                self.cmd=cmd
            def run(self):
                self.output=self.computer.run_and_wait(self.cmd)
            def join(self):
                super(MyThread, self).join()
                return self.output
        for i in range(len(cmd_list)):
            t=MyThread(cmd_list[i],self)
            allthread.append(t)
            t.start()
            while threading.activeCount() > ncpu :
                time.sleep(1)
        res=[]
        for t in allthread:
            t.join()
            res.append(t.output)
        return res

class LocalCruncher(ComputingHost):
    def __init__(self,cpu_per_node=30,node_address=""):
        self.remote_user="zywang"
        self.remote_host="localhost"
        self.ncpu=200
        self.cpu_per_node=cpu_per_node
        if node_address != "" :
            self.queue="#$ -q all.q@"+node_address
        else:
            self.queue=""

    def qsub_submit(self,cmd,qsub_cmd="cat - | qsub -sync y "):
        header="""
#$ -S /bin/bash
#$ -cwd
##$ -v OMPI_MCA_plm_rsh_disable_qrsh=1
{queue}
#$ -pe serial {cpu_per_node}
#$ -N SimpleParallel.qsub_and_wait
#$ -e  $HOME/work/qsub.log/qsub.e$JOB_ID
##              $JOB_NAME, $HOSTNAME, and $GE_TASK_ID
#$ -o  $HOME/work/qsub.log/qsub.o$JOB_ID
#$ -V
""".format(cpu_per_node=self.cpu_per_node,queue=self.queue)
        #print header+cmd
        #return
        output=Popen(qsub_cmd,shell=True,stdin=PIPE,stdout=PIPE).communicate(header+ ("\n echo '%s' \n" % cmd) +cmd)[0]
        buf = StringIO.StringIO(output)
        #print output
        jobid = re.split("\s+",buf.readline())[2]
        return jobid

    def qsub_check(self,jobid):
        cmd="qstat |tail -n +3 |cut -d' ' -f1|grep %s" % jobid
        #
        output=Popen(cmd,shell=True,stdout=PIPE).communicate()[0]
        return re.match(jobid,output)!=None and re.match(jobid,output).group(0)==jobid

    def qsub_and_wait(self,cmd,dryrun=False):
        # return : the first line in the stdout file
        jobid=self.qsub_submit(cmd,qsub_cmd="cat - | qsub ")
        #> tmp ; id=$(tail -n 1 tmp |cut -d' ' -f2) ; cat SimpleParallel.qsub_and_wait.o$id
        while self.qsub_check(jobid):
            time.sleep(5)
        output_filename="%s/%s/work/qsub.log/qsub.o" % (os.environ['HOME'],os.environ['USER']) +jobid
        output_file=open(output_filename,"r")
        res=output_file.readline()
        output_file.close()
        return res

    def run_and_wait(self,cmd,dryrun=False):
        self.qsub_and_wait(cmd,dryrun=False)

class OpenScienceGrid(ComputingHost):
    def __init__(self,user="lfzhao",host="login.osgconnect.net",num_proc=1,finish_rate=0.9):
        self.remote_host=host
        self.remote_user=user
        self.remote_pipe_string="ssh {user}@{host}".format(user=self.remote_user,host=self.remote_host)
        self.max_connect=20
        self.qstat="condor_q"
        self.cooldown_time=30
        self.connect_cooldown = threading.BoundedSemaphore(value=1)
        # num_proc default is 1. The actually copy of running can be done priorly.
        self.num_proc=num_proc
        self.finish_num=finish_rate*self.num_proc
        # No need to know local host, because every copy is started from local host.
        self.submit_header="""
#!/bin/bash
Universe = vanilla
transfer_input_files = {input_tar}
transfer_output_files = {output_tar}
transfer_output_remaps = "{output_tar}={output_tar}.\$(Process)"
Executable = {executable}
Error = {executable}.error
Output = {executable}.output
Log = {executable}.log
+ProjectName="ProtFolding"
Queue %d
""" % self.num_proc
    def get_jobid_osg(self,output):
        buf = StringIO.StringIO(output)
        #print output
        buf.readline()
        jobid = re.split("\s+|\.",buf.readline())
        #print jobid ; exit(0)
        if jobid[-3]=="" :
            exit(-1)
        print "job cluster " + jobid[-3]
        return jobid[-3] # it is a string
    def create_condor_script(self):
        pass
    def qsub_submit(self,cmd,rr=Runnable(),qsub_cmd="cat - | condor_submit " ,dryrun=False):

        if self.remote_pipe_string != "" :
            qsub_cmd=" {pipe_string} \"cd {remote_workpath} ; condor_submit\" ".format(pipe_string=self.remote_pipe_string,
                                                                                              remote_workpath=rr.remote_workpath)
        #print qsub_cmd
        cmd_shell_file=rr.signature+".sh"
        cmd0="{pipe_string} \"cat - > {path}/{file} ; chmod +x {path}/{file}\" ".format(pipe_string=self.remote_pipe_string,
                                                           file=cmd_shell_file,path=rr.remote_workpath)
        header=self.submit_header.format(input_tar=rr.input_tar, output_tar=rr.output_tar, executable=cmd_shell_file,decoynumber=rr.repeat)
        #print cmd0;exit(0)
        #Popen(cmd0,shell=True,stdin=PIPE).communicate( ("\n echo '%s' \n" % cmd) +cmd)
        #print "#/bin/bash\n" + cmd
        if dryrun:
            print "qsub_cmd:\n"+qsub_cmd
            print "header:\n"+header
            print "cmd0:\n"+cmd0
            return 0
        self.try_connect(lambda x:Popen(cmd0,shell=True,stdin=PIPE).communicate( "#!/bin/bash\n" +cmd +"\n") ) # Todo: Add
        print header
        (output,output_error)=self.try_connect(lambda x:Popen(qsub_cmd,shell=True,stdin=PIPE,stdout=PIPE).communicate(header))
        return self.get_jobid_osg(output)

    def qsub_check(self,jobid,test=False):
        # return true if still in the queue
        cmd="%s %s |grep ^%s " % (self.remote_pipe_string,self.qstat,jobid)
        # if num
        #print cmd ; exit(0)
        if not test:
            time.sleep(120)
        #if test:            print "cmd:\n",cmd
        (output,output_error)=self.try_connect(lambda x:Popen(cmd,shell=True,stdout=PIPE,stderr=PIPE).communicate(),test)
        #if test:             print output
        num_proc_running=0
        output_lines=output.split("\n")
        res=[re.match(jobid,x) for x in output_lines] # !=None and re.match(jobid,output).group(0)==jobid
        # if test:            print "res:\n",res;
        for each_res in res:
            if each_res != None:
                num_proc_running=num_proc_running+1
        if num_proc_running < self.num_proc - self.finish_num:
            print num_proc_running," ", self.num_proc ," ",self.finish_num
            return False # not running, finished
        else:
            return True

    def qsub_and_wait(self,cmd,rr=Runnable,dryrun=False):
        # return : the first line in the stdout file
        if dryrun:
            print cmd
            jobid=self.qsub_submit(cmd,rr=rr,dryrun=dryrun)
            return 0
        jobid=self.qsub_submit(cmd,rr=rr)
        #> tmp ; id=$(tail -n 1 tmp |cut -d' ' -f2) ; cat SimpleParallel.qsub_and_wait.o$id
        while self.qsub_check(jobid):
            time.sleep(180)
        #self.copy_back(rr=rr)
        res=0
        return res

    def runbatch_and_wait(self,cmd_list,run_list,dryrun=False):
        #input: a list of command lines, each return one line , return stdout
        ncpu=300
        allthread=[]

        class MyThread(threading.Thread):
        #class MyThread(object):
            def __init__(self,cmd, computer,rr, dryrun=False):
                super(MyThread, self).__init__()
                self.output=""
                self.computer=computer
                self.cmd=cmd
                self.rr=rr
                # modify cmd
                self.dryrun=dryrun
                self.cmd="tar xzf {input_tar} ; {cmd} ; tar czf {output_tar} {output_dir}"\
                            .format(input_tar=rr.input_tar,
                                    cmd=cmd,
                                    output_tar=rr.output_tar,
                                    output_dir=rr.output_dir)

            def run(self):
                # type(self).__name__ == "ComputingHost"
                # pre run
                self.computer.run_and_wait(self.rr.get_pre_run_string(),dryrun=self.dryrun)
                self.output=self.computer.qsub_and_wait(self.cmd,self.rr,dryrun=self.dryrun)
                print "begin copy back: "+self.rr.get_post_run_string()
                self.computer.run_and_wait(self.rr.get_post_run_string(),dryrun=self.dryrun)
                # post run
            def join(self):
                super(MyThread, self).join()
                return self.output
        for i in range(len(cmd_list)):
            t=MyThread(cmd_list[i],self,run_list[i],dryrun=dryrun)
            allthread.append(t)
            t.start()
            time.sleep(60)
            #t.run()
            while threading.activeCount() > ncpu :
                time.sleep(1)
        res=[]
        for t in allthread:
            t.join()
            res.append(t.output)
        return res


class Beagle(OpenScienceGrid): # Beagle is modified version of osg
    def __init__(self,user="zywang",host="login.beagle.ci.uchicago.edu"):
        self.remote_host=host
        self.remote_user=user
        self.remote_pipe_string="ssh {user}@{host}".format(user=self.remote_user,host=self.remote_host)
        self.max_connect=10
        self.qstat="qstat"
        # No need to know local host, because every copy is started from local host.
        self.ncpu=24

    def get_jobid(self,output):
        # unfinished
        return output.rstrip()
    def runbatch_and_wait(self,cmd_list,run_list,dryrun=False):
        # To maximize the node, we need to group jobs together to submit to one node.
        #input: a list of command lines, each return one line , return stdout
        if dryrun :
            print "\n".join(cmd_list)
            return
        all_input=[rr.input_tar for rr in run_list]
        all_input_string=all_input.join(" ")


        runbat="runbat.%s.sh" % hash(run_list)


        self.try_connect(lambda x:Popen(self.remote_pipe_string+" \" cd {path} ; cat - > {runbat}; batch.pl {runbat}\" ".
                               format(path=run_list[0].remote_workpath,runbat=runbat)
                                ).communicate(cmd_list.join("\n")))


class Job(object):
    def __init__(self,cmd,job_name="",mpi_job=False,input_file=[],output_file=[]):
        self.cmd=cmd
        self.job_name=job_name
        self.mpi_job=mpi_job
        self.input_file=input_file
        self.output_file=output_file

class Gouda(ComputingHost): # as a template of SGE compute cluster
    # use system current user if user is empty
    # Support
    # run a shell script  on remote queue
    # Input: shell command, paramenter, input files, shared input files(check before copy) ; Output, stderr, stdout, output files.
    #  run a python function on remote queue (not available now)
    def __init__(self,host="gouda.uchicago.edu",user=os.environ['USER']):
        self.remote_host=host # old name, use host instead
        self.host=host
        self.remote_user=user # old name, use user
        self.user=user
        self.remote_pipe_string="ssh {user}@{host}".format(user=self.remote_user,host=self.remote_host) #old name,use pipe_string instead
        self.pipe_string=self.remote_pipe_string

        # optional global setting
        self.max_connect=10
        self.qstat="qstat"
        # No need to know local host, because every copy is started from local host.
        self.ncpu=24 # old name, use cpu_per_node
        self.cpu_per_node=self.ncpu
        self.max_queued_job=200


class Task(object):
    """Apply a runnable to a sample on a machine"""
    # Which files need to copy
    # COmmand to run
    # How to check status
    # Which files to copy back.
    # Task name
    def __init__(self,name,runnable,sample_list,computer,workdir,exprdir,progdir,db,prof_file):
        self.name=name
        self.workdir=workdir
        self.exprdir=exprdir
        self.progdir=progdir
        self.runnable=runnable
        self.sample_list=sample_list
        self.computer=computer
        self.db=db
        self.exprdir_full=self.workdir+"/"+self.exprdir
        self.prof_file=prof_file
class RankTask(Task):
    def __init__(self, *args, **kwargs):
        super(RankTask, self).__init__(*args, **kwargs)
    def compute_a_rank(self):
        #Input a pdb and some decoys, energy evaluator,
        #Return the string to run
        pass

class SampleTask(Task):
    # Return a folder or tar ball.
    def __init__(self, *args, **kwargs):
        super(SampleTask, self).__init__(*args, **kwargs)
    def run_sampling(self):
        #Input a pdb and some decoys, energy evaluator,
        #Return the string to run
        #The files to copy back
        pass
    def run(self,dryrun=False,**kwargs):
        # TODO: remove to parent
        # create dirs
        for i in self.progdir :
            dir=self.workdir+"/"+self.exprdir+"/"+i
            if not os.path.isdir(dir) :
                os.makedirs(dir)
        cmd_list=[]
        for sample in self.sample_list :
            output_dir=self.workdir+"/"+self.exprdir+"/"+self.progdir[0]
            (cmd,pre_cmd,input_tar,output_tar)=self.runnable.get_run_string(sample,output_dir,**kwargs)
            # run pre_cmd at local

            cmd_list.append(cmd)
        self.computer.runbatch_and_wait(cmd_list,dryrun=dryrun)


# Other helper function
def readlist(filename):
    # read a csv file and return a list for lines.
    f=open(filename,"r")
    res=[ x.rstrip() for x in f.readlines() ]
    f.close()
    return res



if __name__ == '__main__':
    main()

