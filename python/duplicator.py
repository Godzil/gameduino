class Duplicator(object):
    def __init__(self, objs):
        self.objs = objs
    def __getattr__(self, name):
        def bcast(*args):
            return [o.__getattribute__(name)(*args) for o in self.objs]
        return bcast

