Pod::Spec.new do |s|
  s.name                  = "TSMessages"
  s.version               = "1.0"
  s.summary               = "Easy to use and customizable messages for iOS à la Tweetbot."
  s.license               = { :type => 'MIT', :file => 'LICENSE' }
  s.homepage              = "https://github.com/Shayanzadeh/TSMessages/"
  s.author                = { "Felix Krause" => "krausefx@gmail.com" }
  s.source                = { :git => "https://github.com/shayanzadeh/TSMessages.git", :branch => "jailbreak"}
  s.source_files          = 'TSMessages/*.{h,m}'
  s.public_header_files   = 'TSMessages/*.h'
  s.resources             = 'TSMessages/Resources/*.{png,json}'
  s.platform              = :ios
  s.requires_arc          = true
  s.ios.deployment_target = '5.0'
end
