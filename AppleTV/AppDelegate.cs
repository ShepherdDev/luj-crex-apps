using Foundation;
using UIKit;

namespace com.liftupjesus.AppleTV
{
    // The UIApplicationDelegate for the application. This class is responsible for launching the
    // User Interface of the application, as well as listening (and optionally responding) to application events from iOS.
    [Register( "AppDelegate" )]
    public class AppDelegate : UIApplicationDelegate
    {
        public override UIWindow Window { get; set; }

        public override bool FinishedLaunching( UIApplication application, NSDictionary launchOptions )
        {
            Window = new UIWindow( UIScreen.MainScreen.Bounds );

            Crex.tvOS.Application.Current.Run( Window );

            return true;
        }
    }
}
