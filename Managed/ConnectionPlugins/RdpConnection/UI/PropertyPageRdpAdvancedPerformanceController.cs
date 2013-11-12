using System;
using Monobjc;
using Monobjc.AppKit;
using Monobjc.Foundation;
using RoyalDocumentLibrary;
using remojoApi;

namespace remojoConnectionTypes.Rdp
{
	[ObjectiveCClass]
	public partial class PropertyPageRdpAdvancedPerformanceController : NSViewController, IPropertyPage
	{
		public bool IsInitialized { get; private set; }
		public string Name { get { return Language.Get("Performance"); } }
		public RmIcon Icon { get { return ImageAccessor.GetIcon("RDPPerformance.png"); } }
		public SourceListItem ListItem { get; private set; }
		public NSButton IconButton { get; private set; }
		
		public static readonly Class PropertyPageRdpAdvancedPerformanceControllerClass = Class.Get(typeof(PropertyPageRdpAdvancedPerformanceController));
		public PropertyPageRdpAdvancedPerformanceController() { }
		public PropertyPageRdpAdvancedPerformanceController(IntPtr nativePointer) : base(nativePointer) { }

		public PropertyPageRdpAdvancedPerformanceController(NSString nibNameOrNil, NSBundle nibBundleOrNil) : base("initWithNibName:bundle:", nibNameOrNil, nibBundleOrNil) { }
			
		public Id InitPropertyPage()
		{
			this.InitWithNibNameBundle("PropertyPageRdpAdvancedPerformance", ApiUtils.GetPluginBundleByType(this.GetType()));
			
			this.ListItem = new SourceListItem(this.Name, this.Icon.Icon16);
			
			return this;
		}
		
		[ObjectiveCMessage("dealloc")]
		public override void Dealloc()
		{
			this.ListItem.Release();
			
			this.SendMessageSuper(PropertyPageRdpAdvancedPerformanceControllerClass, "dealloc");
		}
		
		[ObjectiveCMessage("loadView")]
		public override void LoadView()
		{
			this.SendMessageSuper(PropertyPageRdpAdvancedPerformanceControllerClass, "loadView");
			
			this.imageViewHeader.Image = ImageAccessor.GetIcon("RDPPerformance.png").Icon48;
			
			LoadLanguage();
		}
		
		private void LoadLanguage()
		{
			this.textFieldHeader.StringValue = Language.Get("On this page you can tweak RDP performance options. To improve performance, check only the boxes for the settings you really need.");
			checkBoxDesktopBackground.Title = Language.Get("Desktop background");
			checkBoxMenuAndWindowAnimations.Title = Language.Get("Menu and window animations");
			checkBoxShowWindowContentsWhileDragging.Title = Language.Get("Show window contents while dragging");
			checkBoxFontSmoothing.Title = Language.Get("Font smoothing");
			checkBoxVisualStyles.Title = Language.Get("Visual styles");
		}
		
		public void Focus()
		{
			this.View.Window.MakeFirstResponder(checkBoxDesktopBackground);
		}
		
		public void FuelUiWithData(RoyalBase data)
		{
			RoyalRDSConnection obj = (RoyalRDSConnection)data;
			
			checkBoxDesktopBackground.State = obj.AllowWallpaper.ToNSCellStateValue();
			checkBoxMenuAndWindowAnimations.State = obj.AllowMenuAnimations.ToNSCellStateValue();
			checkBoxShowWindowContentsWhileDragging.State = obj.AllowFullWindowDrag.ToNSCellStateValue();
			checkBoxFontSmoothing.State = obj.AllowFontSmoothing.ToNSCellStateValue();
			checkBoxVisualStyles.State = obj.AllowThemes.ToNSCellStateValue();
			
			this.IsInitialized = true;
		}
		
		public bool ValidateUiData(RoyalBase data)
		{
			return true;
		}
		
		public bool FuelDataWithData(RoyalBase data)
		{
			if (!this.IsInitialized)
				return true;
			
			if (!ValidateUiData(data))
				return false;
			
			RoyalRDSConnection obj = (RoyalRDSConnection)data;
			
			obj.AllowWallpaper = checkBoxDesktopBackground.State.ToBool();
			obj.AllowMenuAnimations = checkBoxMenuAndWindowAnimations.State.ToBool();
			obj.AllowFullWindowDrag = checkBoxShowWindowContentsWhileDragging.State.ToBool();
			obj.AllowFontSmoothing = checkBoxFontSmoothing.State.ToBool();
			obj.AllowThemes = checkBoxVisualStyles.State.ToBool();
			
			return true;
		}
	}
}
