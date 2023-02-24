public with sharing class InvoiceTriggerHandler {

    private boolean m_isExecuting = false;
    private integer BatchSize = 0;
        
    public InvoiceTriggerHandler(boolean isExecuting, integer size){
        m_isExecuting = isExecuting;
        BatchSize = size;
    }
    
    globalRevenueRecognisedMethods.RevenueRecognisedMethods rev = new globalRevenueRecognisedMethods.RevenueRecognisedMethods();
              
    //public void OnBeforeInsert(Invoice__c[] newInvoices){        
    //}
    
    //public void OnAfterInsert(Invoice__c[] newInvoices){
    //}
    
    //@future public static void OnAfterInsertAsync(Set<ID> newInvoiceIDs){
    //}
    
    //public void OnBeforeUpdate(Invoice__c[] oldInvoices,Invoice__c[] updatedInvoices, Map<ID, Invoice__c> InvoiceMap){
    //}
    
    public void OnAfterUpdate(Invoice__c[] oldInvoices, Invoice__c[] updatedInvoices, Map<ID,  Invoice__c> oldInvoiceMap, Map<ID,  Invoice__c> newInvoiceMap){

        List<InvoiceLineItem__c> invoiceLineItemCache = new List<InvoiceLineItem__c>();
        List<Revenue__c> revenue2DeleteList = new List<Revenue__c>();
        List<Invoice__c> invoiceCache = new List<Invoice__c>();  


        for (Invoice__c invoice : [
                    SELECT
                        Opportunity__r.OwnerId,
                        Opportunity__r.Id,
                        Id,
                        Ref__c,
                        IsInvoice__c,
                        CurrencyIsoCode,
                        InvoiceNumber__c,
                        Date__c,
                        Type__c, (
                        SELECT
                            Id
                        FROM
                            InvoiceJournalEntries__r), (
                        SELECT
                            Id,
                            CurrencyIsoCode,
                            NetAmount__c,
                            ProductType__c,
                            Margin__c,
                            ProductFamily__c,
                            BusinessType__c
                        FROM
                            InvoiceLineItems__r)
                    FROM
                        Invoice__c
                    WHERE
                        Id IN :newInvoiceMap.keySet()])
        {

            Invoice__c oldInvoice = oldInvoiceMap.get(invoice.Id);

            //Check if Invoice Currency has changed and update the line items to match
            if (invoice.CurrencyIsoCode != oldInvoice.CurrencyIsoCode){
                for (InvoiceLineItem__c invoiceLineItem : invoice.InvoiceLineItems__r){
                    invoiceLineItem.CurrencyIsoCode = invoice.CurrencyIsoCode;
                }

                invoiceLineItemCache.addAll(invoice.InvoiceLineItems__r);
            }

            //Check if Invoice status has been changed
            if (invoice.IsInvoice__c != oldInvoice.IsInvoice__c){

                //Remove all current Revenue Entries
                revenue2DeleteList.addAll(invoice.InvoiceJournalEntries__r);
                //Generate new Revenue Entries for Completed Invoice
                if (invoice.IsInvoice__c){
                    invoiceCache.add(invoice);
                }

            }

        }

        if (!revenue2DeleteList.isEmpty()){
            delete revenue2DeleteList;
        }
        
        if (!invoiceLineItemCache.isEmpty()){
            update invoiceLineItemCache;
        } 
        
        if (!invoiceCache.isEmpty()){
            rev.generateRevenueRecognised(invoiceCache);
        }

    }
    
    //@future public static void OnAfterUpdateAsync(Set<ID> updatedTaskIDs){
    //}
    
    //public void OnBeforeDelete(Invoice__c[] InvoicesToDelete, Map<ID, Invoice__c> InvoiceMap){
    //}
    
    //public void OnAfterDelete(Invoice__c[] deletedInvoices, Map<ID, Invoice__c> InvoiceMap){
    //}
    
    //@future public static void OnAfterDeleteAsync(Set<ID> deletedTaskIDs){
    //}
    
    //public void OnUndelete(Invoice__c[] restoredInvoices){
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