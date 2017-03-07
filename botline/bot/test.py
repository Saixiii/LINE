#!/usr/bin/python -u
# coding: utf-8

import sys
import pickle
import paramiko
import urllib2
import random

reload(sys)
sys.setdefaultencoding('utf8')

from bs4 import BeautifulSoup


# Function check english character
def isEnglish(s):
	try:
		s.decode('ascii')
	except UnicodeDecodeError:
		return False
	else:
		return True

		
# Function google transalate
def compic(cmd):
	try:
		proxy_support = urllib2.ProxyHandler({"https":"http://proxy.true.th:80"})
		opener = urllib2.build_opener(proxy_support)
		urllib2.install_opener(opener)
		url = "https://www.google.co.th/search?tbm=isch&tbs=isz:lt,islt:2mp&q="
		#if(isEnglish(cmd)):
		#	url = "https://translate.google.com/m?hl=th&sl=en&tl=th&ie=UTF-8&prev=_m&q="
		word = cmd.replace(" ", "+")
		req = urllib2.Request(url + word, headers={'User-Agent': 'Mozilla/5.0'})
		html = urllib2.urlopen(req, timeout = 20)
		soup = BeautifulSoup(html, 'html.parser')
		div = soup.findAll("img")
                print div
		image = div[random.randrange(1,len(div)-1)].get('src')
		
		f = open('/home/mstm/botline/image/searchimage.jpg','wb')
		f.write(urllib2.urlopen(image).read())
		f.close()
		
		print "pic=/home/mstm/botline/image/searchimage.jpg"
	except:
		raise
	return
		
		
#-------------------------------------------------------------------------------
#     M A I N    P R O G R A M
#-------------------------------------------------------------------------------

if(len(sys.argv) < 2):
	sys.exit(0)

compic(sys.argv[1])
