#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint zetic_mlange_flutter.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'zetic_mlange_flutter'
  s.version          = '0.0.1'
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

  s.prepare_command = <<-CMD
  FRAMEWORK_NAME="ZeticMLange"
  GITHUB_REPO="zetic-ai/ZeticMLangeiOS"
  GITHUB_RELEASE_TAG="1.1.0"
  DOWNLOAD_URL="https://github.com/${GITHUB_REPO}/releases/download/${GITHUB_RELEASE_TAG}/${FRAMEWORK_NAME}.xcframework.zip"
  FRAMEWORK_DIR="ios/Frameworks"
  FRAMEWORK_PATH="${FRAMEWORK_DIR}/${FRAMEWORK_NAME}.xcframework"

  # Create log file
  LOG_FILE="zeticmlange_installation.log"
  if [ -d ${LOG_FILE} ]; then
    rm ${LOG_FILE}
  fi

  echo "$(date): === Starting Zetic framework installation ==="

  # Ensure we have a clean directory - remove existing framework if present
  if [ -d "${FRAMEWORK_PATH}" ]; then
    echo "Removing existing framework at: ${FRAMEWORK_PATH}" | tee -a ${LOG_FILE}
    rm -rf "${FRAMEWORK_PATH}"
  fi

  # Create directory for the framework
  mkdir -p ${FRAMEWORK_DIR}

  echo "=== Installing Zetic framework from GitHub ===" | tee -a ${LOG_FILE}
  echo "Downloading from: ${DOWNLOAD_URL}" | tee -a ${LOG_FILE}

  # Download the XCFramework
  curl -L ${DOWNLOAD_URL} -o ${FRAMEWORK_DIR}/${FRAMEWORK_NAME}.xcframework.zip 2>&1 | tee -a ${LOG_FILE}

  if [ $? -ne 0 ]; then
    echo "❌ Error: Failed to download XCFramework" | tee -a ${LOG_FILE}
    exit 1
  fi

  # Unzip the Zetic framework with overwrite flag
  unzip -o ${FRAMEWORK_DIR}/${FRAMEWORK_NAME}.xcframework.zip -d ${FRAMEWORK_DIR}/ 2>&1 | tee -a ${LOG_FILE}

  if [ $? -ne 0 ]; then
    echo "❌ Error: Failed to unzip XCFramework" | tee -a ${LOG_FILE}
    exit 1
  fi

  # Clean up the zip file
  rm ${FRAMEWORK_DIR}/${FRAMEWORK_NAME}.xcframework.zip

  # Verify installation
  if [ -d "${FRAMEWORK_PATH}" ]; then
    echo "✅ XCFramework successfully installed at: ${FRAMEWORK_PATH}"
    rm ${LOG_FILE}
  else
    echo "❌ Error: Zetic framework installation failed. Path does not exist: ${FRAMEWORK_PATH}" | tee -a ${LOG_FILE}
    exit 1
  fi

  echo ""
  echo "========================================================================"
  echo "🔍 Zetic framework installation details in: ${LOG_FILE}"
  echo "========================================================================"
  echo ""
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
