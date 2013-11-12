using System;
using System.Runtime.InteropServices;
using System.Reflection;
using System.ComponentModel;
using System.Collections.Generic;
using Monobjc;
using Monobjc.AppKit;
using Monobjc.Foundation;
using remojoApi;
using RoyalDocumentLibrary;

namespace remojoConnectionTypes.Rdp
{
	[ObjectiveCClass]
	public class RdpConnection : BaseConnectionType
	{
		#region Constants
		private enum RDConnectionError {
			ConnectionErrorNone = 0,
			ConnectionErrorTimeOut = 1,
			ConnectionErrorHostResolution = 2,
			ConnectionErrorGeneral = 3,
			ConnectionErrorCanceled = 4
		}
		
		private string[] m_errorDescriptions = new string[] {
			Language.Get("No error"),
			Language.Get("The connection timed out."),
			Language.Get("The host name could not be resolved."),
			Language.Get("There was an error connecting."),
			Language.Get("You canceled the connection.")
		};
		#endregion
		
		#region Private Variables
		private IntPtr m_nativeFrameworkHandle;
		private NSObject m_nativeController;

		private int m_screenWidth;
		private int m_screenHeight;
		#endregion

		#region Public Variables
		public override NSArray ConnectWithOptionsMenuItems {
			get {
				NSMutableArray items = NSMutableArray.Array;
				
				NSMenuItem consoleMenuItem = new NSMenuItem(Language.Get ("Console/Admin Session"), IntPtr.Zero, string.Empty).Autorelease<NSMenuItem> ();
				consoleMenuItem.RepresentedObject = "ConnectToAdministerOrConsole".NS();
				consoleMenuItem.State = NSCellStateValue.NSOnState;
				
				items.AddObject(consoleMenuItem);
				
				return items;
			}
		}

		public override bool SupportsBulkAdd {
			get {
				return true;
			}
		}

		public override NSSize ContentSize {
			get {
				if ((this.ConnectionStatus == RtsConnectionStatus.rtsConnectionConnected || 
				     this.ConnectionStatus == RtsConnectionStatus.rtsConnectionDisconnecting) &&
				    this.SessionView != null) {
					return new NSSize(m_screenWidth, m_screenHeight);
				}
				
				return base.ContentSize;
			}
		}
		#endregion
		
		#region Events
		public override event ConnectionStatusChangedHandler ConnectionStatusChanged;
		public override event EventHandler<ContentSizeChangedEventArgs> ContentSizeChanged;
		#endregion
		
		#region Native Methods
		public delegate IntPtr NativeGetRdpViewController(IntPtr parentController, IntPtr mainWindow);
		#endregion
		
		#region ObjC Initialization Stuff
		public static readonly Class RdpConnectionClass = Class.Get(typeof(RdpConnection));
		public RdpConnection() { }
		public RdpConnection(IntPtr nativePointer) : base(nativePointer) { }
		
		public override void InitBasic()
		{
			this.ConnectionIcons.DefaultIcon = ImageAccessor.GetIcon("RDPConnection.png");
			this.ConnectionIcons.InactiveIcon = ImageAccessor.GetIcon("RDPInactive.png");
			this.ConnectionIcons.IntermediateIcon = ImageAccessor.GetIcon("RDPProgress.png");
			this.ConnectionIcons.ActiveIcon = ImageAccessor.GetIcon("RDPActive.png");
			this.ConnectionIcons.TemplateIcon = ImageAccessor.GetIcon("TemplateRDS.png");
		}
		
		[ObjectiveCMessage("dealloc")]
		public override void Dealloc()
		{
			//ApiUtils.UnloadFramework(m_nativeFrameworkHandle);
			if (m_nativeController != null)
				m_nativeController.Release();
			
			if (this.SessionView != null)
				this.SessionView.Release();
			
			this.SendMessageSuper(RdpConnectionClass, "dealloc");
		}
		#endregion
		
		#region ObjC Constructor
		public override Id InitConnectionType(RoyalConnection data, NSTabViewItem tabViewItem, NSWindow parentWindow)
		{
			Id ret = base.InitConnectionType(data, tabViewItem, parentWindow);
			
			m_nativeFrameworkHandle = ApiUtils.LoadPluginFramework(typeof(RdpConnection), "RdpView");
			IntPtr funcSymbol = ApiUtils.GetSymbolFromHandle(m_nativeFrameworkHandle, "getRdpViewController");
			
			NativeGetRdpViewController GetRdpViewController = (NativeGetRdpViewController)ApiUtils.GetDelegateFunctionFromFramework<NativeGetRdpViewController>(funcSymbol);
			m_nativeController = ObjectiveCRuntime.GetInstance<NSObject>(GetRdpViewController(this.NativePointer, parentWindow.NativePointer));
			
			return ret;
		}
		#endregion
		
