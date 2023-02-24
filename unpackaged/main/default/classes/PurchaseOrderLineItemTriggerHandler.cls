public with sharing class PurchaseOrderLineItemTriggerHandler {
    private boolean m_isExecuting = false;
    private integer BatchSize = 0;
    
    public PurchaseOrderLineItemTriggerHandler(boolean isExecuting, integer size){
        m_isExecuting = isExecuting;
        BatchSize = size;
    }
        
    public void OnBeforeInsert(PurchaseOrderLineItem__c[] newPurchaseOrderLineItems){
            
        Set<Id> PurchaseOrderIds = new Set<Id>();    

        for (PurchaseOrderLineItem__c poLI : newPurchaseOrderLineItems) {
            if (poLI.PurchaseOrder__c != null) {
                PurchaseOrderIds.add(poLI.PurchaseOrder__c);
            }
        }
        
        Map<Id, PurchaseOrder__c> PurchaseOrders = new Map<Id, PurchaseOrder__c>(
            [SELECT Id, CurrencyIsoCode from PurchaseOrder__c WHERE Id IN :PurchaseOrderIds]
        );
        
        for(PurchaseOrderLineItem__c poLI : newPurchaseOrderLineItems){
            PurchaseOrder__c po = PurchaseOrders.get(poLI.PurchaseOrder__c);

            if(po != null && po.CurrencyIsoCode != poLi.CurrencyIsoCode){
                poLi.CurrencyIsoCode = po.CurrencyIsoCode;
            }
        }

    }
    
    public void OnAfterInsert(PurchaseOrderLineItem__c[] newPurchaseOrderLineItems){

    }
    
    //@future public static void OnAfterInsertAsync(Set<ID> newPurchaseOrderLineItemIDs){
    //}
    
    public void OnBeforeUpdate(PurchaseOrderLineItem__c[] oldPurchaseOrderLineItems, PurchaseOrderLineItem__c[] updatedPurchaseOrderLineItems, Map<ID, PurchaseOrderLineItem__c> purchaseOrderLineItemMap){

    }
    
    public void OnAfterUpdate(PurchaseOrderLineItem__c[] oldPurchaseOrderLineItems, PurchaseOrderLineItem__c[] updatedPurchaseOrderLineItems, Map<ID, PurchaseOrderLineItem__c> purchaseOrderLineItemMap){
    
    }
    
    //@future public static void OnAfterUpdateAsync(Set<ID> updatedPurchaseOrderLineItemIDs){
    //}
    
    public void OnBeforeDelete(PurchaseOrderLineItem__c[] purchaseOrderLineItemsToDelete, Map<ID, PurchaseOrderLineItem__c> purchaseOrderLineItemMap){
    
        Set<Id> PurchaseOrderIds = new Set<Id>();    

        for (PurchaseOrderLineItem__c poLI : purchaseOrderLineItemsToDelete) {
            if (poLI.PurchaseOrder__c != null) {
                PurchaseOrderIds.add(poLI.PurchaseOrder__c);
            }
        }
        
        Map<Id, PurchaseOrder__c> PurchaseOrders = new Map<Id, PurchaseOrder__c>(
            [SELECT Id, Ordered__c from PurchaseOrder__c WHERE Id IN :PurchaseOrderIds]
        );
        
        for(PurchaseOrderLineItem__c poLI : purchaseOrderLineItemsToDelete){
            PurchaseOrder__c po = PurchaseOrders.get(poLI.PurchaseOrder__c);

            if(po != null && po.Ordered__c){
                poLI.addError('Cannot delete a Line Item from an Purchase Order that has been Ordered.');
            }
        }
        
    }
    
    public void OnAfterDelete(PurchaseOrderLineItem__c[] deletedPurchaseOrderLineItems, Map<ID, PurchaseOrderLineItem__c> purchaseOrderLineItemMap){
        
    }
    
    //@future public static void OnAfterDeleteAsync(Set<ID> deletedPurchaseOrderLineItemIDs){
    //}
    
    public void OnUndelete(PurchaseOrderLineItem__c[] restoredPurchaseOrderLineItems){
    
        Set<Id> PurchaseOrderIds = new Set<Id>();    

        for (PurchaseOrderLineItem__c poLI : restoredPurchaseOrderLineItems) {
            if (poLI.PurchaseOrder__c != null) {
                PurchaseOrderIds.add(poLI.PurchaseOrder__c);
            }
        }
        
        Map<Id, PurchaseOrder__c> PurchaseOrders = new Map<Id, PurchaseOrder__c>(
            [SELECT Id, Ordered__c from PurchaseOrder__c WHERE Id IN :PurchaseOrderIds]
        );
        
        for(PurchaseOrderLineItem__c poLI : restoredPurchaseOrderLineItems){
            PurchaseOrder__c po = PurchaseOrders.get(poLI.PurchaseOrder__c);

            if(po != null && po.Ordered__c){
                poLI.addError('Cannot undelete a Line Item from an Purchase Order that has been Ordered.');
            }
        }
        
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