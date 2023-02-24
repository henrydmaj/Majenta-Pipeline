public with sharing class CreditNoteLineItemTriggerHandler {
    private boolean m_isExecuting = false;
    private integer BatchSize = 0;
    
    public CreditNoteLineItemTriggerHandler(boolean isExecuting, integer size){
        m_isExecuting = isExecuting;
        BatchSize = size;
    }
        
    public void OnBeforeInsert(CreditNoteLineItem__c[] newCreditNoteLineItems){
            
        Set<Id> CreditNoteIds = new Set<Id>();    

        for (CreditNoteLineItem__c crdLI : newCreditNoteLineItems) {
            if (crdLI.CreditNote__c != null) {
                CreditNoteIds.add(crdLI.CreditNote__c);
            }
        }
        
        Map<Id, CreditNote__c> CreditNotes = new Map<Id, CreditNote__c>(
            [SELECT Id, CurrencyIsoCode from CreditNote__c WHERE Id IN :CreditNoteIds]
        );
        
        for(CreditNoteLineItem__c crdLI : newCreditNoteLineItems){
            CreditNote__c crd = CreditNotes.get(crdLI.CreditNote__c);

            if(crd != null && crd.CurrencyIsoCode != crdLi.CurrencyIsoCode){
                crdLi.CurrencyIsoCode = crd.CurrencyIsoCode;
            }
        }

    }
    
    public void OnAfterInsert(CreditNoteLineItem__c[] newCreditNoteLineItems){

    }
    
    //@future public static void OnAfterInsertAsync(Set<ID> newCreditNoteLineItemIDs){
    //}
    
    public void OnBeforeUpdate(CreditNoteLineItem__c[] oldCreditNoteLineItems, CreditNoteLineItem__c[] updatedCreditNoteLineItems, Map<ID, CreditNoteLineItem__c> creditNoteLineItemMap){

    }
    
    public void OnAfterUpdate(CreditNoteLineItem__c[] oldCreditNoteLineItems, CreditNoteLineItem__c[] updatedCreditNoteLineItems, Map<ID, CreditNoteLineItem__c> creditNoteLineItemMap){
    
    }
    
    //@future public static void OnAfterUpdateAsync(Set<ID> updatedCreditNoteLineItemIDs){
    //}
    
    public void OnBeforeDelete(CreditNoteLineItem__c[] creditNoteLineItemsToDelete, Map<ID, CreditNoteLineItem__c> creditNoteLineItemMap){
    
        Set<Id> CreditNoteIds = new Set<Id>();    

        for (CreditNoteLineItem__c crdLI : creditNoteLineItemsToDelete) {
            if (crdLI.CreditNote__c != null) {
                CreditNoteIds.add(crdLI.CreditNote__c);
            }
        }
        
        Map<Id, CreditNote__c> CreditNotes = new Map<Id, CreditNote__c>(
            [SELECT Id, IsCredited__c from CreditNote__c WHERE Id IN :CreditNoteIds]
        );
        
        for(CreditNoteLineItem__c crdLI : creditNoteLineItemsToDelete){
            CreditNote__c crd = CreditNotes.get(crdLI.CreditNote__c);

            if(crd != null && crd.IsCredited__c){
                crdLI.addError('Cannot delete a Line Item from an Credit Note that has been Credited.');
            }
        }
        
    }
    
    //public void OnAfterDelete(CreditNoteLineItem__c[] deletedCreditNoteLineItems, Map<ID, CreditNoteLineItem__c> creditNoteLineItemMap){
    //}
    
    //@future public static void OnAfterDeleteAsync(Set<ID> deletedCreditNoteLineItemIDs){
    //}
    
    public void OnUndelete(CreditNoteLineItem__c[] restoredCreditNoteLineItems){
    
        Set<Id> CreditNoteIds = new Set<Id>();    

        for (CreditNoteLineItem__c crdLI : restoredCreditNoteLineItems) {
            if (crdLI.CreditNote__c != null) {
                CreditNoteIds.add(crdLI.CreditNote__c);
            }
        }
        
        Map<Id, CreditNote__c> CreditNotes = new Map<Id, CreditNote__c>(
            [SELECT Id, IsCredited__c from CreditNote__c WHERE Id IN :CreditNoteIds]
        );
        
        for(CreditNoteLineItem__c crdLI : restoredCreditNoteLineItems){
            CreditNote__c crd = CreditNotes.get(crdLI.CreditNote__c);

            if(crd != null && crd.IsCredited__c){
                crdLI.addError('Cannot undelete a Line Item from an Credit Note that has been Credited.');
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