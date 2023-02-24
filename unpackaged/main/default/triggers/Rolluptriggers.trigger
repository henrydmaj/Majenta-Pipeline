trigger Rolluptriggers on Account (after insert, after update, after delete , after Undelete) {
        
    if((trigger.isAfter && Trigger.isInsert) || (trigger.isAfter && Trigger.isUndelete) ){
        	numberOfSiteAccounts.rollUpSiteAccounts(trigger.new, null);
       }
    
    if(Trigger.isDelete && Trigger.isAfter){
        	numberOfSiteAccounts.rollUpExisitngAccounts(trigger.old);
        }
    
    if(trigger.isAfter && Trigger.isUpdate){
        numberOfSiteAccounts.rollUpSiteAccounts(trigger.new, trigger.oldMap);
    }
   }