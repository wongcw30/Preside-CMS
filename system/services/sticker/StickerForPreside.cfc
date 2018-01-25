/**
 * @presideService true
 * @singleton      true
 *
 */
component {

	/**
	 * @controller.inject coldbox
	 *
	 */
	public any function init() {
		_initSticker();

		return this;
	}

	public any function addBundle()      { return _getSticker().addBundle     ( argumentCollection=arguments ); }
	public any function load()           { return _getSticker().load          ( argumentCollection=arguments ); }
	public any function ready()          { return _getSticker().ready         ( argumentCollection=arguments ); }
	public any function getAssetUrl()    { return _getSticker().getAssetUrl   ( argumentCollection=arguments ); }
	public any function include()        { return _getSticker().include       ( argumentCollection=arguments ); }
	public any function includeData()    { return _getSticker().includeData   ( argumentCollection=arguments ); }
	public any function renderIncludes() { return _getSticker().renderIncludes( argumentCollection=arguments ); }

// PRIVATE HELPERS
	private void function _initSticker() {
		var sticker           = new sticker.Sticker();
		var settings          = $getColdbox().getSettingStructure();
		var sysAssetsPath     = "/preside/system/assets/"
		var extensionsRootUrl = "/preside/system/assets/extension/";
		var siteAssetsPath    = settings.static.siteAssetsPath ?: "/assets";
		var siteAssetsUrl     = settings.static.siteAssetsUrl  ?: "/assets";
		var rootURl           = ( settings.static.rootUrl ?: "" );

		sticker.addBundle( rootDirectory=sysAssetsPath , rootUrl=sysAssetsPath          , config=settings )
		       .addBundle( rootDirectory=siteAssetsPath, rootUrl=rootUrl & siteAssetsUrl, config=settings );

		for( var ext in settings.activeExtensions ) {
			var stickerDirectory  = ( ext.directory ?: "" ) & "/assets";
			var stickerBundleFile = stickerDirectory & "/StickerBundle.cfc";

			if ( FileExists( stickerBundleFile ) ) {
				sticker.addBundle( rootDirectory=stickerDirectory, rootUrl=extensionsRootUrl & ListLast( ext.directory, "\/" ) & "/assets" );
			}
		}

		sticker.load();

		_setSticker( sticker );
	}

// GETTERS AND SETTERS
	private any function _getSticker() {
		return _sticker;
	}
	private void function _setSticker( required any sticker ) {
		_sticker = arguments.sticker;
	}

}