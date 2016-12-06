
platform :ios, '9.0'
use_frameworks!

def pods
    pod 'FayeClient'
    pod 'AsyncDisplayKit'
    pod 'Appsee'
    pod 'DeviceUtil'
    pod 'FXBlurView'
    pod 'TPKeyboardAvoiding'
    pod 'pop'
    pod 'JPush', '~> 2.1.9'
    pod 'Fabric'
    pod ‘LeanCloud’
end

target 'Positano' do
    swift_version = '3.0'

    pods

    target 'PositanoTests' do
        inherit! :search_paths
    end
end

