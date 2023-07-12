/**
 * @description Service class for low level functions for merchant portal integrated experiences requiring authentication via OIDC
 * @date 2023-07-12
 * @changelog
 */
public inherited sharing class MerchantPortalRegHandlerService {

	@TestVisible
	private static final String ATTRIBUTE_CNUMBER_MAPPING = 'https://auspost/cnumber';

	/**
	 * Provides a mockable interface for unit testing
	 */
	public static MerchantPortalRegHandlerService getInstance() {
		return (MerchantPortalRegHandlerService)Application.Utilities.getInstance(MerchantPortalRegHandlerService.class);
	}

	public Map<String, String> getAugmentedAttributes(Map<String, String> attributes) {
		Map<String, String> output = new Map<String, String>();
		output.putAll(attributes);

		String cNumber = String.valueOf(attributes.get(ATTRIBUTE_CNUMBER_MAPPING));
		String federationIdentifier = generateFederationIdentifier(cNumber);

		output.put('federation_identifier', federationIdentifier); // this is to maintain backwards compatibility of the millions of existing records we have
		output.put('cnumber', cNumber); // this is to maintain backwards compatibility of the millions of existing records we have

		return output;
	}

	private String generateFederationIdentifier(String cNumber) {
		return String.valueOf(cNumber) + '.merchant';
	}

	/**
	 * Verify that the attributes are valid
	 */
	public List<String> validateAssertion(Map<String, String> attributes) {
		List<String> output = new List<String>();

		if(!attributes.containsKey('given_name')) {
			output.add('First Name attribute is missing');
		}
		if(!attributes.containsKey('family_name')) {
			output.add('Last Name attribute is missing');
		}
		if(!attributes.containsKey('email')) {
			output.add('Email attribute is missing');
		}
		if(!attributes.containsKey('federation_identifier')) {
			output.add('Username attribute is missing');
		}
		if(!attributes.containsKey(ATTRIBUTE_CNUMBER_MAPPING) || !attributes.containsKey('cnumber')) {
			output.add('CNumber attribute is missing');
		}

		// fail early if possible
		if(!output.isEmpty()) {
			return output;
		}

		return output;
	}

	public class RegHandlerException extends Exception{}
}