import time, os, os.path
import pmap
import itertools as it

class TestRunner:
    def __init__ (self, runtest, istest, threadcount = 1):
        self.runtest     = runtest
        self.istest      = istest
        self.threadcount = threadcount

    def run_test (self, (file, expected_status)):
        start  = time.time ()
        status = self.runtest (file)
        print "%f seconds" % (time.time () - start)

        ok = (status == expected_status)
        if ok:
            print "\033[1;32mSUCCESS!\033[1;0m (%s)\n" % (file)
        else:
            print "\033[1;31mFAILURE :(\033[1;0m (%s) \n" % (file)
        return (file, ok)

    def run (self, tests):
        results   = pmap.map (self.threadcount, self.run_test, tests)
        failed    = [result[0] for result in results if result[1] == False]
        failcount = len(failed)
        if failcount == 0:
            print "\n\033[1;32mPassed all tests! :D\033[1;0m"
        else:
            print "\n\033[1;31mFailed %d tests:\033[1;0m %s" % (failcount, ", ".join(failed))
        return (failcount != 0)

    def directory_tests (self, dir, expected_status):
        return it.chain(*[[(os.path.join (dir, file), expected_status) for file in files if self.istest (file)] for dir, dirs, files in os.walk(dir)])

    def run_directories (self, testdirs):
        return self.run (it.chain (*[self.directory_tests (dir, expected_status) for dir, expected_status in testdirs]))
