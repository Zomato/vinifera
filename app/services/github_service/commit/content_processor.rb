module GithubService
  module Commit
    class ContentProcessor
      def initialize
        @github = Github.new
      end

      def process(commit_url)
        commit_data = @github.get(commit_url)
        return unless commit_data.files
        commit_data.files.each_with_object([]) do |file,result|
          result << process_patch(file.patch) if file.patch.present?
        end
      end

      private

      def process_patch(patch)
        Tempfile.create(SecureRandom.hex) do |temp_file|
          temp_file.write(patch)
          temp_file.flush
          CodeScanner.new.scan_file(temp_file.path)
        end
      end
    end
  end
end