<#assign UtilClass=statics['com.amplitude.integrations.connector.utils.FtlUtils']>
<#assign dom="example.com">
{
  "user_email_domain": "${dom}",
  <#list input.event_properties as key, value>
  "${key}": <#if value?is_number || value?is_boolean>${value}<#else>${UtilClass.toJsonString(value)}</#if><#if key_has_next>,</#if>
  </#list>
  <#list input.user_properties as key, value>
  "${key}": <#if value?is_number || value?is_boolean>${value}<#else>${UtilClass.toJsonString(value)}</#if><#if key_has_next>,</#if>
  </#list>
}
