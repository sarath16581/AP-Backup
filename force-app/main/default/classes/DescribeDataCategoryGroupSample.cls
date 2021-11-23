public class DescribeDataCategoryGroupSample {
public static List<DescribeDataCategoryGroupResult> describeDataCategoryGroupSample(){
List<DescribeDataCategoryGroupResult> describeCategoryResult;
try {
//Creating the list of sobjects to use for the describe
//call
List<String> objType = new List<String>();
objType.add('KnowledgeArticleVersion');
//Describe Call
describeCategoryResult = Schema.describeDataCategoryGroups(objType);
//Using the results and retrieving the information
for(DescribeDataCategoryGroupResult singleResult : describeCategoryResult){
//Getting the name of the category
singleResult.getName();
//Getting the name of label
singleResult.getLabel();
//Getting description
singleResult.getDescription();
//Getting the sobject
singleResult.getSobject();
}
} catch(Exception e){
}
return describeCategoryResult;
}
}