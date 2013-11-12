using System;
using Monobjc;
using Monobjc.AppKit;
using Monobjc.Foundation;
using RoyalDocumentLibrary;
using remojoApi;

namespace remojoConnectionTypes.Rdp
{
	[ObjectiveCClass]
	public partial class PropertyPageRdpMainController : NSViewController, IPropertyPage
	{
		private NSResponder m_prevResponder;

		public bool IsInitialized { get; private set; }
		public string Name { get { return RoyalRDSConnection.ObjectTypeShortName.TL(); } }
		public RmIcon Icon { get { return ImageAccessor.GetIcon("RDPConnection.png"); } }
		public SourceListItem ListItem { get; private set; }
		public RmIconChooserButton IconButton { get; private set; }
		public RmColorChooserButton ColorButton { get; private set; }
		public ObjectEditMode EditMode { get; set; }
		
		public static readonly Class PropertyPageRdpMainControllerClass = Class.Get(typeof(PropertyPageRdpMainController));
		public PropertyPageRdpMainController() { }
		public PropertyPageRdpMainController(IntPtr nativePointer) : base(nativePointer) { }
		public PropertyPageRdpMainController (NSString nibNameOrNil, NSBundle nibBundleOrNil) : base("initWithNibName:bundle:", nibNameOrNil, nibBundleOrNil) { }

		public Id InitPropertyPage()
		{
			this.InitWithNibNameBundle("PropertyPageRdpMain", ApiUtils.GetPluginBundleByType(this.GetType()));
		
			this.ListItem = new SourceListItem(this.Name, this.Icon.Icon16);
			
			return this;
		}
			
		[ObjectiveCMessage("dealloc")]
		public override void Dealloc()
		{
			NSNotificationCenter.DefaultCenter.RemoveObserver(this);
			this.ListItem.Release();
			
			this.SendMessageSuper(PropertyPageRdpMainControllerClass, "dealloc");
		}
		
		[ObjectiveCMessage("loadView")]
		public override void LoadView()
		{
			this.SendMessageSuper(PropertyPageRdpMainControllerClass, "loadView");
			
			this.IconButton = buttonIcon;
			this.ColorButton = buttonColor;

			imageViewDescription.Image = Icon.Icon48;

			LoadLanguage();

			NSNotificationCenter.DefaultCenter.AddObserverSelectorNameObject(this, "windowDidUpdate:".ToSelector(), NSWindow.NSWindowDidUpdateNotification, this.View.Window);
		}
		
		private void LoadLanguage()
		{
			textFieldDescription.StringValue = Language.Get("With a Remote Desktop connection you can connect to remote computers supporting RDP (Remote Desktop Protocol, Standard Port is 3389). You can change the port in the Advanced section.");
			textFieldComputerNameLabel.StringValue = "Computer Name:".TL();
			textFieldComputerName.Cell.CastTo<NSTextFieldCell>().PlaceholderString = "Computer Name (IP/FQDN)".TL();
			textFieldDisplayNameLabel.StringValue = "Display Name:".TL();
			textFieldDisplayName.Cell.CastTo<NSTextFieldCell>().PlaceholderString = "Display Name".TL();
			textFieldConnectionDescriptionLabel.StringValue = "Description:".TL();
			textFieldConnectionDescription.Cell.CastTo<NSTextFieldCell>().PlaceholderString = "Description".TL();
			textFieldPhysicalAddressLabel.StringValue = "Physical Address:".TL();
			textFieldPhysicalAddress.Cell.CastTo<NSTextFieldCell>().PlaceholderString = "Physical Address".TL();
		}

		[ObjectiveCMessage("windowDidUpdate:")]
		public void WindowDidUpdate (NSNotification notification)
		{
			if (this.View != null &&
			    this.View.Window != null &&
			    this.View.Window.FirstResponder != null) {
				NSTextField tv = ApiUtils.GetFirstResponderTextField(this.View.Window);
				
				if (tv != null) {
					if (m_prevResponder != tv &&
					    ApiUtils.IsTextFieldFirstResponder (this.View.Window, textFieldComputerName) &&
					    textFieldComputerName.StringValue.IsEqualToString(NSString.Empty) &&
					    !textFieldDisplayName.StringValue.IsEqualToString(NSString.Empty)) {
						textFieldComputerName.StringValue = textFieldDisplayName.StringValue;
					}
					
					m_prevResponder = tv;
				} else {
					m_prevResponder = this.View.Window.FirstResponder;
				}
			}
		}
		
		public void Focus()
		{
			this.View.Window.MakeFirstResponder(textFieldDisplayName);
		}
		
		public void FuelUiWithData(RoyalBase data)
		{
			RoyalRDSConnection obj = (RoyalRDSConnection)data;
			
			textFieldDisplayName.StringValue = obj.Name;
			
			if (!obj.IsDefaultSetting) {
				textFieldComputerName.StringValue = obj.URI;
			} else {
				textFieldComputerName.IsEnabled = false;
				textFieldDisplayName.IsEnabled = false;
			}

			buttonComputerNameEditor.IsEnabled = (!obj.IsDefaultSetting && EditMode == ObjectEditMode.EditMode_New);
			
			textFieldConnectionDescription.StringValue = obj.Description;
			textFieldPhysicalAddress.StringValue = obj.PhysicalAddress;
			
			metadataView.RoyalObject = obj;
			
			this.IsInitialized = true;
		}
		
