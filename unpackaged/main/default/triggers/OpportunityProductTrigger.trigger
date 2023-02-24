trigger OpportunityProductTrigger on OpportunityLineItem (after insert,after delete) {
        
    if(trigger.isinsert && trigger.isafter){
        opportunityLineItemHandler.copyNumberOfSites(trigger.new);
    }
    
    if(trigger.isdelete && trigger.isafter){
        opportunityLineItemHandler.deleteCopyNumberOfSites(trigger.old);
    }
}