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
 *This class demonstrates the engine method to display on CCP
 *@author Suphakit Annoppornchai
 *@version 1.0
 *@since 14/05/2014
 *@return 
 */
 
public class disCCP7 { 
	
	// CCP8 - 10.95.78.16
	// CCP7 - 10.95.84.135
	// CCP1 - 10.80.65.33
	// CCP2 - 10.80.193.33
	
	
	private static String host = "10.95.84.135";
	private static int port = 8090;
	private static String user = "INOPS";
	private static String pass = "SPONI";
	
	// Define field query parameter
	private static String field[] = {"IMSI","ICCID","PricePlanCode","State","Balance","EffDate","ExpDate","DefLang","GPRSChargeFlag","CustType","RefillAble","ProductCode","ProductName","RefillErrorTimes","ActiveStopDate","CompletedDate","DisableStopDate","ServiceStopDate","SuspendStopDate","StateSet","LowerThreshold","MaxPerRefill"};
	private static String ret[] = {"ReturnCode","ReturnDesc","ErrorCode","ErrorDesc"};
	
	public static void Usage() {
		System.out.println("Usage: dis ccp7 66XXXXXXXXX");
		System.exit(0);
	}
	
	
	// Get return code & return desc
	public static String[] SOAPresult(Document doc) throws JaxenException {
		
		String[] res = new String[ret.length];
		
		for(int i=0; i<ret.length; i++) {
			XPath xpathcode = new Dom4jXPath("//*[name()='ret:" + ret[i] + "']");
			res[i] = String.valueOf(((org.dom4j.Element) xpathcode.selectSingleNode(doc)).getData());
		}
		
		return res;
		
	}
	
	
	// Get display data
	public static String[] SOAPdata(Document doc) throws JaxenException {
		
		String[] data = new String[field.length];
		
		XPath xpath = new Dom4jXPath("//*[name()='queryUserProfileReturn']/child::* | //*[name()='AcctResCode' and text()='0']/following-sibling::*");
		
		List<Element> results = xpath.selectNodes(doc);
		
		for (Element element : results) {
			for(int i=0; i<field.length; i++) {
				if(field[i].equals(String.valueOf(element.getName()))) {
					data[i] = "[" + field[i] + "]: " + String.valueOf(element.getData());
				}
			} 
		}
		
		return data;
	}
	
	
	// Socket CCP engine.
	public static String SOAPdisplay (String msisdn) {
		
		String ans = "[MSISDN]: " + msisdn;
		
		try {
			
			Socket sock = new Socket(host, port);
			BufferedWriter wr = new BufferedWriter(new OutputStreamWriter(sock.getOutputStream(),"UTF-8"));
			BufferedReader rd = new BufferedReader(new InputStreamReader(sock.getInputStream()));
			
			sock.setSoTimeout(10000);
			
			String path = "http://" + host + ":" + port + "/ocswebservices/services/TrueWebServices";
			
			// SOAP Display Command
			String cmd = "<soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:tha=\"http://thaitrue.customization.ws.bss.zsmart.ztesoft.com\"> lns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:tha=\"http://thaitrue.customization.ws.bss.zsmart.ztesoft.com\">" +
			"<soapenv:Header>" +
			"<AuthHeader>" +
			"<username>" + user + "</username>" +
			"<password>" + pass + "</password>" +
			"</AuthHeader>" +
			"</soapenv:Header>" +
			"<soapenv:Body>" +
			"<tha:queryUserProfile>" +
			"<tha:QueryUserProfileReqDto>" +
			"<tha:MSISDN>" + msisdn + "</tha:MSISDN>" +
			"<tha:UserPwd></tha:UserPwd>" +
			"<tha:RequestID>INOPS0000000</tha:RequestID>" +
			"</tha:QueryUserProfileReqDto>" +
			"</tha:queryUserProfile>" +
			"</soapenv:Body>" +
			"</soapenv:Envelope>";
			
			
			// SOAP Binding Header
			wr.write("POST " + path + " HTTP/1.1\r\n");
			wr.write("SOAPAction: \"\"\r\n");
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
				for(int i=0; i<ret.length; i++) {
					ans = ans + "\r\n[" + ret[i] + "]: " + res[i];
				}
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
