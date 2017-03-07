#!/usr/bin/python -u
# coding: utf-8

import sys
import os.path
import socket
import getopt

#-------------------------------------------------------------------------------
#     G L O B A L    V A R I A B L E S
#-------------------------------------------------------------------------------

host  = '10.4.58.39'
port  = 8090
group = None
msg   = None
image = None
data  = None

imagesize = 1073741824

#-------------------------------------------------------------------------------
#     F U N C T I O N S
#-------------------------------------------------------------------------------

# Function Usage
def usage():
	#print 'Mandatory : [-g <LineGroup>] [-m <LineMessage>]'
	#print '          : [-g <LineGroup>] [-i <LineImage>]'
	#print 'Optional  : [-h <host>] [-p <port>]'
	sys.exit(0)
	return


#-------------------------------------------------------------------------------
#     I N I T I A L    P R O G R A M
#-------------------------------------------------------------------------------

# Get option detail
try:
	opts, args = getopt.getopt(sys.argv[1:],"h:p:g:m:i:",["host=","port=","group=","msg="])
except getopt.GetoptError:
	usage()

try:
	for opt, arg in opts:
		if opt in ("-h", "--host"):
			host = arg
		elif opt in ("-p", "--port"):
			port = int(arg)
		elif opt in ("-g", "--group"):
			group = arg
		elif opt in ("-m", "--msg"):
			msg = arg
		elif opt in ("-i", "--image"):
			image = arg
		else:
			usage()
except:
	usage()

# Verify input data
if group == None:
	usage()
elif (((msg == None) and (image == None)) or ((msg != None) and (image != None))):
	usage()
elif msg != None:
	data = group + ":" + msg
elif not (os.path.isfile(image)):
	#print 'File image does not exist.'
	sys.exit(0)
elif os.path.getsize(image) > imagesize:
	#print 'File image must less than 1MB.'
	sys.exit(0)
else:
	data = '@image:' + group
	

# Create a socket (SOCK_STREAM means a TCP socket)
sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

try:
    # Connect to server and send data
    sock.connect((host, port))
    sock.settimeout(30)
    
    if msg != None:
    	sock.sendall(data + "\n")
    elif image != None:
    	sock.sendall(data)
    	if (sock.recv(4096) == "ok"):
    		img = open(image,'r')
    		while True:
    			strng = img.readline(512)
    			if not strng:
    				sock.shutdown(socket.SHUT_WR)
    				break
    			sock.send(strng)
    		img.close()
    	else:
    		print 'fail'

    # Receive data from the server and shut down
    received = sock.recv(4096)
finally:
    sock.close()
    
#print "{0}".format(received)
