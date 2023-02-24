public with sharing class ProductTriggerMethods {

	//create  standard price book entry for every currency
	@future public static void updateStdPriceBookEntry(Set<Id> productId)
	{
		
		//Standard price book
		Id stdPriceB = [select Id from PriceBook2 where isStandard = true limit 1].Id;
		if(stdPriceB!=null)
		{
			// All active currencies set in this org
			List<CurrencyType> currencyList = [Select c.IsoCode, c.IsActive From CurrencyType c where c.IsActive =true];			
			List<PriceBookEntry> pBEList = new List<PriceBookEntry>();
			for(Id prodId:productId)
			{
				for(CurrencyType currencyObj: currencyList)
				{
					 
					 PriceBookEntry pBe = new PriceBookEntry(IsActive = true,
															 PriceBook2Id = stdPriceB,
															 Product2Id = prodId,
															 UnitPrice = 0,
															 CurrencyIsoCode = currencyObj.IsoCode);
						
					pBEList.add(pBe);
				}
			}
			try{
		 		insert pBEList;
			}catch(Exception e)
			{
				
			}
		}
		
	 }
	
	public testmethod static void TestSupportContractRenewal()
    {
    	Product2 prod = new Product2 (Name = 'Test2020',isActive = true,Type__c = 'Software');
    	insert prod;
    	
    	
    }
}