@isTest(seeAllData=true)
public class PurchaseOrderTriggerTests {
       
    public static testmethod void testPurchaseOrderTriggers(){
                        
        Product2 P = new Product2( Name = 'Test Product',
                                   Description = 'Test Product Description',
                                   Family = 'Test',
                                   ProductCode = 'TEST1234'
                                  );
        insert P;
                    
        User Usr = [Select id from User where Profile.Name ='Sales Support' and isActive = true limit 1];
        system.runAs(Usr){
        
            //Insert Test Account
            Account Acc = new Account( Name = 'Purchase Order Test Account' );
            insert Acc;
            
            //Insert Test Opportunity
            Opportunity Opp = new Opportunity( Name = 'Purchase Order Test Opp',
                                               AccountId = Acc.Id,
                                               Type = 'New Customer New Business',
                                               CloseDate = System.Date.today(),
                                               StageName = 'Order Received'
                                             );
            insert Opp;
            
            //Insert Test Purchase Order
            PurchaseOrder__c PO = new PurchaseOrder__c( Opportunity__c = Opp.id,
                                             Date__c = System.Date.today() );
            insert PO;
                                             
            //Insert Test Purchase Order Line Item #1
            PurchaseOrderLineItem__c poLI1 = new PurchaseOrderLineItem__c( PurchaseOrder__c = PO.Id,
                                                                Product__c = P.Id,
                                                                Name = P.Name + ' #1' );
            insert poLI1;
            
            //Insert Test Purchase Order Line Item #2
            PurchaseOrderLineItem__c poLI2 = new PurchaseOrderLineItem__c( PurchaseOrder__c = PO.Id,
                                                                Product__c = P.Id,
                                                                Name = P.Name + ' #2' );
            insert poLI2;
            
            //Change Purchase Order CurrencyIsoCode
            PO.CurrencyIsoCode = 'EUR';
            update PO;
            
            //Requery Purchase Order Line Items
            List<PurchaseOrderLineItem__c> poLIs = [SELECT Id, CurrencyIsoCode from PurchaseOrderLineItem__c WHERE PurchaseOrder__c =: PO.Id];
            
            //Check All Purchase Order Line Items have correct CurrencyIsoCode
            for( PurchaseOrderLineItem__c poLI : poLIs )
                System.AssertEquals( poLI.CurrencyIsoCode, 'EUR' );
            
            //Delete Purchase Order Line Item #1                                                    
            delete poLI1;
                                                                
            //Set Purchase Order to Ordered__c = TRUE
            PO.Ordered__c = TRUE;
            update PO;
            
            //Try to Delete Purchase Order Line Item #2
            try{
                //Delete Purchase Order Line Item #2                                                    
                delete poLI2;
            }
            catch(Exception e){
                Boolean expectedExceptionThrown =  e.getMessage().contains('Cannot delete') ? true : false;
                System.AssertEquals(expectedExceptionThrown, true);
            }
            
            //Try to Undelete Purchase Order Line Item #1
            try{
                //Undelete Purchase Order Line Item #1                                                    
                undelete poLI1;
            }
            catch(Exception e){
                Boolean expectedExceptionThrown =  e.getMessage().contains('Cannot undelete') ? true : false;
                System.AssertEquals(expectedExceptionThrown, true);
            }
                        
        }   
 
    }
    
}