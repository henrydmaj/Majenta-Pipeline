public class OpportunitySetControllerExt {
    public OpportunitySetControllerExt(ApexPages.StandardSetController controller) {
        controller.setPageSize(controller.getResultSize());
    }
    
    public static testmethod void TestController() {
        List<Opportunity> oppList = new List<Opportunity>() ;
        oppList.add(new Opportunity()) ;
        ApexPages.StandardsetController opp = new ApexPages.StandardsetController(oppList);
        OpportunitySetControllerExt x = new OpportunitySetControllerExt(opp);
    } 
}