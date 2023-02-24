({
    
    yesResponse : function(component, event, helper) {
        
  var result = sforce.apex.execute('SupportContractRenewal', 'renewOpportunity', {
  sContractId: ''+helper.idTruncate(component.get('v.sObjectInfo.Id'))+''});
  if (result.length == 2) {
    alert(result[1]);
  } else {
helper.gotoURL(component, '/' + result[0], 'myWindow');
  }

        
        $A.get("e.force:closeQuickAction").fire();
    },
    
    noResponse : function(component, event, helper) {
        

        
        $A.get("e.force:closeQuickAction").fire();
    }
})