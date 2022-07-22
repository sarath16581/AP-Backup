/***
 * Copyright (c) 2022 - Nathan Franklin - All rights reserved
 *
 * @description
 * Wrapper for ExceptionLog__c
 * NOTE: Without sharing since logging should be accessible to all
 * TODO: would prefer inherited sharing, but more analysis is needed
 *
 * @author Nathan Franklin
 * @changelog
 */
public without sharing class ApplicationLogger {
	public static final String EXCEPTION_CODE_FILTER = 'first error:';

	public static final Integer EXCEPTION_CODE_SIZE_LIMIT = 100;
	public static final Integer EXCEPTION_DETAILS_SIZE_LIMIT = 32768;
	public static final Integer ADDITIONAL_INFORMATION_SIZE_LIMIT = 131072;

	/**
	 * Determines the current logging level when logging should be triggered
	 */
	private static final LoggingLevel CURRENT_LOGGING_LEVEL {
		get {
			if(CURRENT_LOGGING_LEVEL == null) {
				String level = SystemSettings__c.getInstance().LoggingLevel__c;
				try {
					CURRENT_LOGGING_LEVEL = LoggingLevel.valueOf(level);
				} catch(Exception ex) {
					CURRENT_LOGGING_LEVEL = LoggingLevel.ERROR;
				}
			}
			return CURRENT_LOGGING_LEVEL;
		}
		private set;
	}

	public enum LoggingLevel {
		ERROR, INFO, ALL
	}

	/**
	 * This is used to determine what logging levels trigger logging based on the current level
	 */
	private static final Map<LoggingLevel, Set<LoggingLevel>> LOGGING_LEVEL_MAPPINGS = new Map<LoggingLevel, Set<LoggingLevel>>{
		LoggingLevel.ERROR => new Set<LoggingLevel>{LoggingLevel.ERROR},
		LoggingLevel.INFO => new Set<LoggingLevel>{LoggingLevel.INFO},
		LoggingLevel.ALL => new Set<LoggingLevel>{LoggingLevel.ERROR, LoggingLevel.INFO}
	};

	public static ApplicationLogger getInstance() {
		return (ApplicationLogger) Application.Utilities.getInstance(ApplicationLogger.class);
	}

	public void logFailedDatabaseResults(List<Database.SaveResult> saveResults, String appName, String className, String methodName, String triggerName, LoggingLevel severity) {
		List<ExceptionLog__c> exceptionLogList = new List<ExceptionLog__c>();

		if(LOGGING_LEVEL_MAPPINGS.get(CURRENT_LOGGING_LEVEL).contains(severity)) {
			for (Integer i = 0; i < saveResults.size(); ++i) {
				Database.SaveResult saveResult = saveResults[i];
				if (!saveResult.isSuccess()) {
					Database.Error[] errors = saveResult.getErrors();

					String errorMessage = buildErrorMessageFromErrorList(saveResult.getId(), errors);
					if (String.isEmpty(errorMessage)) errorMessage = '';

					String exceptionCode = '';
					if (errors.size() > 0) {
						if(!String.isEmpty(String.valueOf(errors[0].statusCode))) {
							exceptionCode = errors[0].statusCode.name();
						}
					}

					exceptionLogList.add(new ExceptionLog__c(
						Application__c = appName, ExceptionCode__c = exceptionCode,
						ClassName__c = className, MethodName__c = methodName,
						ContextUser__c = UserInfo.getUserId(),
						ApexTrigger__c = triggerName,
						ExceptionDetails__c = errorMessage.left(EXCEPTION_DETAILS_SIZE_LIMIT), Severity__c = severity.name(),
						ExceptionType__c = String.valueOf(System.DmlException.class)
					));
				}
			}

			if (!exceptionLogList.isEmpty()) {
				insertExceptions(exceptionLogList);
			}
		}
	}
	public void logFailedDatabaseResults(List<Database.DeleteResult> delResults, String appName, String className, String methodName, String triggerName, LoggingLevel severity) {
		List<ExceptionLog__c> exceptionLogList = new List<ExceptionLog__c>();

		if(LOGGING_LEVEL_MAPPINGS.get(CURRENT_LOGGING_LEVEL).contains(severity)) {
			for (Integer i = 0; i < delResults.size(); ++i) {
				Database.DeleteResult delResult = delResults[i];
				if (!delResult.isSuccess()) {
					Database.Error[] errors = delResult.getErrors();

					String errorMessage = buildErrorMessageFromErrorList(delResult.getId(), errors);
					if (String.isEmpty(errorMessage)) errorMessage = '';

					String exceptionCode = '';
					if (errors.size() > 0) {
						if(!String.isEmpty(String.valueOf(errors[0].statusCode))) {
							exceptionCode = errors[0].statusCode.name();
						}
					}

					exceptionLogList.add(new ExceptionLog__c(
						Application__c = appName, ExceptionCode__c = exceptionCode,
						ClassName__c = className, MethodName__c = methodName,
						ContextUser__c = UserInfo.getUserId(),
						ApexTrigger__c = triggerName,
						ExceptionDetails__c = errorMessage.left(EXCEPTION_DETAILS_SIZE_LIMIT), Severity__c = severity.name(),
						ExceptionType__c = String.valueOf(System.DmlException.class)
					));
				}
			}

			if (!exceptionLogList.isEmpty()) {
				insertExceptions(exceptionLogList);
			}
		}
	}

	public void logException(ExceptionWrapper excp, String applicationName, String className, String methodName, String triggerName, LoggingLevel severity) {
		logException(new List<ExceptionWrapper>{excp}, applicationName, className, methodName, triggerName, severity);
	}

	public void logException(List<ExceptionWrapper> exceptionWrappers, String applicationName, String className, String methodName, String triggerName, LoggingLevel severity) {
		List<ExceptionLog__c> logs = new List<ExceptionLog__c>();

		if(LOGGING_LEVEL_MAPPINGS.get(CURRENT_LOGGING_LEVEL).contains(severity)) {
			for (ExceptionWrapper wrapper : exceptionWrappers) {
				logs.add(buildExceptionObject(wrapper, applicationName, className, methodName, severity, triggerName));
			}

			if (!logs.isEmpty()) {
				insertExceptions(logs);
			}
		}
	}

	public void logMessage(List<String> messages, List<String> additionalInfo, String applicationName, String className, String methodName, String triggerName, LoggingLevel severity) {
		List<ExceptionLog__c> logs = new List<ExceptionLog__c>();

		if(LOGGING_LEVEL_MAPPINGS.get(CURRENT_LOGGING_LEVEL).contains(severity)) {
			for (Integer i = 0; i < messages.size(); i++) {
				logs.add(buildExceptionObject(messages[i], (additionalInfo != null && additionalInfo.size() > i ? additionalInfo[i] : ''), applicationName, className, methodName, severity, triggerName));
			}

			if (!logs.isEmpty()) {
				insertExceptions(logs);
			}
		}
	}

	public void logGenericMessage(List<String> messages, String applicationName, String className, String methodName, String triggerName, LoggingLevel severity) {
		List<ExceptionLog__c> logs = new List<ExceptionLog__c>();

		if(LOGGING_LEVEL_MAPPINGS.get(CURRENT_LOGGING_LEVEL).contains(severity)) {
			for (String message : messages) {
				logs.add(buildExceptionObject(message, '', applicationName, className, methodName, severity, triggerName));
			}

			if (!logs.isEmpty()) {
				insertExceptions(logs);
			}
		}
	}

	// these are used to get around Test.createStub limitations where System types can't be mocked
	public static ExceptionWrapper wrapException(Exception ex) {
		return wrapException(new List<Exception>{ex})[0];
	}

	// these are used to get around Test.createStub limitations where System types can't be mocked
	public static List<ExceptionWrapper> wrapException(List<Exception> exceptions) {
		List<ExceptionWrapper> output = new List<ExceptionWrapper>();
		for(Exception ex : exceptions) {
			output.add(new ExceptionWrapper(ex));
		}
		return output;
	}

	/**
	  * @description	   This method is used to insert ExceptionLog__c record if their Severity__c value is ERROR.
	  * @param			 exceptionLog the ExceptionLog__c record to be created
	  * @return			void
	  * @throws			NA
	  */
	private void insertExceptions(List<ExceptionLog__c> exceptionLogs) {
		if(!exceptionLogs.isEmpty()) {
			ApplicationDatabase.getInstance().dmlInsert(exceptionLogs, false);
		}
	}


	/**
	  * @description	   This method is used to build the ExceptionLog__c record to be inserted.
	  * @param			 excp the Exception object
	  * @param			 applicationName the Application Name
	  * @param			 className the Class Name
	  * @param			 methodName the Method Name
	  * @param			 severity the LoggingLevel variable to determine the exception level
	  * @param			 exceptionName the String containing exception type
	  * @param			 triggerName the String containing Trigger Name
	  * @return			ExceptionLog__c
	  * @throws			NA
	  */
	private ExceptionLog__c buildExceptionObject(ExceptionWrapper wrapper, String applicationName, String className, String methodName, LoggingLevel severity, String triggerName) {

		String exceptionDetails = buildExceptionDetails(wrapper);

		ExceptionLog__c exceptionLog = new ExceptionLog__c();
		exceptionLog.ExceptionDetails__c = (!String.isEmpty(exceptionDetails) ? exceptionDetails.left(EXCEPTION_DETAILS_SIZE_LIMIT) : null);
		exceptionLog.ExceptionType__c = wrapper.ex.getTypeName();
		exceptionLog.Application__c = applicationName;
		exceptionLog.ClassName__c = className;
		exceptionLog.MethodName__c = methodName;
		exceptionLog.ApexTrigger__c = triggerName;
		exceptionLog.ContextUser__c = UserInfo.getUserId();
		exceptionLog.Severity__c = severity.name();
		exceptionLog.ExceptionDescription__c = wrapper.ex.getMessage().left(EXCEPTION_CODE_SIZE_LIMIT);

		Integer startPoint = wrapper.ex.getMessage().indexOf(EXCEPTION_CODE_FILTER) + EXCEPTION_CODE_FILTER.length();
		String excpCode = wrapper.ex.getMessage().substring(startPoint).trim();
		excpCode = (excpCode.split(''))[0];
		exceptionLog.ExceptionCode__c = excpCode.left(excpCode.length() - 1);

		return exceptionLog;
	}

	/**
	  * @description	   This method is used to build the ExceptionLog__c record to be inserted.
	  * @param			 message the message
	  * @param			 applicationName the Application Name
	  * @param			 className the Class Name
	  * @param			 methodName the Method Name
	  * @param			 severity the LoggingLevel variable to determine the exception level
	  * @param			 triggerName the String containing Trigger Name (for unhandledException)
	  * @return			ExceptionLog__c
	  * @throws			NA
	  */
	private static ExceptionLog__c buildExceptionObject(String message, String additionalInfo, String applicationName, String className, String methodName, LoggingLevel severity, String triggerName) {

		ExceptionLog__c exceptionLog = new ExceptionLog__c();
		exceptionLog.ExceptionDetails__c = (!String.isEmpty(message) ? message.left(EXCEPTION_DETAILS_SIZE_LIMIT) : null);
		exceptionLog.AdditionalInformation__c = (!String.isEmpty(additionalInfo) ? additionalInfo.left(ADDITIONAL_INFORMATION_SIZE_LIMIT) : null);
		exceptionLog.Application__c = applicationName;
		exceptionLog.ClassName__c = className;
		exceptionLog.MethodName__c = methodName;
		exceptionLog.ApexTrigger__c = triggerName;
		exceptionLog.ContextUser__c = UserInfo.getUserId();
		exceptionLog.Severity__c = String.valueOf(severity);
		return exceptionLog;
	}


	/**
	  * @description	   This method is used to build the ExceptionDetail__c field value for ExceptionLog__c record to be inserted.
	  * @param			 excp the Exception object
	  * @return			String
	  * @throws			NA
	  */
	private static String buildExceptionDetails(ExceptionWrapper wrapper) {
		return wrapper.ex.getTypeName() + ': ' + wrapper.ex.getMessage() + '\n' + wrapper.ex.getStackTraceString();
	}


	/**
	  * @description	   This method is used to build the error message for the ExceptionLog__c record to be inserted in case of Database.SaveResult or Database.DeleteResult operation.
	  * @param			 idVal the Id of the record throwing exception during Database.insert or Database.delete
	  * @param			 errorList the List of Database.Error Object records
	  * @return			String
	  * @throws			NA
	  */
	private static String buildErrorMessageFromErrorList(Id idVal, List<Database.Error> errorList) {
		String errorMessage = 'Record Id: ' + idVal + '\n';
		for (Database.Error error : errorList) {
			errorMessage += error +  + '\n';
		}
		return errorMessage;
	}

	/**
	 * This is used to get around the limits of Test.createStub not being to stub System types
	 */
	public class ExceptionWrapper {
		public Exception ex;

		public ExceptionWrapper(Exception ex) {
			this.ex = ex;
		}
	}
}