({
    
    yesResponse : function(component, event, helper) {
        
  sforce.apex.execute('globalTargetMethods', 'updateThisTarget', {
  targetId: ''+helper.idTruncate(component.get('v.sObjectInfo.Id'))+''});
  location.reload();

        
        $A.get("e.force:closeQuickAction").fire();
    },
    
    noResponse : function(component, event, helper) {
        

        
        $A.get("e.force:closeQuickAction").fire();
    }
})