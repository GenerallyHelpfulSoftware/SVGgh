Pod::Spec.new do |s|

s.name        = 'SVGgh'
s.version     = '1.12.1'
s.license     = 'MIT'
s.tvos.deployment_target = '9.0'
s.ios.deployment_target = '9.0'

s.summary     = "SVG Rendering Library for iOS"
s.homepage = 'https://github.com/GenerallyHelpfulSoftware/SVGgh'
s.author   = { 'Glenn R. Howes' => 'glenn@genhelp.com' }
s.source   = { :git => 'https://github.com/GenerallyHelpfulSoftware/SVGgh.git', :tag => "v1.12.1" }

s.ios.source_files = 'SVGgh/**/*{.h,m}'
s.tvos.source_files = 'SVGgh/**/*{.h,m}'
s.framework = 'CoreGraphics', 'CoreImage', 'CoreText', 'UIKit', 'Foundation', 'CoreServices'
s.libraries    = 'z'
s.prefix_header_file = 'SVGgh/SVGgh-Prefix.pch'
s.requires_arc = true

end
