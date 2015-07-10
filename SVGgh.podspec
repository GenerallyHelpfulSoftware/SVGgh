Pod::Spec.new do |s|

s.name        = 'SVGgh'
s.version     = '1.2.2'
s.license     = 'MIT'
s.platform    = :ios, '7.0'
s.summary     = "SVG Rendering Library for iOS"
s.homepage = 'https://github.com/GenerallyHelpfulSoftware/SVGgh'
s.author   = { 'Glenn R. Howes' => 'glenn@genhelp.com' }
s.source   = { :git => 'https://github.com/GenerallyHelpfulSoftware/SVGgh.git', :tag => "v1.2.2" }

s.ios.source_files = 'SVGgh/**/*{.h,m}'
s.framework = 'CoreGraphics', 'CoreImage', 'CoreText', 'UIKit', 'Foundation'
s.prefix_header_file = 'SVGgh/SVGgh-Prefix.pch'
s.requires_arc = true

end
