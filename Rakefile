load "specs/Rakefile"

desc "Run specs and generate documentation"
task :default => [ :specs, "docs:generate" ]

namespace :docs do
  desc "Generate documentation"
  task :generate do
    success = system(<<CMD)
      appledoc --project-name "Sharethrough-SDK" \
               --project-company "Sharethrough" \
               --output "/tmp/doc_output" \
               --ignore "*.m" \
               --company-id "com.sharethrough" \
               --no-repeat-first-par \
               --use-code-order SharethroughSDK && \
      cp -r ~/Library/Developer/Shared/Documentation/DocSets/com.sharethrough.Sharethrough-SDK.docset built-framework/
CMD

    raise "generating docs failed" unless success
  end

  desc "Copy html docset to Sharethrough corporate website"
  task :copy_to_website do
    website_docset_path = "tmp/website/publishers/sdk/iOS"
    website_sdk_path = "tmp/website/publishers/sdk/documentation/"
    website_includes_path = "tmp/website/_includes"
    success = system("git clone git@github.com:sharethrough/website.git tmp/website") &&
      system("rm -rf #{website_docs_path}") &&
      system("cp -r documentation/ #{website_sdk_path}") &&
      system("cp readme.md #{website_includes_path}") &&
      system("cp -r built-framework/com.sharethrough.Sharethrough-SDK.docset/Contents/Resources/Documents #{website_docs_path}") &&
      system("cd tmp/website && git add -A && (git diff --cached --quiet || (git commit -am'Update iOS SDK documentation' && git push origin master))")

    raise "copying docs to website failed" unless success
  end
end
