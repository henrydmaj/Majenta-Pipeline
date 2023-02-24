({
    
    yesResponse : function(component, event, helper) {
        
        var action = component.get("c.emailPDF");
        
        var myAttribute = component.get("v.recordId");
        var pgrefAttribute = "/apex/CreditNoteSingle";
        
        action.setParams({
            recordId : myAttribute,
            pageRef : pgrefAttribute
        });  
        
        action.setCallback(this, function(response) {
            if( response.getState() == 'SUCCESS' ){
                $A.get("e.force:closeQuickAction").fire();
            }
        });
        $A.enqueueAction(action);  
    },
    
    noResponse : function(component, event, helper) {
        
        $A.get("e.force:closeQuickAction").fire();
    }
})