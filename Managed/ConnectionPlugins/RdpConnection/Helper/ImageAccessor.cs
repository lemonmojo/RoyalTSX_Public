using Monobjc.AppKit;
using remojoApi;

namespace remojoConnectionTypes.Rdp
{
	public static class ImageAccessor
	{
		private static ImageStore m_store;
		private static ImageStore Store { 
			get {
				if (m_store == null)
					m_store = new ImageStore(typeof(ImageAccessor), "remojoConnectionTypes.Rdp.Resources", "");
				
				return m_store;
			}
		}

		public static RmIcon GetIcon(string name)
		{
			return Store.IconFromResource("Icons." + name);
		}
		
		public static NSImage GetImage(string name)
		{
			return Store.ImageFromResources(name);
		}
	}
}

