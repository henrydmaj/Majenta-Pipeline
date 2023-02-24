public with sharing class PurchaseOrderTriggerHandler {
    private boolean m_isExecuting = false;
    private integer BatchSize = 0;
    
    public PurchaseOrderTriggerHandler(boolean isExecuting, integer size){
        m_isExecuting = isExecuting;
        BatchSize = size;
    }
        
    public void OnBeforeInsert(PurchaseOrder__c[] newPurchaseOrders){

    }
    
    public void OnAfterInsert(PurchaseOrder__c[] newPurchaseOrders){

    }
    
    //@future public static void OnAfterInsertAsync(Set<ID> newPurchaseOrderIDs){
    //}
    
    public void OnBeforeUpdate(PurchaseOrder__c[] oldPurchaseOrders, PurchaseOrder__c[] updatedPurchaseOrders, Map<ID, PurchaseOrder__c> purchaseOrderMap){

    }
    
    public void OnAfterUpdate(PurchaseOrder__c[] oldPurchaseOrders, PurchaseOrder__c[] updatedPurchaseOrders, Map<ID, PurchaseOrder__c> purchaseOrderMap){

        for(PurchaseOrder__c oldPO : oldPurchaseOrders){
            PurchaseOrder__c updPO = purchaseOrderMap.get(oldPO.id);

            if(updPO.CurrencyIsoCode != oldPO.CurrencyIsoCode){
                System.Debug('CurrencyIsoCode changed:' + updPO.CurrencyIsoCode + ' to ' + oldPO.CurrencyIsoCode);
                // List of PurchaseOrder Line Items related to the current PurchaseOrder
                List<PurchaseOrderLineItem__c> poLIs = new List<PurchaseOrderLineItem__c>([SELECT li.Id,
                                                                                       li.CurrencyIsoCode FROM PurchaseOrderLineItem__c li 
                                                                                       WHERE li.PurchaseOrder__c =:updPO.Id]);

                for(PurchaseOrderLineItem__c poLI : poLIs)
                    poLI.CurrencyIsoCode = updPO.CurrencyIsoCode;

                update poLIs;
            }

        }
    
    }
    
    //@future public static void OnAfterUpdateAsync(Set<ID> updatedPurchaseOrderIDs){
    //}
    
    //public void OnBeforeDelete(PurchaseOrder__c[] purchaseOrdersToDelete, Map<ID, PurchaseOrder__c> purchaseOrderMap){     
    //}
    
    //public void OnAfterDelete(PurchaseOrder__c[] deletedPurchaseOrders, Map<ID, PurchaseOrder__c> purchaseOrderMap){ 
    //}
    
    //@future public static void OnAfterDeleteAsync(Set<ID> deletedPurchaseOrderIDs){
    //}
    
    //public void OnUndelete(PurchaseOrder__c[] restoredPurchaseOrders){
    //}
    
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