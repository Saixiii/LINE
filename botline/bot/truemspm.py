#!/usr/bin/python -u
# coding: utf-8

import time
import subprocess
import random
import codecs
import collections
import pickle
import paramiko
import urllib2

from datetime import datetime
from bs4 import BeautifulSoup
from line import LineClient, LineGroup, LineContact

#-------------------------------------------------------------------------------
#     G L O B A L    V A R I A B L E S
#-------------------------------------------------------------------------------
botuser = "truemspm@gmail.com"
botpass = "true"
botlog  = "VASMSPM-PC"
botname = "[BOT]-MSPM"
botcall = "@"
botlen  = len(botcall)
bottoken = "DVEOLQOpsqHmKMayHPf0.r5+wW0L6Fv6zQkJjophEqa.s0lgz2XYAX8lErQbJFlyqlfjrHoG1aIFH2WmUlblTtM="

op       = []
sender   = []
receiver = []
maxread  = 5
timeout  = 60

p_home = "/home/mstm/botline"
p_conf = p_home + "/conf"

f_qa = p_conf + "/QA.conf"
f_dis = p_conf + "/dis.conf"
f_run = p_conf + "/run.conf"
f_ccp = p_conf + "/ccp.conf"
f_sce = p_conf + "/sce.conf"
f_graph = p_conf + "/graph.conf"
u_run = p_conf + "/run.allow"
u_dis = p_conf + "/dis.allow"
u_ccp = p_conf + "/ccp.allow"
u_sce = p_conf + "/sce.allow"

#-------------------------------------------------------------------------------
#     F U N C T I O N S
#-------------------------------------------------------------------------------

# Function line login
def linelogin():
	try:
		print "[%s] [Login] [%s] - Start login line client" % (str(datetime.now()), botname)
		client = LineClient(botuser, botpass,authToken=None,is_mac=False,com_name=botlog,bypass=True)
		print "[%s] [Login] [%s] - Login Success" % (str(datetime.now()), botname)
		authToken = client.authToken
		print "[%s] [Login] [%s] - AuthToken=%s" % (str(datetime.now()), botname,authToken)
	except:
		print "[%s] [Login] [%s] - Login Fail" % (str(datetime.now()), botname)
	return

# Function check call bot
def chkcall(msg):
	if msg != None and msg[:botlen].lower() == botcall:
		return True
	else:
		return False

# Function line send messages
def sendtext(msg):
	for attempt in range(10):
		try:
			if receiver.name == botname:
				sender.sendMessage("[%s]\n%s" % (sender.name, msg))
			else:
				receiver.sendMessage("[%s]\n%s" % (sender.name, msg))
			break
		except Exception as e:
			print "[%s] [Error exception retry send text] %s" % (str(datetime.now()),str(e))
			time.sleep(random.randrange(2,4))
		else:
			print "[%s] [Max limit retry send text] %s" % (str(datetime.now()),str(msg))
			break
	return

# Function line send image
def sendimage(path):
	for attempt in range(10):
		try:
			if receiver.name == botname:
				sender.sendImage(path)
			else:
				receiver.sendImage(path)
			break
		except Exception as e:
			print "[%s] [Error exception retry send image] %s" % (str(datetime.now()),str(e))
			time.sleep(random.randrange(2,4))
		else:
			print "[%s] [Max limit retry send image] %s" % (str(datetime.now()),str(msg))
			break
	return

# Function line send stricker
def sendstk(STKPKGID,STKVER,STKID):
	if receiver.name == botname:
		sender.sendSticker(stickerId=STKID,stickerPackageId=STKPKGID,stickerVersion=STKVER)
	else:
		receiver.sendSticker(stickerId=STKID,stickerPackageId=STKPKGID,stickerVersion=STKVER)
	return

# Function line send stricker
def warnflood():
	msg = "พิมพ์ช้าๆกันหน่อยครัช ผมอ่านไม่ทัน"
	sendstk('2','100','518')
	sendtext(msg)
	return

