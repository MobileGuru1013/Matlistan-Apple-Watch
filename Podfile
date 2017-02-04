platform:ios,'8.0'
def required_pods
    pod 'AFNetworking','~>2.6.3'
    pod 'FBSDKShareKit', '~>4.10.0'
    pod 'FBSDKLoginKit', '~>4.10.0'
    pod 'FBSDKCoreKit', '~>4.10.0'
    pod 'Google-Mobile-Ads-SDK', '~>7.6.0'
    pod 'Fabric', '~>1.6.6'
    pod 'Crashlytics', '~>3.7.0'
    pod 'MBProgressHUD', '~>0.9.2'
    pod 'Mixpanel', '~>2.9.3'
    pod 'MGSwipeTableCell', '~> 1.5.3'
    pod 'Google/SignIn'
    pod 'MagicalRecord', '~> 2.3.2'
    pod 'ZXingObjC', '~> 3.1.0'
    pod 'CustomIOSAlertView', '~> 0.9.3'
    pod 'SpeechKit', '~> 1.0.1'
end

target 'MatListan' do
    required_pods
end

target 'MatListanTests' do
    required_pods
end

target 'MatListanUITests' do
    required_pods
end

target 'MatlistanShare' do
    pod 'AFNetworking','~>2.6.3'
end

post_install do |installer_representation|
    installer_representation.pods_project.targets.each do |target|
        if target.name == 'Mixpanel'
            target.build_configurations.each do |config|
                    puts "  Mixpanel #{config.name} before: #{config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'].inspect}"
                    config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= ['$(inherited)']
                    config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] << 'DISABLE_MIXPANEL_AB_DESIGNER=1'
                    puts "  Mixpanel #{config.name} after:  #{config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'].inspect}"
            end
        end
    end
end
