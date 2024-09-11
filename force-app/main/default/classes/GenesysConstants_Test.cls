/***
 * @description Test class for GenesysConstants
 * @author SteveL
 * @date 2024-09-11
 * @changelog
 * 11/9/2024 created - SteveL
 */

@IsTest
private class GenesysConstants_Test {
	@IsTest
	private static void main() {
		Assert.isFalse(GenesysConstants.voiceCallFieldMappings.keySet().isEmpty(), 'Expect static map to have at least 1 entry');
		Assert.isFalse(GenesysConstants.voiceCallCaseFieldMappings.keySet().isEmpty(), 'Expect static map to have at least 1 entry');
        Assert.isFalse(GenesysConstants.genesysFieldMappings.keySet().isEmpty(), 'Expect static map to have at least 1 entry');
	}
}