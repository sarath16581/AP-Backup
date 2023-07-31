/**
 * @description       : 
 * @author            : Mansi Shah
 * @group             : 
 * @last modified on  : 05-25-2021
 * @last modified by  : Mansi Shah
 * Modifications Log 
 * Ver   Date         Author       Modification
 * 1.0   05-25-2021   Mansi Shah   Initial Version
 * Ken McGuire 2023.04.19 Proposal field migration to opportunity
**/
@isTest
public class APT_DisplayActionCallBackTest {

	private static List<Apttus_Config2.DisplayActionInfo> displayActions;
	@TestSetup
	static void makeData(){

		//create config custom class properties
		Apttus_Config2__ConfigCustomClasses__c configCustomClassesProperty = new Apttus_Config2__ConfigCustomClasses__c();
		configCustomClassesProperty.Name = 'Config Custom Classes';
		configCustomClassesProperty.Apttus_Config2__DisplayActionCallbackCalss__c = 'APT_DisplayActionCallbackClass';
		insert configCustomClassesProperty;

		// insert display action

		List<Apttus_Config2__ConfigCustomDisplayActions__c> listConfigDisplayActions = new List<Apttus_Config2__ConfigCustomDisplayActions__c>();
		Apttus_Config2__ConfigCustomDisplayActions__c tempCustomSetting = new Apttus_Config2__ConfigCustomDisplayActions__c();
		tempCustomSetting.Apttus_Config2__ActionLabelName__c = Label.APT_Action_OfflineRates;
		tempCustomSetting.Apttus_Config2__ActionName__c = Label.APT_Action_OfflineRates;
		tempCustomSetting.Apttus_Config2__Sequence__c = 1;
		tempCustomSetting.Apttus_Config2__IsEnabled__c = true;
		tempCustomSetting.Name = 'Test' + tempCustomSetting.Apttus_Config2__Sequence__c + '' + System.now().millisecond();
		tempCustomSetting.Apttus_Config2__DisplayType__c = 'Cart Line Item';
		tempCustomSetting.Apttus_Config2__ActionPage__c = '';
		listConfigDisplayActions.add(tempCustomSetting);

		Apttus_Config2__ConfigCustomDisplayActions__c tempCustomSetting1 = new Apttus_Config2__ConfigCustomDisplayActions__c();
		tempCustomSetting1.Apttus_Config2__ActionLabelName__c = 'APT_Pricing_Adjustments';
		tempCustomSetting1.Apttus_Config2__ActionName__c = Label.APT_Pricing_Adjustments;
		tempCustomSetting1.Apttus_Config2__Sequence__c = 2;
		tempCustomSetting1.Apttus_Config2__IsEnabled__c = true;
		tempCustomSetting1.Name = 'Test' + tempCustomSetting1.Apttus_Config2__Sequence__c + '' + System.now().millisecond();
		tempCustomSetting1.Apttus_Config2__DisplayType__c = 'Cart Line Item';
		tempCustomSetting1.Apttus_Config2__ActionPage__c = '';
		listConfigDisplayActions.add(tempCustomSetting1);

		insert listConfigDisplayActions;

		Profile p = [SELECT Id FROM Profile WHERE Name='Sales Admin'];
		User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
				EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
				LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
				TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
				UserName=APT_Constants.EMAIL_TEST_USER);
		insert testuser;

