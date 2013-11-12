using System;
using System.Collections.Generic;
using Monobjc;
using remojoApi;
using RoyalDocumentLibrary;

namespace remojoConnectionTypes.Rdp
{
	public class RdpPropertyPages : ConnectionPropertyPageCollection
	{
		public RdpPropertyPages()
		{
			this.Name = Language.Get("Remote Desktop Connection Settings");
			this.Icon = ImageAccessor.GetIcon("RDPConnection.png");
			this.TemplateIcon = ImageAccessor.GetIcon("TemplateRDS.png");
			this.HandledObjectType = typeof(RoyalRDSConnection);
			this.SupportsConnectionCredentials = true;
			this.SupportsWindowMode = true;
			
			// Remote Desktop
			SourceListItem itemRdpCat = new SourceListItem(RoyalRDSConnection.ObjectTypeShortName.TL());
			itemRdpCat.IsCategory = true;
			
			IPropertyPage propPageRdpMain = new PropertyPageRdpMainController().InitPropertyPage() as IPropertyPage;
			itemRdpCat.MutableChildNodes.AddObject(propPageRdpMain.ListItem);
			
			this.ConnectionCredentialsListParent = itemRdpCat;
			this.WindowModeParent = itemRdpCat;
			
			// Advanced
			SourceListItem itemRdpAdvCat = new SourceListItem(Language.Get("Advanced"));
			itemRdpAdvCat.IsCategory = true;
			
			IPropertyPage propPageRdpAdvMain = new PropertyPageRdpAdvancedMainController().InitPropertyPage() as IPropertyPage;
			IPropertyPage propPageRdpAdvDisplay = new PropertyPageRdpAdvancedDisplayController().InitPropertyPage() as IPropertyPage;
			IPropertyPage propPageRdpAdvPerformance = new PropertyPageRdpAdvancedPerformanceController().InitPropertyPage() as IPropertyPage;
			IPropertyPage propPageRdpAdvRedirection = new PropertyPageRdpAdvancedRedirectionController().InitPropertyPage() as IPropertyPage;
			//SourceListItem itemRdpAdvKeyboard = new SourceListItem("Keyboard", ImageAccessor.GetIcon("Keyboard.png").Icon16); */
			itemRdpAdvCat.MutableChildNodes.AddObject(propPageRdpAdvMain.ListItem);
			itemRdpAdvCat.MutableChildNodes.AddObject(propPageRdpAdvDisplay.ListItem);
			itemRdpAdvCat.MutableChildNodes.AddObject(propPageRdpAdvPerformance.ListItem);
			itemRdpAdvCat.MutableChildNodes.AddObject(propPageRdpAdvRedirection.ListItem);
			//itemRdpAdvCat.MutableChildNodes.AddObject(itemRdpAdvKeyboard); */
			
			// Set Properties
			this.DefaultItem = propPageRdpMain.ListItem;
			
			this.PropertyPages.Add(propPageRdpMain);
			this.PropertyPages.Add(propPageRdpAdvMain);
			this.PropertyPages.Add(propPageRdpAdvDisplay);
			this.PropertyPages.Add(propPageRdpAdvPerformance);
			this.PropertyPages.Add(propPageRdpAdvRedirection);
			
			this.ListItems.Add(itemRdpCat);
			this.ListItems.Add(itemRdpAdvCat);
		}
	}
}