public with sharing class ProjectTaskTriggerHandler {
    public static boolean IsTaskContext = false;

    private boolean m_isExecuting = false;
    private integer BatchSize = 0;
    public static boolean runOnce = false;
        
    public ProjectTaskTriggerHandler(boolean isExecuting, integer size){
        m_isExecuting = isExecuting;
        BatchSize = size;
    }
    
    private class linkedTasks {
        ProjectTask__c[] ProjectTasks;

        Map<Id, Id> savedTaskIds = new Map<Id, Id>();
        Map<String, ProjectTask__c> taskMap = new Map<String, ProjectTask__c>();

        linkedTasks(ProjectTask__c[] pTs){
            ProjectTasks = pTs;
        }

        Map<String, ProjectTask__c> getTaskMap(){
            taskMap.clear();
            for(ProjectTask__c ProjectTask : ProjectTasks)
                taskMap.put(ProjectTask.ActivityId__c,ProjectTask);

            return taskMap;
        }
        
        Database.SaveResult[] insertTasks(){
            Database.SaveResult[] savedTasks;

            List<Task> newTasks = new List<Task>();
            for(ProjectTask__c newProjectTask : ProjectTasks){
                 newTasks.add (new Task(
                    OwnerId = newProjectTask.Assigned__c,
                    WhatId = newProjectTask.Project__c,
                    Subject = newProjectTask.Name,
                    ActivityDate = newProjectTask.DueDate__c,
                    Description = newProjectTask.Comments__c,
                    Status = newProjectTask.Status__c,
                    Priority = newProjectTask.Priority__c,
                    Hours__c = newProjectTask.Hours__c,
                    ProjectTaskId__c = newProjectTask.Id,
                    Activity__c = 'Task'));
            }
            
            savedTasks = Database.insert(newTasks);
            
            savedTaskIds.clear();
            for (Integer i = 0; i < ProjectTasks.size(); i++) {
                savedTaskIds.put(ProjectTasks[i].Id,savedTasks[i].getId());
            }

            return savedTasks;
        }
                
        Map<Id, Id> getSavedTaskIds(){ return savedTaskIds; }
    }
        
    public void OnBeforeInsert(ProjectTask__c[] newProjectTasks){

    }
    
    public void OnAfterInsert(ProjectTask__c[] newProjectTasks){
        if(!IsTaskContext){
            TaskTriggerHandler.IsProjectTaskContext = true;
            runOnce = true;
            
            linkedTasks linkedTasks = new linkedTasks(newProjectTasks);
            Database.SaveResult[] savedTasks = linkedTasks.insertTasks();
            Map<Id, Id> taskIds = linkedTasks.getSavedTaskIds();
            
            List<ProjectTask__c> updateProjectTasks = [SELECT ActivityId__c FROM ProjectTask__c 
                WHERE Id IN :newProjectTasks];
            for(ProjectTask__c updateProjectTask : updateProjectTasks)
                updateProjectTask.ActivityId__c = taskIds.get(updateProjectTask.Id);
                
            update updateProjectTasks;
        }
    }
    
    //@future public static void OnAfterInsertAsync(Set<ID> newProjectTaskIDs){
    //}
    
    public void OnBeforeUpdate(ProjectTask__c[] oldProjectTasks, ProjectTask__c[] updatedProjectTasks, Map<ID, ProjectTask__c> ProjectTaskMap){
        if(!IsTaskContext && !runOnce){
            TaskTriggerHandler.IsProjectTaskContext = true;
            runOnce = true;
            
            Map<String, ProjectTask__c> ProjectTaskIds = new linkedTasks(updatedProjectTasks).getTaskMap();
            Set<String> TaskKeys = ProjectTaskIds.KeySet();
                    
            List<Task> Tasks = [SELECT Id, 
                                       OwnerId,
                                       WhatId,
                                       Subject,
                                       ActivityDate,
                                       Description,
                                       Status,
                                       Priority,
                                       Hours__c,
                                       ProjectTaskId__c FROM Task
                                       WHERE Id IN :TaskKeys];
        
            Map<ProjectTask__c, Integer> TaskListMap = new Map<ProjectTask__c, Integer>();
            for (Integer i = 0; i < Tasks.size(); i++){
                TaskListMap.put(ProjectTaskIds.get(Tasks[i].Id), i);
            }
            
            
            Set<ID> ProjectTaskKeys = ProjectTaskMap.KeySet();
            
            List<Task> reverseTasks = [SELECT Id, 
                                              OwnerId,
                                              WhatId,
                                              Subject,
                                              ActivityDate,
                                              Description,
                                              Status,
                                              Priority,
                                              Hours__c,
                                              ProjectTaskId__c FROM Task
                                              WHERE ProjectTaskId__c IN :ProjectTaskKeys];
                                              
            Map<ProjectTask__c, Integer> reverseTaskListMap = new Map<ProjectTask__c, Integer>();
            ID ProjectTaskId;
            for (Integer i = 0; i < reverseTasks.size(); i++){
                ProjectTaskId = reverseTasks[i].ProjectTaskId__c;
                reverseTaskListMap.put(ProjectTaskMap.get(ProjectTaskId), i);
            }
            
            List<Task> updateTasks = new List<Task>();
            Task updateTask = new Task();
            List<ProjectTask__c> newTasks = new List<ProjectTask__c>();
            
            for(ProjectTask__c updatedProjectTask : updatedProjectTasks){
                if(TaskListMap.containsKey(updatedProjectTask) || reverseTaskListMap.containsKey(updatedProjectTask)) {
                    if(TaskListMap.containsKey(updatedProjectTask)){
                        updateTask = Tasks.get(TaskListMap.get(updatedProjectTask));
                    }else{
                        updateTask = reverseTasks.get(reverseTaskListMap.get(updatedProjectTask));
                        updatedProjectTask.ActivityId__c = updateTask.Id;
                    }
                    
                    updateTask.OwnerId = updatedProjectTask.Assigned__c;
                    updateTask.WhatId = updatedProjectTask.Project__c;
                    updateTask.Subject = updatedProjectTask.Name;
                    updateTask.ActivityDate = updatedProjectTask.DueDate__c;
                    updateTask.Description = updatedProjectTask.Comments__c;
                    updateTask.Status = updatedProjectTask.Status__c;
                    updateTask.Priority = updatedProjectTask.Priority__c;
                    updateTask.Hours__c = updatedProjectTask.Hours__c;
                    updateTask.ProjectTaskId__c = updatedProjectTask.Id;
                                    
                    updateTasks.add(updateTask);
                }else{
                    newTasks.add(updatedProjectTask);
                }
            }
            if(!updateTasks.isEmpty())
                update updateTasks;
            if(!newTasks.isEmpty()) {
                    linkedTasks linkedTasks = new linkedTasks(newTasks);
                    Database.SaveResult[] savedTasks = linkedTasks.insertTasks();
                    Map<Id, Id> taskIds = linkedTasks.getSavedTaskIds();
                    for(ProjectTask__c updatedProjectTask : updatedProjectTasks){
                        if(taskIds.containsKey(updatedProjectTask.Id))
                            updatedProjectTask.ActivityId__c = taskIds.get(updatedProjectTask.Id);
                    }
            }
        }
    }
    
    public void OnAfterUpdate(ProjectTask__c[] oldProjectTasks, ProjectTask__c[] updatedProjectTasks, Map<ID, ProjectTask__c> ProjectTaskMap){
    
       /*
        * Code to update related Project Chatter Feed
        * when particular fields are changed.
        */
        List<FeedItem> ProjectFeedItems = new List<FeedItem>();
        for(ProjectTask__c oPt : oldProjectTasks){
            ProjectTask__c uPt = ProjectTaskMap.get(oPt.id);

            String oldDate;
            if(oPt.DueDate__c != null)
                oldDate = oPt.DueDate__c.format();
                
            String oldStatus = oPt.Status__c;
            String oldPriority = oPt.Priority__c;
            
            String updDate;
            if(uPt.DueDate__c != null)
                updDate = uPt.DueDate__c.format();
                
            String updStatus = uPt.Status__c;
            String updPriority = uPt.Priority__c;
            
            FeedItem ProjectFeedItem = new FeedItem();
            ProjectFeedItem.Type = 'LinkPost';
            ProjectFeedItem.ParentId = uPt.Project__c;
            ProjectFeedItem.LinkUrl = '/' + uPt.Id;
            ProjectFeedItem.Title = 'View details...';
            ProjectFeedItem.Body = ' — ' + uPt.Name + ' — changed ';
            List<String> fieldUpdates = new List<String>();
            
            if(updDate != oldDate)       
                fieldUpdates.add('Due Date from ' + oldDate + ' to ' + updDate);

            if(updStatus != oldStatus)       
                fieldUpdates.add('Status from ' + oldStatus + ' to ' + updStatus);
                
            if(updPriority != oldPriority)       
                fieldUpdates.add('Priority from ' + oldPriority + ' to ' + updPriority);
            
            if(fieldUpdates.size()>0){
                for (Integer i = 0; i < fieldUpdates.size(); i++){
                    String seperator;
                    if(i == 0)
                        seperator = '';
                    else if(i == (fieldUpdates.size()-1))
                        seperator = ' and ';
                    else
                        seperator = ', ';
                        
                    ProjectFeedItem.Body += seperator + fieldUpdates.get(i);
                }
                ProjectFeedItems.add(ProjectFeedItem);
            }
        }
        if(!ProjectFeedItems.IsEmpty())
            insert ProjectFeedItems;
    }
    
    //@future public static void OnAfterUpdateAsync(Set<ID> updatedProjectTaskIDs){
    //}
    
    public void OnBeforeDelete(ProjectTask__c[] ProjectTasksToDelete, Map<ID, ProjectTask__c> ProjectTaskMap){
        if(!IsTaskContext){
            TaskTriggerHandler.IsProjectTaskContext = true;
            
            Map<String, ProjectTask__c> ProjectTaskIds = new linkedTasks(ProjectTasksToDelete).getTaskMap();
                
            List<Task> Tasks = [SELECT Id FROM Task
                                       WHERE Id IN :ProjectTaskIds.KeySet()];
            
            if(!Tasks.isEmpty())
                delete Tasks;
        }
    }
    
    public void OnAfterDelete(ProjectTask__c[] deletedProjectTasks, Map<ID, ProjectTask__c> ProjectTaskMap){
        
    }
    
    //@future public static void OnAfterDeleteAsync(Set<ID> deletedProjectTaskIDs){
    //}
    
    public void OnUndelete(ProjectTask__c[] restoredProjectTasks){
        if(!IsTaskContext){
            TaskTriggerHandler.IsProjectTaskContext = true;
            
            Map<String, ProjectTask__c> ProjectTaskIds = new linkedTasks(restoredProjectTasks).getTaskMap();
            List<ProjectTask__c> newTasks = new List<ProjectTask__c>();
            
            List<Task> Tasks = [SELECT Id FROM Task
                                       WHERE IsDeleted = TRUE AND Id IN :ProjectTaskIds.KeySet() ALL ROWS];
            
            if(!Tasks.isEmpty()){
                Database.UndeleteResult[] undeletedTasks = Database.undelete(Tasks, false);
                for (Integer i = 0; i < Tasks.size(); i++){
                    if(!undeletedTasks[i].isSuccess()){
                        newTasks.add(ProjectTaskIds.get(Tasks[i].Id));
                    }
                }
            }
            if(!newTasks.isEmpty()){
                linkedTasks linkedTasks = new linkedTasks(newTasks);
                Database.SaveResult[] savedTasks = linkedTasks.insertTasks();
                Map<Id, Id> taskIds = linkedTasks.getSavedTaskIds();

                List<ProjectTask__c> updateProjectTasks = [SELECT ActivityId__c FROM ProjectTask__c 
                    WHERE Id IN :taskIds.KeySet()];
                for(ProjectTask__c updateProjectTask : updateProjectTasks)
                    updateProjectTask.ActivityId__c = taskIds.get(updateProjectTask.Id);
                    
                update updateProjectTasks;
            }
        }
    }
    
    public boolean IsTriggerContext{
        get{ return m_isExecuting;}
    }
    
    public boolean IsVisualforcePageContext{
        get{ return !IsTriggerContext;}
    }
    
    public boolean IsWebServiceContext{
        get{ return !IsTriggerContext;}
    }
    
    public boolean IsExecuteAnonymousContext{
        get{ return !IsTriggerContext;}
    }
}