# Function dictionary loader
def dicloader(filename):
	dic = {k: [] for k in range(0)}
	with open(filename) as f:
		for line in f:
			listedline = line.strip().split(',') # split around the = sign
			if len(listedline) > 1: # we have the = sign in there
				dic[listedline[0]] = listedline[1]
				#print listedline[0] + " = " + listedline[1]
	return dic

# Function Q/A dictionary loader
def loaderQA():
	dic = pickle.load( open(f_qa, "rb" ) )
	return dic

# Function Q/A dictionary update
def updateQA(msg):
	msg = msg.split(' ', 1 )
	try:
		if len(msg) > 1:
			dic_qa.update({ msg[0] : msg[1] })
			pickle.dump( dic_qa, open(f_qa, "wb" ) )
			sendstk('1','100','2')
			print "[%s] [ContentType : UpdateQA] [%s] : %s -> %s" % (str(datetime.now()), sender.name, msg[0], msg[1])
		else:
			sendtext("คำตอบละครัช ?\n" + botcall + " learn [ถาม] [ตอบ]")
			sendstk('1','100','118')
	except:
		raise
	return

# Function check english character
def isEnglish(s):
	try:
		s.decode('ascii')
	except UnicodeDecodeError:
		return False
	else:
		return True

# Function command run shell
def comrun(cmd):
	try:
		args = cmd.split(' ', 1)
		comargs = dic_run.get(args[0])
		if (sender.name in dic_orun) or (receiver.name in dic_orun):
			if comargs != None:
				if len(args) > 1:
					sendtext("ใจเย็นๆนะครับ กำลังเช็กให้อยู่ รอแปปนึง")
					msg = ""
					ssh = paramiko.SSHClient()
					ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
					ssh.connect('localhost', username='mstm',password='mstm')
					stdin,stdout,stderr = ssh.exec_command(comargs + " " + args[1])
					for line in stdout.readlines():
						msg += line.strip() + "\n"
					ssh.close()
					if msg == "":
						sendtext("No response or timeout > " + str(timeout) + "s.")
					else:
						sendtext(msg)
				else:
					sendtext("ใจเย็นๆนะครับ กำลังเช็กให้อยู่ รอแปปนึง")
					msg = ""
					ssh = paramiko.SSHClient()
					ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
					ssh.connect('localhost', username='mstm',password='mstm')
					stdin,stdout,stderr = ssh.exec_command(comargs)
					for line in stdout.readlines():
						msg += line.strip() + "\n"
					ssh.close()
					if msg == "":
						sendtext("No response or timeout > " + str(timeout) + "s.")
					else:
						sendtext(msg)
			else:
				sendtext("เขาสอนผมมาแค่นี้นะ\n" + man_run)
		else:
			sendtext("คุณคือใคร เราไม่รู้จัก\nไป run ในห้อง group สิ")
	except:
		raise
	return
	
# Function command run shell (ccp)
def comccp(cmd):
	try:
		args = cmd.split(' ', 1)
		comargs = dic_ccp.get(args[0])
		if (sender.name in dic_occp) or (receiver.name in dic_occp):
			if comargs != None:
				if len(args) > 1:
					sendtext("ใจเย็นๆนะครับ กำลังเช็กให้อยู่ รอแปปนึง")
					msg = ""
					ssh = paramiko.SSHClient()
					ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
					ssh.connect('localhost', username='mstm',password='mstm')
					stdin,stdout,stderr = ssh.exec_command(comargs + " " + args[1])
					for line in stdout.readlines():
						msg += line.strip() + "\n"
					ssh.close()
					if msg == "":
						sendtext("No response or timeout > " + str(timeout) + "s.")
					else:
						sendtext(msg)
				else:
					sendtext("ใจเย็นๆนะครับ กำลังเช็กให้อยู่ รอแปปนึง")
					msg = ""
					ssh = paramiko.SSHClient()
					ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
					ssh.connect('localhost', username='mstm',password='mstm')
					stdin,stdout,stderr = ssh.exec_command(comargs)
					for line in stdout.readlines():
						msg += line.strip() + "\n"
					ssh.close()
					if msg == "":
						sendtext("No response or timeout > " + str(timeout) + "s.")
					else:
						sendtext(msg)
			else:
				sendtext("เขาสอนผมมาแค่นี้นะ\n" + man_ccp)
		else:
			sendtext("คุณคือใคร เราไม่รู้จัก\nไป run ในห้อง group สิ")
	except:
		raise
	return
	
