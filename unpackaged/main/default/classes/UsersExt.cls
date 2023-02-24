public class UsersExt {
    public UsersExt(ApexPages.StandardSetController controller) {
        controller.setPageSize(controller.getResultSize());
    }
    
    public static testmethod void TestController() {
        List<User> userList = new List<User>() ;
        userList.add(new User()) ;
        ApexPages.StandardsetController user = new ApexPages.StandardsetController(userList);
        UsersExt x = new UsersExt(user);
    } 
}