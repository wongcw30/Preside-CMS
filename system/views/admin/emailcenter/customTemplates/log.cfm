<cfscript>
	templateId = rc.id ?: "";
	ajaxUrl    = event.buildAdminLink( linkTo="emailCenter.customTemplates.getLogsForAjaxDataTables", querystring="id=" & templateid );
	gridFields = [ "recipient", "subject", "sent_date", "sent", "opened", "click_count" ];
</cfscript>
<cfoutput>
	<cfsavecontent variable="body">
		#renderView( view="/admin/datamanager/_objectDataTable", args={
			  objectName          = "email_template_send_log"
			, useMultiActions     = false
			, datasourceUrl       = ajaxUrl
			, gridFields          = gridFields
		} )#
	</cfsavecontent>

	#renderViewlet( event="admin.emailcenter.customtemplates._customTemplateTabs", args={ body=body, tab="log" } )#
</cfoutput>