#!/usr/bin/python -u
# coding: utf-8

import sys
import os
import os.path
import time
import getopt
import socket

from datetime import datetime
from line import LineClient, LineGroup, LineContact

#-------------------------------------------------------------------------------
#     G L O B A L    V A R I A B L E S
#-------------------------------------------------------------------------------

botuser = "truemsoc@gmail.com"
botpass = "true"
botcom  = "SPHC-PC"
scriptname = sys.argv[0]
host = ''
port = 8090
timeout = 10
backlog = 5
size = 40960

imagename = "/home/line/botline/log/image.jpg"

#-------------------------------------------------------------------------------
#     F U N C T I O N S
#-------------------------------------------------------------------------------

# Function line send messages
def sendtext(name,msg):
        try:
                group = client.getGroupByName(name)
                group.sendMessage(msg)
                print "[%s] [%s] [Socket] [%s:%s] Send text success - Group(%s) : %s" % (str(datetime.now()), botuser, address[0], address[1], name, msg)
                res = '0 [Success]'
        except:
                print "[%s] [%s] [Socket] [%s:%s] Send text fail Line group is not exist - Group(%s) : %s" % (str(datetime.now()), botuser, address[0], address[1], name, msg)
                res = '1 [Line group is not exist]'
                pass
        return res

def sendimage(name,image):
        try:
                imagesize = os.path.getsize(image)
                group = client.getGroupByName(name)
                group.sendImage(image)
                print "[%s] [%s] [Socket] [%s:%s] Send image success - Group(%s) : Size %i bytes" % (str(datetime.now()), botuser, address[0], address[1], name, imagesize)
                res = '0 [Success]'
        except:
                print "[%s] [%s] [Socket] [%s:%s] Send image fail Line group is not exist - Group(%s) : Size %i bytes" % (str(datetime.now()), botuser, address[0], address[1], name, imagesize)
                res = '1 [Line group is not exist]'
                pass                
        return res

#-------------------------------------------------------------------------------
#     I N I T I A L    P R O G R A M
#-------------------------------------------------------------------------------

# Login line account
try:
        print "[%s] [%s] [Initial] Start login line client" % (str(datetime.now()), botuser)
        client = LineClient(botuser, botpass,authToken=None,is_mac=False,com_name=botcom,bypass=True)
        print "[%s] [%s] [Initial] Login Success" % (str(datetime.now()), botuser)
        authToken = client.authToken
        print "[%s] [Login] [%s] - AuthToken=%s" % (str(datetime.now()), botuser,authToken)
except:
        print "[%s] [%s] [Initial] Login Fail" % (str(datetime.now()), botuser)
        raise

#-------------------------------------------------------------------------------
#     M A I N    P R O G R A M
#-------------------------------------------------------------------------------

s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
s.bind((host,port))
s.listen(backlog)
print "[%s] [%s] [Initial] Establish socket listener on port %i" % (str(datetime.now()), botuser, port)

while True:
        sv, address = s.accept()
        sv.settimeout(timeout)
        try:
                data = sv.recv(size)
                if (data.startswith("@image")):
                        msg = data.split(':', 1 )
                        if len(msg) > 1:
                                fp = open(imagename,'w')
                                sv.sendall('ok')
                                while True:
                                        strng = sv.recv(512)
                                        if not strng:
                                                break
                                        fp.write(strng)
                                fp.close()
                                res = sendimage(msg[1],imagename)
                                sv.sendall(res)
                        else:
                                print "[%s] [%s] [Socket] [%s:%s] Fail Syntax Error - File image" % (str(datetime.now()), botuser, address[0], address[1])
                                res = '3 [Syntax Error : Send image]'
                                sv.sendall(res)
                else:
                        msg = data.split(':', 1 )
                        if len(msg) > 1:
                                res = sendtext(msg[0],msg[1])
                                sv.sendall(res)
                        else:
                                print "[%s] [%s] [Socket] [%s:%s] Fail Syntax Error - %s" % (str(datetime.now()), botuser, address[0], address[1], msg[0][:-1])
                                res = '2 [Syntax Error : Send text]'
                                sv.sendall(res)

        except socket.timeout:
                res = '-1 [Connection timeout ' + str(timeout) + ' sec.]'
                sv.sendall(res)
                sv.close()
                print "[%s] [%s] [Socket] [%s:%s] Disconnected by timeout %i sec" % (str(datetime.now()), botuser, address[0], address[1], timeout)

s.shutdown(socket.SHUT_RDWR)
s.close()
