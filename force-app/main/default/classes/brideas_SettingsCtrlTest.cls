@isTest
private class brideas_SettingsCtrlTest {

	@isTest
	public static void testAll() {
		brideas_SettingsCtrl ctrlObj = new brideas_SettingsCtrl();
        PageReference pageRefRes = ctrlObj.saveSettings();

		System.assertNotEquals(null, pageRefRes, 'Method should return PageReference instance');
	}

}