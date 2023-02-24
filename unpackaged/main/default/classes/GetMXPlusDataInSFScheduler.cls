public class GetMXPlusDataInSFScheduler implements Schedulable , Database.AllowsCallouts{
    
    public void execute(SchedulableContext ctx) {
        
        String startDateTime;
		String endDateTime;
        
        List<MXPlus_Data__mdt > mxMetaDataList = [ SELECT masterlabel , AuthToken__c, ServiceProvider__c FROM MXPlus_Data__mdt ];
        
        if( mxMetaDataList.size() > 0 ) {
            
            	if(DateTime.now().time() == Time.newInstance(00, 00, 00, 000)){
     				startDateTime    = (DateTime.now().addHours(-2)).format('yyyy-MM-dd') + 'T' + (DateTime.now().addHours(-2)).format('HH:mm') +'Z';
     				endDateTime      = DateTime.now().format('yyyy-MM-dd') + 'T' + DateTime.now().format('HH:mm') +'Z';
				}
				else{
 					startDateTime    = (DateTime.now().addHours(-2)).format('yyyy-MM-dd') + 'T' + (DateTime.now().addHours(-2)).format('HH:mm') +'Z';
 					endDateTime      = DateTime.now().format('yyyy-MM-dd') + 'T' + DateTime.now().format('HH:mm') +'Z';
				}
					//startDateTime    = (DateTime.now().addHours(-2)).format('yyyy-MM-dd') + 'T' + (DateTime.now().addHours(-2)).format('hh:mm') +'Z';
            		//endDateTime      = (DateTime.now()).format('yyyy-MM-dd') + 'T' + (Datetime.now().addMinutes(-1)).format('hh:mm') +'Z';
            
           	 	system.debug('startDateTime: '+startDateTime);
            	system.debug('endDateTime: '+endDateTime);
            //for testing job errors hard coded dates
            //String startDateTime    = '2020-09-07T00:00Z';
            //String endDateTime      = '2020-09-07T18:00Z';

            for( MXPlus_Data__mdt mx : mxMetaDataList ) {  
                GetMXPlusDatainSF.processMXPlusData( mx.AuthToken__c, mx.ServiceProvider__c, startDateTime, endDateTime);                    
            }
        }        
    }
}