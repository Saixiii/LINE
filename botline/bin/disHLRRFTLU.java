import java.io.*;
import java.net.*;
import java.lang.*;

/**
 *This class demonstrates the engine method to display on HLR-RMV
 *@author Suphakit Annoppornchai
 *@version 1.0
 *@since 10/05/2014
 *@return ISDN,IMSI,HLRSN,CardType,NAM,CATEGORY,ODBOC,ODBROAM,ODBRCF
 */
 
public class disHLRRFTLU {
	
	
	private static String host = "10.80.118.108";
	private static int port = 7776;
	private static String user = "rftHLR";
	private static String pass = "rftHLR01";
	
	// Define field query parameter
	private static String field[] = {"IMSI","VlrNum","CSUPLTIME","CSPURGETIME","MsPurgedForNonGprs","SgsnNum","PSUPLTIME","PSPURGETIME","MsPurgedForGprs","MMEHOST","PURGEDONMME","MME-UpdateLocation-Time","IMEI"};
	
	
	// Usage java
	public static void Usage() {
		System.out.println("Usage: dis hlrrft 66XXXXXXXX");
		System.exit(0);
	}
	
	
	// HLR MML API display
	public static String MMLdisplay (BufferedReader mslist) {
		
		String login = "-1";
		
		try {
			
			// Socket HLR-RMV engine.
			Socket sock = new Socket(host, port);
			sock.setSoTimeout(10000);
			
			BufferedWriter wr = new BufferedWriter(new OutputStreamWriter(sock.getOutputStream(),"UTF-8"));
			BufferedReader rd = new BufferedReader(new InputStreamReader(sock.getInputStream()));
			
			// MML login
			wr.write("LGI: OPNAME=\"" + user + "\", PWD=\"" + pass + "\";\r\n");
			wr.flush();
			Thread.sleep(2000);
			
			String line;
			String msisdn;
			
			// Result login
			while(!(line=rd.readLine()).startsWith("---")) {
				if(line.startsWith("RETCODE")) {
					String splitlogin[] = line.split("\\s");
					login = splitlogin[2];
				}
			}
			
			// Display list msisdn 
			if(login.equals("0")) {
				
				// Loop display msisdn list
				while ((msisdn = mslist.readLine())!= null) {
					
					// MML display
					wr.write("LST DYNSUB: ISDN=\"" + msisdn + "\";\r\n");
					wr.flush();
					
					String data[] = new String[field.length];
					String discode = "-1";
					String disdesc = "null";
					String ucstype = "0";
					String ucsname = "null";
					String ocstype = "0";
					String ocsname = "null";
					
					// Read output data
					while(!(line=rd.readLine()).startsWith("---")) {
						
						// Read display result
						if(line.startsWith("RETCODE")) {
							String splitdiscode[] = line.split("\\s");
							String splitdisdesc[] = line.split("=");
							discode = splitdiscode[2];
							disdesc = splitdisdesc[1];
						}
						
						// Read display data
						String strline = line.replaceAll("\\s","");
						for(int i=0; i<field.length; i++) {
							if(strline.startsWith(field[i] + "="))
								data[i] = strline.split("=")[1];
						}
						
					
					/*
						// Read OCS chain id
						if(strline.startsWith("\"U-CSI\"")) {
							ucstype = "1";
						}
						if((ucstype.equals("1")) && (strline.startsWith("TPLNAME"))) {
							ucsname = strline.split("=")[1];
							ucstype = "0";
						}
						if(strline.startsWith("\"O-CSI\"")) {
							ocstype = "1";
						}
						if((ocstype.equals("1")) && (strline.startsWith("TPLNAME"))) {
							ocsname = strline.split("=")[1];
							ocstype = "0";
						}*/
						
					}
					
					// Print display data
					System.out.println("[Msisdn]: " + msisdn);
					if(discode.equals("0")) {
						for(int i=0; i<data.length; i++) {
							System.out.println("[" + field[i] + "]: " + data[i]);
						}
						//System.out.println("[U-CSI]: " + ucsname);
						//System.out.println("[O-CSI]: " + ocsname);
					} else {
						System.out.println(" " + disdesc);
					}
				}
			} else {
				System.out.println(line);
				System.exit(0);
			}
			
			// MML logoff
			wr.write("LGO:;\r\n");
			wr.flush();
			wr.write("exit;");
			wr.flush();
			
			// Close buffer
			wr.close();
			rd.close();
			
			return login;
			
		} catch (Exception e) {
			e.printStackTrace();
			return login;
		}
		
	}
		
		
	public static void main(String[] args) {
		
		// Check input data
		if (args.length != 1) {
			Usage();
		}
		
		String result = "";
		
		try {
			
			// Check display condition Single or Batch
			if(args[0].length() == 11) {
				BufferedReader br = new BufferedReader(new StringReader(args[0]));
				result = MMLdisplay(br);
			} else
				Usage();
			
		} catch (Exception e) {
			e.printStackTrace();
		}
	}
}
