public with sharing class TaskTriggerHandler {
    public static boolean IsProjectTaskContext = false;

    private boolean m_isExecuting = false;
    private integer BatchSize = 0;
        
    public TaskTriggerHandler(boolean isExecuting, integer size){
        m_isExecuting = isExecuting;
        BatchSize = size;
    }
    
    private class linkedProjectTasks {
        string projectPrefix = Project__c.sObjectType.getDescribe().getKeyPrefix();
        List<Task> relatedTasks = new List<Task>();
        
        Map<Id, Id> savedProjectTaskIds = new Map<Id, Id>();
        Map<ID, Task> TaskMap = new Map<ID, Task>();
        Map<String, Task> ProjectTaskMap = new Map<String, Task>();

        linkedProjectTasks(Task[] Tasks){
            for(Task t : Tasks){
                if(t.WhatId != null && String.valueOf(t.whatId).startsWith(projectPrefix)){
                    relatedTasks.add(t);
                }
            }
        }
        
        boolean IsEmpty{
            get { return relatedTasks.IsEmpty(); }
        }
        
        Map<ID, Task> getTaskMap(){
            TaskMap.clear();
            for(Task rt : relatedTasks)
                TaskMap.put(rt.Id,rt);

            return TaskMap;
        }

        Map<String, Task> getProjectTaskMap(){
            ProjectTaskMap.clear();
            for(Task rt : relatedTasks)
                ProjectTaskMap.put(rt.ProjectTaskId__c,rt);

            return ProjectTaskMap;
        }
        
        Map<ID, ProjectTask__c> getProjectTaskListMap(){
            Map<String, Task> ProjectTaskMap = getProjectTaskMap();
            
            List<ProjectTask__c> ProjectTasks = [SELECT Id, 
                                                        Assigned__c,
                                                        Project__c,
                                                        Name,
                                                        DueDate__c,
                                                        Comments__c,
                                                        Status__c,
                                                        Priority__c,
                                                        Hours__c,
                                                        ActivityId__c FROM ProjectTask__c
                                                        WHERE Id IN :ProjectTaskMap.KeySet()];
        
            Map<ID, ProjectTask__c> ProjectTaskListMap = new Map<ID, ProjectTask__c>();
            for (ProjectTask__c ProjectTask : ProjectTasks){
                ProjectTaskListMap.put(ProjectTaskMap.get(ProjectTask.Id).Id, ProjectTask);
            }
            
            return ProjectTaskListMap;
        }
        
        Map<ID, ProjectTask__c> getReverseProjectTaskListMap(){
            Map<ID, Task> TaskMap = getTaskMap();
            
            List<ProjectTask__c> reverseProjectTasks = [SELECT Id, 
                                                        Assigned__c,
                                                        Project__c,
                                                        Name,
                                                        DueDate__c,
                                                        Comments__c,
                                                        Status__c,
                                                        Priority__c,
                                                        Hours__c,
                                                        ActivityId__c FROM ProjectTask__c
                                                        WHERE ActivityId__c IN :TaskMap.KeySet()];
        
            Map<ID, ProjectTask__c> reverseProjectTaskListMap = new Map<ID, ProjectTask__c>();
            for (ProjectTask__c reverseProjectTask : reverseProjectTasks){
                reverseProjectTaskListMap.put(TaskMap.get(reverseProjectTask.ActivityId__c).Id, reverseProjectTask);
            }
            
            return reverseProjectTaskListMap;
        }
        
        Database.SaveResult[] insertProjectTasks(){
            Database.SaveResult[] savedProjectTasks;

            List<ProjectTask__c> newProjectTasks = new List<ProjectTask__c>();
            String newProjectTaskName;
            for(Task rt : relatedTasks){
                if(rt.Subject != null && rt.Subject.length()>80)
                    newProjectTaskName = rt.Subject.substring(0, 80);
                else
                    newProjectTaskName = rt.Subject;
                    
                 newProjectTasks.add (new ProjectTask__c(
                    Assigned__c = rt.OwnerId,
                    Project__c = rt.WhatId,
                    Name = newProjectTaskName,
                    DueDate__c = rt.ActivityDate,
                    Comments__c = rt.Description,
                    Status__c = rt.Status,
                    Priority__c = rt.Priority,
                    Hours__c = rt.Hours__c,
                    ActivityId__c = rt.Id));
            }
            
            savedProjectTasks = Database.insert(newProjectTasks);
            
            savedProjectTaskIds.clear();
            for (Integer i = 0; i < relatedTasks.size(); i++) {
                savedProjectTaskIds.put(relatedTasks[i].Id,savedProjectTasks[i].getId());
            }

            return savedProjectTasks;
        }
                
        Map<Id, Id> getSavedProjectTaskIds(){ return savedProjectTaskIds; }
    }
        
    public void OnBeforeInsert(Task[] newTasks){
        for(Task newTask : newTasks)
            if(newTask.IsRecurrence)
                newTask.addError('Recurring Tasks are not supported on Projects');
    }
    
    public void OnAfterInsert(Task[] newTasks){
        if(!IsProjectTaskContext){
            ProjectTaskTriggerHandler.IsTaskContext = true;
            
            linkedProjectTasks linkedProjectTasks = new linkedProjectTasks(newTasks);
            if(!linkedProjectTasks.IsEmpty){
                Database.SaveResult[] savedProjectTasks = linkedProjectTasks.insertProjectTasks();
                Map<Id, Id> ProjectTaskIds = linkedProjectTasks.getSavedProjectTaskIds();
                            
                List<Task> updateTasks = [SELECT ProjectTaskId__c FROM Task 
                    WHERE Id IN :newTasks];
                for(Task updateTask : updateTasks)
                    updateTask.ProjectTaskId__c = ProjectTaskIds.get(updateTask.Id);
                    
                update updateTasks;
            }
        }
    }
    
    //@future public static void OnAfterInsertAsync(Set<ID> newTaskIDs){

    //}
    
    public void OnBeforeUpdate(Task[] oldTasks, Task[] updatedTasks, Map<ID, Task> TaskMap){
        if(!IsProjectTaskContext){
            ProjectTaskTriggerHandler.IsTaskContext = true;
            
            linkedProjectTasks oLinkedProjectTasks = new linkedProjectTasks(oldTasks);
            linkedProjectTasks uLinkedProjectTasks = new linkedProjectTasks(updatedTasks);
            
            if(!oLinkedProjectTasks.IsEmpty || !uLinkedProjectTasks.IsEmpty){
                Map<ID, Task> oTaskMap = oLinkedProjectTasks.getTaskMap();
                Map<ID, Task> uTaskMap = uLinkedProjectTasks.getTaskMap();
                
                Map<String, Task> oProjectTaskMap = oLinkedProjectTasks.getProjectTaskMap();
                Map<String, Task> uProjectTaskMap = uLinkedProjectTasks.getProjectTaskMap();
                
                Map<ID, ProjectTask__c> oProjectTaskListMap = oLinkedProjectTasks.getProjectTaskListMap();
                Map<ID, ProjectTask__c> oReverseProjectTaskListMap = oLinkedProjectTasks.getReverseProjectTaskListMap();
                Map<ID, ProjectTask__c> uProjectTaskListMap = uLinkedProjectTasks.getProjectTaskListMap();
                Map<ID, ProjectTask__c> uReverseProjectTaskListMap = uLinkedProjectTasks.getReverseProjectTaskListMap();
                
                List<Task> newTasks = new List<Task>();
                List<ProjectTask__c> updProjectTasks = new List<ProjectTask__c>();
                    ProjectTask__c updProjectTask = new ProjectTask__c();
                    String updProjectTaskName;
                List<ProjectTask__c> delProjectTasks = new List<ProjectTask__c>();
                
                String TaskId;
                Boolean IsOldTask;
                Boolean IsUpdTask;
                Boolean IsOldProjectTask;
                Boolean IsUpdProjectTask;
                Boolean IsOldReverseProjectTask;
                Boolean IsUpdReverseProjectTask;
                    
                for(Task updTask : updatedTasks){
                    TaskId = updTask.Id;
                    IsOldTask = oTaskMap.containsKey(TaskId);
                    IsUpdTask = uTaskMap.containsKey(TaskId);
                    IsOldProjectTask = oProjectTaskListMap.containsKey(updTask.Id);
                    IsOldReverseProjectTask = oReverseProjectTaskListMap.containsKey(updTask.Id);
                    IsUpdProjectTask = uProjectTaskListMap.containsKey(updTask.Id);
                    IsUpdReverseProjectTask = uReverseProjectTaskListMap.containsKey(updTask.Id);
                    
                    if(updTask.IsRecurrence && IsUpdTask){
                        updTask.addError('Recurring Tasks are not supported on Projects');
                    }else if(IsOldTask && IsUpdTask){
                        //Update ProjectTask
                        if(IsUpdProjectTask || IsUpdReverseProjectTask) {
                            if(IsUpdProjectTask){
                                updProjectTask = uProjectTaskListMap.get(updTask.Id);
                            }else{
                                updProjectTask = uReverseProjectTaskListMap.get(updTask.Id);
                                updTask.ProjectTaskId__c = updProjectTask.Id;
                            }
                            
                            if(updTask.Subject != null && updTask.Subject.length()>80)
                                updProjectTaskName = updTask.Subject.substring(0, 80);
                            else
                                updProjectTaskName = updTask.Subject;
                            
                            updProjectTask.Assigned__c     = updTask.OwnerId;
                            updProjectTask.Project__c      = updTask.WhatId;
                            updProjectTask.Name            = updProjectTaskName;
                            updProjectTask.DueDate__c      = updTask.ActivityDate;
                            updProjectTask.Comments__c     = updTask.Description;
                            updProjectTask.Status__c       = updTask.Status;
                            updProjectTask.Priority__c     = updTask.Priority;
                            updProjectTask.Hours__c        = updTask.Hours__c;
                            updProjectTask.ActivityId__c   = updTask.Id;
                            
                            updProjectTasks.add(updProjectTask);
                        }else{
                            newTasks.add(updTask);
                        }
                    }else if(!IsOldTask && IsUpdTask){
                        //Insert ProjectTask
                        newTasks.add(updTask);
                    }else if(IsOldTask && !IsUpdTask){
                        //Delete ProjectTask
                        if(IsOldProjectTask){
                            delProjectTasks.add(oProjectTaskListMap.get(updTask.Id));
                        }else if(IsOldReverseProjectTask){
                            delProjectTasks.add(oReverseProjectTaskListMap.get(updTask.Id));
                        }
                        updTask.ProjectTaskId__c = '';
                    }
                }
                if(!updProjectTasks.isEmpty())
                    update updProjectTasks;
                if(!newTasks.isEmpty()) {
                    linkedProjectTasks newLinkedProjectTasks = new linkedProjectTasks(newTasks);
                    Database.SaveResult[] savedProjectTasks = newLinkedProjectTasks.insertProjectTasks();
                    Map<Id, Id> ProjectTaskIds = newLinkedProjectTasks.getSavedProjectTaskIds();
                    for(Task updTask : updatedTasks){
                        if(ProjectTaskIds.containsKey(updTask.Id))
                            updTask.ProjectTaskId__c = ProjectTaskIds.get(updTask.Id);
                    }
                }
                if(!delProjectTasks.isEmpty())
                    delete delProjectTasks;
            }
        }
    }
    
    public void OnAfterUpdate(Task[] oldTasks, Task[] updatedTasks, Map<ID, Task> TaskMap){
        
    }
    
    //@future public static void OnAfterUpdateAsync(Set<ID> updatedTaskIDs){

    //}
    
    public void OnBeforeDelete(Task[] TasksToDelete, Map<ID, Task> TaskMap){
        if(!IsProjectTaskContext){
            ProjectTaskTriggerHandler.IsTaskContext = true;
            
            Map<String, Task> ProjectTaskMap = new linkedProjectTasks(TasksToDelete).getProjectTaskMap();
                
            List<ProjectTask__c> ProjectTasks = [SELECT Id FROM ProjectTask__c WHERE Id IN :ProjectTaskMap.KeySet()];
            
            if(!ProjectTasks.isEmpty())
                delete ProjectTasks;
        }
    }
    
    public void OnAfterDelete(Task[] deletedTasks, Map<ID, Task> TaskMap){
        
    }
    
    //@future public static void OnAfterDeleteAsync(Set<ID> deletedTaskIDs){
        
    //}
    
    public void OnUndelete(Task[] restoredTasks){
        if(!IsProjectTaskContext){
            ProjectTaskTriggerHandler.IsTaskContext = true;
            
            Map<String, Task> ProjectTaskMap = new linkedProjectTasks(restoredTasks).getProjectTaskMap();
            List<Task> newTasks = new List<Task>();
            
            List<ProjectTask__c> ProjectTasks = [SELECT Id FROM ProjectTask__c
                                                        WHERE IsDeleted = TRUE AND Id IN :ProjectTaskMap.KeySet() ALL ROWS];
                                                        
            if(!ProjectTasks.isEmpty()){
                Database.UndeleteResult[] undeletedProjectTasks = Database.undelete(ProjectTasks, false);
                for (Integer i = 0; i < ProjectTasks.size(); i++){
                    if(!undeletedProjectTasks[i].isSuccess()){
                        newTasks.add(ProjectTaskMap.get(ProjectTasks[i].Id));
                    }
                }
            }
            if(!newTasks.isEmpty()){
                linkedProjectTasks newLinkedProjectTasks = new linkedProjectTasks(newTasks);
                Database.SaveResult[] savedProjectTasks = newLinkedProjectTasks.insertProjectTasks();
                Map<Id, Id> savedProjectTaskIds = newLinkedProjectTasks.getSavedProjectTaskIds();

                List<Task> updateTasks = [SELECT ProjectTaskId__c FROM Task 
                    WHERE Id IN :savedProjectTaskIds.KeySet()];
                for(Task updateTask : updateTasks)
                    updateTask.ProjectTaskId__c = savedProjectTaskIds.get(updateTask.Id);
                    
                update updateTasks;
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