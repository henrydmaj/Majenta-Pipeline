public class CommissionController{
    
    private final Commission__c com;
    private static List<String> companies = new List<String>{
        'SOLUTIONS',
        'PLM'
    };
    private static Map<Integer, String> monthMap = new Map<Integer, String>{
        1 => 'January',
        2 => 'February',
        3 => 'March',
        4 => 'April',
        5 => 'May',
        6 => 'June',
        7 => 'July',
        8 => 'August',
        9 => 'September',
        10 => 'October',
        11 => 'November',
        12 => 'December'
    };
    private static List<Integer> years = new List<Integer>{
        System.Date.Today().Year()-1,
        System.Date.Today().Year(),
        System.Date.Today().Year()+1
    };
    
    

    public List<SelectOption> getCompanies() {
        List<SelectOption> options = new List<SelectOption>();
        
        options.add(new SelectOption('','--Select Company--'));
        
        for(Integer i = 0; i < companies.size(); i++){
            options.add(new SelectOption(companies[i],companies[i]));
        }
        
        return options;    
    }
    
    public List<SelectOption> getMonths() {
        List<SelectOption> options = new List<SelectOption>();
        
        options.add(new SelectOption('','--Select Month--'));
        
        for(Integer i = 1; i <= monthMap.size(); i++){
            options.add(new SelectOption(String.valueOf(i),monthMap.get(i)));
        }
        
        return options;    
    }
    
    public List<SelectOption> getYears(){
        List<SelectOption> options = new List<SelectOption>();
        
        options.add(new SelectOption('','--Select Year--'));
        
        for(Integer i = 0; i < years.size(); i++){
            options.add(new SelectOption(String.valueOf(years[i]),String.valueOf(years[i])));
        }
        
        return options;    
    }
        
    public String selectedCompany {get; set;}
    public Integer selectedMonth {get; set;}
    public Integer selectedYear {get; set;}

    
    public PageReference generate() {
        PageReference pageRef;
        String[] result;
        
        //globalCommissionMethods.CommissionMethods com = new globalCommissionMethods.CommissionMethods();
        //List<Revenue__c> revs = [SELECT Id, Owner.Id, Date__c, CommissionCompany__c, ProductFamily__c, BusinessType__c, ProductType__c, Invoice__c, CreditNote__c, Opportunity__c, Opportunity__r.Customer_Type__c, Opportunity__r.Target__r.MarginTarget__c, Opportunity__r.Target__r.PercentRecognisedMarginTargetAchieved__c, NetMargin__c FROM Revenue__c WHERE CommissionCompany__c = :selectedCompany AND CALENDAR_MONTH(Date__c) = :selectedMonth ];
                        
        if ( selectedCompany != null && selectedMonth != null && selectedYear != null ) {
        
            String revQuery = 'SELECT Id, Owner.Id, Date__c, CommissionCompany__c, ProductFamily__c, BusinessType__c, ProductType__c, Invoice__c, InvoiceLineItem__r.Product__r.Id, CreditNote__c, CreditNoteLineItem__r.Product__r.Id, Opportunity__c, Opportunity__r.Customer_Type__c, Opportunity__r.Target__r.MarginTarget__c, Opportunity__r.Target__r.PercentRecognisedMarginTargetAchieved__c, NetMargin__c, CurrencyIsoCode FROM Revenue__c WHERE CommissionCompany__c = \'' + selectedCompany + '\' AND CALENDAR_MONTH(Date__c) = ' + selectedMonth + 'AND CALENDAR_YEAR(Date__c) = ' + selectedYear;

            globalCommissionBatch batchApex = new globalCommissionBatch(revQuery, selectedMonth, selectedYear);
            ID batchId = Database.executeBatch(batchApex, 50);
            
            pageRef = new PageReference ('/a0O');
        
            //if(!revs.IsEmpty()) {
                //com.generateCommission(revs, selectedMonth);              
                //pageRef = new PageReference ('/a0N');
            //}
        } else {
            //errors.add('You must select a company and month!');
            pageRef = null;
        }
        
        return pageRef;
    }

}