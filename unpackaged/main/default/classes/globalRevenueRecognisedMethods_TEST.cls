@isTest(SeeAllData=true)
public class globalRevenueRecognisedMethods_TEST{
    
    public static testmethod void testRevenueRecognisedMethods(){
        
 		User user = [SELECT Id FROM User WHERE Profile.Name ='System Administrator' AND IsActive = TRUE LIMIT 1];
        
        Pricebook2 pbook = [SELECT Id FROM Pricebook2 WHERE IsStandard = true];
        
        //Insert Test Product 1            
        Product2 prod1 = new Product2( Name = 'Test Product 1',
                                       Description = 'Test Product 1 Description',
                                       Family = 'Software',
                                       Type__c = 'Software',
                                       ProductCode = 'TEST1'
                                     );
        insert prod1;
        
        PricebookEntry pbentry1 = new PricebookEntry( Pricebook2Id = pbook.Id,
                                                 Product2Id = prod1.Id,
                                                 IsActive = TRUE,
                                                 UseStandardPrice= FALSE,
                                                 UnitPrice = 0.00
                                               );
        insert pbentry1;
        
        //Insert Test Product 1            
        Product2 prod2 = new Product2( Name = 'Test Product 2',
                                       Description = 'Test Product 2 Description',
                                       Family = 'PLM',
                                       Type__c = 'Software',
                                       ProductCode = 'TEST2'
                                     );
        insert prod2;

        PricebookEntry pbentry2 = new PricebookEntry( Pricebook2Id = pbook.Id,
                                                 Product2Id = prod2.Id,
                                                 IsActive = TRUE,
                                                 UseStandardPrice= FALSE,
                                                 UnitPrice = 0.00
                                               );
        insert pbentry2;
        
        system.runAs(user){
            
            //Create a new Opportunity & Line Items
            Opportunity opp1 = new Opportunity();
            opp1.Name = 'Test Opportunity #1';
            opp1.Type = 'New Customer New Business';
            opp1.StageName = 'Order Processed';
            opp1.Probability = 100;
            opp1.CloseDate = System.Date.Today();
            opp1.Amount = 1500;
          	opp1.Customer_Order_Number__c = '1234';
            insert opp1;
               
            OpportunityLineItem opp1Li1 = new OpportunityLineItem();
            opp1Li1.OpportunityId = opp1.Id;
            opp1Li1.Quantity = 1;
            opp1Li1.UnitPrice = 500;
            opp1Li1.PriceBookEntryId = pbentry1.Id;
            insert opp1Li1;
            
            OpportunityLineItem opp1Li2 = new OpportunityLineItem();
            opp1Li2.OpportunityId = opp1.Id;
            opp1Li2.Quantity = 1;
            opp1Li2.UnitPrice = 500;
            opp1Li2.PriceBookEntryId = pbentry2.Id;
            insert opp1Li2;
            
            //Create a new Invoice & Line Items
            Invoice__c inv1 = new Invoice__c();
            inv1.Opportunity__c = opp1.Id;
            inv1.Company__c = 'SOLUTIONS';
            inv1.Date__c = System.Date.Today();
            insert inv1;
            
            InvoiceLineItem__c invLi1 = new InvoiceLineItem__c();
            invLi1.Invoice__c = inv1.Id;
            invLi1.Product__c = prod1.Id;
            invLi1.Name = prod1.Name;
            invLi1.BusinessType2__c = 'New';
            invLi1.Quantity__c = 1;
            invLi1.UnitPrice__c = 500;
            insert invLi1;
            
            InvoiceLineItem__c invLi2 = new InvoiceLineItem__c();
            invLi2.Invoice__c = inv1.Id;
            invLi2.Product__c = prod1.Id;
            invLi2.Name = prod1.Name;
            invLi2.BusinessType2__c = 'Renewal';
            invLi2.Quantity__c = 1;
            invLi2.UnitPrice__c = 500;
            insert invLi2;
            
            InvoiceLineItem__c invLi3 = new InvoiceLineItem__c();
            invLi3.Invoice__c = inv1.Id;
            invLi3.Product__c = prod2.Id;
            invLi3.Name = prod2.Name;
            invLi3.BusinessType2__c = 'New';
            invLi3.Quantity__c = 1;
            invLi3.UnitPrice__c = 500;
            insert invLi3;
            
            inv1.IsInvoice__c = TRUE;
            update inv1;
            
            //Create a new Credit Note & Line Items
            CreditNote__c crd1 = new CreditNote__c();
            crd1.Opportunity__c = opp1.Id;
            crd1.Company__c = 'SOLUTIONS';
            crd1.Date__c = System.Date.Today();
            insert crd1;
            
            CreditNoteLineItem__c crdLi1 = new CreditNoteLineItem__c();
            crdLi1.CreditNote__c = crd1.Id;
            crdLi1.Product__c = prod1.Id;
            crdLi1.Name = prod1.Name;
            crdLi1.BusinessType2__c = 'New';
            crdLi1.Quantity__c = 1;
            crdLi1.UnitPrice__c = 500;
            insert crdLi1;
            
            CreditNoteLineItem__c crdLi2 = new CreditNoteLineItem__c();
            crdLi2.CreditNote__c = crd1.Id;
            crdLi2.Product__c = prod1.Id;
            crdLi2.Name = prod1.Name;
            crdLi2.BusinessType2__c = 'Renewal';
            crdLi2.Quantity__c = 1;
            crdLi2.UnitPrice__c = 500;
            insert crdLi2;
            
            CreditNoteLineItem__c crdLi3 = new CreditNoteLineItem__c();
            crdLi3.CreditNote__c = crd1.Id;
            crdLi3.Product__c = prod2.Id;
            crdLi3.Name = prod2.Name;
            crdLi3.BusinessType2__c = 'New';
            crdLi3.Quantity__c = 1;
            crdLi3.UnitPrice__c = 500;
            insert crdLi3;
            
            crd1.IsCredited__c = TRUE;
            update crd1;
            
            //Refresh Opp Test
            globalRevenueRecognisedMethods.generateOppRevRec(opp1.Id);
            
            //Refresh Invoice Test
            globalRevenueRecognisedMethods.generateInvoiceRevRec(inv1.Id);
            
            //Refresh List of Opps Test
            List<Opportunity> opps = new List<Opportunity>([SELECT Id,
                                                                   (SELECT Id, 
                                                                           Ref__c,
                                                                           IsInvoice__c,
                                                                           Date__c,
                                                                           Type__c,
                                                                           Opportunity__r.Id,
                                                                           Opportunity__r.OwnerId 
                                                                    FROM OpportunityInvoices__r 
                                                                    WHERE IsInvoice__c = TRUE),
                                                                   (SELECT Id,
                                                                           Ref__c,
                                                                           IsCredited__c,
                                                                           Date__c,
                                                                           Type__c,
                                                                           Opportunity__r.Id,
                                                                           Opportunity__r.OwnerId 
                                                                    FROM OpportunityCreditNotes__r 
                                                                    WHERE IsCredited__c = TRUE),
                                                                   (SELECT Id 
                                                                    FROM RevenueRecognised__r)
                                                            FROM Opportunity 
                                                            WHERE Id =: opp1.Id]);
            
            globalRevenueRecognisedMethods.RevenueRecognisedMethods rev = new globalRevenueRecognisedMethods.RevenueRecognisedMethods();
            rev.generateRevenueRecognised(opps);
            
        }
        
    }

}