<cfscript>
	templateId = rc.template ?: "";
	ajaxUrl    = event.buildAdminLink( linkTo="emailCenter.systemTemplates.getLogsForAjaxDataTables", querystring="template=" & templateid );
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

	#renderViewlet( event="admin.emailcenter.systemtemplates._templateTabs", args={ body=body, tab="log" } )#
</cfoutput>