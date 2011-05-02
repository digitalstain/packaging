require 'net/http'
require 'time'

Given /^a platform supported by Neo4j$/ do
  fail "unsupported platform #{current_platform}" unless current_platform.supported?
end

Given /^Neo4j version based on system property "([^"]*)" and product based on system property "([^"]*)"$/ do |version_name, product_name|
  neo4j.version = ENV[version_name]
  neo4j.product = ENV[product_name]
  fail "missing property #{version_name}" if neo4j.version == nil
  fail "missing property #{product_name}" if neo4j.product == nil
end

Given /^set Neo4j Home to "([^"]*)"$/ do |home|
  neo4j.home = File.expand_path(home)
  neo4j.home = neo4j.home.tr('/', '\\') if (current_platform.windows?)
  puts "using neo4j.home "+neo4j.home
  ENV["NEO4J_HOME"] = neo4j.home
  Dir.mkdir(neo4j.home) unless File.exists?(neo4j.home)
end

Given /^a web site at host "([^"]*)" or system property "([^"]*)"$/ do |host, env_location|
  puts "host = #{host}"
  puts "env_location = #{env_location}"
  puts "env = #{ENV[env_location]}"
  if ENV[env_location]
    neo4j.download_location = URI.parse(ENV[env_location])
    puts "downloading from " + neo4j.download_location.to_s
  else
    Net::HTTP.get(URI.parse("http://#{host}"))
    neo4j.download_location = URI.parse("http://#{host}/#{archive_name}")
    puts "downloading from " + neo4j.download_location.to_s
  end
end

When /^I download Neo4j \(if I haven't already\)$/ do
  if (neo4j.download_location.scheme == "http") then
	fail "You do the downloading, please? Then do: export DOWNLOAD_LOCATION=file:///Users/ata/dev/neo/packaging/qa/neo4j-community-1.4.M01-unix.tar.gz"
  elsif (neo4j.download_location.scheme == "file") then
    File.open(neo4j.download_location.path, "r") do |src|
      open(archive_name, "wb") do |file|
        while buf = src.read (2048)
          file.write(buf)
        end
      end
    end

  else
    fail 'unsupported schema-location '+ download_location
  end
end

Then /^the working directory should contain a Neo4j archive$/ do
  fail "#{archive_name} does not exists" unless File.exists?(archive_name)
end

When /^I unpack the archive into Neo4j Home$/ do
  full_archive_name= File.expand_path(archive_name)
  pushd neo4j.home

  if (current_platform.unix?)
    puts "unpacking with tar xzf #{full_archive_name} --strip-components 1"
    `tar xzf #{full_archive_name} --strip-components 1`
    fail "unpacking failed (#{$?})" unless $?.to_i == 0
  elsif  current_platform.windows?
    unzip = File.expand_path("../../support/unzip.vbs", __FILE__).tr('/', '\\')
    full_archive_name = full_archive_name.tr('/', '\\')
    cmd = "cmd /c #{unzip} #{full_archive_name} #{neo4j.home}"
    puts cmd
    puts `#{cmd}`
    fail "unpacking failed (#{$?})" unless $?.to_i == 0
  else
    fail 'platform not supported'
  end
  popd
end

Then /^Neo4j Home should contain a Neo4j Server installation$/ do
  if (current_platform.unix?)
    fail "file "+neo4j.home+"/bin/neo4j not found" unless File.exists?(neo4j.home+"/bin/neo4j")
  elsif (current_platform.windows?)
    fail "file "+neo4j.home+"\\bin\\neo4j.bat not found" unless File.exists?(neo4j.home+"\\bin\\neo4j.bat")
  else
    fail 'platform not supported'
  end
end

Then /^the Neo4j version of the installation should be correct$/ do
  (Dir.entries(neo4j.home+"/lib") + Dir.entries(neo4j.home+"/system/lib")).each do |lib|
    if lib =~ /^neo4j.*\.jar$/
      fail lib+" does not contain the Neo4j-version" unless lib =~ /#{neo4j.version}/;
    end
  end
end

When /^in (Windows|Unix) I will patch the "([^\"]*)" adding "([^\"]*)" to ("[^\"]*")$/ do |platform, config, param, value|
  if (platform == "Windows" && current_platform.windows?) || (platform == "Unix" && current_platform.unix?)
    File.open(config, "a") do |config_file|
      config_file.puts "#{param}=" + eval(value)
    end
  end
end
