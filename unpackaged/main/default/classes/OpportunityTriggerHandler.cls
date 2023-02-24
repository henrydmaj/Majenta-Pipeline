public with sharing class OpportunityTriggerHandler {

    private boolean m_isExecuting = false;
    private integer BatchSize = 0;
        
    public OpportunityTriggerHandler(boolean isExecuting, integer size){
        m_isExecuting = isExecuting;
        BatchSize = size;
    }
    
    globalTargetMethods.TargetMethods target = new globalTargetMethods.TargetMethods();
              
    public void OnBeforeInsert(Opportunity[] newOpps){
    
        Map<Id, Id> targetMap = target.getTargetMap(newOpps);
    
        for(Opportunity newOpp : newOpps){
            if(targetMap.containsKey(newOpp.Id) && !newOpp.TargetExcluded__c)
                newOpp.Target__c = targetMap.get(newOpp.Id);
        }
        
    }
    
    public void OnAfterInsert(Opportunity[] newOpps){
        target.updateTarget(target.getTargetIds(newOpps), 'Opportunity');
    }
    
    //@future public static void OnAfterInsertAsync(Set<ID> newOppIDs){
    //}
    
    public void OnBeforeUpdate(Opportunity[] oldOpps,Opportunity[] updatedOpps, Map<ID, Opportunity> OppMap){
    
        Map<Id, Id> targetMap = target.getTargetMap(updatedOpps);
    
        for(Opportunity updatedOpp : updatedOpps){
            if(targetMap.containsKey(updatedOpp.Id) && !updatedOpp.TargetExcluded__c)
                updatedOpp.Target__c = targetMap.get(updatedOpp.Id);
            else
                updatedOpp.Target__c = null;
        }
    
    }
    
    public void OnAfterUpdate(Opportunity[] oldOpps, Opportunity[] updatedOpps, Map<ID,  Opportunity> OppMap){
        
        Set<Id> targetIds = new Set<Id>();
        
        for(Opportunity oldOpp : oldOpps){
            Opportunity updatedOpp = OppMap.get(oldOpp.id);
            
            if( updatedOpp.Probability    != oldOpp.Probability ||
                updatedOpp.Amount         != oldOpp.Amount ||
                updatedOpp.Margin_Calc__c != oldOpp.Margin_Calc__c ||
                updatedOpp.Target__c      != oldOpp.Target__c ){
                
                //add both old and updated target ids incase they are different
                if(oldOpp.Target__c != null) {
                    targetIds.add(oldOpp.Target__c);
                }
                    
                if(updatedOpp.Target__c != null) {
                    targetIds.add(updatedOpp.Target__c);
                }
            }
        }
        
        target.updateTarget(targetIds, 'Opportunity');
    }
    
    //@future public static void OnAfterUpdateAsync(Set<ID> updatedTaskIDs){
    //}
    
    public void OnBeforeDelete(Opportunity[] OppsToDelete, Map<ID, Opportunity> OppMap){
    }
    
    public void OnAfterDelete(Opportunity[] deletedOpps, Map<ID, Opportunity> OppMap){
        target.updateTarget(target.getTargetIds(deletedOpps), 'Opportunity');
    }
    
    //@future public static void OnAfterDeleteAsync(Set<ID> deletedTaskIDs){
    //}
    
    public void OnUndelete(Opportunity[] restoredOpps){
        target.updateTarget(target.getTargetIds(restoredOpps), 'Opportunity');
    }
    
    public boolean IsTriggerContext{
        get{ return m_isExecuting;}
    }
    
    public boolean IsVisualforcePageContext{
        get{ return !IsTriggerContext;}
    }
    
    public boolean IsWebServiceContext{
        get{ return !IsTriggerContext;}
    }
    
    public boolean IsExecuteAnonymousContext{
        get{ return !IsTriggerContext;}
    }
}