		#region Connection Handling
		public override void Connect()
		{
			string sel = "connectWithOptions:";
			
			RoyalRDSConnection rdpData = Data as RoyalRDSConnection;

			rdpData.BeginTemporaryMode();
			bool autologon = rdpData.CredentialAutologon;
			
			NSString hostname = rdpData.URI.ResolveTokensApi(rdpData).NS();
			int port = rdpData.RDPPort;
			rdpData.EndTemporaryMode();

			NSString username = NSString.Empty;
			//NSString domain = NSString.Empty;
			NSString password = NSString.Empty;

			rdpData.BeginTemporaryMode();
			CredentialInfo effectiveCred = rdpData.GetEffectiveCredential();
			rdpData.EndTemporaryMode();

			if (autologon && effectiveCred != null) {
				string usernameStr = effectiveCred.Username;
				string passwordStr = effectiveCred.Password;
				
				username = usernameStr.NS();
				password = passwordStr.NS();
			}

			int screenWidth = 0;
			int screenHeight = 0;
			
			if (rdpData.DesktopWidth == 0 && rdpData.DesktopHeight == 0) {
				screenWidth = (int)TabViewItem.View.CastTo<NSView>().Frame.Width;
				screenHeight = (int)TabViewItem.View.CastTo<NSView>().Frame.Height;
			} else {
				rdpData.BeginTemporaryMode();
				screenWidth = rdpData.DesktopWidth;
				screenHeight = rdpData.DesktopHeight;
				rdpData.EndTemporaryMode();
			}
			
			// TODO: Screen Width should actually be a multitude of 4, not 8, but 8 seems to work just fine with rdesktop
			if (screenWidth % 8 != 0)
				screenWidth = (screenWidth / 8) * 8;

			m_screenWidth = screenWidth;
			m_screenHeight = screenHeight;

			CordRdpOptions options = new CordRdpOptions();

			rdpData.BeginTemporaryMode();
			options.Hostname = hostname;
			options.Port = port;
			options.Username = username;
			//options.Domain = domain;
			options.Password = password;
			options.ConnectToConsole = rdpData.ConnectToAdministerOrConsole;
			options.SmartSize = false; //rdpData.SmartSizing;
			options.ScreenWidth = screenWidth;
			options.ScreenHeight = screenHeight;
			options.ColorDepth = rdpData.ColorDepth;
			options.AllowWallpaper = rdpData.AllowWallpaper;
			options.AllowAnimations = rdpData.AllowMenuAnimations;
			options.FontSmoothing = rdpData.AllowFontSmoothing;
			options.ShowWindowContentsWhileDragging = rdpData.AllowFullWindowDrag;
			options.ShowThemes = rdpData.AllowThemes;
			options.RedirectPrinters = rdpData.RedirectPrinters;
			options.RedirectDiskDrives = rdpData.RedirectDrives;
			options.AudioRedirectionMode = rdpData.AudioRedirectionMode;
			rdpData.EndTemporaryMode();

			if (m_nativeController.RespondsToSelector(sel))
				m_nativeController.SendMessage(sel, options);
			
			options.Release();
		}
		
		public override void Disconnect()
		{
			string sel = "disconnect";
			
			if (m_nativeController.RespondsToSelector(sel))
				m_nativeController.SendMessage(sel);
		}
		
		public override void Focus()
		{
			if (this.SessionView != null)
				this.SessionView.BecomeFirstResponder();
		}
		
		public override NSImage GetScreenshot()
		{
			NSImage img = null;

			try {
				string sel = "getScreenshot";
				
				if (m_nativeController != null && 
				    m_nativeController.RespondsToSelector(sel))
					img = m_nativeController.SendMessage<NSImage>(sel);
			} catch (Exception ex) {
				ApiUtils.Log.Add(new RoyalLogEntry() {
					Severity = RoyalLogEntry.Severities.Debug,
					Action = RoyalLogEntry.ACTION_PLUGIN,
					PluginName = "RDP Plugin (CoRD/rdesktop)",
					PluginID = "a6330510-982c-11e1-a8b0-0800200c9a66",
					Message = "Error while getting screenshot",
					Details = ex.ToString()
				});
			}
			
			string propName = "CurrentScreenshot";
			
			if (this.SupportsProperty(propName)) {
				if (this.GetPropertyValue<NSImage>(propName) != null && img != null) {
					this.GetPropertyValue<NSImage>(propName).Release();
					this.SetPropertyValue(propName, null);
				}
			
				if (img != null)
					this.SetPropertyValue(propName, img.Retain<NSImage>());
			}
			
			return img;
		}
		
		[ObjectiveCMessage("sessionStatusChanged:")]
		public void NativeSessionStatusChanged(ConnectionStatusArguments args)
		{
			this.ConnectionStatus = args.Status;
					
			if (args.ErrorNumber != (int)RDConnectionError.ConnectionErrorNone && 
			    args.ErrorNumber != (int)RDConnectionError.ConnectionErrorCanceled &&
			    (int)args.ErrorNumber > 0 && 
			    (int)args.ErrorNumber < m_errorDescriptions.Length)
			{
				args.ErrorMessage = m_errorDescriptions[(int)args.ErrorNumber];
			}
			
			if (this.ConnectionStatus == RtsConnectionStatus.rtsConnectionConnected) {
				string sel = "sessionView";
				
				if (m_nativeController.RespondsToSelector(sel))
					this.SessionView = m_nativeController.SendMessage<NSView>(sel);
			}/* else if (this.ConnectionStatus == RtsConnectionStatus.rtsConnectionClosed) {
				this.SessionView = null;
			} */
			
			if (this.ConnectionStatusChanged != null)
				this.ConnectionStatusChanged(this, args);

			if (this.ConnectionStatus == RtsConnectionStatus.rtsConnectionConnected &&
			    this.ContentSizeChanged != null)
				this.ContentSizeChanged(this, new ContentSizeChangedEventArgs(this.ContentSize));
		}
		#endregion
	}
}