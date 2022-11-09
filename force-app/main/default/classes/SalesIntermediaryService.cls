/***
 * @author Harry Wang
 * @date 2022-11-07
 * @domain Core
 * @description A service class that provides functionalities related o Intermediary
 * @changelog
 * 2022-11-07 - Harry Wang - Created
 */
public inherited sharing class SalesIntermediaryService {

	static SalesIntermediaryService instance;
	public static SalesIntermediaryService getInstance() {
		if (instance == null) {
			instance = (SalesIntermediaryService) Application.Utilities.newInstance(SalesIntermediaryService.class);
		}
		return instance;
	}

	public class IntermediaryException extends Exception{}
}