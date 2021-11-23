/**
Description - This class is model class to generate json structure for PLI criteria.
Created By - Mahesh Patel
Created Date - 29th Sept, 2020
Last Modified By -
Last Modified Date - 
*/

public with sharing class APT_PLICriteriaModel 
{
	public String sObjectName;
	public String sObjectLabel;
	public Object searchText;
	public Filter filter;
	public List<String> fields;
	public String exprStr;

	public class Filter {
		public List<String> predicates;
		public Object condExpr;
		public ChildFilter childFilter;
    }
    
	public class ChildFilter {
		public String relationFieldName;
		public List<Predicates> predicates;
		public String condExpr;
		public String childSObjectName;
		public String childSObjectLabel;
	}

	public class Predicates {
		public Integer RowNum;
		public Object RHSSObjectName;
		public Object RHSFieldType;
		public Object RHSFieldName;
		public Object RHSFieldLabel;
		public Object RHSChildFilterName;
		public Object RefFieldName;
		public Object OffsetValue;
		public Object LHSSObjectName;
		public Object LHSChildFilterName;
		public String FieldValue;
		public String FieldType;
		public String FieldName;
		public String FieldLabel;
		public String CompOper;
		public String BoolOper;
	}
}