trigger ProductTrigger on Product2 (after insert)
{
	if (!GSP_TriggerContext.DisableAllTriggers)
	{
		ProductTriggerMethods.updateStdPriceBookEntry(trigger.newMap.keySet());
	}

}