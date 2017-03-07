#!/usr/bin/python -u
# coding: utf-8

import sys
import getopt
import time
import os
import socket

from datetime import datetime
from line import LineClient, LineGroup, LineContact

#-------------------------------------------------------------------------------
#     G L O B A L    V A R I A B L E S
#-------------------------------------------------------------------------------

botuser = None
botpass = None
scriptname = sys.argv[0]
host = 'localhost'
port = 8090
timeout = 10
backlog = 5
size = 4096

#-------------------------------------------------------------------------------
#     F U N C T I O N S
#-------------------------------------------------------------------------------

# Function Usage
def usage():
	print 'Usage : ' + scriptname + ' -u <user> -p <password> -l <listen port>'
	sys.exit(0)
	return

# Function line send messages
def sendtext(name,msg):
	try:
		group = client.getGroupByName(name)
		group.sendMessage(msg)
		print "[%s] [%s] [Socket] [%s:%s] Success - Group(%s) : %s" % (str(datetime.now()), botuser, address[0], address[1], name, msg[:-1])
		res = '0 [Success]'
	except:
		print "[%s] [%s] [Socket] [%s:%s] Fail Line group is not exist - Group(%s) : %s" % (str(datetime.now()), botuser, address[0], address[1], name, msg[:-1])
		res = '1 [Line group is not exist]'
		pass
	return res
	
#-------------------------------------------------------------------------------
#     I N I T I A L    P R O G R A M
#-------------------------------------------------------------------------------

# Get option detail
try:
	opts, args = getopt.getopt(sys.argv[1:],"hu:p:l:",["user=","pass=","listen="])
except getopt.GetoptError:
	usage()

try:
	for opt, arg in opts:
		if opt == '-h':
			usage()
		elif opt in ("-u", "--user"):
			botuser = arg
		elif opt in ("-p", "--pass"):
			botpass = arg
		elif opt in ("-l", "--listen"):
			port = int(arg)
		else:
			usage()
except:
	usage()
	
# Verify User & Password input
if (botuser == None) or (botpass == None):
	usage()
	
# Login line account
try:
	print "[%s] [%s] [Initial] Start login line client" % (str(datetime.now()), botuser)
	client = LineClient(botuser, botpass)
	print "[%s] [%s] [Initial] Login Success" % (str(datetime.now()), botuser)
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
		if data:
			msg = data.split(':', 1 )
			if len(msg) > 1:
				res = sendtext(msg[0],msg[1])
				sv.sendall(res)
			else:
				print "[%s] [%s] [Socket] [%s:%s] Fail Syntax Error - %s" % (str(datetime.now()), botuser, address[0], address[1], msg[0][:-1])
				res = '2 [Syntax Error : <Group Name>,<Content>]'
				sv.sendall(res)
	except socket.timeout:
		res = '-1 [Connection timeout ' + str(timeout) + ' sec.]'
		sv.sendall(res)
		sv.close()
		print "[%s] [%s] [Socket] [%s:%s] Disconnected by timeout %i sec" % (str(datetime.now()), botuser, address[0], address[1], timeout)
		
s.shutdown(socket.SHUT_RDWR)
s.close()