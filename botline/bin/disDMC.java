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
 
public class disDMC {
	
	
	private static String host = "10.4.85.137";
	private static int port = 80;
	
	// Define field query parameter
	private static String field[] = {"imsi","priceplan","sub_type","bill_cycle","status","charge_type","pref_language","sub_cat","gprs_usage","billing_plan","sso_sub","migrate_date","user_wifi","ac_pass","domain","wifi_status","wifi_concurrent"};
	private static String ret[] = {"result_code","result_description"};
	
	public static void Usage() {
		System.out.println("Usage: dis dmc 66XXXXXXXXX");
		System.exit(0);
	}
	
	
	// Get return code & return desc
	public static String[] SOAPresult(Document doc) throws JaxenException {
		
		String[] res = new String[ret.length];
		
		for(int i=0; i<ret.length; i++) {
			XPath xpathcode = new Dom4jXPath("//*[name()='" + ret[i] + "']");
			res[i] = String.valueOf(((org.dom4j.Element) xpathcode.selectSingleNode(doc)).getData());
		}
		
		return res;
		
	}
	
	
	// Get display data
	public static String[] SOAPdata(Document doc) throws JaxenException {
		
		String[] data = new String[field.length];
		
		XPath xpath = new Dom4jXPath("//dmc_response/*");
		
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
	
	
	public static String SOAPxml(String msisdn) {
		
		String cmd = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" +
		"<dmc_request>" +
		"<command>get_customer_info</command>" +
		"<transaction_id>12345</transaction_id>" +
		"<msisdn>" + msisdn + "</msisdn>" +
		"<channel>E2E</channel>" +
		"</dmc_request>";
		
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
			
			String path = "/dmc_mobile_e2e/get_response.php";
			
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
