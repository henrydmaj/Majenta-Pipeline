Public class numberOfSiteAccounts{
    
    
    public static void rollUpSiteAccounts(list<Account> newacclist, Map<id, Account> oldAccMap){
        
        Set<Id> Ids= new Set<Id>();
        Set<Id> oldIds = new Set<Id>();
        
        for(Account acc: newacclist){
            if(oldAccMap != null){
            if( acc.ParentId!=null && acc.ParentId != oldAccMap.get(acc.id).ParentId){
                Ids.add(oldAccMap.get(acc.Id).ParentId);
            }
        }
            if(acc.ParentId!=null)
                Ids.add(acc.ParentId);
        	}
        
        if (!Ids.isEmpty()) {
            
            List<Account> AccountToUpdate = new List<Account>();
            
            for (AggregateResult ar : [SELECT COUNT(ID),Parentid FROM Account 
                                       WHERE  Parent.Vendor_Master_Code__c != NULL AND Has_subscription__c = true
                                       AND Parent.ActiveSiteAccounts__c != 0 AND ParentID IN :Ids GROUP BY ParentID ]) {
                                           
                                           system.debug('ar@@'+ar);
                                           Id accID = (ID)ar.get('ParentID');
                                           Integer count = (Integer)ar.get('expr0');
                                           Account acc1 = new Account(Id=accID);
                                           acc1.ActiveSiteAccounts__c = count;
                                           AccountToUpdate.add(acc1);
                                       }
            
            
            
            if (!AccountToUpdate.isEmpty()) {
                update AccountToUpdate;
            }    
        } 
    }
    
    public static void rollUpExisitngAccounts(list<account> oldacclist){
        
        Set<Id> Ids= new Set<Id>();
        
        
        for(Account acc: oldacclist){
            
            if(acc.ParentId!=null || acc.Id != NULL)
                Ids.add(acc.ParentId);
        }
        
        if (!Ids.isEmpty()) {
            List<Account> AccountToUpdate = new List<Account>();
            
            for (AggregateResult ar : [SELECT COUNT(ID),Parentid FROM Account 
                                       WHERE  Parent.Vendor_Master_Code__c != NULL AND Has_subscription__c = true
                                       AND ActiveSiteAccounts__c != 0 AND ParentID IN :Ids GROUP BY ParentID ]) {
                                           
                                           Id accID = (ID)ar.get('ParentID');
                                           Integer count = (Integer)ar.get('expr0');
                                           Account acc1 = new Account(Id=accID);
                                           acc1.ActiveSiteAccounts__c = count;
                                           AccountToUpdate.add(acc1);
                              }
                        
            if (!AccountToUpdate.isEmpty()) {
                try{
                    update AccountToUpdate;
                }
                catch(exception e){
                    
                }
            }
        }
    }
}