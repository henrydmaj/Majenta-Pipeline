@isTest
private class numberOfSiteAccounts_Test {
    /**
* Test setup method to create test records.
*/
    @isTest
    
    static void createData() {

        list<account> updatecc = new list<account>();
        
        Account parentacc2 = new account();
        parentacc2.Name = 'testparent1';
        parentacc2.Vendor_Master_Code__c = 'TRTY1';
        parentacc2.ActiveSiteAccounts__c = 4;
        
        
        Account parentacc = new account();
        parentacc.Name = 'testparent';
        parentacc.Vendor_Master_Code__c = 'TRTY';
        parentacc.ActiveSiteAccounts__c = 4;
      //  parentacc.recordtypeid = RecordTypeIdAccount;
        
        
        test.startTest();
        Insert parentacc;
        Insert parentacc2;
        
        Account acc = new account();
        acc.Name = 'test';
        acc.Has_subscription__c = true;
        acc.ParentId = parentacc.id;
        
        
        insert acc;
        
       	acc.ParentId = parentacc2.id;
        
        update acc;
       
        //updatecc.add(acc);
        
       // acc.Has_subscription__c = true;
        
       // update acc;
        
     //   delete acc;
        
      //  numberOfSiteAccounts siteacc = new numberOfSiteAccounts();
        //numberOfSiteAccounts.rollUpSiteAccounts(updatecc, null);
        
        //System.assertEquals(true, updatecc[0].Has_subscription__c);
        test.stopTest();
        
    }
    @isTest
    static void createDataOld() {

        list<account> updatecc = new list<account>();
        //list<account> insertAcc = New list<Account>();
        Account parentacc = new account();
        parentacc.Name = 'testparent';
        parentacc.Vendor_Master_Code__c = 'TRTY';
        parentacc.ActiveSiteAccounts__c = 4;
        parentacc.Paid_subscription__c = true;
      //  parentacc.recordtypeid = RecordTypeIdAccount;
        
        
        test.startTest();
        Insert parentacc;
        
        Account acc = new account();
        acc.Name = 'test';
        acc.Has_subscription__c = false;
        acc.ParentId = parentacc.id;
        
        //insertAcc.add(acc);
        
        insert acc;
        
        acc.Has_subscription__c = true;
        
        update acc;
        updatecc.add(acc);
        
       // acc.Has_subscription__c = true;
        
       // update acc;
        
        delete updatecc[0];
        
      //  numberOfSiteAccounts siteacc = new numberOfSiteAccounts();
        //numberOfSiteAccounts.rollUpExisitngAccounts(updatecc);
        
       // System.assertEquals(true, updatecc[0].Has_subscription__c);
        test.stopTest();
        
    }
}