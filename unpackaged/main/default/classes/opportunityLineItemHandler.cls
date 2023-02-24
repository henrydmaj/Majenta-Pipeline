public class opportunityLineItemHandler{
    
    public static void copyNumberOfSites(list<OpportunityLineItem> OLIlist){
        list<opportunity> opplist = new list<opportunity>();
        map<id,opportunity> oppmap = new map<id,opportunity>();
         
        try{
            for(OpportunityLineItem oli : OLIlist){
                opportunity opp = [select id, Number_of_sites__c,Name from opportunity where ID =: oli.OpportunityID ] ; 
                Product2 pro = [select id,Name,Productcode from Product2 where ID =: oli.Product2Id];
                if(pro.Productcode.contains('ENJ')){
                    string s1 = pro.Name.replaceAll('[^0-9]','');
                    opp.Number_of_sites__c = Decimal.valueOf(s1);
                }
                opplist.add(opp);
                oppmap.putall(opplist);
                
                
                if(oppmap.size()>0){
                    update oppmap.values();
                }
            } 
        }
        catch(exception ex){
            system.debug('ex'+ ex);
        }  
    }
    
    
    public static void deleteCopyNumberOfSites(list<OpportunityLineItem> OLIlist){
        list<opportunity> opplist = new list<opportunity>();
        
        try{
            for(OpportunityLineItem oli : OLIlist){
                opportunity opp = [select id, Number_of_sites__c,Name from opportunity where ID =: oli.OpportunityID ] ;
                Product2 pro = [select id,Name from Product2 where Name LIKE '%JLR - enerjyhub%' AND ID =: oli.Product2Id];
                opp.Number_of_sites__c = NULL;
                opplist.add(opp);
                
            }
            update opplist;
            
        }catch(exception ex){
            system.debug('ex'+ ex);
        }  
        
        
    }
    
    
}