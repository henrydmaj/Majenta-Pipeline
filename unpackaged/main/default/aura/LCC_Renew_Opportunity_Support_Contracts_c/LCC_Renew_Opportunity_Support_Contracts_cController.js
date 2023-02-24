({
  yesResponse : function(component, event, helper) {
    var action = component.get("c.opportunityCount");
    action.setParams({"sContractId":component.get("v.recordId")});
     action.setCallback(this, function(response){
     var res = response.getReturnValue();
      console.log(res);
      if(res==0) {
          $A.get("e.force:closeQuickAction").fire();

     	 var toastEvent = $A.get("e.force:showToast");
         toastEvent.setParams({
          type: 'Error',
          mode: 'sticky',
         "title": "Error!",
         "message": "Please add at least one opportunity to proceed!"
    });
    toastEvent.fire();
      }
      else{
          var action = component.get("c.renewOpportunity");
           action.setParams({"sContractId":component.get("v.recordId")});
           action.setCallback(this, function(response) {
             var res = response.getReturnValue();
               console.log(res);
               console.log('res>>>'+res.length);
               if(res.length==2) {
            alert('hello'+res[1]);
            }else{
                      $A.get("e.force:closeQuickAction").fire();
                      let url = location.origin + '/lightning/r/Opportunity/' + res[0] + '/view';
                  window.open( url,"myWindow");
            }
            }); //setCallback ends here
          $A.enqueueAction(action);
     }
   }); // first setCallback ends here
   $A.enqueueAction(action);
},
//no response code here
        
    noResponse : function(component, event, helper) {
        
        $A.get("e.force:closeQuickAction").fire();
    }
})