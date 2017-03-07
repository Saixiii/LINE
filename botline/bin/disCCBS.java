import java.io.*;
import java.net.*;
import java.lang.*;
import java.util.*;
import java.util.Map;
import org.dom4j.Document;
import org.dom4j.DocumentException;
import org.dom4j.Element;
import org.dom4j.io.SAXReader;
import org.jaxen.XPath;
import org.jaxen.dom4j.Dom4jXPath;
import org.jaxen.JaxenException;

/**
 *This class demonstrates the engine method to display on DMC
 *@author Suphakit Annoppornchai
 *@version 1.0
 *@since 14/05/2014
 *@return 
 */
 
public class disCCBS {
	
	
	private static String host = "172.19.136.56";
	private static int port = 80;
	
	// Define field query parameter
	private static String[] ret = {"code","msg"};
	
	public static void Usage() {
		System.out.println("Usage: dis ccbs 0XXXXXXXXX");
		System.exit(0);
	}
	
	
	// Get return code & return desc
	public static String[] SOAPresult(Document doc) throws JaxenException {
		
		String[] res = new String[ret.length];
		
		for(int i=0; i<ret.length; i++) {
			XPath xpathcode = new Dom4jXPath("string(//response/@" + ret[i] + ")");
			res[i] = String.valueOf(xpathcode.selectSingleNode(doc));
		}
		
		return res;
		
	}
	
	
	// Get display data
	public static String[] SOAPdata(Document doc) throws JaxenException {
		
		String field[] = {"sub_status_last_act","sub_status_date","init_activation_date","product_subtype","port_ind","rcp_operator","sub_status_rsn_code","priceplan","pp_desc","total_rc","rc_rate","credit_limit","donor_operator","suspend_type","company_code","type","type_desc","category","status","bill_cycle","customer_no","tao_ban"};
		String name[] = {"name_title","first_name","last_name"};
		String addr[] = {"house_num","moo_ban","street","soi","sub_district","district","city","zip_code"};
		//String addr[] = {"sub_district","district","city","zip_code"};
		
		String data_name = "[Name]:";
		String data_addr = "[Addr]:";
		
		String[] data = new String[field.length + 2];
		
		for(int i=0; i<field.length; i++) {
			if(field[i] == "status") {
				XPath xpathcode = new Dom4jXPath("string(/response/list_of_mobile/mobile/@" + field[i] + ")");
				data[i] = "[" + field[i] + "]: " + String.valueOf(xpathcode.selectSingleNode(doc));
			} else {
				XPath xpathcode = new Dom4jXPath("string(//@" + field[i] + ")");
				data[i] = "[" + field[i] + "]: " + String.valueOf(xpathcode.selectSingleNode(doc));
			}
		}
		
		for(int i=0; i<name.length; i++) {
			XPath xpathcode = new Dom4jXPath("string(//@" + name[i] + ")");
			data_name = data_name + " " + String.valueOf(xpathcode.selectSingleNode(doc));
		}
		data[field.length] = data_name;
		
		for(int i=0; i<addr.length; i++) {
			XPath xpathcode = new Dom4jXPath("string(//@" + addr[i] + ")");
			data_addr = data_addr + " " + String.valueOf(xpathcode.selectSingleNode(doc));
		}
		data[field.length + 1] = data_addr;
		
		return data;
	}
	
	
	public static String SOAPxml(String msisdn) {
		
		String cmd = "<?xml version=\"1.0\"?>" +
		"<request cmd=\"Query\" mobile_no=\"" + msisdn + "\"  limit_result=\"no\"/>";
		
		return cmd;
		
	}
	
	
	
	// Socket DMC engine.
	public static String SOAPdisplay (String msisdn) {
		
		String ans = "[MSISDN]: " + msisdn;
		
		try {
			
			Socket sock = new Socket(host, port);
			BufferedWriter wr = new BufferedWriter(new OutputStreamWriter(sock.getOutputStream(),"UTF-8"));
			BufferedReader rd = new BufferedReader(new InputStreamReader(sock.getInputStream()));
			
			sock.setSoTimeout(10000);
			
			String path = "/TrueMoveCustInfoESB/http/TrueMoveCustInfo/service";
			
			// SOAP Display Command
			String cmd = SOAPxml(msisdn);
			
			
			// SOAP Binding Header
			wr.write("POST " + path + " HTTP/1.1\r\n");
			wr.write("Host: " + host + "\r\n");
			wr.write("Connection: close\r\n");
			wr.write("Content-Type: text/xml; charset=utf-8\r\n");
			wr.write("Content-Length: " + cmd.length() + "\r\n");
			wr.write("\r\n");
			
			wr.write(cmd);
			wr.flush();
			
			String line;
			StringBuffer sb = new StringBuffer();
			
			// SOAP Inspec XML tag
			while((line = rd.readLine()) != null) {
				//System.out.println(line);
				if(line.contains("<")) {
					sb.append(line + "\n");
				}
			}
			
			wr.close();
			rd.close();
			
			
			ByteArrayInputStream bs = new ByteArrayInputStream((sb.toString()).getBytes("utf-8"));
			
			SAXReader reader = new SAXReader();
			Document doc = reader.read(bs);
			
			
			String[] res = SOAPresult(doc);
			if(res[0].equals("0")) {
				String[] data = SOAPdata(doc);
				for(String iter : data) {
					ans = ans + "\r\n" + iter;
				}
			} else {
				for(int i=0; i<ret.length; i++) {
					ans = ans + "\r\n[" + ret[i] + "]: " + res[i];
				}
			}
			
			return ans;
			
		} catch (Exception e) {
			e.printStackTrace();
			return ans + ":-1:Java Error";
		}
	}
	
	public static void main(String[] args) {
		
		if (args.length != 1) {
			Usage();
		}
		
		try {
			
			if(args[0].length() == 10 ) {
				System.out.println(SOAPdisplay(args[0]));
			} else {
				Usage();
			}
			
			
		} catch (Exception e) {
			e.printStackTrace();
		}
	}
}
