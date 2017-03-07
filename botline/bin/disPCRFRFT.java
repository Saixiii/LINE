import java.io.*;
import java.net.*;
import java.lang.*;
import java.util.*;
import org.dom4j.Document;
import org.dom4j.DocumentException;
import org.dom4j.Element;
import org.dom4j.io.SAXReader;
import org.jaxen.XPath;
import org.jaxen.dom4j.Dom4jXPath;
import org.jaxen.JaxenException;
import javax.net.*;
import javax.net.ssl.SSLSocket;
import javax.net.ssl.SSLSocketFactory;

/**
 *This class demonstrates the engine method to display on PCRF
 *@author Suphakit Annoppornchai
 *@version 1.0
 *@since 18/05/2014
 *@return 
 */
 
public class disPCRFRFT {
	
	// PCRF RMV - 10.95.234.36
	// PCRF RFT - 10.80.75.50
	
	private static String host = "10.80.75.50";
	private static int port = 8080;
	private static int delay = 10;
	private static String ROOT_PATH = "/home/mstm/script/java/PCRF_KEYSTORE/";
	private static String STORE_FILE = "UPCC_client.store";
	
	
	
	// Define fieldmono query parameter
	private static String fieldmono[] = {"USRIDENTIFIER","USRMSISDN","USRSTATE","USRPAIDTYPE","USRBILLCYCLEDATE",
		"USRSTATION","USRCONTACTMETHOD","USRCREATETYPE","USRMAXOFFLINEDAYS","USRLATESTOFFLINETIME","USRSUBNETTYPE",
		"USRCUSTOMERATTR","USRLANGUAGE"};
		
	private static String fieldmulti[] = {"SRVPKGNAME","SRVNAME"};
	
	
	// Usage
	public static void Usage() {
		System.out.println("Usage: dis pcrfrmv 668XXXXXXXX");
		System.exit(0);
	}
	
	
	// System load ssl the file of certificate
	public static void loadKeyAndTrustStore() {
		
		try {
			
			// Load Key store
			System.setProperty("javax.net.ssl.keyStore", ROOT_PATH + STORE_FILE);
			System.setProperty("javax.net.ssl.keyStorePassword", "123456");
			
			// TrustStore
			System.setProperty("javax.net.ssl.trustStore", ROOT_PATH + STORE_FILE);
			System.setProperty("javax.net.ssl.trustStorePassword", "123456");
			
			
		} catch (Exception e) {
			e.printStackTrace();
		}
	}
	
	
	// Get return code & return desc
	public static String[] SOAPresult(Document doc) throws JaxenException {
		
		String[] res = new String[2];
		
		XPath xpathcode = new Dom4jXPath("//*[name()='resultCode']");
		res[0] = String.valueOf(((org.dom4j.Element) xpathcode.selectSingleNode(doc)).getData());
		
		XPath xpathdesc = new Dom4jXPath("//*[name()='key' and text()='errorDescription']/following-sibling::*[name()='value' and position()=1]");
		res[1] = String.valueOf(((org.dom4j.Element) xpathdesc.selectSingleNode(doc)).getData());
		
		return res;
		
	}
	
	
	// Get display data
	public static String[] SOAPdata(Document doc) throws JaxenException {
		
		String[] data = new String[fieldmono.length + fieldmulti.length];
		
		for (int i=0; i<fieldmono.length; i++) {
			XPath xpath = new Dom4jXPath("//*[name()='key' and text()='" + fieldmono[i] + "']/following-sibling::*[name()='value' and position()=1]");
			data[i] = "[" + fieldmono[i] + "]: " + String.valueOf(((org.dom4j.Element) xpath.selectSingleNode(doc)).getData());
		}
		
		XPath xpathpackage = new Dom4jXPath("//*[name()='servicePackage']/attribute/*[name()='key' and text()='SRVPKGNAME']/following-sibling::*[name()='value']");
		List<Element> resultspackage = xpathpackage.selectNodes(doc);
		data[fieldmono.length] = "[SRVPKGNAME]: ";
		for (Element element : resultspackage) {
			data[fieldmono.length] = data[fieldmono.length] + "|" + String.valueOf(element.getData());
		}
		
		XPath xpathservice = new Dom4jXPath("//*[name()='subscribedService']/attribute/*[name()='key' and text()='SRVNAME']/following-sibling::*[name()='value']");
		List<Element> resultservice = xpathservice.selectNodes(doc);
		data[fieldmono.length +1] = "[SRVNAME]: ";
		for (Element element : resultservice) {
			data[fieldmono.length + 1] = data[fieldmono.length + 1] + "|" + String.valueOf(element.getData());
		}
		
		return data;
	}
	
	
	public static String SOAPxml(String msisdn) {
		
		String cmd = "<?xml version=\"1.0\"?>" +
		"<soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:rm=\"rm:soap\">" +
		"<soapenv:Header/>" +
		"<soapenv:Body>" +
		"<rm:getSubscriberAllInf>" +
		"<inPara>" +
		"<subscriber>" +
		"<attribute>" +
		"<key>usrIdentifier</key>" +
		"<value>" + msisdn + "</value>" +
		"</attribute>" +
		"</subscriber>" +
		"</inPara>" +
		"</rm:getSubscriberAllInf>" +
		"</soapenv:Body>" +
		"</soapenv:Envelope>";
		
		return cmd;
		
	}
	
	
	// Socket PCRF engine.
	public static String SOAPdisplay (String msisdn) {
		
		String ans = "[MSISDN]: " + msisdn;
		
		try {
			
			SSLSocketFactory sslsocketfactory = (SSLSocketFactory) SSLSocketFactory.getDefault();
			SSLSocket sock = (SSLSocket) sslsocketfactory.createSocket(host, port);
			
			BufferedWriter wr = new BufferedWriter(new OutputStreamWriter(sock.getOutputStream(),"UTF-8"));
			BufferedReader rd = new BufferedReader(new InputStreamReader(sock.getInputStream()));
			
			sock.setSoTimeout(10000);
			
			String path = "https://" + host + ":" + port + "/axis/services/ScfPccSoapServiceEndpointPort";
			
			// SOAP Display Command
			String cmd = SOAPxml(msisdn);
			
			
			// SOAP Binding Header
			wr.write("POST " + path + " HTTP/1.1\r\n");
			wr.write("SOAPAction: \"\"\r\n");
			wr.write("Connection: close\r\n");
			wr.write("Host: " + host + "\r\n");
			wr.write("Content-Type: text/xml; charset=utf-8\r\n");
			wr.write("Content-Length: " + cmd.length() + "\r\n");
			wr.write("\r\n");
			
			wr.write(cmd);
			wr.flush();
			
			String line;
			StringBuffer sb = new StringBuffer();
			
			// SOAP Inspec XML tag
			while((line = rd.readLine()) != null) {
				if(line.startsWith("<")) {
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
				ans = ans + "\r\n[resultCode]: " + res[0];
				ans = ans + "\r\n[resultDes]: " + res[0];
			}
			
			return ans;
			
		} catch (Exception e) {
			e.printStackTrace();
			return ans + "\r\nJava Error";
		}
	}
	
	public static void main(String[] args) {
		
		if (args.length != 1) {
			Usage();
		}
		
		loadKeyAndTrustStore();
		
		try {
			
			if(args[0].length() == 11 ) {
				System.out.println(SOAPdisplay(args[0]));
			} else
				Usage();
			
		} catch (Exception e) {
			e.printStackTrace();
		}
	}
}
