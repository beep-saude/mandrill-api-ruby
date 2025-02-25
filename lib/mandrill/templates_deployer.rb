# frozen_string_literal: false
require 'rubygems'

module Mandrill
  class DefaultConsoleLogger
    def info(key:, data: {}, data_in_root: {})
      data = {
        level: 'INFO'.freeze,
        key: key,
        **data
      }
      puts data.to_json
    end

    def error(key:, data: {}, data_in_root: {})
      data = {
        level: 'ERROR'.freeze,
        key: key,
        **data
      }

      puts data.to_json
    end
  end

  class TemplatesDeployer
    
    attr_reader :existing_templates_cache, :deployments

    def initialize(api_key:, templates_path:, default_sender:, templates_suffix: '', labels: [], logger: DefaultConsoleLogger.new)
      @client = ::Mandrill::API.new(api_key)
      @logger = logger
      @templates_client = @client.templates
      @templates_suffix = templates_suffix
      @templates_path = templates_path
      @default_sender = default_sender
      @labels = labels
      @deployments = {}
      @existing_templates_cache = load_existing_templates_cache!
      build_deployments_mapping!
    end

    def deploy!
      @deployments.each do |template_name, deploy_data|
        # reading file content each iteration to save memory
        file_content = File.read(deploy_data[:filepath])
        deploy_data[:code] = file_content
        create_or_update(template_name: template_name, data: deploy_data)
      end
    end

    def filter_files(filespaths)
      filespaths.reject { |filepath| File.directory?(filepath) }
    end

    def build_deployments_mapping!
      template_files = filter_files(Dir[@templates_path])

      template_files.map { |filepath|
        template_name = "#{File.basename(filepath, '.html')}#{@templates_suffix}".downcase
        existing_info = @existing_templates_cache[template_name] || {}

        @deployments[template_name] = {
          name: template_name,
          filepath: filepath,
          from_email: existing_info['from_email'] || @default_sender,
          from_name: existing_info['from_name'] || 'Beep Saúde',
          subject: existing_info['subject'] || template_name,
          publish: true,
          labels: existing_info.key?('labels') ? existing_info['labels'].concat(@labels) : @labels
        }
      }
    end

    def get_info(template_name:)
      begin
        @templates_client.info(template_name)
      rescue Mandrill::UnknownTemplateError
        nil
      end
    end

    def load_existing_templates_cache!
      templates_list = @templates_client.list
      {}.tap do |templates_map|
        templates_list.each do |template|
          template.delete('code')
          template.delete('publish_code')
          templates_map[template['slug']] = template
        end
      end
    end

    def template_exists?(template_name)
      @existing_templates_cache.key?(template_name)
    end

    def create_or_update(template_name:, data:)
      return update(new_data: data) if template_exists?(template_name)

      create(data: data)
    end

    private

    def create(data: {})
      begin
        @logger.info(key: 'rake.task.deployment.email_templates.create', data: { message: "⚠ Criando template #{data[:name]} via API ..." })
        @client.call('/templates/add', data)
        @logger.info(key: 'rake.task.deployment.email_templates.create', data: { message: "✓ template #{data[:name]} criado via API" })
      rescue => e
        @logger.error(key: 'rake.task.deployment.email_templates.create', data: { message: "X Falha na criação do template #{data[:name]} via API ... (#{e.message})" })
      end
    end

    def update(new_data: {})
      begin
        @logger.info(key: 'rake.task.deployment.email_templates.update', data: { message: "⚠ Atualizando template #{new_data[:name]} via API ..." })
        @client.call('/templates/update', new_data)
        @logger.info(key: 'rake.task.deployment.email_templates.update', data: { message: "✓ template #{new_data[:name]} atualizado via API" })
      rescue => e
        @logger.error(key: 'rake.task.deployment.email_templates.update', data: { message: "X Falha na atualização do template #{data[:name]} via API ... (#{e.message})" })
      end
    end
  end
end
