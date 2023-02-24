global class GenerateOpportunityInvoice {

public class Test_Exception extends Exception{}
@AuraEnabled 
    WebService static String[] generateInvoice(String OppId)
    {
        List<String> message = new List<String>();
        if(OppId!=null)
        {
            
           //Conversion currency map
           Map<String,Double> CurrencyConversionRate_Map = new Map<String,Double>();
           for (CurrencyType CT:[select Id,ConversionRate,IsoCode from CurrencyType])
           {
                CurrencyConversionRate_Map.put(CT.IsoCode,CT.ConversionRate);
           }
            // Current Opportunity Record
            Opportunity Opp = [Select o.Id,
                                      o.Company__c,
                                      o.CurrencyIsoCode,
                                      o.Customer_Order_Number__c,
                                      o.Account.Id,
                                      o.Account.ShippingStreet,
                                      o.Account.ShippingCity,
                                      o.Account.ShippingState, 
                                      o.Account.ShippingPostalCode,
                                      o.Account.ShippingCountry,
                                      o.Account.BillingStreet,
                                      o.Account.BillingCity,
                                      o.Account.BillingState, 
                                      o.Account.BillingPostalCode,
                                      o.Account.BillingCountry
                                      From Opportunity o where o.Id=:OppId];
                                                 
            if(Opp!=null)    
            {
                String productName;
                try{
                    // mapping between opportunity and new invoice
                    Invoice__c newInvoice = new Invoice__c( Opportunity__c = Opp.Id,
                                                            Date__c = System.Date.today(),
                                                            Company__c = Opp.Company__c,
                                                            CustomerOrderNumber__c = Opp.Customer_Order_Number__c,
                                                            CurrencyIsoCode = Opp.CurrencyIsoCode
                                                            );
                                                            
                    //Set Bill To & Ship To Accounts as Opp Account
                    newInvoice.ShippingAccount__c = Opp.Account.Id;
                    newInvoice.BillingAccount__c = Opp.Account.Id;
                    
                    //Put the shipping address together in to a single string, no longer than 255 characters
                    String ShippingAddress ='';
                        if(Opp.Account.ShippingStreet != null)
                        {
                            ShippingAddress += Opp.Account.ShippingStreet;
                        }
                        if(Opp.Account.ShippingCity != null)
                        {
                            ShippingAddress += '\n' + Opp.Account.ShippingCity;
                        }
                        if(Opp.Account.ShippingState != null)
                        {
                            ShippingAddress += '\n' + Opp.Account.ShippingState;
                        }
                        if(Opp.Account.ShippingPostalCode != null)
                        {
                            ShippingAddress += '\n' + Opp.Account.ShippingPostalCode;
                        }
                        if(Opp.Account.ShippingCountry != null)
                        {
                            ShippingAddress += '\n' + Opp.Account.ShippingCountry;
                        }
                    if(ShippingAddress.length()>255)
                        newInvoice.ShippingAddress2__c = ShippingAddress.substring(0, 255);
                    else
                        newInvoice.ShippingAddress2__c = ShippingAddress;
                        
                    //Put the billing address together in to a single string, no longer than 255 characters
                    String BillingAddress ='';
                        if(Opp.Account.BillingStreet != null)
                        {
                            BillingAddress += Opp.Account.BillingStreet;
                        }
                        if(Opp.Account.BillingCity != null)
                        {
                            BillingAddress += '\n' + Opp.Account.BillingCity;
                        }
                        if(Opp.Account.BillingState != null)
                        {
                            BillingAddress += '\n' + Opp.Account.BillingState;
                        }
                        if(Opp.Account.BillingPostalCode != null)
                        {
                            BillingAddress += '\n' + Opp.Account.BillingPostalCode;
                        }
                        if(Opp.Account.BillingCountry != null)
                        {
                            BillingAddress += '\n' + Opp.Account.BillingCountry;
                        }
                    if(BillingAddress.length()>255)
                        newInvoice.BillingAddress2__c = BillingAddress.substring(0, 255);
                    else
                        newInvoice.BillingAddress2__c = BillingAddress;
                    
                    insert newInvoice;
                    
                    // List of support product records associated to the current support contract record
                    List<OpportunityLineItem> oProductList = new List<OpportunityLineItem>([SELECT p.PricebookEntryId,
                                                                                                   p.PricebookEntry.Product2.Id,
                                                                                                   p.PricebookEntry.Product2.Name,
                                                                                                   p.PricebookEntry.Product2.Description,
                                                                                                   p.PricebookEntry.Product2.Category__c,
                                                                                                   p.Description, 
                                                                                                   p.Quantity, 
                                                                                                   p.UnitPrice,
                                                                                                   p.Finish_Date__c,
                                                                                                   p.SortOrder,
                                                                                                   p.StartDate__c,
                                                                                                   p.FinishDate__c,
                                                                                                   p.Contract_No_Site_ID__c,
                                                                                                   p.BusinessType2__c 
                                                                                                   FROM OpportunityLineItem p 
                                                                                                   WHERE p.OpportunityId =:Opp.Id
                                                                                                   ORDER BY p.SortOrder]);
                   
                   if(!oProductList.isEmpty())
                   { 
                     
                     Map<Id,Id> priceBookEntryList = new Map<Id,Id>();
                     Set<Id> setProductId = new Set<Id>();
                     for(OpportunityLineItem oProduct:oProductList)
                     {
                        setProductId.add(oProduct.PricebookEntryId);
                     }
                     if(!setProductId.isEmpty())
                     {
                                                  
                                                                                                  
                         List<InvoiceLineItem__c> newInvoiceLineItemList = new List<InvoiceLineItem__c>();
                         for(OpportunityLineItem oProduct:oProductList)
                         {
                                InvoiceLineItem__c InvoiceLineItem  = new  InvoiceLineItem__c( 
                                                                                             Invoice__c = newInvoice.Id,
                                                                                             CurrencyIsoCode = newInvoice.CurrencyIsoCode,
                                                                                             SortOrder__c = oProduct.SortOrder, 
                                                                                             BusinessType2__c = oProduct.BusinessType2__c
                                                                                              );
                                if(InvoiceLineItem.CurrencyIsoCode!='GBP')
                                {
                                    InvoiceLineItem.TaxRate__c = 0;
                                }
                                
                                //Convert UnitPrice into the Opportunity currency 
                                //Need to specify a Sales price
                                if(oProduct.UnitPrice!=null)                                                  
                                {   
                                    InvoiceLineItem.UnitPrice__c =  (oProduct.UnitPrice / CurrencyConversionRate_Map.get(Opp.CurrencyIsoCode))*CurrencyConversionRate_Map.get(Opp.CurrencyIsoCode);
                                }
                                else{
                                    InvoiceLineItem.UnitPrice__c = 1;
                                }
                                
                                // Quantity needs to be greater than 0
                                if(oProduct.Quantity!=null && oProduct.Quantity >0)                                                 
                                {   
                                    InvoiceLineItem.Quantity__c =  oProduct.Quantity;
                                }
                                else{
                                    InvoiceLineItem.Quantity__c = 1;
                                }
                                
                                //Name needs to contains more 1 characters
                                if(oProduct.PricebookEntry.Product2.Name!=null && oProduct.PricebookEntry.Product2.Name.length()>=1)                                                    
                                {   
                                    if(oProduct.PricebookEntry.Product2.Name.length()>80)
                                        InvoiceLineItem.Name =  oProduct.PricebookEntry.Product2.Name.substring(0, 80);
                                    else
                                        InvoiceLineItem.Name =  oProduct.PricebookEntry.Product2.Name;
                                }
                                else{
                                    InvoiceLineItem.Name = 'Please complete the Name';
                                }
                                                                
                                //Description needs to contains more 5 characters
                                if(oProduct.Description!=null && oProduct.Description.length()>=5)                                                    
                                {   
                                    InvoiceLineItem.Description__c =  oProduct.Description;
                                }
                                else if(oProduct.PricebookEntry.Product2.Description!=null){
                                    InvoiceLineItem.Description__c =  oProduct.PricebookEntry.Product2.Description;
                                }
                                else{
                                    InvoiceLineItem.Description__c = 'Please complete the Description';
                                }
                                                                                                
                                if(oProduct.StartDate__c!=null && oProduct.FinishDate__c!=null)
                                {
                                    InvoiceLineItem.Description__c += '\n'+oProduct.StartDate__c.format()+' to '+oProduct.FinishDate__c.format();
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
                                    
                                    InvoiceLineItem.Description__c += '\n'+cnsidDesc+': '+oProduct.Contract_No_Site_ID__c;
                                }
                                                                                              
                                //System.debug('@@@@'+pBookEntryList);
                                if(oProduct.PricebookEntryId!=null)
                                {
                                    InvoiceLineItem.Product__c = oProduct.PricebookEntry.Product2.Id;
                                    newInvoiceLineItemList.add(InvoiceLineItem);                                
                                }
                                
                                
                                //Need a price book entry in order save an opportunity line item
                               
                                productName = oProduct.PricebookEntry.Product2.Id;
                                
                                
                         }
                         if (!newInvoiceLineItemList.isEmpty())
                                insert newInvoiceLineItemList;
                     }
                     
                   }
                   
                    
                  message.add(newInvoice.Id);
                }   
                catch (Exception E)
                {
                    message.clear();
                    message.add('Error');
                    message.add('Error on product '+productName +' '+E.getMessage());
                
                }
            }
    
        }

    return message;

    }
    
    @isTest (seeAllData=true)
    public static void GenerateOpportunityInvoice()
    {
            
        Pricebook2 Pb = [SELECT Id FROM Pricebook2 WHERE IsStandard = true];
                    
        Product2 P = new Product2( Name = 'Test Product',
                                   Description = 'Test Product Description',
                                   Family = 'Test',
                                   ProductCode = 'TEST1234'
                                  );
        insert P;
        
        PricebookEntry PbE = new PricebookEntry( Pricebook2Id = Pb.Id,
                                                 Product2Id = P.Id,
                                                 IsActive = TRUE,
                                                 UseStandardPrice= FALSE,
                                                 UnitPrice = 0.00
                                               );
        insert PbE;
            
        User Usr = [Select id from User where Profile.Name ='Sales Support' and isActive = true limit 1];
        system.runAs(Usr){
        
            //Insert Test Account
            Account Acc = new Account( Name = 'Test Account12345678',
                                       Type = 'Customer',
                                       Phone = '01234567890',
                                       ShippingStreet = 'Test Street',
                                       ShippingCity = 'Test City',
                                       ShippingState = 'Test State', 
                                       ShippingPostalCode = 'Test Postal Code',
                                       ShippingCountry = 'Test Country',
                                       BillingStreet = 'Test Street',
                                       BillingCity = 'Test City',
                                       BillingState = 'Test State',
                                       BillingPostalCode = 'Test Postal Code',
                                       BillingCountry = 'Test Country'
                                     );
            insert Acc;
            
            //Insert Test Opportunity
            Opportunity Opp = new Opportunity( Name = 'TestOpp',
                                               AccountId = Acc.Id,
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
                                                                 PriceBookEntryId = PbE.Id
                                                               );
            insert OppLi;
                                             
            GenerateOpportunityInvoice.generateInvoice(Opp.Id);
            
        }
    }


}