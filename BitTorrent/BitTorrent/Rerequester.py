# Written by Bram Cohen
# see LICENSE.txt for license information

from urllib import urlopen, quote
from btformats import check_peers
from bencode import bdecode
from threading import Thread, Lock
from traceback import print_exc
true = 1
false = 0

class Rerequester:
    def __init__(self, url, interval, sched, howmany, minpeers, 
            connect, externalsched, amount_left, up, down,
            port, ip, myid, infohash, timeout, errorfunc):
        self.url = ('%s?info_hash=%s&peer_id=%s&port=%s' %
            (url, quote(infohash), quote(myid), str(port)))
        if ip != '':
            self.url += '&ip=' + quote(ip)
        self.interval = interval
        self.announce_interval = 30 * 60
        self.sched = sched
        self.howmany = howmany
        self.minpeers = minpeers
        self.connect = connect
        self.externalsched = externalsched
        self.amount_left = amount_left
        self.up = up
        self.down = down
        self.timeout = timeout
        self.errorfunc = errorfunc
        self.last_failed = true
        self.sched(self.c, interval / 2)

    def c(self):
        self.sched(self.c, self.interval)
        if self.howmany() < self.minpeers:
            self.announce(3)

    def d(self, event = 3):
        self.announce(event, self.e)

    def e(self):
        self.sched(self.d, self.announce_interval)

    def announce(self, event = 3, callback = lambda: None):
        s = ('%s&uploaded=%s&downloaded=%s&left=%s' %
            (self.url, str(self.up()), str(self.down()), 
            str(self.amount_left())))
        if event != 3:
            s += '&event=' + ['started', 'completed', 'stopped'][event]
        set = SetOnce().set
        def checkfail(self = self, set = set, callback = callback):
            if set():
                if self.last_failed:
                    self.errorfunc('Problem connecting to tracker - timeout exceeded')
                self.last_failed = true
                callback()
        self.sched(checkfail, self.timeout)
        Thread(target = self.rerequest, args = [s, set, callback]).start()

    def rerequest(self, url, set, callback):
        try:
            h = urlopen(url)
            r = h.read()
            h.close()
            if set():
                def add(self = self, r = r, callback = callback):
                    self.last_failed = false
                    self.postrequest(r, callback)
                self.externalsched(add)
        except IOError, e:
            if set():
                def fail(self = self, r = 'Problem connecting to tracker - ' + str(e)):
                    if self.last_failed:
                        self.errorfunc(r)
                    self.last_failed = true
                self.externalsched(fail)
                self.externalsched(callback)

    def postrequest(self, data, callback):
        try:
            r = bdecode(data)
            check_peers(r)
            if r.has_key('failure reason'):
                self.errorfunc('rejected by tracker - ' + r['failure reason'])
            else:
                self.announce_interval = r['interval']
                for x in r['peers']:
                    self.connect((x['ip'], x['port']), x['peer id'])
        except ValueError, e:
            if data != '':
                self.errorfunc('bad data from tracker - ' + str(e))
        callback()

class SetOnce:
    def __init__(self):
        self.lock = Lock()
        self.first = true

    def set(self):
        try:
            self.lock.acquire()
            r = self.first
            self.first = false
            return r
        finally:
            self.lock.release()

