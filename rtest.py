import time, os, os.path
import pmap
import itertools as it

class TestConfig:
    def __init__ (self, testdirs, logfile = None, threadcount = 1):
        self.testdirs    = testdirs
        self.valid_exits = [x for d, x in self.testdirs]
        self.logfile     = logfile
        self.log         = dict()
        self.exceptions  = list()
        self.threadcount = threadcount

        f = open(logfile, "a")
	f.write("test, time(s), result \n")
	f.close()

    def is_test (self, file):
        pass

    def run_test (self, file):
        pass

    def log_test (self, file, runtime, ok):
        self.log[file] = (runtime, ok)
        if ok not in self.valid_exits:
            self.exceptions.append (file)

    def write_log (self):
        if self.logfile == None:
            return

        f = open(self.logfile, "a")
        for file, (runtime, ok) in sorted(self.log.items()):
            #f.write("test: %s\ntime: %f seconds\nresult: %s\n\n" % (file, runtime, ok))
            f.write("%s, %f, %s \n" % (file, runtime, ok))
	f.close()
  
class TestRunner:
    def __init__ (self, config):
        self.config = config

    def run_test (self, (file, expected_statuses)):
        start   = time.time ()
        status  = self.config.run_test (file)
        runtime = time.time () - start
        print "%f seconds" % (runtime)

        if hasattr (expected_statuses, '__iter__'):
	  ok = (status in expected_statuses)
	else:
	  ok = (status == expected_statuses)
        if ok:
            print "\033[1;32mSUCCESS!\033[1;0m (%s)\n" % (file)
        else:
            print "\033[1;31mFAILURE :(\033[1;0m (%s) \n" % (file)
        self.config.log_test(file, runtime, ok)
        
        return (file, ok, status not in self.config.valid_exits)

    def run_tests (self, tests):
        results   = pmap.map (self.config.threadcount, self.run_test, tests)
        failed    = sorted([(result[0], result[2]) for result in results if result[1] == False])
        failcount = len(failed)
        if failcount == 0:
            print "\n\033[1;32mPassed all tests! :D\033[1;0m"
        else:
            failnames  = [fail[0] for fail in failed]
            print "\n\033[1;31mFailed %d tests:\033[1;0m %s" % (failcount, "\n".join(failnames))

            exceptions = [fail[0] for fail in failed if fail[1]]
            if exceptions != []:
                print "\n\033[1;31mExceptions thrown on %d tests:\033[1;0m %s" % (len(exceptions), ", ".join(exceptions))

        self.config.write_log()
        return (failcount != 0)

    def directory_tests (self, dir, expected_status):
        return it.chain(*[[(os.path.join (dir, file), expected_status) for file in files if self.config.is_test (file)] for dir, dirs, files in os.walk(dir)])

    def run (self):
        return self.run_tests (it.chain (*[self.directory_tests (dir, expected_status) for dir, expected_status in self.config.testdirs]))
