/**************************************************
	Type:	AusPost Inbound Social Post Handler Impl. Test Class
	History:
--------------------------------------------------
	10-06-2018: TDO-50 : Hasantha.Liyanage@auspost.com.au Unit tests re-written with scenario based tests.
**************************************************/

@isTest
private class AusPostInboundSocialPostHandlerImplTest {

    /**
     * Setup Initial Data
     */
    @testSetup static void setupInitialData() {
        // Account
        Account account = new Account(Name = 'Social Account');
        insert account;
    }

    /**
     * SCENARIO: Successful getting default Account Id
     */
    @isTest
    static void AusPostInboundSocialPostHandlerImpl_getDefaultAccountId_Success() {
        // Load's the Account
        Account account = [ SELECT Id FROM Account WHERE Name = 'Social Account' ];

        // Default Account Id
        String accountId = null;

        Test.startTest();

        // Verify the Logic
        AusPostInboundSocialPostHandlerImpl aus = new AusPostInboundSocialPostHandlerImpl();
        accountId = aus.getDefaultAccountId();

        System.assertEquals(accountId, account.Id,
                'AusPostInboundSocialPostHandlerImpl_getDefaultAccountId_Success : Getting default Account is unsuccessful.');

        Test.stopTest();
    }

    /**
     * SCENARIO: Failure in getting default Account Id
     */
    @isTest
    static void AusPostInboundSocialPostHandlerImpl_getDefaultAccountId_Failure() {
        // Load's the Account
        Account account = [ SELECT Id FROM Account WHERE Name = 'Social Account' ];
        account.Name = 'Test Account';
        update account;

        // Default Account Id
        String accountId = null;

        Test.startTest();

        // Verify the Logic
        AusPostInboundSocialPostHandlerImpl aus = new AusPostInboundSocialPostHandlerImpl();
        accountId = aus.getDefaultAccountId();

        System.assertEquals(null, accountId,
                'AusPostInboundSocialPostHandlerImpl_getDefaultAccountId_Failure : Getting default Account is successful.');

        Test.stopTest();
    }

}