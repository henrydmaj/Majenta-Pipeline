public class InvoiceSetControllerExt {
    public InvoiceSetControllerExt(ApexPages.StandardSetController controller) {
        if(controller.getResultSize()<2000) {
            controller.setPageSize(controller.getResultSize());
        }
        else {
            controller.setPageSize(2000);
        }
    }
    
    public static testmethod void TestController() {
        List<Invoice__c> invList = new List<Invoice__c>() ;
        invList.add(new Invoice__c()) ;
        ApexPages.StandardsetController inv = new ApexPages.StandardsetController(invList);
        InvoiceSetControllerExt x = new InvoiceSetControllerExt(inv);
    } 
}