# Function command run shell (sce)
def comsce(cmd):
	try:
		args = cmd.split(' ', 1)
		comargs = dic_ccp.get(args[0])
		if (sender.name in dic_osce) or (receiver.name in dic_osce):
			if comargs != None:
				if len(args) > 1:
					sendtext("ใจเย็นๆนะครับ กำลังเช็กให้อยู่ รอแปปนึง")
					msg = ""
					ssh = paramiko.SSHClient()
					ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
					ssh.connect('localhost', username='mstm',password='mstm')
					stdin,stdout,stderr = ssh.exec_command(comargs + " " + args[1])
					for line in stdout.readlines():
						msg += line.strip() + "\n"
					ssh.close()
					if msg == "":
						sendtext("No response or timeout > " + str(timeout) + "s.")
					else:
						sendtext(msg)
				else:
					sendtext("ใจเย็นๆนะครับ กำลังเช็กให้อยู่ รอแปปนึง")
					msg = ""
					ssh = paramiko.SSHClient()
					ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
					ssh.connect('localhost', username='mstm',password='mstm')
					stdin,stdout,stderr = ssh.exec_command(comargs)
					for line in stdout.readlines():
						msg += line.strip() + "\n"
					ssh.close()
					if msg == "":
						sendtext("No response or timeout > " + str(timeout) + "s.")
					else:
						sendtext(msg)
			else:
				sendtext("เขาสอนผมมาแค่นี้นะ\n" + man_ccp)
		else:
			sendtext("คุณคือใคร เราไม่รู้จัก\nไป run ในห้อง group สิ")
	except:
		raise
	return
	
# Function command send image
def comgraph(cmd):
	try:
		args = cmd.split(' ', 1)
		comargs = dic_graph.get(args[0])
		if (sender.name in dic_orun) or (receiver.name in dic_orun):
			if comargs != None:
				if len(args) > 1:
					sendtext("ใจเย็นๆนะครับ กำลังเช็กให้อยู่ รอแปปนึง")
					msg = ""
					ssh = paramiko.SSHClient()
					ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
					ssh.connect('localhost', username='mstm',password='mstm')
					stdin,stdout,stderr = ssh.exec_command(comargs + " " + args[1])
					for line in stdout.readlines():
						msg += line.strip() + "\n"
					ssh.close()
					if msg == "":
						sendtext("No response or timeout > " + str(timeout) + "s.")
					else:
						pic = msg.split('=', 1)
						if len(pic) > 1 and pic[0] == "pic":
							print pic[1][:-1]
							listpic = pic[1][:-1].split(',')
							for image in listpic:
								sendimage(image)
						else:
							sendtext(msg)
				else:
					sendtext("ใจเย็นๆนะครับ กำลังเช็กให้อยู่ รอแปปนึง")
					msg = ""
					ssh = paramiko.SSHClient()
					ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
					ssh.connect('localhost', username='mstm',password='mstm')
					stdin,stdout,stderr = ssh.exec_command(comargs)
					for line in stdout.readlines():
						msg += line.strip() + "\n"
					ssh.close()
					if msg == "":
						sendtext("No response or timeout > " + str(timeout) + "s.")
					else:
						pic = msg.split('=', 1)
						if len(pic) > 1 and pic[0] == "pic":
							print pic[1][:-1]
							listpic = pic[1][:-1].split(',')
							for image in listpic:
								sendimage(image)
						else:
							sendtext(msg)
			else:
				sendtext(args[0] + "เขาสอนผมมาแค่นี้นะ\n" + man_graph)
		else:
			sendtext("คุณคือใคร เราไม่รู้จัก\nไป run ในห้อง group สิ")
	except:
		raise
	return
	
