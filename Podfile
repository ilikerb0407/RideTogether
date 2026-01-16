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
  
  # Fix gRPC-Core template syntax error for Xcode 16+
  basic_seq_file = File.join(installer.sandbox.root, 'gRPC-Core/src/core/lib/promise/detail/basic_seq.h')
  if File.exist?(basic_seq_file)
    text = File.read(basic_seq_file)
    new_text = text.gsub(/Traits::template CallSeqFactory\(/, 'Traits::CallSeqFactory(')
    if text != new_text
      File.open(basic_seq_file, 'w') { |file| file.puts new_text }
      puts "✅ Fixed gRPC-Core template syntax error in basic_seq.h"
    end
  end
end