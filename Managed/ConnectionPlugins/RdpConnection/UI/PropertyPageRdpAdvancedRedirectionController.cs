using System;
using Monobjc;
using Monobjc.AppKit;
using Monobjc.Foundation;
using RoyalDocumentLibrary;
using remojoApi;

namespace remojoConnectionTypes.Rdp
{
	[ObjectiveCClass]
	public partial class PropertyPageRdpAdvancedRedirectionController : NSViewController, IPropertyPage
	{
		public bool IsInitialized { get; private set; }
		public string Name { get { return Language.Get("Redirection"); } }
		public RmIcon Icon { get { return ImageAccessor.GetIcon("USB.png"); } }
		public SourceListItem ListItem { get; private set; }
		public NSButton IconButton { get; private set; }
		
		public static readonly Class PropertyPageRdpAdvancedRedirectionControllerClass = Class.Get(typeof(PropertyPageRdpAdvancedRedirectionController));
		public PropertyPageRdpAdvancedRedirectionController() { }
		public PropertyPageRdpAdvancedRedirectionController(IntPtr nativePointer) : base(nativePointer) { }

		public PropertyPageRdpAdvancedRedirectionController(NSString nibNameOrNil, NSBundle nibBundleOrNil) : base("initWithNibName:bundle:", nibNameOrNil, nibBundleOrNil) { }
			
		public Id InitPropertyPage()
		{
			this.InitWithNibNameBundle("PropertyPageRdpAdvancedRedirection", ApiUtils.GetPluginBundleByType(this.GetType()));
			
			this.ListItem = new SourceListItem(this.Name, this.Icon.Icon16);
			
			return this;
		}
		
		[ObjectiveCMessage("dealloc")]
		public override void Dealloc()
		{
			this.ListItem.Release();
			
			this.SendMessageSuper(PropertyPageRdpAdvancedRedirectionControllerClass, "dealloc");
		}
		
		[ObjectiveCMessage("loadView")]
		public override void LoadView()
		{
			this.SendMessageSuper(PropertyPageRdpAdvancedRedirectionControllerClass, "loadView");
			
			this.imageViewAudio.Image = ImageAccessor.GetIcon("Speaker.png").Icon48;
			this.imageViewDevices.Image = ImageAccessor.GetIcon("USB.png").Icon48;
			
			LoadLanguage();
		}
		
		private void LoadLanguage()
		{
			this.textFieldAudioLabel.StringValue = Language.Get("Audio:");
			this.popupButtonAudio.Menu.ItemAtIndex(0).Title = Language.Get("Leave at remote computer");
			this.popupButtonAudio.Menu.ItemAtIndex(1).Title = Language.Get("Do not play");
			this.textFieldDevicesHeader.StringValue = Language.Get("Choose the devices and resources on this computer that you want to use in your remote session.");
			this.checkBoxPrinters.Title = Language.Get("Printers");
			this.checkBoxDiskDrives.Title = Language.Get("Disk drives");
		}
		
		public void Focus()
		{
			this.View.Window.MakeFirstResponder(popupButtonAudio);
		}
		
		public void FuelUiWithData(RoyalBase data)
		{
			RoyalRDSConnection obj = (RoyalRDSConnection)data;
			
			if (obj.AudioRedirectionMode == 2)
				this.popupButtonAudio.SelectItemAtIndex(1);
			else // Bring to this computer falls back to leave at remote computer
				this.popupButtonAudio.SelectItemAtIndex(0);
			
			this.checkBoxPrinters.State = obj.RedirectPrinters.ToNSCellStateValue();
			this.checkBoxDiskDrives.State = obj.RedirectDrives.ToNSCellStateValue();
			
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
			
			obj.AudioRedirectionMode = this.popupButtonAudio.IndexOfSelectedItem == 0 ? 1 : 2;
			
			obj.RedirectPrinters = this.checkBoxPrinters.State.ToBool();
			obj.RedirectDrives = this.checkBoxDiskDrives.State.ToBool();
			
			return true;
		}
	}
}
