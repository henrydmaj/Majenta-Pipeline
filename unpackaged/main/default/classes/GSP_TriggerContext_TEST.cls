@isTest
private class GSP_TriggerContext_TEST
{
	@isTest
	private static void test_TriggerContext()
	{
		GSP_triggerContext.DisableAllTriggers				= true;
		GSP_triggerContext.DisableQuoteLineItemTriggers		= true;
		GSP_triggerContext.DisableOpportunityTriggers		= true;
		GSP_triggerContext.DisableAccountTriggers			= true;
		GSP_triggerContext.DisableQuoteTriggers				= true;
		GSP_triggerContext.DisableContactTriggers			= true;
		GSP_triggerContext.DisableLeadTriggers				= true;
		GSP_triggerContext.DisableEventTriggers				= true;
		GSP_triggerContext.DisableCreditNoteTriggers		= true;
		GSP_triggerContext.DisableInvoiceTriggers			= true;
		
		GSP_triggerContext.DisableAllTriggers				= false;
		GSP_triggerContext.DisableQuoteLineItemTriggers		= false;
		GSP_triggerContext.DisableOpportunityTriggers		= false;
		GSP_triggerContext.DisableAccountTriggers			= false;
		GSP_triggerContext.DisableQuoteTriggers				= false;
		GSP_triggerContext.DisableContactTriggers			= false;
		GSP_triggerContext.DisableLeadTriggers				= false;
		GSP_triggerContext.DisableEventTriggers				= false;
		GSP_triggerContext.DisableCreditNoteTriggers		= false;
		GSP_triggerContext.DisableInvoiceTriggers			= false;
	}
}