@isTest(SeeAllData=TRUE)
public class intranet_Wallboards_TEST{
    
    public static testmethod void test_intranet_Wallboards(){
        //Set Controller        
        intranet_Wallboards wallboard = new intranet_Wallboards();
        
        List<AggregateResult> theResultsThisMonth = wallboard.getResultsThisMonth();
        List<AggregateResult> theForecastThisMonth = wallboard.getForecastThisMonth();
        List<AggregateResult> theTargets = wallboard.getTargets();
        List<AggregateResult> theActivitiesThisWeek = wallboard.getActivitiesThisWeek();
    }
    
}