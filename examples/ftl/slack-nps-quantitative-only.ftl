<#assign UtilClass=statics['com.amplitude.integrations.connector.utils.FtlUtils']>
<#assign survey_response = input.event_properties["[Guides-Surveys] Survey Response"]>
<#assign step_title = input.event_properties["[Guides-Surveys] Step Title"]>
<#assign page_path = input.event_properties["[Guides-Surveys] Page.path"]>
<#assign page_domain = input.event_properties["[Guides-Surveys] Page.domain"]>
<#assign page_title = input.event_properties["[Guides-Surveys] Page.title"]>
<#assign org_id = input.user_properties.org_id>
<#assign org_name = input.group_properties.org_id[org_id].organization_name>

<#assign isBeta_styled>
<#if input.user_properties.isBeta?boolean>
:telescope: Preview mode on
<#else>
Preview mode off
</#if>
</#assign>

<#assign isOrgAdmin_styled>
<#if input.user_properties.isOrgAdmin?boolean>
:crown: Org. Administrator
<#else>
Unprivileged user
</#if>
</#assign>

{
  "app": "${input.app}",
  "amplitude_id": "${input.amplitude_id}",
  "country": "${input.country}",
  "step_title": "${step_title}",
  "survey_response": ${UtilClass.toJsonString(survey_response)},
  "page_title": "${page_title}",
  "page_domain": "${page_domain}",
  "page_path": "${page_path}",
  "email_domain": "${input.user_properties.email_domain}",
  "org_id": "${org_id}",
  "organization_name": "${org_name}",
  "isBeta_styled": "${isBeta_styled}",
  "isOrgAdmin_styled": "${isOrgAdmin_styled}"
}
