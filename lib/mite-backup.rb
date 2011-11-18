require "mite-backup/version"
require "multi_json"
require "net/http"
require "uri"
require 'zlib'
require 'yaml'

class MiteBackup
  MAX_CHECKS              = 30
  SLEEP_BEFORE_EACH_CHECK = 2 # seconds
  CONFIG_FILE = File.expand_path('~/.mite-backup.yml')
  
  def initialize(account_name, email, password)
    @account_name = account_name || config["account"]
    @email        = email        || config["email"]
    @password     = password     || config["password"]
    
    @http = Net::HTTP.new(URI.parse("http://#{@account_name}.mite.yo.lk/").host)
  end

  def run
    runnable?
    create
    check
    download
  end

  def setup
    (config["account"] = @account_name) || config.delete("account")
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
      failed "Please provide your account name with --account [ACCOUNT]." unless @account_name
      failed "Please provide your mite.users email with --email [EMAIL]." unless @email
      failed "Please provide your mite.users password with --password [PASSWORD]." unless @password
    end
  
    def create
      @id = perform_request(Net::HTTP::Post.new("/account/backup.json"))["id"]
    end
    
    def check
      MAX_CHECKS.times do |i|
        sleep(SLEEP_BEFORE_EACH_CHECK)
        break if @ready = perform_request(Net::HTTP::Get.new("/account/backup/#{@id}.json"))["ready"]
      end
    end
    
    def download
      if @ready
        content = perform_request(Net::HTTP::Get.new("/account/backup/#{@id}/download.json"), false).body
        gz = Zlib::GzipReader.new(StringIO.new(content), :external_encoding => content.encoding)
        puts gz.read
      else
        failed "Backup was not ready for download after #{MAX_CHECKS*SLEEP_BEFORE_EACH_CHECK} seconds. Contact the mite support."
      end
    end
  
    def perform_request(request, json=true)
      request.basic_auth(@email, @password)
      response = @http.request(request)
      if response.code == "401"
        failed "Could not authenticate with email #{@email.inspect} and provided password. The user needs to be an admin or the owner of the mite.account!"
      elsif !["200", "201"].include?(response.code)
        failed "mite responded with irregular code #{response.code}"
      end
      json ? MultiJson.decode(response.body)["backup"] : response
    end
    
    def failed(reason)
      $stderr.puts "Failed: #{reason}"
      exit(1)
    end
    
    def config
      @config ||= File.exist?(CONFIG_FILE) && YAML::load( File.open( CONFIG_FILE ) ) || {}
    end

end
