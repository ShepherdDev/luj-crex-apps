using Android.App;
using Android.Content;
using Android.OS;

namespace com.liftupjesus.FireTV
{
    [Activity( Label = "@string/app_name", MainLauncher = true )]
    [IntentFilter( new[] { Intent.ActionMain }, Categories = new[] { Intent.CategoryLeanbackLauncher } )]
    public class LaunchActivity : Activity
    {
        protected override void OnCreate( Bundle savedInstanceState )
        {
            base.OnCreate( savedInstanceState );

            Crex.Android.Application.Current.Run( this );
        }
    }
}
