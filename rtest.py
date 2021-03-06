import time, os, os.path
import pmap
import itertools as it
import threading, Queue

class LogWriter (threading.Thread):
    def __init__ (self, logfile, q):
        threading.Thread.__init__ (self)
        self.log  = open (logfile, "w")
        self.q    = q
        self.halt = False
        self.log.write("test, time(s), result \n")

    def __del__ (self):
        self.log.close ()

    def run (self):
        while not self.halt:
            try:
                file, runtime, ok = self.q.get (timeout=1)
                self.log.write("%s, %f, %s \n" % (file, runtime, ok))
                self.log.flush()
                self.q.task_done ()
            except Queue.Empty:
                pass

class TestConfig:
    def __init__ (self, testdirs, logfile = None, threadcount = 1):
        self.testdirs    = testdirs
        self.valid_exits = [x for d, x in self.testdirs]
        if logfile != None:
            self.logq   = Queue.Queue ()
            self.logger = LogWriter (logfile, self.logq)
            self.logger.start ()
        else:
            self.logger = None
        self.exceptions  = list()
        self.threadcount = threadcount

    def finalize (self):
        if self.logger != None:
            self.logger.halt = True

    def is_test (self, file):
        pass

    def run_test (self, file):
        pass

    def log_test (self, file, runtime, ok):
        if self.logger != None:
            self.logq.put ((file, runtime, ok))

        if ok not in self.valid_exits:
            self.exceptions.append (file)
  
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
        self.config.finalize()
        failed    = sorted([(result[0], result[2]) for result in results if result[1] == False])
        failcount = len(failed)
        if failcount == 0:
            print "\n\033[1;32mPassed all tests! :D\033[1;0m"
        else:
            failnames  = [fail[0] for fail in failed]
            print "\n\033[1;31mFailed %d tests:\033[1;0m %s" % (failcount, ", ".join(failnames))

            exceptions = [fail[0] for fail in failed if fail[1]]
            if exceptions != []:
                print "\n\033[1;31mExceptions thrown on %d tests:\033[1;0m %s" % (len(exceptions), ", ".join(exceptions))

        return (failcount != 0)

    def directory_tests (self, dir, expected_status):
        tests = list()
        for dir, dirs, files in os.walk (dir):
            def join_dir (file):
                return os.path.join (dir, file)
            for file in map (join_dir, files):
                if self.config.is_test (file):
                    tests.append ((file, expected_status))
        return tests

    def run (self):
        return self.run_tests (it.chain (*[self.directory_tests (dir, expected_status) for dir, expected_status in self.config.testdirs]))
