public class InvoiceProcessor {
    
    private static final String INVOICE_EMAIL_TEMPLATE = 'Invoice_template';
    private static final String INVOICE_QUOTE_TEMPLATE_ID = '0EH4J000000idSK';
    
    /**
    * Invocable Method To send email when a quote is accepted
    * @param        : List<Id> quoteIds
    * @return       : List<Id> quoteIds
    */
    @InvocableMethod(label='Create and Send Invoice')
    public static List<Id> sendEmailWhenQuoteAccepted(List<Id> quoteIds){
        Id quoteId = quoteIds[0];
        sendEmailWhenQuoteAcceptedFuture(quoteId);
        return quoteIds;
    }
    
    /**
    * Future method to send email when a quote is accepted
    * @param        : Id quoteId
    * @return       : Void
    */
    @future(callout=true)
    public static void sendEmailWhenQuoteAcceptedFuture(Id quoteId){
        
        // Create an invoice attachment for the quote.
        createInvoiceAttachment(quoteId);
        
        Quote qut = [SELECT Id, ContactId FROM Quote WHERE Id = :quoteId];
        
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        
        // Attach files to the message
        List<QuoteDocument> files = [SELECT Name, Document FROM QuoteDocument WHERE QuoteId = :quoteId ORDER BY CreatedDate DESC LIMIT 1];
        
        List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();
        for (QuoteDocument file: files) {
            Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
            efa.setFileName(file.Name);
            efa.setBody(file.Document);
            efa.setContentType('application/pdf');
            attachments.add(efa);
        }
        message.setFileAttachments(attachments);
        
        String invoiceEmailTemplate  = getConfiguration('InvoiceEmailTemplate');
        system.debug('invoiceEmailTemplate------'+invoiceEmailTemplate);
        if(String.IsBlank(invoiceEmailTemplate)){
            invoiceEmailTemplate = INVOICE_EMAIL_TEMPLATE;
        }
        
        // Set the message template
        List<EmailTemplate> templates = [SELECT Id, Subject, HtmlValue FROM EmailTemplate WHERE DeveloperName = :invoiceEmailTemplate];
        message.setTemplateId(templates[0].Id);
        
        // Save the message as activity
        message.setTargetObjectId(qut.ContactId);
        message.setWhatId(quoteId);
        message.setSaveAsActivity(true);
        
        // Send the message
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { message });
    }
    
    /**
    * To create Invoice Attachment for the quote
    * @param        : Id theQuoteId
    * @return       : void
    */
    private static void createInvoiceAttachment(Id theQuoteId) {
        String invoiceQuoteTemplateId  = getConfiguration('InvoiceQuoteTemplateId');
        if(String.IsBlank(invoiceQuoteTemplateId)){
            invoiceQuoteTemplateId = INVOICE_QUOTE_TEMPLATE_ID;
        }
        String quoteURL = '/quote/quoteTemplateDataViewer.apexp?id=' + theQuoteId
            + '&headerHeight=279&footerHeight=74&summlid=' + invoiceQuoteTemplateId
            + '#toolbar=1&navpanes=0&zoom=90&resizeAutomatically=true';
        PageReference pageReferenceForPDF = new PageReference(quoteURL);
        QuoteDocument newQuoteDocument = new QuoteDocument(); 
        if(Test.isRunningTest()) { 
            Blob renderedPDF = blob.valueOf('Unit.Test');
            newQuoteDocument.Document = renderedPDF;
        } else {
            Blob renderedPDF = pageReferenceForPDF.getContentAsPDF();
            newQuoteDocument.Document = renderedPDF;
        }
        newQuoteDocument.QuoteId = theQuoteId;
        insert newQuoteDocument;
    }
    
    /**
    * To get configuration values from Configuration__mdt
    * @param        : String configName
    * @return       : String configValue
    */
    public static string getConfiguration(String configName){
        List<Configuration__mdt> configs = [SELECT Id, Value__c
                                            FROM Configuration__mdt
                                            WHERE DeveloperName =:configName];
        if(configs!=null && configs.size()>0){
            return configs[0].Value__c;
        }
        return Null;
    }
}