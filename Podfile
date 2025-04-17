# Suppress warning about the master specs repo
install! 'cocoapods', :warn_for_unused_master_specs_repo => false

platform :ios, '13.0'

def firebase_pods
  pod 'Firebase/Core'
  pod 'FirebaseStorage'
  pod 'FirebaseFirestore'
  pod 'FirebaseFirestoreSwift'
  pod 'FirebaseCrashlytics'
  pod 'FirebaseAuth'
end

def ui_pods
  pod 'IQKeyboardManagerSwift'
  pod 'JGProgressHUD'
  pod 'Kingfisher'
  pod 'lottie-ios'
  pod 'MJRefresh'
  pod 'CoreGPX'
  pod 'DGCharts'
  pod 'SnapKit' 
end

def shared_pods
  firebase_pods
  ui_pods
end

target 'RideTogether' do
  use_frameworks!
  
  shared_pods

  target 'RideTogetherTests' do
    inherit! :search_paths
    # Pods for testing
  end
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
      config.build_settings['SWIFT_VERSION'] = '5.0'
      config.build_settings['ENABLE_BITCODE'] = 'NO'
      
      # 添加以下設置以解決並發相關問題
      config.build_settings['SWIFT_STRICT_CONCURRENCY'] = 'complete'
      config.build_settings['SWIFT_ACTIVE_COMPILATION_CONDITIONS'] = '$(inherited) SWIFT_STRICT_CONCURRENCY=complete'
    end
    
    if target.name == 'BoringSSL-GRPC'
      target.source_build_phase.files.each do |file|
        if file.settings && file.settings['COMPILER_FLAGS']
          flags = file.settings['COMPILER_FLAGS'].split
          flags.reject! { |flag| flag == '-GCC_WARN_INHIBIT_ALL_WARNINGS' }
          file.settings['COMPILER_FLAGS'] = flags.join(' ')
        end
      end
    end
  end
end