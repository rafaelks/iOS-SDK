load "specs/Rakefile"

desc "Run specs and generate documentation"
task :default => [ :specs, "docs:generate" ]

namespace :docs do
  desc "Generate documentation"
  task :generate do
    success = system(<<CMD)
      appledoc --project-name "SharethroughSDK" \
               --project-company "Sharethrough" \
               --output "/tmp/doc_output" \
               --ignore "*.m" \
               --company-id "com.sharethrough" \
               --no-repeat-first-par \
               --use-code-order SharethroughSDK && \
      mkdir -p built-framework &&
      cp -r ~/Library/Developer/Shared/Documentation/DocSets/com.sharethrough.SharethroughSDK.docset built-framework/
CMD

    raise "generating docs failed" unless success
  end

  desc "Copy html docset to Sharethrough corporate website"
  task :copy_to_website do
    success = system("git clone git@github.com:sharethrough/website.git tmp/website") &&
      copy_to_website("tmp/website") &&
      system("cd tmp/website && git add -A && (git diff --cached --quiet || (git commit -am'Update iOS SDK documentation' && git push origin master))")

    raise "copying docs to website failed" unless success
  end

  desc "Copy docs to local website (assumes website is neighbor of SDK)"
  task :copy_to_local_website do
    raise "copying docs to local website failed" unless copy_to_website("../website")
  end

  def copy_to_website(website_path)
    website_docset_path = "#{website_path}/publishers/sdk/iOS"
    website_sdk_path = "#{website_path}/publishers/sdk/documentation/"
    website_includes_path = "#{website_path}/_includes"
    success = system("rm -rf #{website_docset_path}") &&
      system("cp -r documentation/ #{website_sdk_path}") &&
      system("cp readme.md #{website_includes_path}") &&
      system("cp -r built-framework/com.sharethrough.SharethroughSDK.docset/Contents/Resources/Documents #{website_docset_path}")

    success
  end
end
