from __future__ import division

import os
import sys


def main():
    for i, arg in enumerate(sys.argv):
        if i == 0:
            pass
        else:
            parse(arg)
            #doFile(arg)


def doFile(ff):
    file_name = os.path.split(ff)[-1]

    path_salamon = 'CompletedMelodies/Salamon/'
    path_durrieu = 'CompletedMelodies/Durrieu/'
    len_salamon = lineCount(path_salamon + file_name)
    len_durrieu = lineCount(path_durrieu + file_name)

    parse(path_salamon + file_name)
    parse(path_durrieu + file_name)
    #parse(path_durrieu)


def lineCount(file):
    f = open(file)
    for i, line in enumerate(f):
        pass
    f.close()
    return i+1


def parse(file):
    length = lineCount(file)
    # create file
    print length
    name = os.path.splitext(file)[0]

    f = open(file)
    result = open(str(name + '_formatted.txt'), 'w+')
    for i, line in enumerate(f):
        value = line.split('\t', 1)[-1]
        to_write = str(i/length) + "\t" + value
        result.write(to_write)
    result.close()
    f.close()

if __name__ == "__main__":
    main()
