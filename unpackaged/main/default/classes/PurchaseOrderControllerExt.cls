public class PurchaseOrderControllerExt {

    private final PurchaseOrder__c po;
    private final CompanyInformation__c plm = CompanyInformation__c.getValues('plm');
    private final CompanyInformation__c solutions = CompanyInformation__c.getValues('solutions');
        
    public PurchaseOrderControllerExt(ApexPages.StandardController stdController) {
        List<String> fields = new List<String>();
        
        if (!Test.isRunningTest()) {
            fields.add('Opportunity__r.Division__c');
            stdController.addFields(fields);
        }
        
        this.po = (PurchaseOrder__c)stdController.getRecord();
    }
        
    public CompanyInformation__c getCompanyInformation() {
        CompanyInformation__c company;
        
        if ( po.Opportunity__r.Division__c != null && po.Opportunity__r.Division__c != null )
            if ( po.Opportunity__r.Division__c == 'PLM' || po.Opportunity__r.Division__c == 'Solid Edge' )
                company = plm;
            else
                company = solutions;
        
        return company;
    }
    
    @isTest (seeAllData=true)
    private static void testPurchaseOrderControllerExt() {
    
        CompanyInformation__c company;
        String[] divisions = new List<String>{'PLM', 'Software'};
        
        //Insert Test Opportunity
        Opportunity Opp = new Opportunity( Name = 'TestOpp',
                                           CloseDate = System.Date.today(),
                                           StageName = 'Order Received'
                                         );
        insert Opp;
        
        //Insert Purchase Order
        PurchaseOrder__c PO = new PurchaseOrder__c( Opportunity__c = Opp.Id );
        insert PO;
        
        //Test method against list of divisions
        for ( String division : divisions ) {
        
            //Change the Opportunity Division field for a second test
            Opp.Division__c = division;
            update Opp;
            
            //Requery Fields
            PO = [SELECT Id, Opportunity__r.Division__c FROM PurchaseOrder__c WHERE Id =: PO.Id];
            
            //Set Controller and Extension        
            ApexPages.StandardController stdController = new ApexPages.StandardController(PO);
            PurchaseOrderControllerExt ext = new PurchaseOrderControllerExt(stdController);
    
            //Get the Purchase Order from the controller
            PurchaseOrder__c record = (PurchaseOrder__c)stdController.getRecord();
            
            //Log value of the related Opportunity Division field
            System.debug('Opportunity Division = '+record.Opportunity__r.Division__c);
            
            //Test method
            company = ext.getCompanyInformation();
            
            //Log value of custom setting name
            //System.debug('Company Name = '+company.Name);
        
        }
    
    }
    
}