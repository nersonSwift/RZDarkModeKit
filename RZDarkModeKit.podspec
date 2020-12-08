
Pod::Spec.new do |spec|

  spec.name         = "RZDarkModeKit"
  spec.version      = "1.0"
  spec.summary      = "Small example to test code sharing."
  spec.description  = "Small example to test code sharing via cocoapods."	
  
  spec.homepage     = "https://github.com/nersonSwift/RZDarkModeKit"

  spec.license      = "MIT"
  

 

  spec.author       = { "Angel-senpai" => "daniil.murygin68@gmail.com", "nersonSwift" => "aleksandrsenin@icloud.com" }
 
  spec.source       = { :git => "https://github.com/nersonSwift/RZDarkModeKit.git", :tag => "1.0" }

  spec.exclude_files = "RZDarkModeKit/**/*.plist"
  spec.swift_version = '5.3'
  spec.ios.deployment_target  = '13.0'

  spec.requires_arc = true

  spec.default_subspec = 'Core'

  spec.subspec 'Core' do |core|
    core.source_files   = 'RZDarkModeKit/**/*'
  end

end