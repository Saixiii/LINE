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
 

public class disCDB {
 
   private static final String CONT_FACTORY = "com.sun.jndi.ldap.LdapCtxFactory";
   private static final String SE_AUTHEN = "simple";
   private static final String PROVIDER_URL = "LDAP://10.95.78.12:16611";
   private static final String SE_PRINCIPAL = "cn=ussdbuffet";
   private static final String SE_CREDENTIALS = "q1w2e3r4";
   
   
   public static void Usage() {
         System.out.println("Usage: dis cdb 66XXXXXXXXX");
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
      String name = "msisdn=" + msisdn + ",domainName=msisdn,O=True,C=TH";
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
         //dirCtx.close();
         System.out.println("[Msisdn]: " + cusattr.get("spMsisdn"));
         System.out.println("[Imsi]: " + cusattr.get("spImsi"));
         System.out.println("[SubStatus]: " + cusattr.get("spSubStatus"));
         System.out.println("[AccountType]: " + cusattr.get("spAccountType"));
         System.out.println("[PricePlan]: " + cusattr.get("spPricePlan"));
         System.out.println("[INChain]: " + cusattr.get("appINChain"));
         System.out.println("[SDP]: " + cusattr.get("appSDP"));
         System.out.println("[INStatus]: " + cusattr.get("appINStatus"));
         System.out.println("[INProfile]: " + cusattr.get("appINProfile"));
         System.out.println("[MobileVas]: " +  cusattr.get("spMobileVas"));
         System.out.println("[Convergence]:  " + cusattr.get("spConvergence"));
         System.out.println("[GPRS]: " +  cusattr.get("gprsType"));
         System.out.println("[APN]: " + cusattr.get("gprsAPNList"));
         System.out.println("[ProvDate]: " + cusattr.get("spProvDate"));
      } catch (NamingException ne) {
         System.out.println(msisdn + " is not found in CDB");
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
