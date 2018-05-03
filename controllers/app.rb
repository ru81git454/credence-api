# frozen_string_literal: true

require 'roda'
require 'json'

# require_relative 'lib/init'
# require_relative 'config/environments'
# require_relative 'models/init'

module Credence
  # Web controller for Credence API
  class Api < Roda
    plugin :halt

    route do |routing|
      response['Content-Type'] = 'application/json'

      routing.root do
        { message: 'CredenceAPI up at /api/v1' }.to_json
      end

      routing.on 'api' do
        routing.on 'v1' do
          @api_root = "api/v1"

          routing.on 'accounts' do
            @account_route = "#{@api_root}/accounts"

            routing.on String do |username|
              # GET api/v1/accounts/[USERNAME]
              routing.get do
                account = Account.first(username: username)
                account ? account.to_json : raise('Account not found')
              rescue StandardError => error
                routing.halt 404, { message: error.message }.to_json
              end
            end

            # POST api/v1/accounts
            routing.post do
              new_data = JSON.parse(routing.body.read)
              new_account = Account.new(new_data)
              raise('Could not save account') unless new_account.save

              response.status = 201
              response['Location'] = "#{@account_route}/#{new_account.id}"
              { message: 'Project saved', data: new_account }.to_json
            rescue Sequel::MassAssignmentRestriction
              routing.halt 400, { message: 'Illegal Request' }.to_json
            rescue StandardError => error
              puts error.inspect
              routing.halt 500, { message: error.message }.to_json
            end
          end

          routing.on 'projects' do
            @proj_route = "#{@api_root}/projects"

            routing.on String do |proj_id|
              routing.on 'documents' do
                @doc_route = "#{@api_root}/projects/#{proj_id}/documents"
                # GET api/v1/projects/[proj_id]/documents/[doc_id]
                routing.get String do |doc_id|
                  doc = Document.where(project_id: proj_id, id: doc_id).first
                  doc ? doc.to_json : raise('Document not found')
                rescue StandardError => error
                  routing.halt 404, { message: error.message }.to_json
                end

                # GET api/v1/projects/[proj_id]/documents
                routing.get do
                  output = Project.first(id: proj_id).documents
                  JSON.pretty_generate(output)
                rescue StandardError
                  routing.halt 404, { message: 'Could not find documents' }
                end

                # POST api/v1/projects/[ID]/documents
                routing.post do
                  new_data = JSON.parse(routing.body.read)

                  new_doc = CreateDocumentForProject.call(
                    project_id: proj_id, document_data: new_data
                  )

                  response.status = 201
                  response['Location'] = "#{@doc_route}/#{new_doc.id}"
                  { message: 'Document saved', data: new_doc }.to_json
                rescue Sequel::MassAssignmentRestriction
                  routing.halt 400, { message: 'Illegal Request' }.to_json
                rescue StandardError
                  routing.halt 500, { message: 'Database error' }.to_json
                end
              end

              # GET api/v1/projects/[ID]
              routing.get do
                proj = Project.first(id: proj_id)
                proj ? proj.to_json : raise('Project not found')
              rescue StandardError => error
                routing.halt 404, { message: error.message }.to_json
              end
            end

            # GET api/v1/projects
            routing.get do
              output = Project.all
              JSON.pretty_generate(output)
            rescue StandardError
              routing.halt 404, { message: 'Could not find projects' }.to_json
            end

            # POST api/v1/projects
            routing.post do
              new_data = JSON.parse(routing.body.read)
              new_proj = Project.new(new_data)
              raise('Could not save project') unless new_proj.save

              response.status = 201
              response['Location'] = "#{@proj_route}/#{new_proj.id}"
              { message: 'Project saved', data: new_proj }.to_json
            rescue Sequel::MassAssignmentRestriction
              routing.halt 400, { message: 'Illegal Request' }.to_json
            rescue StandardError => error
              routing.halt 500, { message: error.message }.to_json
            end
          end
        end
      end
    end
  end
end
