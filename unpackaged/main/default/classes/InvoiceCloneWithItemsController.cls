public class InvoiceCloneWithItemsController {
 
    //added an instance varaible for the standard controller
    private ApexPages.StandardController controller {get; set;}
     // add the instance for the variables being passed by id on the url
    private Invoice__c inv {get;set;}
    // set the id of the record that is created -- ONLY USED BY THE TEST CLASS
    public ID newRecordId {get;set;}
 
    // initialize the controller
    public InvoiceCloneWithItemsController(ApexPages.StandardController controller) {
 
        //initialize the stanrdard controller
        this.controller = controller;
        // load the current record
        inv = (Invoice__c)controller.getRecord();
 
    }
 
    // method called from the VF's action attribute to clone the inv
    public PageReference cloneWithItems() {
 
         // setup the save point for rollback
         Savepoint sp = Database.setSavepoint();
         Invoice__c newInv;
 
         try {
 
             //copy the Invoice - ONLY INCLUDE THE FIELDS YOU WANT TO CLONE
             inv = [SELECT Id, Name, BillingAddress2__c, BillingAccount__c, Company__c, CustomerOrderNumber__c, IsFactored__c, IsHeaded__c, Notes__c, Opportunity__c, ShippingAddress2__c, ShippingAccount__c  FROM Invoice__c WHERE Id = :inv.id];
             inv.Date__c = System.Date.today();
             inv.IsClone__c = TRUE;
             newInv = inv.clone(false);
             insert newInv;
 
             // set the id of the new inv created for testing
               newRecordId = newInv.id;
 
             // copy over the line items - ONLY INCLUDE THE FIELDS YOU WANT TO CLONE
             List<InvoiceLineItem__c> items = new List<InvoiceLineItem__c>();
             for (InvoiceLineItem__c invLi : [SELECT Id, Name, Description__c, Product__c, ProductType_ro__c, Quantity__c, SortOrder__c, UnitPrice__c, TaxRate__c FROM InvoiceLineItem__c i WHERE Invoice__c = :inv.id]) {
                  InvoiceLineItem__c newInvLi = invLi.clone(false);
                  newInvLi.Invoice__c = newInv.id;
                  items.add(newInvLi);
             }
             insert items;
 
         } catch (Exception e){
             // roll everything back in case of error
            Database.rollback(sp);
            ApexPages.addMessages(e);
            return null;
         }
 
        return new PageReference('/'+newInv.id+'/e?retURL=%2F'+newInv.id);
    }
    
    @isTest
    private static void testInvCloneController() {
 
       // setup a reference to the page the controller is expecting with the parameters
        PageReference pref = Page.InvoiceClone;
        Test.setCurrentPage(pref);
 
        // setup a ship to account
        Account shipTo = new Account();
        shipTo.Name = 'PSAV 6FOO';
        shipTo.Type = 'Customer';
        insert shipTo;
        
        //Insert Test Opportunity
        Opportunity Opp = new Opportunity( Name = 'TestOpp',
                                           CloseDate = System.Date.today(),
                                           StageName = 'Order Received'
                                         );
        insert Opp;
 
        // create new inv record
        Invoice__c inv = new Invoice__c();
        inv.Opportunity__c = Opp.id;
        inv.Date__c = system.today();//Date.newInstance(2020,01,01);
        inv.ShippingAccount__c = shipTo.id;
        insert inv;
 
        // create a line item for the inv
        InvoiceLineItem__c invLi1 = new InvoiceLineItem__c();
        invLi1.Description__c = 'My item';
        invLi1.Invoice__c = inv.id;
        invLi1.Quantity__c = 1;
        invLi1.UnitPrice__c = 10;
        insert invLi1;
 
        // Construct the standard controller
        ApexPages.StandardController con = new ApexPages.StandardController(inv);
 
        // create the controller
        InvoiceCloneWithItemsController ext = new InvoiceCloneWithItemsController(con);
 
        // Switch to test context
        Test.startTest();
 
        // call the cloneWithItems method
        PageReference ref = ext.cloneWithItems();
        // create the matching page reference
        PageReference redir = new PageReference('/'+ext.newRecordId+'/e?retURL=%2F'+ext.newRecordId);
 
        // make sure the user is sent to the correct url
        System.assertEquals(ref.getUrl(),redir.getUrl());
 
        // check that the new inv was created successfully
        Invoice__c newInv = [SELECT id from Invoice__c WHERE id = :ext.newRecordId];
        System.assertNotEquals(newInv, null);
        // check that the line item was created
        List<InvoiceLineItem__c> newItems = [SELECT i.Id From InvoiceLineItem__c i WHERE Invoice__c = :newInv.id];
        System.assertEquals(newItems.size(),1);
 
        // Switch back to runtime context
        Test.stopTest();
 
    }
  
}