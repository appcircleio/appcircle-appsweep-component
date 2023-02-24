# frozen_string_literal: true

require 'English'
require 'pathname'

require 'dotenv'
Dotenv.load

def get_env(key)
  ENV[key].nil? || ENV[key] == '' ? nil : ENV[key]
end

def env_has_key(key)
  !ENV[key].nil? && ENV[key] != '' ? ENV[key] : abort("Missing #{key}.")
end

def getproject
  repository_path = env_has_key('AC_REPOSITORY_DIR')
  project_path = get_env('AC_PROJECT_PATH') || '.'
  project_path = File.expand_path(project_path, repository_path)
  project_path.to_s
end

api_key = env_has_key('AC_APPSWEEP_API_KEY')
android_module = env_has_key('AC_MODULE')
ENV['APPSWEEP_API_KEY'] = api_key
ac_project_path = getproject
variant = env_has_key('AC_APPSWEEP_VARIANT')
build_file = File.join(ac_project_path, android_module, 'build.gradle')
raise "#{build_file} does not exist." unless File.exist?(build_file)

gradlew_folder_path = if Pathname.new(ac_project_path.to_s).absolute?
                        ac_project_path
                      else
                        File.expand_path(File.join(ac_repo_path, ac_project_path))
                      end

gradle_task = "uploadToAppSweep#{variant.capitalize}"
command = "cd #{gradlew_folder_path} && chmod +x ./gradlew && ./gradlew clean #{gradle_task}"
result = `#{command}`
puts result
matches = result.match(/Your scan results will be available at (\S+)/)
if matches
  File.open(ENV['AC_ENV_FILE_PATH'], 'a') do |f|
    f.puts "AC_APPSWEEP_URL=#{matches[1]}"
  end
end
