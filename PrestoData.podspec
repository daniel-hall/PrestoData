Pod::Spec.new do |s|
  s.name         = 'PrestoData'
  s.version      = '0.2.0'
  s.summary      = 'A utility for parsing, searching and modifying JSON and XML data'
  s.homepage     = 'https://github.com/daniel-hall/PrestoData'

  s.license          = 'MIT'
  
  s.author           = { "Dan Hall" => "dan@danhall.io" }
  s.source           = { :git => "https://github.com/daniel-hall/PrestoData.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/_danielhall'

  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.source_files = 'PrestoData/*.{h,m}'
  s.public_header_files = 'PrestoData/PrestoData.h', 'PrestoData/NSArray+PrestoData.h', 'PrestoData/NSMutableDictionary+PrestoData.h'
  s.frameworks = 'Foundation'
end

