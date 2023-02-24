@isTest
public class CreditNoteTriggerTests
{
    @isTest(seeAllData=true)
    public static void testCreditNoteTriggers()
    {
        List<CreditNoteLineItem__c> creditNoteLineItemCache = new List<CreditNoteLineItem__c>();
        Product2 product = new Product2(
            Name = 'Test Product',
            Description = 'Test Product Description',
            Family = 'Test',
            ProductCode = 'TEST1234');
        insert product;
        System.assertNotEquals(product.Id, null);
        
        List<User> users = new List<User>([
            SELECT
                Id
            FROM
                User
            WHERE
                Profile.Name ='System Administrator'
            AND
                IsActive = true
            LIMIT 1]);
        System.assertEquals(users.size(), 1, 'No valid users, test cannot continue.');
        
        User user = users.get(0);
        
        System.runAs(user)
        {
            Account account = new Account(
                Name = 'Apex Test Account');
            insert account;
            System.assertNotEquals(account.Id, null);
            
            Opportunity opportunity = new Opportunity(
                Name = 'Apex Test Opportunity',
                AccountId = account.Id,
                Type = 'New Customer New Business',
                CloseDate = Date.today(),
                StageName = 'Order Received');
            insert opportunity;
            System.assertNotEquals(opportunity.Id, null);
            
            CreditNote__c creditNote = new CreditNote__c(
                Opportunity__c = opportunity.Id,
                Date__c = Date.today());
            insert creditNote;
            System.assertNotEquals(creditNote.Id, null);
            
            for (Integer i = 0; i < 2; i++)
            {
                CreditNoteLineItem__c creditNoteLineItem = new CreditNoteLineItem__c(
                    CreditNote__c = creditNote.Id,
                    Product__c = product.Id,
                    Name = product.Name + ' #' + (1 + 1));
                creditNoteLineItemCache.add(creditNoteLineItem);
            }
            insert creditNoteLineItemCache;
            

            creditNote.CurrencyIsoCode = 'EUR';
            update creditNote;
            
            List<CreditNoteLineItem__c> testCreditNoteLineItems = new List<CreditNoteLineItem__c>([
                SELECT
                    Id,
                    CurrencyIsoCode
                FROM
                    CreditNoteLineItem__c
                WHERE
                    CreditNote__c =: creditNote.Id]);
            System.assertEquals(testCreditNoteLineItems.size(), 2);
  
            for( CreditNoteLineItem__c testCreditNoteLineItem : testCreditNoteLineItems)
            {
                System.AssertEquals( testCreditNoteLineItem.CurrencyIsoCode, creditNote.CurrencyIsoCode);
            }
            
            Revenue__c revenue = new Revenue__c(
                Name = 'Apex Test Revenue',
                CreditNote__c = creditNote.Id,
                CreditNoteLineItem__c = creditNoteLineItemCache.get(0).Id);
            insert revenue;
            System.assertNotEquals(revenue.Id, null);
            
            creditNote.IsCredited__c = TRUE;
            update creditNote;
            
            CreditNoteLineItem__c creditNoteLineItem = [SELECT Id FROM CreditNoteLineItem__c WHERE CreditNote__c = :creditNote.Id LIMIT 1];
            
            try{
                delete creditNoteLineItem;
            }
            catch(Exception e){
                Boolean expectedExceptionThrown =  e.getMessage().contains('Cannot delete a Line Item from an Credit Note that has been Credited.') ? true : false;
            }
            
            creditNote.IsCredited__c = FALSE;
            update creditNote;
            
            delete creditNoteLineItem;
            
            creditNote.IsCredited__c = TRUE;
            update creditNote;
            
            try{
                undelete creditNoteLineItem;
            }
            catch(Exception e){
                Boolean expectedExceptionThrown =  e.getMessage().contains('Cannot undelete a Line Item from an Credit Note that has been Credited.') ? true : false;
            }
            
            try{
            delete account;
            }
            catch(Exception e){
            Boolean expectedExceptionThrown =  e.getMessage().contains('You cannot delete this record!') ? true : false;
            }
        }   
 
    }
    
}