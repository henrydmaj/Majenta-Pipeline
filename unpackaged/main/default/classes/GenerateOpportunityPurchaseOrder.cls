global class GenerateOpportunityPurchaseOrder {

public class Test_Exception extends Exception{}

    public static String[] generatePurchaseOrder(String OppId, String SuppId) {
    
        List<String> message = new List<String>();
        if(OppId!=null && SuppID!=null) {
            
            //Conversion currency map
            Map<String,Double> CurrencyConversionRate_Map = new Map<String,Double>();
            for (CurrencyType CT:[select Id,ConversionRate,IsoCode from CurrencyType]) {
                CurrencyConversionRate_Map.put(CT.IsoCode,CT.ConversionRate);
            }
            // Current Opportunity Record
            Opportunity Opp = [SELECT o.Id,
                                      o.CurrencyIsoCode,
                                      o.Account.Id 
                                      FROM Opportunity o WHERE o.Id=:OppId];
                                                 
            if(Opp!=null) {
                String productName;
                try{
                    // mapping between opportunity and new po
                    PurchaseOrder__c newPurchaseOrder = new PurchaseOrder__c( Opportunity__c = Opp.Id,
                                                            Date__c = System.Date.today(),
                                                            CurrencyIsoCode = Opp.CurrencyIsoCode,
                                                            Supplier__c = SuppId,
                                                            ShipTo__c = 'Customer',
                                                            ShipToAccount__c = Opp.Account.Id
                                                            );
                                                            
                    // Opportunity Primary Contact
                    List<OpportunityContactRole> Con = [SELECT ContactId FROM OpportunityContactRole WHERE OpportunityId=:OppId AND IsPrimary=true LIMIT 1];
                    if(Con.size()>0) newPurchaseOrder.ShipToContact__c = Con[0].ContactId;
                        
                    insert newPurchaseOrder;
                    
                    // List of Opportunity Line Item records associated to the current Opportunity record and selected Supplier
                    List<OpportunityLineItem> oProductList = new List<OpportunityLineItem>([SELECT p.PricebookEntryId,
                                                                                                   p.PricebookEntry.Product2.Id,
                                                                                                   p.PricebookEntry.Product2.Name,
                                                                                                   p.PricebookEntry.Product2.Description,
                                                                                                   p.PricebookEntry.Product2.Category__c,
                                                                                                   p.Description, 
                                                                                                   p.Quantity, 
                                                                                                   p.Buy_Price__c,
                                                                                                   p.Finish_Date__c,
                                                                                                   p.StartDate__c,
                                                                                                   p.FinishDate__c,
                                                                                                   p.Contract_No_Site_ID__c FROM OpportunityLineItem p 
                                                                                                   WHERE p.OpportunityId =:Opp.Id AND p.PricebookEntry.Product2.Supplier__c =:SuppId]);
                   
                   if(!oProductList.isEmpty()) { 
                     
                     Map<Id,Id> priceBookEntryList = new Map<Id,Id>();
                     Set<Id> setProductId = new Set<Id>();
                     for(OpportunityLineItem oProduct:oProductList) {
                        setProductId.add(oProduct.PricebookEntryId);
                     }
                     if(!setProductId.isEmpty()) {

                         List<PurchaseOrderLineItem__c> newPurchaseOrderLineItemList = new List<PurchaseOrderLineItem__c>();
                         for(OpportunityLineItem oProduct:oProductList) {
                                PurchaseOrderLineItem__c PurchaseOrderLineItem  = new  PurchaseOrderLineItem__c( 
                                                                                             PurchaseOrder__c = newPurchaseOrder.Id,
                                                                                             CurrencyIsoCode = newPurchaseOrder.CurrencyIsoCode 
                                                                                              );
                                if(PurchaseOrderLineItem.CurrencyIsoCode!='GBP') {
                                    PurchaseOrderLineItem.TaxRate__c = 0;
                                }
                                
                                //Convert UnitPrice into the Opportunity currency 
                                //Need to specify a Sales price
                                if(oProduct.Buy_Price__c!=null)                                                  
                                {   
                                    PurchaseOrderLineItem.UnitPrice__c =  (oProduct.Buy_Price__c / CurrencyConversionRate_Map.get(Opp.CurrencyIsoCode))*CurrencyConversionRate_Map.get(Opp.CurrencyIsoCode);
                                }
                                else{
                                    PurchaseOrderLineItem.UnitPrice__c = 1;
                                }
                                
                                // Quantity needs to be greater than 0
                                if(oProduct.Quantity!=null && oProduct.Quantity >0)                                                 
                                {   
                                    PurchaseOrderLineItem.Quantity__c =  oProduct.Quantity;
                                }
                                else{
                                    PurchaseOrderLineItem.Quantity__c = 1;
                                }
                                
                                //Name needs to contains more 1 characters
                                if(oProduct.PricebookEntry.Product2.Name!=null && oProduct.PricebookEntry.Product2.Name.length()>=2)                                                    
                                {   
                                    if(oProduct.PricebookEntry.Product2.Name.length()>80)
                                        PurchaseOrderLineItem.Name =  oProduct.PricebookEntry.Product2.Name.substring(0, 80);
                                    else
                                        PurchaseOrderLineItem.Name =  oProduct.PricebookEntry.Product2.Name;
                                }
                                else{
                                    PurchaseOrderLineItem.Name = 'Please complete the Name';
                                }
                                                                
                                //Description needs to contains more 4 characters
                                if(oProduct.Description!=null && oProduct.Description.length()>=5)                                                    
                                {   
                                    PurchaseOrderLineItem.Description__c =  oProduct.Description;
                                }
                                else if(oProduct.PricebookEntry.Product2.Description!=null){
                                    PurchaseOrderLineItem.Description__c =  oProduct.PricebookEntry.Product2.Description;
                                }
                                else{
                                    PurchaseOrderLineItem.Description__c = 'Please complete the Description';
                                }
                                                                
                                if(oProduct.StartDate__c!=null && oProduct.FinishDate__c!=null)
                                {
                                    PurchaseOrderLineItem.Description__c += '\n'+oProduct.StartDate__c.format()+' to '+oProduct.FinishDate__c.format();
                                }
                                
                                if(oProduct.Contract_No_Site_ID__c!=null)
                                {
                                    String cnsidDesc;
                                    if(oProduct.PricebookEntry.Product2.Category__c == 'Siemens'){
                                        cnsidDesc = 'Sold To';
                                    }else if(oProduct.PricebookEntry.Product2.Category__c == 'Autodesk'){
                                        cnsidDesc = 'Contract No.';
                                    }else{
                                        cnsidDesc = 'Contract No. / Sold To';
                                    }
                                    
                                    PurchaseOrderLineItem.Description__c += '\n'+cnsidDesc+': '+oProduct.Contract_No_Site_ID__c;
                                }
                                
                                                              
                                //System.debug('@@@@'+pBookEntryList);
                                if(oProduct.PricebookEntryId!=null)
                                {
                                    PurchaseOrderLineItem.Product__c = oProduct.PricebookEntry.Product2.Id;
                                    newPurchaseOrderLineItemList.add(PurchaseOrderLineItem);                                
                                }
                                                                
                                //Need a price book entry in order save an opportunity line item
                                productName = oProduct.PricebookEntry.Product2.Id;
                                
                                
                         }
                         if (!newPurchaseOrderLineItemList.isEmpty())
                                insert newPurchaseOrderLineItemList;
                     }
                     
                   }
                   
                    
                  message.add(newPurchaseOrder.Id);
                }   
                catch (Exception E) {
                    message.clear();
                    message.add('Purchase Order could not be generated!');
                    message.add(E.getMessage());
                }
            }
    
        }

        return message;
        
    }
    
    @isTest (seeAllData=true)
    public static void GenerateOpportunityPurchaseOrder()
    {
    
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

        User Usr = [Select id from User where Profile.Name ='Sales Support' and isActive = true limit 1];
        system.runAs(Usr){
        
            //Insert Test Account
            Account custAcc = new Account( Name = 'Test Account',
                                       Type = 'Customer',
                                       Phone = '01234567890'
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
            
            //Insert Test Opportunity Line Item       
            OpportunityLineItem OppLi = new OpportunityLineItem( OpportunityId = Opp.Id,
                                                                 Quantity=1,
                                                                 TotalPrice = 1,
                                                                 PriceBookEntryId = PbE1.Id
                                                               );
            insert OppLi;
                                             
            generatePurchaseOrder(Opp.Id,suppAcc.Id);
            
        }
    }
    
}