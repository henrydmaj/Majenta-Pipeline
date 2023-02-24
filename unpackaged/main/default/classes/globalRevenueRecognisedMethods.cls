global class globalRevenueRecognisedMethods {
    
    public without sharing class RevenueRecognisedMethods {
        
        public void generateRevenueRecognised(List<SObject> data) {
                        
            if(data != null && !data.isEmpty()) {
                
                List<SObject> records = new List<SObject>();
                List<Revenue__c> newRevs = new List<Revenue__c>();
                
                //Get Object Type of data List
                String objectType = data.getSObjectType().getDescribe().getName();
                                
                if(objectType == 'Invoice__c' || objectType == 'CreditNote__c'){
                    records.addAll(data);
                }
                else if(objectType == 'Opportunity'){
                    for(SObject opp : data){
                        records.addAll(opp.getSObjects('OpportunityInvoices__r'));
                        records.addAll(opp.getSObjects('OpportunityCreditNotes__r'));
                    }
                }
                                                  
                for(SObject record : records){
                    String recordType = record.getSObjectType().getDescribe().getName();
                    String recordId = String.valueOf(record.get('Id'));
                    String oppId = String.valueOf(record.getSObject('Opportunity__r').get('Id'));
                    
                    Map<Map<String,String>,Map<String,Decimal>> oppRevMap = new Map<Map<String,String>,Map<String,Decimal>>();                        
                    
                    List<AggregateResult> oppTotals = [SELECT Product_Family_ro__c, Business_Type_ro__c, Product_Type_ro__c, SUM(Total_Sale_Price__c), SUM(Margin__c) FROM OpportunityLineItem  WHERE Opportunity.Id =: oppId GROUP BY ROLLUP(Product_Family_ro__c, Business_Type_ro__c, Product_Type_ro__c ) HAVING Product_Type_ro__c != ''];
                    List<AggregateResult> recordTotals = new List<AggregateResult>();
                    if(recordType == 'Invoice__c'){                    
                    	recordTotals = [SELECT ProductFamily_ro__c, BusinessType_ro__c, ProductType_ro__c, SUM(NetAmount__c) from InvoiceLineItem__c WHERE Invoice__r.Id =: recordId GROUP BY ROLLUP(ProductFamily_ro__c, BusinessType_ro__c, ProductType_ro__c) HAVING ProductType_ro__c != ''];
                    }
                    else if(recordType == 'CreditNote__c'){
                        recordTotals = [SELECT ProductFamily_ro__c, BusinessType_ro__c, ProductType_ro__c, SUM(NetAmount__c) from CreditNoteLineItem__c WHERE CreditNote__r.Id =: recordId GROUP BY ROLLUP(ProductFamily_ro__c, BusinessType_ro__c, ProductType_ro__c) HAVING ProductType_ro__c != ''];
                    }
                    
                    for(AggregateResult oppTotal : oppTotals){
                        
                        String productFamily = (String) oppTotal.get('Product_Family_ro__c');
                        String businessType = (String) oppTotal.get('Business_Type_ro__c');
                        String productType = (String) oppTotal.get('Product_Type_ro__c');
                        Decimal revenueTotal = (Decimal) oppTotal.get('expr0');
                        Decimal marginTotal = (Decimal) oppTotal.get('expr1');
                        
                        //Skip entries without third level groupings
                        //if(productType == null){
                        //    continue;
                        //}
                        
                        //Build the Key Map
                        Map<String,String> keyMap = new Map<String,String>{
                            'productFamily' => productFamily,
                            'businessType' => businessType,
                            'productType' => productType
                        };
                                    
                        //Build the Value Map    
                        Map<String,Decimal> valueMap = new Map<String,Decimal>{
                            'revenue' => revenueTotal,
                            'margin' => marginTotal
                        };
                                        
                        //Add Key and Value Maps to the Opportunity Revenue Map
                        oppRevMap.put(keyMap, valueMap);
                        
                    }
                    
                    for(AggregateResult recordTotal : recordTotals){
                        
                        String productFamily = (String) recordTotal.get('ProductFamily_ro__c');
                        String businessType = (String) recordTotal.get('BusinessType_ro__c');
                        String productType = (String) recordTotal.get('ProductType_ro__c');
                        Decimal revenueTotal = (Decimal) recordTotal.get('expr0');
                        Decimal revenuePercent = 0;
                        Decimal marginTotal = 0;
                        Revenue__c newRev = new Revenue__c();
                        
                        //Skip entries without third level groupings
                        //if(productType == null){
                        //    continue;
                        //}
                        
                        Map<String,String> keyMap = new Map<String,String>{
                            'productFamily' => productFamily,
                            'businessType' => businessType,
                            'productType' => productType
                        };
                                    
                        if(oppRevMap.get(keyMap) != null){
                            //Calculate the percentage difference between this invoice and the total deal amount
                            if(oppRevMap.get(keyMap).get('revenue') != null && oppRevMap.get(keyMap).get('revenue') <> 0){
                                revenuePercent = revenueTotal / oppRevMap.get(keyMap).get('revenue');
                            }
                            //Calculate the margin amount based on the above percentage
                            if(oppRevMap.get(keyMap).get('margin') != null){
                                marginTotal = oppRevMap.get(keyMap).get('margin') * revenuePercent;
                            }
                        }
                        
                        newRev.Name = String.valueOf(record.get('Ref__c'));
                        newRev.OwnerId = String.valueOf(record.getSObject('Opportunity__r').get('OwnerId'));
                        newRev.Opportunity__c = oppId;
                        if(recordType == 'Invoice__c'){
                            newRev.Invoice__c = recordId;
                        }
                        else if(recordType == 'CreditNote__c'){
                            newRev.CreditNote__c = recordId;
                        }
                        newRev.Date__c = Date.valueOf(record.get('Date__c'));
                        newRev.Type__c = String.valueOf(record.get('Type__c'));
                        newRev.ProductFamily__c = productFamily;
                        newRev.BusinessType__c = businessType;
                        newRev.ProductType__c = productType;
                        newRev.GrossAmount__c = revenueTotal;
                        newRev.GrossMargin__c = marginTotal;
                        
                        newRevs.add(newRev);
                    }
                    
                }
                
                if(!newRevs.isEmpty()){
                    insert newRevs;
                }
            }
            
        }
        
    }
    
    WebService static String[] generateInvoiceRevRec(String invId){
        List<String> message = new List<String>();
        List<Revenue__c> deleteRevs = new List<Revenue__c>();
        
        globalRevenueRecognisedMethods.RevenueRecognisedMethods rev = new globalRevenueRecognisedMethods.RevenueRecognisedMethods();
        
        Invoice__c[] Invoices = [ SELECT Id, Ref__c, IsInvoice__c, Date__c, Type__c, Opportunity__r.Id, Opportunity__r.OwnerId, (SELECT Id FROM InvoiceJournalEntries__r) FROM Invoice__c WHERE Id =: invId AND IsInvoice__c = TRUE];
        deleteRevs.addAll(Invoices[0].InvoiceJournalEntries__r);
        
        if (!deleteRevs.isEmpty()){
			delete deleteRevs;
		}
        
        if (!Invoices.isEmpty()){
            rev.generateRevenueRecognised(Invoices);
        }
        
        return message;   
	}
    
    WebService static String[] generateOppRevRec(String oppId){
        List<String> message = new List<String>();
        List<Invoice__c> Invoices = new List<Invoice__c>();
        List<CreditNote__c> Credits = new List<CreditNote__c>();
        List<Revenue__c> deleteRevs = new List<Revenue__c>();
        
        globalRevenueRecognisedMethods.RevenueRecognisedMethods rev = new globalRevenueRecognisedMethods.RevenueRecognisedMethods();
        
        Opportunity opp = [SELECT Id,
                          		  (SELECT Id, 
                                   		  Ref__c,
                                   		  IsInvoice__c,
                                    	  Date__c,
                                    	  Type__c,
                                   		  Opportunity__r.Id,
                                   		  Opportunity__r.OwnerId 
                                   FROM OpportunityInvoices__r 
                                   WHERE IsInvoice__c = TRUE),
                           		  (SELECT Id,
                                   		  Ref__c,
                                   		  IsCredited__c,
                                   		  Date__c,
                                   		  Type__c,
                                   		  Opportunity__r.Id,
                                   		  Opportunity__r.OwnerId 
                                   FROM OpportunityCreditNotes__r 
                                   WHERE IsCredited__c = TRUE),
                           		  (SELECT Id 
                                   FROM RevenueRecognised__r)
                           FROM Opportunity 
                           WHERE Id =: oppId 
                           LIMIT 1];
        
        Invoices.addAll(opp.OpportunityInvoices__r);
        Credits.addAll(opp.OpportunityCreditNotes__r);        
        deleteRevs.addAll(opp.RevenueRecognised__r);
        
        if (!deleteRevs.isEmpty()){
			delete deleteRevs;
		}
        
        if (!Invoices.isEmpty()){
            rev.generateRevenueRecognised(invoices);
        }
        
        if (!Credits.isEmpty()){
            rev.generateRevenueRecognised(credits);
        }
        
        return message;   
	}

}