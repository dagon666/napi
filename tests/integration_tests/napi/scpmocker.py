import os
import subprocess


class ScpMocker(object):
    """
    This class interfaces to scpmocker - a programmable command mock.
    """
    def __init__(self, scpMockerPath, sandboxPath):
        self.scpMockerPath = scpMockerPath
        self.sandboxPath = sandboxPath
        self.binPath = os.path.join(self.sandboxPath, 'bin')
        self.dbPath = os.path.join(self.sandboxPath, 'db')


    def __enter__(self):
        os.mkdir(self.binPath)
        os.mkdir(self.dbPath)
        self.envOrig = os.environ.copy()

        os.environ["PATH"] = ':'.join((self.binPath, os.environ["PATH"]))
        os.environ["SCPMOCKER_BIN_PATH"] = self.binPath
        os.environ["SCPMOCKER_DB_PATH"] = self.dbPath

        return self

    def __exit__(self, *args):
        os.environ.clear()
        os.environ.update(self.envOrig)

    def getPath(self, cmd):
        return os.path.join(self.binPath, cmd)

    def patchCmd(self, cmd):
        cmdPath = self.getPath(cmd)
        os.symlink(self.scpMockerPath, cmdPath)

    def getCallCount(self, cmd):
        inv = [ self.scpMockerPath, '-c', cmd, 'status', '-C' ]
        output = subprocess.check_output(inv).strip()
        return int(output.strip())

    def getCallArgs(self, cmd, n):
        inv = [ self.scpMockerPath, '-c', cmd, 'status', '-A', str(n) ]
        output = subprocess.check_output(inv).strip()
        return output

    def program(self, cmd, stdoutStr = "", exitStatus = 0, n = 0):
        inv = [ self.scpMockerPath, '-c', cmd, 'program',
                '-e', str(exitStatus),
                '-s', stdoutStr,
                ]

        if n == 0:
            inv.append('-a')
            subprocess.call(inv)
        else:
            for _ in xrange(n):
                subprocess.call(inv)

    def unPatchCmd(self, cmd):
        cmdPath = self.getPath(cmd)
        try:
            os.unlink(cmdPath)
        except OSError as e:
            # TODO add logging?
            pass


