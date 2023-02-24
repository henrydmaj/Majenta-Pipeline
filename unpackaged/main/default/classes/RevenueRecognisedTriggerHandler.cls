public with sharing class RevenueRecognisedTriggerHandler {

    private boolean m_isExecuting = false;
    private integer BatchSize = 0;
        
    public RevenueRecognisedTriggerHandler(boolean isExecuting, integer size){
        m_isExecuting = isExecuting;
        BatchSize = size;
    }
    
    globalTargetMethods.TargetMethods target = new globalTargetMethods.TargetMethods();
    
    public void OnBeforeInsert(Revenue__c[] newRevs){
    }
    
    public void OnAfterInsert(Revenue__c[] newRevs){
        target.updateTarget(target.getTargetIds(newRevs), 'Revenue__c');
    }
    
    //@future public static void OnAfterInsertAsync(Set<ID> newRevIDs){
    //}
    
    public void OnBeforeUpdate(Revenue__c[] oldRevs,Revenue__c[] updatedRevs, Map<ID, Revenue__c> RevMap){   
    }
    
    public void OnAfterUpdate(Revenue__c[] oldRevs, Revenue__c[] updatedRevs, Map<ID, Revenue__c> RevMap){
        target.updateTarget(target.getTargetIds(updatedRevs), 'Revenue__c');
    }
    
    //@future public static void OnAfterUpdateAsync(Set<ID> updatedRevIDs){
    //}
    
    public void OnBeforeDelete(Revenue__c[] RevsToDelete, Map<ID, Revenue__c> RevMap){
    }
    
    public void OnAfterDelete(Revenue__c[] deletedRevs, Map<ID, Revenue__c> RevMap){
        target.updateTarget(target.getTargetIds(deletedRevs), 'Revenue__c');
    }
    
    //@future public static void OnAfterDeleteAsync(Set<ID> deletedRevIDs){
    //}
    
    public void OnUndelete(Revenue__c[] restoredRevs){
        target.updateTarget(target.getTargetIds(restoredRevs), 'Revenue__c');
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