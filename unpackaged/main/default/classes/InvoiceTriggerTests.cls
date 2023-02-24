@isTest(seeAllData=true)
public class InvoiceTriggerTests
{
	@isTest(seeAlldata=true)
	public static void testInvoiceTriggers()
	{
		List<InvoiceLineItem__c> invoiceLineItemCache = new List<InvoiceLineItem__c>();
		Product2 product = new Product2(
			Name = 'Apex Test Product',
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
				Profile.Name = 'System Administrator'
			AND
				IsActive = true
			LIMIT 1]);
		System.assertEquals(users.size(), 1, 'No users, test unable to continue.');
		
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
			
			Invoice__c invoice = new Invoice__c(
				Opportunity__c = opportunity.Id,
				Date__c = Date.today());
			insert invoice;
			System.assertNotEquals(invoice.Id, null);
			
			for (Integer i = 0; i < 2; i++)
			{
				InvoiceLineItem__c invoiceLineItem = new InvoiceLineItem__c(
					Invoice__c = invoice.Id,
					Product__c = product.Id,
					Name = product.Name + ' #' + i );
				invoiceLineItemCache.add(invoiceLineItem);
			}
			insert invoiceLineItemCache;
			
			invoice.CurrencyIsoCode = 'EUR';
			update invoice;
			
			List<InvoiceLineItem__c> testInvoiceLineItems = new List<InvoiceLineItem__c>([
				SELECT
					Id,
					CurrencyIsoCode
				FROM
					InvoiceLineItem__c
				WHERE
					Invoice__c = :invoice.Id]);
			System.assertEquals(testInvoiceLineItems.size(), 2);
			
			for (InvoiceLineItem__c testInvoiceLineItem : testInvoiceLineItems)
			{
				System.assertEquals(testInvoiceLineItem.CurrencyIsoCode, invoice.CurrencyIsoCode);
			}
			
			Revenue__c revenue = new Revenue__c(
				Name = 'Apex Test Revenue',
				Invoice__c = invoice.Id,
				InvoiceLineItem__c = invoiceLineItemCache.get(0).Id);
			insert revenue;
			System.assertNotEquals(revenue.Id, null);
			
			invoice.IsInvoice__c = true;
			update invoice;
            
            InvoiceLineItem__c invoiceLineItem = [SELECT Id FROM InvoiceLineItem__c WHERE Invoice__c = :invoice.Id LIMIT 1];
            
            try{
                delete invoiceLineItem;
            }
            catch(Exception e){
                Boolean expectedExceptionThrown =  e.getMessage().contains('Cannot delete a Line Item from an Invoice that has been Invoiced.') ? true : false;
            }
            
            invoice.IsInvoice__c = FALSE;
            update invoice;
            
            delete invoiceLineItem;
            
            invoice.IsInvoice__c = TRUE;
            update invoice;
            
            try{
                undelete invoiceLineItem;
            }
            catch(Exception e){
                Boolean expectedExceptionThrown =  e.getMessage().contains('Cannot undelete a Line Item from an Invoice that has been Invoiced.') ? true : false;
            }
            
        }   
 
    }
}