global class globalEmailPDF {
    @AuraEnabled
    WebService static void emailPDF(String recordId, String pageRef){
        
        String keyCode = recordId.subString(0,3);
        String objectName;
        
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
        for(Schema.SObjectType objectInstance : gd.values()) {
            if(keyCode.equals(objectInstance.getDescribe().getKeyPrefix())) {
                objectName = objectInstance.getDescribe().getName();
            }
        }
        
        String docType;
        String docName;
        String docDesc;
        
        if( objectName == 'Invoice__c' ){
            Invoice__c inv = [SELECT Id, InvoiceNumber__c, BillingAccount__r.Name FROM Invoice__c WHERE Id =: recordId LIMIT 1 ];
            
            docType = 'Invoice';
            docName = inv.InvoiceNumber__c;
            docDesc = inv.BillingAccount__r.Name;
        } else if ( objectName == 'CreditNote__c' ){
            CreditNote__c crd = [SELECT Id, CreditNumber__c, BillingAccount__r.Name FROM CreditNote__c WHERE Id =: recordId LIMIT 1 ];
            
            docType = 'Credit Note';
            docName = crd.CreditNumber__c;
            docDesc = crd.BillingAccount__r.Name;
        } else if ( objectName == 'PurchaseOrder__c' ){    
            PurchaseOrder__c po = [SELECT Id, Name, Supplier__r.Name FROM PurchaseOrder__c WHERE Id =: recordId LIMIT 1 ];
            
            docType = 'Purchase Order';
            docName = po.Name;
            docDesc = po.Supplier__r.Name;
        }
    
        //PageReference pdf = new PageReference('/apex/InvoiceSingle');
        PageReference pdf = new PageReference(pageRef);
        pdf.getParameters().put('id', recordId);
        pdf.getParameters().put('headed', '1');
        
        Blob pdfBlob;
        
        try {
            pdfBlob = pdf.getContentAsPDF();
        } catch (VisualforceException e) {
            pdfBlob = Blob.valueOf('Some Text');
        }
    
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();

        Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
        attachment.setFileName(docName + '.pdf');
        attachment.setBody(pdfBlob);

        String[] toAddresses = new String[] {UserInfo.getUserEmail()};
        String subject =  docType + ' ' + docName + ' ' + docDesc;
        String body = 'Your requested copy ' + docType +' is attached.';
        
        email.setToAddresses(toAddresses);
        email.setSubject(subject);
        email.setPlainTextBody(body);
        email.setFileAttachments(new Messaging.EmailFileAttachment[] {attachment});
        Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email}); 
    }

}