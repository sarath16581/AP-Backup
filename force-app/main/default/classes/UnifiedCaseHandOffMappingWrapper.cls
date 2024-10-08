/**
 * @description Case Hand-off Mapping Wrapper to receive data from LWC component
 * @author Vasu Gorakati
 * @date 2024-06-18
 * @changelog
 * 2024-06-18 - Vasu Gorakati - Case Hand-off
 **/
public class UnifiedCaseHandOffMappingWrapper {
  public List<FieldMapping> mappings;

  public class FieldMapping {
	public String unifiedField;
	public String classicField;
	public Map<String, String> valuesMapping;
  }
}