        // Retrieve the Permission Set
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'APT_Apttus_R2T_User' LIMIT 1];
        
        // Assign the Permission Set to the User
        PermissionSetAssignment psAssignment = new PermissionSetAssignment(
            PermissionSetId = ps.Id,
            AssigneeId = testuser.Id
        );

		System.runAs(testuser) {
  			insert psAssignment;
			Account acc = APT_TestUtils.createOrganisation();
			insert acc;

			//Create Opportunity
			Opportunity opty = APT_TestUtils.createOpportunity(acc.Id);
			opty.type = 'New Customer';
			opty.IsStartrackProposal__c = APT_Constants.OPTION_NO;
			insert opty;

			//Create PriceList
			Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
			insert priceList;

			Product2 bundle1 = APT_TestUtils.createInternationalProduct(APT_Constants.PRODUCT_NAME_EPARCEL,'APOST001','Postal Services');
			bundle1.Non_contracted__c = false;
			insert bundle1;

			//Create Price list Item
			Apttus_Config2__PriceListItem__c pli = APT_TestUtils.createPriceListItem(priceList.ID,bundle1.ID,'C Manufacturing','BAND 2');
			insert pli;

			APT_Post_Code_Mapping__c pcm1 = APT_TestUtils.createPostCodeMapping('3000', 'AUSTRALIAN NATIONAL UNIVERSITY', 'MIL', 'VC3', 'AC3');
			insert pcm1;

			Apttus_Proposal__Proposal__c proposal = APT_TestUtils.getQuoteProposal(acc.ID,opty.ID,'Proposal','Quote', priceList.ID);

			insert proposal;

			Apttus_Config2__ProductConfiguration__c prodconfig = APT_TestUtils.getProductConfiguration('Product Configuration', 1,
					proposal.Id, 'Proposal','Ad Hoc',priceList.Id, null,'Ready For Finalization',null, Datetime.now(), true);
			insert prodconfig;

			Apttus_Config2__LineItem__c bundleLine = APT_TestUtils.getConfigLineItem(prodconfig.Id, null, 1, true,//Config Id, grpId, LineNum, isPrimary
					1, 'Product/Service', null, true, null,//ItemSeq, lineType, bundleId, customizable, productOptionId
					null, null, null, 1, true,//optionId, class Id, class hierarchy, qty, qty Modifiable
					'Each', 1, priceList.Id, pli.Id,//Uom, term, priceList, Pli,
					'One Time', 'Per Unit', 'Standard Price', 'One Time',//priceType, priceMethod, chargeType, frequency
					true, true, 5500, 5500, 'Per Unit',//allowManualAdj, allocateGroupAdj, listPrice, basePrice, basePriceMethod,
					5225, 0, 5225, 'TestaPTTUS');//baseExtPrice, optionPrice, extendedPrice, lineDesc
			bundleLine.Apttus_Config2__AllowManualAdjustment__c = true;
			bundleLine.Apttus_Config2__NetPrice__c = 5225;
			bundleLine.Apttus_Config2__PrimaryLineNumber__c = 1;
			bundleLine.Apttus_Config2__NetAdjustmentPercent__c = -10;
			insert bundleLine;
		}
	}

	/**
	* @description:
	* @author Mansi Shah | 05-25-2021
	**/
	@isTest
	public static void testMethod1(){
		User testuser = [SELECT Id,Name FROM User LIMIT 1];
		Apttus_Config2__ProductConfiguration__c  objProdConfig = [SELECT Id,Apttus_QPConfig__Proposald__c,Apttus_CQApprov__Approval_Status__c FROM Apttus_Config2__ProductConfiguration__c LIMIT 1];
		List<Apttus_Config2__ConfigCustomDisplayActions__c> listConfigDisplayActions = [SELECT Id, Name, Apttus_Config2__ActionName__c, Apttus_Config2__ActionLabelName__c, Apttus_Config2__DisplayType__c, Apttus_Config2__ActionPage__c, Apttus_Config2__IsEnabled__c, Apttus_Config2__Sequence__c FROM Apttus_Config2__ConfigCustomDisplayActions__c ];
		displayActions = new List<Apttus_Config2.DisplayActionInfo>();
		Apttus_Config2.DisplayActionInfo oDisplayActionInfo;

		for( Apttus_Config2__ConfigCustomDisplayActions__c oTempCustomSetting : listConfigDisplayActions){
			oDisplayActionInfo = new Apttus_Config2.DisplayActionInfo(oTempCustomSetting);
			oDisplayActionInfo.IsEnabled = true;
			displayActions.add(oDisplayActionInfo);
		}

		Test.startTest();

		System.runAs(testuser){
			APT_DisplayActionCallBackClass oDisplayActionCallback = new APT_DisplayActionCallBackClass();
			Apttus_Config2.ProductConfiguration cart;

			try{
				APT_DisplayActionCallBackClass.prodConfigObj = objProdConfig;
				APT_DisplayActionCallBackClass.start(cart,displayActions);
			} catch(Exception e){
				System.debug('Exception : '+ e);
			}

			System.debug('Cart '+cart);

			APT_DisplayActionCallBackClass.setActionProperties(null);
		}


		Test.stopTest();
	}

}