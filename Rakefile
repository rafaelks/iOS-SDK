load "specs/Rakefile"

desc "Run specs and generate documentation"
task :default => [ :specs, :docs ]

desc "Generate documentation"
task :docs do
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
