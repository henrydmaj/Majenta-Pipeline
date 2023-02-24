@istest(SeeAllData = true) 
public class opportunitylineitem_Test
{
   public Static testmethod void test1()
    {
       
     // list<Pricebook2> custompricebook = [SELECT Id,Name FROM Pricebook2];
      Id pricebookId = Test.getstandardpricebookid();
       
      
      PriceBook2 pb2=new PriceBook2();
        pb2.Name = 'test';
        pb2.IsActive = true;
        
        insert pb2;
      
      Product2 productObj1 = new Product2(Name = 'BURE160475', IsActive = true , productcode = 'ENJ001');
      insert productObj1;
      Product2 productObj2 = new Product2(Name = 'BURE',IsActive = true);
      insert productObj2;
      Opportunity opp = new Opportunity(Name='Test',
                            StageName='Submitted',
                            CloseDate=Date.today(),Pricebook2Id = pb2.id);    
      insert Opp;    
      PricebookEntry pbe1 = new PricebookEntry(Product2Id=productObj1.Id,
                                               Pricebook2Id=pricebookId,
                                               UnitPrice=100000,
                                             
                                               isActive=true);
      PricebookEntry pbe2 = new PricebookEntry(Product2Id=productObj1.Id,
                                               Pricebook2Id=pb2.id,
                                               UnitPrice=200000,
                                             
                                               isActive=true);
      insert pbe1;
      insert pbe2;    
      OpportunityLineItem oli1 = new OpportunityLineItem(OpportunityId=Opp.Id,PricebookEntryId=pbe2.Id,Quantity=1,UnitPrice = 100);
      OpportunityLineItem oli2 = new OpportunityLineItem(
          OpportunityId=Opp.Id,
          PricebookEntryId=pbe2.Id,
          Quantity=1,UnitPrice = 100
      );
  
 list<OpportunityLineItem> olilist = new list<OpportunityLineItem>();
  olilist.add(oli1);
  olilist.add(oli2);
  
  insert olilist ;
        opp.Number_of_sites__c = 1;
  delete olilist;      
        opp.Number_of_sites__c = null;
  
  
 //opportunityLineItemHandler opportunityLineItemHandlerclass = new opportunityLineItemHandler();
  opportunityLineItemHandler.copyNumberOfSites(olilist);
 } 
 
 }