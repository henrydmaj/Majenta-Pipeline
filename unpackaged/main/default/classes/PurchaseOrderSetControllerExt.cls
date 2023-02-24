public class PurchaseOrderSetControllerExt {
    public PurchaseOrderSetControllerExt(ApexPages.StandardSetController controller) {
        controller.setPageSize(controller.getResultSize());
    }
    
    public static testmethod void TestController() {
        List<PurchaseOrder__c> poList = new List<PurchaseOrder__c>() ;
        poList.add(new PurchaseOrder__c()) ;
        ApexPages.StandardsetController po = new ApexPages.StandardsetController(poList);
        PurchaseOrderSetControllerExt x = new PurchaseOrderSetControllerExt(po);
    } 
}