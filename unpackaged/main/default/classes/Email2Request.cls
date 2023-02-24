global class Email2Request implements Messaging.InboundEmailHandler {
 
  global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email,
    Messaging.InboundEnvelope envelope) {
 
    Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
     
    //String firstName = email.fromname.substring(0,email.fromname.indexOf(' '));
    //String lastName = email.fromname.substring(email.fromname.indexOf(' '));
    String fromAddress = envelope.fromAddress;
    String subject = email.subject.replaceAll( '(?:\\[?(?:[Ff][Ww][Dd]?|[Rr][Ee])(?:\\s*[:;-]+\\s*\\]?))+' , '').trim();
    if( subject != null && subject.length() > 0 )
        subject = subject.abbreviate(255);
    String body = email.plainTextBody;
    if( body != null && body.length() > 0 )
        body = body.abbreviate(32768);
                  
    //Find existing requests where subject contains current email subject
    //NOTE: Might catch short/similar subjects as false positives
    //String searchSubject = '%'+subject+'%';
    //List<Request__c> existingRequests = new List<Request__c>([SELECT Id, Subject__c FROM Request__c WHERE Subject__c LIKE :searchSubject ]);
    
    //Find existing requests where subject equals current email subject
    List<Request__c> existingRequests = new List<Request__c>([SELECT Id, Subject__c FROM Request__c WHERE Subject__c =:subject ]);
    
    //Only create a new request if there are no existing requests with the same subject
    if( existingRequests.size() < 1 ){
    
        //Find the user who sent the email and assign as owner
        List<User> users = new List<User>([SELECT u.Id, u.email, u.UserType, u.IsActive FROM User u WHERE email =:fromAddress AND UserType = 'Standard' AND IsActive = TRUE]);
        if( users.size() == 1 ){
           
            Request__c request = new Request__c();
            
            request.OwnerId = users[0].Id;     
            request.Subject__c = subject;
            request.Description__c = body;
            request.SourceEmail__c = TRUE;
            
            insert request;
         
            System.debug('====> Created Request '+request.Id);
            
            //Add any attachments from the email to the request
            if (email.binaryAttachments != null && email.binaryAttachments.size() > 0) {
              for (integer i = 0 ; i < email.binaryAttachments.size() ; i++) {
                Attachment attachment = new Attachment();
                attachment.ParentId = request.Id;
                attachment.Name = email.binaryAttachments[i].filename;
                attachment.Body = email.binaryAttachments[i].body;
                insert attachment;
              }
            }
            
        }
            
    }
 
    return result;
 
  }
  
    static testMethod void testMe() {
    
        // setup a test user
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        User u = new User(
            Alias = 'TEST', Email='email2request@test.com', 
            EmailEncodingKey='UTF-8',
            LastName='Testing',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US',
            ProfileId = p.Id,
            TimeZoneSidKey='America/Los_Angeles',
            UserName='email2request@test.com'
        );
        insert u;
     
        // create a new email and envelope object
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
         
        // setup the data for the email
        email.subject = 'Test Request Email';
        email.fromname = 'FirstName LastName';
        env.fromAddress = 'email2request@test.com';
         
        // add an attachment
        Messaging.InboundEmail.BinaryAttachment attachment = new Messaging.InboundEmail.BinaryAttachment();
        attachment.body = blob.valueOf('my attachment text');
        attachment.fileName = 'textfile.txt';
        attachment.mimeTypeSubType = 'text/plain';
         
        email.binaryAttachments =
          new Messaging.inboundEmail.BinaryAttachment[] { attachment };
         
        // call the email service class and test it with the data in the testMethod
        Email2Request emailProcess = new Email2Request();
        emailProcess.handleInboundEmail(email, env);
        // query for the request the email service created
        Request__c request = [SELECT id, Subject__c from Request__c
            WHERE Subject__c = 'Test Request Email'];
         
        System.assertEquals(request.Subject__c, 'Test Request Email');
        //System.assertEquals(contact.lastName, 'LastName');
         
        // find the attachment
        Attachment a = [SELECT name FROM attachment WHERE parentId = :request.id];
         
        System.assertEquals(a.name,'textfile.txt');
    
    }
 
}