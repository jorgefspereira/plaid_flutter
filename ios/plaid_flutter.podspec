#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'plaid_flutter'
  s.version          = '5.1.1'
  s.summary          = 'Plaid Link plugin for Flutter'
  s.description      = <<-DESC
Enables Plaid in Flutter apps.
                       DESC
  s.homepage         = 'http://github.com/jorgefspereira'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Jorge Pereira' => 'jorgefspereira@icloud.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  s.dependency 'Plaid', '6.4.3'
  s.static_framework = true
  s.ios.deployment_target = '14.0'
end

