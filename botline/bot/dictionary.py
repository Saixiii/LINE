#!/usr/bin/python -u
# coding: utf-8

import sys
import pickle
import paramiko
import urllib2

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
def comdic(cmd):
	try:
		proxy_support = urllib2.ProxyHandler({"https":"http://proxy.true.th:80"})
		opener = urllib2.build_opener(proxy_support)
		urllib2.install_opener(opener)
		url = "https://translate.google.com/m?hl=en&sl=th&tl=en&ie=UTF-8&prev=_m&q="
		if(isEnglish(cmd)):
			url = "https://translate.google.com/m?hl=th&sl=en&tl=th&ie=UTF-8&prev=_m&q="
		word = cmd.replace(" ", "+")
		req = urllib2.Request(url + word, headers={'User-Agent': 'Mozilla/5.0'})
		html = urllib2.urlopen(req, timeout = 20)
		soup = BeautifulSoup(html, 'html.parser')
		div = soup.findAll("div", { "class" : "t0" })
		if len(div) > 0:
			msg     = div[0].text.strip()
			print str(cmd) + " \n : " + str(msg)
		else:
			msg     = "???"
			print str(cmd) + " \n : " + str(msg)
	except:
		raise
	return
		
		
#-------------------------------------------------------------------------------
#     M A I N    P R O G R A M
#-------------------------------------------------------------------------------

if(len(sys.argv) < 2):
	sys.exit(0)

comdic(sys.argv[1])