# Function command display java
def comdis(cmd):
	try:
		args = cmd.split(' ')
		comargs = dic_dis.get(args[0])
		if True == True:
		#if (sender.name in dic_odis) or (receiver.name in dic_odis) or (sender.name in dic_orun) or (receiver.name in dic_orun):
			if comargs != None:
				if len(args) > 1:
					proc = subprocess.Popen(['/usr/bin/timeout', str(timeout)] + comargs.split(' ') + args[1:], stderr=subprocess.STDOUT, stdout=subprocess.PIPE )
					msg = proc.communicate()[0]
					if msg == "":
						sendtext("No response or timeout > " + str(timeout) + "s.")
					else:
						sendtext(msg)
				else:
					sendtext("เบอร์อะไรละคร้าบ ???\n@ dis " + args[0] + " [เบอร์]")
					sendstk('1','100','118')
			else:
				sendtext(args[0] + "เขาสอนผมมาแค่นี้นะ\n" + man_dis)
		else:
			sendtext("คุณคือใคร เราไม่รู้จัก\nไป run ในห้อง group สิ")
	except:
		pass
	return

# Function command display SET
def comset(cmd):
	try:
		#proxy_support = urllib2.ProxyHandler({"http":"http://proxy.true.th:80"})
		#opener = urllib2.build_opener(proxy_support)
		#urllib2.install_opener(opener)
		html = urllib2.urlopen("http://203.150.227.51/C04_01_stock_quote_p1.jsp?txtSymbol=" + cmd, timeout = 20)
		soup = BeautifulSoup(html, 'html.parser')
		#div = soup.findAll("div", { "class" : "col-xs-12 colorRed" }) + soup.findAll("div", { "class" : "col-xs-12 colorGreen" }) + soup.findAll("div", { "class" : "col-xs-12 colorGray" }) + soup.findAll("h1", { "class" : "colorRed" }) + soup.findAll("h1", { "class" : "colorGreen" }) + soup.findAll("h1", { "class" : "colorGray" }) + soup.findAll("div", { "class" : "col-md-6" })
		div = soup.findAll('h1')
		if len(div) > 1:
			index_price     = div[1].text.strip()
			index_chg       = div[2].text.strip()
			index_perchg    = div[3].text.strip()
			index_preclose  = "0"
			index_open      = "0"
			index_volume    = "0"
			index_value     = "0"
			index_max       = "0"
			index_min       = "0"
			table = soup.find("div", { "class" : "col-md-7" })
			for row in table.findAll('tr'):
				col = row.findAll('td')
				if len(col) > 1:
					key = col[0].string.strip()
					val = col[1].string.strip()
					if key == "ราคาปิดก่อนหน้า":
						index_preclose = val
					elif key == "ราคาเปิด":
						index_open = val
					elif key == "ปริมาณซื้อขาย (หุ้น)":
						index_volume = val
					elif key == "มูลค่าซื้อขาย ('000 บาท)":
						index_value = val
					elif key == "ราคาสูงสุด":
						index_max = val
					elif key == "ราคาต่ำสุด":
						index_min = val
						
			#msg = cmd.upper() + "\nPrice : " + index_price + "\nChange : " + index_chg + "/" + index_perchg
			msg = cmd.upper() + "\nPrice : " + index_price + "\nChange : " + index_chg + "/" + index_perchg + "\n" + "Max/Min : " + index_max + "/" + index_min + "\nVol : " + index_volume + "\nVal : " + index_value + " K Baht"
			sendtext(msg)
		else:
			sendtext(cmd.upper() + " หุ้นพม่าหรอครับ !!!")
	except Exception as e:
		print "[%s] [Error exception in main thread] %s" % (str(datetime.now()),str(e))
		pass
	return
		
