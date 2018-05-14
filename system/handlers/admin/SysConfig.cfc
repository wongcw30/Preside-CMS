component extends="preside.system.base.AdminHandler" {

	property name="systemConfigurationService" inject="systemConfigurationService";
	property name="siteService"                inject="siteService";
	property name="messageBox"                 inject="messagebox@cbmessagebox";
	property name="presideObjectService"         inject="presideObjectService";


// LIFECYCLE EVENTS
	function preHandler( event, rc, prc ) {
		super.preHandler( argumentCollection = arguments );

		if ( !isFeatureEnabled( "systemConfiguration" ) ) {
			event.notFound();
		}

		if ( !hasCmsPermission( permissionKey="systemConfiguration.manage" ) ) {
			event.adminAccessDenied();
		}

		event.addAdminBreadCrumb(
			  title = translateResource( "cms:sysConfig" )
			, link  = event.buildAdminLink( linkTo="sysConfig" )
		);
	}

// FIRST CLASS EVENTS
	public any function index( event, rc, prc ) {
		prc.categories = systemConfigurationService.listConfigCategories();

		prc.pageTitle    = translateResource( uri="cms:sysconfig" );
		prc.pageSubtitle = translateResource( uri="cms:sysconfig.subtitle" );
		prc.pageIcon     = "cogs";
	}

	public any function category( event, rc, prc ) {
		var categoryId       = Trim( rc.id   ?: "" );
		var siteId           = Trim( rc.site ?: "" );
		var versionId        = Val( rc.version ?: "" );
		var fromVersionTable = Val( versionId ) ? true : false

		try {
			prc.category = systemConfigurationService.getConfigCategory( id = categoryId );
		} catch( "SystemConfigurationService.category.notFound" e ) {
			event.notFound();
		}
		prc.sites = siteService.listSites();

		var isSiteConfig = prc.sites.recordCount > 1 && siteId.len();
		if ( isSiteConfig ) {
			prc.savedData = systemConfigurationService.getCategorySettings(
				  category           = categoryId
				, includeDefaults    = false
				, siteId             = siteId
				, fromVersionTable   = fromVersionTable
				, maxVersionNumber   = versionId
				, maxRows            = 2
				, orderBy            = "dateCreated DESC"
			);
		} else {
			prc.savedData = systemConfigurationService.getCategorySettings(
				  category           = categoryId
				, globalDefaultsOnly = true
				, fromVersionTable   = fromVersionTable
				, maxVersionNumber   = versionId
				, maxRows            = 2
				, orderBy            = "dateCreated DESC"
			);
		}

		prc.categoryName        = translateResource( uri=prc.category.getName(), defaultValue=prc.category.getId() );
		prc.categoryDescription = translateResource( uri=prc.category.getDescription(), defaultValue="" );
		prc.formName            = isSiteConfig ? prc.category.getSiteForm() : prc.category.getForm();

		event.addAdminBreadCrumb(
			  title = prc.categoryName
			, link  = ""
		);

		prc.pageTitle    = translateResource( uri="cms:sysconfig.editCategory.title", data=[ prc.categoryName ] );
		prc.pageSubtitle = prc.categoryDescription;
		prc.pageIcon     = translateResource( uri=prc.category.getIcon(), defaultValue="" );

		if ( !Len( Trim( prc.pageIcon ) ) ) {
			prc.pageIcon = "cogs";
		}
	}

	public any function saveCategoryAction( event, rc, prc ) {
		var categoryId = rc.id ?: "";
		var siteId     = rc.site ?: "";

		try {
			prc.category = systemConfigurationService.getConfigCategory( id = categoryId );
		} catch( "SystemConfigurationService.category.notFound" e ) {
			event.notFound();
		}

		var formName = Len( Trim( siteId ) ) ? prc.category.getSiteForm() : prc.category.getForm();
		var formData = event.getCollectionForForm( formName );

		if ( Len( Trim( siteId ) ) ) {
			for( var setting in formData ){
				if ( IsFalse( rc[ "_override_" & setting ] ?: "" ) ) {
					formData.delete( setting );
					systemConfigurationService.deleteSetting(
						  category = categoryId
						, setting  = setting
						, siteId   = siteId
					);
				}
			}
		}

		var validationResult = validateForm(
			  formName      = formName
			, formData      = formData
			, ignoreMissing = Len( Trim( siteId ) )
		);

		announceInterception( "preSaveSystemConfig", {
			  category         = categoryId
			, configuration    = formData
			, validationResult = validationResult
		} );

		if ( !validationResult.validated() ) {
			messageBox.error( translateResource( uri="cms:sysconfig.validation.failed" ) );
			var persist = formData;
			persist.validationResult = validationResult;

			setNextEvent(
				  url           = event.buildAdminLink(linkTo="sysconfig.category", queryString="id=#categoryId#" )
				, persistStruct = persist
			);
		}

		for( var setting in formData ){
			systemConfigurationService.saveSetting(
				  category = categoryId
				, setting  = setting
				, value    = formData[ setting ]
				, siteId   = siteId
			);
		}

		event.audit(
			  action   = "save_sysconfig_category"
			, type     = "sysconfig"
			, recordId = categoryId
			, detail   = formData
		);

		announceInterception( "postSaveSystemConfig", {
			  category         = categoryId
			, configuration    = formData
		} );

		messageBox.info( translateResource( uri="cms:sysconfig.saved" ) );
		setNextEvent( url=event.buildAdminLink( linkTo="sysconfig.category", queryString="id=#categoryId#" ) );
	}

	public void function configHistory( event, rc, prc ) {
		var categoryId = Trim( rc.id   ?: "" );
		var siteId     = Trim( rc.site ?: "" );

		try {
			prc.category = systemConfigurationService.getConfigCategory( id = categoryId );
		} catch( "SystemConfigurationService.category.notFound" e ) {
			event.notFound();
		}
	}

	public void function getConfigHistoryForAjaxDataTables( event, rc, prc ) {
		prc.setting = structKeyList( event.getCollectionForForm( "system-config.#rc.id#" ) );

		var nextVersionNumber = val(presideObjectService.selectData(
			objectName      = "system_config",
			fromVersionTable = true,
			selectFields    = [ "Max( _version_number ) as max_version_number" ]
			, filter = { category = id }
		).max_version_number);
		var allFieldsData = presideObjectService.selectData(
			objectName       = "system_config",
			filter           = "category = :category AND setting IN ( :setting )",
			filterParams     = { "category"=rc.id, "setting"={ value=prc.setting, list="yes" } },
			fromVersionTable = true,
			maxVersionNumber = nextVersionNumber
		);
		var configIds = listRemoveDuplicates(valueList(allFieldsData.id));

		runEvent(
			  event          = "admin.DataManager._getRecordHistoryForAjaxDataTables"
			, prePostExempt  = true
			, private        = true
			, eventArguments = {
				  object     = "system_config"
				, recordId   = configIds
				, actionsView = "admin/SysConfig/_historyActions"
			}
		);
	}

// VIEWLETS
	private string function categoryMenu( event, rc, prc, args ) {
		args.categories = systemConfigurationService.listConfigCategories();

		return renderView( view="admin/sysconfig/categoryMenu", args=args );
	}

	private string function groupVersionNavigator( event, rc, prc, args={} ) {
		var selectedVersion = Val( args.version ?: "" );
		var objectName      = args.object ?: "";
		var id              = args.id     ?: "";
		var setting         = structKeyList( event.getCollectionForForm( "system-config.#args.id#" ) );
		var maxVersion      = val(presideObjectService.selectData(
			objectName      = "system_config",
			fromVersionTable = true,
			selectFields    = [ "Max( _version_number ) as max_version_number" ]
			, filter = { category = id }
		).max_version_number);

		args.versions        = presideObjectService.selectData(
			objectName       = "system_config",
			selectFields     = ["system_config.id", "system_config.site", "system_config.category", "system_config.setting", "system_config.value", "system_config.datecreated", "system_config.datemodified", "system_config._version_is_draft", "system_config._version_has_drafts", "system_config._version_number"],
			filter           = "category = :category AND setting IN ( :setting )",
			filterParams     = { "category"=id, "setting"={ value=setting, list="yes" } },
			fromVersionTable = true,
			maxVersionNumber = maxVersion,
			orderBy          = "system_config._version_number DESC"
		);

		args.latestVersion   = queryExecute(
			sql     = "select top 1 _version_number as latestVersion from args.versions order by _version_number DESC"
			, options = { dbtype="query" }
		).latestVersion[1];
		if(args.latestVersion == "") args.latestVersion = maxVersion;

		args.latestPublishedVersion = queryExecute(
			sql     = "select top 1 _version_number as latestVersion from args.versions where _version_is_draft = 0 order by _version_number DESC"
			, options = { dbtype="query" }
		).latestVersion[1];
		if(args.latestPublishedVersion == "") args.latestPublishedVersion = maxVersion;

		if ( !selectedVersion ) {
			selectedVersion = args.latestVersion;
		}

		args.isLatest    = args.latestVersion == selectedVersion;
		args.nextVersion = 0;
		args.prevVersion = args.versions.recordCount < 2 ? 0 : args.versions._version_number[ args.versions.recordCount-1 ];

		for( var i=1; i <= args.versions.recordCount; i++ ){
			if ( args.versions._version_number[i] == selectedVersion ) {
				args.nextVersion = i > 1 ? args.versions._version_number[i-1] : 0;
				args.prevVersion = i < args.versions.recordCount ? args.versions._version_number[i+1] : 0;
			}
		}

		return renderView( view="admin/sysconfig/groupVersionNavigator", args=args );
	}

}