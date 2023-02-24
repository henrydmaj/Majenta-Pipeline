public class OpportunityPOController {

    private final Opportunity opp;
    private List<OpportunityLineItem> oppLines = new List<OpportunityLineItem>();
    private List<Account> suppliers = new List<Account>();
    private Set<String> setSuppliers = new Set<string>();
    private List<String> errors = new List<String>();
        
    public OpportunityPOController(ApexPages.StandardController stdController) {
        this.opp = (Opportunity)stdController.getRecord();
        
        for ( OpportunityLineItem oppLine : [SELECT p.PricebookEntry.Product2.Supplier__r.Id,
                                                    p.PricebookEntry.Product2.Supplier__r.Name,
                                                    p.PricebookEntry.Product2.Supplier__r.BillingCity,
                                                    p.PricebookEntry.Product2.Supplier__r.Description
                                                    FROM OpportunityLineItem p 
                                                    WHERE p.OpportunityId =:opp.Id] ) {
            if(!setSuppliers.contains(oppLine.PricebookEntry.Product2.Supplier__r.Name)){
                suppliers.add(new account ( Id = oppLine.PricebookEntry.Product2.Supplier__r.Id,
                                            Name = oppLine.PricebookEntry.Product2.Supplier__r.Name,
                                            BillingCity = oppLine.PricebookEntry.Product2.Supplier__r.BillingCity,
                                            Description = oppLine.PricebookEntry.Product2.Supplier__r.Description
                                          ));
               setSuppliers.add(oppLine.PricebookEntry.Product2.Supplier__r.Name);
            }
        }
    }
           
    public List<SelectOption> getItems() {
        List<SelectOption> options = new List<SelectOption>();
        String supplierValue;
        
        options.add(new SelectOption('','--Select Supplier--'));
        
        for ( Account supplier : suppliers ) {
            if ( supplier.BillingCity != null )
                supplierValue = supplier.Name+' ('+supplier.BillingCity+')';
            else
                supplierValue = supplier.Name;
            
            options.add(new selectOption(supplier.Id,supplierValue));
        }
        
        return options;
    }
    
    public List<Account> getSuppliers() {
        return suppliers;
    }
    
    public PageReference generate() {
        PageReference pageRef;
        String[] result;
                
        if ( selectedSupplier != null ) {
            result = GenerateOpportunityPurchaseOrder.generatePurchaseOrder(opp.Id,selectedSupplier);
            if ( result.size() > 1 ) {
                errors.addAll(result);
                pageRef = null;
            } else {
                pageRef = new PageReference ('/'+result[0]);
            }
        } else {
            errors.add('You must select a supplier!');
            pageRef = null;
        }
        return pageRef;
    }
    
    public String selectedSupplier {get; set;}
    
    public Boolean getHasErrors() {
        if (errors.size() > 0)
            return true;
        else
            return false;
    }
    
    public List<String> getErrors() {
        return errors;
    }
    
    @isTest (seeAllData=true)
    private static void OpportunityPOController() {
    
        //Insert Test Supplier Account
        Account suppAcc = new Account( Name = 'Test Supplier Account',
                                       Type = 'Supplier'
                                     );
        insert suppAcc;
        
        
        //Get the standard pricebook
        Pricebook2 Pb = [SELECT Id FROM Pricebook2 WHERE IsStandard = true];
        
        //Insert Test Product 1            
        Product2 prod1 = new Product2( Name = 'Test Product 1',
                                       Description = 'Test Product 1Description',
                                       Family = 'Test',
                                       ProductCode = 'TEST1',
                                       Supplier__c = suppAcc.Id
                                     );
        insert prod1;
        
        //Insert Test Product 1  Pricebook Entry
        PricebookEntry PbE1 = new PricebookEntry( Pricebook2Id = Pb.Id,
                                                  Product2Id = prod1.Id,
                                                  IsActive = TRUE,
                                                  UseStandardPrice= FALSE,
                                                  UnitPrice = 0.00
                                                );
        insert PbE1;
        
        //Insert Test Customer Account
        Account custAcc = new Account( Name = 'Test Customer Account',
                                       Type = 'Customer'
                                     );
        insert custAcc;
        
        //Insert Test Opportunity
        Opportunity Opp = new Opportunity( Name = 'TestOpp',
                                           AccountId = custAcc.Id,
                                           Type = 'New Customer New Business',
                                           CloseDate = System.Date.today(),
                                           StageName = 'Order Received',
                                           Pricebook2Id = Pb.Id
                                         );
        insert Opp;
        
        //Insert Test Opportunity Line Item 1       
        OpportunityLineItem OppLi = new OpportunityLineItem( OpportunityId = Opp.Id,
                                                             Quantity=1,
                                                             TotalPrice = 1,
                                                             PriceBookEntryId = PbE1.Id
                                                           );
        insert OppLi;
        
        //try-catch for account delete prevention
        
        Account acc = new account();
        acc.name = 'test';
        insert acc;
        
        try{ 
        delete acc;
          }
          catch(Exception e){
        Boolean expectedExceptionThrown =  e.getMessage().contains('You cannot delete this record!') ? true : false;
        }
        
        //Set Controller and Extension        
        ApexPages.StandardController stdController = new ApexPages.StandardController(Opp);
        OpportunityPOController ext = new OpportunityPOController(stdController);
        
        //Call getItems method and check returned list size
        List<SelectOption> options = ext.getItems();
        System.assertNotEquals(options.size(),0);
        
        //Call getSuppliers method and check returned list size
        List<Account> suppliers = ext.getSuppliers();
        System.assertNotEquals(suppliers.size(),0);
        
        //Set selectedSupplier to Supplier Account ID to test valid response
        ext.selectedSupplier = suppliers[0].Id;
        System.assert(ext.selectedSupplier == suppliers[0].Id); 
        System.debug('selectedSupplier = '+ext.selectedSupplier);
        
        //Call methods and log results
        System.debug('generate = '+ext.generate());
        System.debug('hasErrors = '+ext.getHasErrors());
        System.debug('errors = '+ext.getErrors());
        
        //Set selectedSupplier to null to test error response
        ext.selectedSupplier = null;
        
        //Call generate method and check it returns null
        PageReference pageref = ext.generate();
        System.assertEquals(pageref,null);
        
        //Call hasErrors method and check it returns true
        Boolean hasErrors = ext.getHasErrors();
        System.assertEquals(hasErrors,true);
        
        //Call getErrors method and check returned list size
        List<String> errors = ext.getErrors();
        System.assertNotEquals(errors.size(),0);
        
    }
    
}