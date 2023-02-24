public class CommissionControllerExt{

    private final Commission__c com;
    
    public Map<String, Map<String, CommissionPayment__c[]>> payments {get; set;}
    public Map<String, sObject> records {get; set;}
    public Map<String, AggregateResult> totals {get; set;}
    
    public CommissionControllerExt(ApexPages.StandardController stdController) {               
        this.com = (Commission__c)stdController.getRecord();
        
        loadData();
    }
    
    private void loadData(){
        payments = new Map<String, Map<String, CommissionPayment__c[]>>();
        records = new Map<String, sObject>();
        totals = new Map<String, AggregateResult>();
        
        for(CommissionPayment__c record : [SELECT Id, Name, Opportunity__c, Invoice__c, CreditNote__c, Date__c, Division__c, CustomerType__c, BusinessType__c, ProductType__c, Margin__c, Rate__c, CommissionPayment__c, Note__c FROM CommissionPayment__c WHERE Commission__r.Id =: com.Id ORDER BY Date__c ASC]){
            String opp = 'oppOther';
            if(record.Opportunity__c != null){
                opp = record.Opportunity__c;
            }
            
            String rev = 'revOther';
            if(record.Invoice__c != null){
                rev = record.Invoice__c;
            }
            else if(record.CreditNote__c != null){
                rev = record.CreditNote__c;
            }
                        
            if(!payments.containsKey(opp)){
                records.put(opp, null);
                payments.put(opp, new Map<String, CommissionPayment__c[]>());
            }
            if(!payments.get(opp).containsKey(rev)){
                records.put(rev, null);
                payments.get(opp).put(rev, new CommissionPayment__c[0]);
            }
            records.put(record.Id, record);
            payments.get(opp).get(rev).add(record);
        }
        
        for(AggregateResult sum : [SELECT Opportunity__c, SUM(Margin__c), SUM(CommissionPayment__c) FROM CommissionPayment__c WHERE Commission__r.Id =: com.Id GROUP BY Opportunity__c]){
            if(sum.get('Opportunity__c') != null){
                totals.put(String.valueOf(sum.get('Opportunity__c')), sum);
            }
            else {
                totals.put('oppOther', sum);
            }
        }
        
        for(AggregateResult sum : [SELECT Invoice__c, SUM(Margin__c), SUM(CommissionPayment__c) FROM CommissionPayment__c WHERE Commission__r.Id =: com.Id GROUP BY Invoice__c]){
            if(sum.get('Invoice__c') != null){
                totals.put(String.valueOf(sum.get('Invoice__c')), sum);
            }
            else {
                totals.put('revOther', sum);
            }
        }
        
        for(AggregateResult sum : [SELECT CreditNote__c, SUM(Margin__c), SUM(CommissionPayment__c) FROM CommissionPayment__c WHERE Commission__r.Id =: com.Id GROUP BY CreditNote__c]){
            if(sum.get('CreditNote__c') != null){
                totals.put(String.valueOf(sum.get('CreditNote__c')), sum);
            }
            else {
                totals.put('revOther', sum);
            }
        }
                        
        sObject oppOther = new Opportunity();
        oppOther.put('Name', 'Other');
        oppOther.put('CloseDate', null);        
        records.put('oppOther', oppOther);
        
        sObject revOther = new Invoice__c();
        records.put('revOther', revOther);  
        
        records.putAll([SELECT Id, Name, Quote_Number_Revised__c, CloseDate FROM Opportunity WHERE Id IN :records.KeySet()]);
        records.putAll([SELECT Id, Name, Ref__c, Date__c FROM Invoice__c WHERE Id IN :records.KeySet()]);
        records.putAll([SELECT Id, Name, Ref__c, Date__c FROM CreditNote__c WHERE Id IN :records.KeySet()]);
                
    }
    
}