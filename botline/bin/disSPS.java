import java.lang.*;
import java.io.*;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Properties;

import javax.naming.Context;
import javax.naming.NamingEnumeration;
import javax.naming.NamingException;
import javax.naming.directory.Attribute;
import javax.naming.directory.Attributes;
import javax.naming.directory.DirContext;
import javax.naming.directory.InitialDirContext;
import javax.naming.directory.SearchControls;
import javax.naming.directory.SearchResult;
 

public class disSPS {
 
   private static final String CONT_FACTORY = "com.sun.jndi.ldap.LdapCtxFactory";
   private static final String SE_AUTHEN = "simple";
   private static final String PROVIDER_URL = "LDAP://10.80.193.21:389";
   private static final String SE_PRINCIPAL = "rmvdmp";
   private static final String SE_CREDENTIALS = "rmvdmp_RFT";
   
   
   public static void Usage() {
   	 System.out.println("Usage: dis sps 66XXXXXXXXX");
   	 System.exit(0);
   }
    
   public static void Search(String msisdn) {
   	
      //Attr for query
      String[] seekAttrs = null;
      //Create search
      SearchControls searchCtl = new SearchControls();
      searchCtl.setSearchScope(SearchControls.SUBTREE_SCOPE);
      searchCtl.setReturningAttributes(seekAttrs);
       
      //The name of the context or object to search
      String name = "msisdn=" + msisdn + ",domainName=mnp,O=True,C=TH";
      //Filter cn start with TA
      String filter = "(objectclass=*)";
      HashMap cusattr = new HashMap();
      NamingEnumeration namingEnum = null;
      DirContext dirCtx = null;
      try {
         dirCtx = getDirContext(); 
         namingEnum = dirCtx.search(name, filter , searchCtl);
         //namingEnum = dirCtx.search(name, filter, null); 
         while (namingEnum.hasMore()) {
            SearchResult searchRs = (SearchResult) namingEnum.next();
            //System.out.println(searchRs.toString()+"\n");
            Attributes attrs = searchRs.getAttributes();                     
            //System.out.println("Name : " + searchRs.getName());
             
            NamingEnumeration namingAttr = attrs.getAll();
            while (namingAttr.hasMoreElements()) {
               Attribute attr = (Attribute) namingAttr.next();
               //System.out.println(attr.getID() + ": " + attr.get(0));
               if(cusattr.get(attr.getID()) == null)
               	 cusattr.put(attr.getID() , attr.get(0));
               else
                 cusattr.put(attr.getID() , cusattr.get(attr.getID()) + "|" + attr.get(0));         
            }
         }
         namingEnum.close();
         dirCtx.close();
         System.out.println("[MSISDN]: " + cusattr.get("msisdn"));
         System.out.println("[objectClass]: " + cusattr.get("objectClass"));
         System.out.println("[portingStatus]: " + cusattr.get("portingStatus"));
         System.out.println("[routingCode]: " + cusattr.get("routingCode"));
         System.out.println("[routingNumber]: " + cusattr.get("routingNumber"));
      } catch (NamingException ne) {
      	 System.out.println(msisdn + " not found in SPS");
         //ne.printStackTrace();
      } catch (Exception e){
         e.printStackTrace();
      }finally{
         if (dirCtx != null) {
            try{
                dirCtx.close();
            }catch (NamingException e){}
         }
         if(namingEnum != null){
            try{
               namingEnum.close();
               namingEnum = null;
            }catch (NamingException e){}
         }
      }
   }
    
   private static DirContext getDirContext() throws NamingException {
      Properties pros = new Properties();
      DirContext dirCtx = null;
      try {
         pros.setProperty(Context.INITIAL_CONTEXT_FACTORY, CONT_FACTORY);
         pros.setProperty(Context.SECURITY_AUTHENTICATION, SE_AUTHEN);
         pros.setProperty(Context.PROVIDER_URL, PROVIDER_URL);
         pros.setProperty(Context.SECURITY_PRINCIPAL, SE_PRINCIPAL);
         pros.setProperty(Context.SECURITY_CREDENTIALS, SE_CREDENTIALS);
         //Optional
         pros.setProperty("com.sun.jndi.ldap.connect.pool", "true");
         pros.setProperty("com.sun.jndi.ldap.connect.pool.initsize", "10");
         pros.setProperty("com.sun.jndi.ldap.connect.pool.maxsize", "100");
         pros.setProperty("com.sun.jndi.ldap.connect.pool.prefsize", "25");
 
         dirCtx = new InitialDirContext(pros);
      } catch (NamingException ne) {
         //Handle exception
      } catch (Exception e) {
         //Handle exception
      }
 
      return dirCtx;
   }
   
   public static void main(String[] args) {
   	
   try {
   	if (args.length != 1) {
   		Usage();
   	}
   	
   	if(args[0].startsWith("66")) {
    	  Search(args[0]);
    } else
    	  Usage();
    } catch (Exception e) {
			e.printStackTrace();
		}
   }
}
