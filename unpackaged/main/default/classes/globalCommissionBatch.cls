global class globalCommissionBatch implements Database.Batchable<sObject>{
    
    global final String query;
    global final Integer month;
    global final Integer year;

    global globalCommissionBatch(string q, Integer theMonth, Integer theYear){    
        query = q;
        month = theMonth;
        year = theYear;
    }
    
    //Start Method
    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(query);
    }

    //Execute Method
    global void execute(Database.BatchableContext BC, List<sObject> scope){
        globalCommissionMethods.CommissionMethods com = new globalCommissionMethods.CommissionMethods();
        com.generateCommission(scope, month, year);
    }
    
    //Finish Method
    global void finish(Database.BatchableContext BC){
        
        // Get the ID of the AsyncApexJob representing this batch job  
        // from Database.BatchableContext.    
        // Query the AsyncApexJob object to retrieve the current job's information.  
        
        AsyncApexJob a = [Select Id, Status, NumberOfErrors, JobItemsProcessed,
                          TotalJobItems, CreatedBy.Email
                          from AsyncApexJob where Id =:BC.getJobId()];
        
        // Send an email to the Apex job's submitter notifying of job completion.  
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] {a.CreatedBy.Email,'developer@majentasolutions.com'};
        	mail.setToAddresses(toAddresses);
        	mail.setSubject('Generate Commission Statements ' + a.Status);
        	mail.setPlainTextBody('The batch Apex job processed ' + a.TotalJobItems +
                              ' batches with '+ a.NumberOfErrors + ' failures.');
        
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        
    }
}