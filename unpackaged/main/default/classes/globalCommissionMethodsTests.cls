@isTest(SeeAllData=true)
public class globalCommissionMethodsTests{
    
    public static testmethod void testCommissionMethods(){
        
      /*  Profile pf = [Select Id from Profile where Name = 'System Administrator'];
 
        User u = new User();
        u.FirstName = 'Test';
        u.LastName = 'User';
        u.Email = 'testuser@test123456789.com';
        u.CompanyName = 'test.com';
        u.Title = 'Test User';
        u.Username = 'testuser@test123456789.com';
        u.Alias = 'testuser';
        u.CommunityNickname = 'Test User';
        u.TimeZoneSidKey = 'America/Mexico_City';
        u.LocaleSidKey = 'en_US';
        u.EmailEncodingKey = 'ISO-8859-1';
        u.ProfileId = pf.Id;
        u.LanguageLocaleKey = 'en_US';
        u.IsActive = false;
        insert u; */
        
        User u = [ select Id from User where Id = :UserInfo.getUserId()];
        
        system.runAs(u){
        
        //Insert Test Product 1            
        Product2 prod1 = new Product2( Name = 'Test Product 1',
                                       Description = 'Test Product 1 Description',
                                       Family = 'Software',
                                       Type__c = 'Software',
                                       ProductCode = 'TEST1'
                                     );
         
           insert prod1;
      
        //Insert Test Product 1            
        Product2 prod2 = new Product2( Name = 'Test Product 2',
                                       Description = 'Test Product 2 Description',
                                       Family = 'PLM',
                                       Type__c = 'Software',
                                       ProductCode = 'TEST2'
                                     );
      
        insert prod2;
        

        
            
            //Create a Commission Rule (Catch All)
            CommissionRule__c comRule1 = new CommissionRule__c();
            comRule1.Active__c = TRUE;
            comRule1.RuleType__c = 'Deal';
            comRule1.Division__c = 'All';
            comRule1.CustomerType__c = 'All';
            comRule1.BusinessType__c = 'All';
            comRule1.ProductType__c = 'All';
            comRule1.Rate__c = 0.1;
            insert comRule1;
            
            //Create a Commission Rule (Target Based)
            CommissionRule__c comRule2 = new CommissionRule__c();
            comRule2.Active__c = TRUE;
            comRule2.RuleType__c = 'Target';
            comRule2.Division__c = 'All';
            comRule2.CustomerType__c = 'New';
            comRule2.BusinessType__c = 'New';
            comRule2.ProductType__c = 'All';
            comRule2.SalesPerson__c = u.Id;
            comRule2.MinPercentTarget__c = 0.5;
            comRule2.Rate__c = 0.2;
            insert comRule2;
            
            //Create a new Target
            Target__c target1 = new Target__c();
            target1.Year__c = String.valueOf(System.Date.Today().Year());
            target1.MarginTarget__c = 10000;
            insert target1;
            
            //Create a new Opportunity
            Opportunity opp1 = new Opportunity();
            opp1.Name = 'Test Opportunity #1';
            opp1.StageName = 'Order Processed';
            opp1.Probability = 100;
            opp1.CloseDate = System.Date.Today();
            opp1.Amount = 1500;
            insert opp1;
            
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
            
            //Insert some related Revenue__c records
            //Revenue__c rev1 = new Revenue__c();
            //rev1.Opportunity__c = opp1.Id;
            //rev1.Type__c = 'SI';
            //rev1.GrossAmount__c = 1000;
            //rev1.GrossMargin__c = 1000;
            //insert rev1;

            //Single Opp Test #1
            globalCommissionMethods.generateOppCommission(opp1.Id);
            
            //Get SOLUTIONS Commission Statement
            Commission__c com1 = [SELECT Id FROM Commission__c WHERE Company__c = 'SOLUTIONS' LIMIT 1];
            delete com1;
            
            //Single Opp Test #2
            //globalCommissionMethods.generateOppCommission(opp1.Id);
            
            //Batch Test
            String selectedCompany = 'SOLUTIONS';
            Integer selectedMonth = System.Date.Today().Month();
            Integer selectedYear = System.Date.Today().Year();
            String revQuery = 'SELECT Id, Owner.Id, Date__c, CommissionCompany__c, ProductFamily__c, BusinessType__c, ProductType__c, Invoice__c, InvoiceLineItem__r.Product__r.Id, CreditNote__c, CreditNoteLineItem__r.Product__r.Id, Opportunity__c, Opportunity__r.Customer_Type__c, Opportunity__r.Target__r.MarginTarget__c, Opportunity__r.Target__r.PercentRecognisedMarginTargetAchieved__c, NetMargin__c, CurrencyIsoCode FROM Revenue__c WHERE Invoice__c = \'' + inv1.Id + '\' LIMIT 1';

            globalCommissionBatch batchApex = new globalCommissionBatch(revQuery, selectedMonth, selectedYear);
            ID batchId = Database.executeBatch(batchApex, 50);
            
            
            //CommissionController & Batch Test
            
            //Set Controller        
            CommissionController comController = new CommissionController();
            comController.selectedCompany = 'SOLUTIONS';
            comController.selectedMonth = System.Date.Today().Month();
            comController.selectedYear = System.Date.Today().Year();
            
            List<SelectOption> theCompanies = comController.getCompanies();
            List<SelectOption> theMonths = comController.getMonths();
            List<SelectOption> theYears = comController.getYears();
            
            //String nextPage = comController.generate().getUrl();
            
            
            //Test the Controller Extension
            
            Commission__c com2 = [SELECT Id FROM Commission__c LIMIT 1];
            
            //Set Controller and Extension        
            ApexPages.StandardController stdController = new ApexPages.StandardController(com2);
            CommissionControllerExt comControllerExt = new CommissionControllerExt(stdController);
    
            //Get the CommissionStatement from the controller
            //PurchaseOrder__c record = (PurchaseOrder__c)stdController.getRecord();
                        
            Map<String, Map<String, CommissionPayment__c[]>> thePayments = comControllerExt.payments;
            Map<String, sObject> theRecords = comControllerExt.records;
            Map<String, AggregateResult> theTotals = comControllerExt.totals;
                        
        }
        
    }

}