		public bool ValidateUiData(RoyalBase data)
		{
			bool retVal = true;
			
			if (!data.IsDefaultSetting) {
				bool isDisplayNameRequired = !IsInBulkAddMode;
				bool displayNameOk = !string.IsNullOrEmpty(textFieldDisplayName.StringValue);
				bool computerNameOk = !string.IsNullOrEmpty(textFieldComputerName.StringValue);
				
				if (isDisplayNameRequired && !displayNameOk)
					RmMessageBox.Show(RmMessageBoxType.WarningMessage, 
					                  this.View.Window, 
					                  "Warning".TL(), 
					                  Language.Get("The \"Display Name\" must not be empty."), 
					                  "OK".TL());

				if (!computerNameOk)
					RmMessageBox.Show(RmMessageBoxType.WarningMessage, 
					                  this.View.Window, 
					                  "Warning".TL(), 
					                  Language.Get("The \"Computer Name\" must not be empty."), 
					                  "OK".TL());
				
				retVal = (!isDisplayNameRequired || (isDisplayNameRequired && displayNameOk)) && computerNameOk;
			}
			
			return retVal;
		}
		
		public bool FuelDataWithData(RoyalBase data)
		{
			if (!this.IsInitialized)
				return true;
			
			if (!ValidateUiData(data))
				return false;
			
			RoyalRDSConnection obj = (RoyalRDSConnection)data;
			
			if (!obj.IsDefaultSetting) {
				obj.URI = textFieldComputerName.StringValue;
				obj.Name = textFieldDisplayName.StringValue;
			}
			
			obj.Description = textFieldConnectionDescription.StringValue;
			obj.PhysicalAddress = textFieldPhysicalAddress.StringValue;
			
			return true;
		}

		partial void ButtonComputerNameEditor_Action (Id sender)
		{
			string computers = RmComputerPicker.Show(this.View.Window, new RmComputerPickerArguments() {
				BonjourEnabled = false,
				CustomEntryEnabled = this.EditMode == ObjectEditMode.EditMode_New,
				CanAddMultiple = this.EditMode == ObjectEditMode.EditMode_New,
				CurrentHosts = textFieldComputerName.StringValue
			});
			
			if (!string.IsNullOrWhiteSpace(computers)) {
				string[] computerLines = computers.Split(new string[] { "\r\n", "\n", "\r" }, StringSplitOptions.RemoveEmptyEntries);
				
				if (computerLines.Length == 1) {
					RoyalRDSConnection con = new RoyalRDSConnection(null);
					ApiUtils.ExtendConnectionWithTaggedComputerString(con, computerLines[0]);
					
					if (!string.IsNullOrWhiteSpace(con.Name))
						textFieldDisplayName.StringValue = con.Name;
					
					if (!string.IsNullOrWhiteSpace(con.Description))
						textFieldConnectionDescription.StringValue = con.Description;

					if (!string.IsNullOrWhiteSpace(con.URI)) {
						textFieldComputerName.StringValue = con.URI;
						CheckIfIsInBulkAddMode();
					}
				} else if (computerLines.Length > 1) {
					if (this.EditMode == ObjectEditMode.EditMode_New) {
						string hostsJoined = string.Empty;
						
						foreach (string host in computerLines) {
							hostsJoined += host + ";";
						}
						
						if (hostsJoined.EndsWith(";"))
							hostsJoined = hostsJoined.Substring(0, hostsJoined.LastIndexOf(";"));
						
						textFieldComputerName.StringValue = hostsJoined;
						CheckIfIsInBulkAddMode();
					} else {
						RmMessageBox.Show(RmMessageBoxType.WarningMessage,
						                  this.View.Window, 
						                  "Warning".TL(),
						                  "Bulk-add can only be used when adding new connections.".TL(),
						                  "OK".TL());
					}
				}
			}
		}
		
		[ObjectiveCMessage("controlTextDidChange:")]
		public void ControlTextDidChange (NSNotification aNotification)
		{
			if (aNotification.Object.CastTo<NSObject> ().IsKindOfClass (NSTextField.NSTextFieldClass) &&
			    aNotification.Object == textFieldComputerName) {
				CheckIfIsInBulkAddMode();
			}
		}
		
		private bool IsInBulkAddMode {
			get {
				return (this.EditMode == ObjectEditMode.EditMode_New &&
				        ((string)textFieldComputerName.StringValue).Contains (";"));
			}
		}
		
		private void CheckIfIsInBulkAddMode ()
		{
			if (IsInBulkAddMode) {
				textFieldDisplayName.StringValue = NSString.Empty;
				textFieldDisplayName.IsEnabled = false;
			} else {
				textFieldDisplayName.IsEnabled = true;
			}
		}
	}
}