# Function google transalate
def comdic(cmd):
	try:
		#proc = subprocess.Popen(['/usr/bin/timeout', str(timeout)] + ['python','/home/mstm/botline/bot/dictionary.py',cmd], stderr=subprocess.STDOUT, stdout=subprocess.PIPE )
		#msg = proc.communicate()[0]
		msg = ""
		ssh = paramiko.SSHClient()
		ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
		ssh.connect('localhost', username='mstm',password='mstm')
		stdin,stdout,stderr = ssh.exec_command('python /home/mstm/botline/bot/dictionary.py' + ' \"' + cmd + '\"')
		for line in stdout.readlines():
			msg += line.strip() + "\n"
			ssh.close()
		if msg == "":
			sendtext("No response or timeout > " + str(timeout) + "s.")
		else:
			sendtext(msg)
	except:
		raise
	return
		
# Function google image
def compic(cmd):
	try:
		msg = ""
		ssh = paramiko.SSHClient()
		ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
		ssh.connect('localhost', username='mstm',password='mstm')
		stdin,stdout,stderr = ssh.exec_command('python /home/mstm/botline/bot/searchimage.py' + ' \"' + cmd + '\"')
		for line in stdout.readlines():
			msg += line.strip() + "\n"
		ssh.close()
		if msg == "":
			sendtext("No response or timeout > " + str(timeout) + "s.")
		else:
			pic = msg.split('=', 1)
			if len(pic) > 1 and pic[0] == "pic":
				print pic[1][:-1]
				listpic = pic[1][:-1].split(',')
				for image in listpic:
					sendimage(image)
			else:
				sendtext(msg)
	except:
		raise
	return	
		
		
		
# Function bot command
def botcom(msg):
	try:
		com = msg.split(' ', 1 )
		if com[0].lower() == "learn":
			if len(com) > 1:
				updateQA(com[1])
			else:
				sendtext(botcall + " learn [ถาม] [ตอบ]")
		elif com[0].lower() == "dis":
			if len(com) > 1:
				comdis(com[1])
			else:
				sendtext(man_dis)
		elif com[0].lower() == "run":
			if len(com) > 1:
				comrun(com[1])
			else:
				sendtext(man_run)
		elif com[0].lower() == "ccp":
			if len(com) > 1:
				comccp(com[1])
			else:
				sendtext(man_ccp)
		elif com[0].lower() == "sce":
			if len(com) > 1:
				comsce(com[1])
			else:
				sendtext(man_sce)
		elif com[0].lower() == "graph":
			if len(com) > 1:
				comgraph(com[1])
			else:
				sendtext(man_graph)
		elif com[0].lower() == "pic":
			if len(com) > 1:
				compic(com[1])
			else:
				sendtext("@ pic <name>")
		elif com[0].lower() == "set":
			if len(com) > 1:
				comset(com[1])
			else:
				sendtext("@ set <name>")
		elif com[0].lower() == "dic":
			if len(com) > 1:
				comdic(com[1])
			else:
				sendtext("@ dic <word>")
		else:
			sendtext("@ learn [ถาม] [ตอบ]\n@ set [หุ้น]\n@ dic [คำศัพท์]\n@ pic [ชื่อ]\n@ dis [อุปกรณ์] [เบอร์]\n@ run [คำสั่ง]\n@ graph [คำสั่ง]")
	except:
		raise
	return

#-------------------------------------------------------------------------------
#     I N I T I A L    P R O G R A M
#-------------------------------------------------------------------------------

