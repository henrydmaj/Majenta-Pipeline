global class SupportContractRenewal {

public class Test_Exception extends Exception{}
    
 @AuraEnabled    
    public static integer opportunityCount(String sContractId){
        system.debug('opportunityCountmethod'+ sContractId);
        integer oppCountList = [select count() from opportunity where Support_Contract__c = :sContractId ];
         return oppCountList;
         
    } 
    
 @AuraEnabled 

     WebService static String[] renewOpportunity(String sContractId)


             
    {

        //Opp Record Type - Majenta Contract Renewals
        Id oppContractRenewalRTId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Majenta Contract Renewals').getRecordTypeId();
        
        //Price Book Id - Maintenance Pricebook
        Pricebook2 maintPriceBook = [select id from Pricebook2 where name = 'Maintenance Pricebook' limit 1];
        
        List<String> message = new List<String>();
        if(sContractId!=null)
        {
            
           //Conversion currency map
           Map<String,Double> CurrencyConversionRate_Map = new Map<String,Double>();
           for (CurrencyType CT:[select Id,ConversionRate,IsoCode from CurrencyType])
           {
                CurrencyConversionRate_Map.put(CT.IsoCode,CT.ConversionRate);
           }
           // Get the Partner, Solution Type and Division from the most recent related Opportunity
           Opportunity opp = [Select Id, 
                                     Partner__c,
                                     SolutionType__c,
                                     Division__c
                                     From Opportunity 
                                     Where Support_Contract__c = :sContractId 
                                     Order By CloseDate DESC LIMIT 1];
            // Current support contract record
            Support_Contracts__c sContract = [Select s.Id,
                                                     s.Supported_By__c, 
                                                     s.OwnerId, 
                                                     s.Name,
                                                     s.Start_Date__c, 
                                                     s.Finish_Date__c, 
                                                     s.Account__c,
                                                     s.Account__r.Name,
                                                     s.Division__c,
                                                     s.CurrencyIsoCode 
                                                     From Support_Contracts__c s where s.Id=:sContractId];
            if(sContract!=null)    
            {
                String productName;
                try{
                    // mapping between support contract record and new opportunity
                    Opportunity newOpp = new Opportunity( OwnerId = sContract.OwnerId,
                                                          Name = sContract.Account__r.Name+' - '+sContract.Supported_By__c+' - '+sContract.Name,
                                                          AccountId = sContract.Account__c,
                                                          Support_Contract__c = sContract.Id,
                                                          Division__c = opp.Division__c,
                                                          Partner__c = opp.Partner__c,
                                                          SolutionType__c = opp.SolutionType__c,
                                                          ContractFinishDate__c = sContract.Finish_Date__c,
                                                          CloseDate = sContract.Finish_Date__c,
                                                          CurrencyIsoCode = sContract.CurrencyIsoCode,
                                                          Type = 'Existing Customer Maintenance Renewal', 
                                                          StageName = 'Quoted',
                                                          //RecordTypeId = '01220000000Dxtg',
                                                          RecordTypeId = oppContractRenewalRTId,                                                                                                                                              
                                                          //PriceBook2Id = '01s20000000Psux'
                                                          PriceBook2Id = maintPriceBook.id                                                          
                                                          );
                    if(newOpp.CloseDate == null)
                        newOpp.CloseDate = System.Date.today();
                    insert newOpp;
                    
                    // List of support product records associated to the current support contract record
                    List<Support_Product__c> sProductList = new List<Support_Product__c>([Select s.Total_Sale_Price__c, 
                                                                                                 s.Total_Buy__c, 
                                                                                                 s.Start_Date__c, 
                                                                                                 s.Product_Description__c, 
                                                                                                 s.Number_of_Users__c, 
                                                                                                 s.Id,
                                                                                                 s.Contract_No_Site_ID__c,
                                                                                                 s.CurrencyIsoCode,
                                                                                                 s.Product__c,
                                                                                                 s.Product__r.Name, 
                                                                                                 s.Finish_Date__c From Support_Product__c s 
                                                                                                 where s.Support_Contract__c =:sContract.Id]);
                   
                   if(!sProductList.isEmpty())
                   { 
                     
                     Map<Id,Id> priceBookEntryList = new Map<Id,Id>();
                     Set<Id> setProductId = new Set<Id>();
                     for(Support_Product__c sProduct:sProductList)
                     {
                        setProductId.add(sProduct.Product__c);
                     }
                     if(!setProductId.isEmpty())
                     {
                        // List of price book entries
                        for(PriceBookEntry pBE:[Select Id,Product2Id,CurrencyIsoCode from PriceBookEntry 
                                                                  where Product2Id IN:setProductId 
                                                                  and Pricebook2Id=:newOpp.PriceBook2Id 
                                                                  and CurrencyIsoCode=:newOpp.CurrencyIsoCode 
                                                                  and isActive=true])
                         {
                                
                                if(!priceBookEntryList.containsKey(pBE.Product2Id))
                                {
                                    priceBookEntryList.put(pBE.Product2Id,pBE.Id);
                                }                                                                    
                                                                                                   
                         }                                                                         
                                                                                                  
                         List<OpportunityLineItem> newOppLineItemList = new List<OpportunityLineItem>();
                         for(Support_Product__c sProduct:sProductList)
                         {
                                OpportunityLineItem oppLineItem  = new  OpportunityLineItem( 
                                                                                             Contract_No_Site_ID__c = sProduct.Contract_No_Site_ID__c,
                                                                                             StartDate__c = sContract.Start_Date__c,
                                                                                             FinishDate__c = sContract.Finish_Date__c,
                                                                                             Current_Expiry_Date__c = sContract.Finish_Date__c,
                                                                                             Support_Product__c = sProduct.Id,
                                                                                             OpportunityId = newOpp.Id
                                                                                              );
                                 
                                if(sContract.Start_Date__c!=null && sContract.Finish_Date__c!=null)
                                {
                                    oppLineItem.Contract_Length_Months__c = sContract.Start_Date__c.monthsBetween(sContract.Finish_Date__c);
                                    //Rounding up
                                    if(math.abs(sContract.Start_Date__c.day() - sContract.Finish_Date__c.day())>15 )
                                    {
                                        oppLineItem.Contract_Length_Months__c ++;
                                    }
                                }
                                
                                //Convert UnitPrice into the Opportunity currency 
                                if(sProduct.Total_Buy__c!=null)
                                 oppLineItem.Buy_Price__c  =  (sProduct.Total_Buy__c / CurrencyConversionRate_Map.get(sProduct.CurrencyIsoCode))*CurrencyConversionRate_Map.get(newOpp.CurrencyIsoCode);
                                
                                // Quantity needs to be greater than 0
                                if(sProduct.Number_of_Users__c!=null && sProduct.Number_of_Users__c >0)                                                 
                                {   
                                    oppLineItem.Quantity =  sProduct.Number_of_Users__c;
                                }
                                else{
                                    oppLineItem.Quantity = 1;
                                }
                                //Description needs to contains more 4 characters
                                if(sProduct.Product_Description__c!=null && sProduct.Product_Description__c.length()>=5)                                                    
                                {   
                                    oppLineItem.Description =  sProduct.Product_Description__c;
                                }
                                else{
                                    oppLineItem.Description = 'Please complete the Description';
                                }
                                
                                //Convert UnitPrice into the Opportunity currency 
                                if(sProduct.Total_Buy__c!=null)
                                 oppLineItem.Buy_Price__c  =  (sProduct.Total_Buy__c / CurrencyConversionRate_Map.get(sProduct.CurrencyIsoCode))*CurrencyConversionRate_Map.get(newOpp.CurrencyIsoCode) / oppLineItem.Quantity;

                                
                                //Need to specify a Sales price
                                if(sProduct.Total_Sale_Price__c!=null)                                                  
                                {   
                                    oppLineItem.UnitPrice =  (sProduct.Total_Sale_Price__c / CurrencyConversionRate_Map.get(sProduct.CurrencyIsoCode))*CurrencyConversionRate_Map.get(newOpp.CurrencyIsoCode) / oppLineItem.Quantity;
                                }
                                else{
                                    oppLineItem.UnitPrice = 1;
                                }
                              
                                //System.debug('@@@@'+pBookEntryList);
                                if(!priceBookEntryList.isEmpty())
                                {
                                    if(priceBookEntryList.containsKey(sProduct.Product__c))
                                    {   
                                        oppLineItem.PriceBookEntryId = priceBookEntryList.get(sProduct.Product__c);
                                        newOppLineItemList.add(oppLineItem);
                                        
                                    }
                                    
                                }
                                
                                
                                //Need a price book entry in order save an opportunity line item
                               
                                productName = sProduct.Product__r.Name;
                                
                                
                         }
                         if (!newOppLineItemList.isEmpty())
                                insert newOppLineItemList;
                     }
                     
                   }
                   
                    
                  message.add(newOpp.Id);
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
    public static void TestSupportContractRenewal()
    {
    
        //Opp Record Type - Majenta Contract Renewals
        Id oppContractRenewalRTId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Majenta Contract Renewals').getRecordTypeId();
        
        //Price Book Id - Maintenance Pricebook
        Pricebook2 maintPriceBook = [select id from Pricebook2 where name = 'Maintenance Pricebook' limit 1];
        
        User jenna = [Select id from User where Profile.Name ='Sales Support' and isActive = true limit 1];
        system.runAs(jenna){
        // Create Product for Support Product
        Product2 productItem = new Product2(
            Name = 'Test Product',
            Family = 'IT',
            ProductCode = 'TESTP',
            Type__c = 'Software',
            Supplier_Discount__c = 0.00,
            Distributor2__c = 'N/A'
        );
        insert productItem;
        
        // Create Support Contract
        Support_Contracts__c supportContract = new Support_Contracts__c(
            Start_Date__c = Date.today().addDays(-7),
            Finish_Date__c = Date.today().addYears(1),
            Status__c = 'Active',
            Supported_By__c = 'Autodesk',
            Division__c = 'IT',
            Support_Contract_Type__c = 'Other'
        );
        insert supportContract;

        // Create Opportunity
        Opportunity newOpp = new Opportunity
            (Name = 'Test Opp',
            Support_Contract__c = supportContract.Id,
            Division__c = 'Overhead',
            Partner__c = 'Majenta',
            ContractFinishDate__c = System.today(),
            CloseDate = System.today(),
            CurrencyIsoCode = 'GBP',
            Type = 'Existing Customer Maintenance Renewal', 
            StageName = 'Quoted',
            //RecordTypeId = '01220000000Dxtg',
            RecordTypeId = oppContractRenewalRTId,                   
            //PriceBook2Id = '01s20000000Psux'
            PriceBook2Id = maintPriceBook.id   
        );
        insert newOpp;

        // Create Support Product
        Support_Product__c supportProduct = new Support_Product__c(
            Support_Contract__c = supportContract.Id,
            Product__c = productItem.Id,
            Type_of_License__c = 'LUM ',
            License_Type__c = 'ALC',
            Total_Sale_Price__c = 10.00,
            Total_Buy__c = 5.00
            );
        insert supportProduct;

        
            System.debug('>>>> Opp SupportContract ID '+ newOpp.Support_Contract__c);   
            // Id sContractId = [Select Support_Contract__c from Support_Product__c limit 1].Support_Contract__c;
            // SupportContractRenewal.renewOpportunity(sContractId);
            SupportContractRenewal.renewOpportunity(supportContract.Id);

        }
    }


}