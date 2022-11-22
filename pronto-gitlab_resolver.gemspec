# frozen_string_literal: true

require_relative "lib/pronto/gitlab_resolver/version"

Gem::Specification.new do |spec|
  spec.name = "pronto-gitlab_resolver"
  spec.version = Pronto::GitlabResolver::VERSION
  spec.authors = ["Vasily Fedoseyev"]
  spec.email = ["vasilyfedoseyev@gmail.com"]

  spec.summary = "Pronto gitlab formatter extension that marks resolved comments"
  # spec.description = "TODO: Write a longer description or delete this line."
  spec.homepage = "https://github.com/Vasfed/pronto-gitlab_resolver"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.require_paths = ["lib"]

  spec.add_dependency "pronto", "~> 0.11"
end
