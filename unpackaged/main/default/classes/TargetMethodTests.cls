@isTest(seeAllData=true)
public class TargetMethodTests {
    
    //These tests currently cover the following apex classes
    // * globalTargetMethods
    // * OpportunityTriggerHandler
    // * RevenueRecognisedTriggerHandler
    
    public static testmethod void testOpportunityTriggers(){
    
        Profile pf = [Select Id from Profile where Name = 'System Administrator'];
 
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
        insert u;
        
        
        system.runAs(u){
        //Insert Test Supplier Account
        Account suppAcc = new Account( Name = 'Test Supplier Account',
                                       Type = 'Supplier'
                                     );
        insert suppAcc;
        
        //Get the standard pricebook
        Pricebook2 Pb = [SELECT Id FROM Pricebook2 WHERE IsStandard = true];
        
        //Insert Test Product 1            
        Product2 prod1 = new Product2( Name = 'Test Product 1',
                                       Description = 'Test Product 1 Description',
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
 
        
            Test.startTest();
            //Create a new Target
            Target__c t1 = new Target__c();
            t1.Name = 'Test Target';
            t1.Year__c = String.ValueOf(System.Today().Year());
            insert t1;
        
            //Test Opportunity on insert
            Opportunity opp1 = new Opportunity();
            opp1.Name = 'Test Opportunity #1';
            opp1.Type = 'New Customer New Business';
            opp1.StageName = 'Order In - Processed';
            opp1.Probability = 100;
            opp1.CloseDate = System.Today();
            opp1.Customer_Order_Number__c = '1234';
            //opp1.Amount = 1000;
            insert opp1;
            
            //Insert Test Opportunity Line Item       
            OpportunityLineItem opp1Li1 = new OpportunityLineItem();
            opp1Li1.OpportunityId = opp1.Id;
            opp1Li1.Quantity = 1;
            opp1Li1.TotalPrice = 1000;
            opp1Li1.PriceBookEntryId = PbE1.Id;
            insert opp1Li1;
            
            Opportunity opp1test1 = [SELECT Amount, Target__r.Id FROM Opportunity WHERE Id = :opp1.Id];
            Target__c t1Test1 = [SELECT Id, RevenueClosed__c FROM Target__c WHERE Id = :t1.Id];
            
            system.assertEquals(t1.Id, opp1test1.Target__r.Id); //check target was added
            system.assertEquals(opp1test1.Amount, t1Test1.RevenueClosed__c); //check opp1 amount was added to target
            
            //Insert some related Revenue__c records
            Revenue__c rev1 = new Revenue__c();
            rev1.Opportunity__c = opp1.Id;
            rev1.Type__c = 'SI';
            rev1.BusinessType__c = 'New';
            rev1.GrossAmount__c = 1000;
            rev1.GrossMargin__c = 1000;
            insert rev1;
            
            Target__c t1Test2 = [SELECT Id, RevenueRecognised__c FROM Target__c WHERE Id = :t1.Id];
            
            system.assertEquals(rev1.GrossAmount__c, t1Test2.RevenueRecognised__c); //check rev1 amount was added to target
            
            //Test Opportunity on update to remove from target
            Opportunity opp1update1 = [SELECT CloseDate FROM Opportunity WHERE Id = :opp1.Id];
            opp1update1.CloseDate = System.Today().AddYears(1); //add one year
            update opp1update1;
            
            Opportunity opp1test2 = [SELECT Target__c FROM Opportunity WHERE Id = :opp1.Id];
            Target__c t1Test3 = [SELECT Id, RevenueClosed__c, RevenueRecognised__c FROM Target__c WHERE Id = :t1.Id];
            
            system.assertEquals(TRUE, opp1test2.Target__c == null); //check target was removed
            system.assertEquals(0, t1Test3.RevenueClosed__c); //check opp1 amount was removed from target
            system.assertEquals(0, t1Test3.RevenueRecognised__c); //check rev1 amount was removed from target
            
            //Test Opportunity on update to add to target
            Opportunity opp1update2 = [SELECT CloseDate FROM Opportunity WHERE Id = :opp1.Id];
            opp1update2.CloseDate = System.Today();
            update opp1update2;
            
            Opportunity opp1test3 = [SELECT Amount, Target__r.Id FROM Opportunity WHERE Id = :opp1.Id];
            Target__c t1Test4 = [SELECT Id, RevenueClosed__c, RevenueRecognised__c FROM Target__c WHERE Id = :t1.Id];
            
            system.assertEquals(t1.Id, opp1test3.Target__r.Id); //check target was added
            system.assertEquals(opp1test3.Amount, t1Test4.RevenueClosed__c); //check opp1 amount was added from target
            system.assertEquals(rev1.GrossAmount__c, t1Test4.RevenueRecognised__c); //check rev1 amount was added from target
            
            //Test Opportunity on second insert
            Opportunity opp2 = new Opportunity();
            opp2.Name = 'Test Opportunity #2';
            opp2.Type = 'New Customer New Business';
            opp2.StageName = 'Order In - Processed';
            opp2.Probability = 100;
            opp2.CloseDate = System.Today();
            opp2.Customer_Order_Number__c = '1234';
            //opp2.Amount = 1000;
            insert opp2;
            
            //Insert Test Opportunity Line Item       
            OpportunityLineItem opp2Li1 = new OpportunityLineItem();
            opp2Li1.OpportunityId = opp2.Id;
            opp2Li1.Quantity = 1;
            opp2Li1.TotalPrice = 1000;
            opp2Li1.PriceBookEntryId = PbE1.Id;
            insert opp2Li1;
            
            Opportunity opp2test1 = [SELECT Target__r.Id FROM Opportunity WHERE Id = :opp2.Id];
            AggregateResult t1OppSum1 = [SELECT SUM(Amount) FROM Opportunity WHERE Target__c = :t1.Id];
            Target__c t1Test5 = [SELECT Id, RevenueRecognised__c, RevenueClosed__c FROM Target__c WHERE Id = :t1.Id];
            
            system.assertEquals(t1.Id, opp2test1.Target__r.Id); //check target was added
            system.assertEquals(t1Test5.RevenueClosed__c, t1OppSum1.get('expr0')); //check opp sum matches target value
            
            //Test Opportunity delete
            delete opp2;
            
            AggregateResult t1OppSum2 = [SELECT SUM(Amount) FROM Opportunity WHERE Target__c = :t1.Id];
            Target__c t1Test6 = [SELECT Id, RevenueRecognised__c, RevenueClosed__c FROM Target__c WHERE Id = :t1.Id];
            
            system.assertEquals(t1Test6.RevenueClosed__c, t1OppSum2.get('expr0')); //check opp sum matches target value
            
            //Test Opportunity undelete
            undelete opp2;
            
            AggregateResult t1OppSum3 = [SELECT SUM(Amount) FROM Opportunity WHERE Target__c = :t1.Id];
            Target__c t1Test7 = [SELECT Id, RevenueRecognised__c, RevenueClosed__c FROM Target__c WHERE Id = :t1.Id];
            
            system.assertEquals(t1Test7.RevenueClosed__c, t1OppSum3.get('expr0')); //check opp sum matches target value
            
            
            //Test Revenue__c on update
            Revenue__c rev1update1 = [SELECT GrossAmount__c, GrossMargin__c FROM Revenue__c WHERE Id = :rev1.Id];
            rev1update1.GrossAmount__c = 2000;
            rev1update1.GrossMargin__c = 2000;
            update rev1update1;
            
            Target__c t1Test8 = [SELECT RevenueRecognised__c, MarginRecognised__c FROM Target__c WHERE Id = :t1.Id];
            
            system.assertEquals(rev1update1.GrossAmount__c, t1Test8.RevenueRecognised__c); //check rev1 amount was updated on target
            system.assertEquals(rev1update1.GrossMargin__c, t1Test8.MarginRecognised__c); //check rev1 margin was updated on target
            
            //Test Revenue__c on delete
            delete rev1;
            
            Target__c t1Test9 = [SELECT RevenueRecognised__c, MarginRecognised__c FROM Target__c WHERE Id = :t1.Id];
            
            system.assertEquals(0, t1Test9.RevenueRecognised__c); //check rev1 amount was removed from target
            system.assertEquals(0, t1Test9.MarginRecognised__c); //check rev1 margin was removed from target
            
            //Test Revenue__c on undelete
            undelete rev1;
            
            Target__c t1Test10 = [SELECT RevenueRecognised__c, MarginRecognised__c FROM Target__c WHERE Id = :t1.Id];
            
            system.assertEquals(rev1update1.GrossAmount__c, t1Test10.RevenueRecognised__c); //check rev1 amount was added to target
            system.assertEquals(rev1update1.GrossMargin__c, t1Test10.MarginRecognised__c); //check rev1 margin was added to target
            Test.stopTest();
            //Test the WebService
            globalTargetMethods.updateThisTarget(t1.Id);
 
        }
    
    }
    
}