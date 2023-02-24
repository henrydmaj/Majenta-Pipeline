@isTest(seeAllData=true)
public class ProjectTaskTriggerTests {
       
    public static testmethod void testProjectTaskTriggerHandler(){
         
        //Define User  
        User User = [SELECT Id FROM User WHERE IsActive = TRUE LIMIT 1];
    
        //Insert Project
        Project__c Project = new Project__c( IsActive__c = TRUE );
        insert Project;
        
        //Insert Account
        Account Account = new Account( Name = 'Project Test Account' );
        insert Account;
        
        test.startTest();
                
        //Insert ProjectTask #1
        ProjectTask__c ProjectTask1 = new ProjectTask__c( Assigned__c = User.Id,
                                                          Project__c = Project.Id,
                                                          Status__c = 'In Progress',
                                                          Priority__c = 'High',
                                                          Name = 'Test Project Task 1' );
        insert ProjectTask1;
               
        //Prepare for next test
        ProjectTaskTriggerHandler.runOnce = false;
        
                
        //Find Task #1
        Task Task1 = [SELECT Id FROM Task WHERE ProjectTaskId__c =: ProjectTask1.Id LIMIT 1];
        //Delete Task #1
        delete Task1;
        
        //Prepare for next test
        ProjectTaskTriggerHandler.runOnce = false;
        
                
        //Update ProjectTask #1
        update ProjectTask1;
        
        //Prepare for next test
        ProjectTaskTriggerHandler.runOnce = false;
        
        
        //Update ProjectTask#1
        ProjectTask1.ActivityId__c = '';
        update ProjectTask1;
                
        //Prepare for next test
        ProjectTaskTriggerHandler.runOnce = false;
        
        
        //Update status to test Parent Project Chatter feed update
        ProjectTask1.Status__c = 'Completed';
        update ProjectTask1;
        
        //Prepare for next test
        ProjectTaskTriggerHandler.runOnce = false;
        
                
        //Delete ProjectTask #1
        delete ProjectTask1;
        
        //Prepare for next test
        ProjectTaskTriggerHandler.runOnce = false;
        
                
        //Undelete ProjectTask #1
        undelete ProjectTask1;
        
        test.stopTest(); 
                               
    }
    
    public static testmethod void testTaskTriggerHandler(){
    
        //Define User  
        User User = [SELECT Id FROM User WHERE IsActive = TRUE LIMIT 1];
    
        //Insert Project
        Project__c Project = new Project__c( IsActive__c = TRUE );
        insert Project;
        
        //Insert Account
        Account Account = new Account( Name = 'Project Test Account' );
        insert Account;
        
        //Insert Task #1
        Task Task1 = new Task( OwnerId = User.Id, WhatId = Project.Id, Subject = 'Test Task 1' );
        insert Task1;
                
        //Clear Id field
        Task1.ProjectTaskId__c = 'test';
        update Task1;
           
        //Delete Task #1
        delete Task1;
        
        //Undelete Task #1
        undelete Task1;
        
        //Insert Task #2 as Orphan
        Task Task2 = new Task();
        insert Task2;
        
        //Update Task #2
        //Add to Project
        Task2.WhatId = Project.Id;
        update Task2;
        //Update Task #2
        //update Task2;
        
        //Update Task #2
        //Remove from Project
        Task2.WhatId = Account.Id;
        update Task2;
    }
}