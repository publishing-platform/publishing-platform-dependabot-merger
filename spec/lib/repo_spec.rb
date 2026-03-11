require_relative "../../lib/repo"

RSpec.describe Repo do
  before { set_up_mock_token }

  let(:repo_name) { "foo" }
  let(:external_config_file_api_url) { "https://api.github.com/repos/publishing-platform/#{repo_name}/contents/.publishing_platform_dependabot_merger.yml" }
  let(:arbitrary_config) do
    <<~EXTERNAL_CONFIG_YAML
      foo: bar
    EXTERNAL_CONFIG_YAML
  end

  describe ".all" do
    it "should return an array of Repo objects" do
      repos = Repo.all(File.join(File.dirname(__FILE__), "../config/test_repos_opted_in.yml"))
      expect(repos).to all be_a_kind_of(Repo)
      expect(repos.count).to eq(2)
    end
  end

  describe "#publishing_platform_dependabot_merger_config" do
    it "should return the Dependabot Merger config for the repo" do
      stub_request(:get, external_config_file_api_url)
        .to_return(status: 200, body: arbitrary_config.to_json, headers: { "Content-Type": "application/json" })

      repo = Repo.new(repo_name)
      expect(repo.publishing_platform_dependabot_merger_config).to eq({
        "foo" => "bar",
      })
    end

    it "should return an error hash if the YAML is malformed" do
      config = <<~EXTERNAL_CONFIG_YAML
        foo:
          - baz
        - bam
        # note that the above is outdented too far
      EXTERNAL_CONFIG_YAML
      stub_request(:get, external_config_file_api_url)
        .to_return(status: 200, body: config.to_json, headers: { "Content-Type": "application/json" })

      repo = Repo.new(repo_name)
      expect(repo.publishing_platform_dependabot_merger_config).to eq({
        "error" => "syntax",
      })
    end

    it "should return an error hash if the config file is missing" do
      stub_request(:get, external_config_file_api_url)
        .to_return(status: 404)

      repo = Repo.new(repo_name)
      expect(repo.publishing_platform_dependabot_merger_config).to eq({
        "error" => "404",
      })
    end
  end

  describe "#dependabot_pull_requests" do
    it "should return an array of PullRequest objects" do
      stub_request(:get, external_config_file_api_url)
        .to_return(status: 200, body: arbitrary_config.to_json, headers: { "Content-Type": "application/json" })
      stub_request(:get, "https://api.github.com/repos/publishing-platform/#{repo_name}/pulls?sort=created&state=open")
        .to_return(status: 200, body: [pull_request_api_response, pull_request_api_response].to_json, headers: { "Content-Type": "application/json" })

      repo = Repo.new(repo_name)
      expect(repo.dependabot_pull_requests).to all be_a_kind_of(PullRequest)
      expect(repo.dependabot_pull_requests.count).to eq(2)
    end

    it "should filter out any PRs not raised by Dependabot" do
      stub_request(:get, external_config_file_api_url)
        .to_return(status: 200, body: arbitrary_config.to_json, headers: { "Content-Type": "application/json" })
      non_dependabot_response = pull_request_api_response({ user: { login: "foo" } })

      stub_request(:get, "https://api.github.com/repos/publishing-platform/#{repo_name}/pulls?sort=created&state=open")
        .to_return(status: 200, body: [non_dependabot_response, pull_request_api_response].to_json, headers: { "Content-Type": "application/json" })

      repo = Repo.new(repo_name)
      expect(repo.dependabot_pull_requests).to all be_a_kind_of(PullRequest)
      expect(repo.dependabot_pull_requests.count).to eq(1)
    end
  end
end

def pull_request_api_response(overrides = {})
  defaults = {
    number: 4081,
    state: "open",
    locked: false,
    title: "Bump publishing_platform_publishing_components from 35.7.0 to 35.8.0",
    user: {
      login: "dependabot[bot]",
      type: "Bot",
      site_admin: false,
    },
    body: "PR body goes here",
    # created_at: 2023-06-26 21:57:29 UTC,
    # updated_at: 2023-06-26 21:57:31 UTC,
    # closed_at: nil,
    # merged_at: nil,
    merge_commit_sha: "56b4f856f745c54e5c2855dfd08f376515b2cbf0",
    labels: [
      {
        id: 889_997_717,
        node_id: "MDU6TGFiZWw4ODk5OTc3MTc=",
        url: "https://api.github.com/repos/publishing-platform/content-publisher/labels/dependencies",
        name: "dependencies",
        color: "0025ff",
        default: false,
        description: nil,
      },
    ],
    milestone: nil,
    draft: false,
    commits_url: "https://api.github.com/repos/publishing-platform/content-publisher/pulls/4081/commits",
    statuses_url: "https://api.github.com/repos/publishing-platform/content-publisher/statuses/545432226f4f1c30818123213cc37606d9f8b037",
    head: {
      label: "publishing-platform:dependabot/bundler/publishing_platform_publishing_components-35.8.0",
      ref: "dependabot/bundler/publishing_platform_publishing_components-35.8.0",
      sha: "545432226f4f1c30818123213cc37606d9f8b037",
      repo: {
        name: "content-publisher",
        full_name: "publishing-platform/content-publisher",
        private: true,
      },
    },
  }
  defaults.merge(overrides)
end
