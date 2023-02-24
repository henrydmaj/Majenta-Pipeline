public with sharing class CreditNoteTriggerHandler {

    private boolean m_isExecuting = false;
    private integer BatchSize = 0;
        
    public CreditNoteTriggerHandler(boolean isExecuting, integer size){
        m_isExecuting = isExecuting;
        BatchSize = size;
    }
    
    globalRevenueRecognisedMethods.RevenueRecognisedMethods rev = new globalRevenueRecognisedMethods.RevenueRecognisedMethods();
              
    //public void OnBeforeInsert(CreditNote__c[] newCreditNotes){        
    //}
    
    //public void OnAfterInsert(CreditNote__c[] newCreditNotes){
    //}
    
    //@future public static void OnAfterInsertAsync(Set<ID> newCreditNoteIDs){
    //}
    
    //public void OnBeforeUpdate(CreditNote__c[] oldCreditNotes,CreditNote__c[] updatedCreditNotes, Map<ID, CreditNote__c> CreditNoteMap){
    //}
    
    public void OnAfterUpdate(CreditNote__c[] oldCreditNotes, CreditNote__c[] updatedCreditNotes, Map<ID,  CreditNote__c> oldCreditNoteMap, Map<ID,  CreditNote__c> newCreditNoteMap){

        List<CreditNoteLineItem__c> creditNoteLineItemCache = new List<CreditNoteLineItem__c>();
        List<Revenue__c> revenue2DeleteList = new List<Revenue__c>();
        List<CreditNote__c> creditNoteCache = new List<CreditNote__c>();  


        for (CreditNote__c creditNote : [
                    SELECT
                        Opportunity__r.OwnerId,
                        Opportunity__r.Id,
                        Id,
                        Ref__c,
                        IsCredited__c,
                        CurrencyIsoCode,
                        CreditNumber__c,
                        Date__c,
                        Type__c, (
                        SELECT
                            Id
                        FROM
                            CreditNoteJournalEntries__r), (
                        SELECT
                            Id,
                            CurrencyIsoCode,
                            NetAmount__c,
                            ProductType__c,
                            Margin__c,
                            ProductFamily__c,
                            BusinessType__c
                        FROM
                            CreditNoteLineItems__r)
                    FROM
                        CreditNote__c
                    WHERE
                        Id IN :newCreditNoteMap.keySet()])
        {

            CreditNote__c oldCreditNote = oldCreditNoteMap.get(creditNote.Id);

            //Check if CreditNote Currency has changed and update the line items to match
            if (creditNote.CurrencyIsoCode != oldCreditNote.CurrencyIsoCode){
                for (CreditNoteLineItem__c creditNoteLineItem : creditNote.CreditNoteLineItems__r){
                    creditNoteLineItem.CurrencyIsoCode = creditNote.CurrencyIsoCode;
                }

                creditNoteLineItemCache.addAll(creditNote.CreditNoteLineItems__r);
            }

            //Check if CreditNote status has been changed
            if (creditNote.IsCredited__c != oldCreditNote.IsCredited__c){

                //Remove all current Revenue Entries
                revenue2DeleteList.addAll(creditNote.CreditNoteJournalEntries__r);
                //Generate new Revenue Entries for Completed CreditNote
                if (creditNote.IsCredited__c){
                    creditNoteCache.add(creditNote);
                }

            }

        }

        if (!revenue2DeleteList.isEmpty()){
            delete revenue2DeleteList;
        }
        
        if (!creditNoteLineItemCache.isEmpty()){
            update creditNoteLineItemCache;
        } 
        
        if (!creditNoteCache.isEmpty()){
            rev.generateRevenueRecognised(creditNoteCache);
        }

    }
    
    //@future public static void OnAfterUpdateAsync(Set<ID> updatedTaskIDs){
    //}
    
    //public void OnBeforeDelete(CreditNote__c[] CreditNotesToDelete, Map<ID, CreditNote__c> CreditNoteMap){
    //}
    
    //public void OnAfterDelete(CreditNote__c[] deletedCreditNotes, Map<ID, CreditNote__c> CreditNoteMap){
    //}
    
    //@future public static void OnAfterDeleteAsync(Set<ID> deletedTaskIDs){
    //}
    
    //public void OnUndelete(CreditNote__c[] restoredCreditNotes){
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