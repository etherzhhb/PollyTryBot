import os
from buildbot.steps.shell import ShellCommand

def checkoutSVN(f, name, mode, svnurl, workdir) :
    #Checkout if the source dir didn't exists
    dirname=os.path.dirname(workdir)
    f.addStep(ShellCommand(name = name,
                           command="[ -e %s ] || svn co %s %s" % (workdir, svnurl, os.path.basename(workdir)),
                                   workdir='.' if dirname == '' else dirname ,
                                   description='checkout %s' % name, timeout= 10 * 60,
                                   haltOnFailure=True))
    f.addStep(ShellCommand(name = name,
                           command="svn update",
                                   workdir=workdir,
                                   description='update %s' % name, timeout= 10 * 60,
                                   haltOnFailure=True))
