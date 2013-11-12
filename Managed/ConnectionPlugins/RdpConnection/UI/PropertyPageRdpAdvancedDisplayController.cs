using System;
using Monobjc;
using Monobjc.AppKit;
using Monobjc.Foundation;
using RoyalDocumentLibrary;
using remojoApi;

namespace remojoConnectionTypes.Rdp
{
	[ObjectiveCClass]
	public partial class PropertyPageRdpAdvancedDisplayController : NSViewController, IPropertyPage
	{
		public bool IsInitialized { get; private set; }
		public string Name { get { return Language.Get("Display Options"); } }
		public RmIcon Icon { get { return ImageAccessor.GetIcon("RDPScreenColors.png"); } }
		public SourceListItem ListItem { get; private set; }
		public NSButton IconButton { get; private set; }
		
		public static readonly Class PropertyPageRdpAdvancedDisplayControllerClass = Class.Get(typeof(PropertyPageRdpAdvancedDisplayController));
		public PropertyPageRdpAdvancedDisplayController() { }
		public PropertyPageRdpAdvancedDisplayController(IntPtr nativePointer) : base(nativePointer) { }

		public PropertyPageRdpAdvancedDisplayController(NSString nibNameOrNil, NSBundle nibBundleOrNil) : base("initWithNibName:bundle:", nibNameOrNil, nibBundleOrNil) { }
			
		public Id InitPropertyPage()
		{
			this.InitWithNibNameBundle("PropertyPageRdpAdvancedDisplay", ApiUtils.GetPluginBundleByType(this.GetType()));
			
			this.ListItem = new SourceListItem(this.Name, this.Icon.Icon16);
			
			return this;
		}
		
		[ObjectiveCMessage("dealloc")]
		public override void Dealloc()
		{
			this.ListItem.Release();
			
			this.SendMessageSuper(PropertyPageRdpAdvancedDisplayControllerClass, "dealloc");
		}
		
		[ObjectiveCMessage("loadView")]
		public override void LoadView()
		{
			this.SendMessageSuper(PropertyPageRdpAdvancedDisplayControllerClass, "loadView");
			
			this.imageViewColors.Image = ImageAccessor.GetIcon("RDPScreenColors.png").Icon48;
			this.imageViewSize.Image = ImageAccessor.GetIcon("RDPScreenSize.png").Icon48;
			
			LoadLanguage();
		}
		
		private void LoadLanguage()
		{
			this.textFieldColorsLabel.StringValue = Language.Get("Colors:");
			this.popupButtonColors.Menu.ItemAtIndex(0).Title = Language.Get("256 Colors");
			this.popupButtonColors.Menu.ItemAtIndex(1).Title = Language.Get("Thousands");
			this.popupButtonColors.Menu.ItemAtIndex(2).Title = Language.Get("Millions");
			this.textFieldSizeDescription.StringValue = Language.Get("You can set the desktop size to fill the client area (\"Auto Expand\") or you specify a custom desktop size.");
			this.textFieldDesktopSizeLabel.StringValue = Language.Get("Desktop Size:");
			this.popupButtonDesktopSize.Menu.ItemAtIndex(0).Title = Language.Get("Auto Expand");
			this.popupButtonDesktopSize.Menu.ItemAtIndex(1).Title = Language.Get("Custom Size");
			this.textFieldCustomSizeWidthLabel.StringValue = Language.Get("Width:");
			this.textFieldCustomSizeHeightLabel.StringValue = Language.Get("Height:");
			this.textFieldResizeModeLabel.StringValue = Language.Get("Resize Mode:");
			this.popupButtonResizeMode.Menu.ItemAtIndex(0).Title = Language.Get("Scroll Bars");
			this.popupButtonResizeMode.Menu.ItemAtIndex(1).Title = Language.Get("Smart Reconnect");
		}
		
		public void Focus()
		{
			this.View.Window.MakeFirstResponder(popupButtonColors);
		}
		
		public void FuelUiWithData(RoyalBase data)
		{
			RoyalRDSConnection obj = (RoyalRDSConnection)data;
			
			switch (obj.ColorDepth) {
				case 8:
					popupButtonColors.SelectItemAtIndex(0);
					break;
				case 16:
					popupButtonColors.SelectItemAtIndex(1);
					break;
				case 24:
					popupButtonColors.SelectItemAtIndex(2);
					break;
				default:
					popupButtonColors.SelectItemAtIndex(2);
					break;
			}
			
			if (obj.DesktopWidth == 0 && obj.DesktopHeight == 0)
				this.popupButtonDesktopSize.SelectItemAtIndex(0);
			else {
				this.popupButtonDesktopSize.SelectItemAtIndex(1);
				this.textFieldCustomSizeWidth.IntValue = obj.DesktopWidth;
				this.textFieldCustomSizeHeight.IntValue = obj.DesktopHeight;
			}
			
			PopupButtonDesktopSize_Action(this);
			
			if (obj.SmartReconnect)
				this.popupButtonResizeMode.SelectItemAtIndex(1);
			else // Smart Size falls back to Scroll Bars
				this.popupButtonResizeMode.SelectItemAtIndex(0);
			
			PopupButtonResizeMode_Action(this);
			
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
			
			switch ((int)this.popupButtonColors.IndexOfSelectedItem) {
				case 0:
					obj.ColorDepth = 8;
					break;
				case 1:
					obj.ColorDepth = 16;
					break;
				case 2:
					obj.ColorDepth = 24;
					break;
			}
			
			if (this.popupButtonDesktopSize.IndexOfSelectedItem == 0) {
				obj.DesktopWidth = 0;
				obj.DesktopHeight = 0;
			} else if (this.popupButtonDesktopSize.IndexOfSelectedItem == 1) {
				obj.DesktopWidth = this.textFieldCustomSizeWidth.IntValue;
				obj.DesktopHeight = this.textFieldCustomSizeHeight.IntValue;
			}
			
			obj.SmartSizing = false;
			obj.SmartReconnect = popupButtonResizeMode.IndexOfSelectedItem == 1;
			
			return true;
		}
		
		partial void PopupButtonDesktopSize_Action(Id sender)
		{
			viewCustomSize.IsHidden = popupButtonDesktopSize.IndexOfSelectedItem != 1;
		}
		
		partial void PopupButtonResizeMode_Action(Id sender)
		{
			if (popupButtonResizeMode.IndexOfSelectedItem == 0)
				textFieldResizeModeDescription.StringValue = Language.Get("Decreasing the window size will show scroll bars in the remote session.");
			else if (popupButtonResizeMode.IndexOfSelectedItem == 1)
				textFieldResizeModeDescription.StringValue = Language.Get("Changing the window size will force a reconnect, so that the remote desktop will adapt to the new size.");
		}
	}
}
