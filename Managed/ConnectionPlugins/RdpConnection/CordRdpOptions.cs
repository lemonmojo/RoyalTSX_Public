using System;
using Monobjc;
using Monobjc.AppKit;
using Monobjc.Foundation;

namespace remojoConnectionTypes.Rdp
{
	[ObjectiveCClass]
	public partial class CordRdpOptions : NSObject
	{
		public static readonly Class CordRdpOptionsClass = Class.Get(typeof(CordRdpOptions));
		public CordRdpOptions() { }
		public CordRdpOptions(IntPtr nativePointer) : base(nativePointer) { }
		
		[ObjectiveCMessage("init")]
		public override Id Init()
		{
			this.SendMessageSuper<IntPtr>(CordRdpOptionsClass, "init");
			
			this.Hostname = @"";
		    this.Port = 0;
		    this.ScreenWidth = 0;
		    this.ScreenHeight = 0;
		    this.Username = @"";
		    this.Domain = @"";
		    this.Password = @"";
		    this.ConnectToConsole = false;
		    this.SmartSize = false;
		    this.ColorDepth = 16;
		    this.AllowWallpaper = true;
		    this.AllowAnimations = true;
		    this.FontSmoothing = true;
		    this.ShowWindowContentsWhileDragging = true;
		    this.ShowThemes = true;
		    this.RedirectPrinters = true;
		    this.RedirectDiskDrives = true;
		    this.AudioRedirectionMode = 0;
			
			return this;
		}
		
		#region Properties
		public NSString Hostname {
			[ObjectiveCMessage("hostname")]
			get;
			[ObjectiveCMessage("setHostname")]
			set;
		}
		
		public int Port { 
			[ObjectiveCMessage("port")]
			get;
			[ObjectiveCMessage("setPort")]
			set; 
		}
		
	    public int ScreenWidth { 
			[ObjectiveCMessage("screenWidth")]
			get; 
			[ObjectiveCMessage("setScreenWidth")]
			set; 
		}
		
		public int ScreenHeight { 
			[ObjectiveCMessage("screenHeight")]
			get; 
			[ObjectiveCMessage("setScreenHeight")]
			set; 
		}
		
	    public NSString Username { 
			[ObjectiveCMessage("username")]
			get; 
			[ObjectiveCMessage("setUsername")]
			set; 
		}
		
	    public NSString Domain { 
			[ObjectiveCMessage("domain")]
			get; 
			[ObjectiveCMessage("setDomain")]
			set; 
		}
		
	    public NSString Password { 
			[ObjectiveCMessage("password")]
			get; 
			[ObjectiveCMessage("setPassword")]
			set; 
		}
		
	    public bool ConnectToConsole { 
			[ObjectiveCMessage("connectToConsole")]
			get; 
			[ObjectiveCMessage("setConnectToConsole")]
			set; 
		}
		
	    public bool SmartSize { 
			[ObjectiveCMessage("smartSize")]
			get; 
			[ObjectiveCMessage("setSmartSize")]
			set; 
		}
		
	    public int ColorDepth { 
			[ObjectiveCMessage("colorDepth")]
			get; 
			[ObjectiveCMessage("setColorDepth")]
			set; 
		}
		
		public bool AllowWallpaper { 
			[ObjectiveCMessage("allowWallpaper")]
			get; 
			[ObjectiveCMessage("setAllowWallpaper")]
			set; 
		}
		
		public bool AllowAnimations { 
			[ObjectiveCMessage("allowAnimations")]
			get; 
			[ObjectiveCMessage("setAllowAnimations")]
			set; 
		}
		
		public bool FontSmoothing { 
			[ObjectiveCMessage("fontSmoothing")]
			get; 
			[ObjectiveCMessage("setFontSmoothing")]
			set; 
		}
		
		public bool ShowWindowContentsWhileDragging { 
			[ObjectiveCMessage("showWindowContentsWhileDragging")]
			get; 
			[ObjectiveCMessage("setShowWindowContentsWhileDragging")]
			set; 
		}
		
		public bool ShowThemes { 
			[ObjectiveCMessage("showThemes")]
			get; 
			[ObjectiveCMessage("setShowThemes")]
			set; 
		}
		
		public bool RedirectPrinters { 
			[ObjectiveCMessage("redirectPrinters")]
			get; 
			[ObjectiveCMessage("setRedirectPrinters")]
			set; 
		}
		
		public bool RedirectDiskDrives { 
			[ObjectiveCMessage("redirectDiskDrives")]
			get; 
			[ObjectiveCMessage("setRedirectDiskDrives")]
			set; 
		}
		
		public int AudioRedirectionMode { 
			[ObjectiveCMessage("audioRedirectionMode")]
			get; 
			[ObjectiveCMessage("setAudioRedirectionMode")]
			set; 
		}
		#endregion
		
		[ObjectiveCMessage("dealloc")]
		public override void Dealloc()
		{	
			this.SendMessageSuper(CordRdpOptionsClass, "dealloc");
		}
	}
}
