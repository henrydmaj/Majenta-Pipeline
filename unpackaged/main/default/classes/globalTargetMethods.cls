global class globalTargetMethods {
    
    public without sharing class TargetMethods {
    
        public Map<Id, Id> getTargetMap(Opportunity[] Opps){
        
            Map<Id, Id> targetMap = new Map<Id, Id>();
        
            for(Opportunity Opp : Opps){
                Id oppOwner = Opp.OwnerId;
                //String oppYear = String.ValueOf(Opp.CloseDate.Year());
                String oppYear = Opp.SalesYear__c;
                
                Target__c[] Targets = [SELECT Id FROM Target__c WHERE OwnerId =: oppOwner AND Year__c =: oppYear LIMIT 1];
                if(Targets.size() > 0)
                    targetMap.put(Opp.Id, Targets[0].Id);           
            }
            
            return targetMap;
        }
        
        public Set<Id> getTargetIds(SObject[] records){
        
            Set<Id> targetIds = new Set<Id>();
            String objectType;
            
            //Check records is not empty
            if(records != null && !records.isEmpty()) {
                objectType = records.getSObjectType().getDescribe().getName();
                   
                if(objectType == 'Target__c'){
                    List<Target__c> Targets = records;
                    
                    for(Target__c Target : Targets){
                        targetIds.add(Target.Id);
                    }
                }
                else if(objectType == 'Opportunity'){
                    List<Opportunity> Opps = records;
                    
                    for(Opportunity Opp : Opps){
                        if(Opp.Target__c != null){
                            targetIds.add(Opp.Target__c);
                        }
                    }
                }
                else if(objectType == 'Revenue__c'){
                    List<Revenue__c> Revs = records;
                    Set<Id> oppIds = new Set<Id>();
                    
                    for(Revenue__c Rev : Revs){
                        oppIds.add(Rev.Opportunity__c);
                    }
                    
                    for(Opportunity opp : [SELECT Id, Target__c from Opportunity WHERE Id IN :oppIds]){
                        if(opp.Target__c != null){
                            targetIds.add(opp.Target__c);
                        }
                    }
                }           
            }
            
            return targetIds;
        }
        
        public void updateTarget(Set<Id> targetIds, String objectType){
                
            //Check targetIds is not empty
            if(targetIds != null && !targetIds.isEmpty()) {
                
                Target__c[] Targets = [SELECT Id, RevenueClosed__c, MarginClosed__c, RevenueRecognised__c, MarginRecognised__c from Target__c WHERE Id IN :targetIds];
                
                //Map<Id, String> targetTypeMap = new Map<Id, String>();
                //for(Target__c Target : Targets){
                //    targetTypeMap.put(Target.Id, Target.BusinessType__c);
                //}
                            
                //Maps will contain one Target Id to one SUM value
                Map<Id,Double> targetNewOppRevenueMap = new Map<Id,Double>();
                Map<Id,Double> targetNewOppMarginMap = new Map<Id,Double>();
                Map<Id,Double> targetNewRevRevenueMap = new Map<Id,Double>();
                Map<Id,Double> targetNewRevMarginMap = new Map<Id,Double>();
                
                Map<Id,Double> targetRenOppRevenueMap = new Map<Id,Double>();
                Map<Id,Double> targetRenOppMarginMap = new Map<Id,Double>();
                Map<Id,Double> targetRenRevRevenueMap = new Map<Id,Double>();
                Map<Id,Double> targetRenRevMarginMap = new Map<Id,Double>();
                
                if(objectType == 'Target__c' || objectType == 'Opportunity'){
                    //Produce a SUM of related Closed Won Opportunities and add them to the map
                    //use group by to have a single Target Id with a single sum value
                    
                    //AggregateResult[] oppSUMs = [SELECT Target__c target,SUM(Amount),SUM(Margin_Calc__c)
                    //    FROM Opportunity WHERE Probability = 100 AND Target__c IN :targetIds GROUP BY Target__c];
                    
                    AggregateResult[] newOppSUMs = [SELECT Opportunity.Target__c target,SUM(Total_Sale_Price__c),SUM(Margin__c)
                        FROM OpportunityLineItem WHERE Opportunity.IsWon = TRUE AND BusinessType__c = 'New' AND Opportunity.Target__c IN :targetIds GROUP BY Opportunity.Target__c];
                    
                    AggregateResult[] renOppSUMs = [SELECT Opportunity.Target__c target,SUM(Total_Sale_Price__c),SUM(Margin__c)
                        FROM OpportunityLineItem WHERE Opportunity.IsWon = TRUE AND BusinessType__c = 'Renewal' AND Opportunity.Target__c IN :targetIds GROUP BY Opportunity.Target__c];
                    
                    for(AggregateResult newOppSUM : newOppSUMs){
                        targetNewOppRevenueMap.put((Id)newOppSUM.get('target'),(Double)newOppSUM.get('expr0'));
                        targetNewOppMarginMap.put((Id)newOppSUM.get('target'),(Double)newOppSUM.get('expr1'));
                    }
                }
                
                AggregateResult[] newRevSUMs = [SELECT Opportunity__r.Target__c target,SUM(NetAmount__c),SUM(NetMargin__c)
                    FROM Revenue__c WHERE BusinessType__c = 'New' AND Opportunity__r.Target__c IN :targetIds GROUP BY Opportunity__r.Target__c];
                
                AggregateResult[] renRevSUMs = [SELECT Opportunity__r.Target__c target,SUM(NetAmount__c),SUM(NetMargin__c)
                    FROM Revenue__c WHERE BusinessType__c = 'Renewal' AND Opportunity__r.Target__c IN :targetIds GROUP BY Opportunity__r.Target__c];
                
                //Produce a SUM of related Revenue Recognised records and add them to the map
                //use group by to have a single Target Id with a single sum value
                for(AggregateResult newRevSUM : newRevSUMs){
                    targetNewRevRevenueMap.put((Id)newRevSUM.get('target'),(Double)newRevSUM.get('expr0'));
                    targetNewRevMarginMap.put((Id)newRevSUM.get('target'),(Double)newRevSUM.get('expr1'));
                }
                
                List<Target__c> targetsToUpdate = new List<Target__c>();
                
                //Run the for loop on Target__c using the non-duplicate set of Target Ids
                //Get the SUM value from the map and create a list of Target__c to update
                for(Target__c Target : Targets){
                    Double newOppRevenueSum = 0;
                    Double newOppMarginSum = 0;
                    Double newRevRevenueSum = 0;
                    Double newRevMarginSum = 0;
                    
                    if(objectType == 'Opportunity' || objectType == 'Target__c'){
                        //If no sum value is found, default 0
                        if(targetNewOppRevenueMap.get(Target.Id) != null)
                            newOppRevenueSum = targetNewOppRevenueMap.get(Target.Id);
                            
                        if(targetNewOppMarginMap.get(Target.Id) != null)
                            newOppMarginSum = targetNewOppMarginMap.get(Target.Id);
                            
                        Target.RevenueClosed__c = newOppRevenueSum;
                        Target.MarginClosed__c = newOppMarginSum;
                    }
                    
                    //If no sum value is found, default 0    
                    if(targetNewRevRevenueMap.get(Target.Id) != null)
                        newRevRevenueSum = targetNewRevRevenueMap.get(Target.Id);
                        
                    if(targetNewRevMarginMap.get(Target.Id) != null)
                        newRevMarginSum = targetNewRevMarginMap.get(Target.Id);
                        
                    Target.RevenueRecognised__c = newRevRevenueSum;
                    Target.MarginRecognised__c = newRevMarginSum;
                    
                    targetsToUpdate.add(Target);
                }
                
                update targetsToUpdate;
                
            }
        }
            
    }
    
    WebService static void updateThisTarget(String targetId){   
        globalTargetMethods.TargetMethods target = new globalTargetMethods.TargetMethods();
        
        Set<Id> targetIds = new Set<Id>();
        targetIds.Add(targetId);
        
        target.updateTarget(targetIds,'Target__c');
    }
        
}