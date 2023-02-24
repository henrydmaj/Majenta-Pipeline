@isTest()
public class globalEmailPDF_TEST {
    public static testmethod void testEmailPdfMethods(){
        
        User user = [SELECT Id FROM User WHERE Profile.Name ='System Administrator' AND IsActive = TRUE LIMIT 1];
        
        system.runAs(user){
            //Create a new Opportunity
            Opportunity opp1 = new Opportunity();
            opp1.Name = 'Test Opportunity #1';
            opp1.StageName = 'Order Processed';
            opp1.Probability = 100;
            opp1.CloseDate = System.Date.Today();
            opp1.Amount = 1500;
            opp1.Customer_Order_Number__c = '1234';
            insert opp1;
            
            //Create a new Invoice
            Invoice__c inv1 = new Invoice__c();
            inv1.Opportunity__c = opp1.Id;
            inv1.Company__c = 'SOLUTIONS';
            inv1.Date__c = System.Date.Today();
            insert inv1;
            
            globalEmailPDF.emailPDF(inv1.Id,'/apex/InvoiceSingle');
            
            
            //Create a new Credit Note
            CreditNote__c crd1 = new CreditNote__c();
            crd1.Opportunity__c = opp1.Id;
            crd1.Company__c = 'SOLUTIONS';
            crd1.Date__c = System.Date.Today();
            insert crd1;
            
            globalEmailPDF.emailPDF(crd1.Id,'/apex/CreditNoteSingle');
            
            
            //Create a new Purchase Order
            PurchaseOrder__c po1 = new PurchaseOrder__c();
            po1.Opportunity__c = opp1.Id;
            po1.Date__c = System.Date.Today();
            insert po1;
            
            globalEmailPDF.emailPDF(po1.Id,'/apex/PurchaseOrderTemplate');
            
        }
    }
}