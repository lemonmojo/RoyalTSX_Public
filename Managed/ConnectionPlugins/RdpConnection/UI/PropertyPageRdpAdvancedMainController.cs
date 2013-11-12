using System;
using Monobjc;
using Monobjc.AppKit;
using Monobjc.Foundation;
using RoyalDocumentLibrary;
using remojoApi;

namespace remojoConnectionTypes.Rdp
{
	[ObjectiveCClass]
	public partial class PropertyPageRdpAdvancedMainController : NSViewController, IPropertyPage
	{
		public bool IsInitialized { get; private set; }
		public string Name { get { return Language.Get("Advanced"); } }
		public RmIcon Icon { get { return ImageAccessor.GetIcon("AdvancedSettings.png"); } }
		public SourceListItem ListItem { get; private set; }
		public NSButton IconButton { get; private set; }
		
		public static readonly Class PropertyPageRdpAdvancedMainControllerClass = Class.Get(typeof(PropertyPageRdpAdvancedMainController));
		public PropertyPageRdpAdvancedMainController() { }
		public PropertyPageRdpAdvancedMainController(IntPtr nativePointer) : base(nativePointer) { }

		public PropertyPageRdpAdvancedMainController(NSString nibNameOrNil, NSBundle nibBundleOrNil) : base("initWithNibName:bundle:", nibNameOrNil, nibBundleOrNil) { }
			
		public Id InitPropertyPage()
		{
			this.InitWithNibNameBundle("PropertyPageRdpAdvancedMain", ApiUtils.GetPluginBundleByType(this.GetType()));
			
			this.ListItem = new SourceListItem(this.Name, this.Icon.Icon16);
			
			return this;
		}
		
		[ObjectiveCMessage("dealloc")]
		public override void Dealloc()
		{
			this.ListItem.Release();
			
			this.SendMessageSuper(PropertyPageRdpAdvancedMainControllerClass, "dealloc");
		}
		
		[ObjectiveCMessage("loadView")]
		public override void LoadView()
		{
			this.SendMessageSuper(PropertyPageRdpAdvancedMainControllerClass, "loadView");
			
			this.imageViewHeader.Image = ImageAccessor.GetIcon("AdvancedSettings.png").Icon48;
			
			LoadLanguage();
		}
		
		private void LoadLanguage()
		{
			checkBoxCustomPort.Title = Language.Get("Custom Port:");
			checkBoxConsoleSession.Title = Language.Get("Console/Admin Session");
		}
		
		public void Focus()
		{
			this.View.Window.MakeFirstResponder(checkBoxCustomPort);
		}
		
		public void FuelUiWithData(RoyalBase data)
		{
			RoyalRDSConnection obj = (RoyalRDSConnection)data;
			
			checkBoxCustomPort.State = (obj.RDPPort == 3389 ? NSCellStateValue.NSOffState : NSCellStateValue.NSOnState);
			CheckBoxCustomPort_Action(checkBoxCustomPort);
			
			textFieldCustomPort.IntValue = obj.RDPPort;
			checkBoxConsoleSession.State = obj.ConnectToAdministerOrConsole.ToNSCellStateValue();
			
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
			
			obj.RDPPort = textFieldCustomPort.IntValue;
			obj.ConnectToAdministerOrConsole = checkBoxConsoleSession.State.ToBool();
			
			return true;
		}

		partial void CheckBoxCustomPort_Action(Id sender)
		{
			if (ObjectiveCRuntime.CastTo<NSButton>(sender).State == NSCellStateValue.NSOffState) {
				textFieldCustomPort.IsEnabled = false;
				textFieldCustomPort.IntValue = 3389;
			} else {
				textFieldCustomPort.IsEnabled = true;
			}
		}
	}
}
