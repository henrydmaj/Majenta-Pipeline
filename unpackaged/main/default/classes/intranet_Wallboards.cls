public class intranet_Wallboards {

    List<User> users = [SELECT Id, Name, FirstName, LastName FROM User WHERE SolutionsWallboard__c = TRUE];
    List<String> salesTeam = new List<String>();
    
    public intranet_Wallboards(){
        for (User u : users) {
            salesTeam.add(u.FirstName + ' ' + u.LastName);
        }
    }


    public List<AggregateResult> getResultsThisMonth() {
        List<AggregateResult> data = [SELECT Owner.Name owner, SUM(Amount) amount, SUM(Margin_Calc__c) margin FROM Opportunity WHERE CloseDate = THIS_MONTH AND IsWon = TRUE AND Owner.Name IN :salesTeam GROUP BY Owner.Name];
        return data;
    }
    
    public List<AggregateResult> getForecastThisMonth() {       
        List<AggregateResult> data = [SELECT Owner.Name owner, ForecastCategoryName probability, SUM(Amount) amount, SUM(Margin_Calc__c) margin FROM Opportunity WHERE CloseDate = THIS_MONTH AND IsWon = FALSE AND Owner.Name IN :salesTeam GROUP BY Owner.Name, ForecastCategoryName];
        return data;
    }
    
    public List<AggregateResult> getTargets() {
        String thisYear = String.valueOf(System.Date.Today().Year());
        
        List<AggregateResult> data = [SELECT Owner.Name owner, SUM(MarginTarget__c) target, SUM(MarginClosed__c) closed, SUM(MarginRecognised__c) invoiced FROM Target__c WHERE Year__c =: thisYear AND Owner.Name IN :salesTeam GROUP BY Owner.Name];  
        return data;
    }
    
    public List<AggregateResult> getActivitiesThisWeek() {       
        List<AggregateResult> data = [SELECT Owner.Name owner, COUNT(Id) total FROM Task WHERE Activity__c = 'Call' AND ActivityDate = THIS_WEEK AND IsClosed = TRUE AND Owner.Name IN :salesTeam GROUP BY Owner.Name];
        return data;
    }

}