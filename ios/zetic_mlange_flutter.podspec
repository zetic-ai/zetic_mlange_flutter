#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint zetic_mlange_flutter.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'zetic_mlange_flutter'
  s.version          = '1.2.0'
  s.summary          = 'A new Flutter plugin project.'
  s.description      = <<-DESC
A new Flutter plugin project.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'

  framework_name = "ZeticMLange"
  repo_path = "zetic-ai/ZeticMLangeiOS"
  framework_dir = "ios/Frameworks"

  s.prepare_command = <<-CMD
  set -e  # Exit on any error
  
  # Variables
  FRAMEWORK_NAME="#{framework_name}"
  REPO="#{repo_path}"
  VERSION="#{s.version}"
  FRAMEWORK_DIR="#{framework_dir}"
  DOWNLOAD_URL="https://github.com/${REPO}/releases/download/${VERSION}/${FRAMEWORK_NAME}.xcframework.zip"
  FRAMEWORK_PATH="${FRAMEWORK_DIR}/${FRAMEWORK_NAME}.xcframework"

  echo "📦 Installing ${FRAMEWORK_NAME} v${VERSION}..."

  # Clean setup
  rm -rf "${FRAMEWORK_PATH}" "${FRAMEWORK_DIR}/${FRAMEWORK_NAME}.xcframework.zip"
  mkdir -p "${FRAMEWORK_DIR}"

  # Download and extract
  echo "⬇️  Downloading from: ${DOWNLOAD_URL}"
  curl -fL "${DOWNLOAD_URL}" -o "${FRAMEWORK_DIR}/${FRAMEWORK_NAME}.xcframework.zip"
  unzip -q "${FRAMEWORK_DIR}/${FRAMEWORK_NAME}.xcframework.zip" -d "${FRAMEWORK_DIR}/"
  rm "${FRAMEWORK_DIR}/${FRAMEWORK_NAME}.xcframework.zip"
  
  # Verify
  if [ -d "${FRAMEWORK_PATH}" ]; then
    echo "✅ Framework installed successfully at: ${FRAMEWORK_PATH}"
  else
    echo "❌ Installation failed: Framework not found at ${FRAMEWORK_PATH}"
    exit 1
  fi
  CMD
  s.vendored_frameworks = 'Frameworks/ZeticMLange.xcframework'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
  s.frameworks = 'Accelerate' 
  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'zetic_mlange_flutter_privacy' => ['Resources/PrivacyInfo.xcprivacy']}
end
