global class globalCommissionMethods{

    public without sharing class CommissionMethods {
        
        public void generateCommission(List<Revenue__c> revs){
            generateCommission(revs, null, null);
        }
        
        public void generateCommission(List<Revenue__c> revs, Integer theMonth){
            generateCommission(revs, theMonth, null);
        }
        
        public void generateCommission(List<Revenue__c> revs, Integer theMonth, Integer theYear){
                                    
            if(theMonth == null) {
                theMonth = System.Date.Today().Month();
            }
            if(theYear == null){
                theYear = System.Date.Today().Year();
            }
            
            Date theDate = Date.newInstance(theYear, theMonth, Date.daysInMonth(theYear, theMonth));
                                   
            Set<Id> ownerIds = new Set<Id>();
            
            //Build a Map of Sales People & Companies based on current Revenue__c records
            //i.e. commission statements that will be required
            Map<Id, Set<String>> ownerCompanyMap = new Map<Id, Set<String>>();
            for(Revenue__c rev : revs){
                ownerIds.add(rev.Owner.Id);
                
                if(ownerCompanyMap.get(rev.Owner.Id) == null){
                    ownerCompanyMap.put(rev.Owner.Id, new Set<String>{ rev.CommissionCompany__c });
                }
                else{
                    ownerCompanyMap.get(rev.Owner.Id).add(rev.CommissionCompany__c);
                }
            }
            
            //Build a Map of Sales People & Companies based on exisiting Commission__c records
            //i.e. commission statements that already exist and don't need to be created
            Map<Id, Map<String,Id>> ownerCompanyComMap = new Map<Id, Map<String,Id>>();
            for(Commission__c com : [SELECT Id, Owner.Id, Company__c FROM Commission__c WHERE CALENDAR_MONTH(Date__c) = :theMonth AND CALENDAR_YEAR(Date__c) = :theYear AND Owner.ID IN :ownerIds ]) {                
                if(ownerCompanyComMap.get(com.Owner.Id) == null){
                    ownerCompanyComMap.put(com.Owner.Id, new Map<String,Id>{ com.Company__c => com.Id });
                }
                else{
                    ownerCompanyComMap.get(com.Owner.Id).put(com.Company__c, com.Id);
                }
            }
            
            //Build a List of new Commission__c records to be created
            //i.e. commission statements that don't exists and need to be created
            List<Commission__c> newComs = new List<Commission__c>();
            
            for(Id ownerId : ownerCompanyMap.keySet()){
                if(!ownerCompanyComMap.keySet().contains(ownerId)){
                    for(String company : ownerCompanyMap.get(ownerId)){
                        Commission__c newCom = new Commission__c();
                        newCom.OwnerId = ownerId;
                        newCom.Date__c = theDate;
                        newcom.Company__c = company;
                        
                        newComs.Add(newCom);                        
                    }
                }
                else if(!ownerCompanyComMap.get(ownerId).keySet().containsAll(ownerCompanyMap.get(ownerId))){
                    for(String company : ownerCompanyMap.get(ownerId)){
                        if(!ownerCompanyComMap.get(ownerId).keySet().contains(company)){
                            Commission__c newCom = new Commission__c();
                            newCom.OwnerId = ownerId;
                            newCom.Date__c = theDate;
                            newcom.Company__c = company;
                            
                            newComs.Add(newCom);   
                        }
                    }
                }
            }
            
            if(!newComs.isEmpty()){
                insert newComs;
                
                for(Commission__c newCom : newComs){
                    if(ownerCompanyComMap.get(newCom.OwnerId) == null){
                        ownerCompanyComMap.put(newCom.OwnerId, new Map<String,Id>{ newCom.Company__c => newCom.Id });
                    }
                    else{
                        ownerCompanyComMap.get(newCom.OwnerId).put(newCom.Company__c, newCom.Id);
                    }
                }
            }
            
            //Build Currency Conversion Rate Map
            Map<String,Double> CurrencyConversionRateMap = new Map<String,Double>();
            for (CurrencyType CT:[SELECT Id, ConversionRate, IsoCode FROM CurrencyType]){
                CurrencyConversionRateMap.put(CT.IsoCode, CT.ConversionRate);
            }
                                    
            for(Revenue__c rev : revs){
                
                List<CommissionRule__c> allComRules = [SELECT Id, RuleType__c, SalesPerson__c, Division__c, CustomerType__c, BusinessType__c, ProductType__c, MinPercentTarget__c, Rate__c FROM CommissionRule__c 
                                                        WHERE Active__c = TRUE 
                                                        AND SalesPerson__c IN ( :rev.Owner.Id, '' )
                                                        AND Division__c IN ( :rev.ProductFamily__c , 'All' ) 
                                                        AND CustomerType__c IN ( :rev.Opportunity__r.Customer_Type__c, 'All' ) 
                                                        AND BusinessType__C IN ( :rev.BusinessType__c, 'All' ) 
                                                        AND ProductType__c IN ( :rev.ProductType__c, 'All' ) 
                                                        AND Product__r.Id IN ( :rev.InvoiceLineItem__r.Product__r.Id, :rev.CreditNoteLineItem__r.Product__r.Id, '' )
                                                        ORDER BY Priority__c ASC ];
                
                List<CommissionRule__c> productComRules = new List<CommissionRule__c>();
                List<CommissionRule__c> targetComRules = new List<CommissionRule__c>();
                List<CommissionRule__c> dealComRules = new List<CommissionRule__c>();
                
                for(CommissionRule__c comRule : allComRules){
                    if(comRule.RuleType__c == 'Product'){
                        productComRules.add(comRule);
                    }
                    else if(comRule.RuleType__c == 'Target' && comRule.SalesPerson__c == rev.Owner.Id){
                        targetComRules.add(comRule);
                    }
                    else if(comRule.RuleType__c == 'Deal'){
                        dealComRules.add(comRule);
                    }
                }
                if(targetComRules.isEmpty()){
                    for(CommissionRule__c comRule : allComRules){
                        if(comRule.RuleType__c == 'Target'){
                            targetComRules.add(comRule);
                        }
                    }
                }

                
                List<CommissionPayment__c> comPayments = new List<CommissionPayment__c>();
                
                if(allComRules.size()>0){
                    CommissionPayment__c comPayment = new CommissionPayment__c();
                    
                    comPayment.Commission__c = ownerCompanyComMap.get(rev.Owner.Id).get(rev.CommissionCompany__c);
                    comPayment.Opportunity__c = rev.Opportunity__c;
                    comPayment.Date__c = rev.Date__c;
                    comPayment.Division__c = rev.ProductFamily__c;
                    comPayment.CustomerType__c = rev.Opportunity__r.Customer_Type__c;
                    comPayment.BusinessType__c = rev.BusinessType__c;
                    comPayment.ProductType__c = rev.ProductType__c;
                    comPayment.CurrencyIsoCode = 'GBP';
                    if(rev.NetMargin__c != null){
                        comPayment.Margin__c = (rev.NetMargin__c / CurrencyConversionRateMap.get(rev.CurrencyIsoCode))*CurrencyConversionRateMap.get(comPayment.CurrencyIsoCode);
                    }
                    comPayment.RevenueID__c = rev.Id;
                    if(rev.Invoice__c != null)
                        comPayment.Invoice__c = rev.Invoice__c;
                    if(rev.CreditNote__c != null)
                        comPayment.CreditNote__c = rev.CreditNote__c;      
                                        
                    if(productComRules.size()>0){
                        CommissionRule__c productComRule = productComRules.get(0);
                        
                        comPayment.Rate__c = productComRule.Rate__c;
                        comPayment.CommissionRuleID__c = productComRule.Id;
                        comPayments.add(comPayment);
                    }
                    else if(targetComRules.size()>0 && rev.Opportunity__r.Target__c != null){
                        CommissionRule__c targetComRule = targetComRules.get(0);
                        
                        AggregateResult[] targetToDate = [SELECT Opportunity__r.Target__c,SUM(NetAmount__c),SUM(NetMargin__c) FROM Revenue__c WHERE Opportunity__r.Target__c = :rev.Opportunity__r.Target__c AND BusinessType__c = 'New' AND Date__c <= :rev.Date__c GROUP BY Opportunity__r.Target__c];
                        Double targetMarginToDate = 0;
                        Double targetPercentToDate = 0;
                        if(targetToDate.size()>0){
                            targetMarginToDate = Double.valueOf(targetToDate[0].get('expr1'));
                            targetPercentToDate = (targetMarginToDate / rev.Opportunity__r.Target__r.MarginTarget__c) * 100;
                        }
                        
                        //System.debug( 'targetPercentToDate: ' + rev.Date__c + ' = ' + targetPercentToDate );
                        
                        for(Integer i = 0; i < targetComRules.size(); i++){                        
                            //if(targetComRules.get(i).MinPercentTarget__c < rev.Opportunity__r.Target__r.PercentRecognisedMarginTargetAchieved__c)
                            //System.debug('MinPercentTarget__c: ' + targetComRules.get(i).MinPercentTarget__c);
                            if(targetComRules.get(i).MinPercentTarget__c < targetPercentToDate)
                                targetComRule = targetComRules.get(i);
                        }
                                                
                        comPayment.Rate__c = targetComRule.Rate__c;
                        comPayment.CommissionRuleID__c = targetComRule.Id;
                        comPayments.add(comPayment);
                    }
                    else if(dealComRules.size()>0){
                        CommissionRule__c dealComRule = dealComRules.get(0);
                        
                        comPayment.Rate__c = dealComRule.Rate__c;
                        comPayment.CommissionRuleID__c = dealComRule.Id;
                        comPayments.add(comPayment);
                    }
                }
                
                if(comPayments.size()>0){
                    insert comPayments;
                }
                
            }
            
        }
        
    }
    
    WebService static String[] generateOppCommission(String oppId){
        List<String> message = new List<String>();
        
        globalCommissionMethods.CommissionMethods com = new globalCommissionMethods.CommissionMethods();
        
        List<Revenue__c> oppRevs = [SELECT Id, 
                                           Owner.Id, 
                                           Date__c, 
                                           CommissionCompany__c, 
                                           ProductFamily__c, 
                                           BusinessType__c, 
                                           ProductType__c, 
                                           Invoice__c,
                                           InvoiceLineItem__r.Product__r.Id,
                                           CreditNote__c,
                                           CreditNoteLineItem__r.Product__r.Id,
                                           Opportunity__c, 
                                           Opportunity__r.Customer_Type__c, 
                                           Opportunity__r.Target__r.MarginTarget__c, 
                                           Opportunity__r.Target__r.PercentRecognisedMarginTargetAchieved__c, 
                                           NetMargin__c,
                                           CurrencyIsoCode
                                    FROM Revenue__c WHERE Opportunity__c =: oppId ];
                
        Set<ID> oppRevIds = new Set<ID>();
        for(Revenue__c oppRev : oppRevs){
            oppRevIds.add(oppRev.Id);
        }
        
        List<CommissionPayment__c> comPayments = [SELECT Id, RevenueID__c FROM CommissionPayment__c WHERE RevenueID__c IN :oppRevIds ];
        delete comPayments;
        
        com.generateCommission(oppRevs);
        
        return message;
    }
    
}