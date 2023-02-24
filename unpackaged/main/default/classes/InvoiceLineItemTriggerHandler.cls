public with sharing class InvoiceLineItemTriggerHandler {
    private boolean m_isExecuting = false;
    private integer BatchSize = 0;
    
    public InvoiceLineItemTriggerHandler(boolean isExecuting, integer size){
        m_isExecuting = isExecuting;
        BatchSize = size;
    }
        
    public void OnBeforeInsert(InvoiceLineItem__c[] newInvoiceLineItems){
    
        Set<Id> InvoiceIds = new Set<Id>();    

        for (InvoiceLineItem__c invLI : newInvoiceLineItems) {
            if (invLI.Invoice__c != null) {
                InvoiceIds.add(invLI.Invoice__c);
            }
        }
        
        Map<Id, Invoice__c> Invoices = new Map<Id, Invoice__c>(
            [SELECT Id, CurrencyIsoCode from Invoice__c WHERE Id IN :InvoiceIds]
        );
        
        for(InvoiceLineItem__c invLI : newInvoiceLineItems){
            Invoice__c inv = Invoices.get(invLI.Invoice__c);

            if(inv != null && inv.CurrencyIsoCode != invLi.CurrencyIsoCode){
                invLi.CurrencyIsoCode = inv.CurrencyIsoCode;
            }
        }

    }
    
    public void OnAfterInsert(InvoiceLineItem__c[] newInvoiceLineItems){
    
    }
    
    //@future public static void OnAfterInsertAsync(Set<ID> newInvoiceLineItemIDs){
    //}
    
    public void OnBeforeUpdate(InvoiceLineItem__c[] oldInvoiceLineItems, InvoiceLineItem__c[] updatedInvoiceLineItems, Map<ID, InvoiceLineItem__c> invoiceLineItemMap){

    }
    
    public void OnAfterUpdate(InvoiceLineItem__c[] oldInvoiceLineItems, InvoiceLineItem__c[] updatedInvoiceLineItems, Map<ID, InvoiceLineItem__c> invoiceLineItemMap){
    
    }
    
    //@future public static void OnAfterUpdateAsync(Set<ID> updatedInvoiceLineItemIDs){
    //}
    
    public void OnBeforeDelete(InvoiceLineItem__c[] invoiceLineItemsToDelete, Map<ID, InvoiceLineItem__c> invoiceLineItemMap){
    
        Set<Id> InvoiceIds = new Set<Id>();    

        for (InvoiceLineItem__c invLI : invoiceLineItemsToDelete) {
            if (invLI.Invoice__c != null) {
                InvoiceIds.add(invLI.Invoice__c);
            }
        }
        
        Map<Id, Invoice__c> Invoices = new Map<Id, Invoice__c>(
            [SELECT Id, IsInvoice__c from Invoice__c WHERE Id IN :InvoiceIds]
        );
        
        for(InvoiceLineItem__c invLI : invoiceLineItemsToDelete){
            Invoice__c inv = Invoices.get(invLI.Invoice__c);

            if(inv != null && inv.IsInvoice__c){
                invLI.addError('Cannot delete a Line Item from an Invoice that has been Invoiced.');
            }
        }
        
    }
    
    public void OnAfterDelete(InvoiceLineItem__c[] deletedInvoiceLineItems, Map<ID, InvoiceLineItem__c> invoiceLineItemMap){
        
    }
    
    //@future public static void OnAfterDeleteAsync(Set<ID> deletedInvoiceLineItemIDs){
    //}
    
    public void OnUndelete(InvoiceLineItem__c[] restoredInvoiceLineItems){
    
        Set<Id> InvoiceIds = new Set<Id>();    

        for (InvoiceLineItem__c invLI : restoredInvoiceLineItems) {
            if (invLI.Invoice__c != null) {
                InvoiceIds.add(invLI.Invoice__c);
            }
        }
        
        Map<Id, Invoice__c> Invoices = new Map<Id, Invoice__c>(
            [SELECT Id, IsInvoice__c from Invoice__c WHERE Id IN :InvoiceIds]
        );
        
        for(InvoiceLineItem__c invLI : restoredInvoiceLineItems){
            Invoice__c inv = Invoices.get(invLI.Invoice__c);

            if(inv != null && inv.IsInvoice__c){
                invLI.addError('Cannot undelete a Line Item from an Invoice that has been Invoiced.');
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