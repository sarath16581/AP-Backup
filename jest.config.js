const { jestConfig } = require('@salesforce/sfdx-lwc-jest/config');

module.exports = {
	...jestConfig,
	modulePathIgnorePatterns: ['<rootDir>/.localdevserver'],
	moduleNameMapper: {
		'^lightning/platformShowToastEvent$': '<rootDir>/force-app/test/jest-mocks/lightning/platformShowToastEvent',
		'^lightning/messageService$': '<rootDir>/force-app/test/jest-mocks/lightning/messageService',
		'^lightning/navigation$': '<rootDir>/force-app/test/jest-mocks/lightning/navigation'
	}
};
