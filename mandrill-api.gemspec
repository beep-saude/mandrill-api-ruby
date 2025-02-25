Gem::Specification.new do |s|
    s.name = 'mandrill-api'
    s.version = '1.1.6'
    s.summary = 'A Ruby API library for the Mandrill email as a service platform.'
    s.description = s.summary
    s.authors = ['Mandrill Devs', 'Renan Medina']
    s.email = 'community@mandrill.com'
    s.files = ['lib/mandrill.rb', 'lib/mandrill/api.rb', 'lib/mandrill/errors.rb', 'lib/mandrill/templates_deployer.rb']
    s.homepage = 'https://github.com/beep-saude/mandrill-api-ruby'
    s.add_dependency 'json', '>= 1.7.7'
    s.add_dependency 'excon'
end