dic_qa   = loaderQA()
dic_dis  = dicloader(f_dis)
dic_run  = dicloader(f_run)
dic_ccp  = dicloader(f_ccp)
dic_sce  = dicloader(f_sce)
dic_graph  = dicloader(f_graph)
dic_orun = dicloader(u_run)
dic_odis = dicloader(u_dis)
dic_occp = dicloader(u_ccp)
dic_osce = dicloader(u_sce)
lst_com  = ["learn","dis","run","ccp","sce","graph","set","dic","pic"]
man_dis   = ""
man_run   = ""
man_ccp   = ""
man_sce   = ""
man_pic   = ""
man_graph = ""

for k in sorted(dic_dis.keys()):
	man_dis += "\n@ dis "
	man_dis += k

for k in sorted(dic_run.keys()):
	man_run += "\n@ run "
	man_run += k

for k in sorted(dic_ccp.keys()):
	man_ccp += "\n@ ccp "
	man_ccp += k

for k in sorted(dic_sce.keys()):
	man_sce += "\n@ sce "
	man_sce += k

for k in sorted(dic_graph.keys()):
	man_graph += "\n@ graph "
	man_graph += k
	
while True:
	try:
		print "[%s] [Login] [%s] - Start login line client" % (str(datetime.now()), botname)
		client = LineClient(botuser, botpass,authToken=None,is_mac=False,com_name=botlog,bypass=True)
		print "[%s] [Login] [%s] - Login Success" % (str(datetime.now()), botname)
		authToken = client.authToken
		print "[%s] [Login] [%s] - Authen Token=%s" % (str(datetime.now()), botname, authToken)
	except Exception as e:
		print "[%s] [Login] [%s] - Login Fail" % (str(datetime.now()), botname)
		print "[%s] [Error exception in main thread] %s" % (str(datetime.now()),str(e))
		time.sleep(random.randrange(10,15))
		continue
	break

#-------------------------------------------------------------------------------
#     M A I N    P R O G R A M
#-------------------------------------------------------------------------------

while True:
	time.sleep(random.randrange(3,5))
	op_list = []
	op_count = 0
	dic_dis  = dicloader(f_dis)
	dic_run  = dicloader(f_run)
	dic_ccp  = dicloader(f_ccp)
	dic_sce  = dicloader(f_sce)
	dic_graph  = dicloader(f_graph)
	dic_orun = dicloader(u_run)
	dic_odis = dicloader(u_dis)
	dic_occp = dicloader(u_ccp)
	dic_osce = dicloader(u_sce)
	try:
		for op in client.longPoll(debug=True):
			op_list.append(op)
			op_count += 1
		
		for op in op_list:
			sender   = op[0]
			receiver = op[1]
			msg      = op[2].text
			contype  = op[2].contentType
			
			print "[%s] [ContentType : %s] [%s->%s] : %s" % (str(datetime.now()), contype, sender.name, receiver.name, msg)
			
			if contype == 0 and chkcall(msg):
				if op_count > maxread:
					warnflood()
				else:
					msg = msg[len(msg.split(' ', 1)[0])+1:]
					com = msg.split(' ', 1 )
					if len(msg) == 0:
						sendtext("@ learn [ถาม] [ตอบ]\n@ set [หุ้น]\n@ dic [คำศัพท์]\n@ pic [ชื่อ]\n@ dis [อุปกรณ์] [เบอร์]\n@ run [คำสั่ง]\n@ graph [คำสั่ง]")
					elif com[0].lower() in lst_com:
						botcom(msg)
					elif msg in dic_qa:
						sendtext(dic_qa[msg])
					else:
						sendtext("@ learn [ถาม] [ตอบ]\n@ set [หุ้น]\n@ dic [คำศัพท์]\n@ pic [ชื่อ]\n@ dis [อุปกรณ์] [เบอร์]\n@ run [คำสั่ง]\n@ graph [คำสั่ง]")
				
	except Exception as e:
		print "[%s] [Error exception in main thread] %s" % (str(datetime.now()),str(e))
		#linelogin()
		time.sleep(random.randrange(3,5))
		pass
		#raise
