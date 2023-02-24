({
    
    yesResponse : function(component, event, helper) {
     var action = component.get("c.generateInvoice");
     action.setParams({"OppId":component.get("v.recordId")});
     action.setCallback(this, function(response) {
       var res = response.getReturnValue();
         console.log('resst>>>'+ JSON.stringify(res));
         if(res.length==2) {
			alert('hello'+res[1]);
			}else{
                $A.get("e.force:closeQuickAction").fire();
                let url = location.origin + '/lightning/r/Invoice__c/' + res[0] + '/view';
		        window.open( url,"myWindow");
		  }
      });
      $A.enqueueAction(action);  
    },
        
    noResponse : function(component, event, helper) {
        
        $A.get("e.force:closeQuickAction").fire();
    }
})