@isTest
private class GetMXPlusDatainSFTest {
    @isTest(SeeAllData=true)
    static void calloutSuccess() {
        
        MXPlus_Data__mdt nct = getCustomMetadataRecord('testmetadata');
        
        // MXParentTransaction__c newMXP = new MXParentTransaction__c(TransactionID__c = '281201');
        // Insert newMXP;
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('GetMXPlusResource');
        mock.setStatusCode(200);
        mock.setHeader('Content-type', 'application/json');
        Test.setMock(HttpCalloutMock.class, mock);
        
        Test.startTest();
        	GetMXPlusDatainSF.passToLWC(nct.AuthToken__c , nct.ServiceProvider__c, '2020-01-14T07:00Z', '2020-01-14T08:00Z');
        	GetMXPlusDatainSF.passToLWC(nct.AuthToken__c , nct.ServiceProvider__c, '2020-01-14T07:00Z', '2020-01-14T08:00Z');
        Test.stopTest();
        
        // List<MXParentTransaction__c> mxParents = [SELECT Id FROM MXParentTransaction__c];
        // System.debug('mxParents Size: ' + mxParents.size());
        // System.assertEquals(2, mxParents.size());
        
        List<MXPlusTransactionActivity__c> mxActivities = [SELECT Id FROM MXPlusTransactionActivity__c WHERE TransactionDate__c = 2020-08-07];
        System.debug('MX+ Activities Size: ' + mxActivities.size());
        System.assertEquals(2,  mxActivities.size());
        
        
        // List<MXTransactionRecipient__c> mxRecipients = [SELECT Id FROM MXTransactionRecipient__c];
        // System.debug('mxRecipients Size: ' + mxRecipients.size());
        // System.assertEquals(1, mxRecipients.size());
    }
    
    
    @isTest
    static void calloutFail(){
        
        MXPlus_Data__mdt nct = getCustomMetadataRecord('testmetadata');
        
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('GetMXPlusResource');
        mock.setStatusCode(400);
        mock.setHeader('Content-type', 'application/json');
        Test.setMock(HttpCalloutMock.class, mock);
        HttpResponse res = new HttpResponse();
        res.setStatus('BAD REQUEST');
        res.setStatusCode(400);
        
        GetMXPlusDatainSF.passToLWC(nct.AuthToken__c , nct.ServiceProvider__c, '2020-01-14T07:00Z', '2020-01-14T08:00Z');
        Integer mailsSent = Limits.getFutureCalls();
        system.assertEquals(1, Limits.getFutureCalls(),'Emails are fired in a future call , not available real time');
    }
    
    @isTest
    static void mxCallOutLwcTest(){
        
        GetMXPlusDatainSF.getMetadataRecords();
        if( GetMXPlusDatainSF.getMetadataRecords().size() > 0 ){
            for( MXPlus_Data__mdt md : GetMXPlusDatainSF.getMetadataRecords()){
            	system.assert(md.masterLabel != '');
                system.assert(md.AuthToken__c != '');
                system.assert(md.ServiceProvider__c != '');
                system.assert(md.masterLabel != null);
                system.assert(md.AuthToken__c != null);
                system.assert(md.ServiceProvider__c != null);
        	}
        }        
    }
    
    static MXPlus_Data__mdt getCustomMetadataRecord(String myName) {
        MXPlus_Data__mdt theRecord = new MXPlus_Data__mdt();
        theRecord.DeveloperName = myName;
        theRecord.AuthToken__c  = 'sdgfghsfuwefwey24464782.wefhjggefjwgej763.ewjhfgwef873';
        theRecord.ServiceProvider__c		= 'Nissan';
        theRecord.MasterLabel	= myname;
        return theRecord;
    }
}