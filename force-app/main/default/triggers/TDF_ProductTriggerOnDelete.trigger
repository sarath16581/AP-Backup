//Trigger used for validating Product before deleting with Product Name Present in Custom Setting (TDF Products)
trigger TDF_ProductTriggerOnDelete on Product2 (before delete) {

    if(Trigger.isBefore){

        if(Trigger.isDelete){

        	//Loop through the records of delete instance of Trigger
	    	for(Product2 objProduct : Trigger.old){

	    		//get all records of Custom setting (TDF Products) and match the name of Product that is in the process of delete
		    	for(TDF_Products__c objCustomSettingProduct : TDF_Products__c.getAll().values()){

		    		//compare the name of Product with the Custom Setting values
		    		if(objProduct.Name.trim().toLowerCase() == objCustomSettingProduct.Name.trim().toLowerCase()){

		    			//If matched then throw the error
		    			objProduct.addError('This Product can not be deleted');

		    		}
		    	}
		    }        	
        }
    }
}