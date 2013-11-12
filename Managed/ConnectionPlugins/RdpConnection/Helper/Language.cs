using System;
using Monobjc.Foundation;
using remojoApi;

namespace remojoConnectionTypes.Rdp
{
	public static class Language
	{
		public static string Get(string text)
		{
			return FoundationFramework.NSLocalizedStringFromTableInBundle(text, "Localizable", ApiUtils.GetPluginBundleByType(typeof(Language)), string.Empty);
		}
		
		public static string GetFormat(string text, params object[] args)
		{
			return string.Format(Get(text), args);
		}
	}
}