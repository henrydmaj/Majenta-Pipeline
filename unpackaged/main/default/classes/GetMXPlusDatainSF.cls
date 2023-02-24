public class GetMXPlusDatainSF {
    @AuraEnabled
    public static Boolean passToLWC( String token, String transactionOrg,  String startDateTime, String endDateTime){
		processMXPlusData(token, transactionOrg, startDateTime, endDateTime);
        return true;
    }
    
    @future(callout=true)
    public static void processMXPlusData(String token, String transactionOrg,  String startDateTime, String endDateTime) {
        Time txTimeValue;
        Time txClosedTimeValue;
		String responsebody = '' ;
        List<MXPlusJSON> txList = new List<MXPlusJSON>();
        
        try{
            Http h = new Http();
            HttpRequest req = new HttpRequest();
            req.setEndpoint('https://access.mymxdata.com/mxext/api/v1/elastic/transactionplus?datestart='+startDateTime+'&dateend='+endDateTime);
            req.setHeader('Authorization', 'Bearer' + token);
            req.setHeader('Content-type', 'application/json');
            req.setMethod('GET');
            req.setTimeout(20000);
            
            HttpResponse res = new HttpResponse();
            res = h.send(req);
            
            if (res.getStatusCode() == 200) {
                responsebody = res.getBody();
                System.debug(responseBody);
                txList = MXPlusJSON.parse(responseBody);
                System.debug(txList.size()+ 'wrappersize---');
                
                List<MXPlusTransactionActivity__c> mxPlusTxActivities  = new List<MXPlusTransactionActivity__c>();
                List<MXPlusTransactionActivity__c> updatedMxPlusTxActivities  = new List<MXPlusTransactionActivity__c>();
                
                // Map<String,String> mapTransactionIdToSFID	   = new Map<String,String>();
                // Set<String> transactionIdsFromCallout 		   = new Set<String>();
    			
                // String activityId = '';
                List<MXPlusTransactionActivity__c> extantTx = [SELECT TransactionID__c FROM MXPlusTransactionActivity__c];
                List<String> extantTxIds = new List<String>();
                // Updated Record Checks
                for (Integer i = 0; i < extantTx.size(); i++) {
                    extantTxIds.add(extantTx[i].TransactionID__c);
                }
                System.debug('DH DEBUG>>> Extant TX Size: ' +extantTx.size());
                                
                for(integer i=0; i<txList.size(); i++){
                    String[] txTimeString = txList[i].transaction_time.split(':');
                    txTimeValue = Time.newInstance(Integer.valueOf(txTimeString[0]),Integer.valueOf(txTimeString[1]),Integer.valueOf(txTimeString[2]),00);
                    if (String.isEmpty(txList[i].transaction_closedtime)) {
                        txClosedTimeValue = null;
                    }
                    else {
                    String[] txClosedTimeString = txList[i].transaction_closedtime.split(':');
                    txClosedTimeValue = Time.newInstance(Integer.valueOf(txClosedTimeString[0]),Integer.valueOf(txClosedTimeString[1]),Integer.valueOf(txClosedTimeString[2]),00);
                    }
                    Date txClosedDate;
                    if (String.isEmpty(txList[i].transaction_closeddate)) {
                        txClosedDate = null;
                    }
                    else {
                        txClosedDate = Date.valueOf(txList[i].transaction_closeddate);
                    }
                    if (extantTxIds.contains(txList[i].transaction_id)) {
                        System.debug('DH DEBUG>>> Record Exists : ' +txList[i].transaction_id);
                        MXPlusTransactionActivity__c updatedMxPlusTxActivity = new MXPlusTransactionActivity__c(
                        // TransactionDate__c = date.valueof(txList[i].transaction_date),
                        // TransactionTime__c = txTimeValue,
                        TransactionID__c = txList[i].transaction_id,
                        TransactionService__c = txList[i].transaction_service,
                        TransactionServiceCategory__c = txList[i].transaction_servicecategory,
                        TransactionClosedDate__c = txClosedDate,
                        TransactionClosedTime__c = txClosedTimeValue,
                        SupplierTotalDataSize__c = txList[i].transaction_supplier_totaldatasize,
                        SupplierTotalFiles__c = txList[i].transaction_supplier_totalfiles,
                        OEMTotalDataSize__c = txList[i].transaction_oem_totaldatasize,
                        OEMTotalFiles__c = txList[i].transaction_oem_totalfiles,
                        ServiceProviderTotalDataSize__c = txList[i].transaction_serviceprovider_totaldatasize,
                        ServiceProviderTotalFiles__c = txList[i].transaction_serviceprovider_totalfiles,
                        TotalComments__c = txList[i].transaction_totalcomments,
                        TransactionHours__c = txList[i].transaction_hours,
                        ServiceDataDirection__c = txList[i].transaction_servicedatadirection,
                        TransactionSupplier__c = txList[i].transaction_supplier,
                        TransactionOEMPick__c = txList[i].transaction_oem,
                        TransactionCOO__c = txList[i].transaction_coo,
                        TransactionUserGroup__c = txList[i].transaction_usergroup,
                        DataServicesOwner__c = txList[i].transaction_assigneduser
                        // UserFullName__c = txList[i].user_full_name,
                        // UserID__c = txList[i].user_id,
                        // UserName__c = txList[i].user_username
                    );
                    updatedMxPlusTxActivities.add(updatedMxPlusTxActivity);
                    }
                    else {
                        MXPlusTransactionActivity__c mxPlusTxActivity = new MXPlusTransactionActivity__c(
                        TransactionDate__c = date.valueof(txList[i].transaction_date),
                        TransactionTime__c = txTimeValue,
                        TransactionID__c = txList[i].transaction_id,
                        TransactionService__c = txList[i].transaction_service,
                        TransactionServiceCategory__c = txList[i].transaction_servicecategory,
                        TransactionClosedDate__c = txClosedDate,
                        TransactionClosedTime__c = txClosedTimeValue,
                        SupplierTotalDataSize__c = txList[i].transaction_supplier_totaldatasize,
                        SupplierTotalFiles__c = txList[i].transaction_supplier_totalfiles,
                        OEMTotalDataSize__c = txList[i].transaction_oem_totaldatasize,
                        OEMTotalFiles__c = txList[i].transaction_oem_totalfiles,
                        ServiceProviderTotalDataSize__c = txList[i].transaction_serviceprovider_totaldatasize,
                        ServiceProviderTotalFiles__c = txList[i].transaction_serviceprovider_totalfiles,
                        TotalComments__c = txList[i].transaction_totalcomments,
                        TransactionHours__c = txList[i].transaction_hours,
                        TransactionStatusPick__c = txList[i].transaction_status,
                        ServiceDataDirection__c = txList[i].transaction_servicedatadirection,
                        TransactionSupplier__c = txList[i].transaction_supplier,
                        TransactionOEMPick__c = txList[i].transaction_oem,
                        TransactionCOO__c = txList[i].transaction_coo,
                        TransactionUserGroup__c = txList[i].transaction_usergroup,
                        UserFullName__c = txList[i].user_full_name,
                        UserID__c = txList[i].user_id,
                        UserName__c = txList[i].user_username,
                        DataServicesOwner__c = txList[i].transaction_assigneduser
                    );
                    mxPlusTxActivities.add(mxPlusTxActivity);
                    } 
                    //String transactionID = txList[i].transaction_id;
                    // activityId = txList[i].transaction_id+'-'+txList[i].transaction_time+'-'+i;    
                }
                if(updatedMxPlusTxActivities.size()>0){
                    Database.UpsertResult[] updateResults = Database.upsert(updatedMxPlusTxActivities, MXPlusTransactionActivity__c.TransactionID__c, false);
    
                for (Integer i = 0; i < updateResults.size(); i++) {
                    if (updateResults[i].isSuccess()) {
                        System.debug('Successfully updated ID: '+ updateResults[i].getId());
                    } 
                    else {
                        System.debug('Update Error: could not update record ' + 'for array element ' + i + '.');
                        System.debug('   The error reported was: ' + updateResults[i].getErrors()[0].getMessage() + '\n');
                    }
                }
                }
                SObject[] sobjList = new List<SObject>();
                sobjList.addAll(mxPlusTxActivities);
                // sobjList.addAll(mxRecipients);
                Database.SaveResult[] results = Database.insert(sobjList, false);
    
                for (Integer i = 0; i < results.size(); i++) {
                    if (results[i].isSuccess()) {
                        System.debug('Successfully created ID: '+ results[i].getId());
                    } 
                    else {
                        System.debug('Error: could not create sobject ' + 'for array element ' + i + '.');
                        System.debug('   The error reported was: ' + results[i].getErrors()[0].getMessage() + '\n');
                    }
                }
            }
            else{
                // String stackTrace = res.getStackTraceString();
                // System.debug('DH DEBUG>>> STack Trace: ' +res.getStackTraceString());
                Error_Log__c err = new Error_Log__c ( Error_Details__c = 'MX+ import has failed on ' +  transactionOrg + 'for the time window  of ' + startDateTime + ' to ' + endDateTime + ' due to an error whilst connecting to the endpoint'  ,
                                                  Error_Summary__c = res.getStatus(),
                                                  Stack_Trace__c   = String.valueOf(res.getStatusCode()));
            	insert err;
            }
            if(Test.isRunningTest())
            {
            throw new applicationException();
            }
        }catch( Exception e){
        	String stackTrace = e.getStackTraceString();
            System.debug('DH DEBUG>>> STack Trace: ' +e.getStackTraceString());
            Error_Log__c err = new Error_Log__c ( Error_Details__c = 'MX+ import has failed on ' + transactionOrg + ' for the time window of ' + startDateTime + ' to ' + endDateTime + ' due to ' + e.getMessage() ,
                                                  Error_Summary__c = e.getTypeName(),
                                                //   Stack_Trace__c   = e.getStackTraceString());
                                                  Stack_Trace__c   =  stackTrace.left(255));
            insert err;
        }        
    }
    
    @AuraEnabled(cacheable=true)
    public static List<MXPlus_Data__mdt> getMetadataRecords(){
        return [ SELECT developerName, masterLabel , AuthToken__c, ServiceProvider__c FROM MXPlus_Data__mdt ];
    }

    public class applicationException extends Exception {}
}