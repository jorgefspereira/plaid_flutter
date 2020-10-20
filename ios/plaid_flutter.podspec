#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'plaid_flutter'
  s.version          = '0.0.1'
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
  s.dependency 'Plaid', '1.1.37'
  s.ios.deployment_target = '8.0'
  # s.script_phase = { :name => 'Prepare Plaid for Distribution', :script => 'LINK_ROOT=${PODS_ROOT:+$PODS_ROOT/Plaid/ios};cp "${LINK_ROOT:-$PROJECT_DIR}"/LinkKit.framework/prepare_for_distribution.sh "${CODESIGNING_FOLDER_PATH}"/Frameworks/LinkKit.framework/prepare_for_distribution.sh;"${CODESIGNING_FOLDER_PATH}"/Frameworks/LinkKit.framework/prepare_for_distribution.sh', :shell_path => '/bin/sh' }
end

