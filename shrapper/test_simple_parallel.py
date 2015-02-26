from SimpleParallel import *

def test_runnable():
    # by default,
    cmd='echo 123'
    cmd_job=Runnable(cmd)
    output=cmd_job.run(runlater=False)
    assert output=="123\n"

def test_runlist():
    # for list, we can run
    # 1) parallel on local, with a pool instead of wait
    # 2) or we use list of Runnable, and give the list to a computer to run them.
    cmd=['echo 123','echo 456 ; echo 789']
    cmd_joblist=[Runnable(x) for x in cmd]

    computer=ComputingHost()
    output_list=computer.runbatch_and_wait(cmd_joblist)
    assert output_list[0]=="123\n"
    assert output_list[1]=="456\n789\n"

def test_runnable_extend():
    class Testr(Runnable):
        def __init__(self):
            super(Testr,self).__init__()
        def get_run_string(self,x):
            return "echo %s " % x
    a=Testr()
    res=a.run("aa")
    print "result:",res
    # test passed

def test_qsub_check():
    computer=OpenScienceGrid()
    print computer.qsub_check("1368207",test=True)
    print computer.qsub_check("1368207",test=False)

def main():
    #test_runnable()
    test_runnable()
    test_runlist()

if __name__ == '__main__':
    main()