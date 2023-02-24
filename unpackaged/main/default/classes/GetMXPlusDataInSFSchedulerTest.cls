@isTest
public class GetMXPlusDataInSFSchedulerTest {
	@isTest
    static void testScheduler(){
        MXPlus_Data__mdt nct = getCustomMetadataRecord('testmetadata');
        
        // MXParentTransaction__c newMXP = new MXParentTransaction__c(TransactionID__c = '281201');
        // Insert newMXP;
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('getMXPlusResource');
        mock.setStatusCode(200);
        mock.setHeader('Content-type', 'application/json');
        Test.setMock(HttpCalloutMock.class, mock);
        
        
        Test.startTest();
            
            GetMXPlusDataInSFScheduler sh1 = new GetMXPlusDataInSFScheduler();      
            String sch = '0  00 1 3 * ?';
            system.schedule('Test', sch, sh1);
        
        Test.stopTest();
    }
    
    static MXPlus_Data__mdt getCustomMetadataRecord(String myName) {
        MXPlus_Data__mdt theRecord = new MXPlus_Data__mdt();
        theRecord.DeveloperName = myName;
        theRecord.AuthToken__c  = 'sdgfghsfuwefwey24464782.wefhjggefjwgej763.ewjhfgwef873';
        theRecord.ServiceProvider__c	= 'Nissan';
        theRecord.MasterLabel	= myname;
        return theRecord;
    }
}