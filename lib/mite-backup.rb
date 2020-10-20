require "mite-backup/version"
require "multi_json"
require "net/https"
require "uri"
require 'zlib'
require 'yaml'

class MiteBackup
  MAX_CHECKS              = 48
  SLEEP_BEFORE_EACH_CHECK = 5 # seconds
  CONFIG_FILE             = File.expand_path('~/.mite-backup.yml')
  USER_AGENT              = "mite-backup/#{MiteBackup::VERSION}"

  def initialize(options={})
    @options = options
    self.class.clear_config if options["clear_config"]
    @account  = correct_account(options["account"]  || config["account"])
    @email    = options["email"]    || config["email"]
    @password = options["password"] || config["password"]
  end

  def run
    runnable?
    create
    check
    download
  end

  def setup
    (config["account"] = @account) || config.delete("account")
    (config["email"] = @email) || config.delete("email")
    (config["password"] = @password) || config.delete("password")

    if config.size == 0
      self.class.clear_config
    else
      File.open(CONFIG_FILE, "w") do |f|
        f.write(YAML::dump(config))
      end
    end
  end

  def self.clear_config
    File.exist?(CONFIG_FILE) && File.delete(CONFIG_FILE)
  end

  private

    def runnable?
      failed "Please provide your account subdomain with --account [ACCOUNT-SUBDOMAIN]." unless @account
      failed "Please provide your mite.users email with --email [EMAIL]." unless @email
      failed "Please provide your mite.users password with --password [PASSWORD]." unless @password
    end

    def create
      @id = parse_json(perform_request(Net::HTTP::Post.new("/account/backup.json")){ |code|
        "Could not find any account located at #{domain}" if code == "404"
      })["id"]
    end

    def check
      MAX_CHECKS.times do |i|
        sleep(SLEEP_BEFORE_EACH_CHECK)
        @ready = parse_json(perform_request(Net::HTTP::Get.new("/account/backup/#{@id}.json")))["ready"]
        break if @ready
      end
    end

    def download
      if @ready
        content = perform_request(Net::HTTP::Get.new("/account/backup/#{@id}/download.json"))
        content_str = StringIO.new(content)
        gz = if RUBY_VERSION =~ /\A1\.8\./
          Zlib::GzipReader.new(content_str)
        else
          Zlib::GzipReader.new(content_str, :external_encoding => content.encoding)
        end
        puts gz.read
      else
        failed "Backup was not ready for download after #{MAX_CHECKS*SLEEP_BEFORE_EACH_CHECK} seconds. Contact the mite support."
      end
    end

    def perform_request(request)
      request.basic_auth(@email, @password)
      request['User-Agent'] = USER_AGENT
      response = mite.request(request)
      if response.code == "401"
        failed "Could not authenticate with email #{@email.inspect} and provided password. The user needs to be an admin or the owner of the mite.account!"
      elsif !["200", "201"].include?(response.code)
        message = block_given? && yield(response.code)
        failed(message || "mite responded with irregular code #{response.code}")
      end
      response.body
    end

    def parse_json(string)
      MultiJson.decode(string)["backup"]
    end

    def mite
      @mite ||= begin
        mite = Net::HTTP.new(URI.parse(domain).host, 443)
        mite.use_ssl = true
        mite
      end
    end

    def domain
      "https://#{@account}.mite.yo.lk/"
    end

    def failed(reason)
      $stderr.puts "Failed: #{reason}"
      exit(1)
    end

    def config
      @config ||= File.exist?(CONFIG_FILE) && YAML::load( File.open( CONFIG_FILE ) ) || {}
    end

    def correct_account(account)
      account.split(/\/\//, 2)[-1].split(/\./, 2)[0] if account
    end
end
