public class PurchaseOrderCloneWithItemsController {
 
    //added an instance varaible for the standard controller
    private ApexPages.StandardController controller {get; set;}
     // add the instance for the variables being passed by id on the url
    private PurchaseOrder__c po {get;set;}
    // set the id of the record that is created -- ONLY USED BY THE TEST CLASS
    public ID newRecordId {get;set;}
 
    // initialize the controller
    public PurchaseOrderCloneWithItemsController(ApexPages.StandardController controller) {
 
        //initialize the stanrdard controller
        this.controller = controller;
        // load the current record
        po = (PurchaseOrder__c)controller.getRecord();
 
    }
 
    // method called from the VF's action attribute to clone the po
    public PageReference cloneWithItems() {
 
         // setup the save point for rollback
         Savepoint sp = Database.setSavepoint();
         PurchaseOrder__c newPO;
 
         try {
 
             //copy the purchase order - ONLY INCLUDE THE FIELDS YOU WANT TO CLONE
             po = [SELECT Id, Name, Opportunity__c, OtherShippingAddress__c, ShipTo__c, ShipToAccount__c, ShipToContact__c, Supplier__c  from PurchaseOrder__c WHERE Id = :po.id];
             po.Date__c = System.Date.today();
             newPO = po.clone(false);
             insert newPO;
 
             // set the id of the new po created for testing
               newRecordId = newPO.id;
 
             // copy over the line items - ONLY INCLUDE THE FIELDS YOU WANT TO CLONE
             List<PurchaseOrderLineItem__c> items = new List<PurchaseOrderLineItem__c>();
             for (PurchaseOrderLineItem__c pi : [SELECT Id, Name, Description__c, Product__c, Quantity__c, UnitPrice__c, TaxRate__c FROM PurchaseOrderLineItem__c p where PurchaseOrder__c = :po.id]) {
                  PurchaseOrderLineItem__c newPI = pi.clone(false);
                  newPI.PurchaseOrder__c = newPO.id;
                  items.add(newPI);
             }
             insert items;
 
         } catch (Exception e){
             // roll everything back in case of error
            Database.rollback(sp);
            ApexPages.addMessages(e);
            return null;
         }
 
        return new PageReference('/'+newPO.id+'/e?retURL=%2F'+newPO.id);
    }
    
    @isTest
    private static void testPOCloneController() {
 
       // setup a reference to the page the controller is expecting with the parameters
        PageReference pref = Page.PurchaseOrderClone;
        Test.setCurrentPage(pref);
 
        // setup a ship to account
        Account shipTo = new Account();
        shipTo.Name = 'PSAV 6FOO';
        shipTo.Type = 'Supplier';
        insert shipTo;
        
        //Insert Test Opportunity
        Opportunity Opp = new Opportunity( Name = 'TestOpp',
                                           CloseDate = System.Date.today(),
                                           StageName = 'Order Received'
                                         );
        insert Opp;
 
        // create new po record
        PurchaseOrder__c po = new PurchaseOrder__c();
        po.Opportunity__c = Opp.id;
        po.Date__c = Date.newInstance(2020,01,01);
        po.ShipTo__c = shipTo.id;
        insert po;
 
        // create a line item for the po
        PurchaseOrderLineItem__c pi1 = new PurchaseOrderLineItem__c();
        pi1.Description__c = 'My item';
        pi1.PurchaseOrder__c = po.id;
        pi1.Quantity__c = 1;
        pi1.UnitPrice__c = 10;
        insert pi1;
 
        // Construct the standard controller
        ApexPages.StandardController con = new ApexPages.StandardController(po);
 
        // create the controller
        PurchaseOrderCloneWithItemsController ext = new PurchaseOrderCloneWithItemsController(con);
 
        // Switch to test context
        Test.startTest();
 
        // call the cloneWithItems method
        PageReference ref = ext.cloneWithItems();
        // create the matching page reference
        PageReference redir = new PageReference('/'+ext.newRecordId+'/e?retURL=%2F'+ext.newRecordId);
 
        // make sure the user is sent to the correct url
        System.assertEquals(ref.getUrl(),redir.getUrl());
 
        // check that the new po was created successfully
        PurchaseOrder__c newPO = [select id from PurchaseOrder__c where id = :ext.newRecordId];
        System.assertNotEquals(newPO, null);
        // check that the line item was created
        List<PurchaseOrderLineItem__c> newItems = [Select p.Id From PurchaseOrderLineItem__c p where PurchaseOrder__c = :newPO.id];
        System.assertEquals(newItems.size(),1);
 
        // Switch back to runtime context
        Test.stopTest();
 
    }
  
}